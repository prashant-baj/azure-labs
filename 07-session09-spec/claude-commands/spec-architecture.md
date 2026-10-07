---
description: Propose an architecture and stack — options compared against your drivers. The group decides.
argument-hint: "[slice folder, e.g. specs/001-first-slice]"
---
Slice folder: $ARGUMENTS (if empty, use the only `specs/NNN-*` folder).

Read `constitution.md`, `<slice>/spec.md`, everything in `specs/design/` — especially
`nfr-register.md`, `constraints.md`, `integration-decisions.md` and every ADR in `specs/design/adr/` —
and `templates/adr-architecture.md`.

**First, ask the group one question and wait for the answer:**
"Which languages and frameworks can at least two of you build with, and debug without help?"
Record the answer as the *Team* driver, source "the group, Session 9". Do not answer it for them.

Then create `specs/design/adr/<next free number>-architecture-and-stack.md` from the template.

Rules:
- **You propose. The group decides.** Leave section 4 as `[DECISION NEEDED: …]` and the status as
  `proposed`. Do not write the decision sentence.
- **Drivers first.** Fill section 1 before any option. Every driver names an ID or the group's answer,
  and the file it came from. Only drivers from our files — nothing you think a system "usually" needs.
- **At least two options** for the architecture, and at least two for each layer of the stack. One of
  the architecture options should be the simplest shape that could work — often one deployable.
- **Every reason names a driver.** "Fits NFR-001", "costs us C-001". A reason with no driver is
  deleted.
- **No popularity, no benchmarks, no numbers** unless they are in our files. "Widely used", "modern",
  "industry standard" and "scales well" are not reasons on their own — say which driver needs it.
- **Do not plan for scale nobody asked for.** If no NFR or constraint asks for it, it is not a reason.
- If a **program shortlist** or rule is given in `constitution.md` or `specs/design/constraints.md`,
  every option comes from it.
- If a driver cannot be judged from our files, add `[NEEDS CLARIFICATION: <question>]` to section 6,
  with who can answer.
- If an architecture-and-stack ADR is already **accepted**, stop. Do not edit it — say that a change
  needs a new ADR that supersedes it.
- **Do not touch `spec.md`.** The spec stays free of technology.

When you finish, print:
- the drivers, one line each
- the comparison, in five lines or fewer
- your recommendation and the driver IDs behind it, labelled clearly as a recommendation
- this line: "The group decides. Write the decision sentence in section 4, set Status to accepted,
  add your names, and commit: `adr: architecture and stack`."
