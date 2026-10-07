---
description: Break the plan into small, ordered tasks — each tied to a requirement ID, tests first
argument-hint: "[slice folder, e.g. specs/001-first-slice]"
---
Slice folder: $ARGUMENTS (if empty, use the only `specs/NNN-*` folder).

Read `constitution.md`, `<slice>/spec.md`, `<slice>/plan.md` and `templates/tasks.md`.
Fill `<slice>/tasks.md`, following the template exactly.

Rules:
- Format: `- [ ] T001 [P] <verb> <what> — FR-001 · done when: <check>`
- **Every task names at least one requirement ID.** If a task has none, it does not belong.
- **Every FR, RULE and NFR gets at least one task**, and at least one test task.
- A test task comes before the build task it checks.
- Each task fits in half a day or less. If it does not, split it.
- `[P]` only when the task touches different files from the one before and does not depend on it.
- Order by risk: the rule and the failure paths early, polish late.
- Use the stack in plan section 8, and only that. A task may name it — "Create the project skeleton
  with <framework> and <test runner>". If a task needs a library or tool the ADR does not name, put
  it under *Not yet* with `[NEEDS CLARIFICATION: new tool — needs an ADR]`.
- Tasks say what to do, not how to code it. No code in `tasks.md`.
- At most twenty-five tasks. If the slice needs more, **stop** and say the slice is too big, and
  propose how to split it. Do not write a longer list.

When you finish, print:
- the number of tasks, and how many are tests
- any requirement ID with no task
- the three tasks most likely to take longer than half a day
