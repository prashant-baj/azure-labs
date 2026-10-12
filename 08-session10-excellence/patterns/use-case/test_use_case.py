from use_case_example import RecordCashPayment, Result


class FakePayments:
    def __init__(self):
        self.rows = []

    def add(self, p):
        self.rows.append(p)

    def exists(self, ref):
        return any(p.reference == ref for p in self.rows)


class FakeFlats:
    def exists(self, flat):
        return flat in {"A-101", "B-304"}


def make():
    payments = FakePayments()
    return RecordCashPayment(payments, FakeFlats()), payments


def test_records_and_says_who():
    use_case, payments = make()
    assert use_case.run("B-304", 2500, "RC-17", "treasurer").ok
    assert payments.rows[0].recorded_by == "treasurer"


def test_the_same_receipt_twice_is_refused():
    use_case, payments = make()
    use_case.run("B-304", 2500, "RC-17", "treasurer")
    assert use_case.run("B-304", 2500, "RC-17", "treasurer") == Result(False, "Receipt RC-17 is already recorded")
    assert len(payments.rows) == 1


def test_bad_input_never_reaches_storage():
    use_case, payments = make()
    assert not use_case.run("Z-999", 2500, "RC-18", "treasurer").ok
    assert not use_case.run("B-304", 0, "RC-19", "treasurer").ok
    assert payments.rows == []
