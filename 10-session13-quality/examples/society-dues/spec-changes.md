# What layer 4 changed in the spec — first, before any code

The spec changes first. These are the edits to `specs/001-match-payments/spec.md` made in Session 13,
before a single scenario or test was written.

| Where | Change | Why |
|---|---|---|
| §5 | **RULE-002 added** — "Paid means the month's dues are covered, by one payment or several. A part payment still gets a reminder, for the balance." Rows RULE-002a–d | The example map: the treasurer answered Q1 |
| §4 FR-008 | *How we will know* now points at `features/reminders.feature` and RULE-002 | The requirement is proved by scenarios, not described in prose |
| §4 FR-003, 004, 006 | *How we will know* points at `features/matching.feature` | Same |
| §10 | Q1 closed. **Q3** (overpayment — carry forward?) and **Q4** (calendar month or due date?) added, each with who can answer | Red cards from the map — written down, not guessed |
| §11 | Clarification: *Session 13 — Asked: does a part payment count as paid? Treasurer: no — remind for the balance. Changed: RULE-002, FR-008* | Every answer has a date and a person |
| new file | `stories.md` — US-001, US-002 with acceptance criteria, each naming what it proves | Stories plan the work; the requirements stay the source of truth |
| new folder | `features/` — two feature files, every scenario tagged with its IDs | The spec runs |
| `trace.md` | New column **Scenario** between *Requirement* and *Test* | See below |

## Trace — after layer 4

| Requirement | Story · AC | Scenario | Unit test | Code |
|---|---|---|---|---|
| FR-003 / RULE-001 | US-001 AC-1, AC-2 | matching.feature — *The flat comes from the remark…* (a, b, d) | test_rule_001.py | matcher.py |
| FR-006 / RULE-001 | US-001 AC-3 | matching.feature — *…set aside with the reason* (c, e) | test_matcher.py | record_payment.py |
| FR-004 | US-001 AC-4 | matching.feature — *…counted once* | test_rule_001.py | record_payment.py |
| FR-008 / RULE-002 | US-002 AC-1–4 | reminders.feature — both scenarios | test_rule_002.py | month_status.py, reminders.py |
| FR-001, 002, 005, 007 | — | **none yet** | contract tests only | — |

The last row is honest, and it is the point: the trace shows which requirements nobody can yet see
running. Sessions 14 and 15 close it.
