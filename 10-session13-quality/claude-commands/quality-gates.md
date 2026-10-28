---
description: Write or update specs/design/quality-gates.md - the quality bar, from your rules and today's local scan. Asks; applies only on a yes.
argument-hint: "[path to .quality/local-report.md - default]"
---
Arguments: $ARGUMENTS — usually nothing. Read `constitution.md` (engineering rules E-0nn, W-0nn, C-0nn), the
NFRs in `specs/design/` and the slice spec, `.quality/local-report.md` (run `quality-local` first if it is
missing — say so and stop), `ci/quality.yml`, and `specs/design/quality-gates.md` if it exists.

1. **Map gates to rules.** For each gate in `templates/quality-gates.md`, find the rule or requirement it
   enforces and quote it. A gate with no rule behind it: ask whether to add the rule to the constitution first
   — the spec changes first. A rule with no gate: list it as "checked by people only".
2. **Thresholds.** Propose each threshold from the rule, never from habit — e.g. the complexity limit is
   E-003's number. Where the constitution has none, ask; do not pick one.
3. **Baseline.** Copy today's counts from the local report into *Baseline today*. Propose the policy:
   lint, secrets, SAST ERROR, dependencies and tests **block**; complexity and IaC are a **ratchet** from
   today's count. Ask the group to confirm or change each, one at a time.
4. **Show the diff** of `specs/design/quality-gates.md` (create it from the template). Apply only on a yes.
5. **Then the pipeline** — and only then: show the changes to the `variables:` block of `ci/quality.yml`
   (`QA_COMPLEXITY_LIMIT`, `QA_COMPLEXITY_BASELINE`, `QA_IAC_BASELINE`, `QA_APP_DIR`) that make it match
   the spec. Apply on a yes.

Never lower a gate to make a finding go away — that is `/triage-findings`, one finding at a time, with a
reason. Never mark secrets as accepted. End with: the gates that block today, the ratchets and their
baselines, and the commit message `spec: quality gates QG-001..QG-007 with today's baseline`.
