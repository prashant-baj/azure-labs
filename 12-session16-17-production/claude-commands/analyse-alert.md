---
description: An alert fired (or the drill ran) - read the telemetry, say what happened, since when and in which version, find example requests by id, and propose the next step (roll back, fix forward, or adjust the alert by merge request). Never changes a threshold to silence an alert.
argument-hint: "[alert name or OBS id] [time window, e.g. 30m]"
---
Arguments: $ARGUMENTS — which alert or signal, and the window (default 30 minutes). Read
`specs/design/observability.md`, `specs/design/test-strategy.md` and the last pipeline's `confidence.md`.

Ask the group to run these in the portal's Logs blade (or with `az monitor log-analytics query`) and paste the
results back. **You do not have their Azure access; never guess numbers.**

```kusto
AppRequests | where TimeGenerated > ago(30m)
| summarize requests = count(), failed = countif(Success == false), p95_ms = percentile(DurationMs, 95) by AppVersion, Name
AppRequests | where TimeGenerated > ago(30m) and (Success == false or DurationMs > 2000) | take 5
| project TimeGenerated, OperationId, Name, ResultCode, DurationMs, AppVersion
```

Then write a short analysis:

1. **What**: which signal crossed which line, quoting the spec ID and the NFR.
2. **Since when, and which version**: did it start with a deploy (`AppVersion` changed) or a drill?
3. **Examples**: two `OperationId`s, with what each request did (dependencies, logs).
4. **Next step**: roll back (`rollback:test`), fix forward (a failing test first, at the lowest layer), or, if the
   alert itself is wrong, propose a merge request changing the threshold **with the NFR it quotes**. Never raise a
   threshold just to make the alert stop.
