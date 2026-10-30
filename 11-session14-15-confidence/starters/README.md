# Starters — copied into your repo by setup-testing

| Starter | Lands in | Runs in |
|---|---|---|
| `api/` | `tests/api/` — a Postman collection and the local environment | `api:local` (before merge), `verify:api` (after deploy) |
| `perf/smoke.js` | `tests/perf/smoke.js` — a k6 performance smoke | `verify:perf` (after deploy) |
| `e2e/` | **only if you have a web UI**: copy it to `tests/e2e/` yourself | `verify:e2e` (after deploy) — runs when `tests/e2e/package.json` exists |

Open them in Postman (*Import*), or edit the JSON with `/api-tests`. The worked example
(`../examples/society-dues/tests/`) has a filled-in version of each.
