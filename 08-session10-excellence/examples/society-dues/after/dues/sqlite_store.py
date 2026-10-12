"""Adapters: the ports, kept in SQLite. The connection is passed in - never built here (E-008)."""
import sqlite3

from dues.model import Payment, UnmatchedReason

SCHEMA = """
create table if not exists flats (flat text, payer text);
create table if not exists payments (bank_reference text primary key, flat text, amount real, source text);
create table if not exists unmatched (bank_reference text primary key, reason text);
"""


def open_store(connection: sqlite3.Connection) -> sqlite3.Connection:
    connection.executescript(SCHEMA)
    return connection


class SqliteFlats:
    def __init__(self, db: sqlite3.Connection):
        self._db = db

    def exists(self, flat: str) -> bool:
        return self._db.execute("select 1 from flats where flat = ?", (flat,)).fetchone() is not None

    def flats_paid_by(self, payer: str) -> list[str]:
        return [row[0] for row in self._db.execute("select flat from flats where payer = ?", (payer,))]


class SqlitePayments:
    def __init__(self, db: sqlite3.Connection):
        self._db = db

    def has(self, bank_reference: str) -> bool:
        found = self._db.execute("select 1 from payments where bank_reference = ?", (bank_reference,))
        return found.fetchone() is not None

    def record(self, payment: Payment, flat: str) -> None:
        with self._db:
            self._db.execute("insert into payments values (?, ?, ?, ?)",
                             (payment.bank_reference, flat, payment.amount, payment.source))


class SqliteUnmatched:
    def __init__(self, db: sqlite3.Connection):
        self._db = db

    def has(self, bank_reference: str) -> bool:
        found = self._db.execute("select 1 from unmatched where bank_reference = ?", (bank_reference,))
        return found.fetchone() is not None

    def add(self, payment: Payment, reason: UnmatchedReason) -> None:
        with self._db:
            self._db.execute("insert into unmatched values (?, ?)", (payment.bank_reference, reason.value))
