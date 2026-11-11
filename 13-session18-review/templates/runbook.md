# Runbook — <service>

*`ops/runbook.md`. Written for someone who is not in your group, at two in the morning, with only this page and
access to GitLab and the Azure portal. Drafted with `/runbook`, then tried by someone outside the group (OR-12).
Replace every _(fill in)_ — `check-review` counts the ones left.*

## 1. The service at a glance

| | |
|---|---|
| What it does, in one sentence | _(fill in)_ |
| Owner, and the on-call route | _(fill in)_ |
| Test environment URL | _(fill in)_ |
| Dashboard (workbook) and alert rules | _(fill in)_ |
| Repository and the pipeline that deploys it | _(fill in)_ |

## 2. Deploy

How a change reaches the test environment, and how to tell it worked (the deploy scorecard, the version on
`/health`). _(fill in)_

## 3. Roll back

The one step, and how to confirm it worked (the versions tile, `/health`). When to roll back rather than fix
forward. _(fill in)_

## 4. Rotate a secret

Which secrets exist, where each lives (masked GitLab variable → Container App secret), how to replace one without
an outage, and how to confirm the app picked it up. _(fill in)_

## 5. Alerts — what each means, and the first three things to do

| Alert | Means | First steps | When to escalate |
|---|---|---|---|
| p95 over the NFR | _(fill in)_ | _(fill in)_ | _(fill in)_ |
| Failed requests | _(fill in)_ | _(fill in)_ | _(fill in)_ |

## 6. Common problems

| Symptom | Likely cause | Fix |
|---|---|---|
| _(fill in)_ | | |

## 7. Backup and restore

What data the service keeps, where, whether it is backed up, and how to restore it. If it is not backed up, say
so, and name the finding. _(fill in)_

## 8. Contacts and escalation

| For | Who | How |
|---|---|---|
| The service | _(fill in)_ | |
| Each outside system your slice calls | _(fill in)_ | |
| The client, when something affects them | _(fill in)_ | |

## 9. Known gaps

The `partly` and `gap` lines of `specs/design/readiness.md` that affect running the service. _(fill in)_
