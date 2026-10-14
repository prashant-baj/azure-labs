"""Azure Functions entry point (Python v2 programming model). Thin: read the request, call the
service, return JSON. No rule and no model call lives here.

  POST /api/triage    {"message": "..."}                       -> a suggestion, or none
  POST /api/decision  {"message_id": "...", "category": "...",  -> records what a PERSON decided
                       "accepted": true, "decided_by": "..."}
"""

import json
import logging
import os

import azure.functions as func

from triage.model import CATEGORIES
from triage.service import TriageService

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)
log = logging.getLogger("triage")


def _suggester():
    """Composition root: the real adapter only when configured; otherwise the fake (If row 1)."""
    if (
        os.environ.get("MODEL_BASE_URL")
        and os.environ.get("MODEL_API_KEY", "").strip()
        and not os.environ["MODEL_API_KEY"].startswith("@Microsoft.KeyVault")
    ):
        from triage.adapters.openai_compatible import OpenAICompatibleSuggester

        return OpenAICompatibleSuggester()
    from triage.adapters.fake import FakeSuggester

    log.warning("No model configured (or the Key Vault reference did not resolve) - using the fake.")
    return FakeSuggester()


def _json(body: dict, status: int = 200) -> func.HttpResponse:
    return func.HttpResponse(json.dumps(body), status_code=status, mimetype="application/json")


def _body(req: func.HttpRequest) -> dict | None:
    try:
        data = req.get_json()
    except ValueError:
        return None
    return data if isinstance(data, dict) else None


@app.route(route="triage", methods=["POST"])
def triage(req: func.HttpRequest) -> func.HttpResponse:
    data = _body(req)
    if data is None:
        return _json({"error": 'send JSON: {"message": "..."}'}, 400)
    suggester = _suggester()
    result = TriageService(suggester).triage(str(data.get("message", "")))
    # Log the outcome, never the message itself (DR-01).
    log.info("triage status=%s category=%s", result.status, result.suggestion.category if result.suggestion else None)
    body = result.to_dict()
    body["suggested_by"] = "fake" if type(suggester).__name__ == "FakeSuggester" else "model"
    return _json(body, 400 if result.status == "rejected_input" else 200)


@app.route(route="decision", methods=["POST"])
def decision(req: func.HttpRequest) -> func.HttpResponse:
    data = _body(req) or {}
    who = str(data.get("decided_by", "")).strip()
    category = data.get("category")
    if not who or category not in CATEGORIES or not isinstance(data.get("accepted"), bool):
        return _json({"error": "need message_id, category (allowed list), accepted (true/false), decided_by"}, 400)
    # The record says who decided (FR-104). Here it goes to the log / Application Insights;
    # in your case it goes to your store.
    log.info(
        "decision message_id=%s category=%s accepted=%s decided_by=%s",
        data.get("message_id"),
        category,
        data["accepted"],
        who,
    )
    return _json({"recorded": True, "decided_by": who})
