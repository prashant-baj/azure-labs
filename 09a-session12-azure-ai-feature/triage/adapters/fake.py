"""A fake model for tests and for running without a key. It keeps the same promise as the real one."""

import json

from triage.ports import SuggesterUnavailable


class FakeSuggester:
    def __init__(self, reply: str | None = None, fail: bool = False):
        self.reply, self.fail, self.seen = reply, fail, []

    def suggest(self, message: str, categories: tuple[str, ...]) -> str:
        self.seen.append(message)
        if self.fail:
            raise SuggesterUnavailable("fake outage")
        if self.reply is not None:
            return self.reply
        text = message.lower()  # a tiny keyword rule, so the app works end to end without a model
        for word, category in [
            ("leak", "maintenance_request"),
            ("lift", "maintenance_request"),
            ("dues", "dues_and_payments"),
            ("receipt", "dues_and_payments"),
            ("noise", "noise_or_neighbour"),
            ("gate", "security_and_access"),
            ("hall", "amenities_booking"),
            ("pool", "amenities_booking"),
        ]:
            if word in text:
                return json.dumps({"category": category, "reason": f"mentions '{word}'"})
        return json.dumps({"category": "other", "reason": "no keyword matched"})
