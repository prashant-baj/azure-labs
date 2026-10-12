# L · Liskov substitution

> **Anything that claims to be a `Notifier` must keep the `Notifier`'s promise — so one can replace another without surprises.**

## The problem

`lsp_before.py` — the `Notifier` promise is: *try to deliver, return `False` if you cannot, never
raise*. `SmsNotifier` keeps it. `EmailNotifier` does not — a flat without an email raises a
`KeyError`, and `remind_all` stops for **every** flat after it. The code "is a" `Notifier` by its
type, but not by its behaviour. The usual "fix" is an `isinstance()` check in the caller, which
is the smell itself.

## The fix

`lsp_after.py` — `EmailNotifier` returns `False` for a missing email, exactly like `SmsNotifier`.
The promise is written on the interface, and `test_lsp.py` has **one contract test that runs
against every notifier**. A new `WhatsAppNotifier` must pass the same test before it is merged.

## How to spot it

- `isinstance()` / `instanceof` / type checks in the code that *uses* an interface.
- A subclass method that raises `NotImplementedError`, or quietly does nothing.
- One implementation needs a `try/except` around it that the others do not.

## Review tip

Ask: *"If I swap this implementation for the other one, does the caller change?"* If yes, the
promise is broken — or was never written down.

## In your constitution

An **optional** rule — add it to §5 when your plan has a port with more than one adapter (or a fake).

```markdown
| E-014 | Every port's promise (inputs, outputs, errors) is written on the interface, and one contract test runs against every adapter and every fake. | A contract test, parametrised over all implementations |
```

## Why it matters on this programme

Your **fake** adapters (Session 10, 12) are substitutes. A fake that keeps a different promise
than the real adapter makes your tests pass and production fail.
