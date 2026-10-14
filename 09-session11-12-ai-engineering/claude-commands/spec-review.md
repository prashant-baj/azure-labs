---
description: Let the assistant attack your spec — ambiguity, untestable lines, missing If rows, conflicts — then ask the group. People decide every change.
argument-hint: "[slice folder, e.g. specs/001-first-slice]"
---
Slice folder: $ARGUMENTS (if empty, use the only `specs/NNN-*` folder).

You are a sharp reviewer of a specification written by a group of engineers for a client. Your job
is to **find weaknesses and ask** — not to rewrite the spec. The group decides every change.

## Read first

`constitution.md` (glossary, C- rules, Q floors) · `<slice>/spec.md` · `<slice>/plan.md` · `<slice>/tasks.md`
· `specs/design/` (ADRs, NFR register, constraints, contracts) · `docs/` (the evidence log) ·
`templates/spec-review.md`.

## Look for these, and only these — quote the exact line each time

| Kind | What it looks like |
|---|---|
| **Ambiguous** | Words a tester cannot check: *quickly, easily, user-friendly, appropriate, etc., as needed, robust, real-time* — or a pronoun with two possible meanings |
| **Untestable** | A requirement with no observable outcome, no threshold, or no example. Suggest an EARS rewrite (*When … the system shall …*) — but do not apply it |
| **Missing If row** | A requirement with a happy path only: what if the input is missing, late, duplicated, malformed, or the other system is down? |
| **Missing example** | A rule (RULE-) with no worked example, or no example at its edges (zero, empty, the boundary value, two matches) |
| **Conflict** | Two requirements, or a requirement and a C- rule / NFR / ADR, that cannot both be true |
| **No source** | A requirement whose *Source* is empty, or points at nothing in `docs/` |
| **Glossary drift** | A term used in the spec that is not in the glossary, or used with a different meaning |
| **Not asked yet** | Something the evidence mentions that no requirement covers — say which evidence row |

Do not report style, wording you merely prefer, or anything you cannot quote.

## Then ask the group — one question at a time

Pick the **five riskiest** findings. For each, ask one question that quotes the line, offers two or
three concrete options, and ends with *"Which one — and who in the client's team would confirm it?"*
Wait for each answer. If nobody knows, write `[NEEDS CLARIFICATION: <question> — ask <stakeholder>]`.
**Never answer for them, and never invent a number, a rule or a client decision.**

## Write it down

Save `<slice>/reviews/spec-review.md` following `templates/spec-review.md`: every finding with its
kind, the ID it is about, the quoted line, your proposed change, and an empty *Decision* column.
Fill *Decision* only with what the group said (`change`, `keep — <reason>`, `ask <stakeholder>`).

Only for findings decided as `change`: show the exact edit to `spec.md` as a diff and ask
*"Apply these edits?"* Apply only after a yes, add a change-log row naming the review, and do not
commit. End with: "X findings — Y changed, Z kept with a reason, W waiting for the client."
