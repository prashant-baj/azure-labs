# Spec 001 — match payments, show dues

*Status: ready to plan · Group: example · Last changed: Session 9*

> **What and why. Never how.** Every row has an ID and a Source.

## 0. The slice, in our words

The treasurer wants to stop matching payments to flats by hand. When a payment arrives — by UPI
message during the day, or in the bank statement file each morning — it should be matched to a flat,
counted once, and show up in that flat's dues. Anyone on the committee who is allowed to should be
able to ask "has flat B-304 paid this month?" and get an answer that says where it came from and how
old it is. Anything that cannot be matched goes on a list the treasurer actually sees, and the
reminder list leaves out people who have paid.

## 1. Why this slice first

Serves objective 1 in `specs/design/solution-definition.md` §2 — "the treasurer no longer matches
payments by hand". Every later slice (receipts, late fees, reports) needs payments matched first.

## 2. Who it is for

| Role (from the concern sheet) | What they need from this slice | Source |
|---|---|---|
| Treasurer | Payments matched without the spreadsheet; one list of what could not be matched | `docs/03-concern-sheet.md` row 1 |
| Secretary | To answer a resident's "did you get my payment?" without calling the treasurer | `docs/03-concern-sheet.md` row 3 |

## 3. What comes in

| ID | Input | From whom, or which system | Arrives as (call / message / file) | How fresh, how reliable | Source |
|---|---|---|---|---|---|
| IN-001 | A UPI payment | The collection gateway | Message, one per payment | Within minutes. Remark is free text — flat number present only sometimes | `design/integration-decisions.md` seam 1 |
| IN-002 | Every credit to the society account, UPI included | The bank, via the treasurer | File, once each morning | Up to a day old. Complete. Carries the bank reference | `design/integration-decisions.md` seam 2 |

## 4. Functional requirements

| ID | Requirement | Source | How we will know |
|---|---|---|---|
| FR-001 | When a UPI payment message arrives, the system shall record it with its source and time of arrival. | `design/contracts/upi-payment.md` | Test: a message in, one recorded payment out, with source and time |
| FR-002 | When the morning statement file is loaded, the system shall record every credit in it with its source and time of loading. | `design/contracts/bank-statement.md` | Test: a file of known credits in, the same credits recorded |
| FR-003 | When a payment is recorded, the system shall match it to a flat using RULE-001. | `design/solution-definition.md` §6 | Rule examples RULE-001 pass |
| FR-004 | When the same payment arrives from both the message and the file, the system shall count it once. | `design/adr/0002-bank-reference-as-key.md` | Test: same bank reference twice, dues change once |
| FR-005 | When an allowed committee member asks for a flat's dues, the system shall return the dues, the payments counted, and the source and time of the newest one. | `design/solution-definition.md` §6 | Test: response carries source and time (Q-001) |
| FR-006 | If a payment cannot be matched to a flat, then the system shall add it to the unmatched list with the reason. | `docs/02-evidence-log.md` row 7 | Test: payment with no flat in remark and unknown payer appears on the list with its reason |
| FR-007 | If the statement file has not been loaded today, then the system shall say so on every dues answer. | `design/integration-decisions.md` seam 2 — "their bad day" | Test: no file today, answer carries the warning |
| FR-008 | When the treasurer asks for the reminder list, the system shall list flats with dues and leave out every flat with a matched payment for the month. | `docs/03-concern-sheet.md` row 1 | Test: a flat that paid by UPI this morning is not on the list |

## 5. The rule that needs judgement

**RULE-001 — which flat does this payment belong to?** As the treasurer put it: "If they wrote the
flat number, believe it — unless the flat doesn't exist. If they didn't, see who usually pays for that
flat. If you still can't tell, don't guess — put it aside and I'll ask." (`docs/02-evidence-log.md` row 4)

| ID | Given | Expect | Source |
|---|---|---|---|
| RULE-001a | Remark "B-304 Oct maint", flat B-304 exists | Matched to B-304 | evidence log row 4 |
| RULE-001b | Remark "B304", flat B-304 exists | Matched to B-304 — the hyphen is often missing | evidence log row 5 |
| RULE-001c | Remark "Z-999", no such flat | Unmatched — reason: flat in remark does not exist | evidence log row 4 |
| RULE-001d | No flat in remark; payer registered for exactly one flat | Matched to that flat | evidence log row 6 |
| RULE-001e | No flat in remark; payer registered for two flats | Unmatched — reason: payer pays for more than one flat | evidence log row 6 |

## 6. What it keeps, and what it gives back

| What is kept | Who asks for it | What they get back | Source |
|---|---|---|---|
| Every payment as it arrived, and how it was matched | Treasurer, secretary | The flat's dues, the payments counted, source and time of the newest | `design/solution-definition.md` §4 |
| The unmatched list | Treasurer | Each payment, and the reason it was not matched | evidence log row 7 |

## 7. What happens next

The treasurer takes the reminder list (FR-008) and sends reminders — by hand in this slice. Sending
them automatically is a later slice.

## 8. Quality requirements for this slice

| ID | Requirement | Metric and threshold | How it is checked | Source |
|---|---|---|---|---|
| NFR-001 | A dues answer is quick enough to give a resident at the gate | 95% of dues answers within two seconds — decided by the secretary | A load test with a full month of payments | `design/nfr-register.md` — performance |
| NFR-002 | Nothing goes missing between the file and the dues | Credits in the file = payments recorded + unmatched, every load | A count check after every load | `design/nfr-register.md` — reliability |

## 9. Not in this slice

| Left out | Why | Which slice, or nobody |
|---|---|---|
| Sending reminders automatically | The treasurer wants to check the list first for a month | Slice 002 |
| Late fees | Committee has not agreed the rule | Nobody yet — see question 2 |
| Receipts to residents | Needs the matching to be trusted first | Slice 003 |

## 10. Open questions

| # | Question | Who can answer | Parked until |
|---|---|---|---|
| 1 | Does a part payment count as "paid" for the reminder list? `[NEEDS CLARIFICATION: part payments]` | Treasurer | Before FR-008 is built |
| 2 | Is there a late fee, and from which day? `[NEEDS CLARIFICATION: late fee rule]` | Managing committee | Not this slice |

## 11. Clarifications

- *Session 9* — Asked: does the matching need to handle cheques? Treasurer: yes, they appear in the
  statement like any other credit. Changed: IN-002, FR-002.

## Change log

| Date | Change | Why | IDs affected |
|---|---|---|---|
| Session 9 | First version | Assembled from design record, section 0 by hand | All |
| Session 9 | Cheques included in IN-002 | Clarification with the treasurer | IN-002, FR-002 |
