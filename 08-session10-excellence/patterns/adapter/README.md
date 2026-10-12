# Adapter

> **Two partners, two formats — one shape inside.** An adapter turns *their* data into *your* type, at the edge.

## When to use it

- Data comes from outside — a partner file, a third-party API, a legacy system — in a shape you do not control.
- More than one source gives you the same kind of thing in different shapes (UPI JSON, bank CSV).
- You want to swap a vendor later without touching the rule.

## When not to

- The outside format **is** your format, and only one source exists. A plain function that parses it is enough.

## Structure

```
UPI JSON ──▶ UpiJsonAdapter ──┐
                              ├──▶ PaymentSource (port) ──▶ the rule (knows only Payment)
bank CSV ──▶ BankCsvAdapter ──┘
```

`adapter_example.py` · `test_adapter.py` — both partners produce the same `Payment`; the rule
gives the same answer for either.

## In plan §12

| Component | Its one job | Exposes | Depends on | Pattern | Requirement IDs |
|---|---|---|---|---|---|
| UpiJsonAdapter | Turn the UPI partner's file into Payments | `PaymentSource` | — | Adapter | FR-001 |
| BankCsvAdapter | Turn the bank statement into Payments | `PaymentSource` | — | Adapter | FR-002 |

## In constitution §5

```markdown
| E-016 | Outside formats stop at an adapter — no partner field names (vpa_note, amt_paise) past the adapters folder | Review; grep in the pipeline for partner field names outside adapters/ | Glossary · FR-<id> |
```

## Misuse smell

- Business rules **inside** the adapter ("if the amount looks too large, flag it") — the adapter translates, it does not decide.
- Partner field names (`amt_paise`) appearing in the rule, the database or the API.
