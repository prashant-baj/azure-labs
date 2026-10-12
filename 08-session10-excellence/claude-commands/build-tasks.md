---
description: Generate code for named tasks only — on the ADR's stack, tests first. You review it next.
argument-hint: "[slice folder] [task IDs, e.g. T001-T006]"
---
Arguments: $ARGUMENTS — the slice folder, then the task IDs to build (a range like T001-T006, or a list).

Read `CLAUDE.md`, `constitution.md`, `<slice>/spec.md`, `<slice>/plan.md` (sections 8 and 12), the
accepted architecture-and-stack ADR and `<slice>/tasks.md`.

Build **only the named tasks**, in the order `tasks.md` gives.

Rules:
- **Only the stack in the ADR.** If a task needs a library the ADR does not name, stop and say so —
  do not add it.
- **Tests first** (W-003): for each task with a test, write the test before the code it checks, and
  name the test after the requirement ID (E-009).
- Follow the components and the direction rule in plan section 12, and the rules in constitution
  section 5.
- Build nothing that no task asks for. No extra endpoints, no "nice to have" (W-002).
- No secrets, keys, passwords or connection strings in code or config (W-004). Read them from the
  environment and list the names in a `.env.example` with empty values.
- Do not commit. The group commits, one task per commit: `T00x: <what> (FR-0xx)`.

When you finish, print: for each task — the files written, the tests and whether they pass, and
anything you were unsure about. Then print: "Next: run the tests yourselves, commit per task, then
/review-excellence."
