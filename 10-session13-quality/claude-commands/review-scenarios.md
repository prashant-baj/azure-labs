---
description: Review feature files and step code for the usual BDD smells and ID gaps. Finds; never fixes.
argument-hint: "[slice folder]"
---
Arguments: $ARGUMENTS — the slice folder. Read `spec.md`, `stories.md`, every `.feature` under
`specs/<slice>/features/`, and the step definitions.

Report findings in a table: `severity (must / should) · file:line · smell · why it matters · suggested fix`.
Look for:

- **IDs:** a scenario with no `@FR-`/`@RULE-`/`@NFR-` tag; a tag whose ID is not in `spec.md`; a rule row with
  no scenario; an AC with no scenario.
- **Imperative steps:** clicks, fields, pages, URLs, JSON, SQL, HTTP codes in a business scenario.
- **Several behaviours in one scenario:** more than one When, or Thens about unrelated outcomes.
- **Invented outcomes:** an Examples row or Then that is not in the spec, the map or `docs/` — the client never
  said it. Always **must**.
- **Hidden coupling:** a scenario that only passes after another one ran; shared state between scenarios.
- **Logic in steps:** a step that calculates the answer itself instead of calling the application — then the
  scenario tests the step, not the system. Always **must**.
- **Cannot fail:** a Then that asserts nothing, or asserts what the Given just set.
- **Vague words:** "correctly", "properly", "valid", "quickly" with no example.

End with a count per severity and the three findings to fix first. Change nothing. The group decides each
finding — fix, debt (in `specs/design/tech-debt.md`) or overruled with a reason.
