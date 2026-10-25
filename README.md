# OpenCode starter kit for Android (research edition)

Run [OpenCode](https://opencode.ai) (an AI assistant for the terminal) on an Android phone, set up for
**research and analysis**, and always running inside **tmux** so it keeps going when you switch apps or lock
the screen. Built for a 64-bit ARM phone with 8 GB of RAM.

**No API keys, passwords or personal data are in this repo.** It works with free models out of the box.

## What you get
- **Research skills:** deep research, market research, competitor/product analysis, SEO, search-first,
  lead intelligence, article writing. Plus the `/plan` and `/aside` commands.
- **Web search tools:** Exa and Context7 (no key needed). Tavily search and Firecrawl scraping if you add a
  free key. Add keys any time with `oc key`: see **[KEYS.md](KEYS.md)** (Gemini, OpenRouter, Tavily, Firecrawl).
- **`oc` command:** one word starts (or reattaches to) OpenCode inside tmux.
- **Phone-friendly Termux:** an extra-keys row (Esc, Tab, Ctrl, arrows, `/`, `|`) and touch scrolling.
- Reports save to your phone's **shared storage** (`Research` folder), so you can open them in any app.

## Step 1: install Termux (the terminal app)
Use the official builds, **not** the Google Play one (it is old and broken).
1. Download the `arm64-v8a` APK: **[Termux releases on GitHub](https://github.com/termux/termux-app/releases/latest)**
   (file named like `termux-app_v0.118.3+github-debug_arm64-v8a.apk`), **or** install it from
   **[F-Droid](https://f-droid.org/en/packages/com.termux/)**.
2. Open the downloaded file. Android will ask to allow "install unknown apps" for your browser/files app: allow it.
3. Pick one source and stick to it (GitHub **or** F-Droid); mixing them blocks updates.

## Step 2: install the kit
Open **Termux**, paste this, press Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/DesolateMartial553/opencode-starter-android/main/install.sh | bash
```

- Takes about 10-20 minutes and downloads ~300 MB. Keep the screen on and stay in Termux.
- When Android asks for **storage access**, tap **Allow**.
- It offers to save free API keys (optional; press Enter to skip each). You can add them later with `oc key`;
  the step-by-step guide is **[KEYS.md](KEYS.md)**.
- Want a preview first? Download the script with `curl -fsSLO <the install.sh URL above>`, then run `bash install.sh --dry-run`.

## Step 3: start it
```bash
oc
```
Type your question, e.g. *"Research the best budget phones in the UK right now, with sources"*.
Read [GETTING-STARTED.md](GETTING-STARTED.md) for more.

## Stop Android killing it (do this once)
1. **Settings > Apps > Termux > Battery > Unrestricted** (no battery optimisation).
2. Keep the **Termux notification** ("wake lock held") in the notification shade: `oc` turns it on.
3. Android 12+ may still kill background processes. If sessions vanish: Settings > Developer options >
   **Disable child process restrictions** (turn on).

## tmux cheat sheet
tmux is what keeps OpenCode alive. The prefix is **Ctrl-b**: tap `CTRL` on the extra-keys row, then `b`, then the key.

| Do this | Keys / command |
|---|---|
| Leave it running in the background | `Ctrl-b` then `d` (detach) |
| Come back | type `oc` |
| Scroll up | swipe with a finger (or `Ctrl-b` `[`, then `q` to exit) |
| New window / next / previous | `Ctrl-b c` / `Ctrl-b n` / `Ctrl-b p` |
| Split screen | `Ctrl-b "` (top/bottom), `Ctrl-b %` (left/right) |
| Second separate session | `oc new NAME` |
| List / end sessions | `oc ls` / `oc kill` |
| Plain Debian shell | `oc shell` |
| Update OpenCode | `oc update` |
| Re-test and use the fastest download mirror | `oc mirror` |
| Add / list / remove API keys | `oc key` / `oc key list` / `oc key remove NAME` |

(`oc`, `oc ls` and the others are typed in Termux. `Ctrl-b ...` works while you are inside tmux.)

## Notes for an 8 GB phone
- OpenCode with cloud models is light (roughly 300-600 MB). Don't run local AI models.
- Close heavy apps (games, many browser tabs) during long research runs.
- First start inside Debian can take 10-20 seconds.

## Troubleshooting
- **Downloads crawl (a few kB/s, ETA of hours)** - the installer already tests every Termux mirror and picks the
  fastest for your phone. To re-test later (speeds change by time and network), run `oc mirror`. If the
  installer itself is stuck, press `Ctrl-C`, run `termux-change-repo`, pick **default**, and run it again.
- **`CANNOT LINK EXECUTABLE "curl"` / `cannot locate symbol`** - Termux was left half-upgraded. Run
  `apt-get update && apt-get -y -o Dpkg::Options::=--force-confold dist-upgrade`, then run the installer again.
- **`oc: command not found`** - close and reopen Termux, or re-run the installer.
- **Installer stopped halfway** - run it again; it is safe to repeat and keeps backups.
- **"Allow storage" was missed** - run `termux-setup-storage`, then re-run the installer.
- **OpenCode won't start in Debian** - `oc shell`, then `opencode --version`. Paste any error when asking for help.
- **Undo everything** - `bash uninstall.sh` (download it from this repo).

## Maintainers
`scripts/sanitize-check.sh` scans for secrets and personal references. Run it before every push.
