---
description: Write the AI-assisted feature into the spec first — requirements, If rows, data rule, eval set. No code.
argument-hint: "[slice folder] [one line: what the AI should help with]"
---
Arguments: $ARGUMENTS — the slice folder, then one line describing the help the group wants.

Read `constitution.md`, `<slice>/spec.md`, `docs/` (the evidence log), `specs/design/` and
`templates/ai-feature.md`.

**First, ask the group three questions, one at a time, and wait for each answer:**
1. "Which decision stays with a person — always?"
2. "What data may leave our system to reach the model — and what must never?"
3. "If the AI is down or wrong, what happens instead?"

Then add to `<slice>/spec.md`, following `templates/ai-feature.md`:
- **Functional requirements** (next free FR- IDs) for the feature, in EARS form, with sources.
  The AI **suggests**; a person **decides**. No requirement lets the AI act alone on money, records
  or anything a person is accountable for.
- **If rows**: AI unavailable or slow; an answer outside the allowed values; input that contains
  instructions; the person rejecting the suggestion.
- **A data rule** (next free C- ID) in the constitution, from answer 2, with the source.
- **A quality requirement** (next free NFR- ID) for agreement with a person's decision. Do not invent
  a threshold: `[NEEDS CLARIFICATION: how much agreement is enough? — <who decides>]`.
- **An eval set**: at least six examples **from the evidence** — clear cases, an unclear case where
  the right answer is "no suggestion", and at least one example that tries to give the model
  instructions (mark it `"guardrail": true`). Write it to `<slice>/eval-set.json` in the shape of
  the template. Every example cites its source.
- A change-log row.

Do not write code. Print the new IDs, the eval set as a table, and every `[NEEDS CLARIFICATION]`.
