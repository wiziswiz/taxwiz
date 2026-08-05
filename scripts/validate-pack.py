#!/usr/bin/env python3
"""validate-pack.py <data-pack.json> — structural gate before any downstream use.

Checks provenance, evidence grades, and starter/placeholder rot. Exit 0 = pass.
This is a structural backstop, not a substitute for the engine cross-check or the
closing PDF diff.
"""
import json
import sys

PLACEHOLDERS = ("TODO", "FIXME", "PLACEHOLDER", "<fill", "XXX", "taxwiz:starter")


def fail(msgs):
    for m in msgs:
        print(f"FAIL: {m}")
    sys.exit(1)


def main(path):
    errors, warnings = [], []
    with open(path) as f:
        raw = f.read()
    for p in PLACEHOLDERS:
        if p in raw:
            errors.append(f"placeholder text {p!r} present — pack is not finished")
    pack = json.loads(raw)

    for key in ("tax_year", "filing_status", "documents", "lines_1040"):
        if key not in pack:
            errors.append(f"missing required key: {key}")
    if errors:
        fail(errors)

    doc_ids = {d.get("id") for d in pack["documents"]}
    for d in pack["documents"]:
        if d.get("grade") not in ("A", "B", "C", "D"):
            errors.append(f"{d.get('id')}: missing/invalid evidence grade")
        lo = (d.get("extraction") or {}).get("low_confidence_fields") or []
        if lo:
            warnings.append(f"{d.get('id')}: low-confidence fields {lo} — resolve before filing")

    for line in pack["lines_1040"]:
        srcs = line.get("sources") or []
        if not srcs:
            errors.append(f"line {line.get('line')}: no sources — orphan number")
        for s in srcs:
            if s not in doc_ids and not str(s).startswith("user-confirmed"):
                errors.append(f"line {line.get('line')}: unknown source {s!r}")
        grades = {d.get("grade") for d in pack["documents"] if d.get("id") in srcs}
        if "D" in grades:
            errors.append(f"line {line.get('line')}: rests on D-grade evidence — obtain the document")

    ssn_like = [c for c in raw.split('"') if c.replace("-", "").isdigit() and len(c.replace("-", "")) == 9]
    if ssn_like:
        errors.append("9-digit values found — pack must hold last-4 only, never full SSNs")

    if errors:
        fail(errors)
    for w in warnings:
        print(f"WARN: {w}")
    n_docs, n_lines = len(pack["documents"]), len(pack["lines_1040"])
    print(f"OK: {n_docs} documents, {n_lines} 1040 lines, provenance intact")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    main(sys.argv[1])
