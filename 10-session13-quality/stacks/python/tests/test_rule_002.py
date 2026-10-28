# TDD on the rule - one example per test, named after it, each seen red first.
from decimal import Decimal as D

from dues.month_status import month_status


def test_rule_002d_no_payment_leaves_the_whole_dues():
    status = month_status(D("2500"), [])
    assert not status.paid
    assert status.balance == D("2500")


def test_rule_002a_one_payment_of_the_full_dues_is_paid():
    assert month_status(D("2500"), [D("2500")]).paid


def test_rule_002b_two_payments_that_cover_the_dues_are_paid():
    assert month_status(D("2500"), [D("1500"), D("1000")]).paid


def test_rule_002c_a_part_payment_shows_the_balance():
    assert month_status(D("2500"), [D("1000")]).balance == D("1500")
