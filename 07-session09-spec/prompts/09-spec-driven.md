# Session 9 prompts — it assembles, and must cite

In Claude Code these are slash commands, already in your repository under `.claude/commands/`.
Type `/spec-` and pick one. The full text of each command is in that folder — read it once, so you
know what you are asking for.

| Step | Command | You do first | You check after |
|---|---|---|---|
| 1 | `/spec-constitution` | Nothing — it reads your Module 2 files | Every row has a source. No rule you were not actually handed |
| 2 | `/spec-specify specs/001-<slice>` | **Write section 0 by hand and commit it** | IDs and sources on every row. No technology words. At least one *If* requirement |
| 3 | `/spec-clarify specs/001-<slice>` | Have the case pack open | You answered. It did not answer for you |
| 4 | `/spec-architecture specs/001-<slice>` | Commit the clarified spec. Agree who in the group knows which language | At least two options. Every reason names a driver. **You** write the decision sentence |
| 5 | `/spec-plan specs/001-<slice>` | Commit the accepted ADR | Constitution check filled. Section 8 matches the ADR — nothing added. *(inferred)* lines read aloud |
| 6 | `/spec-tasks specs/001-<slice>` | Commit the plan | Every task names an ID. Tests before builds. Twenty-five or fewer |
| 7 | `/spec-trace specs/001-<slice>` | Commit the tasks | Read the gaps list as a group. Fix the top one |

## If you are not using Claude Code

Open the command file from `.claude/commands/`, copy the text below the `---` lines, replace
`$ARGUMENTS` with your slice folder, and paste it into your assistant together with the files it
asks for. Paste the files themselves, not your summary of them — the summary is where the evidence
goes missing.

## The one sentence that does the work

Every command contains a version of this:

> If our files do not say it, do not guess. Write `[NEEDS CLARIFICATION: <question>]`.

An assistant that is allowed to guess will fill every gap with something plausible, and you will not
be able to tell which lines came from your client and which came from the assistant's imagination.
