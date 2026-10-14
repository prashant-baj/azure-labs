# Set up the gate — step by step (Session 11, workshop step 1, 15 minutes)

By the end of this page your group has:

- the layer-3 files in your repository (one setup merge request),
- an **AI review** that runs on every push to a merge request and posts each finding as a thread,
- a **gate** on `main`: GitLab will not merge until the pipeline is green and every thread is resolved,
- and you have watched it work once — on the setup merge request itself.

**Worked example used below** (invented): group `mindsprint-group1`, project `society-dues`, three
members — **Asha** (Maintainer), **Ravi** (Driver, runs the commands), **Meena** (Developer). Replace
the names, group and project with yours.

## Who does what — decide in one minute

| Seat | Does | Needs |
|---|---|---|
| **Maintainer** (Asha) | Gate settings, the project access token, the two CI/CD variables — **Part 1** | Maintainer role on the project |
| **Driver** (Ravi) | Runs the setup script, pushes the branch, opens the merge request — **Part 2** | The repository cloned, a clean working tree |
| **Token owner** (often the Maintainer) | Runs `claude setup-token` on their own licence — **only if their organisation allows it** | Claude Code signed in with their organisation's licence |
| **Reviewer** (Meena) | Reads the threads, approves and merges — **Part 4** | Developer role. Never the author |

Parts 1 and 2 run **at the same time**, on two laptops.

---

## Part 1 · The Maintainer: gate settings, token, variables (about 8 minutes)

### 1.1 Protect `main`

*Project → Settings → Repository → Protected branches → expand.*

| Setting | Value |
|---|---|
| Branch | `main` |
| Allowed to merge | **Developers + Maintainers** |
| Allowed to push and merge | **No one** (or Maintainers only) |
| Allowed to force push | Off |

If `main` is already listed, change the two drop-downs on its row. Nobody pushes to `main` directly
from now on — everything arrives through a merge request.

### 1.2 Switch on the two merge checks

*Project → Settings → Merge requests → Merge checks.* Tick both, then **Save changes**:

- [x] **Pipelines must succeed**
- [x] **All threads must be resolved**

Merge method: **Merge commit** (the default) is fine.

### 1.3 Check the runner is there

*Project → Settings → CI/CD → Runners → expand.* Under **Group runners** (or *Instance runners*) you
should see a runner tagged **`junior-SWAT-engineers-program`** with a green dot. No runner, or a grey
dot? Tell your facilitator now — nothing below will run without it.

### 1.4 Create the token that posts the threads — `GITLAB_REVIEW_TOKEN`

*Project → Settings → Access tokens → **Add new token**.*

| Field | Value |
|---|---|
| Token name | `ai-review` |
| Expiration date | The last day of the programme |
| Role | **Developer** |
| Scopes | **`api`** only |

Click **Create project access token**. The token is shown **once** — copy it straight into step 1.6.
Do not paste it into chat, a file or a screenshot.

> *No "Access tokens" page under the project?* Some GitLab set-ups switch project tokens off. Use a
> **personal** access token instead (*your avatar → Edit profile → Access tokens*, scope `api`, same
> expiry). The threads will then appear under that person's name — that is fine.

### 1.5 Create the token that runs Claude Code — `CLAUDE_CODE_OAUTH_TOKEN`

**Stop and check first:** does the token owner's organisation allow its Claude licence to be used
from this GitLab? If you do not know, **skip this step** and use *the laptop route* (Part 5) until
you do. Nobody is behind for following their employer's rules.

If it is allowed, the token owner runs this on **their own laptop**:

```bash
claude setup-token
```

A browser opens; sign in with the organisation account and approve. The terminal prints a long
token (it starts with `sk-ant-oat`). Copy it — it goes into step 1.6 and nowhere else.

> This is **not** an API key for a product, and it never goes into `.env`, a file, or a product's
> CI variable. It lets the pipeline run Claude Code as that person for the review only.

### 1.6 Add the two variables

*Project → Settings → CI/CD → Variables → expand → **Add variable**.* Do this twice:

| Field | First variable | Second variable |
|---|---|---|
| Type | Variable | Variable |
| Environments | All (default) | All (default) |
| Visibility | **Masked** | **Masked** |
| Flags → Protect variable | **Off** ← important | **Off** ← important |
| Flags → Expand variable reference | Off | Off |
| Key | `GITLAB_REVIEW_TOKEN` | `CLAUDE_CODE_OAUTH_TOKEN` |
| Value | the token from 1.4 | the token from 1.5 |

**Why "Protect variable" must be off:** protected variables are only given to pipelines on protected
branches. Your merge requests come from feature branches — with the flag on, the review would
**silently never run**.

When both rows show in the list with their values hidden, tell the Driver: *"Variables are in."*

---

## Part 2 · The Driver: add the layer-3 files (about 5 minutes)

### 2.1 Start from a fresh `main`, on a new branch

```bash
cd ~/work/society-dues                    # your clone
git switch main && git pull
git status                                # must say: nothing to commit, working tree clean
git tag -l L2-design                      # must print L2-design - layer 3 starts from it
git switch -c setup/layer-3
```
```powershell
cd C:\work\society-dues
git switch main; git pull
git status
git tag -l L2-design
git switch -c setup/layer-3
```

### 2.2 Run the setup script

```bash
cd path/to/azure-labs/09-session11-12-ai-engineering
chmod +x *.sh                                       # first time only
./setup-ai-engineering.sh ~/work/society-dues
```
```powershell
cd path\to\azure-labs\09-session11-12-ai-engineering
./setup-ai-engineering.ps1 -Path "C:\work\society-dues"
```

What you should see (shortened):

```text
==> Before we start
  [ OK ] Tag L2-design found - layer 3 starts from it
==> 1 · The AI review job
  [ OK ] ci/ai-review.yml added
  [ OK ] ci/review-mr.md added
  [ OK ] ci/post-review.mjs added
==> 2 · .gitlab-ci.yml
  [ OK ] .gitlab-ci.yml created, with the AI review included
==> 3 · Commands, templates and prompts
  [ OK ] 10 commands added to .claude/commands/
  ...
  [ OK ] .gitignore keeps Terraform state, .terraform/, *.tfvars, .env and local AI review files out of git
==> 4 · CLAUDE.md
  [ OK ] Layer-3 section added to CLAUDE.md
==> 5 · One commit
  [ OK ] Committed: setup: layer 3 ...
```

It makes **one commit** (about 28 files) and never overwrites a file you wrote. If your repository
already has a `.gitlab-ci.yml` with an `include:` list, it prints a **WARN** asking you to add one
line yourself:

```yaml
include:
  - local: ci/ai-review.yml        # add this line to your existing list
```

Then `git commit -am "ci: include the AI review"`.

### 2.3 Push and open the merge request

```bash
git push -u origin setup/layer-3 -o merge_request.create -o merge_request.target=main \
  -o merge_request.title="setup: layer 3 - AI review and the gate"
```

GitLab prints a link to the new merge request. (Push options not working? Open the link GitLab
prints after the push, or *Code → Merge requests → New merge request*, source `setup/layer-3`,
target `main`.)

---

## Part 3 · Start the review (1 minute — once the Maintainer says "variables are in")

The first pipeline may have started before the merge request existed, or before the variables were
added — so it has no `ai-review` job. Start a fresh one with an empty commit:

```bash
git commit --allow-empty -m "ci: run the AI review"
git push
```

### What you should see

*Merge request → Pipelines tab* (refresh after a minute):

```text
Pipeline #1234  running
  .pre   ● ai-review          ← installs Claude Code, reviews the diff, posts threads (2–6 min)
  test   ● spec-present       ← or your lint / test jobs from Session 10
```

Then on the *Overview* tab, one thread per finding — for example:

> **AI review · should · E-012** · Maintainability
> `commit "setup: layer 3 …"`
>
> The setup commit names no task ID, and every commit should.
>
> *Suggested:* Add a setup task (T000) to `tasks.md`, or record this commit as an agreed exception.
>
> _Your group decides: **fix**, **debt** (with a TD- number) or **overruled** (with a reason).
> Reply, then resolve this thread._

…and a summary note: *"AI review — 3 finding(s), 3 new thread(s). The full report is in the job's
artifacts (`ai-review.md`)."*

No findings at all is possible on a setup change — the job log then says
`post-review: 0 finding(s), 0 new thread(s) posted`. That still proves the gate works.

---

## Part 4 · Decide, approve, merge (about 3 minutes)

1. **The author (Ravi) answers every thread** — a reply that starts with one word:
   - `fix` — and push the fix to the same branch (the review runs again; already-posted findings are
     not posted twice),
   - `debt TD-00n` — and add the row to your debt log,
   - `overruled` — with the reason in one sentence.
   Then click **Resolve thread**.
2. **A groupmate who did not write it (Meena)** reads the diff (*Changes* tab), clicks **Approve**,
   then **Merge**. The Merge button stays grey until the pipeline is green **and** every thread is
   resolved — that is the gate.
3. **Everyone else pulls:**

```bash
git switch main && git pull
```

Done. From now on every task follows the same path: branch → push → threads → decide → a groupmate
merges.

---

## Part 5 · No token for the pipeline? The laptop route

The review still happens — on a laptop — and the gate still works (pipeline green + threads resolved).

1. In Claude Code, on your branch: `/review-mr` (or `/review-mr origin/main`). It writes
   `ai-review.json` and `ai-review.md` in the repository folder — both are git-ignored.
2. Post the findings as threads with **your personal access token** (scope `api`):

```bash
GITLAB_URL=https://gitlab.stackroute.in PROJECT=mindsprint-group1/society-dues MR_IID=<number> \
GITLAB_REVIEW_TOKEN=<your token> node ci/post-review.mjs ai-review.json
```
```powershell
$env:GITLAB_URL="https://gitlab.stackroute.in"; $env:PROJECT="mindsprint-group1/society-dues"
$env:MR_IID="<number>"; $env:GITLAB_REVIEW_TOKEN="<your token>"
node ci/post-review.mjs ai-review.json
Remove-Item Env:GITLAB_REVIEW_TOKEN          # do not leave the token in the session
```

`MR_IID` is the number after `!` in the merge request title (for example `!3`). Needs Node 18 or later.

---

## When it goes wrong

| You see | Likely cause | Do this |
|---|---|---|
| No `ai-review` job in the pipeline | A variable is missing or **protected**; or the pipeline started before the merge request existed | Check both variables (Protect = off); push an empty commit |
| Pipeline says *stuck* / *no runners* | Runner tag not available to the project | Show *Settings → CI/CD → Runners* to your facilitator |
| `post-review: … 401` or `403` | `GITLAB_REVIEW_TOKEN` wrong, expired, or without `api` scope | Create a new token (1.4), update the variable |
| `ai-review` fails with a sign-in or auth error | `CLAUDE_CODE_OAUTH_TOKEN` wrong or revoked | Token owner runs `claude setup-token` again; update the variable |
| `ai-review` is orange (failed) but the pipeline is green | It is `allow_failure` on purpose — an AI outage never blocks a merge | Read the job log; meanwhile use the laptop route |
| Merge button grey | A thread is unresolved, or a non-AI job (tests) failed | Open the *Overview* thread list and the *Pipelines* tab |
| `Masked` refused when saving a variable | The value has a space or a line break | Paste again — the token is one line |
| Setup says *uncommitted changes* | Your working tree is not clean | `git status`; commit or stash, then rerun |
| Setup says *No tag L2-design* | Layer 2 was never tagged | Tag what is on `main` now (`git tag L2-design && git push --tags`) and log the rest as debt |

## Security — the three keys again

| Key | Lives | Never |
|---|---|---|
| Your Claude Code login | Your laptop | Anywhere else |
| `CLAUDE_CODE_OAUTH_TOKEN` · `GITLAB_REVIEW_TOKEN` | Masked CI/CD variables | In a file, a commit, a chat or a screenshot |
| Your Azure sign-in and Terraform state | Your laptop | Committed |

If a token is ever pasted somewhere it should not be: **revoke it first** (*Access tokens → Revoke*,
or run `claude setup-token` again to replace it), then clean up. `check-ai-engineering` fails if it
finds one committed.
