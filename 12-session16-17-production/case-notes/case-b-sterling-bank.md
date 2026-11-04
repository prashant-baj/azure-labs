# Session 16 · Case notes for Group 2 — Sterling National Bank

*`setup-production` copies this file into your repo as `specs/design/threat-notes.md`, so `/threat-model` reads it
with the rest of your design. These are **checks, not answers**: each one is a question to try against your own code and
your own deployed service. Keep the threats that are real for your slice. Strike out the ones that are not, with
one line saying why.*

**Your slice, as planned:** a dispute case state machine, eligibility evaluated against your rule set, an
expected-decision date calculated and exposed, and card numbers redacted when evidence comes in.

Yours is the case with the most regulated data in the cohort. Expect more threats than other groups, and expect
Priya Nadarajah's two lines to be in your model.

---

## 1. What you protect

| Asset | Why it matters in this case |
|---|---|
| Card numbers and transaction details | Card data. It must never be stored or shown in full where it is not needed |
| Customer evidence: receipts, screenshots, attachments | Personal and financial data, arriving from outside the bank |
| The case state and its history | A regulated timeline. Who moved a case, when, and why must stand up to audit |
| The expected-decision date | Customers will rely on it. A wrong or manipulated date is a complaint, and possibly a breach |
| Network deadlines | Missing one means an unrecoverable loss |

## 2. Threats to check, letter by letter

| STRIDE | Check this in your slice |
|---|---|
| **Spoofing** | Can a caller act as an investigator by sending a role header? Can a customer see or update a case that is not theirs, by changing the case ID? |
| **Tampering** | Can a state change skip a step — straight from *raised* to *refunded*? Does the state machine refuse transitions your rules do not allow, through the API and not only in the UI? Can the expected date be set by a caller instead of calculated? |
| **Repudiation** | For every transition: who did it, when, from which state, under which rule. Is that recorded where it cannot be edited? "Stand up to audit" is in the brief |
| **Information disclosure** | Is the card number redacted **before** it is stored, logged or returned — not afterwards? Check the redaction on a number with spaces, dashes, and a number inside a sentence. Does an error message ever echo the input back? |
| **Denial of service** | Evidence arrives from outside. What does a very large file, or a thousand files, do to your ingest? |
| **Elevation of privilege** | Who may override eligibility, or close a case without a decision? Is that route checked separately from "may view"? |

**Priya's attachment line.** "I would like somebody to look at what is actually inside those email attachments."
Evidence files are untrusted input. Check the type by content, not by file name; cap the size; never execute or
render them as they arrive. If your slice does not open attachments, write that down as accepted, with her name
as the person who must agree.

## 3. Secrets in this case

The key that proves an investigator or a team lead, and any credential to the card-network stub. Each one is a
masked GitLab variable, never in a test fixture, and the app fails closed when it is missing. **Test card
numbers only**, in tests and seed data — never a real one, even a colleague's expired card.

## 4. Never in a log or a metric

Card numbers (even partly), customer names, evidence content. Log the case ID, the state, the transition and the
rule. A metric attribute such as `outcome` is fine; a customer name is not.

## 5. For step 2 — attack your own service

- Call an investigator-only route with only a role header.
- Change the case ID in a URL to one you were not given.
- Ask for a transition the rules do not allow.
- Send evidence with a card number in it, then check the stored record, the response and the job log.

## 6. Who would agree to an accepted risk

**Priya Nadarajah** for anything touching customer data or regulated timelines. **Claire Beaumont** for
operational trade-offs. Not the group.

## Before you finish step 2

- [ ] Redaction is a control with a test named after its threat, and covers the formats above
- [ ] Every allowed transition is enforced in the API, and one disallowed transition has a failing-first test
- [ ] Each state change records who, when and why
- [ ] Priya's attachment concern is a threat, or an accepted risk with her name on it
