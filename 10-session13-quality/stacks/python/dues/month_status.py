"""RULE-002: has a flat paid this month? Pure - amounts in, an answer out (E-004).

Built test-first - one example per test, each seen red first.
"""

from collections.abc import Iterable
from dataclasses import dataclass
from decimal import Decimal


@dataclass(frozen=True)
class MonthStatus:
    dues: Decimal
    paid_so_far: Decimal

    @property
    def balance(self) -> Decimal:
        return self.dues - self.paid_so_far

    @property
    def paid(self) -> bool:
        return self.balance <= 0  # RULE-002a, 002b: one payment or several, as long as they cover it


def month_status(dues: Decimal, payments: Iterable[Decimal]) -> MonthStatus:
    return MonthStatus(dues=dues, paid_so_far=sum(payments, Decimal(0)))
