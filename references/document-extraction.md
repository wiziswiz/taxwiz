# Document Extraction — folder of PDFs → graded, source-attributed figures

## The two tiers of input

**Tier 1 — IRS wage-and-income transcript PDFs** (downloaded from the taxpayer's IRS
online account, usually named like `<Payer> <year> IRS.pdf`). One standardized
IRS-rendered form per payer, box-numbered, masked TINs. Easiest and most reliable source.
**Known limitation printed on the form itself: grayed-out state/local boxes are omitted.**
If state withholding matters (CA return), the payer's original form is required — flag it.

**Tier 2 — payer-branded documents.** W-2s, standalone 1099s, K-1s, 1098s, 5498s, and the
boss fight: **consolidated brokerage 1099s** (Fidelity/Schwab/Morgan Stanley composites,
20–50+ pages, layout differs per institution and per year).

## Order of operations

1. **Classify before extracting.** Identify the exact form variant (1099-DIV vs INT vs B
   vs OID vs G vs R vs NEC vs K; W-2; K-1 1065 vs 1120-S; 1098 vs 1098-T; 5498) and the
   owner (taxpayer / spouse / joint) before reading a single box. Box numbers mean
   different things on different variants — variant-blind extraction produces silently
   wrong mappings.
2. **Segment consolidated 1099s** into their component forms (1099-INT section, 1099-DIV
   section, 1099-B sections by holding period and covered/noncovered status, 1099-MISC).
   Then extract each component against its own schema.
3. **Extract to the variant schema** (below). Two independent passes per document —
   different reading order/method on the second pass. Field-level agreement = confident;
   disagreement = re-read carefully, and if still uncertain mark `"confidence": "low"`
   and list it in the coverage report for human eyes.
4. **Reconcile totals pages against detail pages** on consolidated 1099s. They disagree
   more often than you'd expect (amended pages, accrued-interest adjustments). The detail
   pages win; note the discrepancy.
5. **Reconcile across documents**: W-2 box 1 vs final pay stub YTD (within ~$100);
   sum of 1099-INT box 1 across payers vs what the entry guide will claim; brokerage
   1099-B totals vs what lands on Schedule D.

## 1099-B rows are sacred

Never flatten or aggregate lots. Preserve per row: description, quantity, acquisition
date, sale date, proceeds, cost basis, wash-sale disallowed amount, covered/noncovered,
short/long term, box category (A/B/C/D/E/F). FreeTaxUSA supports summary entry per box
category with mailed 8453/8949 for noncovered — decide the entry strategy from the data,
don't discover it mid-entry.

## Evidence grades

| Grade | Source | Filing policy |
|---|---|---|
| A | The actual form PDF (IRS transcript or payer original) | File on it |
| B | Payer portal screenshot / year-end statement | File, note in ledger |
| C | Bank/brokerage transaction records reconstructed | File only with user sign-off |
| D | User recollection ("I think about $500") | **Never file. Obtain the document.** |

Every figure in the data pack carries its grade and source file path. The pre-submit
validator refuses D-grade income.

## Normalization rules (encode them or the diff drowns)

- Cents → whole dollars per IRS rounding (round each document's total, not each row,
  unless the software does otherwise — match FreeTaxUSA's behavior and note which).
- Sub-$0.50 interest items: still inventory them; note when a payer needn't issue a
  1099-INT (<$10) but income is still reportable.
- Foreign amounts: record original + USD + conversion source.
- Negative/adjustment values (accrued interest paid, return of capital): keep signed,
  never silently drop.

## Redaction discipline

In conversation and any file outside `~/tax-prep/`: names → role labels (taxpayer/
spouse), SSN → `[SSN-last4:XXXX]`, account numbers → last 4. Full values live only in
`data-pack.json` inside the 700-mode season directory. Do not read a full SSN aloud in
any chat that syncs anywhere.

## Household profile (`~/tax-prep/profile.md`)

The compounding asset. After each season, update: expected payers per person (with form
types), entities (S-corp/partnership → expect K-1 timing), typical deduction categories
(charitable, 1098-T pattern), state footprint. At ingest, diff this season's ledger
against the profile: **"expected but missing" is the highest-value output** — a missing
1099 found in February costs nothing; found in an IRS notice, it costs penalties.

Corrected-form watch: brokerages routinely amend consolidated 1099s in Feb–Mar. If filing
before April, record the original's date and check for corrections before the user
submits.
