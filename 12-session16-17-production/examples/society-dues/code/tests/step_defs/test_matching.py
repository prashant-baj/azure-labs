"""Steps for features/matching.feature (US-001). Thin: each step calls the real use case - no logic here."""

from pytest_bdd import given, parsers, scenarios, then, when

from dues.model import Payment

scenarios("matching.feature")


def _payment(reference, payer, remark, source="upi"):
    return Payment(bank_reference=reference, remark=remark, payer=payer, amount=2500.0, source=source)


@given("the society has these flats")
def flats(db, datatable):
    db.executemany("insert into flats values (?, ?)", [tuple(row) for row in datatable[1:]])


@when(parsers.parse('a payment arrives from {payer} with the remark "{remark}"'))
def payment_arrives(recorder, context, payer, remark):
    context["match"] = recorder.record(_payment("UTR-1", payer, remark))


@then(parsers.parse("it is matched to {flat}"))
def matched_to(context, flat):
    assert context["match"].flat == flat


@then("it is not matched to any flat")
def not_matched(context):
    assert not context["match"].matched


@then(parsers.parse('the unmatched list shows it with the reason "{reason}"'))
def unmatched_with_reason(db, reason):
    assert db.execute("select reason from unmatched where bank_reference = 'UTR-1'").fetchone() == (reason,)


@given(parsers.parse('a payment from {payer} with the remark "{remark}" arrived by UPI'))
def arrived_by_upi(recorder, context, payer, remark):
    context["first"] = _payment("UTR-7", payer, remark, source="upi")
    recorder.record(context["first"])


@when("the morning statement brings the same payment again")
def same_payment_again(recorder, context):
    first = context["first"]
    recorder.record(_payment(first.bank_reference, first.payer, first.remark, source="statement"))


@then(parsers.parse("{flat} has one payment counted"))
def one_payment_counted(db, flat):
    assert db.execute("select count(*) from payments where flat = ?", (flat,)).fetchone() == (1,)
