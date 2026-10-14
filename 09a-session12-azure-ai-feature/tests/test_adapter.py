"""The real adapter, tested with a stand-in client: same promise as the fake (contract)."""

import pytest

from triage.adapters.openai_compatible import OpenAICompatibleSuggester
from triage.ports import SuggesterUnavailable


class _Msg:
    def __init__(self, content):
        self.message = type("M", (), {"content": content})()


class StubClient:
    def __init__(self, content=None, error=None):
        self.calls, self._content, self._error = [], content, error
        self.chat = type("C", (), {"completions": self})()

    def create(self, **kwargs):
        self.calls.append(kwargs)
        if self._error:
            raise self._error
        return type("R", (), {"choices": [_Msg(self._content)]})()


def test_sends_the_message_as_data_with_the_allowed_list():
    client = StubClient('{"category": "other", "reason": "r"}')
    reply = OpenAICompatibleSuggester(client, model="m").suggest("hello", ("other",))
    sent = client.calls[0]
    assert reply.startswith("{") and sent["model"] == "m" and sent["temperature"] == 0
    assert sent["messages"][0]["role"] == "system" and '"message": "hello"' in sent["messages"][1]["content"]


def test_any_failure_becomes_unavailable():
    with pytest.raises(SuggesterUnavailable):
        OpenAICompatibleSuggester(StubClient(error=TimeoutError("slow")), model="m").suggest("x", ("other",))
