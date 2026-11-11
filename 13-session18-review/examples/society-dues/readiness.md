# Readiness checklist — society dues, slice 001

*In a real repo this is `specs/design/readiness.md`, and the evidence paths below are repo paths. It was filled in
with `/readiness-check` in Session 18, scored by the board, and updated after the fixes. Thirteen of seventeen
production lines and four of twelve operations lines are met. Every gap is owned.*

## 1. Production readiness

| ID | Area | Check | Evidence | Status | Finding / note |
|---|---|---|---|---|---|
| PR-01 | Requirements | Every NFR has a number, and the pipeline measures it | `specs/design/test-strategy.md` CS-007, CS-008; `job:confidence:deploy` | met | |
| PR-02 | Requirements | Key decisions are ADRs, and the ADRs match what was built | `specs/design/adr/0001-architecture-and-stack.md` | partly | REV-04: the ADR says PostgreSQL; the slice runs SQLite in memory |
| PR-03 | Requirements | Every accepted risk names who agreed | `specs/design/threat-model.md` §3 | met | |
| PR-04 | Architecture | The code follows the architecture in the ADRs | `code/dues/ports.py` | partly | REV-04 |
| PR-05 | Architecture | Every outside call has a timeout and a retry rule; duplicates are handled | `code/tests/test_api.py` FR-004 duplicate tests | partly | Duplicates handled; no outside calls yet — timeouts and retries go in the backlog for the bank webhook slice |
| PR-06 | Code quality | Quality gates green on main | `ci/quality.yml`; last pipeline on main | met | |
| PR-07 | Code quality | Tests named after IDs; the suite grew; the ratchet holds | `specs/design/test-strategy.md` CS-002, CS-003 | met | |
| PR-08 | Security | Every threat has a control and a test | `specs/design/threat-model.md` §2; `code/tests/test_security.py` | met | |
| PR-09 | Security | No secret in any file; the app fails closed | `infra/secrets.tf`; `test_sec_001_t02_no_key_configured_means_nobody_gets_in` | met | |
| PR-10 | Security | `dast.high = 0` on the running service | `job:verify:dast`; strategy CS-009 | met | |
| PR-11 | Security | No personal data in logs or telemetry | `test_obs_004_t06_the_log_line_names_the_requirement_never_the_payer` | met | |
| PR-12 | Release | Built once; all infrastructure in code | `job:build:image`; `infra/` | met | |
| PR-13 | Release | Every merge deploys, verifies and decides — CONFIDENT | last `confidence.md` on main, 12 of 12 | met | |
| PR-14 | Release | Rollback in one step, and tried | `job:rollback:test`; drill table, `specs/design/observability.md` §4 | met | |
| PR-15 | Observability | Business and technical signal on a dashboard | `infra/observability.tf` workbook; `specs/design/observability.md` | met | |
| PR-16 | Observability | Alerts from the NFRs, a receiver, proved by a drill | `infra/observability.tf`; drill table | partly | REV-03: the errors alert never fired in the drill |
| PR-17 | Observability | One request findable by its id | `code/dues/telemetry.py` RequestId; `test_obs_003_every_response_carries_its_request_id` | met | |

## 2. Operations readiness

| ID | Area | Check | Evidence | Status | Finding / note |
|---|---|---|---|---|---|
| OR-01 | Runbook | Deploy, roll back, rotate a secret, each alert | `ops/runbook.md` | met | REV-02 done: secret rotation added |
| OR-02 | Ownership | A named owner and an on-call route; alerts reach them | `ops/runbook.md` §8; action group `society-dues-team` | partly | Owner named; no on-call route outside office hours — backlog, Session 19 |
| OR-03 | Service level | An SLO agreed with the client, from the NFR | | gap | FB-02: the secretary has not agreed a target yet — backlog, asked |
| OR-04 | Incidents | Severity levels, who decides, how the client is told; postmortem template | `ops/runbook.md` §5 | partly | Severity and escalation written; no postmortem template — backlog |
| OR-05 | Recovery | Backup, a restore tried, recovery targets agreed | | gap | REV-01: payments live in memory — a restart loses them. High |
| OR-06 | Capacity | Minimum and maximum replicas; what happens at the limit | `infra/main.tf` min 1, max 1 | met | One replica on purpose while the store is in memory — REV-01 |
| OR-07 | Cost | A monthly cost estimate; a budget alert | | gap | Backlog, Session 19 |
| OR-08 | Dependencies | Each outside system's owner, support contact, what we do when it is down | | n.a. | No outside system in this slice; the bank webhook arrives later |
| OR-09 | Data | Retention and deletion of personal data; who may see it | `specs/design/threat-model.md` T-01..T-03 | partly | Who may see it: met. Retention: not decided — FB-03 |
| OR-10 | Change | Release notes per deploy; who approves production | `ops/runbook.md` §2 | partly | Release notes from merge requests; production approver not named — backlog |
| OR-11 | Configuration | Every setting documented | `ops/runbook.md` §1 | met | |
| OR-12 | Handover | Someone outside the group deployed and rolled back from the runbook | board slot — Group B ran `rollback:test` from §3 | met | |

## 3. The case

| ID | Area | Check | Evidence | Status | Finding / note |
|---|---|---|---|---|---|
| CR-01 | Society | A payment the bank sent twice is never counted twice | `test_fr_004_*`; Postman FR-004 | met | |
| CR-02 | Society | The treasurer can show the committee who paid, for any month, after a restart | | gap | REV-01 |

## 4. The board's verdict

**Verdict:** Go with conditions — REV-01 decided as a spec change with an owner before any real data is entered.

**Conditions** (each a `REV-0nn` with an owner): REV-01 (spec change, then Session 19, owner: the anchor); REV-03
(fixed today, test first).
