# Worked example — layer 3 for the society dues slice

The same invented housing society. Layer 2 left clean code for the rule. Layer 3 builds the rest
of the slice with the assistant (Session 11), then checks every AI-written line and uses the
assistant to make the **spec** sharper (Session 12).

| Look at | Session | Notice |
|---|---|---|
| `prompt-card-T010.md` | 11 | Context, task, limits, done-when, ask-first. And the plan that was stopped before any code |
| `bug-drill/` | 11 | A bug the tests do not catch. Evidence first, the missing test second, the fix last |
| `spec-review.md` | 12 | `/spec-review` found eight things. The group changed four, kept two with a reason, and asked the client two. Read *What the assistant got wrong* |
| `code/dues/match_by_hand.py` | 12 | FR-009 and FR-010 — requirements the spec review found missing, built after the spec changed |
| `code/tests/test_match_by_hand.py` | 12 | Each new requirement has its test, named after it |
| `L3-validation.md` | 12 | Four lenses. The first draft deleted records and accepted a flat that does not exist — both caught |

Run it (Python 3.10 or later):

```bash
cd code
pip install -r requirements.txt
python -m pytest -q && ruff check .
```

**The order matters.** Spec review first, then the code. The two rows that `/validate-ai-code`
marked *must* were already requirements by then — the code was catching up with the spec, which is
the way round it should be.
