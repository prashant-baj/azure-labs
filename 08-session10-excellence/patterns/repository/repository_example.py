# REPOSITORY - "today SQLite, tomorrow a cloud database". The rule talks to a collection-like
# interface in glossary words. Only the repository knows SQL.
import sqlite3
from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class Payment:
    flat: str
    amount: float
    reference: str


class PaymentRepository(Protocol):
    def add(self, payment: Payment) -> None: ...
    def for_flat(self, flat: str) -> list[Payment]: ...
    def exists(self, reference: str) -> bool: ...


class InMemoryPaymentRepository:  # for tests and demos
    def __init__(self):
        self._rows: list[Payment] = []

    def add(self, payment):
        self._rows.append(payment)

    def for_flat(self, flat):
        return [p for p in self._rows if p.flat == flat]

    def exists(self, reference):
        return any(p.reference == reference for p in self._rows)


class SqlitePaymentRepository:  # the real one - all SQL lives here
    def __init__(self, path=":memory:"):
        self._db = sqlite3.connect(path)
        self._db.execute("CREATE TABLE IF NOT EXISTS payment (flat TEXT, amount REAL, reference TEXT UNIQUE)")

    def add(self, payment):
        with self._db:
            self._db.execute(
                "INSERT INTO payment VALUES (?, ?, ?)",  # parameters, never f-strings
                (payment.flat, payment.amount, payment.reference),
            )

    def for_flat(self, flat):
        rows = self._db.execute("SELECT flat, amount, reference FROM payment WHERE flat = ?", (flat,))
        return [Payment(*r) for r in rows]

    def exists(self, reference):
        row = self._db.execute("SELECT 1 FROM payment WHERE reference = ?", (reference,)).fetchone()
        return row is not None
