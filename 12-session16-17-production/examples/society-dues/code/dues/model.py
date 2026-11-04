"""The words of the spec, as types. Names come from the glossary (E-001)."""

from dataclasses import dataclass
from enum import Enum


@dataclass(frozen=True)
class Payment:
    bank_reference: str  # unique per payment - ADR 0002
    remark: str
    payer: str
    amount: float
    source: str  # "upi" or "statement"


class UnmatchedReason(str, Enum):
    FLAT_NOT_FOUND = "flat in remark does not exist"
    PAYER_HAS_MANY_FLATS = "payer pays for more than one flat"
    NO_FLAT_IN_REMARK = "no flat in remark"


@dataclass(frozen=True)
class Match:
    flat: str | None
    reason: UnmatchedReason | None = None

    @property
    def matched(self) -> bool:
        return self.flat is not None
