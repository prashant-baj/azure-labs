
## Layer 7 — reviewed (Session 18)

- **The readiness checklist is the agenda**: `specs/design/readiness.md`, production (PR) and operations (OR)
  readiness plus the case lines. A line is `met` only with evidence you can point at — a path, a test, a job, a
  dashboard. An honest gap with an owner beats a `met` nobody can see.
- **The runbook is for someone else**: `ops/runbook.md` must let a person outside the group deploy, roll back,
  rotate a secret and handle each alert. Never invent a command, and never write a secret's value.
- **Findings and feedback are decided, not argued**: `specs/review/findings.md` (`REV-0nn`) and
  `specs/review/feedback.md` (`FB-0nn`). Each gets a decision — fix now, spec change, backlog, accepted or
  declined — with a link that proves it later. A high finding is accepted only by the client's side.
- **Spec first, test first**: a finding that changes behaviour changes the spec, the strategy or an ADR first; the
  fix starts with a test named after the finding (`test_rev_0nn_…`), seen red.
- **Never promise the client in the room.** A new request gets "Let me check what that would take", then a
  decision in `feedback.md`.

### Commands (layer 7)

| Command | What it does |
|---|---|
| `/readiness-check <slice>` | Fills the readiness checklist with evidence from the repo — or an honest gap, with a proposed finding |
| `/runbook` | Drafts `ops/runbook.md` from the real pipeline, infra and alerts; asks where the repo is silent |
| `/board-brief` | The three-minute brief for the review board — running slice, two numbers, scorecard, our own top gaps |
| `/triage-review` | A decision for every finding and every piece of feedback — spec changes first, never a promise |
