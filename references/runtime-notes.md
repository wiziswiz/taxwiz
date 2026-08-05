# Runtime Notes — running TaxWiz on Claude Code, Codex, OpenClaw, Hermes

## Canonical source & deployment

Canonical skill lives at `~/.agents/skills/taxwiz/`. Adapters:

```
~/.claude/skills/taxwiz    -> ~/.agents/skills/taxwiz          # dir symlink
~/.codex/skills/taxwiz     -> ~/.agents/skills/taxwiz          # dir symlink
~/.clawdbot/skills/taxwiz  -> ~/.agents/skills/taxwiz          # dir symlink
~/.hermes/skills/finance/taxwiz/       # REAL directory (Hermes rglob skips symlinked dirs)
   ├── SKILL.md   -> ~/.agents/skills/taxwiz/SKILL.md          # FILE symlink works
   ├── references -> ~/.agents/skills/taxwiz/references        # subdir symlinks read fine
   ├── scripts    -> ~/.agents/skills/taxwiz/scripts
   ├── subagents  -> ~/.agents/skills/taxwiz/subagents
   └── assets     -> ~/.agents/skills/taxwiz/assets
```

Quirks: Hermes caches its skill list at session start — new/edited skill needs a fresh
session. OpenClaw precedence is workspace `skills/` → `~/.clawdbot/skills` → bundled;
avoid name collisions with bundled skills. OpenClaw's frontmatter parser is
single-line-keys-only — keep `description` a single-line quoted string and `metadata` a
single-line JSON object (as this skill's frontmatter already does). To ship to the Mac
mini's OpenClaw: copy into the mini's `~/.clawdbot/skills/` (the Obsidian `Clawd/` folder
syncs memory, NOT skills).

## Browser tool adapter table

The playbook (`freetaxusa-playbook.md`) uses generic Playwright-MCP names. Translate:

| Playbook name | Claude Code (playwright plugin) | Claude Code (claude-in-chrome) | OpenClaw / Hermes |
|---|---|---|---|
| `browser_snapshot` | `mcp__plugin_playwright_playwright__browser_snapshot` | `mcp__claude-in-chrome__read_page` | whatever browser tool the agent exposes; prefer accessibility/DOM reads |
| `browser_click` | `..._browser_click` | `mcp__claude-in-chrome__computer` (click) | " |
| `browser_fill_form` | `..._browser_fill_form` | `mcp__claude-in-chrome__form_input` | " |
| `browser_navigate` | `..._browser_navigate` | `mcp__claude-in-chrome__navigate` | " |
| `browser_take_screenshot` | `..._browser_take_screenshot` | `mcp__claude-in-chrome__computer` (screenshot) | " |

Prefer **claude-in-chrome** in Claude Code: it drives the user's real Chrome with their
real login — no separate profile, no bot fingerprint, inherently attended. Playwright
plugin opens its own browser; if used, run headed and let the user log in manually.

## Attended vs headless — the hard split

| Headless-safe (cron / OpenClaw / Hermes autonomous) | Attended-only (user watching) |
|---|---|
| `ingest`: folder walk, classification, extraction, data pack | Anything on freetaxusa.com |
| Engine runs: OpenTax, OpenTaxSolver, Aiwyn cross-checks | Login/MFA (always the user's hands) |
| PDF parse + line diff of a downloaded draft | Clicking Save and Continue |
| `audit` of prior-year PDFs | The $15.99 state paywall screen |
| Watching a downloads/docs folder for new tax forms | Prior-year AGI + PIN + "Send Tax Return" |
| `estimates` deadline reminders (CA 30/40/0/30) | Any payment screen |

Never headless-scrape freetaxusa.com and never apply bot-evasion (stealth plugins, UA
spoofing, automation-flag hiding). The site's ToS prohibits automated access and it WAFs
plain fetches; the only sanctioned pattern is assisting inside the user's own watched,
logged-in session — or falling back to guided mode: read the page, tell the user exactly
what to type where, verify the result.

## Good OpenClaw/Hermes cron uses

- Jan–Mar: watch the user's tax-docs folder + email for new forms; update `source-ledger.md`
  and nag about expected-but-missing payers from `profile.md`.
- Quarterly: estimated-payment reminders with amounts from the latest pack.
- Post-filing: recompute the pack against the filed PDF if an amended form arrives
  (corrected 1099s land Feb–Apr; brokerages love February amendments).

## Note on the name "Hermes"

The abandoned `schwarztim/freetaxusa-mcp` project has an auth component it calls a
"Hermes broker" — unrelated to Nous hermes-agent. If you encounter that repo, don't
conflate them; its income/deduction tools are unimplemented stubs and its concurrency
mutex is broken. Its one reusable idea is the `?sid=N` page-numbering model, already
folded into the playbook.
