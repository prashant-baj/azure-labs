"""Every If row tested with a fake - no model, no key, no network."""

import json

from triage.adapters.fake import FakeSuggester
from triage.model import MAX_MESSAGE_CHARS
from triage.service import TriageService, mask_personal_data, parse_reply


def triage(message, **fake):
    return TriageService(FakeSuggester(**fake)).triage(message)


def test_a_clear_message_gets_a_suggestion():
    result = triage("There is a leak in the B wing lift lobby")
    assert result.status == "suggested" and result.suggestion.category == "maintenance_request"


def test_model_down_means_no_suggestion_not_a_crash():  # If row 1
    result = triage("leak in the lobby", fail=True)
    assert result.status == "unavailable" and result.suggestion is None


def test_answer_outside_the_list_is_thrown_away():  # If row 2
    result = triage("hello", reply=json.dumps({"category": "refund_everyone", "reason": "x"}))
    assert result.status == "no_suggestion" and result.suggestion is None


def test_not_json_is_thrown_away():  # If row 2
    assert triage("hello", reply="Sure! I think it is maintenance.").status == "no_suggestion"


def test_too_long_or_empty_never_reaches_the_model():  # If row 3
    fake = FakeSuggester()
    service = TriageService(fake)
    assert service.triage("x" * (MAX_MESSAGE_CHARS + 1)).status == "rejected_input"
    assert service.triage("   ").status == "rejected_input"
    assert fake.seen == []


def test_phone_and_email_never_leave_the_system():  # DR-01
    fake = FakeSuggester()
    TriageService(fake).triage("Call me on +91 98200 12345 or mail a.resident@example.com about the gate")
    assert "98200" not in fake.seen[0] and "example.com" not in fake.seen[0]
    assert "[phone]" in fake.seen[0] and "[email]" in fake.seen[0]


def test_flat_numbers_are_not_mistaken_for_phones():
    assert mask_personal_data("Flat B-304, 2nd floor") == "Flat B-304, 2nd floor"


def test_reason_is_cut_to_a_safe_length():
    s = parse_reply(json.dumps({"category": "other", "reason": "x" * 999}))
    assert len(s.reason) == 200


def test_code_fenced_json_is_accepted():
    assert parse_reply('```json\n{"category": "other", "reason": "r"}\n```').category == "other"


def test_nobody_has_decided_yet():  # FR-104
    assert triage("noise from 402 after midnight").to_dict()["decided_by"] is None
