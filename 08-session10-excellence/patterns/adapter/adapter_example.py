# ADAPTER - two partners send payments in two shapes. The rule wants ONE shape: Payment.
# Each adapter knows one partner's format. The rule never sees UPI JSON or bank CSV.
import csv
import io
import json
from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class Payment:  # our shape - glossary words
    flat: str
    amount: float
    reference: str


class PaymentSource(Protocol):  # the port the rule depends on
    def payments(self) -> list[Payment]: ...


class UpiJsonAdapter:  # partner 1: {"txn": [{"vpa_note": ..., "amt_paise": ...}]}
    def __init__(self, raw_json: str):
        self._raw = raw_json

    def payments(self):
        return [
            Payment(flat=t["vpa_note"].strip().upper(), amount=t["amt_paise"] / 100, reference=t["utr"])
            for t in json.loads(self._raw)["txn"]
        ]


class BankCsvAdapter:  # partner 2: Narration,Credit,Ref No
    def __init__(self, raw_csv: str):
        self._raw = raw_csv

    def payments(self):
        rows = csv.DictReader(io.StringIO(self._raw))
        return [
            Payment(
                flat=r["Narration"].split("/")[-1].strip().upper(),
                amount=float(r["Credit"].replace(",", "")),
                reference=r["Ref No"],
            )
            for r in rows
        ]


def total_received(source: PaymentSource) -> float:  # the rule: knows only Payment
    return sum(p.amount for p in source.payments())
