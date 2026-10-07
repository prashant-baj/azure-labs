# specs — one place, four layers

Everything this group has decided, in the order a new joiner should read it.

| Layer | Where | What it answers | Came from |
|---|---|---|---|
| 1 · Evidence | `../docs/` | Why — what we heard, and from whom | Module 1 · Sessions 2–4 |
| 2 · Principles | `../constitution.md` | What is always true, whatever we build | Session 9, from layers 1 and 3 |
| 3 · Design record | `design/` | The system as decided, and why | Module 2 · Sessions 5–8 |
| 4 · Slice specs | `NNN-<slice>/` | What we build next — spec, plan, tasks | Session 9 onwards |

## Layer 3 · design/

| File | Session |
|---|---|
| `solution-definition.md` | 5 · what we are building |
| `integration-decisions.md` | 6 · how the pieces talk |
| `contracts/` | 7 · what we promised each other |
| `adr/` | 7 · why we chose it, and what it cost |
| `nfr-register.md`, `constraints.md` | 8 · how well, and the rules we were handed |

## Layer 4 · one folder per slice

| File | Says | Changes when |
|---|---|---|
| `spec.md` | What and why. No technology | The client's need changes |
| `plan.md` | How — including the diagrams, as code | The design changes |
| `tasks.md` | In what order, in small steps | Work is done or re-ordered |
| `trace.md` | Which requirement leads to which task and test | Re-run `/spec-trace` after any change |

## Three rules

1. **One fact, one place.** A slice spec points to the design record. It does not copy it.
2. **The spec changes first.** Then the plan, then the tasks, then the code.
3. **Every line has a source.** If you cannot say where a line came from, it is a guess.
