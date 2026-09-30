# Session 7 · Contracts and Architecture Decision Records

The assistant drafts; you find what is wrong with it. This lab checks the things a draft always gets
wrong, and whether your decision records admit what the decision cost.

## Where this fits

| | Lab | What it proves |
|---|---|---|
| 0–1 | `00-access-check`, `01-prereqs-check` | **Run both at the start of this session** |
| 3 | `03-session05-spec-repo` | Your solution definition |
| 4 | `04-session06-integration` | A decision per seam |
| **5** | **`05-session07-contracts`** (this folder) | **The promises are written down, and the drafts were corrected** |

## Before you start

Run the two environment checks first. A machine that fails today is a problem solved now rather than
on the ninth of October.

Then copy into your case repository:

```
templates/contract.md              ->  templates/
templates/adr.md                   ->  templates/
prompts/07-draft-contracts.md      ->  prompts/
```

## The workshop, in the repository

| Step | Do this | Commit |
|---|---|---|
| 1 | Draft the contract for your hardest seam | `spec: contract draft` |
| 2 | Find what is wrong with it — errors first | `spec: contract corrections` |
| 3 | Draft two ADRs from Monday's rejected options | `spec: adr 0001, 0002` |
| 4 | Correct those too | `spec: adr corrections` |

**Correct it in the file, not in the chat.** The repository is the record; the conversation is not.
If your history shows the draft accepted unchanged, you did not do the exercise.

## Check your work

```bash
./check-contracts.sh ~/work/group-1
```
```powershell
./check-contracts.ps1 -Path "C:\work\group-1"
```

## What it checks

| Check | Why |
|---|---|
| Error cases described — more than one | A draft always gives you exactly one, called "error" |
| Timing, size, duplicates, versioning sections filled | The four a draft leaves out unless asked |
| Inference marks still present | If they were deleted, the evidence went with them |
| Two ADRs with all four sections | Context, decision, alternatives, consequences |
| At least two alternatives per ADR | The section teams cannot reconstruct later |
| Bad consequences written down | An ADR with only good news is marketing |
| More than one commit on the contracts | The draft was corrected, not accepted |

## Notes

- **Size is the check nobody expects.** The empty response and the enormous one are both real, and
  neither is in the draft.
- **Never edit an accepted ADR.** Write a new one that supersedes it — the trail is the value.
