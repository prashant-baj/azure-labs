# Worked example — layer 4 for the society dues slice

The same invented housing society. Layer 3 left a slice that works. Layer 4 **proves the behaviour** and **sets the quality bar**:
the group scans its own repo and writes the quality gates into the spec, turns them on in the pipeline,
talks the rules through as examples, writes them as stories and scenarios the treasurer could read, and
builds the one undecided rule test-first.

Read it in this order — it is the order the group worked in:

| # | Look at | Notice |
|---|---|---|
| 0a | `findings-triage.md` | The first local scan found a "secret" that was not one, and nine IaC findings. Each got a decision and a reason — and the assistant's first two proposals were wrong |
| 0b | `quality-gates.md` | Seven gates, each naming the rule it enforces. Lint, secrets, SAST and dependencies block; complexity and IaC are ratchets from today's count |
| 0c | `ci/quality.yml` | The pipeline follows the spec: limit 5 (E-003), baselines 0 and 7. `infra/main.tf` shows the inline skips, each with its reason |
| 1 | `example-map.md` | Twenty minutes, four colours of card. One question answered on the spot became **RULE-002**; two stayed open — and stayed out of the code |
| 2 | `spec-changes.md` | The spec changed **first**: a new rule, closed and new questions, and a trace with a *Scenario* column. The last trace row shows what is not proved yet |
| 3 | `stories.md` | Two stories. Every acceptance criterion says which requirement or rule row it proves |
| 4 | `features/*.feature` | Business words only — no clicks, no tables, no SQL. Every scenario tagged with its IDs. The *Examples* rows are the spec's rule rows, word for word |
| 5 | `code/tests/step_defs/` | Thin steps: each one calls the real use case. No logic in a step |
| 6 | `tdd-log.md` | Five red–green–refactor cycles on RULE-002, one commit each. A test that went green at once — and was broken on purpose before it was kept |
| 7 | `code/dues/month_status.py` | What came out of it: a few lines, pure, every line demanded by a test |

Run it (Python 3.10 or later):

```bash
cd code
pip install -r requirements.txt
python -m pytest -q                          # unit tests and scenarios together
python -m pytest -q tests/step_defs -v       # the scenarios alone, named as in the feature files
ruff check . && ruff format --check .
```

And the quality gates, as the pipeline runs them (from the lab folder, on a git repo holding this example):

```bash
../../quality-local.sh <repo>               # lint, complexity, secrets, SAST, dependencies, IaC
```

Break something and watch it go red: in `dues/month_status.py`, change `<= 0` to `< 0`. Six tests fail —
scenarios and unit tests both. Put it back.

**In your repo** the feature files go in `specs/NNN-<slice>/features/` — next to the spec they prove.
Here they sit in `features/` so the example stays small.
