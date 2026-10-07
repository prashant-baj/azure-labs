---
description: Write trace.md — which requirement leads to which piece, task and test — and list the gaps. Reports only; fixes nothing.
argument-hint: "[slice folder, e.g. specs/001-first-slice]"
---
Slice folder: $ARGUMENTS (if empty, use the only `specs/NNN-*` folder).

Read `constitution.md`, `<slice>/spec.md`, `<slice>/plan.md` and `<slice>/tasks.md`.

**Do not change any of those files.** Write one new file, `<slice>/trace.md`:

## 1. The chain
One row per ID in the spec (IN, FR, RULE, NFR):

| ID | Source (from the spec) | Plan piece | Build tasks | Test tasks |
|---|---|---|---|---|

## 2. Gaps
List, each with the IDs involved:
- requirements with no build task
- requirements with no test task
- tasks that name no requirement, or name an ID that does not exist in the spec
- NFRs with no metric, or no place where they are measured
- rows in the spec with no Source
- constitution rules the plan breaks without a reason and a name
- `[NEEDS CLARIFICATION]` markers still open, in any of the three files

## 3. Verdict
One line: **ready to build**, or **not ready**, and the single most important gap to close first.

Write today's date at the top. Then print the verdict and the number of gaps.
