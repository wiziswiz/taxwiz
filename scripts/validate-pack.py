#!/usr/bin/env python3
"""validate-pack.py <data-pack.json> — structural gate before any downstream use.

Checks provenance, evidence grades, waivers, and starter/placeholder rot.
Exit 0 = pass. Warnings always print, pass or fail. This is a structural backstop,
not a substitute for the engine cross-check or the closing PDF diff.
"""
import json
import re
import sys

PLACEHOLDERS = ("TODO", "FIXME", "PLACEHOLDER", "<fill", "taxwiz:starter")
# SSN-shaped: 3-2-4 digits with dash/space/no separator. Bare 9-digit runs are only a
# warning (EINs and reference numbers are 9 digits too — human eyes decide).
SSN_RE = re.compile(r"\b\d{3}[- ]\d{2}[- ]\d{4}\b")
NINE_RE = re.compile(r"\b\d{9}\b")


def walk_numbers(node, path="$"):
    if isinstance(node, dict):
        for k, v in node.items():
            yield from walk_numbers(v, f"{path}.{k}")
    elif isinstance(node, list):
        for i, v in enumerate(node):
            yield from walk_numbers(v, f"{path}[{i}]")
    elif isinstance(node, (int, float)):
        yield path, node


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
    docs = pack.get("documents") or []
    lines = pack.get("lines_1040") or []
    if not docs:
        errors.append("documents[] is empty — an empty pack is not a valid pack")
    if not lines:
        errors.append("lines_1040[] is empty — nothing to file is a failure, not a pass")

    doc_ids = set()
    for i, d in enumerate(docs):
        did = d.get("id")
        if not did:
            errors.append(f"documents[{i}]: missing id")
            continue
        doc_ids.add(did)
        if d.get("grade") not in ("A", "B", "C", "D"):
            errors.append(f"{did}: missing/invalid evidence grade")
        lo = (d.get("extraction") or {}).get("low_confidence_fields") or []
        if lo:
            warnings.append(f"{did}: low-confidence fields {lo} — resolve before filing")

    for line in lines:
        label = f"line {line.get('line')}"
        srcs = line.get("sources") or []
        if not srcs or any(s is None for s in srcs):
            errors.append(f"{label}: missing/null sources — orphan number")
            continue
        for s in srcs:
            s = str(s)
            if s in doc_ids:
                continue
            if s.startswith("user-confirmed"):
                if not str(line.get("waiver") or "").strip():
                    errors.append(
                        f"{label}: user-confirmed source without a 'waiver' field — "
                        "recollection is D-grade; obtain the document or record the "
                        "user's typed waiver (see references/data-pack.md)"
                    )
                else:
                    warnings.append(f"{label}: filed on user waiver, no document — flag at review")
            else:
                errors.append(f"{label}: unknown source {s!r}")
        grades = {d.get("grade") for d in docs if d.get("id") in srcs}
        if "D" in grades:
            errors.append(f"{label}: rests on D-grade evidence — obtain the document")

    # PII: SSN-shaped strings are a hard fail; bare 9-digit runs and 9-digit JSON
    # numbers in ssn-ish keys are called out for human eyes.
    if SSN_RE.search(raw):
        errors.append("SSN-formatted value (###-##-#### / ### ## ####) found — last-4 only, ever")
    for pth, num in walk_numbers(pack):
        if isinstance(num, int) and 100_000_000 <= num <= 999_999_999 and "ssn" in pth.lower():
            errors.append(f"{pth}: 9-digit number in an SSN-named field — last-4 only, ever")
    bare = [m for m in NINE_RE.findall(raw)]
    if bare:
        warnings.append(f"{len(bare)} bare 9-digit value(s) present (EIN? reference no.?) — confirm none is an SSN")

    for w in warnings:
        print(f"WARN: {w}")
    if errors:
        for e in errors:
            print(f"FAIL: {e}")
        sys.exit(1)
    print(f"OK: {len(docs)} documents, {len(lines)} 1040 lines, provenance intact")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    main(sys.argv[1])
