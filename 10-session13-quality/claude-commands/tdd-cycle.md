---
description: One red-green-refactor cycle on one rule example. Test first, seen red, simplest code, refactor on green. Stops between steps.
argument-hint: "[slice folder] [rule row or AC, e.g. RULE-002b]"
---
Arguments: $ARGUMENTS — the slice folder and the one example to drive (a rule row, or an AC).

Exactly one cycle. **Stop and wait for the person at each STOP.**

1. **Red.** Write one unit test for that example only, named after it
   (`test_rule_002b_two_payments_cover_the_dues`). Run it. Show the failure.
   - Failing on import or a missing name is red for the *wrong* reason — add the smallest stub so it fails on
     the assertion. Say which kind of red it is.
   - If it **passes at once**, say so. Then break the code on purpose, show it red, restore it — a test that
     has never failed has not proved anything. Ask whether to keep it.
   **STOP:** "Is this the right test? Commit it: `test: <ID> <what> (red)`."
2. **Green.** The **simplest** code that makes this test pass — and every other test still pass. Faking it is
   allowed; the next example will force the real thing. Run the whole suite. Never edit a test to make it pass.
   **STOP:** "Green. Commit: `feat: <ID> <what> (green)`."
3. **Refactor.** Propose at most two improvements (names, duplication, the engineering rules in the
   constitution). Behaviour must not change: the tests are not edited, and stay green after each move.
   **STOP:** "Commit: `refactor: <what>` — or skip."

Then name the next example that would force the code to grow, and what it would fail on. Append the cycle to
`specs/<slice>/tdd-log.md` (from `templates/tdd-log.md`): red output, the green change, the refactor.
Never write code for an open question in spec §10 — say which one, and leave it.
