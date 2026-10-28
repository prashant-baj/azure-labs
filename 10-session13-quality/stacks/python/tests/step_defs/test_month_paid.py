"""Thin steps: words into calls, then compare. The rule lives in dues/, never here."""

from decimal import Decimal

from pytest_bdd import given, parsers, scenarios, then, when

from dues.month_status import month_status

scenarios("month_paid.feature")  # or scenarios(".") - every feature under bdd_features_base_dir


@given(parsers.parse("the dues for the month are {dues:d}"), target_fixture="dues")
def the_dues(dues):
    return Decimal(dues)


@given(parsers.parse("the flat has paid {payments}"), target_fixture="payments")
def the_payments(payments):
    return [] if payments == "nothing" else [Decimal(p.strip()) for p in payments.split("+")]


@when("the treasurer checks the month", target_fixture="status")
def check_the_month(dues, payments):
    return month_status(dues, payments)


@then(parsers.parse("the flat is {expected} with a balance of {balance:d}"))
def the_flat_is(status, expected, balance):
    assert status.paid == (expected == "paid")
    assert status.balance == Decimal(balance)
