"""Adapters: the ports, kept in SQLite. The connection is passed in - never built here (E-008)."""
import sqlite3

from dues.model import Payment, UnmatchedReason

SCHEMA = """
create table if not exists flats (flat text, payer text);
create table if not exists payments (
    bank_reference text primary key, flat text, amount real, source text, matched_by text
);
create table if not exists unmatched (bank_reference text primary key, reason text);
create table if not exists resolutions (bank_reference text primary key, flat text, decided_by text);
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

    def all_flats(self) -> list[str]:
        return [row[0] for row in self._db.execute("select distinct flat from flats order by flat")]


class SqlitePayments:
    def __init__(self, db: sqlite3.Connection):
        self._db = db

    def has(self, bank_reference: str) -> bool:
        found = self._db.execute("select 1 from payments where bank_reference = ?", (bank_reference,))
        return found.fetchone() is not None

    def record(self, payment: Payment, flat: str, matched_by: str = "RULE-001") -> None:
        with self._db:
            self._db.execute("insert into payments values (?, ?, ?, ?, ?)",
                             (payment.bank_reference, flat, payment.amount, payment.source, matched_by))


class SqliteUnmatched:
    def __init__(self, db: sqlite3.Connection):
        self._db = db

    def has(self, bank_reference: str) -> bool:
        found = self._db.execute("select 1 from unmatched where bank_reference = ?", (bank_reference,))
        return found.fetchone() is not None

    def add(self, payment: Payment, reason: UnmatchedReason) -> None:
        with self._db:
            self._db.execute("insert into unmatched values (?, ?)", (payment.bank_reference, reason.value))

    def resolve(self, bank_reference: str, flat: str, decided_by: str) -> None:
        # C-001: nothing is deleted - a resolution is a new record next to the unmatched entry
        with self._db:
            self._db.execute("insert into resolutions values (?, ?, ?)", (bank_reference, flat, decided_by))
