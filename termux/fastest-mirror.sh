#!/usr/bin/env bash
# Pick the fastest Termux package mirror for THIS phone, right now, and switch to it.
# Runs in Termux. Installed as `oc-mirror`; the installer runs it, and you can run it any time with `oc mirror`.
#
#   fastest-mirror.sh [--dry-run] [--update] [--top N]
#     --dry-run   measure and report, change nothing
#     --update    run `apt-get update` after switching
#     --top N     how many of the closest mirrors get the full speed test (default 8)
#
# How it works: (1) collect every mirror Termux knows about, (2) probe them all in parallel and keep the N
# with the lowest delay, (3) download the same 400 KB chunk from each of those N, one at a time, and pick the
# highest speed, (4) write it to sources.list and pin it so `pkg` does not pick a random mirror later.
set -u
PFX=${PREFIX:-/data/data/com.termux/files/usr}
MIRRORS_DIR="$PFX/etc/termux/mirrors"
SOURCES="$PFX/etc/apt/sources.list"
CHOSEN="$PFX/etc/termux/chosen_mirrors"
INDEX="dists/stable/main/binary-aarch64/Packages"
DRY=0; UPDATE=0; TOP=8
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --update) UPDATE=1 ;;
    --top) TOP=${2:?--top needs a number}; shift ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown option: $1"; exit 1 ;;
  esac
  shift
done

command -v curl >/dev/null 2>&1 || { echo "curl is needed"; exit 1; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT

# 1) every mirror Termux ships a definition for, else a built-in list of well-known ones
: > "$tmp/all"
if [ -d "$MIRRORS_DIR" ]; then
  grep -rh '^MAIN=' "$MIRRORS_DIR" 2>/dev/null | sed -e 's/^MAIN=//' -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'\$//" > "$tmp/all"
fi
if [ ! -s "$tmp/all" ]; then
  cat > "$tmp/all" <<'EOF'
https://packages-cf.termux.dev/apt/termux-main
https://packages.termux.dev/apt/termux-main
https://grimler.se/termux/termux-main
https://mirror.accum.se/mirror/termux.dev/termux-main
https://ftp.fau.de/termux/termux-main
https://mirror.fcix.net/termux/termux-main
https://plug-mirror.rcac.purdue.edu/termux/termux-main
https://mirror.csclub.uwaterloo.ca/termux/termux-main
https://mirror.albony.in/termux/termux-main
https://mirrors.tuna.tsinghua.edu.cn/termux/apt/termux-main
EOF
fi
sort -u "$tmp/all" -o "$tmp/all"
echo "Testing $(wc -l < "$tmp/all" | tr -d ' ') mirrors (this takes under a minute)..."

# 2) delay probe, 16 at a time: keep only mirrors that really serve the index
probe() { # probe MAIN -> "seconds MAIN" when the index answers
  local out
  out=$(curl -sS -m 5 -r 0-0 -o /dev/null -w '%{http_code} %{time_total}' "$1/$INDEX" 2>/dev/null) || return 0
  case "$out" in
    200*|206*) printf '%s %s\n' "${out#* }" "$1" ;;
  esac
}
export -f probe
export INDEX
xargs -P 16 -I{} bash -c 'probe "$1"' _ {} < "$tmp/all" > "$tmp/alive" 2>/dev/null
if [ ! -s "$tmp/alive" ]; then
  echo "No mirror answered. Check your internet connection and try again."; exit 1
fi
sort -n "$tmp/alive" | head -n "$TOP" | cut -d' ' -f2- > "$tmp/top"

# 3) speed test: the same 400 KB chunk from each, sequentially so they don't compete
: > "$tmp/speeds"
while IFS= read -r m; do
  bps=$(curl -sS -m 8 -r 0-399999 -o /dev/null -w '%{speed_download}' "$m/$INDEX" 2>/dev/null || echo 0)
  bps=${bps%.*}; bps=${bps:-0}
  printf '%s %s\n' "$bps" "$m" >> "$tmp/speeds"
  printf '  %6d kB/s  %s\n' $((bps / 1000)) "${m#https://}"
done < "$tmp/top"
best=$(sort -rn "$tmp/speeds" | head -n 1)
best_bps=${best%% *}; best_url=${best#* }
if [ "${best_bps:-0}" -le 0 ]; then echo "No mirror finished the speed test. Try again on a better connection."; exit 1; fi
echo "Fastest: ${best_url#https://} ($((best_bps / 1000)) kB/s)"
if [ "$best_bps" -lt 100000 ]; then echo "Note: even the best mirror is slow ($((best_bps / 1000)) kB/s), so your connection itself is slow. Try Wi-Fi."; fi

# 4) switch to it and pin it
if [ "$DRY" = 1 ]; then echo "[dry-run] would write: deb $best_url stable main"; exit 0; fi
[ -f "$SOURCES.bak-termux-kit" ] || cp "$SOURCES" "$SOURCES.bak-termux-kit" 2>/dev/null || true
printf 'deb %s stable main\n' "$best_url" > "$SOURCES"
# pin: point chosen_mirrors at the matching definition so `pkg` doesn't silently re-pick a random one
if [ -d "$MIRRORS_DIR" ]; then
  def=$(grep -rlE "^MAIN=[\"']?${best_url}[\"']?\$" "$MIRRORS_DIR" 2>/dev/null | head -n 1)
  if [ -n "$def" ]; then ln -sfn "$def" "$CHOSEN"; fi
fi
echo "Switched Termux to ${best_url#https://}"
if [ "$UPDATE" = 1 ]; then apt-get update -y; fi
