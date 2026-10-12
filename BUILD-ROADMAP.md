# Build roadmap · one system, layer by layer

From Session 9 to the final presentation, your group builds **one system in one repository**. Every
session adds one layer on top of what is already there. Nothing is thrown away and started again.

Think of it like building a house. The plan is approved first, then the frame, then the walls, the
wiring and the plumbing, then the inspection, and only then the house-warming. Nobody puts the
terrace garden on before the slab is cast. Each layer here stands on the one below it, so a weak
layer shows up everywhere above it.

## The rule for every session

| Every session adds… | Where |
|---|---|
| **One change to the spec — first** | `constitution.md`, `specs/design/`, `specs/NNN-<slice>/` |
| **One change to the code — after** | the code, tests and pipeline in the same repository |
| **One tag** | so anyone can see exactly what the system was at the end of that session |
| **One line of the final demo** | what you can now show that you could not show before |

The spec changes first. If the code moves and the spec does not, the layer is not finished.

## The layers

| # | Session | Layer | In the spec, first | Then in the repo | Tag | The demo can now say |
|---|---|---|---|---|---|---|
| 1 | 9 · Specification-driven Engineering | **Know what to build** | Constitution, slice spec, architecture-and-stack ADR, plan, tasks | Specs only — no code | `spec-001-v1` | "Every requirement traces back to what the client told us" |
| 2 | 10 · Engineering Excellence Practices | **Shape it well** | The components of the slice, drawn as code in the plan. Clean code and design principles added to the constitution as rules | A first version of the code, then reviewed and refactored against those rules | `L2-design` | "Clean structure — and the rules it follows" |
| 3 | 11–12 · AI-assisted Software Engineering | **Make it work** | One AI-assisted capability, written as requirements with its own *If* rows and limits | The slice built task by task, through merge requests. AI reviews every MR; a person approves | `L3-working` | "It works end to end — and a human checks what the AI does" |
| — | 23 Oct · Mid-point check-in | *Show the business* | — | — | — | First demo of what is working |
| 4 | 13 · Quality-first Engineering | **Prove the behaviour** | User stories and acceptance criteria; executable scenarios (Gherkin) tagged with requirement IDs | Scenarios that pass; the rule built test-first | `L4-behaviour` | "The spec runs — as tests" |
| 5 | 14–15 · Modern Testing & Automation | **Automate the confidence** | A test strategy for the whole system, in the design record | Unit, integration, API and end-to-end tests; regression in the pipeline; AI-suggested tests, reviewed | `L5-tested` | "Every change is tested before it merges" |
| 6 | 16–17 · Secure, Observable & Production-ready | **Ready for production** | Security, logging and monitoring requirements; a readiness checklist | Secrets kept safely, logs and a dashboard, infrastructure as code, a pipeline that deploys and can roll back | `L6-production` | "Deployed, watched — and we can roll back" |
| 7 | 18 · Engineering Excellence Review | **Reviewed** | Review findings become spec and ADR changes | The fixes | `L7-reviewed` | "What the review board found, and what we fixed" |
| 8 | 19–21 · Integrated delivery | **Tell the story** | Nothing new — walk the trace | Polish only | `final` | The whole walk-through |

*Layers 2 to 8 are the plan as of Session 9. Details will be sharpened session by session — the
order will not change.*

## What the final demo looks like

If every layer is in place, the demo tells itself, in the same order you built it:

1. **The problem** — what the client told you, from `docs/`.
2. **The spec** — one slice, requirements with IDs and sources.
3. **The design** — components, principles, the stack and why.
4. **It works** — the slice, end to end, including the AI-assisted part.
5. **It is proven** — scenarios and tests, passing, in the pipeline.
6. **It runs for real** — deployed, with a dashboard, and a rollback you can show.
7. **The thread** — pick one requirement and follow it from the client's words, to the spec, to the
   task, to the test, to the code, to the metric on the dashboard.

Step 7 is the part that impresses. Only a group that built in layers can do it.

## The minimum bar — before you build the next layer

Not finished the Session 9 spec? You do not need all of it to move on, but you do need this much.
The next layer is built on it.

| Must have | Why |
|---|---|
| `constitution.md` filled in | The rules every layer is checked against |
| Section 0 of `spec.md`, in your own words | Your definition of the slice |
| At least three requirements, each with an ID and a source | Something real to build, and to trace |
| At least one *If … then* requirement | What happens when it goes wrong |
| The architecture-and-stack ADR, decided and accepted | You cannot write code without it |
| Committed and pushed to your GitLab project | Your work, safe and visible |

Then, before you build: `plan.md` and `tasks.md`. Finish `trace.md` as you go.

**Check it:** run `07-session09-spec/check-spec` on your repository. The last section, *Ready for
the build layers?*, shows `HAVE` or `NEED` for each line above, and says `READY` or `NOT YET`.

## If your group falls behind

- **Close the minimum bar first.** Do not skip a layer to catch up — a layer built on a gap has to
  be built twice.
- **Keep your tags.** If a session ends half-way, tag what you have. The next session starts from a
  known point, not from "whatever was on someone's laptop".
- **Smaller is fine.** A slice with three requirements that works in every layer beats a slice with
  fifteen that works in none.

## Rules that hold in every layer

- **The spec changes first.** Then the plan, the tasks, the code.
- **One fact, one place.** Link to it. Do not copy it.
- **The stack changes only through an ADR.**
- **Every branch, commit and merge request names a task ID.** Every task names a requirement ID.
- **The assistant proposes. You decide** — and your name is on the approval.
