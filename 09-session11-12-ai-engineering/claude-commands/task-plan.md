---
description: Plan one task before any code — files, tests, IDs, questions. Writes nothing.
argument-hint: "[slice folder] [task ID, e.g. T009]"
---
Arguments: $ARGUMENTS — the slice folder and one task ID.

Read `CLAUDE.md`, `constitution.md`, `<slice>/spec.md`, `<slice>/plan.md` (sections 3, 8 and 12),
the accepted ADRs, `<slice>/tasks.md`, and the code the task touches.

Write **no code and no files.** Print a plan for **that task only**:

1. **What it does** — one sentence, and the requirement IDs it serves (from tasks.md).
2. **Files** — every file you would create or change, and why. A file outside the task's component
   (plan section 12) needs a reason, or it comes out of the plan.
3. **Tests first** — the tests you would write, named after the requirement IDs, and what each proves.
   Include at least one *If* case if the spec has one for this requirement.
4. **Docs** — what changes in README ("How to run"), `trace.md` or an ADR, if anything.
5. **Risks** — what could go wrong, and the smallest thing that would show it early.
6. **Questions** — anything our files do not say. Ask; do not assume.

End with: "Approve, change or stop this plan before I write anything." Then wait.
