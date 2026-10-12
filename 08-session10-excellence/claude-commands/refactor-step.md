---
description: Fix one review finding — behaviour pinned by a test first, then the smallest change
argument-hint: "[slice folder] [finding number from reviews/L2-review.md]"
---
Arguments: $ARGUMENTS — the slice folder and the finding number.

Read `constitution.md`, `<slice>/reviews/L2-review.md` (that finding only), and the code it points to.

Fix **that one finding**, in this order:

1. **Pin the behaviour.** Find the tests that cover this code and run them. If none cover it, write
   one that passes against the code *as it is now*, named after the requirement ID — then stop and
   show it, so the group can commit it before any change.
2. **Make the smallest change** that fixes the finding. The behaviour must not change.
3. **Run the tests.** They must pass without being edited. If a test has to change, stop and explain
   why — a refactoring that needs a test change may be a behaviour change.
4. **Show the diff** and suggest the commit message: `refactor: <what> (E-0xx, finding <n>)`.

Rules:
- One finding per run. Touch only the files that finding needs.
- No new library or framework. No behaviour the spec does not ask for.
- If the finding cannot be fixed safely today, say so and propose a `TD-` row for
  `specs/design/tech-debt.md` instead.
- Do not commit, and do not fill the Decision column — the group does both.
