---
description: Write specs/design/test-strategy.md - risks, layers, regression, AI-suggested tests, the confidence thresholds the pipeline decides on, and the pipeline drawn from them (real and planned jobs). Measures before it writes a number. Asks; applies on a yes.
argument-hint: "[slice folder]"
---
Arguments: $ARGUMENTS — the slice folder. Read `constitution.md`, the slice's `spec.md` (FR, RULE, NFR rows),
`specs/design/nfr-register.md` if it exists, `specs/design/quality-gates.md`, `trace.md` (the *Scenario*
column and its "none yet" rows), the tests that exist today, `.gitlab-ci.yml`, `ci/` and `infra/`.

**Measure before you write a number.** If `confidence.md` is not in the repo root from a run in the last hour,
ask the group to run their tests with reports and then `python3 ci/confidence.py --when merge` (workshop guide,
step 3), and read today's test count and line coverage from its *Measured* column. Never estimate either.

Write `specs/design/test-strategy.md` from `templates/test-strategy.md`, **one section at a time, stopping
for the group's yes after each**:

1. **Risks.** What could go wrong that would hurt the client most — from the spec, the evidence log and the
   "none yet" list. Each risk names the requirement and the layer that should catch it. Ask: "What would the
   client be most upset to find in production?" Never invent a risk the files do not support.
2. **Layers.** Unit, scenarios, integration/API in-process, API over HTTP (Postman), end to end (only the
   journeys the client would notice), performance smoke, quality gates. For each: what it proves, the tool
   (from the stack ADR — no new tool without an ADR), where it runs, before merge or after deploy. Then
   **what is not automated yet, and why** — honest gaps beat a pretty pyramid.
3. **Regression.** Every test runs on every push; a defect gets a test at the lowest layer that can catch it.
4. **AI-suggested tests.** How they are marked, reviewed and logged (`reviews/ai-tests.md`).
5. **Confidence thresholds** — the table `ci/confidence.py` reads: `| CS-0nn | Signal | Measure | Threshold |
   Source | When |`. Measures: `tests.pass_rate`, `tests.count`, `coverage.line`, `api.pass_rate`,
   `e2e.pass_rate`, `perf.p95_ms`, `perf.error_rate`, `smoke.version`. Thresholds like `>= 80`, `<= 2000`.
   **Every performance threshold comes from an NFR row** — quote it; none there? `[NEEDS CLARIFICATION]` and ask
   who decides. Coverage and test count are **ratchets**: today's number, measured, never a round target.

   A check the group designs but has not built (a DAST scan, an accessibility check) gets a row with the measure
   `planned.<name>` — shown on the scorecard, never counted as met.
6. **The pipeline.** Draw section 6 from section 5: every row, the job that measures it, the stage, and whether
   it is **real today** or **planned** (and from when). Read `ci/confidence.yml`: the `(planned)` jobs stand in
   for the deploy half until Session 15. A row with no job, or a planned job with no row, is a gap — say which,
   and propose the fix: add the row, delete the job (and a line under "Not automated yet"), or copy a planned job
   for a `planned.<name>` row. Show the YAML change; apply only on a yes.

Then run `python3 ci/confidence.py --when merge` and walk the group through each row: met, MISSED, NOT MEASURED,
NOT SET, after deploy, planned. End with the commit message
`spec: test strategy - confidence thresholds CS-001..CS-0nn and the pipeline drawn from them`.
