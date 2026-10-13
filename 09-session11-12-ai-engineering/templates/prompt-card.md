# Prompt card — <task ID> · <a few words>

*Write the prompt as a card before you send it. Anyone in the group should be able to read what the
assistant was told — and judge the answer against it.*

```text
CONTEXT
Read CLAUDE.md, constitution.md (sections 4 and 5), specs/<slice>/spec.md (<IDs>),
plan.md sections <n>, and <the contract or code it touches>.

TASK
<One task ID only.> <What, in one or two sentences.> Write the test first, named after <ID>.

LIMITS
- Stack from the ADR only. No new library.
- <Which component it may touch - and which it must not.>
- <The rule from section 5 most likely to be broken here.>

DONE WHEN
- <The test that proves it, passing.>
- All existing tests still pass, unedited.
- <Docs that change: README "How to run", trace.md.>

ASK FIRST
If <the thing our files do not say> is unclear, stop and ask. Do not guess.
Before writing code, show me your plan: the files you will touch and the tests you will add.
```

**What happened:** <one or two lines — what you changed in the plan, what you rejected, what surprised you.>
