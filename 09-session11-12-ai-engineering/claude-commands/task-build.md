---
description: Build one approved task — test first, small diff, docs in the same change. Does not commit.
argument-hint: "[slice folder] [task ID]"
---
Arguments: $ARGUMENTS — the slice folder and one task ID. The plan for it was approved in this
conversation with /task-plan. If it was not, run the planning step first and wait for approval.

Rules:
- **Only the approved plan.** If you find you need another file, stop and say why before touching it.
- **Test first** (W-003): write the test, run it, show it failing for the right reason. Then the code.
- Follow constitution sections 4 and 5, plan section 12 and the ADR's stack. No new library.
- No secrets in code or config (W-004). Configuration comes from the environment; list new names in
  `.env.example` with empty values.
- **Docs in the same change:** update README "How to run" and `trace.md` if the task changes them.
- Run the whole test suite and the linter at the end. Everything green — or say exactly what is not.

Do not commit. Print: the files changed, the tests added and their results, and a commit message:
`T0xx: <what> (FR-0xx)`. Then: "Read the diff before you commit — not my summary of it."
