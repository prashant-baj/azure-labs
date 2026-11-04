# Session 17 workshop: observable, with the alerts proved

**By the end of today your group has:**

1. **An observability spec.** It names the questions people will ask of the running service, with **one business
   signal** and **one technical signal** that answer them, where to see each, and what fires when the answer is bad.
2. **The observability stack in Terraform.** Application Insights on the workspace your app already uses, a
   dashboard (workbook) with a business tile and a technical tile, an action group, and two alerts whose
   thresholds come from your NFR.
3. **Your code instrumented.** Telemetry goes to Application Insights only when configured, the business counter
   is incremented in the use case, every response carries `X-Request-Id`, and a drill switch exists for the test
   environment.
4. **Proof that it works.** `verify:observability` finds this commit's telemetry, and a drill under load makes an
   alert fire. You find one request by its id, then roll back and watch the version change on the dashboard.

| # | Step | Who | Time |
|---|---|---|---|
| 1 | Build the stack in Terraform | driver + Maintainer | 15 min |
| 2 | Spec the signals | whole group | 20 min |
| 3 | Instrument the code | two pairs | 25 min |
| 4 | Turn it on, and find your two numbers | whole group | 15 min |
| 5 | The drill: load, alert, one request, rollback | whole group | 25 min |
| 6 | Record, check, tag | driver | 5 min |
| | Debrief | everyone | 10 min |

**Before you start:** Session 16 is merged. `verify:dast` ran on `main`, and the pipeline shows the orange
`verify:observability (planned)` job. You can open your resource group in the Azure portal: if you can see the
Container App, you will also see Application Insights there once step 4 has deployed it.

---

## The stack you are building

| Concern | Where it lives for you (Azure) | Where you look |
|---|---|---|
| Instrumentation | Azure Monitor OpenTelemetry Distro (Python, Node) or the Java agent | your code, `stacks.md` sections 5 to 8 |
| Logs, requests, traces, metrics | Application Insights, keeping its data in the Log Analytics workspace | **Logs** (KQL): `AppRequests`, `AppMetrics`, `AppTraces`, `AppDependencies` |
| One request, end to end | Application Insights **Transaction search** | search by the `X-Request-Id` a response carried |
| Dashboard | An Azure Monitor **workbook** | Monitor → Workbooks, or your resource group |
| Alerts | Scheduled query rules and an action group | Monitor → Alerts, and your inbox |

The concept slide in the session deck shows the same jobs in an open-source stack (OpenTelemetry Collector,
Prometheus, Loki or Elasticsearch, Tempo or Jaeger, Grafana, Alertmanager) and in AWS (ADOT, CloudWatch, X-Ray,
Amazon Managed Grafana). Today you build only the Azure column. The debrief asks which piece of the other two
columns would hold each of your tiles.

---

## Step 1 · Build the stack in Terraform (15 min)

Start a branch: `git -C ~/work/group-1 switch -c feature/observability`.

**1a. Wake up the file.** Rename it, so that Terraform reads it:

```bash
git -C ~/work/group-1 mv infra/observability.tf.s17 infra/observability.tf
```

Read it top to bottom; it is short. It needs `azurerm_resource_group.rg`, `azurerm_log_analytics_workspace.logs`,
`local.name` and `local.tags` from your Session 12 `main.tf`. If your names differ, change the references, not
your resources.

**1b. The connection string is a secret too.** In `infra/secrets.tf`, add one line to `local.app_secrets`:

```hcl
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.appi.connection_string
```

This uses the same journey as yesterday's key: the value goes from Terraform to a Container App secret to an
environment variable. Nobody copies it from the portal.

**1c. Who hears about it** (Maintainer). In GitLab go to **Settings → CI/CD → Variables** and add `ALERT_EMAIL`
with the inbox from your homework. It is not a secret, so leave it unmasked and unprotected.

**1d. The NFR line.** In `ci/production.yml`, set `TF_VAR_nfr_p95_ms` to the **same number** as the p95 row of your
strategy. The alert and the scorecard must disagree about nothing.

```bash
cd ~/work/group-1/infra && terraform init -backend=false -input=false >/dev/null && terraform validate
```

**Check:** `check-production` section 7 shows Application Insights, a workbook, 2 alert rules, an action group,
and the connection string reaching the app as a secret.

---

## Step 2 · Spec the signals (20 min)

```
/observability-spec specs/<your slice>
```

It works one section at a time and stops for your yes after each one. The two decisions that matter:

| | Business signal (OBS-001) | Technical signal (OBS-002) |
|---|---|---|
| The question | the number the client would phone you about: orders placed, claims approved, payments matched | "Is it fast enough?" |
| What it is | a **counter of a business event**, with one `outcome` attribute | request duration, **p95 against your NFR row** |
| Made where | in the use case, at the moment the event happens. Never in a middleware: an HTTP 200 is not a business outcome | automatically, by the distro or the agent |
| Never | personal data in an attribute (check your threat model) | a round number nobody agreed on |

Then set **`OBS_BUSINESS_METRIC`** in `ci/production.yml` to the counter's exact name. Terraform reads the same
variable for the dashboard tile, and `verify:observability` reads it for the check.

**Check:** `check-production` section 5 shows OBS-001 as business, OBS-002 quoting an NFR, and the metric named in the spec.

---

## Step 3 · Instrument the code (25 min, two pairs)

Use `<lab>/stacks.md`, the section for your stack. Write tests first where there is behaviour to test.

| Pair | What | stacks.md |
|---|---|---|
| A | **Telemetry on when configured**: the distro (Python, Node) or the agent in the Dockerfile (Java), with `service.version` set to `APP_VERSION`. **The business counter**, in the use case, plus a test that reads it back (`test_obs_001_...`) | 5, 6 |
| B | **`X-Request-Id`** on every response (`test_obs_003_...`). **The drill switch**: `DRILL_SLOW_MS` and `DRILL_ERROR_PCT`, read on every request, ignored in production and on `/health`, with a test for each | 7, 8 |

Locally, nothing changes. Run the app without `APPLICATIONINSIGHTS_CONNECTION_STRING`: the tests pass, nothing is
sent, and the app needs no Azure. That is the rule in your `CLAUDE.md`.

**Check:** the suite is green, and `check-production` section 6 is all OK.

---

## Step 4 · Turn it on, and find your two numbers (15 min)

**4a.** In `ci/production.yml`, set `OBSERVABILITY: "on"`. In the strategy, section 5, add:

```
| CS-0nn | This commit's telemetry reached the workspace | obs.version | = 1 | OBS-002, OBS-003 | deploy |
| CS-0nn | The business metric was recorded for this commit's traffic | obs.business | = 1 | OBS-001 | deploy |
```

In section 6, change `verify:observability` from *planned* to *real*. Push, open the merge request, check that
`confidence:merge` says CONFIDENT, and merge.

**4b. Watch `main`.** `deploy:test` now creates Application Insights, the workbook and the alerts, and hands the
connection string to the app. `verify:perf` sends traffic, and **`verify:observability`** waits, for up to ten
minutes, until requests from **this commit** and your business metric reach the workspace. Its log shows each
try. Telemetry takes a few minutes to arrive, which is normal.

**4c. Find your two numbers.** In the portal, go to your resource group, then the workbook
**"<name> - business and technical health"**:

- The **business** tile shows your counter, split by outcome. Run the business action a few times by hand and
  watch it move after a few minutes.
- The **p95** tile shows response time per route, with your NFR line on it.
- The **versions** tile shows which commit served the traffic.

Each person, out loud: *"Our business signal is ___. Right now it shows ___. Our technical signal is the p95 of
___ against NFR-0nn, and right now it is ___ ms."* If someone cannot say it, the dashboard is not finished.

**Check:** `confidence:deploy` shows `obs.version` and `obs.business` as met.

---

## Step 5 · The drill: load, alert, one request, rollback (25 min)

Run this in the **test environment only**. It proves the alerts fire before a real incident tests them for you.

**5a. Start it first, because alerts take time.** On the last `main` pipeline, run the manual jobs in this order:

1. **`drill:slow`** sets `DRILL_SLOW_MS=2500` on the running Container App. No rebuild is needed.
2. **`drill:load`** runs your k6 smoke for eight minutes. Its thresholds will fail, which is the point of a drill.

Then watch the p95 tile cross the NFR line over the next few minutes. The `p95-over-nfr` alert evaluates every five
minutes on five minutes of data, so expect the email after roughly ten to fifteen minutes. Note the time you
started.

**5b. While you wait, find one request by its id.**

```bash
curl -si "$APP_URL/health" | grep -i x-request-id
```

Then search for that id in Application Insights → **Transaction search**, or run this in **Logs**:

```kusto
AppRequests | where OperationId == "<the id>"
```

Now find the slowest requests of the drill and open one end to end:

```kusto
AppRequests | where TimeGenerated > ago(15m) | top 5 by DurationMs desc
| project TimeGenerated, OperationId, Name, DurationMs, ResultCode, AppVersion
```

**5c. When the alert email arrives**, run `/analyse-alert p95-over-nfr 30m` and paste in the query results it asks
for. It should name the signal, the version and example requests, and propose a next step. Here the cause is the
drill, so the next step is to run **`drill:clear`**.

**5d. If there is time, run the error drill:** `drill:errors` (30 % of requests return 503), then `drill:load`, and
watch the errors tile and the `errors` alert. Finish with `drill:clear`.

**5e. Roll back.** Run **`rollback:test`**. It puts the image of the previous commit on `main` back into service.
Run `drill:load` again (or a minute of `curl`) and watch the **versions** tile switch to the old commit. The next
merge to `main` deploys forward again, and `deploy:test` also clears any drill setting, because Terraform restores
the settings it declares.

---

## Step 6 · Record, check, tag (5 min)

Fill in the drill table at the end of `specs/design/observability.md`: when each alert fired, whether the email
arrived, and the id of the request you found. Merge that, then:

```bash
cd <lab> && ./check-production.sh ~/work/group-1          # all 8 sections
git -C ~/work/group-1 switch main && git -C ~/work/group-1 pull
git -C ~/work/group-1 tag L6-production && git -C ~/work/group-1 push --tags
```

---

## Done looks like

- [ ] `specs/design/observability.md`: one business signal, one technical signal quoting an NFR, the queries, and the drill recorded
- [ ] `infra/observability.tf` applied by the pipeline: Application Insights, the workbook, an action group, two alerts
- [ ] The code sends telemetry only when configured. The counter has a test. `X-Request-Id` is on every response
- [ ] `verify:observability` is real, and `obs.version` and `obs.business` are met on the scorecard
- [ ] Each person can name the business signal and the technical signal, and read both off the dashboard
- [ ] An alert fired during the drill, one request was found by its id, and `rollback:test` was run and seen on the versions tile
- [ ] `check-production`: READY, tagged `L6-production`

## If something goes wrong

| Symptom | Fix |
|---|---|
| `verify:observability`: requests stay at 0 | Telemetry did not start: is `APPLICATIONINSIGHTS_CONNECTION_STRING` in `local.app_secrets`, and did `deploy:test` apply it? Java: the `ENTRYPOINT` adds the agent only when the variable is set. Node: is `--import ./telemetry.mjs` in the start command and the Dockerfile `CMD`? |
| Requests arrive, but not from this commit | `service.version` is not set to `APP_VERSION`, so `AppVersion` is empty. Java: set `customDimensions` in `applicationinsights.json` |
| Requests arrive, but the business metric stays at 0 | `OBS_BUSINESS_METRIC` does not match the counter's name exactly, or nothing in `verify:perf` triggers the business action. Add one request to your k6 script that does |
| `deploy:test`: workbook or alert error | Read the Terraform message. `local.name`, `local.tags` or the workspace name differ from the Session 12 starter. Change the references in `observability.tf` |
| The alert never fires | Give it 15 minutes after the load started. Check Monitor → Alerts → Alert rules: is the rule enabled, and does its query return rows in **Logs**? Is `drill:slow` really set (Container App → Containers → Environment variables)? |
| No email | `ALERT_EMAIL` was empty when `deploy:test` ran. Set it and redeploy. Check spam too, and that the action group lists the address |
| `rollback:test`: *No image ... was that commit deployed?* | The previous commit on `main` has no image. Run it with `ROLLBACK_TO=<short sha>` of a commit that was deployed |
| Everything is slow after the drill | `drill:clear` was not run. The next `deploy:test` clears it too |
| The lab environment was reset | It resets every few hours. Re-run the last `main` pipeline: Terraform recreates the stack, and telemetry starts again |
