# Your first research session (Android)

## 1. Start
In Termux type `oc`. After a few seconds OpenCode opens. Type your question and press Enter.

Tips for typing on a phone:
- The row above the keyboard has `ESC`, `TAB`, `CTRL`, arrows, `/` and `|`. Use `/` to open the command menu.
- In Termux the **volume-down** key works as CTRL (volume-down + b = Ctrl-b).

## 2. Good first prompts
- *"Research the best budget phones in the UK right now. Compare 5 options in a small table and cite sources."*
- *"Use deep-research to find out how X works and what the main criticisms are."*
- *"Competitor research: who are the main alternatives to X, and what do they charge?"* (market-research)
- *"Audit the SEO of example.com and list the 5 biggest fixes."* (seo)
- *"Find existing tools or libraries for Y before we build anything."* (search-first)

You can name a skill (e.g. "use market-research") or just describe the job: it picks the right one.

## 3. Keep the answer phone-sized
Ask for *"a 5-line summary first"*. The kit is set up to answer briefly and cite sources as links, separating
facts, guesses and unknowns.

## 4. Saving a report
Say *"save this as a report"*. It writes a Markdown file to your phone's shared storage:
**Internal storage > Research > `<topic>-<date>.md`**. Open it in any file manager, or share it.

## 5. Leave it running
Press `CTRL` then `b`, then `d` to detach. OpenCode keeps working in the background. Type `oc` later to
come back right where you were. (Android may still close Termux if battery settings are strict: see the README.)

## 6. Plan before big jobs
Type `/plan` first for anything with many steps; press `Tab` to switch between Plan (read-only thinking) and
Build (makes changes).

## 7. Models and keys
- Free models work with no key. If one is slow or fails, OpenCode automatically tries the next.
- For stronger models or better research search, add free keys from Termux with `oc key`
  (Gemini, OpenRouter, Tavily, Firecrawl). Step-by-step phone instructions are in [KEYS.md](KEYS.md).
- `oc key list` shows what is set. Restart with `oc kill`, then `oc`, after adding one.
- Never paste keys into the chat.
