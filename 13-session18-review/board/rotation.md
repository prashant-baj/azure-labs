# The board — rotation of stakeholder roles

The whole class is the board. While one group presents, **each of the other four groups plays one stakeholder** and
reviews only from that seat. The facilitator chairs, keeps the clock, and speaks as the **client**. Over the five
slots every group plays every role exactly once.

| Slot | Presenting | Security officer | Operations lead | Enterprise architect | QA and release manager |
|---|---|---|---|---|---|
| 1 | Group 1 · Nova Retail | Group 2 | Group 3 | Group 4 | Group 5 |
| 2 | Group 2 · Sterling National Bank | Group 3 | Group 4 | Group 5 | Group 1 |
| 3 | Group 3 · PureFoods Global | Group 4 | Group 5 | Group 1 | Group 2 |
| 4 | Group 4 · Apex Industrial | Group 5 | Group 1 | Group 2 | Group 3 |
| 5 | Group 5 · EcoNova Enterprises | Group 1 | Group 2 | Group 3 | Group 4 |

**The rule behind it:** the group one after the presenter is the security officer, two after is the operations
lead, three after is the enterprise architect, four after is the QA and release manager (counting round: after
Group 5 comes Group 1). What each role looks for, and the questions it asks: [`roles.md`](roles.md).

## Each slot — 12 minutes

| Minutes | What happens |
|---|---|
| 4 | **The presenting group shows** — the slice running, the business number on the dashboard, the last deploy scorecard, its own top three gaps |
| 5 | **The four stakeholders ask** — about 75 seconds each, in this order: security, operations, architecture, QA and release. Ask for evidence: "Show me the test." "Open the runbook." |
| 2 | **The client speaks** — the facilitator, in the voice of the case's people |
| 1 | **Each stakeholder reads out its findings** — one or two each, in the finding format. The presenting group's scribe types them into `specs/review/findings.md` as they are read, with the role in *Raised by* |

Five slots is an hour. Then ten minutes of triage, back in your own group.

## Before the board starts

- **Know your roles:** find your group's column in the table — you have four roles across the hour, one per slot.
- **Read the role** in `roles.md` before each slot: the checklist lines it owns and its five questions.
- **The presenting group** shares its `specs/design/readiness.md` on screen (or as a link) during its four minutes,
  and names one **scribe** who writes every finding into `specs/review/findings.md` as it is read out.

## While you present

One person presents, one drives the screen, the scribe writes. Do not argue with a finding in the slot — write it
down. You decide it in triage, and fix it in the next session.
