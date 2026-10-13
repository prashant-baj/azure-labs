"""Run the eval set against the real suggester - only when a key and a model are configured.

    ANTHROPIC_API_KEY=... SUGGESTER_MODEL=... python -m eval.run_eval

The eval set is to the AI feature what the rule examples are to RULE-001: given this, expect that.
A guardrail example that fails stops the run with a non-zero exit code.
"""
import json
import os
import sys
from pathlib import Path

from dues.model import Payment
from dues.suggest_for_unmatched import SuggestForUnmatched

EVAL_SET = Path(__file__).parent / "eval_set.json"


class ListedFlats:
    def __init__(self, flats):
        self._flats = list(flats)

    def exists(self, flat):
        return flat in self._flats

    def flats_paid_by(self, payer):
        return []

    def all_flats(self):
        return list(self._flats)


def evaluate(suggester, eval_set: dict) -> list[dict]:
    use_case = SuggestForUnmatched(suggester, ListedFlats(eval_set["allowed"]))
    results = []
    for example in eval_set["examples"]:
        payment = Payment(example["id"], example["input"], "-", 0.0, "eval")
        got = use_case.suggest(payment).suggestion
        flat = got.flat if got else None
        results.append({**example, "got": flat, "agreed": flat == example["expected"]})
    return results


def main() -> int:
    if not (os.environ.get("ANTHROPIC_API_KEY") and os.environ.get("SUGGESTER_MODEL")):
        print("Skipped - set ANTHROPIC_API_KEY and SUGGESTER_MODEL to run the eval set against the model.")
        return 0
    from dues.claude_suggester import ClaudeSuggester

    results = evaluate(ClaudeSuggester(), json.loads(EVAL_SET.read_text(encoding="utf-8")))
    for r in results:
        print(f"{r['id']}  {'agreed ' if r['agreed'] else 'DIFFERS'}  expected={r['expected']}  got={r['got']}")
    agreed = sum(r["agreed"] for r in results)
    print(f"\nAgreed on {agreed} of {len(results)}. Whether that is good enough is the treasurer's decision (NFR-003).")
    broken = [r["id"] for r in results if r.get("guardrail") and not r["agreed"]]
    if broken:
        print("Guardrail broken: " + ", ".join(broken))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
