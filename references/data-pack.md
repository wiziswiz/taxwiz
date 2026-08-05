# Data Pack — the contract between ingestion, engines, entry, and verification

`~/tax-prep/<year>/data-pack.json` is the single source of truth. Everything downstream
(entry guide, engine runs, PDF diff) consumes it; nothing downstream invents figures.
Validate with `scripts/validate-pack.py` before any downstream use.

## Schema (shape, not straitjacket — extend fields, never drop provenance)

```json
{
  "tax_year": 2025,
  "generated": "2026-02-07",
  "filing_status": "married_filing_jointly",
  "taxpayers": [
    {"role": "taxpayer", "name_ref": "T", "ssn_last4": "1234"},
    {"role": "spouse",   "name_ref": "S", "ssn_last4": "5678"}
  ],
  "documents": [
    {
      "id": "doc-001",
      "file": "IRS website 2025/Morgan Stanley 2025 IRS.pdf",
      "form": "1099-DIV",
      "payer": "Morgan Stanley Capital Management LLC",
      "owner": "taxpayer",
      "grade": "A",
      "state_boxes_missing": true,
      "fields": {"1a_ordinary_dividends": 9, "1b_qualified_dividends": 9},
      "extraction": {"passes_agreed": true, "low_confidence_fields": []}
    }
  ],
  "lines_1040": [
    {"line": "3b", "description": "Ordinary dividends",
     "amount": 9, "sources": ["doc-001"], "schedule_b_required": false}
  ],
  "carryforwards_in": {"capital_loss_st": 0, "capital_loss_lt": 0, "source": "2024 return + ledger"},
  "expected_totals": {
    "engine": "opentax|opentaxsolver|aiwyn",
    "agi": null, "taxable_income": null, "total_tax": null,
    "federal_refund": null, "state_refund": null
  },
  "coverage": {
    "expected_missing": ["AOD Credit Union 1099-INT (in profile, not found this year)"],
    "new_this_year": [],
    "needs_original_for_state": ["doc-007"],
    "unresolved_low_confidence": []
  },
  "verify_before_submit": [
    "Corrected-1099 check for Fidelity/Morgan Stanley after Mar 1",
    "Prior-year AGI from 2024 Form 1040 line 11"
  ]
}
```

## Rules

- **Every `lines_1040` amount lists `sources`** — document IDs, or `"user-confirmed"`
  with date for the rare figure with no document. No orphan numbers.
- `expected_totals` is written by a deterministic engine run, never by the model.
- The pack is per-year and immutable-ish: corrections append a `revisions` entry rather
  than silently overwriting, so the entry guide and diff can cite what changed.
- SSNs: last-4 only in the pack; full values are typed by the user or entered during the
  attended session, never stored here.

## Entry guide (`entry-guide.md`) — generated from the pack, before the browser opens

Per FreeTaxUSA section, in site order:

```markdown
## Income → Dividend Income (Form 1099-DIV)          [status: pending]
Rows to exist when done: 2 (Morgan Stanley — taxpayer; Fidelity — spouse)
| Field | Value | Source |
|---|---|---|
| Payer name | Morgan Stanley Capital Management LLC | doc-001 |
| Box 1a | 9 | doc-001 |
| Box 1b | 9 | doc-001 |
Expected after this section: column total $9 for 2025; Federal refund unchanged ±$5.
```

Entry marks each section `pending → entered → verified`. "Verified" means the site's
year-column total matches and the header refund moved as predicted. A section that
changes the refund unexpectedly gets investigated **before** the next section starts —
FreeTaxUSA silently recomputes downstream answers from earlier inputs.

## The closing diff (after PDF download)

Three assertions, all mandatory:
1. **Pack → PDF**: every `lines_1040` amount appears on the right line.
2. **PDF → pack**: every nonzero PDF line traces back to pack sources (catches
   double-entry and phantom entries).
3. **Form presence**: expected schedules/forms (from pack contents: Sch B if >$1,500
   interest/dividends, Sch D + 8949 if 1099-B rows, Sch 1/2/3 as implied…) all exist in
   the PDF. A missing form with correct math is still an unfileable return.

Output a diff report: matches, discrepancies with investigate-notes, missing forms.
Every discrepancy is "investigate" — experience says the worksheet is wrong about as
often as the entry.
