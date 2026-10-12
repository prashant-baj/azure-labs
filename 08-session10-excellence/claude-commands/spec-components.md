---
description: Draw the components inside the slice — plan.md section 12 — one job each, the rule in the middle
argument-hint: "[slice folder, e.g. specs/001-first-slice]"
---
Slice folder: $ARGUMENTS (if empty, use the only `specs/NNN-*` folder).

Read `constitution.md` (especially section 5), `<slice>/spec.md`, `<slice>/plan.md`, the accepted
architecture-and-stack ADR, and `templates/plan-section-12.md`.

Add **section 12, Components — inside the code**, to `<slice>/plan.md`, following the template.
If section 12 already exists, update it — do not add a second one.

Rules:
- Start from the pieces in plan section 3. Cut each into components that each have **one job**,
  written without the word "and". If you need "and", split it.
- **The direction rule:** the rule (every RULE- and the FRs that decide something) depends only on
  the model and on ports (interfaces). Storage, inputs, notifications, frameworks and other systems
  are adapters on the outside.
- Every component lists the requirement IDs it serves. A component that serves none is left out.
- Name a pattern only where its problem appears: an adapter per input or system, a strategy where a
  rule has variants the spec actually lists, a repository for what we keep. **No pattern for
  decoration.** "—" is a fine answer.
- For every pattern you name, give the requirement ID that needs it. If constitution section 5 has
  an optional rule for that pattern (E-013 onwards in `templates/engineering-rules.md`), follow it.
- Use the names from the glossary (E-001) and the stack from the ADR. No library the ADR does not name.
- Draw a Mermaid `classDiagram`: ports marked `<<port>>`, adapters implementing them (`..|>`),
  arrows labelled with requirement IDs. Only components from the table.
- Do not write code.

When you finish, print: each component with its one job, any component you could not describe
without "and", and any requirement ID with no component.
