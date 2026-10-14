"""The port: what the feature needs from 'a model', and nothing about which one (E-004)."""

from typing import Protocol


class CategorySuggester(Protocol):
    def suggest(self, message: str, categories: tuple[str, ...]) -> str:
        """Return the model's raw reply text. Raise SuggesterUnavailable if it cannot answer."""
        ...


class SuggesterUnavailable(Exception):
    """Timeout, network, quota, refusal - all mean 'no suggestion right now' (If row 1)."""
