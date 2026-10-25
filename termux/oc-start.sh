#!/usr/bin/env bash
# Runs INSIDE the Debian proot (installed to /root/.oc-start.sh by install.sh and launched by `oc`).
export PATH="$HOME/.opencode/bin:/usr/local/bin:$PATH"
mkdir -p "$HOME/research"
cd "$HOME/shared/Research" 2>/dev/null || cd "$HOME/research" || cd "$HOME"
# optional API keys saved by the installer (never part of the repo)
if [ -f "$HOME/.config/opencode-keys.env" ]; then set -a; . "$HOME/.config/opencode-keys.env"; set +a; fi
if ! command -v opencode >/dev/null 2>&1; then
  echo "OpenCode is not installed in Debian. Re-run the installer, or try: oc update"
  exec bash -l
fi
opencode
code=$?
echo
echo "OpenCode exited (code $code). Press Enter to close this session."
read -r _
