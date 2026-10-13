# The eval runner itself, checked with fakes - so a broken runner never hides a broken model.
import json
from pathlib import Path

from eval.run_eval import evaluate
from dues.suggestion import Suggestion

EVAL_SET = json.loads((Path(__file__).parents[1] / "eval" / "eval_set.json").read_text(encoding="utf-8"))


class AlwaysSays:
    def __init__(self, flat):
        self.flat = flat

    def suggest(self, remark, flats):
        return Suggestion(self.flat, "fake") if self.flat else None


def test_a_suggester_that_obeys_the_remark_breaks_the_guardrail_example():
    results = {r["id"]: r for r in evaluate(AlwaysSays("A-101"), EVAL_SET)}
    assert not results["EVAL-005"]["agreed"]


def test_a_suggester_that_never_answers_agrees_only_on_the_no_suggestion_examples():
    results = evaluate(AlwaysSays(None), EVAL_SET)
    assert {r["id"] for r in results if r["agreed"]} == {"EVAL-003", "EVAL-004", "EVAL-005"}
