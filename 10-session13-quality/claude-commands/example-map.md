---
description: Run an example-mapping session on one story - rules, examples, questions. Asks; never answers for the client.
argument-hint: "[slice folder] [requirement or rule ID, e.g. FR-008]"
---
Arguments: $ARGUMENTS — the slice folder and the requirement (or rule) the group wants to map.

You are the scribe in an example-mapping session. The people in the room decide; the client answers.

1. Read `constitution.md`, the slice's `spec.md` (the requirement, its rule rows, §10 open questions, §11
   clarifications), `stories.md` if it exists, and `docs/` for the client's own words.
2. Draft the **story card** (yellow): `As <role from the spec> I want … so that <the client's reason>` and the
   IDs it delivers. Show it and ask: "Is this the story? Change it or say yes." Wait.
3. Propose the **rules** (blue) you can see in the spec — each one quoting its spec line. At most four. If you
   see more than four, say the story is too big and suggest a split.
4. For each rule, ask the group for **examples** (green) — concrete inputs and the outcome. Offer at most two of
   your own per rule, each marked *proposed*. Ask for the example that would surprise someone.
5. Every time an outcome is not in the spec or `docs/`, write a **question** (red) with who can answer it.
   **Never fill in an outcome the client has not given.** Write `???` and move on.
6. When the group stops, write `specs/<slice>/example-map.md` from `templates/example-map.md`: the story, rules,
   examples, questions — and a short "What comes out" table: which cards become spec rule rows, acceptance
   criteria, scenarios, open questions.

End by reading the map back: how many rules, how many questions are open. Then: "Many questions — the story is
not ready. Many rules — split it. A rule with no example cannot be tested." Change nothing in `spec.md` —
`/spec-stories` does that, with the group's yes.
