# Worked example — layer 3 for the society dues slice

The same invented housing society. Layer 2 left clean code for the rule. Layer 3 builds the rest
of the slice with the assistant (Session 11) and adds one AI-assisted feature — suggesting a flat
for an unmatched payment, with the treasurer deciding (Session 12).

| Look at | Session | Notice |
|---|---|---|
| `prompt-card-T010.md` | 11 | Context, task, limits, done-when, ask-first. And the plan that was stopped before any code |
| `bug-drill/` | 11 | A bug the tests do not catch. Evidence first, the missing test second, the fix last |
| `spec-additions.md` | 12 | The AI feature written as requirements first — *If* rows, a data rule (C-004), and an eval set |
| `code/dues/suggestion.py` | 12 | The model sits behind a port. The rest of the code does not know a model exists |
| `code/dues/suggest_for_unmatched.py` | 12 | Never trust the output: a flat outside the directory is thrown away |
| `code/tests/test_suggestion.py` | 12 | Our guardrails tested with a fake — no key, no network, no cost |
| `code/eval/` | 12 | The eval set — the AI feature's rule examples — and a runner that needs a real key |
| `L3-validation.md` | 12 | Four lenses. The first draft deleted records and sent a payer's name out — both caught |

Run it (Python 3.10 or later):

```bash
cd code
pip install -r requirements.txt
python -m pytest -q && ruff check .
python -m eval.run_eval          # skipped unless ANTHROPIC_API_KEY and SUGGESTER_MODEL are set
```

The real suggester needs an **API key** for the product — not the Claude Code login your
organisation gave you for the coding tool. If your group has no such key, demo the feature with
the fake suggester and show the eval set as the test you would run.
