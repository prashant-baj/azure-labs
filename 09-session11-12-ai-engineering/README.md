# Sessions 11 and 12 · Layer 3 — make it work

Layer 1 said **what** to build. Layer 2 gave the code a **shape**. Layer 3 builds the rest of the
slice so that it works end to end — with the assistant in every part of the loop: planning,
building, debugging, documenting and reviewing. Session 11 has the talks and the task loop.
**Session 12 is one long workshop:** check what the assistant wrote, turn it on your **spec** to find
the gaps, and **deploy your work in progress to Azure with Terraform, from the command line** —
without losing ownership.

Two promises hold for both sessions:

1. **You own every line.** The assistant plans, writes, reviews and explains. People approve the
   plan, read the diff, decide every review finding, and merge.
2. **The AI suggests; a person decides** — about the code, and about the spec.

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

> **Step by step, with who clicks what in GitLab: [`SETUP-GATE.md`](SETUP-GATE.md).** The short
> version is below.

**1. Add the layer-3 files** — one person runs it, on a new branch; everyone else pulls later:

```bash
git -C ~/work/group-1 switch main && git -C ~/work/group-1 pull
git -C ~/work/group-1 switch -c setup/layer-3
cd path/to/azure-labs/09-session11-12-ai-engineering
chmod +x *.sh                                          # first time only
./setup-ai-engineering.sh ~/work/group-1
git -C ~/work/group-1 push -u origin setup/layer-3 -o merge_request.create -o merge_request.target=main
```
```powershell
git -C "C:\work\group-1" switch main; git -C "C:\work\group-1" pull
git -C "C:\work\group-1" switch -c setup/layer-3
./setup-ai-engineering.ps1 -Path "C:\work\group-1"
git -C "C:\work\group-1" push -u origin setup/layer-3 -o merge_request.create -o merge_request.target=main
```

It adds the AI review job (`ci/ai-review.yml`), the ten layer-3 commands, templates, the Azure lab
constraints (`specs/design/azure-lab-constraints.md`), the Terraform starter, `.gitignore` lines and
the CLAUDE.md section, and makes **one commit**. It never overwrites a file you wrote.

**2. Give the pipeline its two variables** — your group's **Maintainer** does this, in GitLab:
*Settings → CI/CD → Variables → Add variable.* Tick **Masked**. Do **not** tick *Protected* —
protected variables are hidden from feature branches, and the review would silently never run.

| Variable | What it is | How to get it |
|---|---|---|
| `CLAUDE_CODE_OAUTH_TOKEN` | Lets the pipeline run Claude Code as one of you | That person runs `claude setup-token` on their laptop and pastes the token. **Only if your organisation allows its licence to be used on this GitLab.** If you are not sure, ask first — and use the laptop route below until you know |
| `GITLAB_REVIEW_TOKEN` | Lets the review post its findings as threads | *Settings → Access tokens* → role **Developer**, scope **api**, expiry the last day of the programme |

**3. Gate settings** (Maintainer): protect `main` (Developers may merge, nobody pushes) and tick
*Pipelines must succeed* and *All threads must be resolved* — `SETUP-GATE.md` 1.1–1.2.

**4. Watch it work** on the setup merge request: once the variables are in, push an empty commit
(`git commit --allow-empty -m "ci: run the AI review" && git push`). The AI review posts its findings
as threads. The author answers each; a groupmate approves and merges.

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
| Your Azure sign-in and Terraform state | You and `terraform`, on your laptop | On your laptop. State files can hold secrets — never committed |

`check-ai-engineering` **fails** if any of them is committed. If one ever is: revoke it first,
then remove it. Removing it from the file does not remove it from history.

## Part B · Session 11 — the assistant across the loop

| # | Step | Time | Do this |
|---|---|---|---|
| 1 | **Set up and see it work** | 15 min | Part A. Merge the setup merge request through the gate |
| 2 | **Pair up, pick tasks** | 5 min | Pairs take the next tasks from `tasks.md`, the rule and the failure paths first |
| 3 | **The task loop — twice** | 30 min | For each task: plan → approve → build → read the diff → commit → push → review → merge (below) |
| 4 | **Azure — find the gaps** | 15 min | `/azure-gaps specs/001-…`. Answer its questions **as a group**. Commit `specs/design/azure-gaps.md` |
| 5 | **Push and check** | 5 min | Push every branch. `check-ai-engineering`. Make sure `az`, `terraform` and Docker work on at least two laptops — Session 12 deploys |

The bug drill and the docs-and-trace step are homework this time (below).

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

### The Azure step — gaps first, then Terraform

Your specs say *what* to build. Azure needs to know *where it runs, what it keeps, who may touch it,
and what happens when it fails* — and the lab only allows some of that. Find the gaps **before**
writing infrastructure.

```text
/azure-gaps specs/001-…          # reads your specs + the lab policy, then asks you pointed questions
/azure-terraform specs/001-…     # asks about your component, then writes infra/ - you run apply
```

| `/azure-gaps` gives you | `/azure-terraform` gives you |
|---|---|
| A resource map: every Azure resource your plan implies, checked against the lab policy | `infra/` — versions, variables (validated region), main, outputs, an example `.tfvars`, a README |
| Every gap classified: undecided · policy conflict · requirement with no resource · resource with no requirement · security · operability · cost | One running component on **Container Apps** (with a registry and logs), plus a data store only if you need one on day one |
| Up to eight questions, one at a time, each quoting your spec — **you answer** | The exact commands: `init → fmt → validate → plan → apply`, build and push the image, `curl /health`, `destroy` |

```bash
cd infra && terraform init && terraform fmt && terraform validate
terraform plan -out tfplan        # a person reads it - what will be created, and why?
terraform apply tfplan
```

**Lab rules the commands follow** (from `specs/design/azure-lab-constraints.md`): `eastus` by default;
Container Apps, not App Service or Functions (no quota); no Azure OpenAI; no role assignments (ACR
admin credentials, Key Vault access policies); everything re-creatable — the lab is cleaned about
every four hours. **Never commit** `*.tfstate`, `.terraform/` or `*.tfvars` — `check-ai-engineering`
**fails** if you do. Key Vault with managed identity and deploying from the pipeline come in
Sessions 16–17.

## Part C · Session 12 — one long workshop: trust it, sharpen the spec, ship it

| # | Step | Time | Do this |
|---|---|---|---|
| 1 | **Validate** | 20 min | `/validate-ai-code specs/001-…` from `L2-design`. It runs your tools and looks through four lenses. **Decide every finding.** The *must*s become merge requests |
| 2 | **Strengthen the spec** | 20 min | `/spec-review specs/001-…` — or the prompts in `prompts/spec-enhancement.md`. **Answer its questions as a group.** Apply only the changes you decided |
| 3 | **Deploy to Azure** | 45 min | **[`DEPLOY-EXERCISE.md`](DEPLOY-EXERCISE.md)** — `/azure-terraform`, then `init → plan → apply` from the CLI, your own image on your own URL, a change and a rollback. **The team decides who runs apply** |
| 4 | **Spec and code in step** | 10 min | `/spec-sync specs/001-…`. Requirements with no test, code with no requirement, behaviour the spec never mentions. Decide each |
| 5 | **Merge and tag** | 10 min | Through the gate. Tag `L3-working` on `main`. Run `check-ai-engineering` |

`/improve-component` is there when you have time left — or as homework.

### Deploying to Azure — the short version

```bash
/azure-terraform specs/001-…                    # writes infra/ (from .claude/infra-starter/) - read it
cd infra && terraform init && terraform validate
terraform plan -var prefix=<group> -out tfplan  # a person reads it out loud
terraform apply tfplan                          # the person the team chose
# your image: docker build --platform linux/amd64 + push   (or az acr build)
terraform plan -var prefix=<group> -var image=<acr>/<app>:v1 -var target_port=<port> -out tfplan
terraform apply tfplan && curl -s $(terraform output -raw app_url)/health
```

Six checkpoints, the plan-reading questions, and a troubleshooting table: **`DEPLOY-EXERCISE.md`**.
The known-good Terraform is in `infra-starter/`; a stand-in app (if yours cannot run yet) is in
`sample-app/`. Log every apply in `infra/deployments.md`.

### The four lenses

| Lens | Ask of every AI-written change |
|---|---|
| **Correctness** | Does it do what its requirement says? Every *If* row covered? Can each test actually fail? |
| **Security** | Secrets? Input used unchecked? Data leaving the system? Instructions hidden in input? |
| **Maintainability** | The engineering rules, the direction rule, code no task asked for |
| **Compliance** | The C- rules — nothing deleted that must be kept, no data where it must not go, no library without an ADR |

### Prompts that strengthen the spec

The assistant is a sharp reviewer, not the author. Ask it to **attack** the spec and **ask** — then
decide as a group.

| Ask it to find | You get | Who decides |
|---|---|---|
| **Ambiguity** — *quickly, easily, appropriate, real-time* | The line, why a tester cannot check it, one question | The group — or the client |
| **Untestable requirements** | An EARS rewrite proposed side by side — not applied | The group |
| **Missing failure paths** | The *If* rows a happy path is missing: late, duplicate, malformed, the other system down | The group, with the client |
| **Edge-case examples** | Inputs at the edges, with the expected result left as `???` | The client |
| **Conflicts** | Two lines that cannot both be true — quoted, no winner picked | The group |
| **Evidence not covered** | What a stakeholder said that no requirement covers | The group: this slice, later, or out |
| **Drift** | Spec vs tasks vs tests vs code | The group: spec change, code fix or debt |

`/spec-review` and `/spec-sync` do this with your files. `prompts/spec-enhancement.md` has the same
ten prompts to copy into any assistant. Every finding goes into `reviews/spec-review.md`; every
decided change gets a change-log row in `spec.md`. **Never let the assistant invent a number, a rule
or a client decision** — that is what `[NEEDS CLARIFICATION]` is for.

### Improving a component

Measure first (tests, linter, complexity — real output) → up to three proposals, each tied to a rule
or NFR → the group picks **one** → pin the behaviour with a test → the smallest change → every test
passes **unedited** → before and after, in the merge request. If the improvement would change what
the client sees, stop: that is a spec change first.

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
| `azure-gaps.md`; Terraform in `infra/`; no state, `.terraform/` or `.tfvars` committed | Gaps asked before infrastructure; state can hold secrets — **fails** if committed |
| At least one apply logged in `infra/deployments.md` | Your work in progress ran on Azure, from code |
| Merges in layer 3; code commits name tasks; tasks ticked | Work arrives task by task, through the gate |
| README and `trace.md` changed in layer 3 | Docs move with the code |
| `reviews/spec-review.md`: findings of several kinds, every one decided; `spec.md` changed in layer 3 | The spec got stronger — and people decided how |
| *If* rows in the spec; open `NEEDS CLARIFICATION` items | Failure paths written; open questions visible, with who will answer |
| Validation: four lenses, real tool results, every finding decided | People decide |
| Tag `L3-working` | Layer 4 starts from it |

## The worked example

`examples/society-dues/` — the same invented society. A prompt card that stopped a bad plan; a bug
the tests did not catch; a validation that caught the first draft deleting records; and a spec
review that found an untestable requirement, a missing failure path and a rule with no edge
examples — with the group's decisions. Read it **after** your own attempt.

```bash
cd examples/society-dues/code && pip install -r requirements.txt && python -m pytest -q
```

## Homework

**After Session 11 (about forty minutes):** the bug drill in `examples/society-dues/bug-drill/` with
`/debug-evidence`; your README "How to run" and `/spec-trace`; your own merge requests — which AI
review thread did you overrule, and would you still? **Before Session 12:** `az login`,
`terraform -version` and `docker info` work on the laptop your team will deploy from (see
*Before you start* in `DEPLOY-EXERCISE.md`). If your component has no `Dockerfile`, ask the assistant
for a minimal one — and read it.

**After Session 12 (reading only, twenty minutes):** your spec review. Which finding did you keep
"as is" — and would the client agree? Send the open `NEEDS CLARIFICATION` questions to the person
who can answer them.
