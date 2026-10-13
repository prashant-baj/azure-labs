"""FR-010: a person accepts a suggestion - and the record says who."""
from dues.model import Payment
from dues.ports import PaymentStore, UnmatchedList
from dues.suggestion import Suggestion


class AcceptSuggestion:
    def __init__(self, payments: PaymentStore, unmatched: UnmatchedList):
        self._payments = payments
        self._unmatched = unmatched

    def accept(self, payment: Payment, suggestion: Suggestion, treasurer: str) -> None:
        decided_by = f"suggestion accepted by {treasurer}"
        self._payments.record(payment, suggestion.flat, matched_by=decided_by)
        self._unmatched.resolve(payment.bank_reference, suggestion.flat, decided_by)
