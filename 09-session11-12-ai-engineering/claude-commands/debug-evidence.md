---
description: Debug with evidence — reproduce, hypothesise, prove, then the smallest fix and the test that would have caught it
argument-hint: "[the failing test, error message, or symptom]"
---
The problem: $ARGUMENTS

Work in this order and show each step:

1. **Reproduce.** Run the failing test or the steps that show the problem. If you cannot reproduce
   it, stop and ask for the exact input, output and environment. Do not fix what you cannot see.
2. **Evidence.** Collect what the system actually says: the full error, the stack trace, the input
   that fails, the input that works. Quote it. No guesses yet.
3. **Hypotheses.** Up to three possible causes, most likely first, each with the evidence for it.
4. **Prove one.** The smallest experiment that confirms or kills the top hypothesis — a print, a
   single test, a different input. Run it. If it is killed, move to the next.
5. **The missing test.** Write a test that fails because of this bug, named after the requirement it
   breaks. Run it: it must fail.
6. **The smallest fix.** Change as little as possible. Run the whole suite: everything green, no test
   edited except the new one.
7. **Root cause in one sentence** — and why the existing tests did not catch it.

Never change unrelated code "while you are there". Do not commit; suggest `fix: <what> (<ID>)`.
