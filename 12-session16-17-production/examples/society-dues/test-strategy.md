# Test strategy — society dues, slice 001

*In a real repo this is `specs/design/test-strategy.md`. It was written with `/test-strategy` in Session 14,
using the spec, the NFR register, the quality gates and the trace's "none yet" list. Session 16 added the threat
model's rows, and Session 17 added the observability rows. The pipeline reads the thresholds table.*

## 1. What could go wrong — and what would hurt most

| Risk | Hurts whom | Where it would show | Proved by |
|---|---|---|---|
| A payment matched to the wrong flat | Treasurer, the resident reminded wrongly | RULE-001 | unit (rule examples), scenarios |
| A payment counted twice — UPI and statement | Treasurer's books | FR-004 | unit, API, scenario |
| A resident sees who paid what | The society — C-002 | role check, T-01..T-03 | API (401, 403), security tests, DAST |
| The running service leaks through headers, the API explorer or the page | The society | T-04, T-05 | security tests, DAST (`verify:dast`) |
| It breaks in the test environment and nobody can tell | Treasurer, whoever is on call | OBS-001..003 | `verify:observability`, alerts, the drill |
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
| Security, in-process | Each control in the threat model works: key, headers, escaping | pytest (`test_security.py`) | `test` job | yes | — |
| DAST | What an attacker sees from outside the running service | OWASP ZAP baseline | `verify:dast` | — | yes |
| Observability | This commit's telemetry, and the business metric, reached Application Insights | `az monitor log-analytics query` | `verify:observability` | — | yes |

**Not automated yet, and why:** full load test (it needs a production-sized environment, and the test
environment is sized for the slice). An authenticated ZAP full scan (the baseline scan is passive; a full scan
belongs in a scheduled pipeline, not on every merge). The alerts themselves: they are proved by the drill, by
hand, once per change to `observability.tf`. Mobile (there is no mobile client in this slice).

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
| CS-009 | No high-risk finding on the running service | dast.high | = 0 | T-01..T-05 | deploy |
| CS-010 | Medium-risk findings only go down | dast.medium | <= 2 | ratchet: the first scan after SEC-002 | deploy |
| CS-011 | This commit's telemetry reached the workspace | obs.version | = 1 | OBS-002, OBS-003 | deploy |
| CS-012 | The business metric was recorded for this commit's traffic | obs.business | = 1 | OBS-001 | deploy |

## 6. The pipeline — every row, the job that measures it

*This table was drawn on Session 14's whiteboard, before anyone touched the YAML. In Session 14 the deploy half ran
as orange `(planned)` jobs. Session 15 turned `CONFIDENCE_DEPLOY` on. Session 16 added `verify:dast`, real from the
start, and drew `verify:observability` as planned. Session 17 set `OBSERVABILITY` to "on".*

| Rows | Job | Stage | S14 | S15 | S16 | S17 |
|---|---|---|---|---|---|---|
| — | `qa:lint`, `qa:complexity`, `qa:secrets` | check | real | real | real | real |
| CS-001, CS-002, CS-003 | `test`, `scenarios` | test | real | real | real | real |
| — | `qa:sast`, `qa:dependencies`, `qa:iac` | test | real | real | real | real |
| CS-004 | `api:local` — uvicorn in the job, Newman against it | test | real | real | real | real |
| — | `build:image`, `deploy:test` | deploy | planned | real | real | real |
| CS-005 | `verify:smoke` | verify | planned | real | real | real |
| CS-004 | `verify:api` — the same collection, the deployed URL | verify | planned | real | real | real |
| CS-006 | `verify:e2e` — the treasurer's journey | verify | planned | real | real | real |
| CS-007, CS-008 | `verify:perf` — k6 on `/reminders` and `/payments/upi` | verify | planned | real | real | real |
| CS-009, CS-010 | `verify:dast` — ZAP baseline on the deployed URL | verify | — | — | real | real |
| CS-011, CS-012 | `verify:observability` — this commit in the workspace | verify | — | — | planned | real |
| — | `drill:slow`, `drill:errors`, `drill:clear`, `rollback:test` (by hand) | verify | — | — | — | real |
| merge rows | `confidence:merge` | .post | real | real (branches) | real | real |
| every row | `confidence:deploy` | .post | planned | real (main) | real | real |
