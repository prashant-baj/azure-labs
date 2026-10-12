# Use case

> **A person does one thing.** One class per user goal — *record a cash payment*, *send this month's reminders*. It checks, decides, saves, and returns a result. It knows nothing about HTTP or SQL.

## When to use it

- Your spec's user stories or requirements read "The treasurer shall be able to…".
- The same action is reached from more than one place — a web page, an API, a nightly job, a test.
- You want the controller to be thin: read the request, call `.run()`, show the result.

## When not to

- Pure reads with no rule ("list all flats"). A repository call from the controller is fine.
- Do not make one use case call another use case — share a rule or a repository instead.

## Structure

```
web route / CLI / test ──▶ RecordCashPayment.run(...) ──▶ Payments, Flats (ports)
                                │
                                └── returns Result(ok, message)
```

`use_case_example.py` · `test_use_case.py` — every *If* row from the spec (duplicate receipt, no
such flat, zero amount) is a test, without a server or a database.

## In plan §12

| Component | Its one job | Exposes | Depends on | Pattern | Requirement IDs |
|---|---|---|---|---|---|
| RecordCashPayment | Record one cash payment for one flat | `run(flat, amount, receipt_no, treasurer)` | `Payments`, `Flats` | Use case | FR-006 |

Name it **verb + object** in the client's words. Its docstring names the requirement.

## In constitution §5

```markdown
| E-018 | One use case per user goal, named verb + object; controllers only translate the request and call it | Review against plan §12; a test per If row that calls the use case directly | Single responsibility · FR-<id> |
```

## Misuse smell

- A `PaymentService` with fifteen methods — that is fifteen use cases in one class.
- Request objects, HTTP status codes or SQL inside the use case.
- Validation duplicated in the controller **and** the use case.
