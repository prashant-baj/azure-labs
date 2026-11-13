# Session 18 workshop — the Engineering Excellence Review Board

**Today has two halves.** The first hour is yours: check your own build against the readiness checklist. The
second hour, the whole class is the **Engineering Excellence Review Board**: each group presents once, and while it
does, the other four groups each play one **stakeholder role** — security officer, operations lead, enterprise
architect, QA and release manager. The facilitator chairs and speaks as the client. **The fixes are the next
session.**

**By the end of today your group has:**

1. **A readiness checklist with evidence** — production readiness (17 lines) and operations readiness (12 lines),
   plus two lines from your case. Every `met` names its evidence; every gap is owned.
2. **A runbook someone else can use** — deploy, roll back, rotate a secret, and what to do for each alert.
3. **A review by the board** — at least one finding from each of the four stakeholder roles, the client's feedback,
   and the chair's verdict — all written into your findings and feedback files.
4. **Every finding and every piece of feedback decided** — fix now (next session), spec change, backlog, accepted or
   declined.

**Next session:** the `fix now` findings fixed — spec first, a test named after the finding, then the fix — and the
tag `L7-reviewed`.

| # | Step | Who | Time |
|---|---|---|---|
| | **Part A — self-review** | | **60 min** |
| 1 | Set up | driver + Maintainer | 5 min |
| 2 | Check yourselves — the checklist and the runbook | two pairs | 35 min |
| 3 | Challenge each other, then prepare the brief | whole group | 20 min |
| | **Part B — the board, the whole class** | | **60 min** |
| 4 | The board — present once, play four stakeholder roles | everyone | 60 min |
| 5 | Triage — a decision for every finding and every piece of feedback | whole group | 10 min |
| | Debrief | everyone | 10 min |
| | **Next session** | | |
| 6 | Fix the `fix now` findings | two pairs | |
| 7 | Check and tag `L7-reviewed` | Maintainer | |

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

## Step 2 · Check yourselves (35 min, two pairs)

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

## Step 3 · Challenge each other, then prepare the brief (20 min)

**10 minutes — swap and challenge.** Pair A reads pair B's operations lines and runbook; pair B reads pair A's
production lines. Play the board before the board does: for every `met`, open the evidence. Could a stranger see it?
For every `gap`, is there a finding? Use the questions in `<lab>/board/roles.md` on yourselves.

**10 minutes — the brief.**

```
/board-brief
```

Four minutes on the board, no slides, in this order: what the slice does in the client's words · show it running (one
live request) · the business number and the technical number, from the dashboard · the last deploy scorecard · **your
own top three gaps**. Decide who presents, who drives the screen, and who is the **scribe** — the person who types
every finding into `specs/review/findings.md` as it is read out. Push your branch so the board can see the files.

Also look up **your four roles** for the board in `<lab>/board/rotation.md` — your group's column — and read each
role in `roles.md`. You will play all four, one per slot.

---

## Step 4 · The board — the whole class (60 min)

The whole class is the board. While one group presents, each of the other four groups plays one stakeholder role,
and the roles rotate each slot — so over the hour every group presents once and plays every role once:

| Slot | Presenting | Security officer | Operations lead | Enterprise architect | QA and release manager |
|---|---|---|---|---|---|
| 1 | Group 1 · Nova Retail | Group 2 | Group 3 | Group 4 | Group 5 |
| 2 | Group 2 · Sterling National Bank | Group 3 | Group 4 | Group 5 | Group 1 |
| 3 | Group 3 · PureFoods Global | Group 4 | Group 5 | Group 1 | Group 2 |
| 4 | Group 4 · Apex Industrial | Group 5 | Group 1 | Group 2 | Group 3 |
| 5 | Group 5 · EcoNova Enterprises | Group 1 | Group 2 | Group 3 | Group 4 |

Twelve minutes per slot:

| Minutes | What happens |
|---|---|
| 4 | **The presenting group shows** — the brief from step 3, on screen, `readiness.md` open |
| 5 | **The four roles ask**, about 75 seconds each — security, operations, architecture, QA and release. For evidence, not explanations: "Show me the test." "Roll it back from section 3 of your runbook." |
| 2 | **The client speaks** — the facilitator, in the voice of the case's people |
| 1 | **Each role reads out one or two findings** in the finding format; the presenting group's scribe types them into `specs/review/findings.md` with the role in *Raised by*. The chair gives the verdict in one sentence |

**When you play a role:** stay in your seat — `board/roles.md` lists the checklist lines each role owns and five
questions to pick from. Fill a role card (`board/scorecard.md`) while the group presents: score the lines you own,
write one or two findings, and one thing done well. A finding is what you saw, the evidence, the risk and the smallest
next step — never who did it.

**When you present:** one person presents, one drives, the scribe types. Do not argue with a finding in the slot —
write it down; you decide it in step 5. Afterwards, also write the client's words into `specs/review/feedback.md` and
the chair's verdict into section 4 of the checklist.

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
| `fix now` | Fixed first thing next session, test first. Every `high` finding is `fix now` or `spec change` unless the client's side accepts it. Rank them: high first, then what the client feels most |
| `spec change` | The spec, the strategy or an ADR was wrong or silent — it changes **first**, in the same merge request as any code |
| `backlog` | Sessions 19–20, with an owner |
| `accepted` / `declined` | With who agreed — a **high** finding is accepted only by the client's side — or the reason given to the person who asked |

Feedback also gets a type: `defect` (the slice does not do what the spec says — quote the line), `spec change`,
`new request`, `question`.

**Check:** `check-review` sections 3 and 4 are all OK.

---

## Step 6 · Next session — fix the `fix now` findings (two pairs)

For each `fix now`, on its own branch `review/rev-0nn`:

1. **Spec first** — if the finding changes behaviour, change the spec line, the strategy row or the ADR, and name
   the finding in it (`REV-0nn`).
2. **Red** — a test named after the finding: `test_rev_003_<what the client would notice>`. Run it; it must fail.
3. **Green** — the smallest change. Run the suite.
4. **Merge request** `fix: REV-0nn <what> - test first`. When merged, set the finding to `done` with the link.

A finding about the runbook or the checklist is fixed in the document — still `done`, still with the link.

---

## Step 7 · Next session — check and tag

```bash
cd <lab> && ./check-review.sh ~/work/group-1
git -C ~/work/group-1 switch main && git -C ~/work/group-1 pull
git -C ~/work/group-1 tag L7-reviewed && git -C ~/work/group-1 push --tags
```

Tag only when the READY bar says so. Findings still `open` are fine — as long as each has a decision and an owner.

---

## Done looks like — today

- [ ] `specs/design/readiness.md`: 31 lines, each with a status; every `met` with evidence; every gap owned
- [ ] `ops/runbook.md`: no _(fill in)_ left; a board member tried to roll back from it
- [ ] `specs/review/findings.md`: at least one finding from each of the four roles, each with a severity, a decision and *Raised by*; the chair's verdict in section 4 of the checklist
- [ ] The client's feedback in their words, each with a type and a decision — nothing promised in the room
- [ ] Your group played all four roles, and handed over a role card each time

## Done looks like — next session

- [ ] Every `fix now` finding `done`, each with a test named after it, spec first
- [ ] `check-review` READY · tag `L7-reviewed` pushed

## In Sessions 19 and 20

Next session starts with the fixes (steps 6 and 7), then the integrated demo. The board's conditions and your
`backlog` findings are the first things you show were done.
Keep the readiness checklist current: it is what the final presentation's review will open first.

## If something goes wrong

| Symptom | Fix |
|---|---|
| `check-review`: *Evidence that is not in the repo* | A typo in the path, or the file is on another branch — merge it, or correct the path |
| The checklist has no case lines | Setup could not tell your case from the repo name — copy yours from `<lab>/templates/case-lines/` into section 3 |
| The dashboard is empty for the board | A lab reset. Re-run the last `main` pipeline and `drill:load`; show the drill table and the job logs meanwhile |
| The board ran out of time | The chair cuts questions, never the findings minute. A role that did not get to ask still reads out its finding |
| Your role found nothing to ask | Pick a question from `board/roles.md` and ask it anyway — the answer is often the finding |
| The scribe could not keep up | Each role hands its role card over after the slot; type the rest from the cards in step 5 |
| A finding you disagree with | Write it down anyway, then decide it: `accepted` with a reason, or ask the board for the evidence. Arguing in the slot costs the next group its time |
| Next session: `fix now` is turning into an afternoon | Stop. Make it `backlog` with an owner and pick the next one. Small, finished fixes beat one large, unfinished one |
| `check-review`: *No test named after a finding* | Name it `test_rev_0nn_…` (or `REV-0nn` in a Java `@DisplayName`). Runbook-only fixes still need one finding fixed in code or a test elsewhere |
