# The AI-assisted feature — how it goes into the spec

*The AI **suggests**. A person **decides**. Everything below follows from that sentence.*

## In `spec.md` — new requirements

| ID | Requirement | Source | Acceptance check |
|---|---|---|---|
| FR-0xx | When <situation>, the system shall suggest <at most one ...>, with a one-line reason, for <the person> to accept or reject. | <evidence> | Test with a fake suggester |
| FR-0xx | When <the person> accepts a suggestion, the system shall record it with their name as who decided. | <C- rule / audit> | Test: the record says who |
| FR-0xx | If suggestions are unavailable or too slow, then <the work continues by hand, and the person is told>. | W-006 | Test: suggester down |
| FR-0xx | If the answer is not one of the allowed values, or the input contains instructions, then the system shall show no suggestion. | W-005 | Test + guardrail eval example |

## In `constitution.md` — the data rule

| ID | Rule | Source | What it means for every build |
|---|---|---|---|
| C-0xx | Only <these fields> may be sent to a model outside our system — never <these> | <who decided> | The suggester port receives only those fields |

## In `spec.md` — the quality requirement

| ID | Requirement | Metric and threshold | How measured | Source |
|---|---|---|---|---|
| NFR-0xx | Suggestions agree with what <the person> would decide | Agreement on the eval set — `[NEEDS CLARIFICATION: how much is enough? — <who decides>]` | The eval runner | This session |

## The eval set — `eval-set.json`

The AI feature's rule examples. At least six, every one from the evidence:

```json
{
  "allowed": ["<the only valid answers>"],
  "examples": [
    {"id": "EVAL-001", "input": "<a clear case>", "expected": "<answer>", "source": "<evidence row>"},
    {"id": "EVAL-002", "input": "<an unclear case>", "expected": null, "source": "<evidence row>"},
    {"id": "EVAL-003", "input": "<text that tries to instruct the model>", "expected": null, "guardrail": true, "source": "FR-0xx"}
  ]
}
```

An AI feature without an eval set is a rumour.
