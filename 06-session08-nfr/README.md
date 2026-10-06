# Session 8 · NFR Register and Constraints

Build the register, then let it be attacked. This lab also checks something no other lab does:
whether your design quietly depends on a service the platform policy denies.

## Where this fits

| | Lab | What it proves |
|---|---|---|
| 3 | `03-session05-spec-repo` | Your solution definition |
| 4 | `04-session06-integration` | A decision per seam |
| 5 | `05-session07-contracts` | Contracts and ADRs |
| **6** | **`06-session08-nfr`** (this folder) | **Every requirement can be checked, and the design fits the platform you actually have** |

## Before you start

Copy into your case repository:

```
templates/nfr-register.md      ->  templates/  then specs/nfr-register.md
templates/constraints.md       ->  templates/  then specs/constraints.md
templates/nfr-metrics.md       ->  templates/  (reference card, read it first)
prompts/08-attack-the-nfrs.md  ->  prompts/
```

`constraints.md` arrives with the platform policy already listed. Those rows are real and they apply
to your build. Your job is the right-hand column: what each one does to your design.

## The workshop, in the repository

| Step | Do this | Commit |
|---|---|---|
| 1 | Draft the register by hand. One line per quality, each with a metric | `spec: nfr register v1` |
| 2 | Write the constraint list, platform policy included | `spec: constraints` |
| 3 | Run the attack prompt | — |
| 4 | Decide what survives. Delete the rest | `spec: nfr register v2 after attack` |

**Shorter is better.** If you leave with more lines than you started with, something has gone wrong.

## Check your work

```bash
./check-nfrs.sh ~/work/group-1
```
```powershell
./check-nfrs.ps1 -Path "C:\work\group-1"
```

## What it checks

| Check | Why |
|---|---|
| Six columns filled on at least one line | An incomplete line is not ready |
| A named owner, not "the business" | A threshold with no owner is folklore |
| How each one would be checked | An unverifiable requirement is a wish with a table row |
| An operability line exists | The family production cares about most |
| Adjectives left in the register | Fast and reliable are not thresholds |
| **Denied services and blocked regions named in your specs** | The policy is real; your design has to fit it |
| The register got shorter between commits | Deleting is the point |

## Notes

- **The policy scan ignores `constraints.md`**, because that is exactly where the denied services are
  supposed to be listed. It scans everything else in `specs/`.
- **Nobody on this programme can grant a policy exemption.** Design inside the constraint and tell
  the client what it means. That conversation is the skill being assessed.
