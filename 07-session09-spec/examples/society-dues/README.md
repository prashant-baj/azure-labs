# Worked example — society maintenance dues

An invented scenario, so that every group can see one finished set of Session 9 files without
anybody's case being used. The society, the people and every number in it are made up. Thresholds
are written as **decisions with owners**, exactly as yours should be.

**The situation.** A housing society collects monthly maintenance. Residents pay by UPI, which sends a
message for each payment, or by bank transfer and cheque, which only show up in the bank statement
file the treasurer downloads each morning. UPI payments appear in the statement too. Residents put
their flat number in the payment remark — sometimes. The treasurer spends the first week of every
month matching payments to flats in a spreadsheet, and still sends reminders to people who have
already paid.

**The slice.** Match each payment to a flat, show any flat's dues status with where the answer came
from, and give the treasurer a reminder list that does not include people who have paid.

| File | Look at |
|---|---|
| `constitution.md` | Sources on every rule. Section 4 untouched |
| `spec.md` | Section 0 in plain words. IDs and sources. The *If* rows. No technology anywhere |
| `0003-architecture-and-stack.md` | The ADR the group decided after the spec. Drivers first, two options each, every reason names a driver, one honest open question. In a real repo: `specs/design/adr/` |
| `plan.md` | The constitution check. Section 8 — the stack copied from the ADR, not re-decided. Section 11 — two diagrams as code |
| `tasks.md` | Every task names an ID. Tests before builds. The failure paths early |

This example is deliberately small. Yours will have more `[NEEDS CLARIFICATION]` markers — this one
kept two, so you can see what an honest open question looks like.
