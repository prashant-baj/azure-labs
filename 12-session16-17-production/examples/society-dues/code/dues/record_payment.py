"""The use case: record one payment, once (FR-003, FR-004, FR-006)."""

from dues.matcher import match
from dues.model import Match, Payment
from dues.ports import FlatDirectory, PaymentStore, UnmatchedList


class PaymentRecorder:
    def __init__(self, flats: FlatDirectory, payments: PaymentStore, unmatched: UnmatchedList):
        self._flats = flats
        self._payments = payments
        self._unmatched = unmatched

    def record(self, payment: Payment) -> Match | None:
        """Returns the match, or None when this bank reference was already recorded (FR-004)."""
        if self._already_seen(payment.bank_reference):
            return None
        result = match(payment, self._flats)
        if result.matched:
            self._payments.record(payment, result.flat)
        else:
            self._unmatched.add(payment, result.reason)  # W-006: never dropped
        return result

    def _already_seen(self, bank_reference: str) -> bool:
        return self._payments.has(bank_reference) or self._unmatched.has(bank_reference)
