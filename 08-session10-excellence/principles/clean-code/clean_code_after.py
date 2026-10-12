# AFTER - the same answers for every valid input. Now it reads like the committee's rule.
# (Invented example: a housing society's late fee on monthly maintenance.)
from enum import Enum

GRACE_DAYS = 15  # committee resolution: no fee in the first fifteen days
MONTHLY_LATE_RATE = 0.02  # residential flats pay a share of the dues per late month
COMMERCIAL_LATE_FEE = 500  # shops pay a flat amount, however late
DAYS_PER_LATE_MONTH = 30


class UnitType(Enum):
    RESIDENTIAL = 1
    COMMERCIAL = 2


def amount_due(dues: float, days_late: int, unit: UnitType) -> float:
    """Dues plus the late fee the committee's rule asks for."""
    if days_late < 0 or dues < 0:
        raise ValueError(f"days_late and dues cannot be negative: {days_late}, {dues}")
    return dues + late_fee(dues, days_late, unit)


def late_fee(dues: float, days_late: int, unit: UnitType) -> float:
    if days_late <= GRACE_DAYS:
        return 0.0
    if unit is UnitType.COMMERCIAL:
        return COMMERCIAL_LATE_FEE
    # The first late day already counts as a whole late month - that is how the treasurer bills it.
    late_months = (days_late - GRACE_DAYS) // DAYS_PER_LATE_MONTH + 1
    return dues * MONTHLY_LATE_RATE * late_months
