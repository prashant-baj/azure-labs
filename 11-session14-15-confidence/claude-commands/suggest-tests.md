---
description: Propose tests for one requirement - edges, failure paths, boundaries - marked AI-suggested. Each one is run red against a broken version before it is kept. The group decides.
argument-hint: "[slice folder] [FR-, RULE- or NFR- ID]"
---
Arguments: $ARGUMENTS — the slice folder and one requirement ID. Read the requirement, its rule rows and
examples, its scenarios, the existing tests for it, and the code that implements it.

1. **List what is already proved** for this ID — test names and what each checks.
2. **Propose at most six new tests**, each with: the input, the expected outcome **and where the expectation
   comes from** (spec row, rule example, NFR, contract). Look for: boundaries (zero, maximum, just over), the
   *If … then* rows, wrong types and formats, duplicates and ordering, empty and missing data, concurrency,
   role checks. An expected outcome the spec does not give is a **question**, not a test — write it as
   `[NEEDS CLARIFICATION]` and stop for that one.
3. **Wait** for the group to pick which to write.
4. For each picked test: write it at the **lowest layer** that can catch the problem, named after the ID,
   marked `ai_suggested` (in the name or a comment). Then **break the code on purpose** so the test should
   fail, run it, show it red, restore the code, run it green. A test that cannot go red is not kept.
5. Append to `reviews/ai-tests.md` (from `templates/ai-tests-review.md`): each test — kept, changed or
   rejected, by whom, and why.

Never edit an existing test to make it pass. Never change the code to match a suggested test without a
spec line saying the code is wrong.
