# Worked example — layer 7 for the society dues slice

The same invented housing society, reviewed. The code is the lab-12 example (`12-session16-17-production/examples/
society-dues/`); this folder holds only what Session 18 adds. In a real repo these files live in
`specs/design/readiness.md`, `ops/runbook.md`, `specs/review/findings.md` and `specs/review/feedback.md`, and the
evidence paths inside them are repo paths.

Read it in this order — the order the group worked in:

| # | Look at | Notice |
|---|---|---|
| 1 | `readiness.md` | Every `met` line names its evidence: a path, a test, a job. Every `partly` and `gap` names its finding or backlog item. **The group marked OR-05 a gap itself** — payments live in memory — before the board said a word |
| 2 | `runbook.md` | Written for someone outside the group. Real job names, real settings, no secret values. Section 7 says plainly that nothing is backed up. Another group ran `rollback:test` from section 3 alone (OR-12) |
| 3 | `findings.md` | Five findings, each with what was seen, the evidence, the risk and a decision. REV-01 is high, and decided as a **spec change** (a new NFR and an ADR) with an owner — not quietly fixed. The board's verdict: Go with conditions |
| 4 | `feedback.md` | Four things the society's people said, in their words. One is the same as REV-01 seen from the treasurer's side. One is a new request, **declined with a reason** and a date — never promised in the room |

**A code fix** starts like every fix in this programme: a test named after the finding, seen red. For a finding
`REV-06` it would be `test_rev_006_<what the client would notice>`, then the smallest change, then the merge request
`fix: REV-06 <what> - test first`. In this example the two fixes done in the session were to the runbook and the
drill; the code change for REV-01 is Session 19's work, after its ADR.
