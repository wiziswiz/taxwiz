# TaxWiz 🧾

**Do your U.S. taxes with an AI agent that double-checks everything — and never clicks
"submit" for you.**

TaxWiz is an agent skill for FreeTaxUSA that works in **Claude Code, Codex, OpenClaw,
and Hermes** from one install. You hand it a folder of tax documents; it reads them,
builds your return line-by-line with sources for every number, helps you enter it all
into FreeTaxUSA in your own browser, and then verifies the draft PDF against an
independent calculation before you sign.

## Get started in 2 minutes

**1. Install** (clone once, link into whichever agents you use):

```bash
git clone https://github.com/wiziswiz/taxwiz ~/.agents/skills/taxwiz

ln -sfn ~/.agents/skills/taxwiz ~/.claude/skills/taxwiz     # Claude Code
ln -sfn ~/.agents/skills/taxwiz ~/.codex/skills/taxwiz      # Codex
ln -sfn ~/.agents/skills/taxwiz ~/.clawdbot/skills/taxwiz   # OpenClaw
```

<details><summary>Hermes (needs one extra step — click to expand)</summary>

Hermes can't see symlinked folders, so give it a real folder with linked files:

```bash
mkdir -p ~/.hermes/skills/finance/taxwiz
ln -sf  ~/.agents/skills/taxwiz/SKILL.md ~/.hermes/skills/finance/taxwiz/SKILL.md
for d in references scripts subagents assets; do
  ln -sfn ~/.agents/skills/taxwiz/$d ~/.hermes/skills/finance/taxwiz/$d
done
```
Then start a fresh Hermes session (it caches its skill list on startup).
</details>

**2. Say the magic words:**

```
/taxwiz
```

or just *"help me with my taxes."*

**3. Hand it your documents.** It will ask you to point it at a folder (it never goes
digging through your computer on its own). That's the whole onboarding — everything
else, from working directories to calculation engines, sets itself up when first needed.

## What can it do for me?

| You say… | TaxWiz does… |
|---|---|
| *"Here's my folder of tax docs for 2025"* | Reads every W-2/1099/K-1 (even 40-page brokerage statements), tells you which documents are **missing** based on last year, and builds a verified worksheet with a source for every dollar. |
| *"Let's file it"* | Plans every FreeTaxUSA screen before the browser opens, helps you enter it in **your** logged-in session, watches the running refund for surprises, then diffs the draft PDF line-by-line against the worksheet. You review and click Send. |
| *"I'm three years behind"* | Builds a year-by-year catch-up plan in the right order (business K-1s first, oldest year first, expiring refunds prioritized), gives you honest penalty math (filing late is far cheaper than you fear — refund years cost nothing), and tracks progress so you can chip away in short sessions. |
| *"Did my old CPA miss anything?"* | Cross-year audit of prior returns: dropped carryforwards, missed deductions, errors worth amending — with dollar impact, while the amendment window is still open. |
| *"An IRS letter just arrived"* | Decodes the notice and drafts a response plan. (Real audit? It stops and tells you to get a professional.) |
| *"What do I owe this quarter?"* | Estimated-payment amounts and deadlines, including state quirks like California's uneven 30/40/0/30 schedule. |
| *"Help with my parents' taxes"* | Keeps each household's documents and workspace fully separate — nothing ever blends between returns. |

## What it will never do

- ❌ Click **Submit**, **Buy**, or **Send Tax Return** — the final click is always yours
- ❌ Ask for or store your FreeTaxUSA password (you log in; it assists while you watch)
- ❌ Trust its own math — every total comes from a deterministic tax engine, checked twice
- ❌ File a number nobody can prove ("I think around $500" gets flagged, not filed)
- ❌ Scan your computer for documents uninvited, or touch anyone else's tax records
- ❌ Run headless against freetaxusa.com or sneak past bot detection

## How it stays safe with your data

Everything lives in `~/tax-prep/` — locked to your user account (mode 700), gitignored,
never synced anywhere by the skill. Documents for anyone outside the household you're
filing get quarantined by name, never read into the return. When a season is done, a
consented cleanup wipes the scratch files while keeping what the IRS expects you to
retain (3–6 years).

## Design lineage & credits

- FreeTaxUSA browser playbook, Aiwyn engine notes, verification protocol, common-errors
  library, and carryforward ledger derive from **Jeffrey's**
  `tax-return-preparation-and-advice-generic` and `wills-and-estate-planning-skill` —
  published here with his permission; the mode-router/evidence-grading architecture
  follows his estate skill's design.
- "Build the 1040 twice and diff the PDF" methodology after Dzianis Vashchuk's
  *Vibe Engineering: I built my 1040 twice on purpose*.
- Data-pack architecture informed by the India ITR agent-skill ecosystem
  (NidheeshJain/itr-prep-skill). Engines: filedcom/opentax, OpenTaxSolver, Aiwyn.
  `?sid=N` page model observed by schwarztim/freetaxusa-mcp.

## Disclaimer

TaxWiz helps you prepare **your own** return, with you reviewing and submitting it. It
is not a tax professional and this is not tax advice. FreeTaxUSA's terms prohibit
automated access, so this skill only assists inside your attended, logged-in session and
refuses headless or evasive use. Tax rates and thresholds in the references are
templates — the skill must verify current-year law against official sources and log
every check. When it tells you to see a professional, listen to it.

## License

MIT. Reference material derived from Jeffrey's skills included with permission.
