# Session 16 · Case notes for Group 1 — Nova Retail Group

*`setup-production` copies this file into your repo as `specs/design/threat-notes.md`, so `/threat-model` reads it
with the rest of your design. These are **checks, not answers**: each one is a question to try against your own code and
your own deployed service. Keep the threats that are real for your slice. Strike out the ones that are not, with
one line saying why.*

**Your slice, as planned:** partner updates come in through a push API and an overnight file. They are
normalised to one consignment event, duplicates and conflicts are resolved by a documented rule, status is
exposed with its freshness and source, and an exception is raised when a milestone is overdue.

---

## 1. What you protect

| Asset | Why it matters in this case |
|---|---|
| The consignment status and its source | Nova's product is reliability. A wrong status tells an account manager everything is fine when it is not |
| The exception list | Meera's team acts on it. A missing exception means the customer finds out first again |
| Customer and delivery details: names, addresses, phone numbers | Personal data. Agents and partners see some of it; nobody else should |
| The partners' credentials | Each partner pushes to you, or you collect from them. Whoever holds a partner's key can speak as that partner |

## 2. Threats to check, letter by letter

| STRIDE | Check this in your slice |
|---|---|
| **Spoofing** | Can anyone post a "delivered" update to your push endpoint? What proves an update came from *that* partner — a key per partner, or one shared key? (A shared key means one leaked key lets someone speak for all five.) |
| **Tampering** | Can a crafted update change a consignment that belongs to a *different* partner? Is the overnight file checked (format, partner, size) before a single row is applied? |
| **Repudiation** | When two sources disagree, your rule picks one. Can you show afterwards *which* source won and *why*? Arun's line — "nobody has agreed what the data means when two systems disagree" — becomes an audit question |
| **Information disclosure** | Can a caller see any consignment by guessing its number? Does the status API return the delivery address or phone number when only the status was asked for? |
| **Denial of service** | A partner resends a whole day's events, or the file arrives twice. Does your duplicate rule hold, or does the exception list fill with noise? What does a very large file do? |
| **Elevation of privilege** | Is there a route that clears or closes an exception? Who may call it — an agent, a partner, anyone with the key? |

## 3. Secrets in this case

- One credential **per partner**, for the push API, so that one can be withdrawn without breaking the others.
  Each is a masked GitLab variable, and the app compares in constant time.
- If your slice *collects* from a partner, that partner's credential is a secret too, and takes the same journey.
- Fail closed: an update from a partner whose key is not configured is refused, not accepted.

## 4. Never in a log or a metric

Addresses, phone numbers, customer names. Log the consignment ID, the partner, the event type, the source and
the rule that decided. (Session 17's telemetry follows the same rule.)

## 5. For step 2 — attack your own service

- Post a "delivered" event to your push endpoint with no key, a wrong key, and another partner's key.
- Fetch a consignment by a number you were not given.
- Send the same event twice, and the same file twice.

## 6. Who would agree to an accepted risk

Nova's side: **Arun Deshpande** for partner connections and credentials; **Rahul Menon** for what agents may
see. Not the group.

## Before you finish step 2

- [ ] Every row of section 2 is a threat, or struck out with one line saying why
- [ ] Partner identity on the push API is T-01 or close to it
- [ ] The duplicate and conflict rule has a test named after the threat it answers
- [ ] No address or phone number in any log line or response that does not need it
