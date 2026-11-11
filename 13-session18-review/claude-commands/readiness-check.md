---
description: Fill in specs/design/readiness.md - every production and operations readiness line with evidence from the repo and the pipeline, or an honest gap. Never marks a line met without evidence. Asks; applies on a yes.
argument-hint: "[slice folder]"
---
Arguments: $ARGUMENTS — the slice folder. Read `specs/design/readiness.md` first: its rows are the agenda. Then
read what can be evidence: `specs/` (spec, NFR register, ADRs, `test-strategy.md`, `threat-model.md`,
`observability.md`, `threat-notes.md`), the tests, `.gitlab-ci.yml` and `ci/`, `infra/`, `ops/`, and the last
`confidence.md` if it is in the repo root. Ask the group to paste the last deploy scorecard and the result of
`check-production` if they are not there.

Go **one section at a time** (production, operations, the case lines), stopping for the group's yes after each:

1. For each row, look for evidence **in the files**: a path, a test name, a pipeline job, a Terraform resource, a
   heading in the runbook. Quote it in the *Evidence* column as `path`, `test_name` or `job:name`.
2. Propose a status. **`met` only with evidence you can point at.** If the evidence is outside the repo (a
   dashboard, an email, a drill), ask the group to describe it and record where it is — e.g. "drill table,
   `specs/design/observability.md` §4".
3. `partly` says what is missing. `gap` says so plainly. `n.a.` gives the reason. Never soften a gap into `partly`.
4. For every `partly` and `gap`, propose a finding `REV-0nn` for `specs/review/findings.md`, with a severity
   (`high` would block go-live or harm the client) — the group decides.

Then summarise: how many lines are met, partly, gap; the three gaps the board is most likely to ask about; and
which `ops/runbook.md` sections are still _(fill in)_. Show the changes and apply them only on a yes. End with the
commit message `review: readiness checklist - <met> met, <partly> partly, <gap> gaps, each gap owned`.
