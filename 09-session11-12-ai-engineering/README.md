# Sessions 11 and 12 · Layer 3 — make it work

Layer 1 said **what** to build. Layer 2 gave the code a **shape**. Layer 3 builds the rest of the
slice so that it works end to end — with the assistant in every part of the loop: planning,
building, debugging, documenting and reviewing. And in Session 12 you add one AI-assisted feature
to the product itself.

Two promises hold for both sessions:

1. **You own every line.** The assistant plans, writes, reviews and explains. People approve the
   plan, read the diff, decide every review finding, and merge.
2. **The AI suggests; a person decides** — in the way you build, and in the product you build.

See [`../BUILD-ROADMAP.md`](../BUILD-ROADMAP.md) for where this layer sits. Tag at the end of
Session 12: **`L3-working`**.

## Before you start

Your repository should carry the tag `L2-design`. Check it:

```bash
../08-session10-excellence/check-excellence.sh ~/work/group-1          # last section: READY?
```

Not there yet? Merge what you have, tag it `L2-design`, and log the rest as debt. Layer 3 starts
from a tag, not from a laptop.

## Part A · Set up (once per group, at the start of Session 11)

**1. Add the layer-3 files** — one person runs it, everyone else pulls:

```bash
cd path/to/azure-labs/09-session11-12-ai-engineering
chmod +x *.sh                                          # first time only
./setup-ai-engineering.sh ~/work/group-1
git -C ~/work/group-1 switch -c setup/layer-3
git -C ~/work/group-1 push -u origin setup/layer-3 -o merge_request.create -o merge_request.target=main
```
```powershell
./setup-ai-engineering.ps1 -Path "C:\work\group-1"
git -C "C:\work\group-1" switch -c setup/layer-3
git -C "C:\work\group-1" push -u origin setup/layer-3 -o merge_request.create -o merge_request.target=main
```

It adds the AI review job (`ci/ai-review.yml`), the seven layer-3 commands, templates and the
CLAUDE.md section, and makes **one commit**. It never overwrites a file you wrote.

**2. Give the pipeline its two variables** — your group's **Maintainer** does this, in GitLab:
*Settings → CI/CD → Variables → Add variable.* Tick **Masked**. Do **not** tick *Protected* —
protected variables are hidden from feature branches, and the review would silently never run.

| Variable | What it is | How to get it |
|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | Lets the pipeline run Claude Code as one of you | That person runs `claude setup-token` on their laptop and pastes the token. **Only if your organisation allows its licence to be used on this GitLab.** If you are not sure, ask first — and use the laptop route below until you know |
| `GITLAB_REVIEW_TOKEN` | Lets the review post its findings as threads | *Settings → Access tokens* → role **Developer**, scope **api**, expiry the last day of the programme |

**3. Watch it work** on the setup merge request: the pipeline runs, the AI review posts its
findings as threads. A groupmate reads them, resolves them, and merges.

**No token for the pipeline?** The review still happens — on a laptop. Run `/review-mr` in Claude
Code, then post its findings with a personal access token (scope `api`):

```bash
GITLAB_URL=https://gitlab.stackroute.in PROJECT=mindsprint-group1/<project> MR_IID=<number> \
GITLAB_REVIEW_TOKEN=<your token> node ci/post-review.mjs ai-review.json
```

### Three keys, three places — never mix them up

| Key | Used by | Lives |
|---|---|---|
| Your Claude Code login | You, on your laptop | On your laptop. Nowhere else |
| `CLAUDE_CODE_OAUTH_TOKEN` | The pipeline's AI review | A masked CI/CD variable. Never in a file |
| An API key for the **product's** AI feature (Session 12) | Your running application | The environment (`.env`, not committed). A Claude Code login token is for the coding tool — not for running a product |

`check-ai-engineering` **fails** if any of them is committed. If one ever is: revoke it first,
then remove it. Removing it from the file does not remove it from history.

## Part B · Session 11 — the assistant across the loop

| # | Step | Time | Do this |
|---|---|---|---|
| 1 | **Set up and see it work** | 15 min | Part A. Merge the setup merge request through the gate |
| 2 | **Pair up, pick tasks** | 5 min | Pairs take the next tasks from `tasks.md`, the rule and the failure paths first |
| 3 | **The task loop — twice** | 35 min | For each task: plan → approve → build → read the diff → commit → push → review → merge (below) |
| 4 | **Bug drill** | 10 min | A real failure from step 3 — or the drill in `examples/society-dues/bug-drill/`. `/debug-evidence` |
| 5 | **Docs and trace** | 5 min | README "How to run" still true? `/spec-trace` — which requirements now have code and tests? |

### The task loop

```bash
git switch main && git pull
git switch -c 001/T009-upi-receiver                     # one branch per task
```

1. **Plan** — `/task-plan specs/001-… T009`, or write a prompt card (`templates/prompt-card.md`).
   Read the plan. **Change it or stop it before any code exists** — the cheapest review there is.
2. **Build** — `/task-build specs/001-… T009`. The test fails first, then passes. Docs change in
   the same diff.
3. **Read the diff** — `git diff`. Not the assistant's summary of it.
4. **Commit and push** — `T009: UPI receiver (FR-001)`, then push with
   `-o merge_request.create -o merge_request.target=main -o merge_request.title="Draft: T009 …"`.
5. **Review** — the pipeline runs your tests and the AI review. Every finding arrives as a thread.
6. **Decide every thread** — reply *fix*, *debt* (TD-…) or *overruled* (with a reason). Fixes are
   new commits on the same branch.
7. **Merge** — mark the merge request Ready. A groupmate — never the author — reads the diff, resolves
   what is settled, approves and merges. Tick the task in `tasks.md` in the same merge request.

### The merge gate

| Who | Does |
|---|---|
| The pipeline | Runs the tests. Runs the AI review and posts each finding as a thread |
| The author | Answers every thread: fix, debt or overruled — with a reason |
| A groupmate | Reads the diff, resolves the threads, approves, merges |
| GitLab | Refuses to merge until the pipeline passes and every thread is resolved |

The assistant never approves and never merges. It cannot — and it should not.

### Prompting with ownership

A prompt you would be happy to show your lead has five parts: **context** (which files), **task**
(one task ID), **limits** (stack, component, the rule most likely to break), **done when** (the test
that proves it) and **ask first** (what it must not guess). `templates/prompt-card.md` is the shape;
`examples/society-dues/prompt-card-T010.md` is a real one.

### Debugging with evidence

Reproduce it. Quote the real error. Prove one cause with the smallest experiment. Write the test that
fails because of the bug. Then the smallest fix. **Paste the evidence, not your theory** — an
assistant given a theory will happily prove it.

## Part C · Session 12 — validate it, then add the AI feature

| # | Step | Time | Do this |
|---|---|---|---|
| 1 | **Validate** | 20 min | `/validate-ai-code specs/001-…` from `L2-design`. It runs your tools and looks through four lenses. **Decide every finding.** The *must*s become merge requests |
| 2 | **Spec the AI feature** | 15 min | `/spec-ai-feature specs/001-… "<what the AI should help with>"`. Answer its three questions as a group. Eval set from the evidence. Merge the spec change first |
| 3 | **Build it behind a port** | 25 min | `/build-ai-feature specs/001-…`. Every guardrail tested with a fake. The real adapter only by configuration |
| 4 | **Merge and tag** | 10 min | Through the gate. Tag `L3-working` on `main`. Run `check-ai-engineering` |

### The four lenses

| Lens | Ask of every AI-written change |
|---|---|
| **Correctness** | Does it do what its requirement says? Every *If* row covered? Can each test actually fail? |
| **Security** | Secrets? Input used unchecked? Data leaving the system? Instructions hidden in input? |
| **Maintainability** | The engineering rules, the direction rule, code no task asked for |
| **Compliance** | The C- rules — nothing deleted that must be kept, no data where it must not go, no library without an ADR |

### The AI feature — five rules

1. **The AI suggests; a person decides.** No suggestion changes a record until someone accepts it,
   and the record says who.
2. **Spec first.** Requirements, *If* rows (AI down; answer not allowed; instructions in the input),
   a data rule for what may leave the system, and an eval set from the evidence.
3. **Behind a port.** Only one file knows a model exists. Everything else is tested with a fake.
4. **Never trust the answer.** Anything outside the allowed values is thrown away. A failure means
   "no suggestion", not a crash.
5. **The eval set is its test.** Clear cases, unclear ones where the right answer is "no
   suggestion", and at least one that tries to give the model instructions.

No API key for the product? Build and test everything with the fake, and show the eval set as the
test you would run. That is a complete layer 3.

## Part D · Check your work

```bash
./check-ai-engineering.sh ~/work/group-1
```
```powershell
./check-ai-engineering.ps1 -Path "C:\work\group-1"
```

| Check | Why |
|---|---|
| AI review in the pipeline; a test job with a junit report | The gate needs both |
| No token or key committed | **Fails** if found — revoke first, then remove |
| Merges in layer 3; code commits name tasks; tasks ticked | Work arrives task by task, through the gate |
| README and `trace.md` changed in layer 3 | Docs move with the code |
| Eval set: six examples or more, a guardrail example, every example sourced | The AI feature's rule examples |
| *If* rows in the spec; a fake in the tests; `.env.example` | Guardrails, tested without a model |
| Validation: four lenses, real tool results, every finding decided | People decide |
| Tag `L3-working` | Layer 4 starts from it |

## The worked example

`examples/society-dues/` — the same invented society. A prompt card that stopped a bad plan; a bug
the tests did not catch; the AI feature written as requirements first; the suggester behind a port
with every guardrail tested by a fake; an eval set with an example that tries to instruct the model;
and a validation that caught the first draft deleting records and sending a payer's name out. Read it
**after** your own attempt.

```bash
cd examples/society-dues/code && pip install -r requirements.txt && python -m pytest -q
```

## Homework

**After Session 11 (reading only, twenty minutes):** your own merge requests — which AI review
thread did you overrule, and would you still? Then `examples/society-dues/prompt-card-T010.md`.

**After Session 12 (reading only, twenty minutes):** your validation and eval set. Which eval example
are you least sure about — and who in the client's team could tell you the right answer?
