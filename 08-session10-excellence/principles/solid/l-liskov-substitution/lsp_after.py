# AFTER - every notifier keeps the same promise, so any one can stand in for any other.
from typing import Protocol


class Notifier(Protocol):
    def send(self, flat: str, message: str) -> bool:
        """Try to deliver. True if delivered, False if not. Never raise for a missing contact."""
        ...


class SmsNotifier:
    def __init__(self, phones):
        self.phones, self.sent = phones, []

    def send(self, flat, message):
        if flat not in self.phones:
            return False
        self.sent.append((flat, message))
        return True


class EmailNotifier:
    def __init__(self, emails):
        self.emails, self.sent = emails, []

    def send(self, flat, message):
        if flat not in self.emails:
            return False  # same promise as SmsNotifier
        self.sent.append((self.emails[flat], message))
        return True


def remind_all(notifier: Notifier, flats, message):
    return [flat for flat in flats if not notifier.send(flat, message)]
