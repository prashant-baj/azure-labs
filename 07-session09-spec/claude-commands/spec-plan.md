---
description: Draft plan.md — how the slice will be built — without choosing the stack
argument-hint: "[slice folder, e.g. specs/001-first-slice]"
---
Slice folder: $ARGUMENTS (if empty, use the only `specs/NNN-*` folder).

Read `constitution.md`, `<slice>/spec.md`, everything in `specs/design/`, and `templates/plan.md`.
Fill `<slice>/plan.md`, following the template exactly.

Rules:
- Section 2 first. Check the plan against every rule in the constitution. A rule broken without a
  reason and a name is a failed plan — say so plainly.
- Every FR, RULE and NFR in the spec must appear in section 3 or section 6. List any that do not.
- Section 5: link the existing contract file for each interface. If no contract exists, write
  `[NEEDS CLARIFICATION: no contract for <interface>]`. Do not write a new contract here.
- Use the shapes the group chose in `specs/design/integration-decisions.md`. Do not change them.
- **Section 8: do not choose a stack.** The stack has not been decided. List what any stack must
  give this slice, and the requirement ID that needs it.
- Mark everything you inferred rather than took from our files with *(inferred)*.
- Keep it to what this slice needs. If a piece serves no requirement ID, leave it out.
- **Section 11: draw the two diagrams in Mermaid**, from section 3 and
  `specs/design/integration-decisions.md` — an area map (`flowchart`) of this slice and everything
  it talks to, and a `sequenceDiagram` of the main path with an `alt` branch for at least one
  failure from the spec's *If* rows. Only pieces that appear in section 3. Label every line with
  its requirement ID. Use the shapes the group chose (call / message / file).

When you finish, print:
- any requirement ID with no home in the plan
- any constitution rule the plan breaks
- every line marked *(inferred)*
