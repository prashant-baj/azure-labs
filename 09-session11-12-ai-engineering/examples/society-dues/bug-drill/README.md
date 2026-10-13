# Bug drill — fifteen minutes

A resident wrote **"b304 oct"** in the remark. The treasurer says the payment went to the
unmatched list, although "B304" works fine. Your job: find out why, with evidence, before anyone
touches the code.

1. Copy `flat_in_remark.py` from this folder over `code/dues/flat_in_remark.py`.
2. Run the tests: `cd code && python -m pytest -q`. Do they catch it? *(Look at RULE-001b: which
   remark does it use?)*
3. Write the failing test **first**, from the resident's remark: `test_rule_001b_lowercase_remark`.
4. Run `/debug-evidence` with the failing test's output — the evidence, not your theory.
5. Smallest fix. All tests green. Commit: `fix: lowercase flat in remark (RULE-001b)`.

**The lesson:** the original tests passed with the bug, because no example used a lowercase
remark. The fix is two lines; the test that would have caught it is the real deliverable.
