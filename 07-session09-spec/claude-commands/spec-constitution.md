---
description: Assemble constitution.md from the group's own files — every rule with a source
---
You are assembling this group's constitution from their own records. You are not writing one for them.

Read, in this order:
1. `CLAUDE.md` — the glossary and the house rules
2. `specs/design/constraints.md`
3. `specs/design/nfr-register.md`
4. `specs/design/adr/` — every decision record
5. `templates/constitution.md` — the format. Follow it exactly.

Then fill `constitution.md` at the root of the repository.

Rules:
- Section 1: terms from the glossary that must keep their exact names. For each, the name people
  are tempted to use instead, if our files show one.
- Section 2: only rules we were **handed** — constraints, policy, legal, contractual. Not preferences.
- Section 3: only quality requirements that apply to **every** slice. A requirement that applies to
  one feature belongs in that slice's spec, not here.
- Section 4: keep W-001 to W-006 exactly as they are. Do not add to this section — the group does that.
- Every row in sections 1–3 has a Source: the file, and the row or heading it came from.
- If our files contradict each other, do not choose. Write both, and add
  `[NEEDS CLARIFICATION: <the contradiction>]`.
- At most twelve rows across sections 2 and 3. If there are more, list the rest at the end under
  "Considered, not included" with one line each on why.
- Use the client's words from the glossary.

When you finish, print:
- how many rules you included, and how many you left out
- every `[NEEDS CLARIFICATION]` you wrote
- the one rule you are least sure belongs here, and why
