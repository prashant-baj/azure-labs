# Sessions 14 and 15 · Layer 5 — automate the deployment, with measurable confidence

Layer 4 set the quality bar and proved the behaviour. Layer 5 answers the question every release is really about:

> **"How sure are we — and how do we know?"**

Not a feeling, and not "the pipeline is green". A **scorecard**: each signal you trust, the threshold your
group decided in the spec, and what this pipeline measured. The pipeline reads your thresholds, measures
the signals, and **decides** — before merge, and again after every deploy.

| | Session 14 — Fri 30 Oct | Session 15 — Mon 2 Nov |
|---|---|---|
| **Theme** | Confidence **before merge** | Confidence **after deploy** |
| **You build** | The test strategy that says how you know · the **whole pipeline drawn from it** — real where it is built, orange `(planned)` where it is not · the merge scorecard | Every planned job made real: build once, deploy to the test environment, verify (smoke, API, end to end, performance) · the deploy scorecard |
| **The pipeline says** | *"Here is our whole test design — and what is real today."* | *"Every merge to main deploys — and proves it."* |

Both sessions are mostly workshop. See [`../BUILD-ROADMAP.md`](../BUILD-ROADMAP.md). Tag at the end of
Session 15: **`L5-tested`**. The demo can now say: *"Every merge deploys to a test environment, and the
pipeline shows what it proved — against thresholds the client's requirements set."*

## The idea in one picture

```
specs/design/test-strategy.md          ci/confidence.py                         confidence.md
| CS-001 | tests pass   | = 100   | ─┐                                          | CS-001 | 100     | met    |
| CS-003 | coverage     | >= 71   |  ├─ reads the thresholds ─ measures ─ decides | CS-003 | 73.4    | met    |
| CS-007 | p95, NFR-001 | <= 2000 | ─┘  from junit, coverage, newman, k6, health  | CS-007 | 412 ms  | met    |
                                                                                   CONFIDENT - 8 of 8
```

A threshold changes **only in the strategy**, in a merge request, decided by the group — never in the
pipeline, and never to make a scorecard pass.

## Session 14 — today's TO-DO (Fri 30 Oct)

**Step by step: [`WORKSHOP-S14.md`](WORKSHOP-S14.md).** By the end, the strategy says how you know you are
confident — and the pipeline shows the whole design: real jobs for what is built, orange `(planned)` jobs for the
rest.

| # | Do | Who | Time |
|---|---|---|---|
| 0 | `git pull` azure-labs. Your repo has the tag `L4-behaviour`. Python 3 and Node 20+ on one laptop | everyone | before |
| 1 | **Set up**: `setup-testing` on a branch | driver + Maintainer | 10 min |
| 2 | **Make your code measurable**: test reports, `/health` with version, `APP_START` ([`stacks.md`](stacks.md)) | driver + one | 15 min |
| 3 | **Measure today**: tests with reports, then `python3 ci/confidence.py --when merge` — read the *Measured* column | driver | 10 min |
| 4 | **Spec the strategy**: `/test-strategy` — risks, layers, *not automated yet*, every threshold with its source | whole group | 25 min |
| 5 | **Draw the whole pipeline from the strategy**: section 6, then `ci/confidence.yml` — real and planned jobs | whole group | 15 min |
| 6 | **Run it, read it against the strategy**: push, *Visualize*, the scorecard row by row, see it say MISSED once, merge | whole group | 20 min |
| 7 | **Debrief** — compare pipelines and scorecards across groups | everyone | 10 min |

## Session 15 — today's TO-DO (Mon 2 Nov)

| # | Do | Who | Time |
|---|---|---|---|
| 0 | `./check-testing` — section 4 lists what deploy needs from your `infra/`. Install k6 (and Playwright if you have a web UI) | everyone | before |
| 1 | **Finish Session 14 — and grow the suite**: anything still NEED in sections 1–3; `/suggest-tests` on one ID where the strategy says you are thin, each test seen red, logged in `reviews/ai-tests.md` | whole group | 10 min |
| 2 | **The deploy thresholds**: every `[NEEDS CLARIFICATION]` from Session 14 answered; section 6 — which planned job becomes real today | whole group | 15 min |
| 3 | **Performance smoke**: point `tests/perf/smoke.js` at the answer your NFR is about; run it locally | pair A | 20 min, at the same time as 4 |
| 4 | **One journey end to end** — or, with no web UI, more API failure paths | pair B | 20 min, at the same time as 3 |
| 5 | **Turn deploy on**: `CONFIDENCE_DEPLOY: "on"`, merge, watch build → deploy → verify → decide | whole group | 25 min |
| 6 | **Break it on purpose** on a branch — see the scorecard say NOT CONFIDENT, analyse it, put it back | pairs | 15 min |
| 7 | `check-testing` says READY → tag `L5-tested` | Maintainer | 5 min |
| 8 | **Debrief** | everyone | 10 min |

**Two repositories, as before:** this lab (azure-labs) is pull-only. Your case repo (GitLab) is where you
push. Never copy `examples/` into your case repo.

## Tools — install before the session

| Tool | Needed for | macOS / Linux / WSL | Windows |
|---|---|---|---|
| Node.js 20 or later | Newman, Playwright | as in Session 10 | as in Session 10 |
| **Newman** 6.2.3 (Postman's runner) | API checks, Session 14 | nothing to install: `npx newman@6.2.3 …` | the same |
| Postman (optional) | Reading and editing the collection by hand | postman.com/downloads | postman.com/downloads |
| **k6** | Performance smoke, Session 15 | `brew install k6`, or the release binary | `winget install k6 --source winget` |
| **Playwright** 1.56.1 | Only with a web UI, Session 15 | `cd tests/e2e && npm install && npx playwright install chromium` | the same |

The pipeline runs all of them anyway, pinned. Your laptop is where you find out first.

---

## Session 14

The whole workshop, step by step, with commands for each stack and each step's check: **[`WORKSHOP-S14.md`](WORKSHOP-S14.md)**.

---

## Session 15

### Before: what deploy needs

`./check-testing` section 4 tells you. The pipeline deploys **its own** test environment (`test<group number>`),
with its own Terraform state in Azure — your Session 12 laptop deploy is not touched. It needs:

| | Where it comes from |
|---|---|
| Azure sign-in | The OIDC variables from lab 09c on your GitLab project: `AZURE_OIDC_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` (protected — main only) |
| `infra/` takes `var.prefix`, `var.image`, `var.target_port`; outputs `acr_name`, `acr_login_server`, `app_url` | The Session 12 Terraform starter has all six |
| A Dockerfile in `APP_DIR` that listens on `PORT` and reads `APP_VERSION` | Session 12; [`stacks.md`](stacks.md), section 4 |

### Step 2 · The deploy thresholds (15 min)

Back to the strategy, section 5 — **the spec first, then the pipeline**:

- **CS-007, CS-008 — performance.** Which NFR says how fast is fast enough, and for which answer? The threshold
  is the NFR's number. The smoke is a **few users for a short time** — it catches a slow change, it is not a
  load test (the deck covers the difference).
- **CS-006 — end to end.** Do you have a web UI a user would notice breaking? One or two journeys. No UI? Delete
  the row, and say so under *Not automated yet, and why*.

### Step 3 · Performance smoke (20 min, pair A)

Set `PERF_PATHS` in `tests/perf/smoke.js` to the requests your NFR is about — not just `/health`. Run it against
your app locally, with the thresholds from your strategy:

```bash
python3 ci/confidence.py --env                     # prints P95_MS, ERROR_RATE from your strategy
k6 run -e BASE_URL=http://localhost:8000 -e P95_MS=2000 -e ERROR_RATE=0.01 tests/perf/smoke.js
```

Read the result: `http_req_duration p(95)` and `http_req_failed`. Under load, did anything fail that never fails
alone? That is a finding — `/analyse-failure` it.

### Step 4 · One journey end to end (20 min, pair B, at the same time)

**With a web UI:**

```bash
cp -r .claude/test-starters/e2e tests/e2e
cd tests/e2e && npm install && npx playwright install chromium
BASE_URL=http://localhost:8000 npx playwright test
```

Write the journey in the client's words, named after its ID: `test('FR-008 the treasurer sees who has not paid', …)`.
Prefer roles and visible text over CSS selectors. Commit `package-lock.json` too. **Keep these few** — every
end-to-end test is slow and the likeliest to be flaky; push everything else down to API or unit tests.

**No web UI:** more API failure paths with `/api-tests` — and the *Not automated yet* line in the strategy.

### Step 5 · Turn deploy on (25 min)

On a branch: `CONFIDENCE_DEPLOY: "on"` in `ci/confidence.yml`, and the deploy rows set in the strategy. Merge it.
On `main` the pipeline now runs, after your tests and gates:

```
deploy   deploy:state ─ deploy:registry ─ build:image ─ deploy:test           built once, in Azure, tagged with the commit
verify   verify:smoke   verify:api   verify:e2e   verify:perf              the deployed service, this commit
.post    confidence:deploy                                                 every row - red unless CONFIDENT
```

The orange `(planned)` jobs are gone from `main`: each one is replaced by the real job it stood for. Check
section 6 of the strategy — every *planned* there should now say *real*. A `planned.<name>` row for a later session
stays planned, and says so on the scorecard.

`build:image` builds **in Azure** (`az acr build`) — no Docker on the runner or your laptop. `verify:smoke`
waits until the service answers with **this** commit, not the last one. Then the same Postman collection,
against the deployed URL. *Operate → Environments → test* shows what is deployed and links to it.

### Step 6 · Break it on purpose (15 min, in pairs)

Confidence you never saw fail has not proved anything. On a **branch**, one at a time:

- Delete a test → `CS-002` (*the suite only grows*) **missed**.
- Make a health check return a fixed version → after merge, `CS-005` **missed** — the pipeline caught a stale deploy.
- Add a slow path to the request your NFR is about (for example a short sleep) → run k6 locally: `CS-007`.

Read `confidence.md`, run `/analyse-failure`, revert. Never merge the broken change.

### Step 7 · Check, tag (5 min)

```bash
./check-testing.sh ~/work/group-1                     # last section: READY?
git -C ~/work/group-1 switch main && git -C ~/work/group-1 pull
git -C ~/work/group-1 tag L5-tested && git -C ~/work/group-1 push origin L5-tested
```

---

## Commands (layer 5)

| Command | What it does |
|---|---|
| `/test-strategy <slice>` | Risks, layers, regression, AI-suggested tests and the confidence thresholds — section by section, on a yes |
| `/suggest-tests <slice> <ID>` | Up to six tests for one requirement; each seen red against a broken version before it is kept; logged |
| `/api-tests <slice> [url]` | The Postman collection from the spec — happy and failure paths, every test named after its ID; runs it with Newman |
| `/analyse-failure <job or test>` | Evidence, classification, the lowest layer, a `DEF-0nn` regression test, the smallest fix |

## Done looks like

- [ ] `specs/design/test-strategy.md` — risks, layers, *not automated yet*, every threshold set; performance rows quote an NFR
- [ ] The suite grew since `L4-behaviour`; coverage reported in the merge request; tests named after IDs
- [ ] `reviews/ai-tests.md` — every AI-suggested test with a decision; kept ones seen red
- [ ] `tests/api/` — every test named after its ID; `api:local` green before merge
- [ ] `tests/perf/smoke.js` at the answer the NFR is about; `tests/e2e/` — or the strategy says why not
- [ ] Deploy on: main builds once, deploys, verifies; `confidence:deploy` says **CONFIDENT**
- [ ] One deliberate failure seen and analysed; `check-testing` READY; tag `L5-tested` pushed

## The rules of this layer

1. **Confidence is measured, not felt.** A signal, a threshold, a measurement — or it is an opinion.
2. **Thresholds come from the spec.** Performance from the NFRs, coverage and count from today's ratchet.
   Changed only in the strategy, in a merge request. Never lowered to pass.
3. **The lowest layer that can catch it.** Many unit tests, some API checks, few journeys end to end.
4. **Build once, deploy that.** The image the checks verified is the image that runs — tagged with the commit.
5. **A failure is evidence.** Classify it, reproduce it, pin it with a test. Retrying until green hides it.
6. **AI suggests, a person decides.** Seen red, traced to the spec, logged.

## Homework, before Session 16

- Every requirement in the slice proved somewhere — the trace has no *none yet* rows, or each says why.
- Read your last `confidence.md` aloud to someone outside the group. Can they tell what you are sure of?
- Session 16 starts layer 6, ready for production — security first. List every setting your app reads, and mark which of them are secret.

## If something goes wrong

| Symptom | Fix |
|---|---|
| `confidence:merge` says *NOT SET* | A threshold in the strategy still has a placeholder (`<today's count>`). Measure it, write the number |
| `confidence:merge` says *NOT MEASURED* for tests or coverage | Your `test` job does not keep `report.xml` / `coverage.xml` as artifact **paths** — `stacks.md`, section 2 |
| `api:local`: *The app did not answer on /health* | Read `app.log` in the job's artifacts. Usually: `APP_START` run from the wrong folder (`APP_DIR`), the wrong port, or the app needs a database — `stacks.md`, section 3 |
| `api:local` or `verify:api`: *SMOKE … version* fails | Your health endpoint does not return `APP_VERSION` from the environment |
| Newman: *more than one collection* | Keep one `*.postman_collection.json` in `tests/api/`; folders inside it organise the rest |
| `deploy:state`: *No Azure identity* | The OIDC variables from lab 09c are missing on this project, or `main` is not protected |
| `build:image`: *TasksOperationsNotAllowed* | The subscription does not allow ACR Tasks (`az acr build`). Tell your facilitator: the image then has to be built on a runner with Docker and pushed. Meanwhile the merge scorecard still works — set `CONFIDENCE_DEPLOY` back to `"off"` |
| `deploy:registry`: resource already exists | Another state owns that name — check `prefix`: the pipeline's is `test<group number>`, not your laptop's |
| `verify:smoke` never sees this commit | The container did not start (Container App → *Log stream*), it listens on another port than `APP_PORT`, or it ignores `APP_VERSION` |
| `verify:e2e`: `npm ci` needs a lockfile | Commit `tests/e2e/package-lock.json` (the job falls back to `npm install`, slower) |
| `verify:perf` red, works alone | Under load something breaks that never breaks alone — a lock, a pool, a shared connection. That is the smoke doing its job: `/analyse-failure` |
| A test passes, then fails, then passes | Flaky. Never just retry: find the cause (time, order, shared data, waiting). Quarantine with a `DEF-0nn` and a date only if the group agrees |
| `check-testing`: *still the starter* | `/api-tests` has not replaced the starter collection yet |
| The test environment costs money overnight | *Operate → Environments → test → Stop* runs `destroy:test`. The next merge to main deploys it again |
