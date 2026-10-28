# Stories 001 — match payments, show dues

*Lives next to `spec.md` in `specs/001-match-payments/`. A story is a promise of a conversation; the
acceptance criteria are what the conversation agreed. Every story names the requirements it delivers —
the requirements stay the source of truth, the story is how we plan and talk about them.*

## US-001 · Each payment is matched to a flat, or set aside

**As** the treasurer **I want** each payment matched to a flat — or set aside with the reason —
**so that** I stop matching payments by hand.

Delivers: FR-003, FR-004, FR-006 · Rule: RULE-001 · Scenarios: `features/matching.feature`

| AC | Given | When | Then | Proves |
|---|---|---|---|---|
| AC-1 | the remark names a flat that exists | the payment arrives | it is matched to that flat | RULE-001a, 001b |
| AC-2 | the remark names no flat; the payer usually pays for one flat | the payment arrives | it is matched to that flat | RULE-001d |
| AC-3 | the flat cannot be told | the payment arrives | it is not matched, and the unmatched list shows it with the reason | RULE-001c, 001e, FR-006 |
| AC-4 | a payment arrived by UPI | the morning file brings it again | it is counted once | FR-004 |

## US-002 · The reminder list leaves out flats that have paid

**As** the treasurer **I want** the reminder list to leave out every flat that has paid this month
**so that** nobody who paid gets a reminder.

Delivers: FR-008 · Rule: RULE-002 (from the example map, Q1 answered) · Scenarios: `features/reminders.feature`

| AC | Given | When | Then | Proves |
|---|---|---|---|---|
| AC-1 | a flat's payments this month cover its dues — one payment or several | the treasurer asks for the list | the flat is not on it | RULE-002a, 002b |
| AC-2 | a flat has paid part of its dues | the treasurer asks for the list | the flat is on it, with the balance | RULE-002c |
| AC-3 | a flat has paid nothing | the treasurer asks for the list | the flat is on it, with the whole dues | RULE-002d |
| AC-4 | a flat paid by UPI this morning | the treasurer asks for the list | the flat is not on it | FR-008 *How we will know* |

Not in these stories: overpayments (Q3) and when a month starts (Q4) — open questions in `spec.md` §10.

## Checklist for every story

- [x] Names a real role from the concern sheet — not "the user"
- [x] The *so that* is the reason the client gave, not a restatement of the *I want*
- [x] Every AC is a Given / When / Then a person could check by hand
- [x] Every AC names what it proves — a requirement or rule row
- [x] Small enough to build and merge in a day
