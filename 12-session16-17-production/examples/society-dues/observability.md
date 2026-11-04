# Observability spec: society dues, slice 001

*In a real repo this lives at `specs/design/observability.md`. It was written with `/observability-spec` in
Session 17. Each line answers a question someone will ask, then says which signal answers it, where to look, and
what fires when the answer is bad.*

## 1. The questions

| Who asks | The question | Answered by |
|---|---|---|
| The treasurer | "Are payments coming in, and how many could the system not match?" | OBS-001 |
| The secretary, at the gate | "Is it fast enough today?" (NFR-001) | OBS-002 |
| Whoever is on call | "Is it failing, and since which version?" | OBS-003, OBS-002 |
| A resident: "it failed at 10:42" | "Which request was that, and what happened inside it?" | OBS-003 |

## 2. The signals

| ID | Kind | Signal | Where it is made | Where to see it | Alert |
|---|---|---|---|---|---|
| OBS-001 | **Business** | `dues_payments_recorded`, a counter by `outcome`: matched, unmatched or duplicate | `telemetry.record_outcome`, at the moment the use case records the payment | Workbook tile "business"; `AppMetrics` | none yet: the client has not said how many unmatched is too many. Asked in the review |
| OBS-002 | **Technical** | Request duration per route, p95 against NFR-001 (2000 ms) | automatic: Azure Monitor OpenTelemetry Distro | Workbook tile "p95"; `AppRequests.DurationMs` | `p95-over-nfr`, severity 2, p95 > 2000 ms over 5 min |
| OBS-003 | Technical | Failed requests (%), and `X-Request-Id` on every response, which is the trace id | automatic, plus `RequestId` middleware | Workbook tile "errors"; Transaction search by id | `errors`, severity 1, more than 5 % failed over 5 min |
| OBS-004 | Logs | Structured lines: event, outcome, requirement ID. Never the payer (T-06) | `logging.getLogger("dues")` | `AppTraces` | none |
| version | All of the above | `service.version` = the commit, shown as `AppVersion` | `telemetry.setup(version)` | Workbook tile "versions" | `verify:observability` fails if this commit sends nothing |

**Why these two.** OBS-001 is the number the treasurer would phone about. It is a counter of business events,
not of HTTP calls: a 200 response does not mean the payment was matched. OBS-002 is the NFR the client signed,
measured where the client feels it: on real requests in the deployed service, not in a test.

## 3. The queries behind the tiles

```kusto
// OBS-001 - payments recorded, by outcome, every 5 minutes
AppMetrics | where Name == "dues_payments_recorded"
| extend outcome = tostring(Properties.outcome)
| summarize total = sum(Sum) by bin(TimeGenerated, 5m), outcome

// OBS-002 - p95 per route against the NFR
AppRequests | summarize p95_ms = percentile(DurationMs, 95) by bin(TimeGenerated, 5m), Name

// OBS-003 - one request, by the id a resident read off the response
AppRequests | where OperationId == "<X-Request-Id>"
| union (AppDependencies | where OperationId == "<X-Request-Id>"), (AppTraces | where OperationId == "<X-Request-Id>")
```

## 4. The drill: proof that the alerts work

Session 17, test environment only. `drill:slow` sets `DRILL_SLOW_MS=2500`, then k6 runs for five minutes. The p95
tile crosses the NFR line and `p95-over-nfr` emails the team. `drill:errors` sets `DRILL_ERROR_PCT=30`, the errors
tile climbs and `errors` fires. `drill:clear` turns both off. `rollback:test` puts the previous commit's image back,
and the versions tile shows the switch.

| Drill | Alert fired after | Email arrived | Found the request by X-Request-Id |
|---|---|---|---|
| slow | *fill in* | *fill in* | *fill in* |
| errors | *fill in* | *fill in* | *fill in* |
