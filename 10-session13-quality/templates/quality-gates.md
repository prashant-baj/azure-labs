# Quality gates

*The quality bar for this repository, decided by the group. Every gate names the engineering rule or
requirement it enforces, the tool that checks it, where it runs, and whether it blocks a merge. Tools and
thresholds change only by editing this file first — the pipeline (`ci/quality.yml`) follows it.*

*Last changed: <session> · Baseline taken from `.quality/local-report.md` on <date>, commit <sha>*

## The gates

| ID | Gate | Enforces | Tool | On my laptop | In the pipeline | Blocks merge | Threshold | Baseline today |
|---|---|---|---|---|---|---|---|---|
| QG-001 | Format and lint | E-010, E-006 | <ruff / eslint + prettier / spotless + checkstyle> | `quality-local` | `qa:lint` | yes | no findings | |
| QG-002 | Complexity | E-003 | lizard | `quality-local` | `qa:complexity` | ratchet | per function ≤ <limit from E-003> | <functions above it today> |
| QG-003 | Secrets | E-008, W-004 | gitleaks | `quality-local` | `qa:secrets` | yes | none, in the whole history | |
| QG-004 | Static analysis | <C- or NFR- security rule> | semgrep (`p/default`) | `quality-local` | `qa:sast` | yes, on ERROR | no ERROR findings | <ERROR / WARNING today> |
| QG-005 | Dependencies | <rule> | osv-scanner | `quality-local` | `qa:dependencies` | yes | no known vulnerability | |
| QG-006 | Infrastructure as code | <rule> | checkov | `quality-local` | `qa:iac` | ratchet | no new failed check | <failed checks today> |
| QG-007 | Unit tests and scenarios | every FR, RULE | <pytest / jest / junit> + BDD runner | your test command | `test`, `scenarios` | yes | all green | |

**Ratchet** — the number today is the baseline. A merge may keep it or lower it, never raise it. When it
goes down, lower the baseline here and in `ci/quality.yml` in the same merge request.

## Decisions

| Date | Decision | Why | Who |
|---|---|---|---|
| | Complexity and IaC start as ratchets, not hard gates | Existing findings are triaged first; new ones are stopped from today | |

## Accepted findings

*Each one triaged with `/triage-findings`: a reason, and where it is suppressed. Secrets are never accepted —
they are rotated.*

| Finding | Tool | Where | Decision | Reason | Review by |
|---|---|---|---|---|---|
| | | | false positive / accepted risk / debt | | |
