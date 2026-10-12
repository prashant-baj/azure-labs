# Clean code — six habits

Clean code is not a talent. It is a handful of habits, each of which a reviewer, a linter or a test
can check. This folder shows all six on one small, invented example: a housing society's late fee.

| File | What it shows |
|---|---|
| `clean_code_before.py` | Code that **works** — and that nobody else wants to change |
| `clean_code_after.py` | The same answers, written so the committee's rule can be read in the code |
| `test_clean_code.py` | One table of cases run against **both** versions: refactoring changed the shape, not the answers |

Run it: `python -m pytest -q` (from this folder).

## The six habits

### 1 · Names say what, in the client's words — E-001

```python
def calc(d, a, t):                                            # before
def amount_due(dues: float, days_late: int, unit: UnitType):  # after
```

`d`, `a`, `t` make every reader decode the function. `dues`, `days_late`, `unit` come from the
glossary — the same words the treasurer uses. **Check:** the reviewer reads the names against the
glossary in `CLAUDE.md`.

### 2 · One function, one job — E-002, E-003

Before: one function decides the unit type, the grace period, the late-month count and the fee.
After: `amount_due` adds up; `late_fee` applies the rule. Each can be read in one breath.
**Check:** a complexity limit in the linter (for Python, ruff `C901`).

### 3 · No magic values — E-005

```python
if d > 15: return a + a * 0.02 * ((d - 15) // 30 + 1)        # before: what are 15, 0.02, 30?
GRACE_DAYS = 15; MONTHLY_LATE_RATE = 0.02                      # after: named, with where they came from
```

A bare number is a decision nobody wrote down. Name it once, say where it came from, use the name.
**Check:** review — and your linter, if it has a magic-number rule.

### 4 · No silent failures — E-006, W-006

```python
except Exception:                                              # before
    return 0                                                   #   any bug becomes "no dues"
raise ValueError(f"days_late and dues cannot be negative ...") # after: the mistake is visible
```

A catch-all that returns a normal-looking value hides bugs from the treasurer *and* from you.
**Check:** the linter's blind-except rule (ruff `BLE`); the review.

### 5 · Comments say why, not what — E-011

```python
# calculate fee                                               # before: says what the code says
# The first late day already counts as a whole late month -
# that is how the treasurer bills it.                          # after: says why, which the code cannot
```

**Check:** review. Delete every comment that repeats the code.

### 6 · Formatting is the tool's job — E-010

Spacing, line length and import order are not worth a review comment. Let the formatter decide
(`ruff format`, Prettier, Spotless, `dotnet format`) and run it in the pipeline.

## How these appear in your constitution

See [`../in-your-constitution.md`](../in-your-constitution.md). Pick only the habits you will
actually check — and say how.
