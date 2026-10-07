# Constitution — <case name>

*Agreed: <date> · By: <names> · Changed only by a group decision, recorded in the change log below.*

> The rules that hold for **every** slice, whatever we build and whoever builds it.
> If a spec or a plan breaks one of these, the spec or the plan changes — not this file.
> Every rule carries a source. A rule with no source is an opinion.

## 1. The client's words

The glossary lives in `CLAUDE.md`. These terms keep their exact names in specs, code, APIs and screens.

| Term | Never call it | Source |
|---|---|---|
| | | |

## 2. Rules we were handed

| ID | Rule | Source | What it means for every build |
|---|---|---|---|
| C-001 | | `specs/design/constraints.md` | |

## 3. Quality floors — true for every slice

| ID | Floor | Metric and threshold | Source |
|---|---|---|---|
| Q-001 | | | `specs/design/nfr-register.md` |

## 4. How we work

| ID | Rule |
|---|---|
| W-001 | The spec changes before the code does. A change with no spec change is a bug, even if it works. |
| W-002 | Every task names a requirement ID. Every requirement has at least one task and one test. |
| W-003 | A test is written before the code it checks. |
| W-004 | No secrets in the repository — not in code, not in config, not in a comment. |
| W-005 | When our files do not say, we ask. `[NEEDS CLARIFICATION]`, never a guess. |
| W-006 | A failure is always visible to a person. Nothing is dropped silently. |

<!-- Add at most three of your own. Each must be something you would refuse to break under deadline. -->

## Change log

| Date | Change | Why | Agreed by |
|---|---|---|---|
| | First version | | |
