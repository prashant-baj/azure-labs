# Session 16 · Case notes for Group 5 — EcoNova Enterprises

*`setup-production` copies this file into your repo as `specs/design/threat-notes.md`, so `/threat-model` reads it
with the rest of your design. These are **checks, not answers**: each one is a question to try against your own code and
your own deployed service. Keep the threats that are real for your slice. Strike out the ones that are not, with
one line saying why.*

**Your slice, as planned:** data pulled from two stubs on different refresh cycles, ordered transformation rules
applied, a measure published with its definition attached, and a notification when a definition changes.

Your case's damage is quiet. Nothing leaks and nothing crashes: a number changes, nobody says why, and a regional
manager stops trusting the reports. That is exactly what happened to Adaeze. **Integrity and traceability of
definitions** are your main assets.

---

## 1. What you protect

| Asset | Why it matters in this case |
|---|---|
| The definitions: what each measure means, and the order the adjustments run in | Tobias's sequence. The order matters — done the wrong way round, it double counts |
| The published measures | Leadership acts on them. A silently changed figure costs trust that is hard to win back |
| The record of *who changed a definition, when, and why* | Without it, the next "the number moved" conversation has no answer |
| Financial figures before they are published | Revenue by region is sensitive until it is reported |
| The source systems | Rajiv: the main system "runs the factories" and cannot take reporting load in the day |

## 2. Threats to check, letter by letter

| STRIDE | Check this in your slice |
|---|---|
| **Spoofing** | Who may change a definition or the rule order? Is that a separate, stronger permission than reading a measure? Can a header alone grant it? |
| **Tampering** | Can a definition change take effect **without** the notification firing? Can a caller reorder the rules, or publish a measure with a definition other than the one stored? Can a stub extract inject a row that changes a figure? |
| **Repudiation** | For every published figure: which definition version, which rule order, which source extracts, which time? Can you reproduce last month's number? |
| **Information disclosure** | Are unpublished figures readable by anyone with the URL? Do regions see each other's numbers if they should not? |
| **Denial of service** | Rajiv's constraint is a security concern too: what stops your service — or a caller hammering it — from querying the main system during the working day? Your credential to the source should be **read-only**, and your pull should respect its window |
| **Elevation of privilege** | Is there an "apply this adjustment manually" route? Who may call it, and is it recorded? |

## 3. Secrets in this case

The credentials your service uses to read each source system (read-only, one per source), and the key that
separates the people who may change definitions from everyone else. Each is a masked GitLab variable, never in a
test, and the app fails closed: no credential means no pull, never a stale number presented as fresh.

## 4. Never in a log or a metric

Individual customer or employee figures, if your extracts carry any. Log the measure, the definition version,
the rule order, the source and its refresh time.

## 5. For step 2 — attack your own service

- Change a definition with no key, and with only a role header.
- Change a definition and check that the notification fired — then try to change one so that it does not.
- Read an unpublished measure without credentials.
- Ask for a measure and check that its definition version comes back with it.

## 6. Who would agree to an accepted risk

**Ingrid Moller** as sponsor; **Rajiv Balakrishnan** for anything touching the main system; **Tobias Lehmann** for
the adjustment order. Not the group.

## Before you finish step 2

- [ ] A definition cannot change without a recorded who, when and why — and a notification
- [ ] Changing definitions is a separate permission from reading measures, with a test
- [ ] Every published figure carries its definition version
- [ ] The source credentials are read-only and in masked variables
