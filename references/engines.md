# Deterministic Engines — independent calculation before and after entry

The model never does tax arithmetic. Pick engines by role; verify availability at
session start (`opentax version`, `which ots_*`, MCP tool listing) rather than assuming.

## Roles

| Engine | Role | Why |
|---|---|---|
| **OpenTax** (filedcom/opentax) | Primary calculation of `expected_totals` | Open-source federal 1040 engine, validates against IRS MeF business rules, exports filled PDFs + MeF XML; JSON-in/JSON-out CLI built for agents. Federal only. AGPL-3.0. |
| **OpenTaxSolver** | Independent second opinion | Shares zero code with anything else here; maintained yearly (TY2025 current); matches commercial packages "within a dollar or so". C program, text input files. |
| **Aiwyn MCP** | Cross-check + PDF when connected | Hosted deterministic engine, no auth: `claude mcp add --transport http --scope user aiwyn-tax https://mcp.columnapi.com/mcp` (config lands in `~/.claude.json`). Full conventions in `references/aiwyn.md`. Cannot e-file. |
| **FreeTaxUSA** | The filing compiler + state return | The only path to e-file. Its downloaded PDF is ground truth for what would be filed. |

Install OpenTax: download https://raw.githubusercontent.com/filedcom/opentax/main/install.sh, review it, then run it (never pipe curl straight to sh; pin a commit if scripting this)
(or the Claude Code plugin: `/plugin marketplace add filedcom/opentax` →
`/plugin install opentax@opentax`). Confirm the engine's tax-year coverage matches the
season before trusting it.

**PII rule for hosted engines (Aiwyn or any remote MCP):** calculations don't need the
real SSN — send a synthetic placeholder by default. Real SSN only with explicit
same-session user consent, call-time only, never persisted. See the privacy gate in
`aiwyn.md` §8C.

## Reconciliation thresholds

Compare AGI, taxable income, total tax, SE tax, total payments, refund/owed:

- **≤ $1 per line** — rounding; accept.
- **$2–$99** — note it, find the cause if cheap (usually a rounding-method difference;
  record which engine rounds where in the verification log).
- **≥ $100** — STOP. Something is materially wrong: a missing document, a variant
  misclassification, an unsupported form, or an engine coverage gap. Root-cause before
  any entry continues.
- **Engines disagree with each other ≥ $100 after re-check** — check form-coverage gaps
  first (NIIT, Additional Medicare, AMT, QBI are the usual suspects — an engine that
  doesn't model Form 8959/8960 isn't wrong, it's incomplete). If genuinely
  irreconcilable: STOP, human professional.

## Cross-model check (impact > ~$5k)

For high-stakes judgments (entity treatment, deduction eligibility, carryforward
character — not arithmetic), pose the same precisely-worded question independently to a
second model (Codex lane if available) without sharing the first answer. Disagreement is
the signal, not a vote: route any current-law disagreement to live IRS/FTB sources and
log the resolution in `verification-log.md`. Real catches this pattern has produced:
SEP-IRA 20%-vs-25% self-employed rate, stale standard mileage rate, outdated standard
deduction.

## State (CA)

OpenTaxSolver ships a California module -- use it as the independent CA cross-check. Also compare FreeTaxUSA's CA result vs
the pack's CA expectations built from `references/states/CA.md` figures **after**
verifying them against ftb.ca.gov (that file hard-codes a prior year's numbers — treat
as shape, verify live, log it). CA quirks that bite: estimated payments are 30/40/0/30
not equal quarters; $1M+ AGI loses prior-year safe harbor; PTE elective tax is 9.3% and
excludes the 1% Mental Health Services Tax.
