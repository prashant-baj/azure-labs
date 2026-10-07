
## Module 3 — working from the spec

The repository now has four layers. Read `specs/README.md` before anything else.

- `constitution.md` holds the rules for every slice. Never break one silently — say which rule, and why.
- `specs/NNN-<slice>/spec.md` is the source of truth for what to build. If a request is not in the
  spec, say so and ask whether the spec should change first.
- **The spec changes first.** When asked to change behaviour, update `spec.md` and its change log,
  then `plan.md`, then `tasks.md` — and only then the code.
- Every piece of work names a task ID from `tasks.md`, and every task names a requirement ID.
- When our files do not say, write `[NEEDS CLARIFICATION: <question>]`. Never fill the gap with a
  plausible guess.
- Cite the file and section for anything you take from our records.
- **Build only with the stack in the accepted architecture-and-stack ADR** (`specs/design/adr/`).
  Do not add a framework, library or service it does not name — propose a new ADR instead.

### Commands

| Command | What it does |
|---|---|
| `/spec-constitution` | Assembles `constitution.md` from the glossary, constraints, NFRs and ADRs |
| `/spec-specify <slice folder>` | Assembles `spec.md` for one slice — IDs and sources on every line |
| `/spec-clarify <slice folder>` | Asks the group what the spec cannot answer, one question at a time |
| `/spec-architecture <slice folder>` | Proposes architecture and stack options against our drivers. **The group decides** |
| `/spec-plan <slice folder>` | Drafts `plan.md` — how — on the stack in the accepted ADR |
| `/spec-tasks <slice folder>` | Breaks the plan into small tasks, tests first |
| `/spec-trace <slice folder>` | Writes `trace.md` and lists the gaps. Fixes nothing |
