# Python — pytest-bdd

```
pyproject.toml                  bdd_features_base_dir, markers
features/month_paid.feature     in your repo: specs/NNN-<slice>/features/
dues/month_status.py            the rule - built test-first
tests/test_rule_002.py          unit tests, one per example
tests/step_defs/test_month_paid.py   thin steps; scenarios("month_paid.feature")
```

## Wire it into your repo

1. `requirements.txt` (or your dependency file): add `pytest-bdd`.
2. `pyproject.toml`, under `[tool.pytest.ini_options]`:
   ```toml
   bdd_features_base_dir = "specs/001-<slice>/features/"   # relative to the folder pytest runs from
   markers = ["US-001", "FR-001", "RULE-001"]               # every tag you use - keeps the run quiet
   ```
   If your code sits in a sub-folder (`code/`, `backend/`), the path starts with `../`.
3. Step files in `tests/step_defs/test_<feature>.py`, each starting with `scenarios("<feature>.feature")`.
   `pytest` collects them with your unit tests — your existing `test` job runs them already.
4. `ci/scenarios.yml` (setup-quality adds it) runs `tests/step_defs` alone, with a junit report.

## Gotchas

- An Examples column is passed to steps as text — parse it (`{amount:d}`) or convert in the step.
- Use `target_fixture=` to hand a value from one step to the next; never a module-level variable.
- `pytest -k RULE_002b` runs one example: outline rows become test ids.
