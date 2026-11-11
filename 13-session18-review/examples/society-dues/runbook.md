# Runbook — society dues API

*In a real repo this is `ops/runbook.md`. Drafted with `/runbook` from the pipeline, `infra/` and the alert rules,
then tried by a member of another group in the board slot (OR-12): they ran `rollback:test` from section 3 alone.*

## 1. The service at a glance

| | |
|---|---|
| What it does, in one sentence | Matches UPI payments to flats and lists the flats still to pay this month, for the treasurer and the secretary |
| Owner, and the on-call route | The group anchor (owner); in office hours the Maintainer, through the GitLab issue board. No route out of hours yet — OR-02, backlog |
| Test environment URL | GitLab → Operate → Environments → **test** → Open (`deploy:test` prints it) |
| Dashboard (workbook) and alert rules | Workbook **"<name> - business and technical health"** (`terraform output dashboard_name`); alert rules `…-p95-over-nfr` and `…-errors`; action group `…-team` |
| Repository and the pipeline that deploys it | The case repo, `main`. Every merge runs build → deploy → verify → `confidence:deploy` |

**Settings** (OR-11): `APP_VERSION` (set by the pipeline), `PORT` (8000), `APP_ENV` (`test`; `production` switches
the drill off), `DUES_PER_FLAT` (2500), `DRILL_SLOW_MS` and `DRILL_ERROR_PCT` (drill only, cleared by every deploy).
**Secrets:** `TREASURER_KEY`, `APPLICATIONINSIGHTS_CONNECTION_STRING` — Container App secrets, never in a file.

## 2. Deploy

Merge to `main`. The pipeline builds the image once (tag = the commit), deploys it with Terraform and verifies it.
It worked if `confidence:deploy` says **CONFIDENT** and `curl -s $APP_URL/health` shows the commit you merged.
Release notes: the merge request description (OR-10).

## 3. Roll back

On the last `main` pipeline, run the manual job **`rollback:test`**. It puts the previous commit's image back in
one step. To go further back: run it with the variable `ROLLBACK_TO=<short sha>` of a commit that was deployed.
Confirm: `/health` shows the old commit; the **versions** tile switches after a few minutes of traffic.

Roll back when the last deploy broke something users feel (an alert, a failed check on main). Fix forward when
the problem is small and understood — through a merge request, test first. The next merge deploys forward again.

## 4. Rotate a secret

For `TREASURER_KEY` (if it may have leaked):
1. Generate a new value: `python3 -c "import secrets; print(secrets.token_urlsafe(24))"`.
2. GitLab → Settings → CI/CD → Variables → `TREASURER_KEY` → paste the new value (masked).
3. Re-run the last `main` pipeline. `deploy:test` hands the new value to the Container App secret.
4. Confirm: a request with the old key gets **401**; with the new key, **200**. Tell the treasurer and the
   secretary the new key by phone — never by email or chat.

`APPLICATIONINSIGHTS_CONNECTION_STRING` is created by Terraform; re-running the pipeline is enough.

## 5. Alerts — what each means, and the first three things to do

| Alert | Means | First steps | When to escalate |
|---|---|---|---|
| p95 over the NFR | The dues answer is slower than NFR-001 (2000 ms) for five minutes | 1. Workbook → p95 tile: which route, since when, which version. 2. `/analyse-alert p95-over-nfr 30m`. 3. If it started with a deploy: `rollback:test` | Still over after a rollback, or the secretary reports the gate waiting |
| Failed requests | More than 5 % of requests failed in five minutes | 1. Workbook → errors tile, then Failures in Application Insights. 2. One failing request by its `X-Request-Id`. 3. A 503 everywhere? `TREASURER_KEY` missing (fail closed) — see §4 | More than ten minutes, or any payment rejected that should not be |

**Drills:** `drill:slow` / `drill:errors`, then `drill:load` for at least eight minutes — the alert window is five
minutes and telemetry takes a few to arrive (REV-03). `drill:clear` afterwards.

## 6. Common problems

| Symptom | Likely cause | Fix |
|---|---|---|
| Every protected route returns 503 | `TREASURER_KEY` did not reach the app | §4, steps 2–3 |
| `verify:smoke` never sees the new commit | The new revision did not start | Container App → Log stream; `PORT` must be 8000 |
| The dashboard is empty | A lab reset removed Application Insights | Re-run the last `main` pipeline; old data does not come back |
| Payments recorded yesterday are gone | A restart — the store is in memory | REV-01: known, high, fix in Session 19. Tell the treasurer |

## 7. Backup and restore

**Not backed up.** Payments live in an in-memory SQLite database inside the container; a restart, a redeploy or a
lab reset loses them (REV-01, high). Until ADR 0002 is built, the treasurer keeps the bank statement as the record.

## 8. Contacts and escalation

| For | Who | How |
|---|---|---|
| The service | The group anchor; the Maintainer | GitLab issue on the case repo; the group channel |
| Each outside system your slice calls | None in this slice | The bank webhook arrives in a later slice |
| The client, when something affects them | The secretary (operations), the treasurer (payments) | Phone first, then a written note the same day |

## 9. Known gaps

OR-02 out-of-hours route · OR-03 no agreed SLO (asked, FB-02) · OR-04 no postmortem template · OR-05 no backup
(REV-01) · OR-07 no cost estimate (REV-05).
