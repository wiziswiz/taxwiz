#!/usr/bin/env bash
# creds.sh store|status|email|paste-password|delete
# Opt-in FreeTaxUSA credential handling via the macOS Keychain
# (see references/hands-off-entry.md).
#
# Design goal: the password NEVER appears in agent context, terminal scrollback,
# logs, or process argument lists. `store` requires the USER at an interactive
# terminal; the password is prompted by `security` itself (-w as last option, per
# Apple's own guidance), so it is never passed as an argv value. `paste-password`
# never prints the secret — it places it on the clipboard briefly so the agent can
# Cmd+V it into the login form without reading it, then clears the clipboard only
# if it still holds the password (a later user copy is never clobbered).
#
# Per-household separation: set TAXWIZ_CRED_SERVICE (e.g. taxwiz-freetaxusa-parents).
# One account per service is enforced at store time.
set -euo pipefail
SERVICE="${TAXWIZ_CRED_SERVICE:-taxwiz-freetaxusa}"
CLIP_SECONDS="${TAXWIZ_CLIP_SECONDS:-20}"
USAGE="usage: creds.sh store|status|email|paste-password|delete   [service via TAXWIZ_CRED_SERVICE, default taxwiz-freetaxusa]"

acct() { security find-generic-password -s "$SERVICE" 2>/dev/null | sed -n 's/.*"acct"<blob>="\(.*\)"/\1/p'; }

CMD="${1:-}"
case "$CMD" in
  store)
    [[ -t 0 ]] || { echo "store must be run by the user at an interactive terminal" >&2; exit 1; }
    EXISTING="$(acct || true)"
    read -r -p "FreeTaxUSA email: " EMAIL
    [[ -n "$EMAIL" ]] || { echo "no email given" >&2; exit 1; }
    if [[ -n "$EXISTING" && "$EXISTING" != "$EMAIL" ]]; then
      echo "A different account ($EXISTING) already exists under service '$SERVICE'." >&2
      echo "Second household? Use: TAXWIZ_CRED_SERVICE=taxwiz-freetaxusa-<household> creds.sh store" >&2
      echo "Replacing this account? Run: creds.sh delete   first." >&2
      exit 1
    fi
    echo "macOS 'security' will now prompt for the password (hidden; never an argument):"
    security add-generic-password -U -a "$EMAIL" -s "$SERVICE" -w
    echo "Stored in macOS Keychain (service '$SERVICE', account $EMAIL). Remove anytime: creds.sh delete"
    ;;
  status)
    A="$(acct || true)"
    if [[ -n "$A" ]]; then echo "credentials stored (service: $SERVICE, account: $A)"
    else echo "no stored credentials for service '$SERVICE'"; exit 1; fi
    ;;
  email)
    A="$(acct || true)"
    [[ -n "$A" ]] || { echo "no stored credentials for service '$SERVICE'" >&2; exit 44; }
    printf '%s\n' "$A"
    ;;
  paste-password)
    A="$(acct || true)"
    [[ -n "$A" ]] || { echo "no stored credentials for service '$SERVICE'" >&2; exit 44; }
    PW="$(security find-generic-password -s "$SERVICE" -a "$A" -w)"
    printf '%s' "$PW" | pbcopy
    ( sleep "$CLIP_SECONDS"; [[ "$(pbpaste 2>/dev/null || true)" == "$PW" ]] && printf '' | pbcopy ) >/dev/null 2>&1 & disown
    echo "Password on clipboard for ${CLIP_SECONDS}s — paste with Cmd+V now. Clears itself only if still the password."
    ;;
  delete)
    N=0
    while security delete-generic-password -s "$SERVICE" >/dev/null 2>&1; do N=$((N+1)); done
    if [[ $N -gt 0 ]]; then echo "Removed $N credential item(s) for service '$SERVICE'."
    else echo "nothing stored for service '$SERVICE'"; exit 1; fi
    ;;
  "")
    echo "$USAGE" >&2; exit 2 ;;
  *)
    echo "unknown command: $CMD" >&2; echo "$USAGE" >&2; exit 2 ;;
esac
