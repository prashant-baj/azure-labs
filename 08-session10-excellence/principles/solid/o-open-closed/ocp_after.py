# AFTER - the rule is open to new unit types and closed to editing.
# A new unit type is a new class plus one line in the registry. Existing rules are not touched.
from typing import Protocol

GRACE_DAYS = 15


class LateFeeRule(Protocol):
    def fee(self, dues: float, days_late: int) -> float: ...


class ResidentialRule:
    def fee(self, dues, days_late):
        late_months = (days_late - GRACE_DAYS) // 30 + 1
        return dues * 0.02 * late_months


class FlatFeeRule:  # commercial and parking differ only in the amount
    def __init__(self, amount):
        self.amount = amount

    def fee(self, dues, days_late):
        return self.amount


RULES: dict[str, LateFeeRule] = {
    "residential": ResidentialRule(),
    "commercial": FlatFeeRule(500),
    "parking": FlatFeeRule(100),
}


def late_fee(unit_type, dues, days_late, rules=RULES):
    if days_late <= GRACE_DAYS:
        return 0
    if unit_type not in rules:
        raise ValueError(f"unknown unit type: {unit_type}")
    return rules[unit_type].fee(dues, days_late)
