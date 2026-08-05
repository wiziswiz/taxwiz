# Catch-Up Protocol — multiple unfiled years, personal + entity

> **⚠ Verify-live gate applies to every penalty figure and deadline below** — log checks
> in the season's `verification-log.md`. This file encodes the *strategy*; the numbers rot.

## Phase 0 — Situation report (before any preparation)

Build the delinquency map, one row per (year × return):

| Year | Return | Filed? | Extension? | Docs on hand | K-1 dependency | Refund or owe (guess) |
|---|---|---|---|---|---|---|

Sources: the user's tax folders (year dirs + return PDFs = filed evidence), IRS online
account (filed-return + wage-and-income transcripts — the user already downloads these),
state FTB account. If filed status is uncertain for a year, the transcript settles it —
never guess.

## Sequencing rules (violate none of these)

1. **Entity before personal, per year.** 1120-S/1065 produce the K-1s and W-2s the 1040
   consumes. Corp preparer engagement is therefore the critical path — start it first.
2. **Oldest year first** within each track. Carryforwards (capital loss, NOL, credits)
   flow forward; a younger year prepared first is built on guessed carryforwards and
   will be redone.
3. **Refund years have a shelf life**: the refund claim window is generally 3 years from
   the original due date. Compute the expiry for every probable-refund year FIRST and
   prioritize any that are close — an expired refund is money incinerated.
4. **Each completed year updates the carryforward ledger before the next begins.**

## Penalty triage (frame honestly, don't catastrophize)

- If a year is a **refund year, there is no federal failure-to-file penalty** — filing
  late costs nothing but the time-value and the expiring claim window. Many catch-up
  years turn out to be refunds; establish this early, it defuses panic.
- Owe years: failure-to-file (~5%/mo of unpaid tax, cap ~25%) dwarfs failure-to-pay
  (~0.5%/mo). Filing stops the big one even if the user can't pay yet — file first,
  arrange payment second (installment agreement is routine).
- **S-corp/partnership late-filing penalties are per-shareholder per-month** and accrue
  even with zero tax due — this is usually the largest and most urgent exposure in a
  mixed catch-up. Quantify it immediately for the corp preparer conversation.
- **First-Time Abatement** exists for a first offense year; reasonable-cause relief may
  apply beyond it. Note eligibility per year; the request happens after filing.
- Multiple unfiled years with tax due + IRS letters already arriving = "STOP and hand to
  a human professional" territory for the negotiation part; TaxWiz still does all the
  document and preparation legwork underneath.

## Mechanics that differ from a current-year filing

- **Prior-year FreeTaxUSA returns cannot be e-filed** — prepared online, then printed,
  signed, and mailed (certified mail, return receipt; keep the receipt in the season
  dir). Each tax year is a separate FreeTaxUSA year-site (`taxes<year>` in the URL).
- E-file is generally only open for the current season plus the two prior years via
  authorized channels; assume mail for anything older.
- State (CA FTB) has its own delinquency track and its own (longer) refund/assessment
  windows — map it per year alongside federal, don't mirror federal assumptions.
- Wage-and-income transcripts are the safety net for missing docs, but remember: they
  omit state boxes and may lack basis for 1099-B — brokerage originals still needed
  where those matter.
- Health-coverage forms (1095) and year-specific law differences matter per year — the
  verify-live rule applies *per season being prepared*, not just the current one.

## The catch-up loop

For each (year × return) in dependency order:
`ingest` that year's folder → intake gaps → entity years: handoff package to preparer,
wait for K-1 → personal years: `file` mode against that year's FreeTaxUSA site →
print/sign/mail where e-file is closed → log mailing proof → update carryforward ledger
→ next year. One season directory per year (`~/tax-prep/<year>/`), one shared profile.

Progress artifact: `~/tax-prep/catch-up-plan.md` — the delinquency map plus per-year
status (`blocked-on-K1 / docs-incomplete / ready / mailed / accepted`), updated every
session. This file IS the onboarding for every future session: a bare `/taxwiz` during a
catch-up reads it and resumes.
