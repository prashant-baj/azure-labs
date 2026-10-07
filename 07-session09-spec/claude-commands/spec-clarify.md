---
description: Ask the group the questions the spec cannot answer — one at a time, never answering for them
argument-hint: "[slice folder, e.g. specs/001-first-slice]"
---
Slice folder: $ARGUMENTS (if empty, use the only `specs/NNN-*` folder).

Read `<slice>/spec.md` and `constitution.md`.

Find, in this order:
1. Every `[NEEDS CLARIFICATION]` marker
2. Words that cannot fail: fast, quickly, timely, appropriate, user-friendly, seamless, real time,
   as required, etc.
3. Two rows that contradict each other
4. A requirement with no way to know it was met

Pick the **five** that would change the most if answered differently. Ask them **one at a time**.
For each question:
- quote the row and its ID
- offer two to four possible answers, and say which one you would recommend and why
- then wait for the group's answer

Never answer on the group's behalf. "We don't know" is a valid answer — when you get it, move the
question to section 10 with who could answer it, and go on.

After each answer:
- update the affected rows
- add a dated line to section 11, naming the IDs it changed
- add a line to the change log

When you finish, print how many questions were answered, how many were parked, and who the parked
ones are waiting for.
