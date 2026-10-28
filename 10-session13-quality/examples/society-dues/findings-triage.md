# Triage — the first local scan

*The group ran `quality-local`, then `/triage-findings` on what it found. Eleven minutes. Every finding got a
decision and a reason; none was hidden.*

| # | Gate | Finding | What could actually happen here | Decision |
|---|---|---|---|---|
| 1 | Secrets | `hashicorp-tf-password` at `infra/main.tf`, `password_secret_name = "acr-password"` | Nothing — it names a Container Apps secret; the value comes from the registry at deploy time | **False positive.** Second person agreed. `# gitleaks:allow` on the line, fingerprint in `.gitleaksignore` |
| 2 | IaC | CKV_AZURE_137 — registry admin account enabled | Anyone with the admin password can push an image | **Accepted risk** — lab policy forces it. Inline `#checkov:skip` with the reason; review in Session 16 |
| 3 | IaC | CKV_AZURE_139 — registry on the public network | The registry is reachable from the internet (still needs credentials) | **Accepted risk** — no private networking in the lab |
| 4–10 | IaC | Seven Premium-only registry features | Mostly resilience features a society's app does not need | **Debt**, one row in `tech-debt.md`. Ratchet baseline 7 — an eighth fails the pipeline |

**What the assistant got wrong:** its first proposal for finding 1 was to delete the line "to be safe" — that
would have broken the deploy. And for 4–10 it proposed changing the SKU to Premium, which the lab policy does
not allow. Both were caught because the group read the proposal before applying it.

**What it got right:** for finding 2 it pointed out that the admin password ends up in Terraform state —
which is why state is never committed (rule from Session 12).
