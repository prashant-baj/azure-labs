"""RULE-001: match a payment to a flat. Pure - no database, no framework (E-004)."""

from dues.flat_in_remark import flat_in_remark
from dues.model import Match, Payment, UnmatchedReason
from dues.ports import FlatDirectory


def match(payment: Payment, flats: FlatDirectory) -> Match:
    flat = flat_in_remark(payment.remark)
    if flat is not None:
        return Match(flat) if flats.exists(flat) else Match(None, UnmatchedReason.FLAT_NOT_FOUND)
    return _match_by_payer(payment.payer, flats)


def _match_by_payer(payer: str, flats: FlatDirectory) -> Match:
    paid_for = flats.flats_paid_by(payer)
    if len(paid_for) == 1:
        return Match(paid_for[0])  # RULE-001d
    if paid_for:
        return Match(None, UnmatchedReason.PAYER_HAS_MANY_FLATS)  # RULE-001e
    return Match(None, UnmatchedReason.NO_FLAT_IN_REMARK)
