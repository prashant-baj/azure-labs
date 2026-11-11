# Readiness checklist — <slice>

*`specs/design/readiness.md`. Filled in with `/readiness-check` in Session 18, then scored by the review board.
Every line is a claim, and every claim needs **evidence** — a file, a test, a pipeline job, a dashboard. No
evidence, no `met`.*

**Status:** `met` (evidence attached) · `partly` (some of it — say what is missing) · `gap` (not there) · `n.a.`
(does not apply — say why). A `partly` or `gap` line names its finding (`REV-0nn`) or backlog item in the last
column; an honest gap is worth more than a `met` the board cannot see.

## 1. Production readiness — will it work, and stay safe, when real people use it?

| ID | Area | Check | Evidence | Status | Finding / note |
|---|---|---|---|---|---|
| PR-01 | Requirements | Every NFR has a number, and the pipeline measures it | | | |
| PR-02 | Requirements | Key decisions are ADRs, and the ADRs match what was built | | | |
| PR-03 | Requirements | Every accepted risk names who agreed | | | |
| PR-04 | Architecture | The code follows the architecture in the ADRs — no dependency nobody decided | | | |
| PR-05 | Architecture | Every outside call has a timeout and a retry rule; duplicates are handled | | | |
| PR-06 | Code quality | Quality gates green on main: lint, complexity, SAST, dependencies, IaC | | | |
| PR-07 | Code quality | Tests are named after the IDs they prove; the suite grew; the coverage ratchet holds | | | |
| PR-08 | Security | Every threat in the threat model has a control and a test | | | |
| PR-09 | Security | No secret in any file; the app fails closed without its secrets | | | |
| PR-10 | Security | No high-risk finding on the running service (`dast.high = 0`) | | | |
| PR-11 | Security | No personal data in logs, metric attributes or traces | | | |
| PR-12 | Release | Built once — the image tested is the image deployed; all infrastructure in code | | | |
| PR-13 | Release | Every merge to main deploys, verifies and decides — the last scorecard says CONFIDENT | | | |
| PR-14 | Release | Rollback in one step — and it has been tried | | | |
| PR-15 | Observability | One business and one technical signal on a dashboard anyone can read | | | |
| PR-16 | Observability | Alerts with lines from the NFRs, a receiver, and a drill that proved they fire | | | |
| PR-17 | Observability | One request can be found end to end by its id | | | |

## 2. Operations readiness — can someone run it at two in the morning without you?

| ID | Area | Check | Evidence | Status | Finding / note |
|---|---|---|---|---|---|
| OR-01 | Runbook | `ops/runbook.md`: deploy, roll back, rotate a secret, and what to do for each alert | | | |
| OR-02 | Ownership | A named owner and an on-call route — and the alerts reach them | | | |
| OR-03 | Service level | A service level objective agreed with the client, from the NFR, and how it is measured | | | |
| OR-04 | Incidents | Severity levels, who decides, how the client is told; a blameless postmortem template | | | |
| OR-05 | Recovery | What data is backed up, how often, a restore tried; recovery time and data-loss targets agreed | | | |
| OR-06 | Capacity | Minimum and maximum replicas set; what happens at the limit | | | |
| OR-07 | Cost | A monthly cost estimate for each environment; a budget alert | | | |
| OR-08 | Dependencies | For every outside system: its owner, a support contact, and what we do when it is down | | | |
| OR-09 | Data | Retention and deletion of personal data; who may see production data | | | |
| OR-10 | Change | Release notes for every deploy; who approves a production release; freeze windows | | | |
| OR-11 | Configuration | Every setting documented — its default, where it is set, whether it is secret | | | |
| OR-12 | Handover | Someone outside the group deployed and rolled back from the runbook alone | | | |

## 3. Your case

*Two lines from your case study — what your client would check before go-live.*

| ID | Area | Check | Evidence | Status | Finding / note |
|---|---|---|---|---|---|
<!-- case lines -->

## 4. The board's verdict

*Filled in by the review board in step 4, copied from its scorecard.*

**Verdict:** Go · Go with conditions · Not yet — _(fill in)_

**Conditions** (each a `REV-0nn` with an owner): _(fill in)_
