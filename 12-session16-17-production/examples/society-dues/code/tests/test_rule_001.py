# The same rule examples as before the refactoring - same inputs, same answers.
# Only the way we call the code changed. The behaviour did not.
import sqlite3

import pytest

from dues.model import Payment
from dues.record_payment import PaymentRecorder
from dues.sqlite_store import SqliteFlats, SqlitePayments, SqliteUnmatched, open_store

FLATS = [("B-304", "Asha"), ("C-101", "Ravi"), ("C-102", "Ravi")]


@pytest.fixture
def db():
    connection = open_store(sqlite3.connect(":memory:"))
    connection.executemany("insert into flats values (?, ?)", FLATS)
    return connection


@pytest.fixture
def recorder(db):
    return PaymentRecorder(SqliteFlats(db), SqlitePayments(db), SqliteUnmatched(db))


def a_payment(reference="UTR1", remark="B-304", payer="Asha", source="upi"):
    return Payment(bank_reference=reference, remark=remark, payer=payer, amount=2500.0, source=source)


@pytest.mark.parametrize(
    "example, remark, payer, expected",
    [
        ("RULE-001a", "B-304 Oct maint", "Asha", "B-304"),
        ("RULE-001b", "B304", "Asha", "B-304"),
        ("RULE-001c", "Z-999", "Asha", None),
        ("RULE-001d", "Oct maint", "Asha", "B-304"),
        ("RULE-001e", "Oct maint", "Ravi", None),
    ],
)
def test_rule_001_fr_003(recorder, example, remark, payer, expected):
    assert recorder.record(a_payment(example, remark, payer)).flat == expected


def test_fr_004_same_payment_counted_once(recorder, db):
    recorder.record(a_payment(source="upi"))
    assert recorder.record(a_payment(source="statement")) is None
    assert db.execute("select count(*) from payments").fetchone()[0] == 1


def test_fr_006_unmatched_payment_is_listed_with_its_reason(recorder, db):
    recorder.record(a_payment("UTR9", remark="Z-999"))
    assert (
        db.execute("select reason from unmatched where bank_reference = 'UTR9'").fetchone()[0]
        == "flat in remark does not exist"
    )
