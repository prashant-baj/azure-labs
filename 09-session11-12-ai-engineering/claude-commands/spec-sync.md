---
description: Find where the spec and the code no longer agree — and let the group decide which one is wrong.
argument-hint: "[slice folder] [optional: base tag, default L2-design]"
---
Arguments: $ARGUMENTS — the slice folder, then (optionally) the tag to compare from.

Code written with an assistant drifts from the spec fast. Your job is to show **where** — not to
fix it silently.

## Read first

`<slice>/spec.md` · `<slice>/tasks.md` · `<slice>/trace.md` · the tests (find requirement IDs in
test names) · the code · `git log <base>..HEAD --oneline` (commits name tasks and requirements).

## Build the map, then list the drift

For every requirement ID (FR-, RULE-, NFR-, If rows): task(s) → test(s) → code. Then report:

| Drift | Meaning |
|---|---|
| **Requirement, no test** | Promised to the client, never proven |
| **Requirement, no code** | Not built — is that on purpose? |
| **Test or code, no requirement** | Built without being asked — gold plating, or a requirement nobody wrote down |
| **Behaviour not in the spec** | The code decides something the spec never said (a default, a limit, a rounding rule, an error message the user sees) — quote the code line |
| **Spec says one thing, code does another** | Quote both |
| **Stale trace** | `trace.md` points at a file, test or task that no longer exists |

For each drift, propose **one** of: *update the spec* (and who must agree), *fix the code* (as a new
task), or *log as debt* (TD- with a pay-back date). Do not choose for the group.

## Then

Ask the group to decide each row. Update `trace.md` only for rows they decided, and only after they
say yes. Spec changes go through `/spec-review`'s rule: show the diff, apply on a yes, add a
change-log row. New tasks go to `tasks.md` with the next free ID. Do not commit.

End with: "N requirements: P fully traced, Q with drift — R decided, S open."
