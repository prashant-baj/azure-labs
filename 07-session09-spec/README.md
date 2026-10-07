# Session 9 · From a pile of documents to one spec

Module 3 opens here. Over eight sessions your group has written a problem statement, an evidence
log, a concern sheet, a decision log, a solution definition, integration decisions, contracts, ADRs,
an NFR register and a constraint list. All good work — and, today, all in different places.

This lab does two things:

1. **Organises** your repository into four layers, so a new joiner — or an assistant — reads it in
   the right order.
2. **Turns it into a spec a team can build from**: a constitution, then for your first slice a spec,
   a plan and a list of tasks, every line traced back to where it came from.

No code is written today. No Azure resources are created. The stack is not decided yet, and that is
deliberate — a good spec does not depend on it.

## Where this fits

| | Lab | What it proves |
|---|---|---|
| 3 | `03-session05-spec-repo` | Your solution definition |
| 4 | `04-session06-integration` | A decision per seam |
| 5 | `05-session07-contracts` | Contracts and ADRs |
| 6 | `06-session08-nfr` | NFRs you can measure, and the rules you were handed |
| **7** | **`07-session09-spec`** (this folder) | **One spec, traced to its sources, that a team could build from** |

## What your repository looks like after this lab

```
CLAUDE.md                 + a Module 3 section: the spec is the source of truth
constitution.md           NEW - the rules for every slice
docs/                     layer 1 - evidence (Module 1), unchanged
specs/
  README.md               the map: four layers, three rules
  design/                 layer 3 - Module 2, moved here with history kept
    solution-definition.md  integration-decisions.md  contracts/  adr/
    nfr-register.md  constraints.md  diagrams/
  001-<your-slice>/       layer 4 - what you build first
    spec.md               what and why - no technology
    plan.md               how - stack left open, diagrams as code (Mermaid)
    tasks.md              small steps, tests first, each with a requirement ID
    trace.md              written by /spec-trace: requirement -> task -> test, and the gaps
templates/                + constitution, spec, plan, tasks
prompts/09-spec-driven.md
.claude/commands/         /spec-constitution  /spec-specify  /spec-clarify
                          /spec-plan  /spec-tasks  /spec-trace
```

The layout and the steps follow the same shape as GitHub's open-source **Spec Kit** — constitution,
specify, plan, tasks — delivered as Claude Code commands inside your repository, so there is nothing
to install.

## Before you start

- Your case repository, with Sessions 5 to 8 committed
- Claude Code, from any member of the group (see *the driver* below)
- The **GitLab project URL** for your group — ask the facilitator. Only the IT team can create
  projects under `mindsprint-group1` … `mindsprint-group5`

## Part A · Organise the repository (once per group)

One person runs it, commits, pushes. Everyone else pulls.

```powershell
# Windows
cd "path\to\azure-labs\07-session09-spec"
./organise-specs.ps1 -Path "C:\work\group-1" -Slice "status-with-source"
```
```bash
# macOS / Linux / WSL
cd path/to/azure-labs/07-session09-spec
chmod +x *.sh                         # first time only
./organise-specs.sh ~/work/group-1 status-with-source
```

The slice name is yours to choose — a few words for the first thing you will build. It moves your
Module 2 files with `git mv`, so their history comes with them, adds the new files, and makes **one
commit**. It never deletes or overwrites anything you wrote. It refuses to run on uncommitted work.

## Part B · The workshop, in the repository

| Step | Do this | Commit |
|---|---|---|
| 1 | Run Part A | done by the script |
| 2 | **By hand, as a group:** write section 0 of `specs/001-…/spec.md` — the slice in one paragraph | `spec: slice in our words` |
| 3 | `/spec-constitution` — then check every row has a source | `spec: constitution` |
| 4 | `/spec-specify specs/001-…` — then check IDs, sources, no technology, one *If* row | `spec: assembled` |
| 5 | `/spec-clarify specs/001-…` — **you** answer; park what you cannot | `spec: clarified` |
| 6 | `/spec-plan specs/001-…` then `/spec-tasks specs/001-…` | `plan: v1` · `tasks: v1` |
| 7 | `/spec-trace specs/001-…` — read the gaps aloud, fix the top one | `trace: v1` |
| 8 | Check, then push to GitLab (Part C, Part D) | — |

**Step 2 is committed before the assistant opens the file.** That commit is your group's own
definition of the slice. Everything after it is the assistant assembling your records around it.

### The rule for this session

The assistant **assembles, and must cite**. Every line it writes carries the file it came from. A
line with no source is either deleted or becomes `[NEEDS CLARIFICATION]`. It does not get to fill a
gap with something plausible.

### If not everybody has Claude access

Same as before: whoever has it is the **driver** — shares the screen, types what the group decides,
does not improvise. Note the driver in the commit message. If you are using Claude Code through the
lab's OpenRouter key, the commands work the same way. If you are using a chat assistant instead,
`prompts/09-spec-driven.md` explains how to use the command text by hand.

## Part C · Check your work

```powershell
./check-spec.ps1 -Path "C:\work\group-1"
```
```bash
./check-spec.sh ~/work/group-1
```

Each check reports `[ OK ]`, `[WARN]` or `[FAIL]`. The script exits non-zero only if something
required is missing.

| Check | Why |
|---|---|
| The four layers exist; Module 2 is all in `specs/design/` | Later sessions read these paths |
| Constitution: placeholders gone, every rule has a source, W-001 to W-006 kept | A rule with no source is an opinion |
| Section 0 written, and committed before the rest | Your definition of the slice, on record |
| Requirements have IDs, EARS form, and at least one *If* row | A spec with no failure case is half a spec |
| At least two inputs; worked examples of the rule; a quality requirement | What comes in, the judgement, how well |
| Every row has a source | Traceability starts here |
| No technology names in the spec; no words that cannot fail | What and why, never how |
| Open `[NEEDS CLARIFICATION]` each have someone who can answer | Honest gaps beat confident guesses |
| Plan: constitution check, every FR placed, contract links real, stack left open | A plan that ignores the constitution is a failed plan |
| Plan: two Mermaid diagrams — area map, and a sequence with a failure branch | Pictures that change in the same commit as the plan never go stale |
| Tasks: twenty-five or fewer, each with an ID, tests present, every FR and RULE covered | No task, no build. No ID, no reason |
| `trace.md` present; files committed; pushed to GitLab | The chain, and the remote |

## Part D · Push to your group's GitLab project

```powershell
./connect-gitlab.ps1 -Path "C:\work\group-1" -Url "https://gitlab.stackroute.in/mindsprint-group1/<project>.git"
```
```bash
./connect-gitlab.sh ~/work/group-1 https://gitlab.stackroute.in/mindsprint-group1/<project>.git
```

Safe to run again — it updates the remote and pushes what is new. Then tag the version you are
handing in, so the facilitator can find it:

```bash
git -C ~/work/group-1 tag spec-001-v1
git -C ~/work/group-1 push origin --tags
```

| If you see | It means | Do this |
|---|---|---|
| `certificate` / `SSL` | Your network inspects HTTPS | Run `tools/fix-company-proxy` from the root of azure-labs |
| `not found` | The project does not exist yet, or the URL is wrong | Ask the facilitator for the exact URL |
| `403` / `protected branch` | You are not a member, or Developers cannot push to `main` | Ask IT for Maintainer on the project |
| `Authentication failed` | GitLab wants a token, not your password | GitLab → Edit profile → Access tokens → `write_repository` |
| `rejected` / `fetch first` | Someone in your group pushed first | `git pull --rebase`, then run it again |

Nothing on GitLab yet? Your work is safe locally — hand in a bundle with
`03-session05-spec-repo/handin` as before, and push when the project exists.

## Diagrams as code

From this session the diagrams engineers build from live **in `plan.md`, as Mermaid** — text that
GitLab draws as a picture. They change in the same commit as the plan, show up in code review, and
the assistant can read and update them. Your Session 6 photo stays in `specs/design/diagrams/` as
history. To preview locally in VS Code, install a Mermaid preview extension; on GitLab they render
automatically.

## The worked example

`examples/society-dues/` is a finished set of Session 9 files for an invented scenario — a housing
society matching maintenance payments. It passes every check in this lab. Read it **after** you have
written your own section 0, not before; it is there to show the shape, not the answer.

## Notes

- **Warnings are not failures.** Read them, decide, and be ready to explain at the debrief.
- **The check does not grade your thinking.** Whether you picked the right slice is what the debrief
  is for.
- **The spec changes first.** From today, any change to what the system does starts in `spec.md`
  and its change log — then the plan, then the tasks, then the code.
