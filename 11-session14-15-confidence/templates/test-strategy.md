# Test strategy — <slice>

*`specs/design/test-strategy.md`. Written with `/test-strategy` from the spec, the NFRs, the quality gates and
the trace's "none yet" list. The pipeline reads section 5; section 6 is the pipeline drawn from it.*

## 1. What could go wrong — and what would hurt most

| Risk | Hurts whom | Where it would show | Proved by |
|---|---|---|---|
| | | FR-0nn | unit / scenario / API / end to end / performance |

## 2. The layers — what each proves, where it runs

| Layer | Proves | Tool | Runs | Before merge | After deploy |
|---|---|---|---|---|---|
| Unit | The rules, one example at a time | | `test` | yes | — |
| Scenarios | The behaviour, in the client's words | | `scenarios` | yes | — |
| Integration / API, in-process | | | `test` | yes | — |
| API, over HTTP | The contract of the running service | Postman, Newman | `api:local`, `verify:api` | yes | yes |
| End to end | The journeys the client would notice — few | | `verify:e2e` | — | yes |
| Performance smoke | The NFR thresholds at a few users | k6 | `verify:perf` | — | yes |
| Quality gates | Session 13 | | `qa:*` | yes | — |

**Not automated yet, and why:**

## 3. Regression

Every test runs on every push. A defect gets a test at the lowest layer that can catch it, before the fix.

## 4. AI-suggested tests

Marked `ai_suggested`, read by a person, seen red before kept. Logged in `reviews/ai-tests.md`.

## 5. Confidence thresholds

*Read by `ci/confidence.py`. Measures: tests.pass_rate · tests.count · coverage.line · api.pass_rate ·
e2e.pass_rate · perf.p95_ms · perf.error_rate · smoke.version — or `planned.<name>` for a check designed but
not built yet (shown on the scorecard, never counted as met). When: merge (checked before merge **and** after
deploy) or deploy (after deploy only).*

| ID | Signal | Measure | Threshold | Source | When |
|---|---|---|---|---|---|
| CS-001 | Unit, integration and scenario tests pass | tests.pass_rate | = 100 | W-003 | merge |
| CS-002 | The suite only grows | tests.count | >= <today's count> | ratchet | merge |
| CS-003 | Line coverage | coverage.line | >= <today's %> | ratchet | merge |
| CS-004 | API checks pass on the running service | api.pass_rate | = 100 | <FR IDs> | merge |
| CS-005 | The deployed service is this commit | smoke.version | = 1 | deploy | deploy |
| CS-006 | <the journey> works end to end | e2e.pass_rate | = 100 | <FR> | deploy |
| CS-007 | <the answer>, 95th percentile | perf.p95_ms | <= <from NFR> | NFR-0nn | deploy |
| CS-008 | Requests failing under load | perf.error_rate | < <from NFR> | NFR-0nn | deploy |

*CS-004 is `merge` when `APP_START` lets the pipeline start your app (`api:local`); if it cannot yet, make it
`deploy` and say why under "Not automated yet".*

## 6. The pipeline — every row, the job that measures it, and when it is real

*Drawn from section 5. Jobs marked planned run today as orange `(planned)` placeholders. A check your strategy
rules out has no job — and a line under "Not automated yet".*

| Rows | Job | Stage | Today | Real from |
|---|---|---|---|---|
| — | `qa:lint`, `qa:complexity`, `qa:secrets` | check | real | Session 13 |
| CS-001, CS-002, CS-003 | `test` (your job), `scenarios` | test | real | — |
| — | `qa:sast`, `qa:dependencies`, `qa:iac` | test | real | Session 13 |
| CS-004 | `api:local` | test | <real / planned> | <today / when APP_START is set> |
| — | `build:image`, `deploy:test` | deploy | planned | Session 15 |
| CS-005 | `verify:smoke` | verify | planned | Session 15 |
| CS-004 | `verify:api` | verify | planned | Session 15 |
| CS-006 | `verify:e2e` | verify | planned | Session 15 |
| CS-007, CS-008 | `verify:perf` | verify | planned | Session 15 |
| merge rows | `confidence:merge` | .post | real | — |
| every row | `confidence:deploy` | .post | planned | Session 15 |
