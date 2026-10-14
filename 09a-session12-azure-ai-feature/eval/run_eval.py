"""Run the eval set against the real model - only when one is configured.

    MODEL_BASE_URL=... MODEL_NAME=... MODEL_API_KEY=... python -m eval.run_eval

The eval set is to the AI feature what rule examples are to a rule: given this, expect that.
A broken guardrail stops the run with a non-zero exit code - put it in your pipeline.
"""

import json
import os
import sys
from pathlib import Path

from triage.service import TriageService

EVAL_SET = Path(__file__).parent / "eval_set.json"


def evaluate(suggester, examples: list[dict]) -> list[dict]:
    service, results = TriageService(suggester), []
    for ex in examples:
        r = service.triage(ex["message"])
        got = r.suggestion.category if r.suggestion else None
        results.append({**ex, "got": got, "status": r.status, "agreed": got == ex["expected"]})
    return results


def main() -> int:
    if not all(os.environ.get(k) for k in ("MODEL_BASE_URL", "MODEL_NAME", "MODEL_API_KEY")):
        print("Skipped - set MODEL_BASE_URL, MODEL_NAME and MODEL_API_KEY to run the eval set against a model.")
        return 0
    from triage.adapters.openai_compatible import OpenAICompatibleSuggester

    results = evaluate(OpenAICompatibleSuggester(), json.loads(EVAL_SET.read_text(encoding="utf-8"))["examples"])
    for r in results:
        flag = "agreed " if r["agreed"] else "DIFFERS"
        print(f"{r['id']}  {flag}  expected={r['expected']}  got={r['got']}  ({r['status']})")
    agreed = sum(r["agreed"] for r in results)
    print(f"\nAgreed on {agreed} of {len(results)}. Whether that is good enough is the client's call, not ours.")
    broken = [r["id"] for r in results if r.get("guardrail") and r["got"] not in (r["expected"], None)]
    if broken:
        print("Guardrail broken: " + ", ".join(broken))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
