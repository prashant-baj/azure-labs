"""FR-009 to FR-012: suggest a flat for an unmatched payment. A person always decides."""
from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class Suggestion:
    flat: str
    reason: str


class FlatSuggester(Protocol):
    """Port for anything that can suggest a flat: a model, a simple rule, or a fake in tests (E-004)."""

    def suggest(self, remark: str, flats: list[str]) -> Suggestion | None: ...


class SuggesterUnavailable(Exception):
    """An adapter raises this when it cannot answer - network down, too slow, refused (FR-011)."""
