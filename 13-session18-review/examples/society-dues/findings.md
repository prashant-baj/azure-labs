# Review findings — society dues, slice 001

*In a real repo this is `specs/review/findings.md`. Copied from the board's scorecard in step 4, decided with
`/triage-review` in step 5.*

| ID | Severity | Checklist line | Finding — what the board saw | Evidence | Decision | Status | Link |
|---|---|---|---|---|---|---|---|
| REV-01 | high | OR-05, CR-02 | Payments are kept in an in-memory database. A restart, a redeploy or a lab reset loses every payment recorded — the treasurer's books are gone | `code/dues/api.py` `create_app`: `sqlite3.connect(":memory:")` | spec change | done | NFR-004 added (durability); ADR 0002 — a file-backed store on an Azure Files volume; build in Session 19, owner: the anchor |
| REV-02 | medium | OR-01 | The runbook did not say how to rotate the treasurer key. Asked "the key leaked — what now?", nobody could answer from the page | `ops/runbook.md` had no §4 | fix now | done | `ops/runbook.md` §4; MR "fix: REV-02 secret rotation in the runbook" |
| REV-03 | medium | PR-16 | The errors alert never fired in the drill. `drill:errors` ran for two minutes — shorter than the alert's five-minute window — so the rule never saw enough failures | drill table; alert rule history | fix now | done | `ops/runbook.md` §5: run `drill:load` for the full window; drill re-run, the alert fired (drill table) |
| REV-04 | low | PR-02, PR-04 | ADR 0001 says PostgreSQL. The slice uses SQLite. Nobody decided the change | `specs/design/adr/0001-architecture-and-stack.md` | spec change | open | ADR 0001 superseded by ADR 0002 (REV-01) |
| REV-05 | low | OR-07 | No cost estimate. The board could not say what the test environment costs a month | — | backlog | open | Session 19, owner: the Maintainer |

**Done well (from the board):** "You named REV-01 yourselves in the first minute, before we asked."
