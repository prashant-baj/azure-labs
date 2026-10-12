import pytest

from strategy_example import FlatAmount, PercentPerLateMonth, Waived, amount_due


@pytest.mark.parametrize(
    "strategy,expected",
    [
        (PercentPerLateMonth(0.02), 2550.0),
        (FlatAmount(500), 3000.0),
        (Waived(), 2500.0),
    ],
)
def test_same_caller_different_rules(strategy, expected):
    assert amount_due(2500, 20, strategy) == pytest.approx(expected)


def test_grace_period_applies_to_every_strategy():
    for strategy in (PercentPerLateMonth(0.02), FlatAmount(500), Waived()):
        assert amount_due(2500, 15, strategy) == 2500
