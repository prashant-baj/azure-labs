# Publisher (observer / domain events)

> **Three systems want to know when something happens.** The component announces an event; any listener can subscribe. It does not know — or care — who is listening.

## When to use it

- One happening triggers several follow-ups: *payment matched* → send the receipt, update the ledger, refresh the dashboard.
- More follow-ups are likely later, and you do not want to edit the matcher each time.
- The follow-ups can fail without undoing the main thing (a mail server down must not "unmatch" a payment).

## When not to

- Only one thing ever happens next, and it must succeed with the main step. Call it directly.
- The order of listeners matters to correctness. Then it is a workflow — write it as one, explicitly.

## Structure

```
Matcher ──publish(PaymentMatched)──▶ EventPublisher ──▶ receipt mailer
                                                     ├──▶ ledger
                                                     └──▶ dashboard  (added later, matcher unchanged)
```

`publisher_example.py` · `test_publisher.py` — every listener hears it; a new listener needs no
change to the matcher; a failing listener is **logged** and does not stop the others.

This example is in-process. In Sessions 16–17 the same idea can move to a queue or a cloud event
service — the matcher's code stays the same if it only talks to the publisher port.

## In plan §12

| Component | Its one job | Exposes | Depends on | Pattern | Requirement IDs |
|---|---|---|---|---|---|
| Matcher | Match a payment to a flat and announce it | `match()` | `PaymentRepository`, `EventPublisher` | Publisher | FR-003 |
| ReceiptMailer | Send a receipt when a payment is matched | listens to `PaymentMatched` | `Notifier` | — | FR-007 |

Add the events to §11 (a sequence diagram shows publish → listeners well).

## In constitution §5

```markdown
| E-019 | Follow-ups to a domain event are listeners, not calls inside the component that raised it; events are named in the past tense in glossary words | Review against plan §12 | Open–closed |
| E-006 | No silent failures — a failing listener is logged, never swallowed | Linter (blind except) + a test with a failing listener | W-006 |
```

## Misuse smell

- Events used to return a value ("publish and wait for the answer") — that is a function call in disguise.
- A chain of events nobody can follow — if a reviewer needs a whiteboard to trace one payment, call things directly.
- `except: pass` around listeners.
