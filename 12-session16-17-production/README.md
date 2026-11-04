# Sessions 16 and 17 · Layer 6: secure, observable, ready for production

Layer 5 made every merge deploy, with a scorecard to show for it. Layer 6 asks the two questions a client asks
before letting real people in:

> **"Is it safe to expose?"** and **"When it misbehaves, will you know before we do?"**

| | Session 16 · Wed 4 Nov | Session 17 · Fri 6 Nov |
|---|---|---|
| **Theme** | **Secure**: every threat named, controlled and proved | **Observable**: one business number and one technical number, visible and alerting |
| **You build** | A threat model of your slice; the controls, each written red first; a secret that never touches a file; a scan of the running service after every deploy | The observability spec; Application Insights, a dashboard and alerts in Terraform; your code instrumented; a drill that makes an alert fire; a rollback |
| **The pipeline says** | *"No high-risk finding on the running service, and every threat has a test."* | *"This commit's telemetry arrived, and the business metric with it."* |

Both sessions are mostly workshop. See [`../BUILD-ROADMAP.md`](../BUILD-ROADMAP.md). Tag at the end of
Session 17: **`L6-production`**. The demo can now say: *"Here is the number our client cares about, live. Here is
the alert that fired when we slowed the service on purpose, and here is the rollback."*

## The idea in one picture

```
specs/design/threat-model.md        code + tests                         pipeline, after every deploy
| T-01 | Spoofing | SEC-001 | ─────  require_key()  test_sec_001_t01_*  verify:dast ── zap.json ── dast.high = 0
                                                                                                        │
specs/design/observability.md                                                                           ▼
| OBS-001 | Business  | orders_placed │──  counter in the use case ──┐                         confidence.md
| OBS-002 | Technical | p95 vs NFR-0nn│──  the distro, automatic  ───┤─ Application Insights ─ verify:observability
                                                                    │  (Log Analytics)        ── obs.json ── obs.version, obs.business
infra/observability.tf  ── workbook (business + p95 tiles) ── alerts ── action group ── your inbox
```

The threat model and the observability spec are **spec**, like the test strategy: the code, the Terraform and the
pipeline follow them, and each row names the test or the signal that proves it.

## Session 16: today's TO-DO (Wed 4 Nov)

**Step by step: [`WORKSHOP-S16.md`](WORKSHOP-S16.md).**

| # | Do | Who | Time |
|---|---|---|---|
| 0 | `git pull` azure-labs. Your repo has `L5-tested`; the last `main` pipeline deployed and was CONFIDENT | everyone | before |
| 1 | **Set up**: `setup-production` on a branch | driver + Maintainer | 10 min |
| 2 | **Attack your own service, then model the threats**: `curl` the deployed service as an outsider, try the attacks in your case's notes, then `/threat-model` | whole group | 25 min |
| 3 | **Controls, red test first**: the key (fail closed), security headers, escaping ([`stacks.md`](stacks.md) 1–4) | two pairs | 25 min |
| 4 | **The secret's journey**: masked GitLab variable → `TF_VAR_` → Container App secret → environment variable | driver + Maintainer | 15 min |
| 5 | **Merge, deploy, scan**: `verify:dast` on `main`, read `zap.html`, set the `dast.*` rows | whole group | 20 min |
| 6 | **Review and check**: `/secure-review`, `check-production` sections 1–4 | driver | 10 min |
| 7 | **Debrief**: which threat surprised you? | everyone | 10 min |

## Session 17: today's TO-DO (Fri 6 Nov)

**Step by step: [`WORKSHOP-S17.md`](WORKSHOP-S17.md).**

| # | Do | Who | Time |
|---|---|---|---|
| 0 | Session 16 merged. `ALERT_EMAIL` decided. You can open your resource group in the Azure portal | everyone | before |
| 1 | **Build the stack in Terraform**: `observability.tf`, the connection string as a secret, the NFR line | driver + Maintainer | 15 min |
| 2 | **Spec the signals**: `/observability-spec`, with one business signal and one technical signal | whole group | 20 min |
| 3 | **Instrument the code**: telemetry when configured, the counter, `X-Request-Id`, the drill switch ([`stacks.md`](stacks.md) 5–8) | two pairs | 25 min |
| 4 | **Turn it on**: `OBSERVABILITY: "on"`, merge, `verify:observability`, find your two numbers on the dashboard | whole group | 15 min |
| 5 | **The drill**: `drill:slow` + `drill:load`, alert email, one request by its id, `/analyse-alert`, `rollback:test` | whole group | 25 min |
| 6 | Record the drill. `check-production` says READY → tag `L6-production` | Maintainer | 5 min |
| 7 | **Debrief**: where would each tile live in an open-source stack, or in AWS? | everyone | 10 min |

**Two repositories, as before:** this lab (azure-labs) is pull-only. Your case repo (GitLab) is where you
push. Never copy `examples/` into your case repo.

## What is in this folder

| Path | What it is |
|---|---|
| `setup-production.sh` / `.ps1` | Once per group: commands, templates, `ci/production.yml`, `infra/secrets.tf`, `infra/observability.tf.s17`, one commit |
| `check-production.sh` / `.ps1` | Sections 1–4 (Session 16), 5–8 (Session 17), the READY bar |
| `stacks.md` | What layer 6 needs from your code, for Python, Node and Java: key, headers, escaping, telemetry, counter, request id, drill |
| `ci/production.yml` | `verify:dast`, `verify:observability` (planned until `OBSERVABILITY` is on), `drill:*`, `rollback:test` |
| `ci/confidence.py` | The scorecard, now also reading `zap.json` (`dast.high`, `dast.medium`) and `obs.json` (`obs.version`, `obs.business`) |
| `infra-additions/` | `secrets.tf`, the Container App snippet, `observability.tf` (Application Insights, workbook, action group, two alerts) |
| `claude-commands/` | `/threat-model`, `/secure-review`, `/observability-spec`, `/analyse-alert` |
| `templates/` | The threat model, the observability spec, the layer-6 `CLAUDE.md` section |
| `case-notes/` | One file per case: the assets, STRIDE checks, secrets, attacks to try and who agrees to a risk. `setup-production` copies yours to `specs/design/threat-notes.md` |
| `examples/society-dues/` | The worked example, complete and tested. Read its README first |

## Tools

Nothing new on your laptop. ZAP, the Azure CLI and k6 run in the pipeline, pinned. You need the Azure portal
(your resource group) in Session 17, and `curl` (on Windows, `curl.exe`).

---

## Commands (layer 6)

| Command | What it does |
|---|---|
| `/threat-model <slice>` | Assets, trust boundaries, STRIDE threats, each with a control and a test; what is accepted, and who agreed |
| `/secure-review [branch]` | The change against your threat model and the OWASP Top 10: file, line, threat, the test that would catch it. Edits nothing |
| `/observability-spec <slice>` | The questions, one business and one technical signal, the tiles and their KQL, the alerts, the drill |
| `/analyse-alert <alert> [window]` | What crossed which line, since which version, example requests by id, the next step. Never silences an alert |

## Done looks like

- [ ] `specs/design/threat-model.md`: at least 4 threats across STRIDE, each with a control and a proof; accepted risks with who agreed
- [ ] Controls written red first and named after their threats; T-01 tried before (it got in) and after (401)
- [ ] Secrets only in masked GitLab variables; no value in any file; `verify:dast` on every deploy, `dast.high` = 0
- [ ] `specs/design/observability.md`: one business signal, one technical signal quoting an NFR, the drill recorded
- [ ] Application Insights, the workbook and two alerts in Terraform, applied by the pipeline
- [ ] `verify:observability` real; `obs.version` and `obs.business` met; everyone can read both numbers off the dashboard
- [ ] An alert fired in the drill; one request found by its id; a rollback seen on the versions tile
- [ ] `check-production` READY; tag `L6-production` pushed

## The rules of this layer

1. **A threat without a test is a hope.** Every control is written red first, against today's code.
2. **Secrets come from the environment, and fail closed.** Masked in GitLab, sensitive in Terraform, a secret in
   the Container App, never in a file. No secret configured means nobody gets in.
3. **No personal data in logs, metric attributes or traces.** Log the event, the outcome and the requirement ID.
4. **One business signal and one technical signal, first.** A counter of what the client cares about, and the
   NFR they signed. More dashboards can come later; these two come first.
5. **An alert you have not seen fire is not an alert.** The drill proves it, in the test environment only.
6. **Thresholds come from the spec.** The p95 alert, the scorecard row and the NFR quote the same number.

## Homework, before Session 18

- Read your dashboard to someone outside the group. Can they tell what the business is doing right now?
- One accepted risk from the threat model: who would have to agree to fix it, and what would it cost?

## If something goes wrong

The workshop guides have a table each: [Session 16](WORKSHOP-S16.md#if-something-goes-wrong),
[Session 17](WORKSHOP-S17.md#if-something-goes-wrong). The most common ones:

| Symptom | Fix |
|---|---|
| Every protected route returns 503 after deploy | The secret did not arrive. Fail closed is working: check the GitLab variable, the `TF_VAR_` line and the snippet in `main.tf` |
| `verify:dast` cannot pull the ZAP image | `ZAP_IMAGE: "zaproxy/zap-stable"` in `ci/production.yml` |
| `verify:observability` waits ten minutes, then reports 0 | The connection string is not in `local.app_secrets`, or the code does not set `service.version` from `APP_VERSION` |
| No alert email | `ALERT_EMAIL` was empty when `deploy:test` ran, or the email went to spam. Give the alert 15 minutes after the load starts |
| `check-production`: *In git, and must not be* | `git rm --cached <file>`, add it to `.gitignore`, and **rotate** the secret, because it is in the history now |
