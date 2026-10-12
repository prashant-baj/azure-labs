# Session 10 · Layer 2 — code other people can live with

Layer 1 (Session 9) said **what** to build. Today you add layer 2: **how the code is shaped** — and
you do it the way real teams do. The assistant writes a first version quickly. Then you review it
against rules you agreed, and refactor it until someone else could live with it.

Two promises for today:

1. **The spec changes first.** Your engineering rules go into the constitution and your components
   into the plan *before* any code is generated.
2. **The assistant generates; people decide.** It proposes code and findings. Your group decides
   every finding — fix it, log it as debt, or overrule it with a reason — and a groupmate approves
   the merge.

See [`../BUILD-ROADMAP.md`](../BUILD-ROADMAP.md) for where this layer sits.

## Today's TO-DO — update your specs from this lab

Tick these in order. Steps 3–5 change **your specs** before any code is generated.

- [ ] **1. Get the lab** (from GitHub) — `git -C path/to/azure-labs pull`
- [ ] **2. Add the layer-2 files to your case repo** (on GitLab) — Part A below, then `git push`
- [ ] **3. Read the principles** — [`principles/`](principles/): clean code and the five SOLID
      folders. Skim as a group in class (the full read is homework). Each folder ends with
      *"In your constitution"*
- [ ] **4. Update `constitution.md` §5** — `/spec-engineering-rules`. Keep **five to seven** rules,
      each with *Checked by*. Optional rows from [`principles/in-your-constitution.md`](principles/in-your-constitution.md)
      only if your spec has the situation. Add a change-log row. Commit `spec: engineering rules`
- [ ] **5. Update `plan.md` §12** — read [`patterns/README.md`](patterns/README.md) (pick by the
      situation, not the name), then `/spec-components specs/001-…`. Every pattern names the
      requirement that needs it; "—" is a fine answer. Commit `plan: components` and **push**
- [ ] **6. Generate, review, refactor, merge, tag `L2-design`** — Part B, steps 3–6

### Two repositories, two hosts — how the lab reaches your GitLab repo

| | Lives on | You… |
|---|---|---|
| **This lab** (`azure-labs`) | GitHub — `https://github.com/prashant-baj/azure-labs.git` | **pull** it. Read it, run its scripts. Never push to it |
| **Your case repo** (`mindsprint-groupN/…`) | GitLab — `gitlab.stackroute.in` | commit and **push** your work here, through merge requests |

The two never talk to each other. **Your laptop is the bridge:** `setup-excellence` copies the
templates and commands from your `azure-labs` folder into your case-repo folder and commits them
there. From then on, everything is ordinary work in your GitLab repo.

```bash
git -C ~/work/azure-labs pull                                   # 1 · from GitHub
cd ~/work/azure-labs/08-session10-excellence
./setup-excellence.sh ~/work/group-1                            # 2 · copies into your case repo, one commit
git -C ~/work/group-1 push                                      #     to GitLab
git -C ~/work/group-1 remote -v                                 #     must show only gitlab.stackroute.in
```

**Do not:**

- add GitHub as a remote in your case repo, or push your case repo to GitHub;
- copy the whole `azure-labs` folder (or `principles/`, `patterns/`, `examples/`) into your case
  repo — read them where they are. If you borrow a snippet, it is now **your** code: rename it to
  your glossary, test it, and review it like any other change;
- edit files inside `azure-labs` — your next `git pull` will fight you. Change the copies in your
  case repo instead.

No clone of `azure-labs` yet? `git clone https://github.com/prashant-baj/azure-labs.git` into
your work folder — next to your case repo, not inside it. If GitHub is blocked on your network,
use *Code → Download ZIP* on the GitHub page, or copy the folder from a groupmate.

## Before you start — the minimum bar

Run the Session 9 check on your repository:

```bash
../07-session09-spec/check-spec.sh ~/work/group-1          # macOS / Linux / WSL
```
```powershell
..\07-session09-spec\check-spec.ps1 -Path "C:\work\group-1"   # Windows
```

The last section must say **READY**. If it says **NOT YET**, close the missing lines first — most
often the architecture-and-stack ADR. You cannot generate code without a decided stack. Your group
joins at step 1 as soon as the bar is closed; keep step 3 to fewer tasks.

## What your repository looks like after this lab

```
constitution.md           + section 5: engineering rules, each with how it is checked
specs/
  design/
    tech-debt.md          NEW - what we did not fix, what it costs, when we pay it back
  001-<slice>/
    plan.md               + section 12: components inside the code, and a class diagram
    reviews/
      L2-review.md        NEW - findings with a rule and a line; decisions by the group
<your code and tests>     NEW - on the stack in your ADR
.gitlab/merge_request_templates/Default.md   NEW - the checklist on every merge request
.claude/commands/         + /spec-engineering-rules  /spec-components  /build-tasks
                            /review-excellence  /refactor-step
```

Tag on `main` when it is merged: **`L2-design`**.

## Part A · Set up (once per group, two minutes)

```bash
cd path/to/azure-labs/08-session10-excellence
chmod +x *.sh                                   # first time only
./setup-excellence.sh ~/work/group-1
git -C ~/work/group-1 push
```
```powershell
cd "path\to\azure-labs\08-session10-excellence"
./setup-excellence.ps1 -Path "C:\work\group-1"
git -C "C:\work\group-1" push
```

It adds the templates, the five commands, the merge request checklist and the debt register, and
makes **one commit**. It never overwrites a file you wrote. Everyone else pulls.

## Part B · The workshop

| # | Step | Time | Do this | Commit |
|---|---|---|---|---|
| 1 | **Rules** | 12 min | Skim `principles/`. `/spec-engineering-rules`. Read the proposals together; keep **five to seven** you will actually check | `spec: engineering rules` |
| 2 | **Components** | 10 min | Skim `patterns/README.md`. `/spec-components specs/001-…`. Read every "one job". If it needs "and", split it | `plan: components` |
| 3 | **Generate** | 12 min | New branch, then `/build-tasks specs/001-… T001-T005` (your first few tasks). Run the tests yourselves. Push and open a **Draft** merge request | one per task: `T002: …` |
| 4 | **Review** | 12 min | `/review-excellence specs/001-…`. Read it as a group. Add what it missed. Decide every finding | `review: layer 2 findings decided` |
| 5 | **Refactor** | 16 min | `/refactor-step specs/001-… <n>` — every **must** first. Tests pass without being edited. What you cannot fix today goes to `tech-debt.md` | one per finding: `refactor: … (E-002, finding 2)` |
| 6 | **Merge and tag** | 8 min | Mark the MR **Ready**. A groupmate — not the author — reviews with the checklist and merges. Tag `L2-design`. Run `check-excellence` | — |

Steps 1 and 2 are spec changes: commit them on `main` before you branch. From step 3 everything
arrives on `main` through the merge request.

### The rule for this session

**The assistant generates and reviews. People decide.** Every finding names a rule and a place —
`E-006, payments.py:55`. A finding with no rule is deleted. Nobody fills the *Decision* column but
the group, and the person who merges is never the person who wrote the code.

### Branches, commits and the merge request

```bash
git switch -c 001/T002-rule-examples                    # slice / first task / a few words
# ... /build-tasks, run the tests, then one commit per task:
git add -A && git commit -m "T002: rule examples as one table test (RULE-001)"
git push -u origin 001/T002-rule-examples \
  -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="Draft: layer 2 - first tasks"
```

The push prints a link to the merge request. The checklist from
`.gitlab/merge_request_templates/Default.md` appears in its description. Push more commits to the
same branch as you review and refactor — the merge request updates itself.

When it is merged:

```bash
git switch main && git pull
git tag L2-design && git push origin L2-design
```

### Deciding a finding

| Decision | When | Write |
|---|---|---|
| **fix** | It breaks a W- rule, hides a failure, or is cheap to put right now | `fix` — then `/refactor-step` |
| **debt** | Real, but not today — and you can say when | `debt — TD-00n`, and a row in `specs/design/tech-debt.md` with *Pay back by* |
| **overruled** | You disagree, and you can say why | `overruled — <the reason, with a source>` |

An overrule with a good reason is a sign of a working team, not of a lazy one. An overrule with no
reason is a lazy one.

### Refactoring safely

1. **Pin the behaviour.** The rule examples from your spec are already a test — run them, green.
   If a finding touches code no test covers, `/refactor-step` writes one first. Commit it.
2. **One finding, one small change.** Not five at once.
3. **Run the tests.** They must pass *without being edited*. If a test has to change, that was not a
   refactoring — stop and talk.
4. **Commit**, naming the rule and the finding.

### If not everybody has Claude access

Same as before: whoever has it is the **driver**, shares the screen, types what the group decides.
Without Claude Code, `prompts/10-excellence.md` explains how to use the command text by hand.

## Part C · Check your work

```bash
./check-excellence.sh ~/work/group-1
```
```powershell
./check-excellence.ps1 -Path "C:\work\group-1"
```

| Check | Why |
|---|---|
| Constitution section 5: rules, each with *Checked by* | A rule nobody checks is a wish |
| Plan section 12: components, one job each, a class diagram | One change should stay in one place |
| Code and tests; tests named after requirement IDs | W-003, E-009 |
| No obvious secret, no catch-all that hides errors | W-004, W-006 — the pipeline scan goes deeper |
| A review where every finding has a rule and a decision | People decide, not the assistant |
| Debt items each have *Pay back by* | Debt with no date is a surprise |
| Code commits name a task or a finding; work arrived through a merge | W-002; the merge request is where review happens |
| Tag `L2-design`, pushed | The next layer starts from here |

The last section, **Ready for layer 3?**, says `READY` or `NOT YET`.

## Stretch — make the rules run by themselves

Copy the starter for your stack from `ci/` to the root of your repository as `.gitlab-ci.yml`:

| Stack | Starter |
|---|---|
| Python | `ci/python.gitlab-ci.yml` |
| Java (Maven) | `ci/java-maven.gitlab-ci.yml` |
| Node / TypeScript | `ci/node.gitlab-ci.yml` |

Each runs the formatter and linter (your E- rules), a secret scan, and the tests — with results
shown in the merge request. Ask the facilitator which runner tag to use. A rule in the pipeline beats
a rule in a reminder.

## Principles and patterns — reference you can run

| Folder | What is in it |
|---|---|
| [`principles/clean-code/`](principles/clean-code/) | Six habits on one before/after example, with a test that proves the answers did not change |
| [`principles/solid/`](principles/solid/) | One folder per SOLID principle — problem, fix, smell, review tip, the constitution rule |
| [`principles/in-your-constitution.md`](principles/in-your-constitution.md) | Rows you can copy into §5, with *Checked by* — and when not to |
| [`patterns/`](patterns/) | Adapter, Strategy, Repository, Use case, Publisher — when to use, when **not** to, the plan §12 row, the rule, the misuse smell |
| [`patterns/patterns-in-plan-and-constitution.md`](patterns/patterns-in-plan-and-constitution.md) | Step by step: from your spec to the *Pattern* column and a class diagram |

```bash
pip install pytest ruff
python -m pytest -q principles patterns        # every example has a test
```

Python because it is short to read; the ideas are the same in Java, Node or .NET. These folders
stay in `azure-labs` — read them here, do not copy them into your case repo.

## The worked example

`examples/society-dues/` — the same invented housing society as Session 9. Code that works and is
still hard to live with (`before/`), the review with the group's decisions, the refactored code that
gives the same answers to the same rule examples (`after/`), and the debt register. Read it **after**
your own review — it shows the shape, not your answers.

## Homework — before the next session (about thirty minutes, reading only)

| # | Look at | Notice |
|---|---|---|
| 1 | Your own `reviews/L2-review.md` | Which finding would you decide differently today, and why? |
| 2 | `examples/society-dues/before/` then `after/` | The rule now runs without a database. What made that possible? |
| 3 | Your `tech-debt.md` | Is every *Pay back by* honest? |
| 4 | One `principles/solid/` folder and one `patterns/` folder | Find the smell in **your** code — or decide, with a reason, that it is not there |
