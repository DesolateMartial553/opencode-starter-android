#!/usr/bin/env bash
# Runs INSIDE the Debian proot (installed to /root/.oc-start.sh by install.sh and launched by `oc`).
export PATH="$HOME/.opencode/bin:/usr/local/bin:$PATH"
mkdir -p "$HOME/research"
# reports land in the phone's shared storage when it is linked, otherwise inside Debian
cd "$HOME/shared/Research" 2>/dev/null || cd "$HOME/research" || cd "$HOME"
# optional API keys saved by the installer (never part of the repo)
if [ -f "$HOME/.config/opencode-keys.env" ]; then set -a; . "$HOME/.config/opencode-keys.env"; set +a; fi
if ! command -v opencode >/dev/null 2>&1; then
  echo "OpenCode is not installed in Debian."
  echo "In Termux: run  oc doctor  (or  oc update  to install it again)."
  echo "Press Enter to close this window."
  read -r _ || true
  exit 1
fi
started=$SECONDS
opencode
code=$?
ran=$((SECONDS - started))
echo
if [ "$code" -eq 0 ]; then
  echo "OpenCode closed. Come back any time with:  oc"
elif [ "$ran" -lt 15 ]; then
  # exits this early are a crash, not a normal quit: say so, because the screen is already gone
  echo "OpenCode crashed on start (code $code, after ${ran}s)."
  echo "In Termux: run  oc doctor  and screenshot it, and try  oc update  for a newer version."
else
  echo "OpenCode stopped (code $code). In Termux: run  oc doctor  for a health check."
fi
echo "Press Enter to close this window."
read -r _ || true
