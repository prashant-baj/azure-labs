# I · Interface segregation

> **Ask only for what you use. Many small interfaces beat one big one.**

## The problem

`isp_before.py` — one `SocietyRepository` with eight methods. The reminder job only reads dues and
payments, yet it depends on `delete_member()` and `export_csv()` too. Every test fake must
implement all eight. And nothing stops the reminder job from calling `delete_member()` by mistake —
which, if your constitution has a "never delete" rule, is a compliance bug waiting to happen.

## The fix

`isp_after.py` — three small interfaces named for what callers need: `DuesReader`,
`PaymentWriter`, `MemberAdmin`. The reminder job asks for `DuesReader` only. One storage class
can still implement all three — splitting the interface does **not** mean splitting the database.

`test_isp.py` shows the difference: the fake shrinks from eight methods to three.

## How to spot it

- Fakes full of `pass` or `raise NotImplementedError` for methods the test never calls.
- An interface named after a thing (`SocietyRepository`) rather than a need (`DuesReader`).
- A component that *could* call a dangerous method it never needs.

## Review tip

Ask: *"Which of these methods does this caller actually use?"* If it is less than half, split.

## In your constitution

An **optional** rule — useful when one of your C-rules forbids an action (delete, send data out).

```markdown
| E-015 | Components depend on the smallest interface they use; read-only components get a read-only interface. | Review against plan §12 — each component lists the ports it uses |
```

## In your plan §12

In the components table, the *Depends on (interfaces only)* column should name the small interface (`DuesReader`), not
the whole repository.
