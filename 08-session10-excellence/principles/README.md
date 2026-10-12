# Principles — clean code and SOLID, with examples you can run

This folder is **reading and reference** for the Session 10 workshop. It does not change your
repository. Use it to choose the rules for **constitution §5** and to review your own code.

| Folder | What is in it |
|---|---|
| [`clean-code/`](clean-code/) | Six habits on one before/after example, with a test that proves the answers did not change |
| [`solid/`](solid/) | One folder per SOLID principle — problem, fix, smell, review tip, constitution rule |
| [`in-your-constitution.md`](in-your-constitution.md) | How these become §5 rows in **your** `constitution.md` — with "Checked by" |

All code is Python because it is short to read. The ideas are the same in Java, Node or .NET —
each README names the tool that checks the rule in other stacks where one exists.

```bash
pip install pytest
python -m pytest -q principles/          # from 08-session10-excellence/
```

Patterns (Adapter, Strategy, Repository…) are in [`../patterns/`](../patterns/).
