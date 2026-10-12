# Patterns — pick by the situation, not by the name

A pattern is a **known answer to a problem you actually have**. Start from the situation in your
spec, then pick the pattern — never the other way round. Same order as Session 10, slide 12.

| When your spec says… | Pattern | What it does | Folder |
|---|---|---|---|
| Two partners send the same data in different formats | **Adapter** | Wraps each source so the rest of the code sees one shape | [`adapter/`](adapter/) |
| You only need to tidy values — trim, case, dates | **—** | No pattern. A plain function is enough | — |
| The spec lists different rules for different types of customer | **Strategy** | Each variant of the rule in its own class, chosen at run time | [`strategy/`](strategy/) |
| Today SQLite, tomorrow a cloud database — the rule must not care | **Repository** | Hides how data is stored behind simple methods | [`repository/`](repository/) |
| A person does one thing: record a payment, ask for dues | **Use case** | One entry point per action a person takes | [`use-case/`](use-case/) |
| Three systems want to know when a payment is matched | **Publisher** | Announces an event; any listener can subscribe | [`publisher/`](publisher/) |

Each folder has: **when to use it**, **when not to**, the structure, a runnable example and test,
the row it adds to **plan §12**, the rule it can add to **constitution §5**, and the misuse smell
a reviewer should look for.

```bash
pip install pytest
python -m pytest -q patterns/            # from 08-session10-excellence/
```

How patterns land in your specs: [`patterns-in-plan-and-constitution.md`](patterns-in-plan-and-constitution.md).
The principles behind them: [`../principles/`](../principles/).

## The rule of thumb

> If you cannot point to the line in **your** spec that needs the pattern, you do not need the
> pattern. A plain function that a junior can read beats a clever pattern that only you can.
