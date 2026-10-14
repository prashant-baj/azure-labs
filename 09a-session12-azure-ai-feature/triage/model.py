"""The words of the feature. Nothing here knows a model exists."""

from dataclasses import dataclass

# The only answers the feature may ever give (FR-102). Anything else is thrown away.
CATEGORIES = (
    "maintenance_request",
    "dues_and_payments",
    "noise_or_neighbour",
    "security_and_access",
    "amenities_booking",
    "other",
)

MAX_MESSAGE_CHARS = 2000  # longer messages are not sent to the model (If row 3)
MAX_REASON_CHARS = 200


@dataclass(frozen=True)
class Suggestion:
    category: str
    reason: str


@dataclass(frozen=True)
class TriageResult:
    status: str  # "suggested" | "no_suggestion" | "unavailable" | "rejected_input"
    suggestion: Suggestion | None
    note: str = ""

    def to_dict(self) -> dict:
        return {
            "status": self.status,
            "suggestion": None if self.suggestion is None else vars(self.suggestion),
            "note": self.note,
            "decided_by": None,  # always empty here: only a person fills it (FR-104)
        }
