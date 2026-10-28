# TDD log — RULE-002, "has this flat paid this month?"

*Pair: one driver, one navigator. The assistant wrote code; the people wrote — or approved — every test
first, and watched it fail before any code. One commit per step, so the history tells the story:*

```
git log --oneline -- dues/month_status.py tests/test_rule_002.py
e7c1a40 refactor: RULE-002 amounts as Decimal; status derives paid and balance
9b2f113 test: RULE-002 instalments in paise add up exactly (red)
51d08ce test: RULE-002c part payment shows the balance (green at once - broken on purpose, then kept)
c3a9e27 feat: RULE-002b sum every payment of the month (green)
f40b6d2 test: RULE-002b two payments cover the dues (red)
a18e5c9 feat: RULE-002a one full payment is paid (green)
2d7710b test: RULE-002a one payment of the full dues is paid (red)
86fe0b1 feat: RULE-002d no payment leaves the whole dues (green)
0c4d8e2 test: RULE-002d no payment leaves the whole dues (red)
```

## Cycle 1 — RULE-002d, no payment

**Red.** `test_rule_002d_no_payment_leaves_the_whole_dues`. First run: `ModuleNotFoundError: dues.month_status`.
That is red for the *wrong* reason — it proves nothing about the rule. A stub that returns nothing made it
fail on the assertion instead: `AttributeError: 'NoneType' object has no attribute 'paid'`. Now it is red
for the right reason.

**Green.** The simplest thing: `return MonthStatus(paid=False, balance=dues)`. Yes, it ignores the payments.
That is the point — the next test will force them in.

## Cycle 2 — RULE-002a, one full payment

**Red.** `assert month_status(2500, [2500]).paid` → `assert False`.
**Green.** `paid = bool(payments) and payments[0] >= dues`. Still deliberately simple.

## Cycle 3 — RULE-002b, two payments

**Red.** `[1500, 1000]` → not paid, because only the first payment counted. The test found the shortcut
from cycle 2 — that is what it is for.
**Green.** Sum every payment of the month.

## Cycle 4 — RULE-002c, a part payment

**Green at once.** The sum from cycle 3 already gives a balance of 1500. A test that passes on its first
run has not proved it *can* fail. So we broke the code on purpose — `balance = dues` — watched it go red,
put the code back, and kept the test. *(Ask the assistant: "Change the code so this test fails. Did it?")*

## Cycle 5 — instalments, and the refactor

**Red.** The treasurer's example from the map: three UPI instalments, `75.23 + 367.28 + 2057.49`.
With `float` amounts, `sum()` gives `2499.9999999999995` — the flat is "not paid" and gets a reminder for
half a paisa. The engineering rule already said *money is never a float*; this test is the rule, enforced.
**Green and refactor, with every test green after each move:**
- amounts as `Decimal`; the store converts at the edge (`amounts_by_flat`)
- `MonthStatus` keeps `dues` and `paid_so_far`; `balance` and `paid` are derived, so they can never disagree
- no new behaviour in the refactor commit — the tests did not change

## What we did not build

An overpayment makes the balance negative. Should it carry forward to next month? That is **Q3** in the
spec, open, with the committee. There is no test and no code for it — the code does not guess what the
client has not decided. `paid` is still right for an overpayment (`balance <= 0`), and that is all this
slice promises.

## Where the scenarios came in

`features/reminders.feature` was written **before** cycle 1, from the acceptance criteria — and ran red
(steps undefined, then `reminder_list` missing). It went green only after `reminders.py` used
`month_status`. The scenarios were the outer loop; the five cycles above were the inner one.
