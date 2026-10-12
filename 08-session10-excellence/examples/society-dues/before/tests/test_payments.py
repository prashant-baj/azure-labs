# The rule examples from spec.md section 5 (RULE-001a-e), written before any refactoring.
# They pin today's behaviour: the same table runs, unchanged, against the refactored code.
import pytest
from dues.payments import PaymentManager

FLATS = [("B-304", "Asha"), ("C-101", "Ravi"), ("C-102", "Ravi")]

@pytest.fixture
def pm():
    m = PaymentManager(":memory:")
    m.conn.executemany("insert into flats values (?,?)", FLATS)
    return m

@pytest.mark.parametrize("example, remark, payer, expected", [
    ("RULE-001a", "B-304 Oct maint", "Asha", "B-304"),
    ("RULE-001b", "B304", "Asha", "B-304"),
    ("RULE-001c", "Z-999", "Asha", None),
    ("RULE-001d", "Oct maint", "Asha", "B-304"),
    ("RULE-001e", "Oct maint", "Ravi", None),
])
def test_rule_001_fr_003(pm, example, remark, payer, expected):
    p = {"ref": example, "remark": remark, "payer": payer, "amt": 2500.0, "src": "upi"}
    assert pm.process(p) == expected

def test_fr_004_same_payment_counted_once(pm):
    p = {"ref": "UTR1", "remark": "B-304", "payer": "Asha", "amt": 2500.0, "src": "upi"}
    pm.process(p)
    pm.process(dict(p, src="statement"))
    assert pm.conn.execute("select count(*) from payments").fetchone()[0] == 1
