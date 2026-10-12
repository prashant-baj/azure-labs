
## Session 10 — layer 2: code other people can live with

- `constitution.md` section 5 holds our **engineering rules**. Follow them in every file you write,
  and name the rule when you point out a problem (E-…, W-…).
- `plan.md` section 12 says how the code is cut into components. Keep the direction rule: the rule
  depends only on the model and on ports. Storage, inputs and frameworks are adapters outside it.
- Build only what a task asks for, on the stack the ADR names. A new library needs an ADR first.
- Work on a branch per task (`001/T006-matcher`). Every commit names its task: `T006: … (FR-003)`.
  Refactoring commits name the finding: `refactor: … (E-002, finding 2)`.
- Reviews go to `specs/NNN-<slice>/reviews/`. **You never fill the Decision column** — the group does.
- Refactoring never changes behaviour. If a test has to change, stop and say why.

### Commands (Session 10)

| Command | What it does |
|---|---|
| `/spec-engineering-rules` | Proposes five to seven checkable rules for constitution section 5 — the group picks |
| `/spec-components <slice>` | Draws plan section 12 — components with one job each, and a class diagram |
| `/build-tasks <slice> <tasks>` | Generates code for the named tasks only, tests first, on the ADR's stack |
| `/review-excellence <slice>` | Reviews the code against the rules. Every finding has a rule and a line. Changes nothing |
| `/refactor-step <slice> <n>` | Fixes one finding — pins behaviour with a test first, then the smallest change |
