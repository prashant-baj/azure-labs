---
description: Triage scanner findings one at a time - fix, false positive, accepted risk or debt - each with a reason. Never hides a finding silently.
argument-hint: "[gate: lint|complexity|secrets|sast|dependencies|iac] [report file or pipeline job log]"
---
Arguments: $ARGUMENTS — the gate, and where the findings are: `.quality/semgrep.json`, `.quality/osv.json`,
`.quality/local-report.md`, or a job log pasted into the conversation.

For **each finding, one at a time**:

1. Show it: rule ID, file and line, the code around it, what the tool says. Explain in two sentences what an
   attacker or a future maintainer could actually do with it **here** — or say plainly that you cannot see a
   way, and why.
2. Propose **one** of:
   - **Fix** — the smallest change, with the test that proves it (W-003). Preferred.
   - **False positive** — the tool is wrong here. Suppress it **inline, on that line only**, with the reason
     in the comment (`# nosemgrep: <rule> - <reason>`, `#checkov:skip=<ID>: <reason>`, `// eslint-disable-next-line <rule> -- <reason>`).
   - **Accepted risk** — real, but accepted for now (e.g. a lab constraint). Inline skip with the reason, and
     a row in *Accepted findings* in `specs/design/quality-gates.md` with a review date.
   - **Debt** — real, not fixed today: a row in `specs/design/tech-debt.md`; the ratchet baseline stays.
3. **Wait** for the group to decide. Apply only what they chose.

Rules that do not bend:
- **A real secret is never accepted.** Rotate it first (revoke the key), then remove it, and tell the
  facilitator. Deleting the line does not delete it from history.
- **A secret finding that is not a secret** (the *name* of a secret, a documented example value) needs a second
  person to agree. Then: `# gitleaks:allow - <reason>` on the line, and its fingerprint (gitleaks prints it)
  in `.gitleaksignore` with the reason above it — the inline comment does not cover older commits.
- **A dependency finding** is fixed by upgrading to the fixed version the scanner names — run the tests after.
  If no fixed version exists, it is accepted risk with a review date, never a silent skip.
- Never widen a suppression to a file or a whole rule. Never change a threshold in `ci/quality.yml` to pass.

End with a table: finding · decision · reason · where, and the new counts against the baselines.
