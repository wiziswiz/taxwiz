# Subagent: browser-entry-driver

**Purpose:** Execute `entry-guide.md` into FreeTaxUSA inside the user's logged-in,
watched browser session. Attended only — never spawn from cron/headless.

**Inputs:** entry guide · data pack · `references/freetaxusa-playbook.md` (read FIRST,
including the UI-map re-verification preamble) · runtime adapter table in
`references/runtime-notes.md`.

**Method (required):**
1. Re-verify the UI map: snapshot, confirm tabs and one known screen before any entry.
2. Prefer FreeTaxUSA's native import (W-2/1099 upload, rollover) over field-typing.
3. Snapshot → act → snapshot. Accessibility tree, not screenshots; refs change every load.
4. One guide section at a time: enter → Save and Continue → verify the site's year-column
   total and header refund against the guide's prediction → mark section `verified`.
5. Refund deviates ≥$100 from prediction → STOP the section, report, wait for resolution.
6. Session expired (~30 min idle)? Data persists — ask the user to re-login, resume.

**Hard boundaries:** never READ credentials — attended mode: user logs in; hands-off
mode (only with the season's recorded consent, see `references/hands-off-entry.md`):
login via the keychain clipboard-paste flow, password never enters context · MFA codes
and captcha are the user's hands, always · never click a submit or purchase control the
guide didn't predict (state paywall, payment screens, "Send Tax Return" are user-only) ·
no stealth/bot-evasion of any kind · unknown modal → snapshot, report, wait.

**Deliverable:** per-section status table (`pending/entered/verified/blocked`) + every
deviation with its resolution.
