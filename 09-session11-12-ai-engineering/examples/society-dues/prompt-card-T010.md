# Prompt card — T010 · the statement loader

*Session 11. The prompt the group actually used, written as a card so anyone can read what the
assistant was told. Context, task, limits, done-when, and when to stop and ask.*

```text
CONTEXT
Read CLAUDE.md, constitution.md (sections 4 and 5), specs/001-match-payments-show-dues/spec.md
(FR-002, FR-007, NFR-002), plan.md sections 3, 8 and 12, and specs/design/contracts/bank-statement.md.

TASK
T010 only: build the statement loader. It reads the morning file and hands every credit to
PaymentRecorder.record. Write the test first, named after NFR-002.

LIMITS
- Stack from ADR 0003 only. No new library.
- The loader is an adapter: it may know the file format; the rule must not.
- No silent failures (E-006): an unreadable line is reported with its line number, the rest is loaded.
- Do not touch the matcher or its tests.

DONE WHEN
- The NFR-002 test passes: lines in = recorded + unmatched + unreadable, for a sample file.
- All existing tests still pass, unedited.
- README "How to run" says how to load a file.

ASK FIRST
If the contract does not say how dates or amounts are written, stop and ask. Do not guess a format.
Before writing code, show me your plan: the files you will touch and the tests you will add.
```

**What happened:** the plan named one file outside the task (`matcher.py`, "to add a helper").
The driver said no — the plan changed before any code was written. That is the cheapest review
there is.
