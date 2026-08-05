#!/usr/bin/env bash
# cleanse.sh <year> [--confirm-i-reviewed-retention]
# Three-gate consented deletion of INTERMEDIATE SCRATCH ONLY for a finished season.
#
# What it deletes:  ~/tax-prep/<year>/scratch/   (extraction intermediates, temp files)
# What it KEEPS, always: the filed return PDF, sources/, data-pack.json, all ledgers,
# entry-guide.md, verification-log.md. IRS retention: 3 years minimum, 6 for
# substantial understatement — retained artifacts are the audit defense.
#
# Gates:
#   1. --confirm-i-reviewed-retention flag
#   2. RETURN_FILED.txt marker in the season dir, written BY THE USER (not the agent),
#      containing the word FILED and a date
#   3. typed confirmation at an interactive terminal
# Agents: you may prepare the user to run this. You may NOT create the marker file,
# pass the flag on the user's behalf, or pipe input to the prompt.
set -euo pipefail

YEAR="${1:?usage: cleanse.sh <year> --confirm-i-reviewed-retention}"
FLAG="${2:-}"
BASE="$HOME/tax-prep"
SEASON="$BASE/$YEAR"
TARGET="$SEASON/scratch"

[[ "$FLAG" == "--confirm-i-reviewed-retention" ]] || { echo "Gate 1 failed: missing --confirm-i-reviewed-retention" >&2; exit 1; }

# Containment: refuse to operate outside ~/tax-prep/<year>/scratch, defeat symlinks.
REAL_TARGET="$(cd "$TARGET" 2>/dev/null && pwd -P || true)"
REAL_BASE="$(cd "$BASE" && pwd -P)"
[[ -n "$REAL_TARGET" && "$REAL_TARGET" == "$REAL_BASE/$YEAR/scratch" ]] || {
  echo "Gate: target $TARGET does not resolve inside $REAL_BASE/$YEAR — refusing" >&2; exit 1; }

MARKER="$SEASON/RETURN_FILED.txt"
[[ -f "$MARKER" ]] || { echo "Gate 2 failed: $MARKER missing. Write it yourself after filing (e.g. 'FILED 2026-04-10 federal+CA accepted')." >&2; exit 1; }
grep -qi "FILED" "$MARKER" && grep -qE '20[0-9]{2}' "$MARKER" || {
  echo "Gate 2 failed: marker must contain the word FILED and a date." >&2; exit 1; }

[[ -t 0 ]] || { echo "Gate 3 failed: interactive terminal required (no piped input)." >&2; exit 1; }
echo "About to permanently delete: $REAL_TARGET"
echo "Retained: sources/, drafts/, data-pack.json, ledgers, logs (IRS retention 3-6 yrs)."
read -r -p "Type exactly 'YES DELETE SCRATCH FOR $YEAR' to proceed: " ANSWER
[[ "$ANSWER" == "YES DELETE SCRATCH FOR $YEAR" ]] || { echo "Confirmation mismatch — nothing deleted."; exit 1; }

rm -rf "$REAL_TARGET"
mkdir -p "$TARGET" && chmod 700 "$TARGET"
echo "Done. scratch/ cleared for TY$YEAR; all retention-covered artifacts kept."
