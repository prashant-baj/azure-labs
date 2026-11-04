# Worked example: layer 6 for the society dues slice

This is the same invented housing society. Layer 5 made the confidence measurable. Layer 6 makes the running
service **safe to expose** and **visible while it runs**. A threat model names what could go wrong, each threat
gets a control and a test, and a scan of the deployed service checks from outside. Application Insights then
shows one business number and one technical number, alerts fire when either goes wrong, and a drill proves that
they do.

Read it in the order the group worked in:

| # | Look at | Notice |
|---|---|---|
| 1 | `threat-model.md` | Seven threats, STRIDE by STRIDE. **T-01 worked before layer 6**: anyone could send `X-Role: treasurer`. Each row names its control and the test that proves it. What is accepted for now is written down, with when to revisit it |
| 2 | `code/dues/security.py` | Three controls, each tied to a threat. The key comes from the environment, the check fails closed (no key configured gives 503 for everyone) and the comparison runs in constant time |
| 3 | `code/tests/test_security.py` | One test per threat, named after it: `test_sec_001_t01_...`. The key in the tests is a value used only by tests (`conftest.py`) |
| 4 | `infra/secrets.tf`, `ci/production.yml` | A secret's journey: masked GitLab variable → `TF_VAR_treasurer_key` → a Container App secret → an environment variable. No value appears in any file |
| 5 | `ci/production.yml`, `verify:dast` | ZAP baseline against the deployed URL, after every deploy. `dast.high` must be 0, and `dast.medium` is a ratchet |
| 6 | `observability.md` | Four questions people will ask, and the signal that answers each. **OBS-001 is business** (payments recorded, by outcome) and **OBS-002 is technical** (p95 against NFR-001). Each has a tile, and OBS-002 has an alert |
| 7 | `code/dues/telemetry.py` | The distro sends nothing unless the connection string is set. The counter is incremented in the use case, not in a middleware. Log lines carry the requirement ID and never the payer (T-06) |
| 8 | `infra/observability.tf` | Application Insights on the workspace the app already uses, a workbook with the two tiles, an action group, and two alerts whose thresholds come from the NFR |
| 9 | `ci/production.yml`, `verify:observability` | It waits until **this commit's** requests and the business metric reach the workspace, then writes `obs.json` for the scorecard |
| 10 | `test-strategy.md` | Rows CS-009 to CS-012. Section 6 now has a column per session: `verify:observability` was drawn as planned in S16 and became real in S17 |
| 11 | `confidence-example.md` | The scorecard after a deploy: 12 of 12 |

Run it locally (Python 3.10 or later, Node 20 or later, k6). Nothing is sent to Azure, because the connection
string is not set:

```bash
cd code
pip install -r requirements.txt
python -m pytest -q                                          # unit, API, scenarios, security, observability
export TREASURER_KEY="local-only-$(date +%s)"                # PowerShell: $env:TREASURER_KEY = "local-only-1"
APP_VERSION=local uvicorn dues.api:app --port 8000 &

curl -si localhost:8000/reminders -H "X-Role: treasurer"     # 401 - T-01 closed
curl -si localhost:8000/reminders -H "X-Role: treasurer" -H "X-Api-Key: $TREASURER_KEY" | head -12   # 200 and the security headers (X-Request-Id too, once telemetry is on)

cd ..
npx newman@6.2.3 run tests/api/dues.postman_collection.json -e tests/api/local.postman_environment.json --env-var treasurerKey="$TREASURER_KEY"
k6 run -e BASE_URL=http://localhost:8000 -e P95_MS=2000 -e ERROR_RATE=0.01 -e TREASURER_KEY="$TREASURER_KEY" tests/perf/smoke.js
```

**Try the drill locally.** Restart the app with `DRILL_SLOW_MS=2500` and run k6 again: `perf.p95_ms` misses
NFR-001. In Azure, that same switch is what makes the p95 alert fire.

**In your repo**, the threat model and the observability spec live in `specs/design/`. Here they sit at the top
so the example stays small.
