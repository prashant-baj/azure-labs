# Worked example — layer 2 for the society dues slice

The same invented housing society as Session 9. Here, the assistant generated code for a few tasks,
the group accepted it without review, and then did layer 2 properly: rules first, then review, then
refactoring in small steps with the rule examples holding the behaviour.

| Look at | Notice |
|---|---|
| `constitution-section-5.md` | Seven engineering rules, each with **how it is checked**. The group did not take all twelve starters |
| `plan-section-12.md` | Each component has one job, said without "and". The rule depends on ports, not on the database. A class diagram, as code |
| `before/` | Code that **works** — all rule examples pass — and is still hard to live with. Read it as a reviewer would before you open the review |
| `L2-review.md` | Every finding names a rule and a line. The group decided each one: fix, debt, or overrule — with a reason |
| `after/` | The same examples, the same answers. The rule now runs without a database (`tests/test_matcher.py`) |
| `tech-debt.md` | What was not fixed today, what it costs, and when it gets paid |

Run it (Python 3.10 or later, `pip install pytest ruff`):

```bash
cd before && python -m pytest -q && ruff check .     # tests pass, the linter does not
cd ../after && python -m pytest -q && ruff check .   # both pass
```

The linter rules in each `pyproject.toml` are the engineering rules made into checks — E-003
(complexity) and E-006 (no catch-all).
