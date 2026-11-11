---
description: Draft ops/runbook.md from what is really in the repo - the pipeline jobs, infra/, the alert rules, the secrets - for someone outside the group at two in the morning. Never invents a command; asks where the repo is silent.
argument-hint: ""
---
Read `.gitlab-ci.yml` and `ci/` (deploy, verify, `rollback:test`, the drill jobs), `infra/` (the Container App,
`secrets.tf`, `observability.tf`, outputs), `specs/design/observability.md`, `specs/design/readiness.md`, the
threat model and the README. Then fill `ops/runbook.md` from `templates/runbook.md`, **one section at a time,
stopping for the group's yes after each**:

1. **At a glance** — what it does, the URL (from the `deploy:test` output or the GitLab environment), the dashboard
   and alert names (from `observability.tf`), the owner (ask — never guess a name).
2. **Deploy** and **Roll back** — the real pipeline jobs, how to run them, and how to confirm: the scorecard, the
   version on `/health`, the versions tile.
3. **Rotate a secret** — each entry of `local.app_secrets`: where its value lives (the masked GitLab variable), how
   to replace it and redeploy, how to confirm the app picked it up. **Never write a value.**
4. **Alerts** — one row per alert rule in `observability.tf`: what it means, the first three steps (the KQL from
   the observability spec, `/analyse-alert`), when to escalate and to whom.
5. **Backup and restore**, **Contacts**, **Known gaps** — from the readiness checklist. If the service keeps data
   that is not backed up, say so and propose the finding.

Every command you write must be one that exists in this repo or in the lab guides. Where the repo does not say,
write the question for the group instead of an answer. End with: "Ask someone outside the group to deploy and roll
back using only this page" — that is OR-12.
