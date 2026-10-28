# Session 13 · Layer 4 — quality first: set the bar, prove the behaviour

Layer 3 made the slice **work**. Layer 4 makes quality something you can **see and enforce**, in two places:

1. **Quality gates.** Lint, complexity, secrets, static analysis, vulnerable dependencies and infrastructure
   misconfiguration — scanned first **in your workspace**, written into **the spec** as gates with a rule
   and a threshold, and then enforced by **the pipeline** on every push. That is your baseline CI.
2. **Behaviour.** The rules are talked through as examples, written as stories and acceptance criteria, turned
   into scenarios the client could read — and those scenarios **run**. The one rule that needs judgement is
   built test-first.

> Quality is not a phase at the end. It is a habit at the start: a gate agreed before the code, and an
> example agreed before the test, are the cheapest bugs you will ever fix.

This session introduces both. **Sessions 14 and 15 go deep** — test strategy, coverage, API and end-to-end
tests, regression and AI-suggested tests in the same pipeline you build today.

See [`../BUILD-ROADMAP.md`](../BUILD-ROADMAP.md). Tag at the end: **`L4-behaviour`**.
The demo can now say: *"Every push is checked against our quality bar — and the spec runs, as tests."*

## Today's TO-DO

| # | Do | Who | Time |
|---|---|---|---|
| 0 | `git pull` this repository (azure-labs) — this folder is new. Install the scanners (table below) | everyone | before |
| 1 | **Set up**: `setup-quality` on a branch; wire the BDD runner for your stack | driver + Maintainer | 10 min |
| 2 | **Scan in your workspace, write the gates**: `quality-local`, then `/quality-gates` | whole group | 10 min |
| 3 | **The pipeline**: push, read every red job, `/triage-findings`, set the baselines, merge | whole group | 10 min |
| 4 | **Example map** one story — the rule that needs judgement, plus one *If* row | whole group | 10 min |
| 5 | **Spec first, then stories**: `/spec-stories` — decide every diff | whole group | 10 min |
| 6 | **Scenarios, red**: `/spec-scenarios` — read one aloud; run them; see them fail | whole group | 5 min |
| 7 | **TDD the rule**: `/tdd-cycle`, one example per cycle — then check, merge, tag | pairs | 10 min |

**Setting up CI for the first time, or stuck?** [`CI-SETUP.md`](CI-SETUP.md) walks through it on your own case
repo: install the tools, the lint configuration for your stack, the local loop before every push (with an
optional pre-push hook), and the GitLab pipeline click by click.

**Two repositories, as before:** this lab (azure-labs, GitHub) is pull-only. Your case repo (GitLab) is where you
push. `setup-quality` on your laptop is the bridge. Never copy `examples/` or `stacks/` into your case repo.

## Before you start

Your repository should carry the tag `L3-working` (`git tag --list 'L3-*'`). Not there yet? Merge what
works, tag it, log the rest as debt. Layer 4 starts from a tag.

**Install the scanners on at least two laptops per group** — the pipeline runs them anyway; locally you find
things before anyone else does:

| Gate | Tool | macOS / Linux / WSL | Windows |
|---|---|---|---|
| Lint, format | your stack's — ruff · ESLint + Prettier · Spotless + Checkstyle | as in Session 10 | as in Session 10 |
| Complexity | lizard | `pip install lizard` | `pip install lizard` |
| Secrets | gitleaks | `brew install gitleaks`, or the release binary | release `.zip` from github.com/gitleaks/gitleaks, on your PATH |
| Static analysis | semgrep | `pip install semgrep` | in WSL, or Docker: `docker run --rm -v "${PWD}:/src" semgrep/semgrep:1.182.1 semgrep scan --config p/default /src` |
| Dependencies | osv-scanner | `brew install osv-scanner`, or the release binary | release `.exe` from github.com/google/osv-scanner, on your PATH |
| Infrastructure | checkov | `pip install checkov` | `pip install checkov` |

Missing one? `quality-local` says *skipped* and tells you how to get it. The pipeline still runs it.
Exact install commands for each OS, including Windows: [`CI-SETUP.md`](CI-SETUP.md), section 0.

**No lint configuration in your repo yet?** `qa:lint` needs one. Tested starters for ruff, ESLint + Prettier and
Spotless + Checkstyle are in [`lint-config/`](lint-config/) — [`CI-SETUP.md`](CI-SETUP.md), section 1, before you push.

## Part A · Set up (once per group, 10 minutes)

**1. Add the layer-4 files** — one person, on a fresh `main`:

```bash
git -C ~/work/group-1 switch main && git -C ~/work/group-1 pull
cd path/to/azure-labs/10-session13-quality
chmod +x *.sh                                       # first time only
./setup-quality.sh ~/work/group-1                   # finds your stack; add  python|node|java <app-folder>  if it guesses wrong
```
```powershell
git -C "C:\work\group-1" switch main; git -C "C:\work\group-1" pull
./setup-quality.ps1 -Path "C:\work\group-1"         # -Stack python|node|java -App <folder>  if it guesses wrong
```

It creates the branch `setup/layer-4` and makes **one commit** with:

| Adds | What for |
|---|---|
| `ci/quality.yml` | **The baseline quality pipeline** for your stack — `qa:lint`, `qa:complexity`, `qa:secrets` (stage `check`), `qa:sast`, `qa:dependencies`, `qa:iac` (stage `test`). Every tool pinned to a version |
| `ci/scenarios.yml` | The BDD scenarios as their own job, with a test report in the merge request |
| `.gitlab-ci.yml` | Both included; stages `check` and `test` made sure of |
| seven commands, templates | `/quality-gates`, `/triage-findings` and the five behaviour commands; `templates/quality-gates.md` and the rest |
| `specs/<slice>/features/`, `.claude/bdd-starter/` | Where your scenarios live; a runnable starter for your stack |
| `.gitignore`, `CLAUDE.md` | Local scan output stays local; the layer-4 rules for the assistant |

It never overwrites your files and never touches your build files. **If it warns that your `.gitlab-ci.yml`
still has the Session 10 jobs `lint:` and `secrets:`** — delete them in this branch: `qa:lint` and
`qa:secrets` replace them. Two jobs for one gate drift apart.

**2. Wire the BDD runner into your build** — the one manual step: *Wire it into your repo* in
[`stacks/python`](stacks/python/README.md), [`stacks/node`](stacks/node/README.md) or
[`stacks/java`](stacks/java/README.md). Commit it on the same branch. **Do not push yet** — step 2 first.

## Part B · Quality gates — workspace, spec, pipeline (20 minutes)

### Step 2 · Scan in your workspace, then write the gates into the spec (10 min)

```bash
./quality-local.sh ~/work/group-1                    # or: ./quality-local.ps1 -Path "C:\work\group-1"
```

Six gates, the same ones the pipeline runs: **lint**, **complexity**, **secrets**, **static analysis**,
**dependencies**, **infrastructure**. Each says *clean*, a count, or *skipped* with how to install the tool.
The counts land in `.quality/local-report.md` (never committed).

Then in Claude Code: **`/quality-gates`**. It writes `specs/design/quality-gates.md` from the template — and asks:

- **Which rule does each gate enforce?** Lint → E-010, E-006. Complexity → E-003. Secrets → E-008, W-004. A gate
  with no rule behind it is a habit, not a decision — add the rule to the constitution first.
- **What threshold?** The complexity limit is the number in **your** E-003, not a default.
- **Does it block?** The baseline policy:

| Blocks the merge from today | Ratchet — today's count is the baseline; it may only go down |
|---|---|
| lint errors · any secret · static-analysis findings of severity ERROR · known-vulnerable dependencies · failing tests and scenarios | functions above the complexity limit · failed infrastructure checks |

Then it shows the matching `variables:` for `ci/quality.yml` — `QA_COMPLEXITY_LIMIT`, `QA_COMPLEXITY_BASELINE`,
`QA_IAC_BASELINE`. **The spec first, then the pipeline.** Commit: `spec: quality gates QG-001..QG-007 with today's baseline`.

### Step 3 · The pipeline — push, read, triage, merge (10 min)

```bash
git -C ~/work/group-1 push -u origin setup/layer-4 -o merge_request.create -o merge_request.target=main
```

Check the YAML in **Build → Pipeline editor**, then open the merge request → **Pipelines** — where to look
and what each job runs locally: [`CI-SETUP.md`](CI-SETUP.md), section 3. Expect red on the first run — **that is the point**: the gates found something nobody had
looked for. For every red job, read the log, then **`/triage-findings <gate>`** — one finding at a time:

| Decision | When | How |
|---|---|---|
| **Fix** | Almost always | The smallest change, and the test that proves it |
| **False positive** | The tool is wrong *here* | Suppress on that line only, with the reason in the comment. A second person agrees |
| **Accepted risk** | Real, but a constraint forces it (the lab policy) | Inline skip with the reason + a row in *Accepted findings* with a review date |
| **Debt** | Real, not today | `specs/design/tech-debt.md`; the ratchet baseline holds it |

**A real secret is never accepted.** Revoke it first, then remove it, then tell your facilitator.

Green? A groupmate approves, merge. From now on **every** merge request runs the gates. Lint findings appear
in the merge request (*Code Quality*); everything else in the job logs.

## Part C · Behaviour — examples, scenarios, test-first (35 minutes)

Read [`examples/society-dues/`](examples/society-dues/README.md) first if you have five minutes — it is
the whole workshop, done once, on an invented case.

### Step 4 · Example map one story (10 min)

Pick **the rule in your spec that needs judgement** (§5) and one *If … then* requirement. One person runs
`/example-map specs/<slice> <ID>`; everyone else talks. **Yellow** — the story. **Blue** — the rules.
**Green** — examples. **Red** — questions. Nobody knows the outcome? A red card with who can answer — never a
guess. Many red cards: not ready. Many blue: split it.

### Step 5 · Spec first, then stories (10 min)

`/spec-stories specs/<slice>` — it stops for your yes after each: **the spec** (new rule rows; questions
closed, recorded, opened), then **stories** (*As / I want / so that*, **Delivers:** the IDs), then
**acceptance criteria** (Given / When / Then, each naming what it **proves**). Commit each.

### Step 6 · Scenarios — and see them red (5 min)

`/spec-scenarios specs/<slice> US-0nn` writes `specs/<slice>/features/<story>.feature`: every scenario tagged
`@FR-0nn @RULE-0nn`; the rule's examples as one `Scenario Outline` whose rows are the spec's rows, word for word;
business words only. **Read one aloud** — would the client say *"yes, that is what I meant"*? Run them: red.

### Step 7 · TDD the rule — then check, merge, tag (10 min, in pairs)

`/tdd-cycle specs/<slice> RULE-0nna` — one example per cycle, one commit per step:
**red** (`test: … (red)` — failing on the assertion, not an import) → **green** (`feat: … (green)` — the
simplest code) → **refactor** (`refactor: …` — tests unchanged). Then thin step definitions; the scenarios go
green — and the quality gates run on the same push.

```bash
./check-quality.sh ~/work/group-1                     # last section: READY?
git -C ~/work/group-1 switch main && git -C ~/work/group-1 pull
git -C ~/work/group-1 tag L4-behaviour && git -C ~/work/group-1 push origin L4-behaviour
```

Not finished? Push the branch. Two examples built test-first and the gates green is a good session.

## Commands (layer 4)

| Command | What it does |
|---|---|
| `/quality-gates` | Writes `specs/design/quality-gates.md` from your rules and today's local scan; asks about each threshold and policy; then aligns `ci/quality.yml` |
| `/triage-findings <gate>` | One finding at a time: fix, false positive, accepted risk or debt — each with a reason. Never hides one silently |
| `/example-map <slice> <ID>` | Scribe for an example-mapping session. Asks — never answers for the client |
| `/spec-stories <slice>` | Map → spec rule rows and questions → stories → acceptance criteria. Applied on a yes |
| `/spec-scenarios <slice> <US-0nn>` | Gherkin from the AC, tagged with IDs, next to the spec. Runs them red |
| `/tdd-cycle <slice> <example>` | One red–green–refactor cycle. Stops for you between steps. Appends `tdd-log.md` |
| `/review-scenarios <slice>` | BDD smells and ID gaps. Finds; never fixes |

## Done looks like

- [ ] `quality-local` run; `specs/design/quality-gates.md` — every gate names its rule, threshold, policy, baseline
- [ ] `ci/quality.yml` included and green — lint, complexity, secrets, SAST, dependencies (and IaC if you have `infra/`)
- [ ] Every finding triaged — fixed, or suppressed on the line with a reason, or in *Accepted findings* / tech debt
- [ ] `example-map.md`, `spec.md` changed first, `stories.md` with AC naming their IDs
- [ ] `features/*.feature` — every scenario tagged; every rule row has a scenario
- [ ] The rule built test-first — `test:` before `feat:`, and `tdd-log.md`
- [ ] `check-quality` says READY; tag `L4-behaviour` pushed

## The rules of this layer

1. **The spec changes first** — for gates as for behaviour. A threshold is decided in `quality-gates.md`, then the pipeline follows.
2. **Same checks in two places.** Your laptop is where you find it. The pipeline is where nobody can skip it.
3. **Never lower a gate to pass it.** A finding is fixed or triaged, one at a time, with a reason.
4. **Pin your tools.** A scanner on `latest` runs whatever was published last — including by someone who should not have.
5. **Never invent an outcome.** If the client did not say it, it is a question, not an Examples row.
6. **Red first, for the right reason.** A test — or a gate — you never saw fail has not proved anything.

## Homework, before Session 14

- Pin your dependencies (lockfile, or exact versions in `requirements.txt`) — the dependency scan is only as good as the pin.
- Scenarios for the other requirements of the slice — at least every *If … then* row.
- `trace.md`: a **Scenario** column; *none yet* where there is none — Session 14 starts from that list.
- Ask the client your red-card questions.

## If something goes wrong

| Symptom | Fix |
|---|---|
| `qa:secrets` red on `infra/main.tf`, `password_secret_name = "acr-password"` | Not a secret — the *name* of one (from the Session 12 Terraform starter). Triage it as a false positive: `# gitleaks:allow - <reason>` on the line and its fingerprint in `.gitleaksignore` (it is in older commits too) |
| `qa:secrets` red on a real key | Revoke it **first**, then remove it, then tell your facilitator. Deleting the line does not delete it from history |
| `qa:sast`: cannot download rules from semgrep.dev | The runner has no route to it. Tell your facilitator; meanwhile `include: - template: Jobs/SAST.gitlab-ci.yml` (rules bundled in the image) and remove `qa:sast` |
| `qa:dependencies`: *No lockfile or pinned requirements* | Commit `package-lock.json`, or pin `requirements.txt`, or let Maven resolve `pom.xml` — then push |
| `qa:dependencies` red | Upgrade to the fixed version it names, run your tests. No fixed version? Accepted risk with a review date |
| `qa:lint` red on Java: *No plugin found for prefix 'spotless'* | Spotless and Checkstyle are not in your `pom.xml` yet — Session 10, `templates/engineering-rules.md` |
| `qa:iac` many findings on the Container Registry | Most need the Premium SKU or private networking, which the lab does not allow. Triage: accepted risk or debt; set `QA_IAC_BASELINE` |
| `qa:complexity` *No baseline yet* | Working as designed until step 2 is done: write the count in QG-002 and set `QA_COMPLEXITY_BASELINE` |
| Pipeline error: *stage check does not exist* | Your `stages:` list lacks `check` — `stages: [check, test, deploy]` |
| `scenarios` job: *0 scenarios* | The runner does not find the feature files — check the path in your config (stack README) |
| Scenarios pass before any code exists | A step contains the logic, or a Then asserts nothing. `/review-scenarios` finds both |
| `check-quality`: *scenario(s) with no tag* | Tag the scenario — or the whole feature — with the FR or RULE it proves |
