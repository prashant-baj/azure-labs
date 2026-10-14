# Example spec additions — AI-assisted message triage

*Invented example (a housing-society office). It shows the **shape** your Session 12 spec change
should have. Write yours from your own case and your own evidence — do not copy these lines.*

## Requirements

| ID | Requirement | Source |
|---|---|---|
| FR-101 | When a resident sends a message, the system **suggests** one category and a one-sentence reason | Office log — staff re-sort every message by hand |
| FR-102 | The suggestion is always one of the six agreed categories, or none | Office manager — "anything else just confuses us" |
| FR-103 | A suggestion never changes a record by itself | Constitution — the AI suggests; a person decides |
| FR-104 | When staff accept or reject a suggestion, the record says **who** decided | Audit — "proof that somebody looked" |
| FR-105 | If no suggestion can be made, staff sort the message as they do today | Office manager — "never block the counter" |

## *If* rows — what happens when it goes wrong

| # | If… | Then… | Test |
|---|---|---|---|
| 1 | the model is down, slow (over 10 s) or refuses | status `unavailable`, no suggestion, no crash | `test_model_down_means_no_suggestion_not_a_crash` |
| 2 | the reply is not JSON, or the category is not on the list | status `no_suggestion`; the reply is thrown away | `test_answer_outside_the_list_is_thrown_away` |
| 3 | the message is empty or over 2,000 characters | rejected before any model sees it | `test_too_long_or_empty_never_reaches_the_model` |
| 4 | the message contains instructions ("ignore your rules…") | treated as data; eval examples EVAL-08, EVAL-09 | `eval/run_eval.py` (guardrail) |

## Data rule

| ID | Rule | Checked by |
|---|---|---|
| DR-01 | Phone numbers and e-mail addresses are masked before anything leaves the system; logs never contain the message text | `test_phone_and_email_never_leave_the_system`; review of `function_app.py` |

## Decision (ADR, short form)

**Context.** We need a model behind FR-101. The lab subscription's policy does **not** allow Azure
OpenAI. **Decision.** The feature talks to a port (`CategorySuggester`); one adapter speaks the
OpenAI chat-completions protocol, so it works with OpenRouter (lab keys) today and Azure OpenAI's v1
endpoint later by configuration only. It runs on Azure Functions, with the key in Key Vault.
**Consequences.** Swapping provider is a settings change. Every guardrail is tested with a fake.
The eval set — not a demo — decides whether a model is good enough.
