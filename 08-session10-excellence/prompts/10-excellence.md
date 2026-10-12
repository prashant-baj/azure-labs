# Session 10 prompts — it generates, then it is reviewed

In Claude Code these are slash commands, added to `.claude/commands/` by `setup-excellence`.
Type `/spec-` or `/build-` or `/review-` or `/refactor-` and pick one.

| Step | Command | You do first | You check after |
|---|---|---|---|
| 1 | `/spec-engineering-rules` | Read `templates/engineering-rules.md` together | Five to seven rules. Each says **how** it is checked |
| 2 | `/spec-components specs/001-<slice>` | Commit the rules | Every component has one job, no "and". The rule depends on ports |
| 3 | `/build-tasks specs/001-<slice> T001-T006` | Commit the plan. Create your branch | Run the tests yourselves. Commit one task at a time |
| 4 | `/review-excellence specs/001-<slice>` | Push, open a Draft merge request | Every finding has a rule and a line. **You** fill the Decision column |
| 5 | `/refactor-step specs/001-<slice> <n>` | Commit the review with your decisions | Tests pass without being edited. One finding, one commit |

## If you are not using Claude Code

Open the command file from `.claude/commands/`, copy the text below the `---` lines, replace
`$ARGUMENTS` with your slice folder (and task IDs or finding number), and paste it into your
assistant together with the files it asks for — the files themselves, not your summary of them.

## The sentence that does the work today

> Every finding names a rule ID and a place. No rule, no finding.

Without it, an assistant review is a list of opinions. With it, every comment can be checked,
argued with, and decided.
