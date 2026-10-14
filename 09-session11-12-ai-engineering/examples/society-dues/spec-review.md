# Spec review — layer 3

*Written by `/spec-review` in Session 12. The assistant found and asked; the group decided. Every
**Decision** is what the group said — not what the assistant proposed.*

**Slice:** specs/001-match-payments-show-dues · **Reviewed on:** Session 12 · **Group present:** Asha, Meena, Ravi (invented)

| # | Kind | About | The line (quoted) | Proposed change | Decision | By |
|---|---|---|---|---|---|---|
| 1 | Untestable | NFR-001 | "A dues answer is quick enough to give a resident at the gate" | The metric is fine; the *load* is not. Say how many dues answers at once, or the load test can pass with one user | **change** — "…with 20 dues answers at the same time" (secretary agreed on the call) | Meena |
| 2 | Ambiguous | FR-005 | "When an allowed committee member asks…" | Who is "allowed"? Name the roles, or point to the list | **ask** Managing committee — open question 3 | Asha |
| 3 | Missing example | RULE-001 | "If they wrote the flat number, believe it" | No example for a lowercase remark ("b304 oct"). Add RULE-001f | **change** — RULE-001f added. It is the bug from the Session 11 drill: the test came first, the spec now holds the example too (in this folder the code is left as it was, so the drill still works) | Ravi |
| 4 | Missing example | RULE-001 | (two flats in one remark) | Remark "B-304 and B-305" — which wins? | **ask** Treasurer — "don't guess" suggests unmatched, but she has to say it | Meena |
| 5 | Not asked yet | §6 — the unmatched list | "Each payment, and the reason it was not matched" | The list is kept, but nothing says how a payment *leaves* it. Who clears it, and what is kept? | **change** — FR-009 and FR-010 added (below). C-001 already says nothing is deleted | Asha |
| 6 | Missing If row | FR-002 | "When the morning statement file is loaded…" | What if the same file is loaded twice? FR-004 covers one payment, not one file | **keep** — FR-004 already makes a second load harmless; test `test_fr_004_…` proves it | Ravi |
| 7 | Glossary drift | FR-008 | "a matched payment for the month" | The glossary says *payment*; FR-008 and §0 also say "dues paid" and "has paid". Same thing? | **change** — "has paid" replaced with "has a matched payment" in §0 | Meena |
| 8 | Conflict | FR-007 vs NFR-001 | "say so on every dues answer" | Checking "was the file loaded today?" on every answer could cost time | **keep** — one cheap lookup; NFR-001's load test will tell us if not | Ravi |

## Questions for the client

| # | Question | Who | Asked on | Answer |
|---|---|---|---|---|
| 1 | How many dues answers at the same time should NFR-001 survive? | Secretary | Session 12 | "20 — the evening rush at the gate" |
| 2 | Which committee members may ask for a flat's dues? | Managing committee | Session 12 | `[NEEDS CLARIFICATION: allowed roles]` — next meeting |
| 3 | A remark names two flats. Unmatched, or the first one? | Treasurer | Session 12 | `[NEEDS CLARIFICATION: two flats in one remark]` |

## What changed in spec.md

New requirements, from row 5:

| ID | Requirement | Source | How we will know |
|---|---|---|---|
| FR-009 | When the treasurer matches an unmatched payment by hand, the system shall record the match with the treasurer's name, and keep the unmatched entry. | C-001; this review, row 5 | Test: `test_fr_009_…`, `test_c_001_…` |
| FR-010 | If the flat the treasurer types is not in the society, then the system shall record nothing and say why. | W-005 — never guess; this review, row 5 | Test: `test_fr_010_…` |

Also changed: NFR-001 (row 1), RULE-001f (row 3), §0 wording (row 7). Change-log row:

| Date | Change | Why | IDs affected |
|---|---|---|---|
| Session 12 | Spec review with AI — 8 findings, 4 changed, 2 kept, 2 asked | `reviews/spec-review.md` | NFR-001, RULE-001f, FR-009, FR-010, §0 |

## What the assistant got wrong

- It proposed rewriting FR-005 itself with "treasurer and secretary". The group refused — the
  committee decides who is allowed, so it became a question (row 2), not a guess.
- Row 6 was a false alarm: FR-004 already covered it. The assistant had not read the tests.
