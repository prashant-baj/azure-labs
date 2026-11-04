"""Steps for features/reminders.feature (US-002). The amounts in the scenarios are rupees."""

from decimal import Decimal

from pytest_bdd import given, parsers, scenarios, then, when

from dues.model import Payment
from dues.reminders import reminder_list
from dues.sqlite_store import SqlitePayments

scenarios("reminders.feature")


def _amounts(text: str) -> list[Decimal]:
    return [] if text == "nothing" else [Decimal(part.strip()) for part in text.split("+")]


@given(parsers.parse("this month's dues are {amount:d} for every flat"))
def dues_for_every_flat(context, amount):
    context["dues_each"] = Decimal(amount)


@given(parsers.parse("the society has the flats {first}, {second} and {third}"))
def the_flats(db, context, first, second, third):
    context["flats"] = [first, second, third]
    db.executemany("insert into flats values (?, ?)", [(flat, f"owner of {flat}") for flat in context["flats"]])


@given(parsers.parse("{flat} has paid {payments} this month"))
def has_paid(context, flat, payments):
    context["paid"] = {flat: _amounts(payments)}


@given(parsers.parse("{flat} paid {amount:d} by UPI this morning"))
def paid_by_upi(recorder, db, context, flat, amount):
    recorder.record(Payment("UTR-9", f"{flat} maintenance", f"owner of {flat}", float(amount), "upi"))
    context["paid"] = SqlitePayments(db).amounts_by_flat()  # end to end: matched, recorded, read back


@when("the treasurer asks for the reminder list")
def ask_for_the_list(context):
    dues = {flat: context["dues_each"] for flat in context["flats"]}
    context["list"] = {r.flat: r.balance for r in reminder_list(dues, context.get("paid", {}))}


@then(parsers.parse("the reminder list shows {flat}"))
def list_shows(context, flat):
    assert flat in context["list"]


@then(parsers.parse("the reminder list leaves out {flat}"))
def list_leaves_out(context, flat):
    assert flat not in context["list"]


@then(parsers.parse("the balance of {flat} is {balance:d}"))
def balance_is(context, flat, balance):
    assert context["list"].get(flat, Decimal(0)) == Decimal(balance)


@then(parsers.parse("{flat} is not on the list"))
def not_on_list(context, flat):
    assert flat not in context["list"]


@then(parsers.parse("{first} and {second} are on the list"))
def both_on_list(context, first, second):
    assert first in context["list"] and second in context["list"]
