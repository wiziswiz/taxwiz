# Hands-Off Entry — opt-in terminal-driven filing (no browser-watching)

For users who want the season driven from the terminal (or through OpenClaw/Hermes
messages) instead of watching a browser. **Strictly opt-in, once per season**, after the
user hears the honest trade-offs. Default remains guided/assisted attended entry.

## What changes, what doesn't

| Hands-off automates | Stays human, always |
|---|---|
| Opening the session and logging in (keychain paste flow — agent never sees the password) | **MFA codes** — the user reads the code from their phone/email and types it in the terminal (~10 sec; codes expire in seconds so log exposure is negligible) |
| All section-by-section data entry from the entry guide | **Captcha** — if one appears, STOP and hand the browser to the user; never solve or evade |
| Per-section verification against predicted totals | **Final review + Self-Select PIN + "Send Tax Return"** — the user's legal signature, on-site, ~2 min after the GO report |
| Draft PDF download and the closing diff | Any payment/purchase screen (state filing fee, balance due) |
| Progress narration to terminal / OpenClaw / Hermes | Deciding to proceed past any $100+ deviation |

## The consent gate (per season, recorded in verification-log.md)

Before the first hands-off session of a season, tell the user plainly:
1. FreeTaxUSA's ToS prohibits automated access; hands-off mode is more exposed than
   watched-assisted entry (no human eyes between agent action and site state).
2. Every section is still verified against the entry guide, and nothing is submitted —
   the worst uncaught failure is wasted entry work, caught by the closing PDF diff.
3. Credentials live in the OS keychain, readable by their account only, deletable
   anytime; the agent never reads the password.
4. **Clipboard exposure:** during the paste window the password sits on the system
   clipboard, readable by any process running as the user — and clipboard managers
   (Raycast, Alfred, Maccy, Paste) typically persist clipboard history to disk, where
   it outlives the auto-clear. A user running one should pause it or exclude it during
   login, or use attended login instead. Say this before they say yes.
Record their yes (their words, date) in `verification-log.md`. No recorded yes = no
hands-off mode.

Like `cleanse.sh`'s gates, this consent gate is a POLICY backstop, not code-enforced —
the log is agent-writable, and its integrity rests on this rule being followed, not on
a technical check. Fabricating a consent entry is a violation, not a workaround.

## Credential flow (macOS Keychain, `scripts/creds.sh`)

- **Setup (user, once):** `scripts/creds.sh store` — run by the user at their
  terminal; the password is prompted (hidden) by macOS `security` itself, so it never
  appears in an argument list. One account per service, enforced. Never ask the user
  to paste a password into chat, and never run `store` yourself.
- **Login (agent):** navigate to the login page → fill email from `creds.sh email` →
  click the password field → run `creds.sh paste-password` → send Cmd+V → submit.
  The script places the password on the clipboard for 20 seconds and then clears it
  only if the clipboard still holds the password (a user's later copy is never
  clobbered). The agent never reads, echoes, or stores the value. If MFA fires, ask
  the user for the code in the terminal.
- **Post-season (offer, don't insist):** after `RETURN_FILED.txt` exists, offer
  `creds.sh delete`. Some users keep credentials for amendment season; their call.
- An env file is NOT an acceptable fallback — plaintext on disk, and anything the
  agent `cat`s enters context and logs. Keychain or nothing.

## Session protocol

1. Precondition: validated data pack + entry guide + engine expected-totals. Hands-off
   entry never improvises a number; if the guide lacks a value, stop and ask.
2. Run the browser HEADED but unattended (minimized is fine) — headless triggers WAF
   heuristics faster and hides captchas you need to see. Never add stealth flags; if
   the site blocks or challenges beyond MFA, fall back to attended mode rather than
   fighting it.
3. Narrate per section, not per click: `Income → 1099-DIV: 2 payers entered, column
   total $9 ✓, refund $5,651 → $5,651 (predicted no change) ✓`. On OpenClaw/Hermes,
   send the same line as a message; include a screenshot only on deviation.
4. Deviation ≥$100 from predicted refund, unexpected modal, red error, or any screen
   not in the entry guide: pause, report, wait for a human decision. Never click
   through the unexpected.
5. Session end: download the draft PDF, run the closing diff, deliver the GO/NO-GO
   report with the link for the user's on-site final review and Send.

## Runtime notes

- Claude Code: claude-in-chrome (user's Chrome, minimized) or the Playwright plugin
  headed. Cmd+V via the computer/keyboard tool — the paste keystroke, never the text.
- OpenClaw/Hermes on a remote box (Mac mini): the keychain and browser live on the
  machine running the session; MFA relay happens over the user's chat channel. The
  final review + Send is still done by the user on their own device.
- Multi-household: one keychain service per FreeTaxUSA account, one account per
  service (enforced by `creds.sh store`). Default service `taxwiz-freetaxusa`; for
  other households set `TAXWIZ_CRED_SERVICE=taxwiz-freetaxusa-<household>` on every
  `creds.sh` call in that household's session. Before any hands-off login, run
  `creds.sh status` and confirm the account shown matches the household being filed.
