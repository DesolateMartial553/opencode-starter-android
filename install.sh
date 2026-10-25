#!/usr/bin/env bash
# OpenCode starter kit for Android (run inside the Termux app).
#
#   curl -fsSL https://raw.githubusercontent.com/DesolateMartial553/opencode-starter-android/main/install.sh | bash
#
# What it does:
#   1. installs tmux and proot-distro in Termux
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

  # --- 1. Termux packages ------------------------------------------------------------------
  say "[1/5] Installing Termux packages (tmux, proot-distro)"
  # Use apt-get, not `pkg`: on a fresh Termux `pkg update` auto-picks a random mirror (it once chose a
  # Chinese university server at ~5 kB/s). apt-get keeps Termux's default fast mirror.
  # --no-install-recommends: avoids ~600 MB of unneeded extras (clang, llvm, python, openssh...).
  # curl is already in Termux and git is only needed inside Debian.
  run apt-get update -y
  run env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends -o Dpkg::Options::=--force-confold tmux proot-distro curl
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

  # --- 2. get the kit files ----------------------------------------------------------------
  say "[2/5] Fetching the kit"
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

  # --- 3. Debian + OpenCode ----------------------------------------------------------------
  say "[3/5] Installing Debian and OpenCode (this takes a few minutes and downloads ~300 MB)"
  if [ -d "$ROOTFS" ]; then
    ok "Debian already installed"
  else
    run proot-distro install "$DISTRO"
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
    install_file "$kit/termux/termux.properties" "$HOME/.termux/termux.properties" 644
    install_file "$kit/termux/oc" "$PFX/bin/oc" 755
    if command -v termux-reload-settings >/dev/null 2>&1; then run termux-reload-settings; fi
  else
    note "[dry-run] would install ~/.tmux.conf, ~/.termux/termux.properties and $PFX/bin/oc"
  fi

  # --- 5. optional API keys ----------------------------------------------------------------
  say "[5/5] Optional API keys"
  note "OpenCode works with no keys using free models. Keys only add stronger models / better web scraping."
  note "They are saved only on this phone (inside Debian, readable only by you)."
  local keyfile="$ROOTFS/root/.config/opencode-keys.env"
  save_key() { # save_key "Label" VAR "where to get it"
    local label=$1 var=$2 link=$3 val=""
    if [ -f "$keyfile" ] && grep -q "^export $var=" "$keyfile"; then ok "$label key already saved"; return 0; fi
    if [ "$YES" = 1 ] || [ "$DRY" = 1 ] || ! have_tty; then note "$label: get a free key at $link (optional; add it later by re-running the installer)"; return 0; fi
    printf '\n  %s key: get one free at %s\n  Paste it (nothing shows as you type) or press Enter to skip: ' "$label" "$link" >/dev/tty
    read -rs val </dev/tty || val=""
    printf '\n' >/dev/tty
    if [ -z "$val" ]; then note "skipped $label"; return 0; fi
    case "$val" in *"'"*|*" "*) warn "that key looks wrong (contains a quote or space); skipped"; return 0 ;; esac
    ( umask 077; touch "$keyfile"; grep -v "^export $var=" "$keyfile" > "$keyfile.tmp" || true
      printf "export %s='%s'\n" "$var" "$val" >> "$keyfile.tmp"; mv "$keyfile.tmp" "$keyfile" )
    chmod 600 "$keyfile"
    ok "$label key saved"
  }
  save_key "Google Gemini" GOOGLE_GENERATIVE_AI_API_KEY "https://aistudio.google.com/apikey"
  save_key "OpenRouter" OPENROUTER_API_KEY "https://openrouter.ai/keys"
  save_key "Firecrawl (web scraping for deep research)" FIRECRAWL_API_KEY "https://www.firecrawl.dev/app/api-keys"
  # the Firecrawl MCP server ships switched off; turn it on only when a key exists
  if [ -f "$keyfile" ] && grep -q '^export FIRECRAWL_API_KEY=' "$keyfile" && [ -f "$dest/opencode.json" ]; then
    sed -i 's/"enabled": false/"enabled": true/' "$dest/opencode.json"
    # Firecrawl's MCP server runs through npx, so Node.js is needed (only installed when Firecrawl is used)
    run proot-distro login "$DISTRO" -- bash -c 'command -v npx >/dev/null 2>&1 || { apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nodejs npm; }' \
      || warn "could not install Node.js for Firecrawl; run: oc shell, then apt-get install nodejs npm"
    ok "Firecrawl search turned on"
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
