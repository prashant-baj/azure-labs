# AFTER - the rule says WHAT it needs (ports). The outside world is plugged in from outside.
# The rule imports no database, no clock and no gateway. Arrows point inward, to the rule.
import datetime
from dataclasses import dataclass
from typing import Protocol

GRACE_DAYS = 15


@dataclass(frozen=True)
class Due:
    flat: str
    due_date: datetime.date
    outstanding: float


class DuesSource(Protocol):  # port: where dues come from
    def open_dues(self) -> list[Due]: ...


class Clock(Protocol):  # port: what day it is
    def today(self) -> datetime.date: ...


class Notifier(Protocol):  # port: how a resident is told
    def send(self, flat: str, message: str) -> bool: ...


class ReminderJob:
    def __init__(self, dues: DuesSource, clock: Clock, notifier: Notifier):
        self._dues, self._clock, self._notifier = dues, clock, notifier

    def run(self):
        today = self._clock.today()
        reminded = []
        for due in self._dues.open_dues():
            if due.outstanding > 0 and (today - due.due_date).days > GRACE_DAYS:
                self._notifier.send(due.flat, f"Rs {due.outstanding:.0f} pending")
                reminded.append(due.flat)
        return reminded


# The SQLite adapter, the system clock and the SMS gateway live in adapters/ and are
# wired together in one place (main / composition root) - see patterns/repository.
