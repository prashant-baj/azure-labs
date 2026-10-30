# Test strategy — society dues, slice 001

*`specs/design/test-strategy.md` in a real repo. Written with `/test-strategy` in Session 14, from the spec,
the NFR register, the quality gates and the trace's "none yet" list. The pipeline reads the last table.*

## 1. What could go wrong — and what would hurt most

| Risk | Hurts whom | Where it would show | Proved by |
|---|---|---|---|
| A payment matched to the wrong flat | Treasurer, the resident reminded wrongly | RULE-001 | unit (rule examples), scenarios |
| A payment counted twice — UPI and statement | Treasurer's books | FR-004 | unit, API, scenario |
| A resident sees who paid what | The society — C-002 | role check | API (403), DAST later (S16) |
| The reminder list includes a flat that paid this morning | Residents, the treasurer's credibility | FR-008 | scenario, API, end-to-end |
| The answer is too slow at the gate | Secretary — NFR-001 | under load | performance smoke |
| Two requests at once corrupt the store | Everyone | concurrency | performance smoke, then a regression test (DEF-001) |

## 2. The layers — what each proves, where it runs

| Layer | Proves | Tool | Runs | Before merge | After deploy |
|---|---|---|---|---|---|
| Unit | The rules, one example at a time | pytest | `test` job | yes | — |
| Scenarios | The behaviour, in the client's words | pytest-bdd | `scenarios` job | yes | — |
| Integration / API, in-process | Routes call the use cases; roles enforced | pytest + TestClient | `test` job | yes | — |
| API, over HTTP | The contract of the running service | Postman, Newman | `api:local`, `verify:api` | yes, on the app in the job | yes, on the test environment |
| End to end | One journey the treasurer would notice | Playwright | `verify:e2e` | — | yes |
| Performance smoke | NFR-001 at a few users; no errors under concurrency | k6 | `verify:perf` | — | yes |
| Quality gates | Lint, complexity, secrets, SAST, dependencies, IaC | Session 13 | `qa:*` | yes | — |

**Not automated yet, and why:** full load test (needs a production-sized environment — Session 17);
DAST (Session 16); mobile (no mobile client in this slice).

## 3. Regression

Every test above runs on every push. A defect found anywhere gets a test **at the lowest layer that can
catch it** before it is fixed (DEF-001: found by k6, pinned by a unit-level concurrency test).

## 4. AI-suggested tests

Generated with `/suggest-tests`, marked `ai_suggested` in the test name or a comment, read by a person, run
red against a broken version before they are kept. Kept, changed and rejected are logged in
`reviews/ai-tests.md`.

## 5. Confidence thresholds

*The pipeline reads this table (`ci/confidence.py`). `merge` rows are checked on every merge request,
`deploy` rows after every deploy to the test environment. Change a threshold here, in a merge request — never
in the pipeline.*

| ID | Signal | Measure | Threshold | Source | When |
|---|---|---|---|---|---|
| CS-001 | Unit, integration and scenario tests pass | tests.pass_rate | = 100 | W-003, QG-007 | merge |
| CS-002 | The suite only grows | tests.count | >= 39 | ratchet — count at L5 start | merge |
| CS-003 | Line coverage | coverage.line | >= 95 | ratchet — today's baseline | merge |
| CS-004 | API checks pass on the running service | api.pass_rate | = 100 | FR-001, 003, 004, 006, 008, C-002 | merge |
| CS-005 | The deployed service is this commit | smoke.version | = 1 | deploy | deploy |
| CS-006 | The treasurer's journey works end to end | e2e.pass_rate | = 100 | FR-008 | deploy |
| CS-007 | Dues answer, 95th percentile | perf.p95_ms | <= 2000 | NFR-001 | deploy |
| CS-008 | Requests failing under load | perf.error_rate | < 1 | NFR-002, DEF-001 | deploy |

## 6. The pipeline — every row, the job that measures it

*Drawn on Session 14's whiteboard, before anyone touched the YAML. In Session 14 the deploy half ran as orange
`(planned)` jobs; Session 15 turned `CONFIDENCE_DEPLOY` on and every row below became real.*

| Rows | Job | Stage | Session 14 | Session 15 |
|---|---|---|---|---|
| — | `qa:lint`, `qa:complexity`, `qa:secrets` | check | real | real |
| CS-001, CS-002, CS-003 | `test`, `scenarios` | test | real | real |
| — | `qa:sast`, `qa:dependencies`, `qa:iac` | test | real | real |
| CS-004 | `api:local` — uvicorn in the job, Newman against it | test | real | real |
| — | `build:image`, `deploy:test` | deploy | planned | real |
| CS-005 | `verify:smoke` | verify | planned | real |
| CS-004 | `verify:api` — the same collection, the deployed URL | verify | planned | real |
| CS-006 | `verify:e2e` — the treasurer's journey | verify | planned | real |
| CS-007, CS-008 | `verify:perf` — k6 on `/reminders` and `/payments/upi` | verify | planned | real |
| merge rows | `confidence:merge` | .post | real | real (branches) |
| every row | `confidence:deploy` | .post | planned | real (main) |
