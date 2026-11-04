
## Layer 6: secure, observable, ready for production (Sessions 16 and 17)

- **The threat model is spec**: `specs/design/threat-model.md`. Every threat has a control (`SEC-0nn`) and a test
  named after both IDs, written red first. A threat with no test is a hope, not a control. An accepted risk is
  written down, with who agreed.
- **Secrets come from the environment and fail closed.** A masked GitLab variable becomes `TF_VAR_<name>`, then a
  Container App secret, then an environment variable. Never put a value in code, tests, Postman environments,
  `.tf`, `.tfvars` or a log. No secret configured means nobody gets in. Compare secrets in constant time.
- **Personal data never goes in logs, metric attributes or traces.** Log the event, the outcome and the
  requirement ID.
- **The observability spec is spec**: `specs/design/observability.md`. Exactly one business signal (a counter in the
  use case, never in a middleware) and one technical signal (p95 against an NFR row). Alert thresholds quote the
  NFR. Never raise a threshold to silence an alert; propose it in a merge request with its reason.
- **Telemetry is off unless configured**: the code sends nothing without `APPLICATIONINSIGHTS_CONNECTION_STRING`.
  Local runs and CI never need Azure.
- **The drill runs only in the test environment.** `APP_ENV=production` switches it off, and `/health` is never
  touched.
- The scan of the running service (`verify:dast`) and the telemetry check (`verify:observability`) are scorecard
  rows like any other: `dast.high`, `dast.medium`, `obs.version`, `obs.business`.

### Commands (layer 6)

| Command | What it does |
|---|---|
| `/threat-model <slice>` | Assets, boundaries, STRIDE threats, each with a control and a test. Section by section, on a yes |
| `/secure-review [branch]` | The change against the threat model and the OWASP Top 10: file, line, threat, the test that would catch it. Edits nothing |
| `/observability-spec <slice>` | The questions, one business and one technical signal, the tiles, the alerts, the drill |
| `/analyse-alert <alert> [window]` | What crossed which line, since which version, example requests by id, the next step |
