---
description: Review a change, or the whole slice, against the threat model and the OWASP Top 10 (2025) - finds what is missing, never fixes silently. Every finding names the file, the line, the threat ID and a test that would catch it.
argument-hint: "[merge request, branch, or path]"
---
Arguments: $ARGUMENTS — what to review (default: this branch against main). Read `specs/design/threat-model.md`
first: the review is against **its** threats, and then against the OWASP Top 10 (2025) for anything it missed.

For each changed route, file or Terraform resource, check:

| Check | Look for |
|---|---|
| Access (A01) | Every route that returns protected data calls the access check. A header alone never grants a role. The check fails closed |
| Secrets (A04, A02) | A value in code, a test, a Postman environment, a `.tf` or `.tfvars` file, or a job log. Secrets come from the environment; Terraform variables holding them are `sensitive` |
| Injection (A05) | Strings built into SQL, shell commands or HTML. Parameters, not concatenation; HTML is escaped |
| Configuration (A02) | Security headers on every response; no API explorer or debug mode in the deployed app; HTTPS only at ingress |
| Supply chain (A03) | A new dependency without a pinned version, or one `qa:dependencies` reports |
| Logging (A09) | A business event that leaves no trace, or a log line that carries personal data (names, phone numbers, account numbers) |
| Errors (A10) | An exception that answers with a stack trace, or a failure path that lets the request through (fail open) |

Report as a table: `| # | File:line | Threat (T-0n or OWASP) | What is wrong | The test that would catch it |`.
A finding with no file and line is not a finding. **Do not edit code.** Offer, for each finding, to write the
failing test first, and apply that on a yes. A threat the review found that the model lacks becomes a proposed new
`T-0n` row.
