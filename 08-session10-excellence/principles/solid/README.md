# SOLID — five principles, five small examples

Each folder has the same four files: a `README.md` (the principle, the smell, the review tip, the
constitution rule), a `*_before.py` that works but hurts, a `*_after.py` that fixes it, and a
`test_*.py` that proves the fix kept the behaviour. All examples use the same invented housing
society, so you can compare them.

| | Principle | In one line | Example | Rule in §5 |
|---|---|---|---|---|
| **S** | [Single responsibility](s-single-responsibility/) | One job, one reason to change | Reminder service split into rule, wording, sender | E-002 (template) |
| **O** | [Open–closed](o-open-closed/) | Add behaviour by adding code, not editing working code | Late fee by unit type — no `if/elif` chain | E-013 (optional) |
| **L** | [Liskov substitution](l-liskov-substitution/) | A substitute keeps the same promise | Email and SMS notifiers — one contract test | E-014 (optional) |
| **I** | [Interface segregation](i-interface-segregation/) | Ask only for what you use | Fat repository split into `DuesReader`, `PaymentWriter`… | E-015 (optional) |
| **D** | [Dependency inversion](d-dependency-inversion/) | The rule asks for ports; adapters plug in from outside | Reminder job with injected source, clock, notifier | E-004 (template) |

Run them all: `python -m pytest -q` (from this folder).

**Read the "Do not overdo it" notes too.** SOLID applied everywhere gives you forty files for a
forty-line feature. Apply a principle when its smell is actually in your code.
