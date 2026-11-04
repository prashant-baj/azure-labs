# Session 16 · Case notes for Group 3 — PureFoods Global

*`setup-production` copies this file into your repo as `specs/design/threat-notes.md`, so `/threat-model` reads it
with the rest of your design. These are **checks, not answers**: each one is a question to try against your own code and
your own deployed service. Keep the threats that are real for your slice. Strike out the ones that are not, with
one line saying why.*

**Your slice, as planned:** three record types (goods-in, production, despatch) ingested from stubs, identifiers
resolved including the known defect, genealogy links built, and affected lots and destinations returned with a
confidence indicator where a link is inferred.

In your case the worst failure is not a leak. It is a **wrong answer believed**: a trace that misses an affected
lot, or one that sweeps in lots that were never affected. Integrity comes before confidentiality here.

---

## 1. What you protect

| Asset | Why it matters in this case |
|---|---|
| The genealogy links (supplier batch → delivery → run → lot → pallet → customer) | A recall decision rests on them |
| The difference between a **proven** link and an **inferred** one | Withdrawing too much is expensive; withdrawing too little is a safety failure |
| Customer allocation: who holds which pallets | Commercially sensitive, and needed fast on the night of a recall |
| How a trace was answered | Sandra must be able to show the authority *how the company knows* |

## 2. Threats to check, letter by letter

| STRIDE | Check this in your slice |
|---|---|
| **Spoofing** | Can anyone post goods-in or production records to your ingest? What proves a record came from a site, and from *which* site? |
| **Tampering** | Can a caller add, change or remove a link? Can an inferred link be presented as proven? Is the identifier-matching rule (including the goods-in defect Vikram hinted at) something a request can switch off or override? |
| **Repudiation** | For a trace answer: which records, which matching rule, which links were inferred, at what time? Can you reproduce yesterday's answer today? |
| **Information disclosure** | Who may see customer destinations? Does the trace API return them to every caller, or only to quality and the distribution centre? |
| **Denial of service** | A trace is a graph walk. What does a batch code that links to a very large tree do to response time — or a crafted code that matches everything? |
| **Elevation of privilege** | Is there a route that marks a lot as "cleared" or "withdrawn"? Who may call it? |

**Sandra's line.** "The notification deadline runs from awareness, not from certainty." Making traces faster also
makes the company *aware* sooner. That is not a security control, but it belongs in your accepted-for-now section
as a question for her: who is told when a trace first returns a hit?

## 3. Secrets in this case

Any credential the stubs or sites use to send you records, and the key that separates quality users from
everyone else. Each is a masked GitLab variable, never in seed data or a test, and the app fails closed without it.

## 4. Never in a log or a metric

Customer names and delivery addresses. Log the batch code, the record type, the site, the rule and the
proven/inferred flag.

## 5. For step 2 — attack your own service

- Post a goods-in record with no key and with a site you do not own.
- Ask for a trace as an ordinary caller, and see whether customer destinations come back.
- Try to create or change a link directly.
- Send a batch code with the goods-in defect, and check that the answer says *inferred*.

## 6. Who would agree to an accepted risk

**Elena Duarte** as sponsor; **Sandra Whitfield** for anything touching notification. Not the group.

## Before you finish step 2

- [ ] Proven and inferred links cannot be confused, and a test says so
- [ ] Record ingest proves which site sent it
- [ ] A trace answer can be reproduced: the records, the rule, the time
- [ ] Customer destinations are shown only to the roles that need them
