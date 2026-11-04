# Layer 6 observability tests - the dashboard is only as good as what the code emits (spec OBS-001..OBS-004).
# The real exporter sends to Application Insights; here an in-memory reader shows exactly what would be sent.
import logging

import pytest
from fastapi.testclient import TestClient
from opentelemetry import metrics, trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import InMemoryMetricReader
from opentelemetry.sdk.trace import TracerProvider

from dues.api import create_app

READER = InMemoryMetricReader()
metrics.set_meter_provider(MeterProvider(metric_readers=[READER]))
trace.set_tracer_provider(TracerProvider())


@pytest.fixture
def client():
    app = create_app()
    FastAPIInstrumentor.instrument_app(app)
    return TestClient(app)


def pay(client, ref, remark, payer="Asha"):
    body = {"bank_reference": ref, "remark": remark, "payer": payer, "amount": "2500"}
    return client.post("/payments/upi", json=body)


def recorded() -> dict:
    """Current value of dues_payments_recorded, by outcome."""
    data = READER.get_metrics_data()
    found = [m for rm in data.resource_metrics for sm in rm.scope_metrics for m in sm.metrics]
    points = [p for m in found if m.name == "dues_payments_recorded" for p in m.data.data_points]
    return {p.attributes["outcome"]: p.value for p in points}


def test_obs_001_every_payment_is_counted_by_outcome(client):
    before = recorded()
    pay(client, "OBS-1", "B-304")  # matched
    pay(client, "OBS-1", "B-304")  # duplicate
    pay(client, "OBS-2", "Z-999")  # unmatched
    after = recorded()
    for outcome in ("matched", "duplicate", "unmatched"):
        assert after[outcome] - before.get(outcome, 0) == 1


def test_obs_003_every_response_carries_its_request_id(client):
    rid = client.get("/health").headers.get("X-Request-Id", "")
    assert len(rid) == 32 and int(rid, 16) > 0


def test_obs_004_t06_the_log_line_names_the_requirement_never_the_payer(client, caplog):
    with caplog.at_level(logging.INFO, logger="dues"):
        pay(client, "OBS-3", "A-101", payer="Meera Iyer")
    line = next(r for r in caplog.records if getattr(r, "event", "") == "payment.recorded")
    assert line.req == "FR-003"
    assert "Meera" not in str(line.__dict__)


def test_drill_injects_failures_but_never_on_health(client, monkeypatch):
    monkeypatch.setenv("DRILL_ERROR_PCT", "100")
    assert client.get("/unmatched").status_code == 503
    assert client.get("/health").status_code == 200


def test_drill_is_ignored_in_production(client, monkeypatch):
    monkeypatch.setenv("DRILL_ERROR_PCT", "100")
    monkeypatch.setenv("APP_ENV", "production")
    assert client.get("/health").status_code == 200
    assert pay(client, "OBS-4", "C-101").status_code == 201
