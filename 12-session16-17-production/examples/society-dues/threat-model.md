# Threat model: society dues, slice 001

*In a real repo this lives at `specs/design/threat-model.md`. It was written with `/threat-model` in Session 16,
using the C4 container view, the spec and the deployed service. Each threat names the control that answers it
and the test that proves the control works. A threat with no test is a hope, not a control.*

## 1. What we protect, and from whom

| Asset | Why it matters | Who would want it |
|---|---|---|
| Who paid what, by flat | C-002: only the treasurer and the secretary may see it | a curious resident, a neighbour in a dispute |
| The payments record | The books the society's accounts are built on | anyone who wants their flat marked as paid |
| The treasurer key | It opens everything above | anyone, so it must never be in git, a log or a laptop |

**Trust boundaries:** the internet → the Container App's ingress (HTTPS only), the app → its SQLite file, and
GitLab → Azure (OIDC, no stored password).

## 2. Threats (STRIDE), each with its control and its proof

| ID | STRIDE | Threat | Control | Proved by |
|---|---|---|---|---|
| T-01 | Spoofing | Anyone sends `X-Role: treasurer` and sees who paid what. Before layer 6, this worked | SEC-001: the role **and** `X-Api-Key` matching the `TREASURER_KEY` secret, compared in constant time | `test_sec_001_t01_*`, Postman "SEC-001 a role header without the key is refused" |
| T-02 | Elevation of privilege | The key is not configured, and the check quietly lets everyone in | SEC-001 fails closed: no key configured means 503 for everyone | `test_sec_001_t02_no_key_configured_means_nobody_gets_in` |
| T-03 | Information disclosure | The treasurer's reminder page (`/ui/reminders`) was public | SEC-001 on the page as well as on the API | `test_sec_001_t03_the_treasurers_page_is_not_public_any_more` |
| T-04 | Tampering, disclosure | The page is framed by another site, content types are sniffed, personal data sits in a shared cache, the API explorer maps every route | SEC-002: security headers on every response; no `/docs` and no `/openapi.json` | `test_sec_002_t04_*`, `verify:dast` (`dast.high` = 0) |
| T-05 | Tampering | A flat name or remark containing `<script>` runs in the treasurer's browser | SEC-003: everything written into HTML is escaped | `test_sec_003_t05_a_flat_name_is_escaped_in_the_page` |
| T-06 | Information disclosure | A payer's name ends up in logs or telemetry that more people can read | OBS-004: log lines carry the event, the outcome and the requirement ID, never the payer | `test_obs_004_t06_the_log_line_names_the_requirement_never_the_payer` |
| T-07 | Information disclosure | The key leaks through git, a job log or a Terraform file | Masked GitLab variable → `TF_VAR_treasurer_key` → a Container App secret. No value in any file | `qa:secrets` (gitleaks), the job log shows `[MASKED]`, `check-production` section 3 |

## 3. Accepted for now, written down

| Threat | Why it is accepted | Who agreed | Revisit when |
|---|---|---|---|
| Repudiation: nobody can tell who matched a payment by hand (FR-006) | One treasurer in this slice; the client has not asked for an audit trail | the secretary, at the review | a second person can match payments |
| Denial of service: `/payments/upi` flooded | Container Apps caps replicas; no rate limit in this slice | the secretary, at the review | the bank's real webhook is connected |
| One shared key instead of per-person sign-in | The slice has two users and no identity provider | the secretary, at the review | the society asks for more roles, or for sign-in with Entra ID |

## 4. What the scan of the running service said

The first `verify:dast` run (ZAP baseline, before SEC-002) reported missing anti-framing, CSP and
`X-Content-Type-Options` headers, a cacheable response, and the API explorer. After SEC-002 it reported no
high-risk findings. The remaining medium and low findings are recorded in `zap.html` (a pipeline artifact), and
`dast.medium` in the strategy is a ratchet set from that run.
