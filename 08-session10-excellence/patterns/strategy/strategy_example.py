# STRATEGY - the spec lists different late-fee rules for different unit types.
# Each rule is one small class with the same method. The caller picks one; it never branches.
from typing import Protocol

GRACE_DAYS = 15


class LateFeeStrategy(Protocol):
    def fee(self, dues: float, days_late: int) -> float: ...


class PercentPerLateMonth:  # residential: a share of dues per late month
    def __init__(self, rate: float):
        self.rate = rate

    def fee(self, dues, days_late):
        return dues * self.rate * ((days_late - GRACE_DAYS) // 30 + 1)


class FlatAmount:  # commercial, parking: a fixed amount
    def __init__(self, amount: float):
        self.amount = amount

    def fee(self, dues, days_late):
        return self.amount


class Waived:  # committee decision: no fee for this unit
    def fee(self, dues, days_late):
        return 0.0


def amount_due(dues: float, days_late: int, strategy: LateFeeStrategy) -> float:
    if days_late <= GRACE_DAYS:
        return dues
    return dues + strategy.fee(dues, days_late)
