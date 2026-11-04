# FR-009, FR-010 and C-001 - added in Session 12 after the spec review (reviews/spec-review.md, row 5).
import sqlite3

import pytest

from dues.match_by_hand import FlatNotInDirectory, MatchByHand
from dues.model import Payment, UnmatchedReason
from dues.sqlite_store import SqliteFlats, SqlitePayments, SqliteUnmatched, open_store

UNMATCHED = Payment("REF-77", "Oct maint", "S Iyer", 2500.0, "statement")


@pytest.fixture
def db():
    connection = open_store(sqlite3.connect(":memory:"))
    connection.executemany("insert into flats values (?, ?)", [("B-304", "Asha"), ("C-101", "Ravi")])
    SqliteUnmatched(connection).add(UNMATCHED, UnmatchedReason.NO_FLAT_IN_REMARK)
    return connection


def by_hand(db):
    return MatchByHand(SqliteFlats(db), SqlitePayments(db), SqliteUnmatched(db))


def test_fr_009_the_record_says_who_matched_it(db):
    by_hand(db).match(UNMATCHED, "B-304", "Meena")
    flat, matched_by = db.execute("select flat, matched_by from payments").fetchone()
    assert (flat, matched_by) == ("B-304", "matched by hand by Meena")


def test_c_001_matching_by_hand_keeps_the_unmatched_record(db):
    by_hand(db).match(UNMATCHED, "B-304", "Meena")
    assert db.execute("select count(*) from unmatched").fetchone()[0] == 1
    assert db.execute("select count(*) from resolutions").fetchone()[0] == 1


def test_fr_010_a_flat_the_society_does_not_have_is_refused(db):
    with pytest.raises(FlatNotInDirectory):
        by_hand(db).match(UNMATCHED, "Z-999", "Meena")
    assert db.execute("select count(*) from payments").fetchone()[0] == 0
    assert db.execute("select count(*) from resolutions").fetchone()[0] == 0
