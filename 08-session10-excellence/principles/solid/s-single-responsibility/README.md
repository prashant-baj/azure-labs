# S · Single responsibility

> **A class or module has one job — and so only one reason to change.**

## The problem

`srp_before.py` — one `ReminderService` works out what is due, writes the message **and** sends it.
Three different people can ask for three different changes (the treasurer changes the rule, the
committee changes the wording, the society changes the SMS gateway) — and all three edit the same
class. Each change risks breaking the other two, and the dues rule cannot be tested without
pretending to send an SMS.

## The fix

`srp_after.py` — three small pieces and one that puts them together:

| Piece | Its one reason to change |
|---|---|
| `DuesCalculator` | The dues rule |
| `reminder_text()` | The wording |
| `SmsNotifier` | The gateway |
| `ReminderService` | The order of the steps — nothing else |

`test_srp.py` proves the behaviour did not change, and then tests the rule on its own.

## How to spot it

- The class name ends in *Manager*, *Service*, *Helper* or *Utils* and nobody can say its job in one sentence.
- Describing its job needs the word **"and"**.
- The test for one rule needs a fake for something unrelated (a database, a gateway, a clock).

## Review tip

Ask: *"Who would ask for this class to change?"* More than one answer → more than one job.

## In your constitution

```markdown
| E-002 | Each component has one job, stated in one sentence without "and" (plan §12). | Review against plan §12 |
```

## Do not overdo it

One job is not one method. Do not split a ten-line class into five files just to say you did.
Split when two reasons to change are **actually** pulling at the same code.
