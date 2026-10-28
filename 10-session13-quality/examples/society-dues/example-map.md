# Example map — US-002, the reminder list

*Example-mapping session, about twenty minutes. Treasurer (on the phone for the last five), two developers, one tester.
Written down as the cards were laid out. Colours as on the table.*

```
                         ┌──────────────────────────────────────────────────────┐
  STORY (yellow)         │ US-002  As the treasurer I want the reminder list to │
                         │ leave out flats that have paid, so that nobody who   │
                         │ paid gets a reminder.                     FR-008     │
                         └──────────────────────────────────────────────────────┘
        ┌───────────────────────────┐   ┌───────────────────────────┐   ┌───────────────────────────┐
RULES   │ R1  A flat that has paid  │   │ R2  "Paid" means the      │   │ R3  Only payments matched │
(blue)  │ this month is left out    │   │ month's dues are covered  │   │ to the flat count         │
        └───────────────────────────┘   └───────────────────────────┘   └───────────────────────────┘
EXAMPLES  paid by UPI this morning        one payment, full dues          paid, but the remark named
(green)   → not on the list               → paid                          another flat → it counts for
                                          two payments covering it        THAT flat, not this one
          no payment at all               → paid
          → on the list, whole dues       one part payment                unmatched payment
                                          → on the list, with the balance → on nobody's account until
                                                                            the treasurer matches it (FR-009)
QUESTIONS (red)
  Q1  Does a part payment count as "paid"?                  → ANSWERED by the treasurer, on the call:
                                                              "No. They get a reminder for the balance."
  Q3  Someone pays more than the dues — carry it forward?   → OPEN. Treasurer will ask the committee.
  Q4  Does the month run by calendar or by due date?         → OPEN. Assumed calendar month in this slice;
                                                              written in spec §10 so it is not forgotten.
```

## What came out of it

| Card | Went to | As |
|---|---|---|
| R2 + its green cards | `spec.md` §5 | **RULE-002** with rows a–d — the treasurer's words, quoted |
| Q1 answered | `spec.md` §10 and §11 | Open question 1 closed; clarification recorded with the date and who answered |
| Q3, Q4 | `spec.md` §10 | New open questions, with who can answer. **No code guesses them** |
| R1 example "paid by UPI this morning" | `features/reminders.feature` | The FR-008 scenario — it was already the spec's *How we will know* |
| R3 examples | Nothing new | Already covered by RULE-001 and FR-009 — the map showed it, so we did not write it twice |

## Reading a map

- **Many red cards** — the story is not ready. Do not estimate it; ask the questions first.
- **Many blue cards** — the story is too big. Split it, one rule or two per story.
- **A rule with no green card** — nobody can give an example, so nobody can test it. It is a hope, not a rule.
- **Green cards nobody disagrees with** — good. Those become the scenarios, word for word.
