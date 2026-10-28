# Stories NNN — <slice name>

*Lives next to `spec.md`. A story is a promise of a conversation; the acceptance criteria are what the
conversation agreed. The requirements stay the source of truth — every story names the IDs it delivers.*

## US-001 · <the outcome, in the client's words>

**As** <a role from spec §2 — never "the user"> **I want** <what they can do or see>
**so that** <the reason the client gave>.

Delivers: FR-0nn, FR-0nn · Rule: RULE-0nn · Scenarios: `features/<file>.feature`

| AC | Given | When | Then | Proves |
|---|---|---|---|---|
| AC-1 | <a state> | <one event> | <an outcome someone can see> | FR-0nn / RULE-0nna |
| AC-2 | | | | |

Not in this story: <what it leaves out, and where it went — §9 or §10>

## Checklist for every story

- [ ] Names a real role from the concern sheet — not "the user"
- [ ] The *so that* is the client's reason, not the *I want* again
- [ ] Every AC is a Given / When / Then a person could check by hand
- [ ] Every AC names what it proves — a requirement or rule row
- [ ] Small enough to build and merge in a day
