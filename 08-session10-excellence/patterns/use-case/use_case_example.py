# USE CASE - "the treasurer records a cash payment". One class per thing a person does.
# It checks the input, asks the rule, saves, and returns a plain result. No HTTP, no SQL here.
from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class Payment:
    flat: str
    amount: float
    reference: str
    recorded_by: str


@dataclass(frozen=True)
class Result:
    ok: bool
    message: str


class Payments(Protocol):
    def add(self, payment: Payment) -> None: ...
    def exists(self, reference: str) -> bool: ...


class Flats(Protocol):
    def exists(self, flat: str) -> bool: ...


class RecordCashPayment:
    """FR-006: the treasurer records a cash payment against a flat, once per receipt number."""

    def __init__(self, payments: Payments, flats: Flats):
        self._payments, self._flats = payments, flats

    def run(self, flat: str, amount: float, receipt_no: str, treasurer: str) -> Result:
        if amount <= 0:
            return Result(False, "Amount must be more than zero")
        if not self._flats.exists(flat):
            return Result(False, f"No flat {flat} in this society")
        if self._payments.exists(receipt_no):
            return Result(False, f"Receipt {receipt_no} is already recorded")
        self._payments.add(Payment(flat, amount, receipt_no, recorded_by=treasurer))
        return Result(True, f"Recorded Rs {amount:.0f} for {flat}")


# A web route, a CLI command and a test all call the same .run() - see test_use_case.py.
