# API tests in-process - the integration layer of the strategy. Fast, before every merge.
# The same behaviour is checked again against the deployed service by the Postman collection.
import pytest
from fastapi.testclient import TestClient

from dues.api import create_app

TREASURER = {"X-Role": "treasurer"}


@pytest.fixture
def client():
    return TestClient(create_app())


def pay(client, ref, remark, payer="Asha", amount="2500"):
    body = {"bank_reference": ref, "remark": remark, "payer": payer, "amount": amount}
    return client.post("/payments/upi", json=body)


def test_health_reports_the_version(client):
    assert client.get("/health").json()["status"] == "ok"


def test_fr_003_a_upi_payment_is_matched_by_its_remark(client):
    assert pay(client, "UTR-1", "B-304 Oct maint").json()["flat"] == "B-304"


def test_fr_004_the_same_bank_reference_is_counted_once(client):
    pay(client, "UTR-2", "B-304")
    assert pay(client, "UTR-2", "B-304").json()["duplicate"] is True


def test_fr_006_an_unknown_flat_goes_to_the_unmatched_list_with_its_reason(client):
    pay(client, "UTR-3", "Z-999")
    assert {"bank_reference": "UTR-3", "reason": "flat in remark does not exist"} in client.get(
        "/unmatched", headers=TREASURER
    ).json()


def test_fr_008_a_flat_that_paid_in_full_is_not_reminded(client):
    pay(client, "UTR-4", "B-304")
    flats = [r["flat"] for r in client.get("/reminders", headers=TREASURER).json()]
    assert "B-304" not in flats and "A-101" in flats


def test_c_002_a_resident_may_not_see_the_reminder_list(client):
    assert client.get("/reminders", headers={"X-Role": "resident"}).status_code == 403


# "0", "12.345" and "abc" were AI-suggested (/suggest-tests), seen red, kept - reviews/ai-tests.md
@pytest.mark.parametrize("amount", ["0", "-5", "12.345", "abc"])
def test_fr_001_an_impossible_amount_is_refused(client, amount):
    assert pay(client, "UTR-5", "B-304", amount=amount).status_code == 422


def test_the_treasurers_page_lists_who_still_owes(client):
    page = client.get("/ui/reminders").text
    assert 'data-flat="A-101"' in page
