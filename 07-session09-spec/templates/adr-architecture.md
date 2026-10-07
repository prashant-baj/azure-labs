# ADR <number> — Architecture and stack

*Date: <date> · Status: proposed · Decided by: <names, once the group decides>*

> **Written after the spec, before the plan.** The spec says what to build; this record says what we
> build it with, and why. It lives in `specs/design/adr/` because it is a design decision for the
> whole system, not just this slice.
>
> The assistant proposes options and compares them. **The group decides.** Every reason names an ID.

## 1. What the choice must serve — the drivers

| Driver | What it asks of the architecture or the stack | Source |
|---|---|---|
| <NFR-0xx> | | `specs/design/nfr-register.md` |
| <C-0xx> | | `constitution.md` |
| Seams | <call / message / file — what comes in and goes out> | `specs/design/integration-decisions.md` |
| Team | <what at least two of us can build and debug without help> | The group, Session 9 |
| Program | <shortlist or rules from the facilitator — or "none given"> | <where it was given> |

## 2. Architecture — the shape

| Option | In one line | Fits — which drivers | Costs us — which drivers |
|---|---|---|---|
| A | | | |
| B | | | |

**Chosen:** <option> — because <driver IDs>.

## 3. Stack — the tools

| Layer | Option 1 | Option 2 | Chosen | Because |
|---|---|---|---|---|
| Language | | | | |
| Framework | | | | |
| Data store | | | | |
| Test runner | | | | |
| Runs on | | | | |

## 4. Decision

[DECISION NEEDED: the group writes this sentence, then sets Status to accepted]

<We will build <system> as <architecture>, in <language> with <framework>, keeping data in <store>,
tested with <test runner>, running on <where>.>

## 5. Consequences

**Good:** <what this makes easier>
**Bad:** <what this makes harder, slower or more expensive — and which NFR to watch>
**Later:** <what we will revisit, and what would make us revisit it>

## 6. Not decided yet

| # | Question | Who can answer |
|---|---|---|
| | | |

---
*Never edit an accepted ADR. A change of stack is a new ADR that supersedes this one.*
