# Refactoring changes the shape, never the answers: the same table runs against both versions.
import pytest

from clean_code_after import UnitType, amount_due
from clean_code_before import calc

CASES = [  # dues, days late, unit
    (2500, 0, 1),
    (2500, 15, 1),
    (2500, 16, 1),
    (2500, 46, 1),
    (2500, 75, 1),
    (8000, 10, 2),
    (8000, 40, 2),
]


@pytest.mark.parametrize("dues, days, unit", CASES)
def test_same_answers_before_and_after(dues, days, unit):
    assert amount_due(dues, days, UnitType(unit)) == pytest.approx(calc(days, dues, unit))


def test_bad_input_is_reported_not_hidden():
    # Before: calc(-1, ...) quietly returned a number. After: the mistake is visible.
    with pytest.raises(ValueError):
        amount_due(2500, -1, UnitType.RESIDENTIAL)
