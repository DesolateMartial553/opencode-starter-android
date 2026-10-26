#!/usr/bin/env bash
# Undo the OpenCode Android starter kit (run in Termux). Usage: bash uninstall.sh [--dry-run]
# Removes the `oc` launcher and the kit's config, restoring any backups the installer made.
# It asks before deleting Debian itself (which also deletes OpenCode, your saved keys and ~/research).
set -uo pipefail
DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
PFX=${PREFIX:-/data/data/com.termux/files/usr}
PD="$PFX/var/lib/proot-distro"
# proot-distro 5+ keeps Debian in containers/NAME/rootfs; older versions used installed-rootfs/NAME
if [ -d "$PD/containers/debian/rootfs" ]; then ROOTFS="$PD/containers/debian/rootfs"; else ROOTFS="$PD/installed-rootfs/debian"; fi
run() { if [ "$DRY" = 1 ]; then echo "  [dry-run] $*"; else "$@"; fi; }
latest() { ls -d "$1".backup-* 2>/dev/null | sort | tail -n 1; }   # newest backup of a path
restore() { # restore path
  local b; b=$(latest "$1")
  if [ -n "$b" ]; then run rm -rf "$1"; run mv "$b" "$1"; echo "restored $1"; else run rm -rf "$1"; echo "removed $1"; fi
}
ask() { local a; [ "$DRY" = 1 ] && return 1; ( : </dev/tty ) 2>/dev/null || return 1; printf '%s [y/N] ' "$1" >/dev/tty; read -r a </dev/tty; case "$a" in y|Y|yes) return 0;; *) return 1;; esac; }

tmux kill-server 2>/dev/null || true
run rm -f "$PFX/bin/oc" "$HOME/.shortcuts/OpenCode"
[ -f "$HOME/.bashrc" ] && run sed -i '/^# >>> opencode-kit autostart >>>$/,/^# <<< opencode-kit autostart <<<$/d' "$HOME/.bashrc"
[ -f "$HOME/.tmux.conf" ] && restore "$HOME/.tmux.conf"
run rm -f "$HOME/.tmux-menu.conf" "$HOME/.tmux-help.txt"
[ -f "$HOME/.termux/termux.properties" ] && restore "$HOME/.termux/termux.properties"
command -v termux-reload-settings >/dev/null 2>&1 && run termux-reload-settings
[ -d "$ROOTFS/root/.config/opencode" ] && restore "$ROOTFS/root/.config/opencode"
run rm -f "$ROOTFS/root/.oc-start.sh"
[ -f "$ROOTFS/root/.bashrc" ] && run sed -i '/^# >>> opencode-kit PATH >>>$/,/^# <<< opencode-kit PATH <<<$/d' "$ROOTFS/root/.bashrc"
if [ -f "$ROOTFS/root/.config/opencode-keys.env" ] && ask "Delete your saved API keys too?"; then run rm -f "$ROOTFS/root/.config/opencode-keys.env"; fi
if [ -d "$ROOTFS" ] && ask "Delete the whole Debian system (frees ~1 GB, removes OpenCode and ~/research inside it)?"; then run proot-distro remove debian; fi
echo "Done. Termux packages (tmux, proot-distro) were left installed."
