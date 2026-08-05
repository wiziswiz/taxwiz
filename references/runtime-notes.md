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

| Headless-safe (cron / OpenClaw / Hermes autonomous) | Human-only in EVERY mode |
|---|---|
| `ingest`: folder walk, classification, extraction, data pack | MFA codes and captcha |
| Engine runs: OpenTax, OpenTaxSolver, Aiwyn cross-checks | The $15.99 state paywall / any payment screen |
| PDF parse + line diff of a downloaded draft | Prior-year AGI + PIN + "Send Tax Return" |
| `audit` of prior-year PDFs | Proceeding past a $100+ deviation |
| Watching a downloads/docs folder for new tax forms | Writing the RETURN_FILED.txt marker |
| `estimates` deadline reminders (CA 30/40/0/30) | |

Data entry on freetaxusa.com sits between these columns: **attended by default**
(user watching the browser), or unattended-with-terminal-narration under the opt-in
hands-off mode — per-season recorded consent required, protocol and credential flow in
`hands-off-entry.md`. It is never cron-autonomous: a responsive human at the terminal
is part of the mode.

Never headless-scrape freetaxusa.com and never apply bot-evasion (stealth plugins, UA
spoofing, automation-flag hiding). Be honest about the terms: FreeTaxUSA's ToS prohibits
automated access, full stop — nothing here is "sanctioned" by the site. The default mode
is therefore GUIDED: the agent reads the page and tells the user exactly what to type
where, and the user does the typing. Assisted entry (agent fills fields in the user's
own watched, logged-in session) is the user's informed choice: surface the ToS fact once
per season and let them decide — never make that choice for them. Unattended entry
exists only as the separately-consented hands-off mode (`hands-off-entry.md`); outside
that recorded consent, stop assisting the moment they aren't watching.

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
