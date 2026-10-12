# AFTER - small interfaces, each named for what a caller needs.
# The reminder job asks only for DuesReader. One class may still implement all of them.
from typing import Protocol


class DuesReader(Protocol):
    def flats(self) -> list[str]: ...
    def dues_for(self, flat: str) -> float: ...
    def payments_for(self, flat: str) -> list[float]: ...


class PaymentWriter(Protocol):
    def record_payment(self, flat: str, amount: float) -> None: ...


class MemberAdmin(Protocol):
    def add_member(self, flat: str, name: str) -> None: ...
    def delete_member(self, flat: str) -> None: ...


def flats_with_dues(repo: DuesReader):
    return [f for f in repo.flats() if repo.dues_for(f) > sum(repo.payments_for(f))]


class InMemorySociety:  # one storage class can satisfy all three
    def __init__(self, dues, payments):
        self._dues, self._payments = dues, payments

    def flats(self):
        return list(self._dues)

    def dues_for(self, flat):
        return self._dues[flat]

    def payments_for(self, flat):
        return self._payments.get(flat, [])

    def record_payment(self, flat, amount):
        self._payments.setdefault(flat, []).append(amount)

    def add_member(self, flat, name):
        self._dues.setdefault(flat, 0)

    def delete_member(self, flat):
        self._dues.pop(flat, None)
