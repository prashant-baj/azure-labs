# Spec changes for the AI-assisted feature — written before any code (W-001)

*Added to `specs/001-match-payments-show-dues/spec.md` in Session 12. The feature: when a payment
cannot be matched, suggest a flat — and let the treasurer decide.*

## New requirements

| ID | Requirement | Source | Acceptance check |
|---|---|---|---|
| FR-009 | When a payment is on the unmatched list, the system shall suggest at most one flat, with a one-line reason, for the treasurer to accept or reject. | `docs/02-evidence-log.md` row 7 — "most unmatched ones are obvious once you read them" | Test: unmatched payment gets a suggestion |
| FR-010 | When the treasurer accepts a suggestion, the system shall record the match with the treasurer's name as who decided. | C-001; `design/constraints.md` — audit | Test: the record says "suggestion accepted by …" |
| FR-011 | If suggestions are unavailable or too slow, then the payment shall stay on the unmatched list, marked "matched by hand". | W-006 | Test: suggester down → no suggestion, no crash |
| FR-012 | If the suggestion is not a flat in the society, or the remark contains instructions, then the system shall show no suggestion. | W-005 — never guess | Test: a flat outside the directory is never shown; eval example EVAL-005 |

## New rule we were handed

| ID | Rule | Source | What it means for every build |
|---|---|---|---|
| C-004 | Only the remark and the list of flat numbers may be sent outside the society's system — never a payer's name, phone or bank reference | Committee resolution (invented) | The suggester port receives two arguments and nothing else |

## New quality requirement

| ID | Requirement | Metric and threshold | How measured | Source |
|---|---|---|---|---|
| NFR-003 | Suggestions agree with what the treasurer would decide | Agreement on the eval set — `[NEEDS CLARIFICATION: how much agreement is enough? — the treasurer decides]` | `python -m eval.run_eval` | This session |

## The eval set — the AI feature's rule examples

`eval/eval_set.json`. Six examples from the evidence log, including one that tries to give the
model instructions (EVAL-005) and one where two flats fit and the right answer is "no suggestion"
(EVAL-004). An AI feature without an eval set is a rumour.

## Change log row

| Date | Change | Why | Agreed by |
|---|---|---|---|
| Session 12 | FR-009 to FR-012, C-004, NFR-003 and the eval set added | Layer 3: one AI-assisted feature, with a person deciding | The group (invented) |
