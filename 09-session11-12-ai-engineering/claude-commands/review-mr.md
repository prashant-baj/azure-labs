---
description: The same review the pipeline runs — on your laptop. Writes ai-review.json and ai-review.md
argument-hint: "[optional: base branch, default origin/main]"
---
Base branch: $ARGUMENTS (if empty, use origin/main). Use it wherever the text below says $REVIEW_BASE.

You are reviewing one merge request for a training team. You review; people decide.

Read first: `CLAUDE.md`, `constitution.md` (sections 4 and 5), the slice spec and plan in
`specs/NNN-*/` (spec.md, plan.md sections 8 and 12), and the accepted ADRs in `specs/design/adr/`.

Then read the change: run `git diff $REVIEW_BASE...HEAD` (if REVIEW_BASE is empty, use `origin/main`)
and `git log --oneline $REVIEW_BASE..HEAD`. Open the changed files when you need more context.

Look through four lenses, in this order:
1. **Security** — secrets (W-004, E-008); data sent outside the system; input used without checks;
   queries or commands built from strings; a missing role check the spec asks for.
2. **Correctness** — does the change do what its task and requirement IDs say? Missing *If* cases?
   Tests that cannot fail, or tests changed to make code pass?
3. **Maintainability** — the engineering rules in constitution section 5; the direction rule in
   plan section 12; code no task asked for (W-002).
4. **Compliance** — the C- rules in the constitution; a new library not named in an ADR; licence
   or data-handling concerns.

Rules for every finding:
- It names a rule ID (C-, Q-, W-, E-, FR-, NFR-…) and a place (`file:line`). No rule, no finding.
- Severity: "must" breaks a C- or W- rule, leaks data or hides a failure; "should" breaks an E- rule
  or misses a requirement; "could" is anything else.
- One sentence for what you see, one for the smallest change that fixes it.
- Nothing a linter or formatter already reports. No matters of taste. At most fifteen findings,
  most severe first.

Write two files and change nothing else:
- `ai-review.json` — a JSON array, one object per finding:
  `{"severity": "...", "lens": "...", "rule": "...", "where": "file:line", "finding": "...", "suggestion": "..."}`
  Write `[]` if you find nothing that names a rule.
- `ai-review.md` — the same findings as a table, then up to three things that are already good.

Do not approve, do not merge, do not edit code, and do not say the change is "ready".

When you finish, print the count of findings by severity, and: "To post these to the merge request, run node ci/post-review.mjs ai-review.json with GITLAB_URL, PROJECT, MR_IID and GITLAB_REVIEW_TOKEN set."
