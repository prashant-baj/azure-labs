---
description: Write specs/design/threat-model.md - assets, trust boundaries, STRIDE threats each with a control and the test that proves it, and what is accepted for now. Reads the code and the deployed shape; never invents a threat the files do not support. Asks; applies on a yes.
argument-hint: "[slice folder]"
---
Arguments: $ARGUMENTS — the slice folder. Read `constitution.md`, the slice's `spec.md` (FR, C- constraints, NFR
rows), `specs/design/` (the C4 views, ADRs, `quality-gates.md`, `test-strategy.md`), the code's routes and how
each one decides who may call it, `infra/` (ingress, secrets, identities), `.gitlab-ci.yml` and `ci/`.

Write `specs/design/threat-model.md` from `templates/threat-model.md`, **one section at a time, stopping for the
group's yes after each**:

1. **Assets and trust boundaries.** What the client would be hurt to lose or leak: data, money, a decision, a
   secret. Quote the requirement or constraint that makes it matter. Where data crosses a boundary (internet →
   ingress, app → store, GitLab → Azure), name it.
2. **Threats, STRIDE by STRIDE.** For each letter, ask what an outsider, a legitimate user acting out of role, and
   a careless insider could do. **Check the code, not the hope.** For each protected route, read how it decides
   and try it: does a header on its own get in? What happens when the secret is not configured? Write each threat
   as `| T-0n | STRIDE | Threat | Control | Proved by |`. A threat the code already lets happen is the first row:
   say so plainly. Never list a threat the system cannot have; say "not applicable, because ...".
3. **Controls.** Each threat gets a control (`SEC-0nn`) from `stacks.md` or the stack ADR. No new library without
   an ADR. Secrets come from the environment, fail closed, and are compared in constant time. Personal data never
   goes in logs or telemetry.
4. **Proof.** Each control gets a test named after both IDs (`test_sec_001_t01_...`), at the lowest layer that can
   catch it, written **red first** against today's code, then the control, then green. The scan of the running
   service (`verify:dast`, `dast.high`, `dast.medium`) is proof for the header and disclosure rows.
5. **Accepted for now.** Threats the slice will not fix: why, and when to revisit. An accepted risk is a decision
   for the client's representative, not for the group alone, so mark it `[NEEDS CLARIFICATION]` until someone with
   the authority agrees.

Then propose the strategy rows: `dast.high` = 0 and `dast.medium` as a ratchet (measured from the first scan, never
guessed), plus a line in section 2 for the security tests. Show the change and apply it only on a yes. End with the
commit message `spec: threat model T-01..T-0n, controls SEC-001..SEC-0nn`.
