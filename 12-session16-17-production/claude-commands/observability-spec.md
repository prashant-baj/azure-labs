---
description: Write specs/design/observability.md - the questions people will ask of the running service, one business and one technical signal that answer them, where to see each, and the alerts with thresholds from the NFRs. Asks; applies on a yes.
argument-hint: "[slice folder]"
---
Arguments: $ARGUMENTS — the slice folder. Read `spec.md` (FR and NFR rows), `specs/design/test-strategy.md`,
`specs/design/threat-model.md`, the use cases in the code, `infra/observability.tf` and `stacks.md`.

Write `specs/design/observability.md` from `templates/observability.md`, **one section at a time, stopping for the
group's yes after each**:

1. **The questions.** Who will ask what of the running service: the client's representative, a user, whoever is
   on call. Ask the group: "What number would the client phone you about?" Quote the requirement behind each.
2. **The signals.** Exactly **one business signal** (`OBS-001`): a counter of a business event, incremented in the
   use case at the moment the event happens (never in a middleware, never "HTTP 200s"), with one `outcome`
   attribute and **no personal data** (check the threat model). Exactly **one technical signal** (`OBS-002`):
   request duration p95 against the NFR row, quoting it. If there is no NFR, write `[NEEDS CLARIFICATION]` and ask
   who decides. Then failed requests with `X-Request-Id` (`OBS-003`) and structured logs (`OBS-004`). For each one:
   where it is made, where to see it (workbook tile, table), and its alert.
3. **The queries.** The KQL behind each tile: `AppMetrics` for the business counter, `AppRequests` for duration and
   failures, `OperationId` for one request. Run each one in the portal's Logs blade before writing it down.
4. **The drill.** How each alert will be proved: `drill:slow` for OBS-002, `drill:errors` for OBS-003. Leave a
   table to fill in with what happened.

Then check that the code matches the spec: the counter's name equals `OBS_BUSINESS_METRIC` in `ci/production.yml`,
`TF_VAR_nfr_p95_ms` equals the p95 row of the strategy, and a unit test reads the counter back. List any mismatch
and fix it only on a yes. Propose strategy rows `obs.version` = 1 and `obs.business` = 1. End with the commit message
`spec: observability OBS-001..OBS-004 - one business and one technical signal, alerts from the NFR`.
