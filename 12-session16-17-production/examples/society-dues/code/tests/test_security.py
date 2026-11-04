# Layer 6 security tests - each named after the threat-model row it closes (../threat-model.md).
import sqlite3

import pytest
from fastapi.testclient import TestClient

from dues.api import create_app
from dues.security import SECURITY_HEADERS
from dues.sqlite_store import open_store

ROLE = {"X-Role": "treasurer"}


@pytest.fixture
def client():
    return TestClient(create_app())


@pytest.mark.parametrize("path", ["/reminders", "/unmatched", "/ui/reminders"])
def test_sec_001_t01_a_role_header_without_the_key_is_refused(client, path):
    assert client.get(path, headers=ROLE).status_code == 401


@pytest.mark.parametrize("path", ["/reminders", "/unmatched", "/ui/reminders"])
def test_sec_001_t01_a_wrong_key_is_refused(client, path):
    assert client.get(path, headers={**ROLE, "X-Api-Key": "guess"}).status_code == 401


def test_sec_001_t01_the_right_role_and_key_get_in(client, treasurer_key):
    assert client.get("/reminders", headers={**ROLE, "X-Api-Key": treasurer_key}).status_code == 200


def test_sec_001_t02_no_key_configured_means_nobody_gets_in(client, monkeypatch, treasurer_key):
    monkeypatch.delenv("TREASURER_KEY")
    assert client.get("/reminders", headers={**ROLE, "X-Api-Key": treasurer_key}).status_code == 503


def test_sec_001_t03_the_treasurers_page_is_not_public_any_more(client):
    assert client.get("/ui/reminders").status_code == 403


@pytest.mark.parametrize("path", ["/health", "/reminders"])
def test_sec_002_t04_every_response_carries_the_security_headers(client, path):
    headers = client.get(path).headers
    for name, value in SECURITY_HEADERS.items():
        assert headers[name] == value


def test_sec_002_t04_no_api_explorer_in_the_deployed_service(client):
    assert client.get("/docs").status_code == 404
    assert client.get("/openapi.json").status_code == 404


def test_sec_003_t05_a_flat_name_is_escaped_in_the_page(treasurer_key):
    db = open_store(sqlite3.connect(":memory:", check_same_thread=False))
    db.execute("insert into flats values (?, ?)", ("<script>alert(1)</script>", "x"))
    page = TestClient(create_app(db)).get("/ui/reminders", headers={**ROLE, "X-Api-Key": treasurer_key}).text
    assert "<script>alert(1)</script>" not in page
    assert "&lt;script&gt;" in page
