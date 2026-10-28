"""FR-008: the reminder list - every flat that has not paid this month, with what is left to pay."""

from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from decimal import Decimal

from dues.month_status import month_status


@dataclass(frozen=True)
class Reminder:
    flat: str
    balance: Decimal


def reminder_list(dues: Mapping[str, Decimal], paid: Mapping[str, Sequence[Decimal]]) -> list[Reminder]:
    """dues: flat -> this month's dues. paid: flat -> matched payments this month (RULE-001 already applied)."""
    statuses = {flat: month_status(amount, paid.get(flat, ())) for flat, amount in dues.items()}
    return [Reminder(flat, s.balance) for flat, s in sorted(statuses.items()) if not s.paid]
