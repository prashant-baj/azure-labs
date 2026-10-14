# Sessions 11 and 12 prompts — the assistant across the whole loop

In Claude Code these are slash commands, added to `.claude/commands/` by `setup-ai-engineering`.

| When | Command | You do first | You check after |
|---|---|---|---|
| Every task | `/task-plan specs/001-<slice> T0xx` | Pick one task. New branch | The plan names only files in the task's component. Questions answered by **you** |
| Every task | `/task-build specs/001-<slice> T0xx` | Approve or change the plan | Test failed first, then passed. Docs changed in the same diff. **Read the diff** |
| When it breaks | `/debug-evidence <the error>` | Copy the real error, not your summary | The missing test fails before the fix and passes after |
| Before Ready | `/review-mr` | Push. The pipeline runs the same review | Every finding has a rule and a place. **You** decide each |
| Session 11 | `/azure-gaps specs/001-<slice>` | Your ADR and plan §12 are merged | Every gap has a kind and a source. **You** answered each question — or wrote NEEDS CLARIFICATION |
| Session 12 | `/azure-terraform specs/001-<slice>` | `azure-gaps.md` committed; the team chose who applies | Each resource names the spec line it serves. You read `terraform plan` before `apply`. Every apply logged in `infra/deployments.md`. No state committed — `DEPLOY-EXERCISE.md` |
| Session 12 | `/validate-ai-code specs/001-<slice>` | All layer-3 work merged | Real tool results quoted. Decision column is yours |
| Session 12 | `/spec-review specs/001-<slice>` | Bring the requirement you are least sure about | Every finding quotes a line. **You** decided each: change, keep with a reason, or ask the client |
| Session 12 | `/spec-sync specs/001-<slice>` | All layer-3 work merged | Every drift row decided: spec change, code fix or debt. `trace.md` updated |
| Session 12 | `/improve-component specs/001-<slice> <component>` | Pick a component from plan §12 | Measured before and after. One change. Tests pass unedited |

## Prompts for strengthening the spec

`prompts/spec-enhancement.md` has ten copy-paste prompts — ambiguity hunt, EARS rewrite, missing
failure paths, edge-case examples, conflicts, evidence not covered, glossary drift, questions for
the client, spec–code drift, explain it back. Use them in any assistant, with the files attached.

## A prompt card, when you are not using a command

Use `templates/prompt-card.md`: **context, task, limits, done-when, ask-first.** The card is the
prompt *and* the record of what the assistant was told — keep it with the merge request.

## If you are not using Claude Code

Open the command file from `.claude/commands/`, copy the text below the `---` lines, replace
`$ARGUMENTS`, and paste it into your assistant with the files it asks for — the files, not a summary.
