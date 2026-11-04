# Observability spec: <slice>

*`specs/design/observability.md`. Written with `/observability-spec`. One business signal, one technical signal,
where to see each, what fires.*

## 1. The questions

| Who asks | The question | Answered by |
|---|---|---|
| The client's representative | | OBS-001 |
| A user | "Is it fast enough?" (NFR-0nn) | OBS-002 |
| Whoever is on call | "Is it failing, and since which version?" | OBS-003 |

## 2. The signals

| ID | Kind | Signal | Where it is made | Where to see it | Alert |
|---|---|---|---|---|---|
| OBS-001 | **Business** | `<name>`, a counter by `outcome` | the use case, at the event | Workbook tile "business"; `AppMetrics` | |
| OBS-002 | **Technical** | request duration p95 against NFR-0nn (<n> ms) | automatic (the distro or the agent) | Workbook tile "p95"; `AppRequests` | `p95-over-nfr` |
| OBS-003 | Technical | failed requests (%), `X-Request-Id` on every response | automatic, plus the middleware | Workbook tile "errors"; Transaction search | `errors` |
| OBS-004 | Logs | structured lines with the requirement ID, never personal data | the logger | `AppTraces` | none |

**Why these two:**

## 3. The queries behind the tiles

```kusto
```

## 4. The drill: proof that the alerts work

| Drill | Alert fired after | Email arrived | Found the request by X-Request-Id |
|---|---|---|---|
| slow | | | |
| errors | | | |
