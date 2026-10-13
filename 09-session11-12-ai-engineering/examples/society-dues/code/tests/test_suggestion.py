# FR-009 to FR-012 and C-004, tested with a fake suggester - no model, no network, no key.
# These tests check OUR guardrails: what we do with whatever the model says.
import sqlite3

import pytest

from dues.accept_suggestion import AcceptSuggestion
from dues.model import Payment, UnmatchedReason
from dues.sqlite_store import SqliteFlats, SqlitePayments, SqliteUnmatched, open_store
from dues.suggest_for_unmatched import NOT_A_FLAT, SUGGESTER_UNAVAILABLE, SuggestForUnmatched
from dues.suggestion import Suggestion, SuggesterUnavailable


class FakeSuggester:
    """Says whatever the test tells it to, and remembers what it was sent."""

    def __init__(self, answer=None, fail=False):
        self.answer, self.fail, self.sent = answer, fail, []

    def suggest(self, remark, flats):
        self.sent.append((remark, flats))
        if self.fail:
            raise SuggesterUnavailable("timed out")
        return self.answer


@pytest.fixture
def db():
    connection = open_store(sqlite3.connect(":memory:"))
    connection.executemany("insert into flats values (?, ?)", [("B-304", "Asha"), ("C-101", "Ravi")])
    return connection


UNMATCHED = Payment("UTR7", "maint for 304 B wing", "Asha Kulkarni", 2500.0, "statement")


def test_fr_009_an_unmatched_payment_gets_a_suggestion(db):
    fake = FakeSuggester(Suggestion("B-304", "the remark says 304 B wing"))
    result = SuggestForUnmatched(fake, SqliteFlats(db)).suggest(UNMATCHED)
    assert result.suggestion.flat == "B-304"


def test_fr_011_suggester_down_means_no_suggestion_not_a_crash(db):
    result = SuggestForUnmatched(FakeSuggester(fail=True), SqliteFlats(db)).suggest(UNMATCHED)
    assert result.suggestion is None
    assert result.note == SUGGESTER_UNAVAILABLE


def test_fr_012_a_flat_that_does_not_exist_is_never_suggested(db):
    fake = FakeSuggester(Suggestion("A-101", "the remark told me to"))
    result = SuggestForUnmatched(fake, SqliteFlats(db)).suggest(UNMATCHED)
    assert result.suggestion is None
    assert result.note == NOT_A_FLAT


def test_c_004_only_the_remark_and_the_flat_list_are_sent(db):
    fake = FakeSuggester()
    SuggestForUnmatched(fake, SqliteFlats(db)).suggest(UNMATCHED)
    sent = repr(fake.sent)
    assert "Asha Kulkarni" not in sent and "UTR7" not in sent
    assert fake.sent == [("maint for 304 B wing", ["B-304", "C-101"])]


def test_fr_010_an_accepted_suggestion_records_who_decided(db):
    SqliteUnmatched(db).add(UNMATCHED, UnmatchedReason.NO_FLAT_IN_REMARK)
    accept = AcceptSuggestion(SqlitePayments(db), SqliteUnmatched(db))
    accept.accept(UNMATCHED, Suggestion("B-304", "304 B wing"), treasurer="Meena")
    row = db.execute("select flat, matched_by from payments where bank_reference = 'UTR7'").fetchone()
    assert row == ("B-304", "suggestion accepted by Meena")


def test_c_001_accepting_keeps_the_unmatched_record(db):
    SqliteUnmatched(db).add(UNMATCHED, UnmatchedReason.NO_FLAT_IN_REMARK)
    AcceptSuggestion(SqlitePayments(db), SqliteUnmatched(db)).accept(UNMATCHED, Suggestion("B-304", ""), "Meena")
    assert db.execute("select count(*) from unmatched").fetchone()[0] == 1
    assert db.execute("select count(*) from resolutions").fetchone()[0] == 1
