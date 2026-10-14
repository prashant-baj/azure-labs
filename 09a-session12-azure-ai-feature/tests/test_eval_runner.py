import json

from eval.run_eval import EVAL_SET, evaluate
from triage.adapters.fake import FakeSuggester


def test_eval_set_has_clear_unclear_and_guardrail_examples_all_sourced():
    examples = json.loads(EVAL_SET.read_text(encoding="utf-8"))["examples"]
    assert len(examples) >= 6 and all(e.get("source") for e in examples)
    assert any(e.get("guardrail") for e in examples) and any(e.get("unclear") for e in examples)


def test_runner_works_with_the_fake():
    results = evaluate(FakeSuggester(), [{"id": "X", "message": "leak", "expected": "maintenance_request"}])
    assert results[0]["agreed"]
