# Validation — layer 3 · the slice, built with the assistant

*Written by `/validate-ai-code` against the constitution, the spec and the four lenses. The
**Decision** and **By** columns are filled in by the group.*

## Findings

| # | Lens | Where | Rule | What we see | Suggested change | Severity | Decision | By |
|---|---|---|---|---|---|---|---|---|
| 1 | Compliance | `sqlite_store.py` — first draft of `UnmatchedList.remove` | C-001 | Matching by hand **deleted** the unmatched entry. Nothing that arrives may be deleted | Record a resolution next to it instead | must | **fix** — now `resolve()`, insert-only; test `test_c_001_…` | Meena |
| 2 | Correctness | `match_by_hand.py` — first draft | FR-010 | Any flat the treasurer typed was accepted, even "Z-999" | Check the flat exists first; record nothing if not | must | **fix** — `FlatNotInDirectory`; test `test_fr_010_…` | Ravi |
| 3 | Security | `sqlite_store.py:28` — first draft | Security lens | `flats_paid_by` built its query with an f-string from the payer's name — a name with a quote in it breaks it, or worse | Parameters, never string-building | must | **fix** — `?` placeholders everywhere | Asha |
| 4 | Correctness | `tests/` | E-009 | The assistant's first loader test was named after NFR-002 but only checked that a mock was called — it could never fail | Test what the treasurer sees: rows in, rows recorded | should | **fix** — rewritten against a real in-memory SQLite | Meena |
| 5 | Maintainability | `record_payment.py` | E-004 | The use case imported `sqlite3` "just for the error type" | The use case knows the ports only | should | **fix** | Ravi |
| 6 | Correctness | `match_by_hand.py:20` | NFR-002 | Two writes — the payment, then the resolution — not in one transaction. A crash in between leaves a payment recorded and the entry unresolved | One transaction across both | should | **debt** — TD-002: the unit of work comes with the real database in layer 6 | Asha |
| 7 | Maintainability | `matcher.py:20` | FR-006 | A payer the society has never seen gets the reason "no flat in remark" — the treasurer cannot tell an unknown payer from a known one | Add a fourth reason, "payer not known" | could | **overruled** — RULE-001 names three reasons; a new one is a spec change, not a code change. Taken to the treasurer as a question | Ravi |

## What is already good

- The rule (RULE-001) has no idea SQLite exists. Every rule example runs without a database.
- Nothing is deleted. Every match says who, or which rule, made it.
- The spec review (`spec-review.md`) found FR-009 and FR-010 *before* the code — rows 1 and 2 here
  are the code catching up with the spec, not the other way round.

## Tally

Seven findings · five fixed · one debt · one overruled with a reason · three found by the group
(rows 2, 4 and 7).
