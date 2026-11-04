# Session 16 · Case notes for Group 4 — Apex Industrial Manufacturing

*`setup-production` copies this file into your repo as `specs/design/threat-notes.md`, so `/threat-model` reads it
with the rest of your design. These are **checks, not answers**: each one is a question to try against your own code and
your own deployed service. Keep the threats that are real for your slice. Strike out the ones that are not, with
one line saying why.*

**Your slice, as planned:** a document received through a channel, its type and expiry extracted, the original
retained unaltered, expiry tracked, a chase event emitted, a flag set and cleared on a stub ERP endpoint, and a
log of who could have known when.

Two stakeholders have already written part of your threat model for you. Claudia: "The signed contract is the
legal record. Whatever your system extracts from it is a convenience, not evidence." Peter: "What I ask for is
proof that you knew."

---

## 1. What you protect

| Asset | Why it matters in this case |
|---|---|
| The original document, exactly as received | Claudia's legal record. If it changes, it is no longer evidence |
| The extracted type and expiry date | They drive the chase and the gate flag. A wrong date means a lapse nobody sees, or a lorry turned away |
| The compliance flag on the ERP | It decides whether a lorry enters a plant |
| The "who could have known when" record | Peter's audit proof |
| Supplier documents | Insurance, certifications and contracts are commercially sensitive, and may carry personal details |

## 2. Threats to check, letter by letter

| STRIDE | Check this in your slice |
|---|---|
| **Spoofing** | Can anyone upload a certificate *as* a supplier? Can anyone set or clear the ERP flag by calling your service, or the stub, directly? |
| **Tampering** | Is the original stored unaltered — and can you prove it (a hash recorded on receipt and checked later)? Can a caller edit an extracted expiry date without it being recorded who changed it? |
| **Repudiation** | Peter's question: for each lapse, who was told, when, and what did the system show them? Is that record append-only? |
| **Information disclosure** | Can one supplier fetch another supplier's documents by changing an ID? Are documents served only to procurement roles? |
| **Denial of service** | Nearly half the documents arrive as photographs or scans. What do a very large image, a PDF bomb, or a thousand uploads do to your extraction? |
| **Elevation of privilege** | Who may clear a flag by hand? Is clearing a flag a separate, recorded permission from viewing one? |

**Untrusted files.** Every document comes from outside Apex. Check the type by content, not by file name; cap the
size; never execute or render it as it arrives. If your extraction library is new to the group, `/secure-review`
it — parsers of untrusted files are a classic weak point.

## 3. Secrets in this case

The credential your service uses to set the ERP flag (the most powerful secret in your slice), and the key that
separates procurement users from everyone else. Each is a masked GitLab variable, and the app fails closed without
it: no ERP credential means no flag change, never a silent success.

## 4. Never in a log or a metric

Document content, and any personal details inside a certificate. Log the supplier ID, the document type, the
expiry, the hash and the decision.

## 5. For step 2 — attack your own service

- Upload a document with no key, and as a different supplier.
- Fetch another supplier's document by changing the ID.
- Call the flag route — and the stub ERP itself — without credentials.
- Change an extracted expiry date and look for the record of who changed it.

## 6. Who would agree to an accepted risk

**Claudia Rossi** for anything about what counts as evidence; **Peter Nwosu** for audit; **Henrik Lund** as
sponsor. Not the group.

## Before you finish step 2

- [ ] The original is provably unaltered (a hash on receipt, checked by a test)
- [ ] The ERP flag can only be changed by your service, with its secret, and every change is recorded
- [ ] Suppliers cannot see each other's documents, and a test says so
- [ ] "Who could have known when" is append-only
