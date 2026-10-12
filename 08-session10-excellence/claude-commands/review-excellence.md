---
description: Review the code against the constitution's rules — findings with a rule and a line. Changes nothing.
argument-hint: "[slice folder] [optional: base branch, default main]"
---
Arguments: $ARGUMENTS — the slice folder, then optionally the branch to compare with (default `main`).

Read `constitution.md` (sections 4 and 5), `<slice>/spec.md`, `<slice>/plan.md` section 12, the
accepted architecture-and-stack ADR, and `templates/review.md`.

Review the code changed on this branch (`git diff <base>...HEAD`). If nothing has changed against
the base, review all the code for the slice.

Write the review to `<slice>/reviews/L2-review.md`, following the template. **Change no code.**

Rules:
- **Every finding names a rule ID** (E-… or W-…) **and a place** (`file:line`). No rule, no finding.
- Check, in this order: secrets (W-004, E-008) · silent failures (E-006, W-006) · code no task asked
  for (W-002) · one job per module (E-002) · the direction rule (E-004) · names against the
  glossary (E-001) · magic values (E-005) · duplication (E-007) · tests named after IDs (E-009).
- Suggest a refactoring for each finding, in one line — the smallest change that fixes it.
- Severity: **must** breaks a W- rule or hides a failure; **should** breaks an E- rule; **could** is
  everything else.
- No findings the formatter or linter would already report. No matters of taste.
- At most fifteen findings, most severe first. If there are more, say how many you left out.
- Also list up to three things that are **already good**, with where they are.
- Leave the **Decision** and **By** columns empty. The group decides each finding: fix, debt, or
  overruled — with a reason.

When you finish, print the findings count by severity and: "Now decide each one as a group. Fix the
'must' findings with /refactor-step, one at a time."
