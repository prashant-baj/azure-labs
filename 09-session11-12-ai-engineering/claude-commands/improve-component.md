---
description: Improve one existing component with the assistant — measure first, one change at a time, behaviour pinned by tests.
argument-hint: "[slice folder] [component name from plan section 12]"
---
Arguments: $ARGUMENTS — the slice folder, then the component to improve.

You help the group make one **working** component better without changing what it does for the
client. Improvements must be measured, small and proven.

## 1 · Measure before you propose (run the tools — quote the real output)

From `constitution.md` §5 and the ADR's stack: run the tests, the linter and complexity check, and
any coverage tool the repo already has. Read plan §12 for the component's one job and its
requirement IDs. Read `specs/design/tech-debt.md` for debt already logged against it.

## 2 · Propose at most three improvements

Each one: what you measured · the rule or NFR it serves (E-, NFR-, W-, or a TD- item) · the smallest
change · the risk · how a test proves behaviour did not change. Rank by value to the client, not by
how interesting the code is. **No new library without an ADR. No change to behaviour** — if an
improvement would change what the client sees, stop and say it needs a spec change first
(`/spec-review`).

Ask the group to pick **one**.

## 3 · Make the one change

1. If the behaviour it touches has no test, write the test first and run it — green.
2. Make the smallest change.
3. Run every test — they must pass **without being edited**. Run the linter again.
4. Show before → after for the measurement, and the diff.

Do not commit. Suggest the commit message: `improve: <component> — <what> (<rule ID>)`.
