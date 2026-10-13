"""FR-009, FR-011, FR-012, C-004: ask for a suggestion - and never trust it blindly."""
from dataclasses import dataclass

from dues.model import Payment
from dues.ports import FlatDirectory
from dues.suggestion import FlatSuggester, Suggestion, SuggesterUnavailable

NO_SUGGESTION = "no suggestion - the treasurer matches it by hand"
SUGGESTER_UNAVAILABLE = "suggestions are unavailable right now - the treasurer matches it by hand"
NOT_A_FLAT = "suggestion ignored - it is not a flat in the society"


@dataclass(frozen=True)
class SuggestionResult:
    suggestion: Suggestion | None
    note: str | None = None


class SuggestForUnmatched:
    def __init__(self, suggester: FlatSuggester, flats: FlatDirectory):
        self._suggester = suggester
        self._flats = flats

    def suggest(self, payment: Payment) -> SuggestionResult:
        # C-004: only the remark and the list of flats leave the system - no payer name, no bank reference
        try:
            suggestion = self._suggester.suggest(payment.remark, self._flats.all_flats())
        except SuggesterUnavailable:
            return SuggestionResult(None, SUGGESTER_UNAVAILABLE)          # FR-011
        if suggestion is None:
            return SuggestionResult(None, NO_SUGGESTION)
        if not self._flats.exists(suggestion.flat):
            return SuggestionResult(None, NOT_A_FLAT)                     # FR-012
        return SuggestionResult(suggestion)                               # FR-009
