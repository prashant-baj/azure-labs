# Session 18 workshop — the Engineering Excellence Review Board

**By the end of today your group has:**

1. **A readiness checklist with evidence** — production readiness (17 lines) and operations readiness (12 lines),
   plus two lines from your case. Every `met` names its evidence; every gap is owned.
2. **A runbook someone else can use** — deploy, roll back, rotate a secret, and what to do for each alert.
3. **A review by a board** — two other groups and the facilitator score you against the rubric, write at least
   three findings, and give a verdict. The facilitator speaks as your client's people.
4. **Every finding and every piece of feedback decided** — fix now, spec change, backlog, accepted or declined.
5. **The top one or two findings fixed** — spec first, a test named after the finding, then the fix. Tag
   `L7-reviewed`.

| # | Step | Who | Time |
|---|---|---|---|
| 1 | Set up | driver + Maintainer | 5 min |
| 2 | Check yourselves — the checklist and the runbook | two pairs | 20 min |
| 3 | Prepare the brief | whole group | 5 min |
| 4 | The board — present once, review twice | everyone | 40 min |
| 5 | Triage — a decision for every finding and every piece of feedback | whole group | 10 min |
| 6 | Fix the top one or two | two pairs | 20 min |
| 7 | Check and tag | Maintainer | 5 min |
| | Debrief | everyone | 10 min |

Commands below are for macOS / Linux / WSL. **PowerShell** lines are given where they differ. `~/work/group-1` is
your case repo, `<lab>` is this folder.

**Before you start:** your repo has the tag `L6-production` — or you know exactly what is missing, and it goes in
the checklist as a gap. The last `main` pipeline deployed. If the lab was reset since, re-run the last `main`
pipeline now and `drill:load` once, so the dashboard has something to show the board.

---

## Step 1 · Set up (5 min)

```bash
git -C ~/work/group-1 switch main && git -C ~/work/group-1 pull
cd <lab> && chmod +x *.sh
./setup-review.sh ~/work/group-1
```
```powershell
./setup-review.ps1 -Path "C:\work\group-1"
```

It makes the branch `setup/layer-7` with one commit:

| File | What it is |
|---|---|
| `specs/design/readiness.md` | **The checklist** — PR-01..17, OR-01..12, and your case's CR-01, CR-02. The board's agenda |
| `ops/runbook.md` | The runbook template — every _(fill in)_ is a question someone will ask at two in the morning |
| `specs/review/findings.md` | Where the board's findings go — `REV-0nn` |
| `specs/review/feedback.md` | Where the client's feedback goes — `FB-0nn` |
| `.claude/commands/` | `/readiness-check`, `/runbook`, `/board-brief`, `/triage-review` |

Read `<lab>/board/rubric.md` now — two minutes. It is how you will be scored, and how you will score others.

---

## Step 2 · Check yourselves (20 min, two pairs)

| Pair | Does | Command |
|---|---|---|
| A | **Production readiness**, PR-01..17, and the case lines | `/readiness-check specs/<slice>` |
| B | **Operations readiness**, OR-01..12, and `ops/runbook.md` | `/runbook`, then `/readiness-check` on section 2 |

The rules of the checklist:

- **`met` only with evidence** — a path (`specs/design/threat-model.md`), a test name, a job (`job:rollback:test`), a
  dashboard. `check-review` warns about any path that is not in the repo.
- **`partly` says what is missing; `gap` says so plainly.** Each names a finding (`REV-0nn` — write it in
  `findings.md` yourselves) or a backlog item. **A gap you name before the board finds it earns trust.**
- **`n.a.` gives the reason.** "No outside system in this slice" is a reason; "not needed" is not.

Operations readiness will have more gaps than production readiness. That is normal at this point in a build, and
it is exactly what a client's operations team asks about first. What matters is that each gap is visible and owned.

**Check:** `./check-review.sh ~/work/group-1` — sections 1 and 2: every line has a status; no `met` without
evidence; the runbook's _(fill in)_ count is going down.

---

## Step 3 · Prepare the brief (5 min)

```
/board-brief
```

Three minutes, no slides, in this order: what the slice does in the client's words · show it running (one live
request) · the business number and the technical number, from the dashboard · the last deploy scorecard · **your own
top three gaps**. Decide who presents and who drives the screen. Push your branch so the board can see the files.

---

## Step 4 · The board (40 min)

Order and boards: `<lab>/board/rotation.md`. Seven minutes per slot:

| Minutes | What happens |
|---|---|
| 3 | **The reviewed group shows**: the brief from step 3, on screen |
| 2 | **The board asks** — for evidence, not explanations: "Show me the test." "Open the alert rule." "Where is that in the runbook?" "Who agreed to that risk?" |
| 2 | **The client speaks** — the facilitator, in the voice of your case's people. Write down what they say, in their words |
| (3) | **The board writes** its scorecard (`board/scorecard.md`) while the next slot starts, and hands it over |

**As a board** (twice): score the eight areas 0–3, write **at least three findings** and one thing done well, give a
verdict — Go, Go with conditions, Not yet. A finding is what you saw, the evidence, the risk and what to do — never
who did it. Ask one member of your board to try the reviewed group's runbook: "roll back, using only section 3"
(their OR-12).

**When you are reviewed:** one person presents, one drives, everyone else writes down every question. A question you
could not answer is a finding, even if the board does not write it. Afterwards, copy the board's findings into
`specs/review/findings.md` and the client's words into `specs/review/feedback.md`, and the verdict into section 4 of
the checklist.

**Customer feedback — the one rule:** never say yes to a new request in the room. Say *"Let me check what that would
take, and I will come back to you by Friday."* Then decide it in step 5.

---

## Step 5 · Triage (10 min)

```
/triage-review
```

Every finding and every piece of feedback gets a decision:

| Decision | When |
|---|---|
| `fix now` | It fits in 20 minutes, test first. **At most two.** High severity first, then what the client feels most |
| `spec change` | The spec, the strategy or an ADR was wrong or silent — it changes **first**, in the same merge request as any code |
| `backlog` | Sessions 19–20, with an owner |
| `accepted` / `declined` | With who agreed — a **high** finding is accepted only by the client's side — or the reason given to the person who asked |

Feedback also gets a type: `defect` (the slice does not do what the spec says — quote the line), `spec change`,
`new request`, `question`.

**Check:** `check-review` sections 3 and 4 are all OK.

---

## Step 6 · Fix the top one or two (20 min, two pairs)

For each `fix now`, on its own branch `review/rev-0nn`:

1. **Spec first** — if the finding changes behaviour, change the spec line, the strategy row or the ADR, and name
   the finding in it (`REV-0nn`).
2. **Red** — a test named after the finding: `test_rev_003_<what the client would notice>`. Run it; it must fail.
3. **Green** — the smallest change. Run the suite.
4. **Merge request** `fix: REV-0nn <what> - test first`. When merged, set the finding to `done` with the link.

A finding about the runbook or the checklist is fixed in the document — still `done`, still with the link.

---

## Step 7 · Check and tag (5 min)

```bash
cd <lab> && ./check-review.sh ~/work/group-1
git -C ~/work/group-1 switch main && git -C ~/work/group-1 pull
git -C ~/work/group-1 tag L7-reviewed && git -C ~/work/group-1 push --tags
```

Tag only when the READY bar says so. Findings still `open` are fine — as long as each has a decision and an owner.

---

## Done looks like

- [ ] `specs/design/readiness.md`: 31 lines, each with a status; every `met` with evidence; every gap owned
- [ ] `ops/runbook.md`: no _(fill in)_ left; someone outside the group rolled back from it
- [ ] The board's scorecard copied: at least three findings, each with a severity and a decision; the verdict in section 4
- [ ] The client's feedback in their words, each with a type and a decision — nothing promised in the room
- [ ] One or two findings `done`, each with a test named after it, spec first
- [ ] `check-review` READY · tag `L7-reviewed` pushed

## In Sessions 19 and 20

The integrated demo. The board's conditions and your `backlog` findings are the first things you show were done.
Keep the readiness checklist current: it is what the final presentation's review will open first.

## If something goes wrong

| Symptom | Fix |
|---|---|
| `check-review`: *Evidence that is not in the repo* | A typo in the path, or the file is on another branch — merge it, or correct the path |
| The checklist has no case lines | Setup could not tell your case from the repo name — copy yours from `<lab>/templates/case-lines/` into section 3 |
| The dashboard is empty for the board | A lab reset. Re-run the last `main` pipeline and `drill:load`; show the drill table and the job logs meanwhile |
| The board ran out of time | The scorecard can be finished in step 5 — but within the session, while the questions are fresh |
| A finding you disagree with | Write it down anyway, then decide it: `accepted` with a reason, or ask the board for the evidence. Arguing in the slot costs the next group its time |
| `fix now` is turning into an afternoon | Stop. Make it `backlog` with an owner and pick a smaller one. Two small, finished fixes beat one large, unfinished one |
| `check-review`: *No test named after a finding* | Name it `test_rev_0nn_…` (or `REV-0nn` in a Java `@DisplayName`). Runbook-only fixes still need one finding fixed in code or a test elsewhere |
