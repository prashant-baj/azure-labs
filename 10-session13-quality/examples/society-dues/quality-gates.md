# Quality gates — society dues

*Decided by the group in Session 13. Baseline taken from `.quality/local-report.md`, before the first
pipeline run. Lives in `specs/design/quality-gates.md` in a real repo. The pipeline is `ci/quality.yml`.*

## The gates

| ID | Gate | Enforces | Tool | On my laptop | In the pipeline | Blocks merge | Threshold | Baseline today |
|---|---|---|---|---|---|---|---|---|
| QG-001 | Format and lint | E-010, E-006 | ruff (rules in `code/pyproject.toml`) | `quality-local` | `qa:lint` | yes | no findings | 0 |
| QG-002 | Complexity | E-003 — "no function above 5" | lizard | `quality-local` | `qa:complexity` | ratchet | ≤ 5 per function | 0 functions above |
| QG-003 | Secrets | E-008, W-004 | gitleaks | `quality-local` | `qa:secrets` | yes | none, whole history | 0 — after one triaged false positive |
| QG-004 | Static analysis | C-002 (residents' data stays private), E-017 (parameterised queries) | semgrep `p/default` | `quality-local` | `qa:sast` | yes, on ERROR | no ERROR findings | 0 ERROR, 0 WARNING |
| QG-005 | Dependencies | ADR 0003 — only the libraries the stack ADR names, none with a known hole | osv-scanner | `quality-local` | `qa:dependencies` | yes | no known vulnerability | 0 |
| QG-006 | Infrastructure as code | `azure-lab-constraints.md`, W-004 | checkov | `quality-local` | `qa:iac` | ratchet | no new failed check | 7 failed, 2 accepted |
| QG-007 | Unit tests and scenarios | every FR and RULE | pytest + pytest-bdd | `pytest` | `test`, `scenarios` | yes | all green | 27 green |

## Decisions

| Session | Decision | Why |
|---|---|---|
| 13 | Complexity limit 5, not the pipeline's default 10 | E-003 already says 5, and ruff enforces it. One number, one place — the constitution |
| 13 | Complexity and IaC are ratchets | We met 7 IaC findings on day one. Blocking them would stop every merge; ignoring them would hide new ones |
| 13 | SAST blocks only on ERROR | WARNING findings are read in the merge request and triaged; a wall of warnings gets ignored |
| 13 | Dependencies pinned in `requirements.txt` before Session 14 | Unpinned lines are resolved to today's versions — the scan is only as good as the pin |

## Accepted findings

| Finding | Tool | Where | Decision | Reason | Review by |
|---|---|---|---|---|---|
| `hashicorp-tf-password` | gitleaks | `infra/main.tf` — `password_secret_name` | false positive | It is the *name* of a secret, not a value. Confirmed by a second person; `# gitleaks:allow` on the line and the fingerprint in `.gitleaksignore` | — |
| CKV_AZURE_137 ACR admin account | checkov | `infra/main.tf` — registry | accepted risk | The lab role cannot create the AcrPull role assignment (`azure-lab-constraints.md`) | Session 16 — Key Vault and managed identity |
| CKV_AZURE_139 ACR public network | checkov | `infra/main.tf` — registry | accepted risk | No private networking in the lab subscription | Session 16 |
| Seven ACR Premium features (zone redundancy, geo-replication, quarantine, retention, trust, dedicated endpoints, scanning) | checkov | registry | debt | Premium SKU — not available, and not needed for a society's dues. Logged in `tech-debt.md`; baseline 7 | Session 18 review |
