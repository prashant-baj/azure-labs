# Session 14 workshop — the strategy, and the whole pipeline drawn from it

**By the end of today your group has:**

1. **A test strategy that says how you know you are confident** — risks, layers, what is not automated yet, and
   a table of thresholds, each with a number you measured or a requirement that set it.
2. **The whole pipeline, drawn from that strategy** — everything you have built so far running **for real**, and
   every check you have designed but not built yet standing in as an orange **`(planned)`** job. One pipeline
   view that shows the complete test design, honestly marked.

Session 15 turns every planned job real. Nothing you design today is thrown away.

| # | Step | Who | Time |
|---|---|---|---|
| 1 | Set up | driver + Maintainer | 10 min |
| 2 | Make your code measurable | driver + one | 15 min |
| 3 | Measure today | driver | 10 min |
| 4 | Spec the strategy | whole group | 25 min |
| 5 | Draw the whole pipeline from the strategy | whole group | 15 min |
| 6 | Run it, and read it against the strategy | whole group | 20 min |
| | Debrief | everyone | 10 min |

Commands below are for macOS / Linux / WSL. **PowerShell** lines are given where they differ. On Windows,
`python3` may be called `python`. `~/work/group-1` is your case repo, `<lab>` is this folder.

**Before you start:** your repo has the tag `L4-behaviour` (`git tag --list 'L4-*'`) — today's growth is measured
from it. You have Python 3 (the scorecard needs nothing else) and Node 20+ (for `npx newman`).

---

## Step 1 · Set up (10 min)

One person, on a fresh `main`:

```bash
git -C ~/work/group-1 switch main && git -C ~/work/group-1 pull
cd <lab> && chmod +x *.sh
./setup-testing.sh ~/work/group-1                  # add  python|node|java <app-folder>  if it guesses wrong
```
```powershell
./setup-testing.ps1 -Path "C:\work\group-1"        # -Stack python|node|java -App <folder>
```

It makes the branch `setup/layer-5` with one commit. What matters today:

| File | What it is |
|---|---|
| `specs/design/test-strategy.md` | The strategy template — sections 1–6. You fill it in step 4 |
| `ci/confidence.py` | **The scorecard**: reads your thresholds, measures the reports, decides |
| `ci/confidence.yml` | The confidence pipeline — real jobs **and** the `(planned)` ones |
| `.gitlab-ci.yml` | `ci/confidence.yml` included; stages `check, test, deploy, verify` |
| `tests/api/`, `tests/perf/smoke.js` | Starters: a Postman collection, a k6 smoke |
| `.claude/commands/` | `/test-strategy`, `/suggest-tests`, `/api-tests`, `/analyse-failure` |

Open Claude Code in your repo once now, so it reads the new `CLAUDE.md` section.

**Check:** `git -C ~/work/group-1 log --oneline -1` shows the setup commit; `ls ~/work/group-1/ci` shows
`confidence.py` and `confidence.yml`.

---

## Step 2 · Make your code measurable (15 min)

The scorecard can only decide on what your pipeline **reports**. Three changes, once — all in [`stacks.md`](stacks.md):

**2a. Your `test` job writes junit and coverage reports** — `stacks.md`, section 2. Replace your `test:` job in
`.gitlab-ci.yml` with the complete one for your stack (Python, Node — Jest, Vitest or node:test — or Java).
Set `APP_DIR` to your app folder. Java: add the JaCoCo plugin to `pom.xml` first.

**2b. `/health` says which version it is** — `stacks.md`, section 1. One small endpoint:
`{"status": "ok", "version": "<APP_VERSION from the environment>"}`. Run the app and open it in a browser.

**2c. `APP_START` — can the pipeline start your app?** — `stacks.md`, section 3. In `ci/confidence.yml`:

```yaml
  APP_DIR: "backend"                               # your app folder
  APP_START: "uvicorn app.main:app --port 8000"    # or: npm start · java -jar target/<name>.jar
```

Your app needs a cloud database or a secret to start? Leave `APP_START` **empty** for now — `api:local` then
runs as a planned job, and you say why in the strategy. That is an honest answer, not a failure.

**Check:** run your stack's test line from `stacks.md` on your laptop, from `APP_DIR`, with `CI_PROJECT_DIR` set
to the repo root:

```bash
cd ~/work/group-1 && export CI_PROJECT_DIR="$PWD" && cd <app folder>
# then the test line for your stack, e.g. Python:
python -m pytest -q --junitxml="$CI_PROJECT_DIR/report.xml" --cov=. --cov-report=xml:"$CI_PROJECT_DIR/coverage.xml" --cov-report=term
```
```powershell
cd C:\work\group-1; $env:CI_PROJECT_DIR = (Get-Location).Path; cd <app folder>
python -m pytest -q --junitxml="$env:CI_PROJECT_DIR/report.xml" --cov=. --cov-report=xml:"$env:CI_PROJECT_DIR/coverage.xml" --cov-report=term
# Jest:  $env:JEST_JUNIT_OUTPUT_DIR = $env:CI_PROJECT_DIR; npx jest --ci --reporters=default --reporters=jest-junit --coverage --coverageReporters=cobertura --coverageDirectory="$env:CI_PROJECT_DIR/coverage"
# Java:  mvn -B test
```

The repo root now has `report.xml` / `junit.xml` (Java: `target/surefire-reports/`) and a coverage file. They are
git-ignored — never commit them. Commit the job and the endpoint: `ci: test reports for the scorecard; /health with version`.

---

## Step 3 · Measure today (10 min)

Before anyone writes a threshold, ask the scorecard what is true **now**. From the repo root:

```bash
python3 ci/confidence.py --when merge
```

The template's thresholds are still placeholders, so the rows say **NOT SET** — but the **Measured** column is
filled in. That is today's baseline:

```
| ID     | Signal                                    | Measured | Threshold          | ... | Result        |
| CS-001 | Unit, integration and scenario tests pass | 100      | = 100              |     | met           |
| CS-002 | The suite only grows                      | 31       | >= <today's count> |     | **NOT SET**   |
| CS-003 | Line coverage                             | 64.2     | >= <today's %>     |     | **NOT SET**   |
```

**Write the two numbers down.** Not round them — `31`, not `30`; `64.2`, not `65`. A ratchet starts from what is
true, and may only go up. (Your numbers will differ — those above are an example.)

CS-001 below 100? A test is failing today. That goes into the strategy as a risk, and into `/analyse-failure`
in step 6 — not into a lower threshold.

**If `APP_START` works** (step 2c), measure the API checks too — start your app, then:

```bash
npx newman@6.2.3 run tests/api/*.postman_collection.json -e tests/api/local.postman_environment.json \
  --reporters cli,junit --reporter-junit-export newman-local.xml
python3 ci/confidence.py --when merge --api newman-local.xml
```

The starter collection has two `FR-0nn` requests to `/<path>` — they will fail until step 5. The `SMOKE` health
check should pass.

---

## Step 4 · Spec the strategy (25 min)

In Claude Code: **`/test-strategy specs/<slice>`**. It reads your spec, NFRs, quality gates, trace and pipeline,
and writes `specs/design/test-strategy.md` **one section at a time, stopping for your yes**. Your job is to
decide. For each section, the decision the group must make:

| Section | You decide | A good answer looks like |
|---|---|---|
| 1 · Risks | What would hurt the client most if it went wrong in production? | Three to six risks, each naming the requirement and the layer that should catch it |
| 2 · Layers | What each kind of test proves, the tool, where it runs | Unit and scenarios before merge; API over HTTP before merge (if `APP_START`) and after deploy; few journeys end to end |
| 2 · Not automated yet | What you will not automate yet — and why | "No web UI in this slice — no end-to-end test." "App needs the cloud database — API checks after deploy only." |
| 3 · Regression | How a defect gets a test | "At the lowest layer that can catch it, before the fix" |
| 4 · AI-suggested tests | How suggestions are reviewed | Seen red, traced to the spec, logged in `reviews/ai-tests.md` |
| 5 · Thresholds | The number for every row, and where it comes from | Below |

**Section 5 — the rows, and where each number comes from:**

| Row | Measure | Threshold | Source | When |
|---|---|---|---|---|
| CS-001 tests pass | `tests.pass_rate` | `= 100` | your rule W-003 | merge |
| CS-002 the suite only grows | `tests.count` | `>=` **step 3's count** | ratchet | merge |
| CS-003 line coverage | `coverage.line` | `>=` **step 3's %** | ratchet | merge |
| CS-004 API checks pass | `api.pass_rate` | `= 100` | the FR IDs the collection covers | **merge** if `APP_START` works, else **deploy** |
| CS-005 this commit is deployed | `smoke.version` | `= 1` | deploy | deploy |
| CS-006 a journey end to end | `e2e.pass_rate` | `= 100` | the FR | deploy — or delete the row (no web UI) |
| CS-007 the answer, 95th percentile | `perf.p95_ms` | `<=` **the NFR's number** | NFR-0nn | deploy |
| CS-008 requests failing under load | `perf.error_rate` | `<` **the NFR's number** | NFR-0nn | deploy |

- **merge** rows are checked before every merge — and again after deploy. **deploy** rows only after deploy.
- **No NFR behind a performance number?** Do not invent one. Write `[NEEDS CLARIFICATION]` in the threshold and the
  name of who can decide; the scorecard will say NOT SET until someone does. That is a finding to bring to the client.
- **A gate you design but cannot build yet** — a security scan of the running app, an accessibility check? Give it
  a row with the measure `planned.<name>`, for example
  `| CS-009 | No high-risk findings from a scan of the running app | planned.dast | = 0 | NFR-005 | deploy |`.
  The scorecard shows it as *planned — not built yet* and never counts it as met.

**Check:** `python3 ci/confidence.py --when merge` — every merge row is `met` (or MISSED for a reason you
wrote down), deploy rows say *after deploy*, nothing says *unknown measure*. Then
`python3 ci/confidence.py --env` shows the performance thresholds the pipeline will hand to k6.

Commit: `spec: test strategy - risks, layers, confidence thresholds CS-001..CS-0nn`.

---

## Step 5 · Draw the whole pipeline from the strategy (15 min)

Every row in section 5 needs a job that measures it; every job should serve a row. Today some of those jobs are
real and some are placeholders. **First on paper, then in the YAML.**

**5a. Fill in section 6 of the strategy** — `/test-strategy` proposes it; check every line:

| Rows | Job | Stage | Today | Real from |
|---|---|---|---|---|
| — | `qa:lint`, `qa:complexity`, `qa:secrets` | check | real | Session 13 |
| CS-001, CS-002, CS-003 | `test` (yours), `scenarios` | test | real | — |
| — | `qa:sast`, `qa:dependencies`, `qa:iac` | test | real | Session 13 |
| CS-004 | `api:local` | test | real **or** planned | today, or when `APP_START` can be set |
| — | `build:image`, `deploy:test` | deploy | planned | Session 15 |
| CS-005 | `verify:smoke` | verify | planned | Session 15 |
| CS-004 | `verify:api` | verify | planned | Session 15 |
| CS-006 | `verify:e2e` | verify | planned — or no job | Session 15 |
| CS-007, CS-008 | `verify:perf` | verify | planned | Session 15 |
| merge rows | `confidence:merge` | .post | real | — |
| every row | `confidence:deploy` | .post | planned | Session 15 |

**5b. Make the YAML match the picture** — in `ci/confidence.yml`, at the bottom, the planned jobs look like this:

```yaml
"verify:e2e (planned)":
  extends: .planned
  stage: verify
  variables:
    PLANNED_MEASURE: "e2e.pass_rate"
    PLANNED_WHAT: "one journey the client would notice, in a real browser (only with a web UI)"
    PLANNED_WHEN: "Session 15"
```

- **A row your strategy ruled out** (no web UI → no CS-006)? **Delete** its planned job. The reason is already in
  "Not automated yet".
- **A `planned.<name>` row?** Copy any planned job, rename it, and set the three variables — for example:

  ```yaml
  "verify:dast (planned)":
    extends: .planned
    stage: verify
    variables:
      PLANNED_MEASURE: "planned.dast"
      PLANNED_WHAT: "a scan of the running app for the OWASP top risks"
      PLANNED_WHEN: "Session 16"
  ```
- **CS-004 at merge** (your app starts in the job)? Then `api:local` runs for real — and so does your collection.
  Replace the starter's two `FR-0nn` requests: **`/api-tests specs/<slice>`** writes the health check and one
  requirement (happy path **and** a failure path), each test named after its ID. Run it locally as in step 3 —
  green before you push. No time? Delete the two `FR-0nn` starter requests: `SMOKE` alone is still a real check.

Never make a planned job pass. It ends with exit code 3, which GitLab shows **orange** — "allowed to fail, did not
succeed". That is the truth: the check does not exist yet.

**5c. Check the picture and the YAML agree:**

```bash
<lab>/check-testing.sh ~/work/group-1          # PowerShell: <lab>/check-testing.ps1 -Path "C:\work\group-1"
```

Section 5 must say *"Every row has a job, every job a row"*. It names any row without a job and any planned job
without a row. Commit: `ci: the pipeline drawn from the strategy - real and planned jobs`.

---

## Step 6 · Run it, and read it against the strategy (20 min)

**6a. Push and validate:**

```bash
git -C ~/work/group-1 push -u origin setup/layer-5 -o merge_request.create -o merge_request.target=main
```

**Build → Pipeline editor**, branch `setup/layer-5`: *"Pipeline syntax is correct"*. Open **Visualize** — that is
your whole test design, stage by stage. Compare it with section 6 of the strategy, line by line.

**6b. Read the pipeline run** (merge request → **Pipelines** → the pipeline):

| You see | It means |
|---|---|
| **Green** jobs | Real checks that passed — the Session 13 gates, your `test`, `scenarios`, `api:local` if real |
| **Orange** `(planned)` jobs | Designed, not built. Click one: the log names the measure and when it becomes real |
| **Red** job | A real check failed — that is information. `/analyse-failure <job>` before you change anything |
| `confidence:thresholds` (first job) | Its log prints **your** numbers — `COVERAGE_MIN=64.2` and so on. Not yours? The pipeline did not read your strategy: check the file path and the table format |
| `confidence:merge` (last job) | **The scorecard** — merge request → *Confidence*, or the job's artifacts → `confidence.md` |

**6c. Read the scorecard row by row** — the debrief asks you to:

| Result | Meaning | Do |
|---|---|---|
| `met` | Measured, and inside the threshold | — |
| **MISSED** | Measured, outside the threshold | Fix the code or the test; never the threshold. `/analyse-failure` |
| **NOT MEASURED** | No report reached the scorecard | The `test` job's artifact paths (`stacks.md` §2); `api:local` did not run |
| **NOT SET** | The threshold is a placeholder or `[NEEDS CLARIFICATION]` | Measure it (step 3), or get the decision |
| *after deploy* | A deploy row — its job is planned until Session 15 | — |
| *planned — not built yet* | A `planned.<name>` row | — |

**6d. Prove the scorecard can say no** — on your laptop, not in git: delete one test, rerun the tests with
reports and `python3 ci/confidence.py --when merge`. **CS-002 is MISSED** — the ratchet caught a shrinking suite.
Put the test back (`git checkout -- <file>`). A scorecard you have never seen fail has not proved anything.

**6e. Merge.** Real jobs green, planned jobs orange, `confidence:merge` says **CONFIDENT** on the merge rows: a
groupmate approves, merge. From now on every merge request carries a scorecard.

```bash
<lab>/check-testing.sh ~/work/group-1        # sections 1, 2, 3 and 5 in - section 4 is Session 15
```

---

## Done looks like

- [ ] `specs/design/test-strategy.md` — risks, layers, *not automated yet*; every threshold measured, from an NFR, or `[NEEDS CLARIFICATION]` with a name
- [ ] Section 6 — every row, its job, real or planned, and when it becomes real
- [ ] The pipeline view matches section 6: real jobs green, planned jobs orange, none missing, none extra
- [ ] `confidence:thresholds` printed your numbers; `confidence:merge` says CONFIDENT on the merge rows
- [ ] You saw the scorecard say MISSED once, on purpose
- [ ] Merged to `main`

## In Session 15

Every orange job becomes real: `CONFIDENCE_DEPLOY: "on"` replaces the planned deploy-and-verify jobs with the real
ones on `main`. Before then — the homework:

- Every `[NEEDS CLARIFICATION]` threshold answered by whoever owns the NFR.
- Your API collection: every requirement in the slice, happy and failure path (`/api-tests`).
- Install k6 — and Playwright if your strategy has CS-006.

## If something goes wrong

| Symptom | Fix |
|---|---|
| `confidence.py`: *No specs/design/test-strategy.md* | Run it from the repo root, or pass `--strategy <path>` |
| `confidence.py`: *unknown measure* | A typo in the Measure column — the allowed names are in the template's section 5, or `planned.<name>` |
| `confidence.py`: *no 'Confidence thresholds' rows* | The table lost its format: `| CS-001 | … | merge |`, one row per line |
| Measured is `-` for tests or coverage | No report in the repo root — rerun step 2's check with `CI_PROJECT_DIR` set |
| `confidence:thresholds` shows the template's numbers | You pushed before committing the strategy, or edited a copy in another folder |
| `api:local`: *The app did not answer on /health* | `app.log` in the job's artifacts: wrong `APP_DIR`, wrong port, or the app needs a database — then empty `APP_START` and make CS-004 a deploy row |
| `api:local` red on `FR-0nn` | The starter requests are still in the collection — step 5b |
| A `(planned)` job is green | Someone changed its script. A placeholder must never pass — restore `exit 3` |
| No orange jobs at all | `CONFIDENCE_DEPLOY` is `"on"` — set it back to `"off"` until Session 15 |
| Pipeline: *jobs ... (planned) ... stage verify does not exist* | `stages:` lacks `verify` — `stages: [check, test, deploy, verify]` |
| `check-testing`: *has no row in the strategy* | Add the row, or delete the planned job and say why under "Not automated yet" |
