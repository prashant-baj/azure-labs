# Session 5 · Case Repository and Solution Definition

Sets up your group's case repository and checks that the solution definition you write in the
Session 5 workshop holds together. No Azure resources are created and nothing is deployed —
this lab is about the artefact, not the infrastructure.

## Where this fits

| | Lab | What it proves |
|---|---|---|
| 0 | `00-access-check` | You can reach the Azure lab account |
| 1 | `01-prereqs-check` | Your local tools are installed |
| 2 | `02-azure-resources-test` | The serverless stack deploys |
| **3** | **`03-session05-spec-repo`** (this folder) | **Your group has a case repository, and its solution definition is one a team could build from** |

From here the repository grows every session — integration decisions on Monday, contracts and
ADRs on Wednesday, the NFR register on 5 October — and Module 3 builds from it. Nothing in it
gets thrown away.

## Before you start

- Git installed (`01-prereqs-check` covers this)
- Your Module 1 artefacts to hand: problem statement, evidence log, concern sheet, decision log

## Part A · Create the repository

Run this once per **group**, not per person. One person runs it and pushes; everyone else clones.

### Windows (PowerShell)

```powershell
cd "path\to\azure-labs\03-session05-spec-repo"
./new-case-repo.ps1 -Group group-1 -Path "C:\work"
```

If scripts are blocked: `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`

### macOS / Linux / WSL (bash)

```bash
cd path/to/azure-labs/03-session05-spec-repo
chmod +x new-case-repo.sh check-spec-repo.sh    # first time only
./new-case-repo.sh group-1 ~/work
```

You get a repository with this shape, an initial commit already made:

```
group-1/
  CLAUDE.md          how the assistant works on this case — including your glossary
  docs/              your Module 1 artefacts. Paste them in
  specs/             what Module 2 produces. Starts with solution-definition.md
  templates/         the formats. Copy them, do not redesign them
  prompts/           the prompts for this session, word for word
```

## Part B · The workshop, in the repository

| Step | Do this | Commit |
|---|---|---|
| 1 | Paste your four Module 1 artefacts into `docs/` | `docs: Module 1 artefacts` |
| 2 | Fill in the glossary table in `CLAUDE.md` — the client's words, not yours | `glossary: client terms` |
| 3 | Write `specs/solution-definition.md` from the template. **By hand, as a group** | `spec: solution definition v1` |
| 4 | **Only now** run the three prompts in `prompts/` — one screen, group dictates | — |
| 5 | Decide what to accept, reject at least one finding, and record why in the file | `spec: solution definition v2 after review` |

### If your group does not have Claude access yet

Access is arriving in batches, so run step 4 with whoever in the group has it. That person is the
**driver**: they share their screen, and the group dictates. The driver types what the group decides
and does not improvise — the thinking stays with the group, which is the point of the whole exercise.

If nobody in your group has access yet, pair with a neighbouring group's driver for ten minutes, or
ask the facilitator to run the prompts at the front. Nobody waits.

Note who drove in the commit message — `spec: solution definition v2 after review (driver: <name>)`.
Swap the driver as access spreads, so the same person is not typing for the rest of the programme.

Step 3 is committed **before** the assistant sees anything. That commit is your own thinking on
record, and the difference between v1 and v2 is what gets discussed at the debrief.

## Part C · Check your work

### Windows (PowerShell)

```powershell
./check-spec-repo.ps1 -Path "C:\work\group-1"
```

### macOS / Linux / WSL (bash)

```bash
./check-spec-repo.sh ~/work/group-1
```

Each check reports `[ OK ]`, `[WARN]` or `[FAIL]`, and the script exits non-zero if anything
required is missing.

## Where does this repository live?

You need somewhere to commit. In order of preference:

| Option | Notes |
|---|---|
| A private repository per group, under the organisation account | Best. Ask the facilitator whether one exists |
| A private repository owned by one member, the rest added as collaborators | Works today. A free personal account is enough |
| Azure DevOps Repos | If your organisation already uses it, this is usually the sanctioned route |
| **Nowhere yet — work locally and hand in a bundle** | Perfectly fine for this session. See below |

Nothing in these cases is client data — the companies, the people and the numbers are all invented
for the programme — so a personal account carries no confidentiality problem. Follow your own
organisation's policy on where work artefacts live, and ask if you are unsure.

### If you cannot push anywhere yet

Work locally. `git init` needs no account, and every check in this lab passes without a remote —
the only thing you will see is `[WARN] No git remote`.

At the end of the session, package the repository and hand in one file:

```bash
./handin.sh ~/work/group-1 ~/Desktop          # macOS / Linux / WSL
```
```powershell
./handin.ps1 -Path "C:\work\group-1" -Out "$HOME\Desktop"
```

This produces a single `.bundle` file carrying **every commit**, so the difference between version
one and version two is still reviewable. The facilitator restores it with
`git clone group-1-<date>.bundle`.

Send it by whatever your team already uses. When hosting is sorted, add the remote and push — the
history comes with you, and nothing is lost.

## What it checks

| Check | Why |
|---|---|
| Repository structure and required files | The later sessions assume these paths |
| Template placeholders removed | An unfilled template is not a definition |
| Objectives present, and not more than five | More than five and you have written a feature list |
| Components listed, and each says what it needs | The source column is where the next session starts |
| Something in the **Not now** column | An empty middle column means the scope conversation has not happened |
| Acceptance criteria in EARS form (`shall`) | A criterion that cannot fail is a sentiment |
| Assumptions and open questions not empty | The section everybody deletes is the most useful one |
| Glossary in `CLAUDE.md` has at least one row | The client's words, or the assistant will use yours |
| At least two commits touching the solution definition | v1 before the assistant, v2 after |

## Notes

- **Warnings are not failures.** A `[WARN]` means a rule of thumb was missed, not that the lab
  is incomplete. Read it, decide, and move on.
- **The check does not grade your thinking.** It tells you whether the document is in a state a
  team could work from. Whether the objectives are the *right* objectives is what the debrief is
  for.
- **Push before you leave.** The reference version published after the session is only useful to
  a group whose own work is safely on the remote.
