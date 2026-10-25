# Free API keys (all optional)

OpenCode already works with **no keys at all** (free models, plus Exa and Context7 search with no sign-up).
Keys only make it stronger or lift limits. Everything here has a free tier and does **not** need a card unless noted.

Free-tier numbers below are what providers published or what articles reported in 2026. They change often, so
**check the provider's own dashboard** before relying on them.

## Adding a key (the easy way)
Keys are added from Termux (not inside OpenCode) with the `oc key` command:

```bash
oc key              # asks for each key you haven't set; press Enter to skip any
oc key gemini       # add or replace one key: gemini | openrouter | tavily | firecrawl
oc key list         # shows what is set (last 4 characters only)
oc key remove tavily
```

How it goes on a phone:
1. Open the provider's page below in your phone browser, sign up, and **copy** the key.
2. Switch to Termux. If OpenCode is open, press `CTRL` then `b`, then `d` to step out of it first.
3. Run `oc key gemini` (for example). **Long-press** in the Termux screen and tap **Paste**.
   Nothing shows as you paste: that is normal (it is hidden on purpose). Press Enter.
4. Restart so it takes effect: `oc kill`, then `oc`.

Keys are saved only on your phone, inside the Debian system, readable only by you. OpenCode is told never to
read that file. Never paste a key into the chat. If one leaks, delete it on the provider's site and add a new one.

## Models (the "brain")

### Google Gemini
- **Get it:** <https://aistudio.google.com/apikey> > sign in with a Google account > **Create API key** (pick or
  create a project) > copy it.
- **Free tier:** no card; limited requests per minute and per day (roughly tens to hundreds a day for Flash
  models; check the AI Studio dashboard for today's numbers). Free-tier prompts may be used by Google to improve
  its products, so don't send private or sensitive information.
- **Add:** `oc key gemini`. The kit already lists Gemini as a fallback when the free built-in models are slow.
  To make it your main model, open OpenCode and type `/models`.

### OpenRouter
- **Get it:** <https://openrouter.ai/keys> > sign up > **Create Key** > copy it.
- **Free tier:** models whose names end in `:free` cost nothing and need no card. Reported limits: about 20
  requests per minute and about 50 requests per day until you have ever bought credits (about 1,000 a day after
  buying roughly $10). Extra keys or accounts do not add capacity. Free models rotate and get busy at peak times.
- **Add:** `oc key openrouter`. The kit uses OpenRouter's free router as the last fallback.

## Research tools (better web search and reading)
These switch on extra search/scraping tools for the research skills. Exa and Context7 are already on without a key.

### Tavily (best extra pick for research)
- **Get it:** <https://app.tavily.com/home> > sign up (no card) > copy the API key on the dashboard
  (starts with `tvly-`).
- **Free tier:** reported at about 1,000 credits a month (a normal search costs 1 credit).
- **Add:** `oc key tavily`. This switches on the Tavily search tool automatically.

### Firecrawl (reads and scrapes whole web pages)
- **Get it:** <https://www.firecrawl.dev/app/api-keys> > sign up > copy the key (starts with `fc-`).
- **Free tier:** a monthly credit allowance (reported around 1,000 credits; scraping a page costs about 1).
- **Add:** `oc key firecrawl`. Firecrawl runs through Node.js, so the first time this installs Node.js inside
  Debian (a few minutes and a bigger download than the other keys). Run it on Wi-Fi.

## Already free and keyless (nothing to set up)
- **Exa** web search and **Context7** library docs: built in, no key. (An Exa account adds higher limits, but the
  kit works without one.)
- Public research data the assistant can read from the web when you ask: **Wikipedia/Wikidata**, **OpenAlex** and
  **Crossref** (papers), **arXiv**, **PubMed**, **Semantic Scholar** (a free key is optional), **World Bank**
  data, **SEC EDGAR** filings. Just name the source in your question, e.g. *"search OpenAlex for recent papers on X"*.
- Brave Search's API no longer has a true free plan (2026), so the kit doesn't use it.

## If something doesn't work
- **"key saved" but no change:** restart with `oc kill`, then `oc`. Check `oc key list`.
- **Error mentioning 401 / unauthorized:** the key was copied wrongly. Run `oc key NAME` again.
- **Error mentioning 429 / rate limit:** you hit the free limit. Wait, or let OpenCode fall back to the next model.
- **Firecrawl says npx/node not found:** run `oc shell`, then `apt-get update && apt-get install -y --no-install-recommends nodejs npm`.
- **Remove a key:** `oc key remove NAME`.
