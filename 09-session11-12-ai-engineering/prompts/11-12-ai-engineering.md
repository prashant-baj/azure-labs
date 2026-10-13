# Sessions 11 and 12 prompts — the assistant across the whole loop

In Claude Code these are slash commands, added to `.claude/commands/` by `setup-ai-engineering`.

| When | Command | You do first | You check after |
|---|---|---|---|
| Every task | `/task-plan specs/001-<slice> T0xx` | Pick one task. New branch | The plan names only files in the task's component. Questions answered by **you** |
| Every task | `/task-build specs/001-<slice> T0xx` | Approve or change the plan | Test failed first, then passed. Docs changed in the same diff. **Read the diff** |
| When it breaks | `/debug-evidence <the error>` | Copy the real error, not your summary | The missing test fails before the fix and passes after |
| Before Ready | `/review-mr` | Push. The pipeline runs the same review | Every finding has a rule and a place. **You** decide each |
| Session 12 | `/validate-ai-code specs/001-<slice>` | All layer-3 work merged | Real tool results quoted. Decision column is yours |
| Session 12 | `/spec-ai-feature specs/001-<slice> "<idea>"` | Agree as a group what stays with a person | If rows, a data rule, an eval set from the evidence |
| Session 12 | `/build-ai-feature specs/001-<slice>` | Commit the spec change | Every guardrail tested with a fake. No key in the repository |

## A prompt card, when you are not using a command

Use `templates/prompt-card.md`: **context, task, limits, done-when, ask-first.** The card is the
prompt *and* the record of what the assistant was told — keep it with the merge request.

## If you are not using Claude Code

Open the command file from `.claude/commands/`, copy the text below the `---` lines, replace
`$ARGUMENTS`, and paste it into your assistant with the files it asks for — the files, not a summary.
