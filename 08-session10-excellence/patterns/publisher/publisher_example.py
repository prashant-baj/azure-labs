# PUBLISHER - "three systems want to know when a payment is matched": the receipt mailer, the
# ledger and the dashboard. The matcher announces one event. It does not know who is listening.
from dataclasses import dataclass
from typing import Callable


@dataclass(frozen=True)
class PaymentMatched:  # the event - past tense, glossary words
    flat: str
    amount: float
    reference: str


Listener = Callable[[PaymentMatched], None]


class EventPublisher:
    def __init__(self, log=print):
        self._listeners: list[Listener] = []
        self._log = log

    def subscribe(self, listener: Listener) -> None:
        self._listeners.append(listener)

    def publish(self, event: PaymentMatched) -> None:
        for listener in self._listeners:
            try:
                listener(event)
            # One failing listener must not stop the others - and it is never silent (E-006).
            except Exception as error:  # noqa: BLE001
                name = getattr(listener, "__name__", repr(listener))
                self._log(f"listener {name} failed: {error}")


class Matcher:
    def __init__(self, publisher: EventPublisher):
        self._publisher = publisher

    def match(self, flat, amount, reference):
        # ... the matching rule would sit here ...
        self._publisher.publish(PaymentMatched(flat, amount, reference))
