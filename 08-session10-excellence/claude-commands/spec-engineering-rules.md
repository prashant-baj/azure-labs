---
description: Propose engineering rules for constitution.md section 5 — the group picks, each one checkable
argument-hint: ""
---
Read `constitution.md`, `specs/design/nfr-register.md`, the accepted architecture-and-stack ADR in
`specs/design/adr/`, and `templates/engineering-rules.md`.

Propose rules for a new **section 5, Engineering rules**, in `constitution.md`.

Rules:
- Start from the starter list in `templates/engineering-rules.md`. Propose **five to seven**, not all.
- Propose an **optional** rule (E-013 onwards) only if you can quote the line in our spec or plan
  that creates its situation (rules that vary by type, a port with several adapters, a partner
  format, a domain event). Quote that line next to the proposal.
- For each, fill **Checked by** with a real check for *our* stack (from the ADR): a linter rule, a
  test, the MR checklist, or a pipeline step. Use the tool table in the starter list. A rule you
  cannot say how to check is not proposed.
- Fill **Source**: our maintainability or other NFR, a W- rule, the ADR, or "starter list".
- Do not invent thresholds. If a limit is needed (for example complexity) and our files do not give
  one, write `[NEEDS CLARIFICATION: limit — the group decides]`.
- **Ask the group to pick.** Show the proposals as a table, then ask: "Which of these will you
  actually check?" Write only the rules they choose into section 5, and add a change-log row.
- Never change sections 1 to 4.

When you finish, print the chosen rules and, for each, the one command or setting that checks it.
