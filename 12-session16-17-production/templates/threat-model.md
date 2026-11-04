# Threat model: <slice>

*`specs/design/threat-model.md`. Written with `/threat-model` from the spec, the C4 views, the code and `infra/`.
Each threat names its control and the test that proves it.*

## 1. What we protect, and from whom

| Asset | Why it matters (requirement) | Who would want it |
|---|---|---|
| | C-0nn / FR-0nn | |

**Trust boundaries:** internet → ingress; app → its store; GitLab → Azure.

## 2. Threats (STRIDE), each with its control and its proof

| ID | STRIDE | Threat | Control | Proved by |
|---|---|---|---|---|
| T-01 | Spoofing | | SEC-001 | `test_sec_001_t01_...` |
| T-02 | Tampering | | | |
| T-03 | Repudiation | | | |
| T-04 | Information disclosure | | | `verify:dast` |
| T-05 | Denial of service | | | |
| T-06 | Elevation of privilege | | | |

*More than one row per letter is fine. A letter that does not apply gets one line saying why.*

## 3. Accepted for now, written down

| Threat | Why it is accepted | Who agreed | Revisit when |
|---|---|---|---|
| | | [NEEDS CLARIFICATION] | |

## 4. What the scan of the running service said

*After the first `verify:dast`: the high and medium findings, what you fixed, and the ratchet for `dast.medium`.*
