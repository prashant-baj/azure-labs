import srp_after
import srp_before

PAYMENTS = {"B-304": 2500, "C-101": 1000}


def test_same_behaviour():
    old = srp_before.ReminderService(PAYMENTS)
    notifier = srp_after.SmsNotifier()
    new = srp_after.ReminderService(srp_after.DuesCalculator(PAYMENTS), notifier)
    for flat in ["B-304", "C-101", "A-101"]:
        assert new.remind(flat, 2500) == old.remind(flat, 2500)
    assert notifier.sent == old.sent


def test_the_rule_can_now_be_tested_alone():
    assert srp_after.DuesCalculator({"C-101": 1000}).outstanding("C-101", 2500) == 1500
