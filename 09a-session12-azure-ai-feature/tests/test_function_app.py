"""The HTTP layer: thin, and it never claims a person decided."""

import json

import azure.functions as func
import pytest

import function_app


@pytest.fixture(autouse=True)
def no_model(monkeypatch):
    monkeypatch.delenv("MODEL_BASE_URL", raising=False)
    monkeypatch.delenv("MODEL_API_KEY", raising=False)


def call(fn, body):
    raw = body if isinstance(body, bytes) else json.dumps(body).encode()
    req = func.HttpRequest(method="POST", url="/api/x", body=raw, headers={"Content-Type": "application/json"})
    resp = fn.build().get_user_function()(req)
    return resp.status_code, json.loads(resp.get_body())


def test_triage_returns_a_suggestion_from_the_fake_when_no_model_is_set():
    status, body = call(function_app.triage, {"message": "the pool booking page is down"})
    assert status == 200 and body["suggested_by"] == "fake" and body["decided_by"] is None


def test_unresolved_key_vault_reference_falls_back_to_the_fake(monkeypatch):
    monkeypatch.setenv("MODEL_BASE_URL", "https://example.invalid/v1")
    monkeypatch.setenv("MODEL_API_KEY", "@Microsoft.KeyVault(VaultName=kv;SecretName=model-api-key)")
    status, body = call(function_app.triage, {"message": "gate is broken"})
    assert status == 200 and body["suggested_by"] == "fake"


def test_bad_json_is_a_400():
    status, _ = call(function_app.triage, b"not json")
    assert status == 400


def test_a_decision_must_name_the_person():
    status, _ = call(function_app.decision, {"message_id": "M1", "category": "other", "accepted": True})
    assert status == 400
    status, body = call(
        function_app.decision, {"message_id": "M1", "category": "other", "accepted": False, "decided_by": "office-asha"}
    )
    assert status == 200 and body["decided_by"] == "office-asha"
