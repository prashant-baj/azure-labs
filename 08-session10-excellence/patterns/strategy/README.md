# Strategy

> **The spec lists different rules for the same decision.** Each rule becomes a small class with the same method; the caller picks one and never branches.

## When to use it

- The spec says *"for residential units … for commercial units … unless the committee waives it"*.
- The rule is chosen by data (unit type, plan, region) or by configuration.
- New variants are likely — the client has said so, or the spec already has three.

## When not to

- Two variants that will stay two. An `if` is clearer than three classes.
- The variants differ only by a number. Put the number in configuration instead (see `FlatAmount(500)` — one class, many amounts).

## Structure

```
amount_due(dues, days, strategy) ──▶ LateFeeStrategy.fee()
                                         ├── PercentPerLateMonth(rate)
                                         ├── FlatAmount(amount)
                                         └── Waived()
```

`strategy_example.py` · `test_strategy.py` — one caller, three rules; the grace period is tested
once for all of them. This is the **open–closed** principle in practice
([`../../principles/solid/o-open-closed/`](../../principles/solid/o-open-closed/)).

## In plan §12

| Component | Its one job | Exposes | Depends on | Pattern | Requirement IDs |
|---|---|---|---|---|---|
| LateFeeCalculator | Work out the amount due for a unit | `amount_due()` | `LateFeeStrategy` | Strategy | FR-004, FR-005 |

Add a class diagram (§12) showing the interface and one box per strategy.

## In constitution §5

```markdown
| E-013 | A rule that varies by type is one strategy per variant behind one interface — no if/elif chain on the type | Review; a test that adds a variant without editing old ones | Open–closed · FR-<id> |
```

## Misuse smell

- A strategy that checks `isinstance` of another strategy.
- The choosing `if/elif` simply moved into a factory that grows every month — keep a **registry** (a dictionary from type to strategy) instead.
