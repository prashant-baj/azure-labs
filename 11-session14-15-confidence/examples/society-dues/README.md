# Worked example — layer 5 for the society dues slice

The same invented housing society. Layer 4 proved the behaviour and set the quality bar. Layer 5 makes the
**confidence measurable**: a test strategy whose last table the pipeline decides on, a suite that grew,
API checks on the running service, a deploy that verifies itself — and one real defect the performance
smoke found that no earlier layer could.

Read it in this order — it is the order the group worked in:

| # | Look at | Notice |
|---|---|---|
| 1 | `test-strategy.md` | Six risks, each with the layer that catches it. *Not automated yet, and why* is honest. The thresholds: two ratchets measured that day, performance from **NFR-001**, not a round number. Section 6: the pipeline drawn from the rows — what was real in Session 14, what was planned |
| 2 | `reviews/ai-tests.md` | Six AI-suggested tests: three kept (each seen red), two rejected — they encoded a decision the client never made — one not needed |
| 3 | `code/tests/test_api.py` | In-process API tests, named after their IDs: the role check (C-002), duplicates (FR-004), bad amounts (FR-001) |
| 4 | `tests/api/dues.postman_collection.json` | The same contract over HTTP, 14 assertions: `SMOKE` checks the version; every test starts with its ID; one collection for `local` and `test` |
| 5 | `tests/perf/smoke.js` | Five users, thirty seconds, on the requests NFR-001 is about — not `/health` |
| 6 | `defects/DEF-001.md` | What that smoke found: two requests at once broke the store. Evidence, cause, why every earlier layer missed it, the test that pins it |
| 7 | `code/tests/test_concurrency.py` | DEF-001 pinned at the lowest layer that can catch it — it fails without the fix |
| 8 | `tests/e2e/` | **One** journey the treasurer would notice, in a real browser |
| 9 | `ci/confidence.yml` | `APP_DIR`, `APP_START`, `CONFIDENCE_DEPLOY: "on"` — three lines changed; the rest is the lab's |
| 10 | `confidence-example.md` | The scorecard after a deploy: 8 of 8 — and every row says where its threshold came from |

Run it (Python 3.10 or later, Node 20 or later, k6):

```bash
cd code
pip install -r requirements.txt
python -m pytest -q --junitxml=../report.xml --cov=dues --cov-report=xml:../coverage.xml     # unit, API in-process, scenarios
APP_VERSION=local uvicorn dues.api:app --port 8000 &                                        # the app, for the next three

cd ..
npx newman@6.2.3 run tests/api/dues.postman_collection.json -e tests/api/local.postman_environment.json
k6 run -e BASE_URL=http://localhost:8000 -e P95_MS=2000 -e ERROR_RATE=0.01 tests/perf/smoke.js
(cd tests/e2e && npm ci && npx playwright install chromium && BASE_URL=http://localhost:8000 npx playwright test)

python3 ../../ci/confidence.py --strategy test-strategy.md --when merge      # the merge scorecard
```

See the defect for yourself: in `code/dues/api.py`, give `Store` a lock that does nothing —
`self._lock = contextlib.nullcontext()` (and `import contextlib`). Restart the app, run k6 again, then
`python -m pytest tests/test_concurrency.py`. Put it back.

**In your repo** the strategy is `specs/design/test-strategy.md` and defects go in `specs/design/defects/`.
Here they sit at the top so the example stays small.
