# Prompts that strengthen a spec — copy, paste, adapt

Use these in Claude Code (or any assistant) **with the files attached, not a summary**. Each prompt
makes the assistant *attack* the spec and *ask* — it never decides. Paste the answer into
`reviews/spec-review.md`, decide as a group, then change `spec.md`.

> Rule for all of them: "Quote the exact line for every finding. Do not rewrite the spec. Do not
> invent numbers, rules or client decisions — mark them `[NEEDS CLARIFICATION]`."

## 1 · Ambiguity hunt
```text
Read spec.md and the glossary in constitution.md. List every word or phrase a tester could not
check — "quickly", "user-friendly", "appropriate", "as needed", "real-time" — and every pronoun
with two possible meanings. For each: quote the line, say why it is untestable, and ask me the one
question that would make it testable.
```

## 2 · Make it testable (EARS)
```text
For FR-xxx to FR-yyy in spec.md, propose an EARS rewrite ("When <trigger>, the system shall
<response>"; "If <unwanted condition>, then the system shall …"). Keep the meaning. Where you need
a number or rule I have not given, write [NEEDS CLARIFICATION: …]. Show old → new side by side.
```

## 3 · Missing failure paths
```text
For every requirement in spec.md that has only a happy path, list the If rows it is missing:
missing input, late input, duplicate, malformed, the other system down, the person says no.
Quote the requirement. Ask me which ones the client actually cares about.
```

## 4 · Edge-case examples for a rule
```text
For RULE-xxx in spec.md, list worked examples at the edges: zero, empty, the exact boundary,
just over it, two possible matches, the oldest and newest record. For each, write the input and
leave the expected result as ??? — the client decides it, not you.
```

## 5 · Conflicts
```text
Compare every requirement in spec.md with the C- rules, Q floors and NFRs in constitution.md and
specs/design/, and with the ADRs. List any two lines that cannot both be true. Quote both. Do not
pick a winner.
```

## 6 · Evidence not covered
```text
Read docs/ (the evidence log) and spec.md. List anything a stakeholder said that no requirement
covers, with the evidence row. For each, ask: is this in scope for this slice, a later slice,
or out of scope — and who decides?
```

## 7 · Glossary drift
```text
List every domain term used in spec.md, plan.md and the code (class, table and field names) that
is not in the glossary in constitution.md, or is used with a different meaning. Quote where.
```

## 8 · Questions for the client
```text
From the open [NEEDS CLARIFICATION] items in spec.md and reviews/spec-review.md, write the five
questions we should ask the client next, most important first. Each: one sentence, the options we
see, who should answer, and what we will build differently depending on the answer.
```

## 9 · Spec and code drift
```text
Map every requirement ID in spec.md to tasks.md, test names and code. List: requirements with no
test, code with no requirement, and behaviour in the code the spec never mentions (defaults,
limits, rounding, messages) — quote the code line. Propose spec change, code fix or debt; do not
choose for me.
```

## 10 · Explain it back
```text
Explain spec.md back to me as the client would read it, in plain words, in under a page. Then list
the three things a client is most likely to misunderstand, and why.
```
