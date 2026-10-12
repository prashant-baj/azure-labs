import pytest

import ocp_after
import ocp_before

CASES = [
    ("residential", 2500, 10),
    ("residential", 2500, 16),
    ("residential", 2500, 50),
    ("commercial", 9000, 40),
    ("parking", 600, 20),
    ("parking", 600, 3),
]


@pytest.mark.parametrize("unit,dues,days", CASES)
def test_same_answers(unit, dues, days):
    assert ocp_after.late_fee(unit, dues, days) == pytest.approx(ocp_before.late_fee(unit, dues, days))


def test_a_new_unit_type_without_editing_old_rules():
    rules = {**ocp_after.RULES, "shop": ocp_after.FlatFeeRule(250)}
    assert ocp_after.late_fee("shop", 4000, 30, rules) == 250


def test_unknown_unit_type_is_an_error():
    with pytest.raises(ValueError):
        ocp_after.late_fee("hostel", 1000, 30)
