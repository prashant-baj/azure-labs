# Your stack: what layer 6 needs from your code

Session 16 asks for four security changes. Session 17 asks for four observability changes. Each section below
has one snippet per stack, and each snippet carries the spec ID it serves, so a reviewer can follow it from the
threat model to the code. The worked example (`examples/society-dues/code/dues/security.py` and `telemetry.py`)
is the Python version, complete and tested.

Use your own names. `APP_API_KEY`, `orders_placed` and `/orders` are placeholders. Your threat model decides which
routes need the key, and your observability spec names the business metric.

---

## Session 16: secure

### 1. A secret, read from the environment, that fails closed (SEC-001 → T-01)

A role header on its own proves nothing, because anyone can send it. A protected route needs a secret the caller
must present. The app reads that secret from an environment variable at request time. Nothing is read from a
file, and nothing has a default. **If the variable is unset, nobody gets in (503).** That is what "fail closed"
means. Compare the values in constant time so the response time gives an attacker no hints.

**Python (FastAPI)**

```python
import hmac, os
from fastapi import Header, HTTPException

def require_key(x_api_key: str | None) -> None:            # SEC-001
    expected = os.getenv("APP_API_KEY", "")
    if not expected:
        raise HTTPException(503, "Access is not configured (APP_API_KEY)")
    if not x_api_key or not hmac.compare_digest(x_api_key.encode(), expected.encode()):
        raise HTTPException(401, "A valid X-Api-Key is required")

@app.get("/orders")
def list_orders(x_api_key: str | None = Header(default=None)):
    require_key(x_api_key)
    ...
```

**Node (Express)**

```js
import { timingSafeEqual } from 'node:crypto';

export function requireKey(req, res, next) {               // SEC-001
  const expected = process.env.APP_API_KEY ?? '';
  if (!expected) return res.status(503).json({ detail: 'Access is not configured (APP_API_KEY)' });
  const given = Buffer.from(req.get('X-Api-Key') ?? '');
  const want = Buffer.from(expected);
  if (given.length !== want.length || !timingSafeEqual(given, want)) {
    return res.status(401).json({ detail: 'A valid X-Api-Key is required' });
  }
  next();
}
app.get('/orders', requireKey, listOrders);
```

**Java (Spring Boot)**: one filter, no Spring Security needed for this.

```java
@Component
public class ApiKeyFilter extends OncePerRequestFilter {     // SEC-001
  private static final List<String> PROTECTED = List.of("/orders");   // the routes your threat model names
  @Override protected void doFilterInternal(HttpServletRequest req, HttpServletResponse res, FilterChain chain)
      throws ServletException, IOException {
    if (PROTECTED.stream().noneMatch(req.getRequestURI()::startsWith)) { chain.doFilter(req, res); return; }
    String expected = System.getenv().getOrDefault("APP_API_KEY", "");
    if (expected.isEmpty()) { res.sendError(503, "Access is not configured (APP_API_KEY)"); return; }
    String given = Optional.ofNullable(req.getHeader("X-Api-Key")).orElse("");
    if (!MessageDigest.isEqual(given.getBytes(UTF_8), expected.getBytes(UTF_8))) { res.sendError(401); return; }
    chain.doFilter(req, res);
  }
}
```

**Tests, Session 13 style.** Write three tests: no key gives 401, a wrong key gives 401, and no key configured
gives 503. Name them after the threat, for example `test_SEC_001_T_01_no_key_is_refused`. In tests, set the
variable to a value used only by the tests: `monkeypatch.setenv`, `process.env` in a `beforeEach`, or
`@SetEnvironmentVariable`. No real key ever goes in a test file.

### 2. Security headers on every response (SEC-002 → T-04)

The ZAP baseline scan in `verify:dast` reports these headers first when they are missing.

| Header | Value |
|---|---|
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `DENY` |
| `Referrer-Policy` | `no-referrer` |
| `Content-Security-Policy` | `default-src 'self'; frame-ancestors 'none'` |
| `Cache-Control` | `no-store`: personal data must not sit in a shared cache |

**Python**: copy `SecurityHeaders` from the example's `security.py` and add it with `app.add_middleware(SecurityHeaders)`.
Also pass `docs_url=None, redoc_url=None, openapi_url=None` to `FastAPI(...)` in the deployed app. Every route
the interactive docs expose is another place to attack.

**Node**: this was run and checked on Express 4.22:

```js
app.use((req, res, next) => {                               // SEC-002
  res.set({ 'X-Content-Type-Options': 'nosniff', 'X-Frame-Options': 'DENY', 'Referrer-Policy': 'no-referrer',
            'Content-Security-Policy': "default-src 'self'; frame-ancestors 'none'", 'Cache-Control': 'no-store' });
  next();
});
app.disable('x-powered-by');                                // do not announce the framework
```

`helmet` sets the same headers and more. Using it is fine, but keep the test that checks them.

**Java**: a second filter that calls `res.setHeader(...)` for each header, then `chain.doFilter`. Add
`server.server-header=` (empty) to `application.properties`.

### 3. Anything written into HTML is escaped (SEC-003 → T-05)

Only if your app renders HTML. **Python**: `html.escape(value)`, or Jinja2 with autoescape (on by default).
**Node**: a template engine that escapes, such as EJS `<%= %>` (not `<%- %>`); never build HTML with
`` `${value}` ``. **Java**: Thymeleaf `th:text` (not `th:utext`). A test should send `<script>` and assert that
it comes back as `&lt;script&gt;`.

### 4. Your tests send the key too

Once the routes are protected, your own Postman, k6 and Playwright checks need the key, from the same masked
variable:

| Where | Add |
|---|---|
| Postman collection | header `X-Api-Key: {{apiKey}}` on protected requests. Both environment files get `"apiKey": ""`, an empty value and never a real one |
| `ci/confidence.yml`, both `newman` lines | `--env-var apiKey="$APP_API_KEY"` |
| `ci/confidence.yml`, `k6 run` | `-e APP_API_KEY="$APP_API_KEY"`, and in the script `headers: { 'X-Api-Key': __ENV.APP_API_KEY }` |
| `tests/e2e/playwright.config.js` | `use: { extraHTTPHeaders: { 'X-Api-Key': process.env.APP_API_KEY ?? '' } }` |

Add one more Postman request: a protected route **without** the key must get 401. That request is your merge-time
evidence for T-01.

---

## Session 17: observable

### 5. Send telemetry to Application Insights (OBS-002, OBS-004)

All three stacks use the **Azure Monitor OpenTelemetry Distro**. It records every request (route, duration,
status), every outgoing call, and every log line, with no code per route. It turns itself on **only when
`APPLICATIONINSIGHTS_CONNECTION_STRING` is set**. In Azure, that variable comes from a Container App secret. On
your laptop and in CI it is not set, nothing is sent, and the tests do not change.

`service.version` is set to `APP_VERSION`, the commit. In the workspace, this value appears in the `AppVersion`
column, which is how `verify:observability` finds **this** commit's requests.

**Python**: `requirements.txt` gets `azure-monitor-opentelemetry==1.8.11`. Call this once, before the app is created:

```python
import os
from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry.sdk.resources import Resource

if os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING"):
    configure_azure_monitor(
        resource=Resource.create({"service.name": os.getenv("OTEL_SERVICE_NAME", "api"),
                                  "service.version": os.getenv("APP_VERSION", "local")}),
        logger_name="app",                                   # logs from logging.getLogger("app") are sent
    )
```

**Node**: `npm i -E @azure/monitor-opentelemetry@1.20.1 @opentelemetry/api@1.9.0`. Then add `telemetry.mjs`, which
must load **before** the app:

```js
// node --import ./telemetry.mjs server.mjs   (package.json "start" script, and the Dockerfile CMD)
import { useAzureMonitor } from '@azure/monitor-opentelemetry';
import { resourceFromAttributes } from '@opentelemetry/resources';   // installed with the distro

if (process.env.APPLICATIONINSIGHTS_CONNECTION_STRING) {
  useAzureMonitor({
    resource: resourceFromAttributes({
      'service.name': process.env.OTEL_SERVICE_NAME || 'api',
      'service.version': process.env.APP_VERSION || 'local',
    }),
  });
}
```

This was run with Express 4.22.3. With the connection string set, requests are traced and `X-Request-Id`
(section 7) is returned. Without it, the app runs unchanged. CommonJS app? Use `require` and
`node --require ./telemetry.cjs`.

**Java**: the Application Insights Java agent. It needs no code change for requests, dependencies and logs.
Add these lines to the Dockerfile:

```dockerfile
ADD https://github.com/microsoft/ApplicationInsights-Java/releases/download/3.7.4/applicationinsights-agent-3.7.4.jar /app/ai-agent.jar
COPY applicationinsights.json /app/applicationinsights.json
# the agent only when the connection string is there - local runs and CI stay exactly as before
ENTRYPOINT ["sh", "-c", "if [ -n \"$APPLICATIONINSIGHTS_CONNECTION_STRING\" ]; then export JAVA_TOOL_OPTIONS=\"-javaagent:/app/ai-agent.jar\"; fi; exec java -jar /app/app.jar"]
```

Put `applicationinsights.json` next to the Dockerfile:

```json
{ "role": { "name": "api" }, "customDimensions": { "service.version": "${APP_VERSION}" } }
```

### 6. One business metric (OBS-001)

This is the one number the client would ask about: orders placed, payments recorded, claims approved. It is not
something only engineers care about. Make it a **counter**, with **one attribute that says how it went** (the
outcome), and increment it at the point where the business event happens, never in a middleware. **Never put
personal data in an attribute**: no names, emails or account numbers (T-06).

**Python**

```python
from opentelemetry import metrics
orders_placed = metrics.get_meter("app").create_counter("orders_placed", description="OBS-001")
...
orders_placed.add(1, {"outcome": "accepted"})              # or "rejected", "duplicate" ...
```

**Node**

```js
import { metrics } from '@opentelemetry/api';
const ordersPlaced = metrics.getMeter('app').createCounter('orders_placed', { description: 'OBS-001' });
...
ordersPlaced.add(1, { outcome: 'accepted' });
```

**Java**: add `io.opentelemetry:opentelemetry-api:1.49.0` (compile scope). The agent connects it to Application Insights.

```java
private static final LongCounter ORDERS = GlobalOpenTelemetry.getMeter("app")
    .counterBuilder("orders_placed").setDescription("OBS-001").build();
...
ORDERS.add(1, Attributes.of(AttributeKey.stringKey("outcome"), "accepted"));
```

Use that exact name in three places: `OBS_BUSINESS_METRIC` in `ci/production.yml` (which Terraform also reads for
the dashboard tile), your observability spec, and the test.

**The test.** Read the counter back in a unit test. Python: `InMemoryMetricReader` (see the example's
`tests/test_observability.py`). Node: `MeterProvider` with an in-memory exporter from `@opentelemetry/sdk-metrics`.
Java: `opentelemetry-sdk-testing`'s `InMemoryMetricReader`. A metric that no test covers drifts silently.

### 7. Every response carries X-Request-Id (OBS-003)

The id is the trace id of the request. When a client reports "it failed at 10:42", the id in their response is
the one line of KQL that finds that request, its dependencies and its logs:
`AppRequests | where OperationId == "<id>"`.

**Python**: copy `RequestId` from the example's `telemetry.py`, and add it last so that it runs outermost.

**Node** (run and checked):

```js
import { trace } from '@opentelemetry/api';
app.use((req, res, next) => {                               // OBS-003
  const span = trace.getActiveSpan();
  if (span) res.set('X-Request-Id', span.spanContext().traceId);
  next();
});
```

**Java**: in a filter, `Span.current().getSpanContext()`. If `isValid()`, set the header to `getTraceId()`.

### 8. The drill switch, for the test environment only

To see an alert fire, the service must misbehave on purpose. The `drill:slow` and `drill:errors` jobs set two
environment variables on the running Container App. Your code reads them **on every request**, so no rebuild is
needed. `/health` is never touched. When `APP_ENV` is `production`, the switch does nothing.

| Variable | Effect |
|---|---|
| `DRILL_SLOW_MS=2500` | every request waits that long, so p95 goes over the NFR and the p95 alert fires |
| `DRILL_ERROR_PCT=30` | that share of requests return 503, so the error alert fires |

**Python**: copy `Drill` from the example's `telemetry.py`.

**Node**

```js
app.use(async (req, res, next) => {                         // the drill - never in production
  if (process.env.APP_ENV === 'production' || req.path === '/health') return next();
  const slow = Number(process.env.DRILL_SLOW_MS || 0);
  if (slow > 0) await new Promise((r) => setTimeout(r, slow));
  if (Math.random() * 100 < Number(process.env.DRILL_ERROR_PCT || 0)) {
    return res.status(503).json({ detail: 'drill: injected failure' });
  }
  next();
});
```

**Java**: a filter with the same three rules: skip in production and on `/health`; `Thread.sleep`; return
`res.sendError(503)` for that share of requests.

Write one test per switch that sets the variable and checks the effect, plus one that checks `/health` is never
touched.
