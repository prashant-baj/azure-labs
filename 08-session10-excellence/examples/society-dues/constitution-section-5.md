## 5. Engineering rules — how we write code

*Added in Session 10. Picked by the group from `templates/engineering-rules.md`. Each one is
something a reviewer, a linter or a test can actually check — otherwise it is a wish, not a rule.*

| ID | Rule | Checked by | Source |
|---|---|---|---|
| E-001 | Names come from the glossary — the treasurer's words in code, tables and APIs | Review — MR checklist | Section 1 · glossary |
| E-002 | One job per module. If you need "and" to say what it does, split it | Review | `specs/design/nfr-register.md` — maintainability |
| E-003 | Functions stay simple — complexity at most five | Linter: ruff `C901` | `specs/design/nfr-register.md` — maintainability |
| E-004 | The rule depends on nothing outside it — storage and inputs sit behind ports | `tests/test_matcher.py` runs the rule with no database | ADR 0003 — one deployable, separate modules |
| E-006 | No silent failures — no catch-all that hides an error | Linter: ruff `BLE` | W-006 |
| E-008 | Configuration and secrets come from the environment, never from code | Secret scan in the pipeline (gitleaks) | W-004 |
| E-009 | Every requirement has a test that names its ID | `check-excellence` | W-002 |

<!-- E-005, E-007, E-010 to E-012 from the starter list were not picked — a group keeps what it will
     actually check, and adds more when it can check them. -->

## Change log (new row)

| Date | Change | Why | Agreed by |
|---|---|---|---|
| Session 10 | Section 5 added — seven engineering rules | Layer 2: the code must follow rules we can check | The group (invented) |
