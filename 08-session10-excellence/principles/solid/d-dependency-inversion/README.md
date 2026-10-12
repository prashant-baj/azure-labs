# D · Dependency inversion

> **The rule does not reach for the database, the clock or the gateway. It asks for them — through small interfaces — and someone outside plugs them in.**

## The problem

`dip_before.py` — `ReminderJob` opens `society.db`, reads today's date and prints an "SMS" itself.
The most important line in the file — *remind after fifteen days* — cannot be tested without a
real database file, waiting for the right calendar date, and an SMS account. Changing SQLite to a
cloud database means editing the rule.

## The fix

`dip_after.py` — the rule declares three **ports**: `DuesSource`, `Clock`, `Notifier`. It imports
no database, clock or gateway library. Real adapters (SQLite, system clock, SMS) are written
separately and wired together in one place — the *composition root* (`main.py`, or your
framework's dependency-injection setup).

`test_dip.py` tests "day 15 → nothing, day 16 → remind" in milliseconds, with three tiny fakes.

## The direction rule

```
adapters (SQLite, SMS, HTTP)  ──depend on──▶  ports  ◀──used by──  the rule
```

Arrows point **inward**. The rule never imports an adapter. This is the same rule your
Session 9 ADR and Session 10 component diagram already show.

## How to spot it

- `import sqlite3` / `requests` / an ORM / `datetime.now()` inside the business rule.
- `new SomeConcreteThing()` inside the rule instead of receiving it.
- A unit test that needs `docker compose up` first.

## Review tip

Open the rule's file and read only its imports. Anything that talks to the outside world is a
finding.

## In your constitution

This one is already in the template — **E-004**:

```markdown
| E-004 | The rule depends on nothing outside it. Inputs, storage and notifications sit behind interfaces (ports); the rule imports no framework, database or HTTP library. | A test that runs the rule with no database; an architecture check |
```

Stack note — "an architecture check" can be a tool: `import-linter` (Python), ArchUnit (Java),
`dependency-cruiser` (Node), NetArchTest (.NET). A review checklist line is enough to start.
