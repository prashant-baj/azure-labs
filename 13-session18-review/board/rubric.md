# The Engineering Excellence Review Board — rubric

*Used by every board in Session 18, and again at the final presentation. The board scores **evidence**, not
effort, not slides and not promises. The reviewed group's `specs/design/readiness.md` is the agenda.*

## How the board works

- **Two groups and the facilitator** review one group (rotation: `board/rotation.md`).
- The reviewed group has **three minutes**: the slice running, the business number on the dashboard, the last
  deploy scorecard, and their own top gaps from the readiness checklist.
- The board has **two minutes of questions**. Ask for evidence, not explanations: *"Show me the test."* *"Open the
  alert rule."* *"Where is that in the runbook?"*
- The facilitator then speaks **as the client's people** for two minutes — customer feedback, in their words.
- The board fills in `board/scorecard.md` and hands it over **within three minutes**. The reviewed group copies the
  findings into `specs/review/findings.md`.

## Scoring — eight areas, 0 to 3 each

| Score | Means |
|---|---|
| **0 — Not there** | Nothing to show |
| **1 — Claimed** | They say it is done; there is no evidence the board could see |
| **2 — Evidenced** | A file, a test, a job or a dashboard shows it |
| **3 — Proved** | Evidenced, and it runs by itself or was tried: a pipeline job decides it, a test fails without it, a drill fired it |

| Area | Checklist lines | A 3 looks like |
|---|---|---|
| Architecture and decisions | PR-01–05 | ADRs match the code; every NFR measured; every outside call has a timeout, retry and duplicate rule — with tests |
| Code quality | PR-06–07 | Gates green on main; tests named after IDs; the ratchet held through layer 6 |
| Testing and confidence | PR-13, the scorecard | The last deploy scorecard is CONFIDENT, and the group can say what each row proves |
| Security | PR-08–11 | Every threat has a test that failed first; no secret in any file; `dast.high = 0` |
| Release and recovery | PR-12, PR-14, OR-05 | Built once; rollback tried; a restore tried — or an honest, owned gap |
| Observability | PR-15–17 | Both numbers read aloud from the dashboard; the drill fired an alert; one request found by id |
| Operations readiness | OR-01–04, OR-06–12 | Someone outside the group deployed and rolled back from the runbook; owner, on-call, SLO and incident path agreed |
| Customer value | Case lines, feedback | The business signal is the number the client cares about; feedback is triaged, not promised |

## Writing a finding

One line each. What you saw, the evidence, the risk, and what to do — **never who did it**.

> **Weak:** "Security could be better."
> **Strong:** "REV-03 · high · PR-09 — the Postman test environment file holds the API key value (`tests/api/test.postman_environment.json`). Anyone with repo access can call the protected routes. Empty it, rotate the key, add the file check to the pipeline."

**Severity:** `high` would block go-live or harm the client · `medium` fix before the next release · `low` an
improvement.

## The verdict

| Verdict | When |
|---|---|
| **Go** | No high findings; every `gap` line is owned |
| **Go with conditions** | High findings each have a decision and an owner, and none would harm the client on day one |
| **Not yet** | A high finding with no decision, or a line the board was told is `met` that it could not see |

*A board that finds nothing has not looked. Every board writes at least three findings and one thing done well.*
