"""FR-101 to FR-105: suggest a category for a resident's message. Never trust the answer."""

import json
import re

from triage.model import CATEGORIES, MAX_MESSAGE_CHARS, MAX_REASON_CHARS, Suggestion, TriageResult
from triage.ports import CategorySuggester, SuggesterUnavailable

# Data rule (DR-01): phone numbers and e-mail addresses never leave the system.
_EMAIL = re.compile(r"[\w.+-]+@[\w-]+\.[\w.-]+")
_PHONE = re.compile(r"(?<!\w)\+?\d[\d\s-]{8,}\d(?!\w)")


def mask_personal_data(text: str) -> str:
    return _PHONE.sub("[phone]", _EMAIL.sub("[email]", text))


def parse_reply(text: str) -> Suggestion | None:
    """Anything that is not exactly the agreed shape counts as 'no suggestion' - never a guess."""
    try:
        data = json.loads(text.strip().removeprefix("```json").removeprefix("```").removesuffix("```"))
    except (json.JSONDecodeError, AttributeError):
        return None
    if not isinstance(data, dict):
        return None
    category = data.get("category")
    if category not in CATEGORIES:  # outside the allowed list -> thrown away (FR-102)
        return None
    return Suggestion(category=category, reason=str(data.get("reason", ""))[:MAX_REASON_CHARS])


class TriageService:
    def __init__(self, suggester: CategorySuggester):
        self._suggester = suggester

    def triage(self, message: str) -> TriageResult:
        message = (message or "").strip()
        if not message:
            return TriageResult("rejected_input", None, "empty message")
        if len(message) > MAX_MESSAGE_CHARS:
            return TriageResult("rejected_input", None, f"longer than {MAX_MESSAGE_CHARS} characters")
        try:
            reply = self._suggester.suggest(mask_personal_data(message), CATEGORIES)
        except SuggesterUnavailable as error:
            return TriageResult("unavailable", None, f"no suggestion right now ({type(error).__name__})")
        suggestion = parse_reply(reply)
        if suggestion is None:
            return TriageResult("no_suggestion", None, "the reply was not an allowed category")
        return TriageResult("suggested", suggestion)
