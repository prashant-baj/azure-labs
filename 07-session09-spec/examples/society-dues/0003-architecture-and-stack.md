# ADR 0003 — Architecture and stack

*Date: Session 9 · Status: accepted · Decided by: the group (invented for this example)*

> In a real repository this file lives at `specs/design/adr/0003-architecture-and-stack.md`.
> Every name, team answer and choice below is invented, to show the shape — not to recommend a stack.

## 1. What the choice must serve — the drivers

| Driver | What it asks of the architecture or the stack | Source |
|---|---|---|
| NFR-001 | A dues answer quick enough to give at the gate | `specs/design/nfr-register.md` |
| NFR-002 | The load count (in = recorded + unmatched) checked after every load | `specs/design/nfr-register.md` |
| C-001 | Nothing that arrives is deleted — records are only ever added | `constitution.md` |
| C-002 | Only the treasurer and the secretary see payments — a role check on every view | `constitution.md` |
| Q-002 | A payment is never counted twice — one key, the bank reference | `constitution.md`, ADR 0002 |
| Seams | A message in (UPI), a file in (statement), a call out (dues) | `specs/design/integration-decisions.md` |
| Team | Three of us build and debug Python without help; one knows Java | The group, Session 9 |
| Program | None given | — |

## 2. Architecture — the shape

| Option | In one line | Fits — which drivers | Costs us — which drivers |
|---|---|---|---|
| A | One deployable, with separate modules for the receivers, the matcher and the dues answer | Q-002 is one unique key in one store. One thing to run and test (Team) | A heavy morning load shares the process with gate queries — watch NFR-001 |
| B | A small service per piece, with a queue between them | Pieces can be run and changed separately | Q-002 must hold across services. More to run and watch than Team can support. No NFR asks for separate scaling |

**Chosen:** A — because Q-002 and Team. Nothing in our files asks for what B gives.

## 3. Stack — the tools

| Layer | Option 1 | Option 2 | Chosen | Because |
|---|---|---|---|---|
| Language | Python | Java | Python | Team |
| Framework | FastAPI | Spring Boot | FastAPI | Seams — a message in and a call out, both over HTTP; C-002 role check on each call; Team |
| Data store | PostgreSQL | PostgreSQL | PostgreSQL | Q-002 — unique bank reference; C-001 — insert-only tables; NFR-002 — the count in one transaction |
| Test runner | pytest | JUnit | pytest | RULE-001 — five examples as one table test |
| Runs on | One container | One container | One container | Where it runs is not decided — see section 6 |

## 4. Decision

We will build the dues service as one deployable with separate modules for the receivers, the
matcher and the dues answer, in Python with FastAPI, keeping every record in PostgreSQL, tested with
pytest, packaged as one container.

## 5. Consequences

**Good:** One thing to run, test and deploy. "Never counted twice" is one unique key, not a promise
between services.
**Bad:** The morning load and the gate queries share one process. NFR-001's load test must run while
a file is loading.
**Later:** If the society ever needs the receivers to run separately, that is a new ADR — and an NFR
that asks for it first.

## 6. Not decided yet

| # | Question | Who can answer |
|---|---|---|
| 1 | [NEEDS CLARIFICATION: where does the container run, and who pays for it?] | Treasurer and secretary |

---
*Never edit an accepted ADR. A change of stack is a new ADR that supersedes this one.*
