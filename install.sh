#!/usr/bin/env bash
# OpenCode starter kit for Android (run inside the Termux app).
#
#   curl -fsSL https://raw.githubusercontent.com/DesolateMartial553/opencode-starter-android/main/install.sh | bash
#
# What it does:
#   1. finds the fastest Termux download mirror for your phone, then installs tmux and proot-distro
#   2. installs a small Debian (no root needed) and OpenCode inside it
#   3. copies this kit's config, research skills and agents (backing up anything it replaces)
#   4. sets up tmux, a phone extra-keys row and the `oc` launcher in Termux
#   5. optionally saves your own API keys (only on this phone, never in any repo)
#
# Options:  --dry-run (show steps, change nothing)   --yes (no questions)   --source DIR (use a local copy of the repo)
set -euo pipefail

REPO="DesolateMartial553/opencode-starter-android"
BRANCH="main"
DISTRO="debian"
DRY=0
YES=0
SOURCE=""

say()  { printf '\n\033[36m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32mOK\033[0m  %s\n' "$*"; }
note() { printf '  ... %s\n' "$*"; }
warn() { printf '  \033[33m!!\033[0m  %s\n' "$*"; }
die()  { printf '\n\033[31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# run a command, or only print it with --dry-run
run() {
  if [ "$DRY" = 1 ]; then note "[dry-run] $*"; else "$@"; fi
}

# prompts read from the keyboard even when the script itself is piped from curl
have_tty() { ( : </dev/tty ) 2>/dev/null; }

ask_yn() { # ask_yn "question" default(y|n)
  local q=$1 def=${2:-y} a hint="Y/n"
  [ "$def" = n ] && hint="y/N"
  if [ "$YES" = 1 ] || [ "$DRY" = 1 ] || ! have_tty; then [ "$def" = y ]; return; fi
  printf '%s [%s] ' "$q" "$hint" >/dev/tty
  read -r a </dev/tty || a=""
  a=${a:-$def}
  case "$a" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

backup_if_exists() { # backup_if_exists path
  if [ -e "$1" ]; then
    local b
    b="$1.backup-$(date +%Y%m%d-%H%M%S)"
    run mv "$1" "$b"
    note "existing file/folder kept as $b"
  fi
}

install_file() { # install_file src dest mode
  local src=$1 dest=$2 mode=$3
  if [ -f "$dest" ] && ! cmp -s "$src" "$dest" 2>/dev/null; then
    run cp "$dest" "$dest.backup-$(date +%Y%m%d-%H%M%S)"
  fi
  run mkdir -p "$(dirname "$dest")"
  run cp "$src" "$dest"
  run chmod "$mode" "$dest"
}

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) DRY=1 ;;
      --yes|-y) YES=1 ;;
      --source) SOURCE="${2:?--source needs a folder}"; shift ;;
      -h|--help) echo "usage: install.sh [--dry-run] [--yes] [--source DIR]"; return 0 ;;
      *) die "unknown option: $1" ;;
    esac
    shift
  done

  say "OpenCode starter kit for Android (research edition)"
  if [ "$DRY" = 1 ]; then warn "DRY RUN: nothing will be changed"; fi

  # --- 0. environment check ----------------------------------------------------------------
  case "${PREFIX:-}" in
    *com.termux*) ok "running inside Termux" ;;
    *) if [ "$DRY" = 1 ]; then warn "not in Termux (fine for a dry run)"; else die "run this inside the Termux app, not another terminal."; fi ;;
  esac
  case "$(uname -m)" in
    aarch64|arm64) ok "64-bit ARM phone" ;;
    *) if [ "$DRY" = 1 ]; then warn "CPU is $(uname -m) (fine for a dry run)"; else die "needs a 64-bit ARM (arm64) phone; this one reports $(uname -m)."; fi ;;
  esac
  local PFX=${PREFIX:-/data/data/com.termux/files/usr}
  local ROOTFS="$PFX/var/lib/proot-distro/installed-rootfs/$DISTRO"

  # --- 1. get the kit files, then pick the fastest Termux mirror ---------------------------
  say "[1/5] Fetching the kit and finding the fastest download mirror"
  local kit="" work=""
  if [ -n "$SOURCE" ]; then
    kit=$(cd "$SOURCE" && pwd)
    note "using local copy: $kit"
  elif [ "$DRY" = 1 ]; then
    note "[dry-run] would download https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz"
  else
    work=$(mktemp -d)
    curl -fsSL "https://github.com/$REPO/archive/refs/heads/$BRANCH.tar.gz" | tar -xz -C "$work"
    kit="$work/$(ls "$work" | head -n 1)"
    ok "downloaded"
  fi
  # On a fresh Termux `pkg` auto-picks a RANDOM mirror (it once chose a Chinese university server at ~5 kB/s).
  # So we time the real mirrors from this phone and switch to the fastest before downloading anything big.
  if [ -n "$kit" ]; then
    mirror_args=()
    if [ "$DRY" = 1 ]; then mirror_args=(--dry-run); fi
    bash "$kit/termux/fastest-mirror.sh" "${mirror_args[@]}" || warn "mirror test failed; continuing with Termux's current mirror (run  oc mirror  later to retry)"
  else
    note "[dry-run] would test every Termux mirror and switch to the fastest"
  fi

  # --- 2. Termux packages ------------------------------------------------------------------
  say "[2/5] Installing Termux packages (tmux, proot-distro)"
  # --no-install-recommends: avoids ~600 MB of unneeded extras (clang, llvm, python, openssh...).
  # curl is already in Termux and git is only needed inside Debian. apt-get (not `pkg`) so nothing re-picks a mirror.
  run apt-get update -y
  # Full upgrade first: Termux breaks on PARTIAL upgrades (installing one package that upgrades curl but not
  # openssl left curl unable to start: "cannot locate symbol SSL_set_quic_tls_early_data_enabled").
  run env DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -o Dpkg::Options::=--force-confold
  run env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends -o Dpkg::Options::=--force-confold tmux proot-distro curl
  # safety net: if curl still cannot start, repair with another full upgrade before continuing
  if [ "$DRY" != 1 ] && ! curl --version >/dev/null 2>&1; then
    warn "curl is broken by a half-finished upgrade; repairing"
    apt-get -f install -y -o Dpkg::Options::=--force-confold || true
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y -o Dpkg::Options::=--force-confold
    curl --version >/dev/null 2>&1 || die "curl is still broken. Run: apt-get update && apt-get dist-upgrade   then run this installer again."
  fi
  if [ ! -d "$HOME/storage/shared" ]; then
    note "asking Android for storage access: tap ALLOW on the pop-up (lets reports be saved where your file manager can see them)"
    run termux-setup-storage
    if [ "$DRY" != 1 ]; then
      for _ in $(seq 1 30); do [ -d "$HOME/storage/shared" ] && break; sleep 1; done
      if [ -d "$HOME/storage/shared" ]; then ok "storage access granted"; else warn "no storage access yet; reports will go to ~/research inside Debian. Run termux-setup-storage later."; fi
    fi
  else
    ok "storage access already granted"
  fi

  # --- 3. Debian + OpenCode ----------------------------------------------------------------
  say "[3/5] Installing Debian and OpenCode (this takes a few minutes and downloads ~300 MB)"
  if [ -d "$ROOTFS" ]; then
    ok "Debian already installed"
  else
    # the ~50 MB image comes from GitHub; mobile connections often drop mid-download, so retry a few times
    tries=0
    until run proot-distro install "$DISTRO"; do
      tries=$((tries + 1))
      [ "$tries" -ge 5 ] && die "the Debian download keeps dropping (a weak or switching connection). Move closer to the router or use Wi-Fi, then run this installer again: it is safe to repeat."
      note "download interrupted; trying again in 5 seconds ($tries of 4 retries used)"
      sleep 5
    done
  fi

  # config + launcher script go in before provisioning so `npm install` can read package.json
  local dest="$ROOTFS/root/.config/opencode"
  if [ -d "$dest" ]; then backup_if_exists "$dest"; fi
  if [ -n "$kit" ]; then
    run mkdir -p "$dest"
    run cp -r "$kit/config/." "$dest/"
    install_file "$kit/termux/oc-start.sh" "$ROOTFS/root/.oc-start.sh" 755
  else
    note "[dry-run] would copy config/ to $dest and termux/oc-start.sh to $ROOTFS/root/.oc-start.sh"
  fi

  local PROVISION='set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y --no-install-recommends curl git ca-certificates unzip
export PATH="$HOME/.opencode/bin:$PATH"
if ! command -v opencode >/dev/null 2>&1; then
  if ! curl -fsSL https://opencode.ai/install | bash; then
    echo "official installer failed; trying npm"
    apt-get install -y --no-install-recommends nodejs npm
    npm install -g opencode-ai
  fi
fi
command -v opencode >/dev/null 2>&1 || { echo "OpenCode did not install"; exit 3; }
echo "OpenCode: $(opencode --version 2>/dev/null || echo installed)"
if command -v npm >/dev/null 2>&1; then (cd "$HOME/.config/opencode" && npm install --no-audit --no-fund --silent) || true; fi'
  if ! run proot-distro login "$DISTRO" -- bash -c "$PROVISION"; then
    die "setting up OpenCode inside Debian failed. Check your internet and run this installer again (it is safe to repeat). If it keeps failing, copy the last lines and ask for help."
  fi

  # --- 4. Termux side: tmux, extra keys, launcher -------------------------------------------
  say "[4/5] Setting up tmux, the extra-keys row and the 'oc' command"
  if [ -n "$kit" ]; then
    install_file "$kit/termux/tmux.conf" "$HOME/.tmux.conf" 644
    install_file "$kit/termux/tmux-menu.conf" "$HOME/.tmux-menu.conf" 644
    install_file "$kit/termux/tmux-help.txt" "$HOME/.tmux-help.txt" 644
    install_file "$kit/termux/termux.properties" "$HOME/.termux/termux.properties" 644
    install_file "$kit/termux/oc" "$PFX/bin/oc" 755
    install_file "$kit/termux/fastest-mirror.sh" "$PFX/bin/oc-mirror" 755
    if command -v termux-reload-settings >/dev/null 2>&1; then run termux-reload-settings; fi
  else
    note "[dry-run] would install ~/.tmux.conf (+ tap menu and help), ~/.termux/termux.properties and $PFX/bin/oc"
  fi

  # --- 5. optional API keys ----------------------------------------------------------------
  say "[5/5] Optional API keys"
  note "OpenCode works with no keys using free models. Keys only add stronger models and better research search."
  note "They are saved only on this phone (inside Debian, readable only by you). Press Enter to skip any of them."
  note "You can add or change them any time later with:  oc key"
  if [ "$YES" = 1 ] || [ "$DRY" = 1 ] || ! have_tty; then
    note "skipping key prompts. Later, run:  oc key   (step-by-step guide: KEYS.md in the repo)"
  elif [ -n "$kit" ]; then
    "$PFX/bin/oc" key || warn "key setup was interrupted; run  oc key  later"
  fi

  if [ -n "$work" ]; then rm -rf "$work"; fi

  say "All done."
  cat <<'EOF'

Next steps (in Termux):
  1. Start it:           oc
  2. Leave it running:   press CTRL (extra-keys row) then b, then d.   Come back any time with: oc
  3. First prompt to try: "Research the best budget phones in the UK right now, with sources"

Android may close Termux in the background. In Android settings: Apps > Termux > Battery > Unrestricted.
Full guide: https://github.com/DesolateMartial553/opencode-starter-android#readme
EOF
}

main "$@"
