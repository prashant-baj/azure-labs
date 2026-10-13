"""Adapter: asks a model for a suggestion. The only file that knows a model exists (E-004).

Needs an API key in ANTHROPIC_API_KEY and a model name in SUGGESTER_MODEL - both from the
environment (E-008). A Claude Code login token is for the coding tool, not for running a product.
"""
import json
import os
from pathlib import Path

from dues.suggestion import Suggestion, SuggesterUnavailable

PROMPT = (Path(__file__).parent / "prompts" / "suggest_flat.txt").read_text(encoding="utf-8")


class ClaudeSuggester:
    def __init__(self, client=None, model: str | None = None, timeout_seconds: float = 10.0):
        if client is None:
            import anthropic  # imported only when the real adapter is used

            client = anthropic.Anthropic(timeout=timeout_seconds)
        self._client = client
        self._model = model or os.environ["SUGGESTER_MODEL"]

    def suggest(self, remark: str, flats: list[str]) -> Suggestion | None:
        question = json.dumps({"remark": remark, "flats": flats})
        try:
            reply = self._client.messages.create(
                model=self._model,
                max_tokens=200,
                system=PROMPT,
                messages=[{"role": "user", "content": question}],
            )
        except Exception as error:  # timeout, network, refusal: all mean "no suggestion now" (FR-011)
            raise SuggesterUnavailable(str(error)) from error
        return parse_reply(reply.content[0].text)


def parse_reply(text: str) -> Suggestion | None:
    """Anything that is not the agreed shape counts as 'no suggestion' - never a guess."""
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        return None
    if not isinstance(data, dict) or not data.get("flat"):
        return None
    return Suggestion(flat=str(data["flat"]), reason=str(data.get("reason", ""))[:200])
