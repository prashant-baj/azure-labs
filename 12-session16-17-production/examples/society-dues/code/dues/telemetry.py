"""Layer 6 observability - what the dashboard shows comes from here (spec: OBS-001..OBS-004).

OBS-001  Business metric: UPI payments recorded, by outcome (matched / unmatched / duplicate) - a counter.
OBS-002  Technical metric: request duration per route - from the automatic request telemetry, p95 against NFR-001.
OBS-003  Every response carries X-Request-Id: the trace id - find that one request in Application Insights.
OBS-004  Logs are structured and carry the requirement ID - never the payer's name (privacy, T-06).

Telemetry is sent only when APPLICATIONINSIGHTS_CONNECTION_STRING is set (in Azure, from a Container App secret).
Locally and in the tests nothing is sent - the OpenTelemetry API is a no-op until a provider is configured.
"""

import asyncio
import logging
import os
import random

from opentelemetry import metrics, trace
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse

log = logging.getLogger("dues")
_meter = metrics.get_meter("dues")
payments_recorded = _meter.create_counter(
    "dues_payments_recorded", unit="1", description="UPI payments recorded, by outcome (OBS-001)"
)
_configured = False


def setup(version: str) -> bool:
    """Send traces, metrics and logs to Application Insights - once per process, only when configured."""
    global _configured  # noqa: PLW0603 - one telemetry pipeline per process
    connection = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
    if _configured or not connection:
        return _configured
    from azure.monitor.opentelemetry import configure_azure_monitor  # only needed in Azure
    from opentelemetry.sdk.resources import Resource

    resource = Resource.create(
        {"service.name": os.getenv("OTEL_SERVICE_NAME", "society-dues-api"), "service.version": version}
    )
    configure_azure_monitor(connection_string=connection, resource=resource, logger_name="dues")
    logging.getLogger("dues").setLevel(logging.INFO)
    _configured = True
    return True


def record_outcome(outcome: str, requirement: str) -> None:
    """OBS-001 and OBS-004: one counter increment and one structured log line - no personal data."""
    payments_recorded.add(1, {"outcome": outcome})
    log.info("payment recorded", extra={"event": "payment.recorded", "outcome": outcome, "req": requirement})


class RequestId(BaseHTTPMiddleware):
    """OBS-003 - the trace id of this request, so a person can find it in the telemetry."""

    async def dispatch(self, request, call_next):
        response = await call_next(request)
        span = trace.get_current_span().get_span_context()
        if span.is_valid:
            response.headers["X-Request-Id"] = format(span.trace_id, "032x")
        return response


class Drill(BaseHTTPMiddleware):
    """The observability drill: slow or failing requests on purpose - test environment only, never production.

    DRILL_SLOW_MS=1500 adds latency; DRILL_ERROR_PCT=30 fails that share of requests with 503. Both read on every
    request, so `az containerapp update --set-env-vars` switches them without a rebuild. /health is never touched.
    """

    async def dispatch(self, request, call_next):
        if os.getenv("APP_ENV", "test") == "production" or request.url.path == "/health":
            return await call_next(request)
        slow = int(os.getenv("DRILL_SLOW_MS", "0") or 0)
        if slow > 0:
            await asyncio.sleep(slow / 1000)
        if random.uniform(0, 100) < float(os.getenv("DRILL_ERROR_PCT", "0") or 0):  # noqa: S311 - not security
            log.warning("drill error injected", extra={"event": "drill.error"})
            return JSONResponse({"detail": "drill: injected failure"}, status_code=503)
        return await call_next(request)
