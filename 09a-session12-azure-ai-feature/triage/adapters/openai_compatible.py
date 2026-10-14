"""Adapter: the only file that knows a model exists (E-004).

One adapter, two providers - both speak the OpenAI chat-completions protocol:
  * OpenRouter (the lab keys):  MODEL_BASE_URL=https://openrouter.ai/api/v1
  * Azure OpenAI (v1 API):      MODEL_BASE_URL=https://<resource>.openai.azure.com/openai/v1/
                                MODEL_NAME = your *deployment* name
Settings come from the environment (E-008). On Azure, MODEL_API_KEY is a Key Vault reference.
A Claude Code login token is for the coding tool - never for running a product.
"""

import json
import os
from pathlib import Path

from triage.ports import SuggesterUnavailable

PROMPT = (Path(__file__).resolve().parent.parent / "prompt.txt").read_text(encoding="utf-8")


class OpenAICompatibleSuggester:
    def __init__(self, client=None, model: str | None = None, timeout_seconds: float = 10.0):
        if client is None:
            from openai import OpenAI  # imported only when the real adapter is used

            client = OpenAI(
                base_url=os.environ["MODEL_BASE_URL"],
                api_key=os.environ["MODEL_API_KEY"],
                timeout=timeout_seconds,
                max_retries=1,
            )
        self._client = client
        self._model = model or os.environ["MODEL_NAME"]

    def suggest(self, message: str, categories: tuple[str, ...]) -> str:
        question = json.dumps({"categories": list(categories), "message": message})
        try:
            reply = self._client.chat.completions.create(
                model=self._model,
                max_tokens=150,
                temperature=0,
                messages=[{"role": "system", "content": PROMPT}, {"role": "user", "content": question}],
            )
            return reply.choices[0].message.content or ""
        except Exception as error:  # noqa: BLE001 - every failure means "no suggestion now" (If row 1)
            raise SuggesterUnavailable(str(error)[:200]) from error
