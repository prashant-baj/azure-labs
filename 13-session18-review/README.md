# Session 18 · Layer 7 — the Engineering Excellence Review

Six layers are built: spec, design, working code, behaviour, measurable confidence, and a service that is safe to
expose and watched. Layer 7 asks the question a client asks before signing a go-live:

> **"Would you put your name on it — and can someone else run it?"**

Today a **review board** — two other groups and the facilitator — reviews your build against a **readiness
checklist** of production and operations readiness. The facilitator speaks as your client's people. What the board
finds and what the client says become decisions, spec changes and fixes.

| | Session 18 · Wed 11 Nov |
|---|---|
| **You build** | A readiness checklist with evidence (production + operations + your case), a runbook, the board's findings and the client's feedback — decided — and the top one or two fixed, test first |
| **The review covers** | Architecture review · code review · security assessment · production readiness evaluation · operations readiness · customer feedback |
| **Tag** | `L7-reviewed` |

The demo can now say: *"A review board scored our build against a readiness checklist. Here is what it found, what
our client said, and what we fixed."* See [`../BUILD-ROADMAP.md`](../BUILD-ROADMAP.md).

## Today's TO-DO

**Step by step: [`WORKSHOP-S18.md`](WORKSHOP-S18.md).**

| # | Do | Who | Time |
|---|---|---|---|
| 0 | `git pull` azure-labs. `L6-production` tagged. Last `main` pipeline deployed; if the lab was reset, re-run it and `drill:load` | everyone | before |
| 1 | **Set up**: `setup-review` — the checklist (with your case's lines), runbook, findings and feedback files | driver + Maintainer | 5 min |
| 2 | **Check yourselves**: pair A `/readiness-check` (production), pair B `/runbook` + operations | two pairs | 20 min |
| 3 | **The brief**: `/board-brief` — three minutes, your own gaps first | whole group | 5 min |
| 4 | **The board**: present once, sit on two boards; the client speaks ([`board/rotation.md`](board/rotation.md), [`board/rubric.md`](board/rubric.md)) | everyone | 40 min |
| 5 | **Triage**: `/triage-review` — a decision for every finding and every piece of feedback | whole group | 10 min |
| 6 | **Fix the top one or two**: spec first, `test_rev_0nn_…` red, then the fix | two pairs | 20 min |
| 7 | `check-review` READY → tag `L7-reviewed` | Maintainer | 5 min |
| 8 | **Debrief** — what did a board see that you could not? | everyone | 10 min |

**Two repositories, as before:** this lab (azure-labs) is pull-only. Your case repo (GitLab) is where you push.

## What is in this folder

| Path | What it is |
|---|---|
| `setup-review.sh` / `.ps1` | Once per group: commands, templates, the checklist with your case's lines, runbook, findings, feedback, one commit |
| `check-review.sh` / `.ps1` | Five sections and the READY bar. Checks evidence paths exist; does not judge the evidence — the board does |
| `templates/readiness.md` | **The readiness checklist** — PR-01..17 production, OR-01..12 operations, section 3 for your case, section 4 for the verdict |
| `templates/case-lines/` | Two case lines per case (A–E), added by setup |
| `templates/runbook.md`, `findings.md`, `feedback.md` | The other three documents |
| `board/rubric.md` | Eight areas scored 0–3, how to write a finding, the verdict |
| `board/scorecard.md` | One per review — the board fills it in and hands it over |
| `board/rotation.md` | Who reviews whom, in what order |
| `claude-commands/` | `/readiness-check`, `/runbook`, `/board-brief`, `/triage-review` |
| `examples/society-dues/` | The worked example — read its README first |

## The checklist on one page

| Production readiness | | Operations readiness | |
|---|---|---|---|
| Requirements | PR-01–03 · NFRs measured, ADRs current, risks owned | Runbook | OR-01 · deploy, roll back, rotate, each alert |
| Architecture | PR-04–05 · code matches ADRs; timeouts, retries, duplicates | Ownership | OR-02 · owner, on-call, alerts reach them |
| Code quality | PR-06–07 · gates green, tests named after IDs | Service level | OR-03 · an SLO agreed with the client |
| Security | PR-08–11 · threats tested, no secrets, `dast.high = 0`, no personal data in logs | Incidents | OR-04 · severity, who decides, blameless postmortem |
| Release | PR-12–14 · built once, CONFIDENT, rollback tried | Recovery | OR-05 · backup, a restore tried, targets |
| Observability | PR-15–17 · two signals, alerts proved, one request by id | Capacity, cost | OR-06–07 · replica limits; cost estimate, budget alert |
| | | Dependencies, data | OR-08–09 · contacts, fallbacks; retention, access |
| | | Change, config, handover | OR-10–12 · release notes, approver; settings; someone else ran it |

The production lines map to what layers 1–6 built — most can be met with evidence you already have. The
operations lines are mostly new; expect gaps, and own them.

## Commands (layer 7)

| Command | What it does |
|---|---|
| `/readiness-check <slice>` | Fills the checklist with evidence from the repo — or an honest gap, with a proposed finding |
| `/runbook` | Drafts `ops/runbook.md` from the real pipeline, infra and alerts; asks where the repo is silent |
| `/board-brief` | The three-minute brief: running slice, two numbers, scorecard, your own top gaps |
| `/triage-review` | A decision for every finding and every piece of feedback — spec changes first, never a promise |

## The rules of this layer

1. **No evidence, no `met`.** A claim the board cannot see scores 1, not 2.
2. **Name your gaps before the board does.** An owned gap is a plan; a hidden one is a risk.
3. **A finding describes the work, never the person.**
4. **Never promise the client in the room.** "Let me check what that would take" — then decide it.
5. **Spec first, test first.** A finding that changes behaviour changes the spec; its fix starts with a failing test
   named after it.

## Homework, before Session 19

- Every `backlog` finding has an owner and a session.
- Send one piece of declined or deferred feedback back to "the client" as a short note: what you decided, and why.
- Read another group's runbook. Could you roll back their service from it alone?

## If something goes wrong

See [WORKSHOP-S18.md](WORKSHOP-S18.md#if-something-goes-wrong). The most common: evidence paths that point at
another branch, an empty dashboard after a lab reset, and a `fix now` that grew into an afternoon — make it backlog
and pick a smaller one.
