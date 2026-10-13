# Validation — layer 3 · the AI-assisted feature

*Written by `/validate-ai-code` against the constitution, the spec and the four lenses. The
**Decision** and **By** columns are filled in by the group.*

## Findings

| # | Lens | Where | Rule | What we see | Suggested change | Severity | Decision | By |
|---|---|---|---|---|---|---|---|---|
| 1 | Compliance | `sqlite_store.py` — first draft of `UnmatchedList.remove` | C-001 | Accepting a suggestion **deleted** the unmatched entry. Nothing that arrives may be deleted | Record a resolution next to it instead | must | **fix** — now `resolve()`, insert-only; test `test_c_001_…` | Meena |
| 2 | Security | `suggest_for_unmatched.py:27` | C-004 | First draft sent the whole `Payment` — payer name and bank reference included | Send only the remark and the flat list | must | **fix** — test `test_c_004_…` proves it | Asha |
| 3 | Correctness | `claude_suggester.py:41` | FR-012 | A reply that is not JSON raised an error and stopped the queue | Anything not in the agreed shape is "no suggestion" | must | **fix** — `parse_reply`, five shapes tested | Ravi |
| 4 | Security | `prompts/suggest_flat.txt` | FR-012 | Nothing stops a remark from carrying instructions | Say in the prompt that the remark is data; *and* never trust the output — check it against the directory | must | **fix** — both; EVAL-005 is the guardrail example | Asha |
| 5 | Maintainability | `claude_suggester.py:22` | E-008 | The model name was written in the code | Read it from `SUGGESTER_MODEL` | should | **fix** | Ravi |
| 6 | Correctness | `tests/` | E-009 | The assistant's first tests checked that the fake returned what the fake was told — they could never fail | Test *our* guardrails with the fake, and the model with the eval set | should | **fix** | Meena |
| 7 | Compliance | `requirements-ai.txt` | ADR 0003 | A new library — the model's client — not named in the ADR | Small decision: add it to the ADR's consequences | should | **fix** — ADR 0004 written, one paragraph | Asha |
| 8 | Maintainability | `claude_suggester.py:33` | E-006 | Catches every exception | It re-raises as `SuggesterUnavailable` — every failure still reaches a person (FR-011) | could | **overruled** — the catch is deliberate and re-raises; the rule is about hiding failures, and this one does not hide it | Ravi |
| 9 | Correctness | `eval/eval_set.json` | NFR-003 | No agreed threshold for "good enough" | — | should | **debt** — TD-003: the treasurer decides after seeing a month of suggestions | Meena |

## What is already good

- The suggester is a port. Every guardrail is tested with a fake — no key, no network, no cost.
- A person decides every match the model touches, and the record says who.
- The eval set includes the example that tries to break it.

## Tally

Nine findings · seven fixed · one debt · one overruled with a reason · three found by the group
(rows 1, 6 and 8).
