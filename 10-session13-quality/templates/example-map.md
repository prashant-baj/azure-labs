# Example map — US-0nn, <story>

*Who was there: <roles — no names needed>. Who answered for the client: <role>. How long: <minutes>.*

| Colour | Card |
|---|---|
| Yellow — story | As … I want … so that … · delivers FR-0nn |
| Blue — rule R1 | <the rule, quoting the spec line> |
| Green — R1 examples | <input> → <outcome> · <input> → <outcome> |
| Blue — rule R2 | |
| Green — R2 examples | |
| Red — questions | Q? <question> → who can answer · ANSWERED: "<their words>" or OPEN |

## What comes out

| Card | Goes to | As |
|---|---|---|
| R1 + examples | `spec.md` §5 | RULE-0nn rows a–… |
| Answered question | `spec.md` §10, §11 | Closed; clarification with date and who |
| Open question | `spec.md` §10 | New row, who can answer — **no code guesses it** |
| Examples | `features/*.feature` | Scenario Outline rows, word for word |

Reading it: many red cards — not ready. Many blue cards — split the story. A rule with no green card — untestable.
