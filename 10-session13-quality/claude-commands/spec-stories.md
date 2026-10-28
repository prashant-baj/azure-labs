---
description: Turn an example map into spec changes, user stories and acceptance criteria - shows every diff, applies only on a yes.
argument-hint: "[slice folder]"
---
Arguments: $ARGUMENTS — the slice folder. Read its `spec.md`, `example-map.md` (if there is one), `stories.md`
(if there is one), `constitution.md` and the glossary.

The spec changes first. Work in this order and **stop for a yes after each step**:

1. **Spec rule rows.** For each blue card with green examples whose outcomes are known: propose new or changed
   rows in `spec.md` §5 (or a requirement in §4), quoting the source — the map, a clarification, `docs/`.
   Answered questions → close them in §10 and record them in §11 with the date and who answered.
   New red cards → new rows in §10 with who can answer. Show the diff. Apply only on a yes.
2. **Stories.** In `specs/<slice>/stories.md` (from `templates/stories.md`), one story per user-visible outcome:
   `US-0nn`, *As / I want / so that*, **Delivers:** the FR and RULE IDs. A real role from the spec, never "user".
   The *so that* is the client's reason, not the *I want* again.
3. **Acceptance criteria.** For each story, a table of AC in Given / When / Then, each a check a person could do
   by hand, each naming what it **proves** (FR or rule row). Every rule row is proved by at least one AC.
   No UI words (click, page, button) unless the requirement is about the UI.

Rules: never invent an outcome, a number or a client decision — write `[NEEDS CLARIFICATION]` and add the
question to §10. Do not write `.feature` files or code — that is `/spec-scenarios`.

End with a list: each FR and RULE row of the slice → the story and AC that cover it, and the ones that have
none yet.
