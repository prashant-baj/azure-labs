---
description: Write executable Gherkin scenarios from the acceptance criteria, tagged with IDs - then run them red.
argument-hint: "[slice folder] [story ID, e.g. US-002]"
---
Arguments: $ARGUMENTS — the slice folder and one story ID. Read `stories.md`, `spec.md`, the glossary and
the stack ADR (to know the BDD runner: `stacks/<stack>/README.md` in the lab says how it is wired).

Write `specs/<slice>/features/<story-name>.feature`:

- `Feature:` = the story's outcome in business words; the story's *so that* as its description.
- Tag the feature `@US-0nn`. Tag **every scenario** with the IDs it proves: `@FR-0nn`, `@RULE-0nnx` (or
  `@RULE-0nn` for an outline covering several rows), `@NFR-0nn`. Only IDs that exist in `spec.md`.
- One scenario per acceptance criterion. A rule with example rows → **one `Scenario Outline`** whose
  `Examples:` rows are the spec's rule rows, word for word, with an `example` column holding the row ID.
- **Declarative, not imperative**: what happens, never how — no clicks, fields, URLs, tables, SQL, JSON.
- Business words from the glossary. Given = state, When = one event, Then = an outcome someone can see.
- A `Background:` only for what every scenario needs. No scenario depends on another.

Then show the feature file and ask the group: "Would the client read this and say yes, that is what I meant?"
Apply changes they ask for.

Then run the scenarios **before** any step code exists and show the result: undefined steps, or failing.
That is the right kind of red. Print the snippets the runner suggests, and stop. Step code comes with
`/tdd-cycle` — steps stay thin: each calls the application, never contains the rule.
