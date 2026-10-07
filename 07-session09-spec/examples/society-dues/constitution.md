# Constitution — Sahyadri Heights society dues

*Agreed: Session 9 · By: the example group · Changed only by a group decision, recorded in the change log below.*

> The rules that hold for **every** slice, whatever we build and whoever builds it.
> If a spec or a plan breaks one of these, the spec or the plan changes — not this file.

## 1. The client's words

| Term | Never call it | Source |
|---|---|---|
| Flat | Unit, apartment, account | `CLAUDE.md` glossary |
| Maintenance | Bill, fee, invoice | `CLAUDE.md` glossary |
| Dues | Balance, outstanding amount | `docs/03-concern-sheet.md` — treasurer's own word |
| Remark | Narration, description | `docs/02-evidence-log.md` row 4 |

## 2. Rules we were handed

| ID | Rule | Source | What it means for every build |
|---|---|---|---|
| C-001 | Payment records are kept for the society's audit, every year | `specs/design/constraints.md` — legal | Nothing that arrives is deleted. Corrections are new records |
| C-002 | Only the treasurer and the secretary may see who paid what | `specs/design/constraints.md` — committee resolution | Every view of a flat's payments checks the role |
| C-003 | The bank statement can only be downloaded, once a day, by the treasurer | `specs/design/constraints.md` — contractual | The system never assumes the file is newer than this morning |

## 3. Quality floors — true for every slice

| ID | Floor | Metric and threshold | Source |
|---|---|---|---|
| Q-001 | Every answer shows where it came from and how old it is | Every status carries source and time — checked by a test on each response | `specs/design/nfr-register.md` — reliability |
| Q-002 | A payment is never counted twice | Duplicate count after matching is zero — checked by the rule examples | `specs/design/nfr-register.md` — reliability, owner: treasurer |

## 4. How we work

| ID | Rule |
|---|---|
| W-001 | The spec changes before the code does. A change with no spec change is a bug, even if it works. |
| W-002 | Every task names a requirement ID. Every requirement has at least one task and one test. |
| W-003 | A test is written before the code it checks. |
| W-004 | No secrets in the repository — not in code, not in config, not in a comment. |
| W-005 | When our files do not say, we ask. `[NEEDS CLARIFICATION]`, never a guess. |
| W-006 | A failure is always visible to a person. Nothing is dropped silently. |

## Change log

| Date | Change | Why | Agreed by |
|---|---|---|---|
| Session 9 | First version | Assembled from the design record, checked by the group | Whole group |
