# RULE-002 - written one test at a time, each one red before the code that made it green.
# The order below is the order they were written. ../tdd-log.md tells the story.
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


def test_rule_002c_a_part_payment_is_not_paid_and_shows_the_balance():
    # Passed the first time it ran. Before keeping it we broke the code on purpose and watched it go red -
    # a test that has never failed has not proved anything yet (log, cycle 4).
    status = month_status(D("2500"), [D("1000")])
    assert not status.paid
    assert status.balance == D("1500")


def test_rule_002_instalments_in_paise_add_up_exactly():
    # Cycle 5. With float amounts these three come to 2499.9999999999995 - and the flat gets a reminder.
    assert month_status(D("2500"), [D("75.23"), D("367.28"), D("2057.49")]).paid
