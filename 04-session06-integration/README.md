# Session 6 · Integration Decisions and the Context Diagram

One decision per seam, with the options that lost written down, and a diagram somebody who joined
this week could understand. Nothing is deployed in this lab.

## Where this fits

| | Lab | What it proves |
|---|---|---|
| 0 | `00-access-check` | You can reach the Azure lab account |
| 1 | `01-prereqs-check` | Your local tools are installed |
| 2 | `02-azure-resources-test` | The serverless stack deploys |
| 3 | `03-session05-spec-repo` | Your solution definition is one a team could build from |
| **4** | **`04-session06-integration`** (this folder) | **Every seam has a decision somebody could disagree with** |

## Before you start

Copy these into your case repository:

```
templates/integration-decision.md   ->  templates/
prompts/06-integration-options.md   ->  prompts/
```

Then create `specs/integration-decisions.md` — one copy of the template per seam, separated by `---`.

Not sure what a finished record looks like? Read
[`examples/integration-decisions-example.md`](examples/integration-decisions-example.md) — two
complete records from an invented hotel, deliberately outside every case in this programme, so
you copy the discipline rather than an answer.

## The workshop, in the repository

| Step | Do this | Commit |
|---|---|---|
| 1 | List your seams, including the human ones | — |
| 2 | Run the options prompt, **one seam at a time** | — |
| 3 | Choose, and write down why the other options lost | `spec: integration decisions` |
| 4 | Draw the context diagram. Paper is fine | `spec: context diagram` |

A photograph of a whiteboard in `specs/diagrams/` counts. A drawing tool is not the exercise.

## Check your work

```bash
./check-integration.sh ~/work/group-1          # macOS / Linux / WSL
```
```powershell
./check-integration.ps1 -Path "C:\work\group-1"
```

## What it checks

| Check | Why |
|---|---|
| A decision record per seam | Most designs have more than one edge |
| An owner for the other side | Design follows ownership more than technology |
| Rejected options, with reasons | A record with no rejections is a preference, not a decision |
| The chosen shape is stated | And whether every seam chose the same one |
| How you would find out it changed | Silent changes are the classic outage |
| A context diagram exists | Somebody outside the group has to be able to read your design |

## Notes

- **If every seam is an event**, the check says so. That is a question, not an accusation — it may
  well be right, and you should be able to say why.
- **"They will tell us" is a valid answer** to how you would find out about a change. Write it down;
  it is an assumption, and assumptions are the ones that bite.
