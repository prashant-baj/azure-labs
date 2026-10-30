# Shared by every scenario: a fresh in-memory society for each one - no scenario depends on another.
import sqlite3

import pytest

from dues.record_payment import PaymentRecorder
from dues.sqlite_store import SqliteFlats, SqlitePayments, SqliteUnmatched, open_store


@pytest.fixture
def db():
    return open_store(sqlite3.connect(":memory:"))


@pytest.fixture
def recorder(db):
    return PaymentRecorder(SqliteFlats(db), SqlitePayments(db), SqliteUnmatched(db))


@pytest.fixture
def context():
    return {}
