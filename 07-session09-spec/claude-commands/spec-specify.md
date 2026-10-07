---
description: Assemble spec.md for one slice from the group's own files — every line with an ID and a source
argument-hint: "[slice folder, e.g. specs/001-first-slice]"
---
You are assembling a specification from this group's own records. You are not inventing one.

Slice folder: $ARGUMENTS
If that is empty, use the only folder under `specs/` whose name starts with three digits. If there is
more than one, stop and ask which.

Read, in this order:
1. `constitution.md`
2. `<slice>/spec.md` — **section 0 was written by the group, by hand. It defines the slice.
   Never change section 0.**
3. `specs/design/` — solution-definition, integration-decisions, contracts/, adr/, nfr-register, constraints
4. `docs/` — the evidence from Module 1
5. `CLAUDE.md` — the glossary
6. `templates/spec.md` — the format. Follow it exactly.

Fill sections 1 to 10 of `<slice>/spec.md`.

Rules:
- Only what section 0 covers. Anything else goes in section 9 with the reason.
- Every row has an ID (`IN-`, `FR-`, `RULE-`, `NFR-`, numbered from 001) and a Source: the file and
  section it came from, for example `design/solution-definition.md §6` or `docs/02-evidence-log.md`.
- If our files do not say it, **do not guess**. Write `[NEEDS CLARIFICATION: <question>]` in that row
  and add the question to section 10 with who could answer it.
- Requirements in EARS form. At least one `If <unwanted case>, then the system shall …` row.
- **No technology names.** No languages, frameworks, databases, cloud services or products. "Call",
  "message" and "file" are the only words allowed for how something arrives.
- Section 5: write the rule as the client would say it, then give worked examples — given this,
  expect that — taken from our files.
- Do not add a requirement nobody in our files asked for. If you think one is missing, put it in
  section 10 as a question.
- Use the client's words from the glossary.

When you finish, print:
- the number of requirements by type (IN, FR, RULE, NFR)
- the number of `[NEEDS CLARIFICATION]` markers
- the three rows you are least sure of, and why
