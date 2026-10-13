# The model adapter, with a fake client - checks we read the reply safely (FR-011, FR-012).
from types import SimpleNamespace

import pytest

from dues.claude_suggester import ClaudeSuggester, parse_reply
from dues.suggestion import SuggesterUnavailable


class FakeClient:
    def __init__(self, text=None, error=None):
        self.messages = SimpleNamespace(create=self._create)
        self._text, self._error = text, error

    def _create(self, **_):
        if self._error:
            raise self._error
        return SimpleNamespace(content=[SimpleNamespace(text=self._text)])


def test_a_well_formed_reply_becomes_a_suggestion():
    s = ClaudeSuggester(FakeClient('{"flat": "B-304", "reason": "says 304 B"}'), model="any").suggest("x", ["B-304"])
    assert s.flat == "B-304"


NOT_THE_AGREED_SHAPE = ["B-304", "", "[]", '{"flat": null, "reason": "unclear"}', '{"reason": "no flat key"}']


@pytest.mark.parametrize("text", NOT_THE_AGREED_SHAPE)
def test_fr_012_anything_else_is_no_suggestion(text):
    assert parse_reply(text) is None


def test_fr_011_a_failing_call_is_reported_as_unavailable():
    suggester = ClaudeSuggester(FakeClient(error=TimeoutError("slow")), model="any")
    with pytest.raises(SuggesterUnavailable):
        suggester.suggest("x", ["B-304"])
