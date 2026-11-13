---
description: Decide every review finding (REV) and every piece of customer feedback (FB) - fix now, spec change, backlog or accepted/declined - spec and ADR changes first, never a promise to the client in the room. Asks; applies on a yes.
argument-hint: ""
---
Read `specs/review/findings.md`, `specs/review/feedback.md`, `specs/design/readiness.md`, the spec, the NFR
register, the ADRs and the threat model.

For **each finding and each piece of feedback**, propose:

1. **Type** (feedback only): `defect` — the slice does not do what the spec says (quote the line); `spec change` —
   the spec was wrong or silent; `new request` — outside the slice; `question`.
2. **Decision**:
   - `fix now` — fixed first thing in the next session: a test named after it (`test_rev_0nn_…`,
     `test_fb_0nn_…`) written red first, then the smallest fix. Every `high` finding is `fix now` or `spec change`
     unless the client's side accepts it.
   - `spec change` — the spec, the strategy or an ADR changes **first**, in the same merge request as any code.
   - `backlog` — with an owner and Session 19 or 20.
   - `accepted` (findings) or `declined` (feedback) — with who agreed or the reason given to the person who asked.
     A high finding is accepted only by the client's side, never by the group alone.
3. **The link** that will prove it later: the test name, the spec line, the ADR, the backlog item.

Rank the `fix now` findings into the order the group will fix them next session: high severity first, then the
one the client feels most, then the quickest. Show the table changes and
apply them only on a yes. For each `fix now`, end with the branch name `review/rev-0nn` and the commit message
`fix: REV-0nn <what> - test first`.
