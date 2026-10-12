# Review — layer 2 · `before/dues/payments.py`

*Written by `/review-excellence` against `constitution.md` sections 4 and 5. The **Decision** and
**By** columns are filled in by the group — never by the assistant.*

## Findings

| # | Where | Rule | What we see | Suggested refactoring | Severity | Decision | By |
|---|---|---|---|---|---|---|---|
| 1 | `payments.py:6` | E-008, W-004 | An API key is written in the code | Read it from the environment; rotate the key — it is now in history | must | **fix** — key moved out; rotation logged as TD-001 | Asha |
| 2 | `payments.py:16` | E-002, E-003 | `process` checks duplicates, parses the remark, applies the rule, stores and notifies — five jobs; complexity 9 | Extract: find flat in remark · apply the rule · record once | must | **fix** | Ravi |
| 3 | `payments.py:55` | E-006, W-006 | `except Exception: return None` — any error, including a database failure, looks like "not matched" | Remove the catch-all; let real failures surface | must | **fix** | Ravi |
| 4 | `payments.py:11` | E-004 | The rule reads the database directly — it cannot be tested without one | Put flats, payments and unmatched behind ports; pass the connection in | must | **fix** | Meena |
| 5 | `payments.py:33` | W-002 | Notifies the treasurer above an amount — no requirement asks for this | Remove. If it is wanted, the spec changes first | should | **fix** — removed; question added to spec section 10 | Asha |
| 6 | `payments.py:33` | E-005 | The amount and the reason texts are bare values | Name them — the reasons become one list | should | **fix** | Meena |
| 7 | `payments.py:16` | E-001 | `p`, `r`, `f`, `ref`, `amt` — not the glossary's words | Use `payment`, `bank_reference`, `flat`, `amount` | should | **fix** | Ravi |
| 8 | `payments.py:32` | E-002 | Every insert commits on its own — the morning load cannot be counted in one go (NFR-002) | A transaction around the whole file load | should | **debt** — TD-002, layer 3, when the loader is built | Meena |
| 9 | `payments.py:26` | E-005 | The flat pattern allows one block letter only | — | could | **overruled** — the society has only single-letter blocks today (evidence log row 4). Re-check if that changes | Asha |

## What is already good

- The five RULE-001 examples were tested before any change — that test is what made the refactoring safe.
- Duplicates are caught by the bank reference, exactly as ADR 0002 decided.
- Unmatched payments carry a reason — nothing disappears.

## Tally

Nine findings · seven fixed · one logged as debt · one overruled with a reason · two found by the
group that the assistant missed (rows 5 and 9).
