"""FR-009: the treasurer matches an unmatched payment by hand - and the record says who (C-001)."""
from dues.model import Payment
from dues.ports import FlatDirectory, PaymentStore, UnmatchedList


class FlatNotInDirectory(ValueError):
    """FR-010: the flat typed is not in the society - nothing is recorded."""


class MatchByHand:
    def __init__(self, flats: FlatDirectory, payments: PaymentStore, unmatched: UnmatchedList):
        self._flats = flats
        self._payments = payments
        self._unmatched = unmatched

    def match(self, payment: Payment, flat: str, treasurer: str) -> None:
        if not self._flats.exists(flat):
            raise FlatNotInDirectory(flat)
        decided_by = f"matched by hand by {treasurer}"
        self._payments.record(payment, flat, matched_by=decided_by)
        self._unmatched.resolve(payment.bank_reference, flat, decided_by)
