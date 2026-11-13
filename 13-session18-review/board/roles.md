# The board — four stakeholder roles

*What to see and how, one slide per concern: the workshop handout. Each role reviews from one seat only. Stay in it: the security officer does not ask about the dashboard, and the
operations lead does not ask about test coverage. One or two strong findings from your seat beat five vague ones
from everywhere. The client's seat belongs to the facilitator.*

**Every role, every slot:** listen for the evidence behind the checklist lines you own · ask for it in your 75
seconds · write **one or two findings** in the format below · and note one thing done well.

> **Finding format:** what you saw · the evidence (or that there was none) · the risk to the client · the smallest
> next step · severity (`high` would block go-live or harm the client · `medium` fix before the next release ·
> `low` an improvement). **Never who.**

---

## Security officer — "Can it be misused, and what proves it cannot?"

| You own | PR-08 – PR-11 · OR-09 · the threat model and the S16 case notes |
|---|---|
| Concerns | **Threats and controls** (PR-08, PR-10, case notes) · **Secrets and personal data** (PR-09, PR-11, OR-09) |

**Ask — pick two:**
1. "Show me T-01 — the threat, its control, and the test that failed before the fix."
2. "Where does the API key live? Show me it is in no file — not the Postman environment, not the Terraform."
3. "What happens when the secret is missing? Show me the 503."
4. "What did the last DAST scan find? Open `zap.html`."
5. "Which log line or metric attribute could carry a customer's name? Show me the test that says it cannot."

**Typical findings:** a role header that still gets in · a key value in a test or environment file · a threat with
no test · a risk accepted by the group, not the client · personal data in a log line.

---

## Operations lead — "Can someone else run it at two in the morning?"

| You own | OR-01 – OR-08, OR-10 – OR-12 · PR-14 · `ops/runbook.md` |
|---|---|
| Concerns | **Run and support** (OR-01–04) · **Recovery and resilience** (PR-14, OR-05, OR-06, OR-08) · **Change, cost and handover** (OR-07, OR-10–12) |

**Ask — pick two:**
1. "Roll it back — using only section 3 of your runbook." *(If you can, try it yourselves: that is their OR-12.)*
2. "The p95 alert fires at 2 a.m. Who gets it, and what are the first three steps?"
3. "What data do you keep, and what happens to it on a restart or a lab reset?"
4. "The key has leaked. Walk me through rotating it — without saying its value."
5. "What does the test environment cost a month, and who would notice if it doubled?"

**Typical findings:** no rollback step, or one nobody has tried · alerts that reach nobody · data that a restart
loses · no service level agreed with the client · a runbook only its authors can follow.

---

## Enterprise architect — "Does what was built match what was decided — and will it hold?"

| You own | PR-01 – PR-05 · the ADRs, the C4 views, the NFR register, the integration contracts |
|---|---|
| Concerns | **Requirements and decisions** (PR-01–03) · **Architecture and integration** (PR-04, PR-05) |

**Ask — pick two:**
1. "Which ADR decided the store you use? Does the code match it?"
2. "Pick an NFR. Where does the pipeline measure it?"
3. "Your slice calls something outside itself — what is the timeout, the retry rule, and what happens to a duplicate?"
4. "What would you have to change to add the next partner, plant or supplier your case says is coming?"
5. "Which dependency in the code did nobody decide?"

**Typical findings:** an ADR that says one thing and code that does another · an NFR nobody measures · an outside
call with no timeout · a design that gets harder with each new partner, site or supplier · an unrecorded library.

---

## QA and release manager — "How do you know it works — and that this version is the one running?"

| You own | PR-06, PR-07, PR-12, PR-13, PR-15 – PR-17 · the test strategy, the scorecard, the pipeline, the dashboard |
|---|---|
| Concerns | **Code quality and testing** (PR-06, PR-07) · **Release and confidence** (PR-12, PR-13) · **Observability** (PR-15–17) |

**Ask — pick two:**
1. "Open the last deploy scorecard. Which row would you look at first, and why?"
2. "Which requirement has no test named after it?"
3. "Show me the version on `/health` — is it the commit you just merged?"
4. "Read me your two numbers off the dashboard. What would make the alert fire?"
5. "Show me one request found by its `X-Request-Id`."

**Typical findings:** a scorecard row that is NOT MEASURED or NOT SET · a requirement with no test · alerts never
seen to fire · a business tile that counts HTTP calls, not business events · a planned job still orange.

---

## The client — the facilitator

Owns **customer value** — your case lines CR-01, CR-02, the business number and the feedback. Speaks as the case's named
people for two minutes: what they noticed, what worries them, and one new request.
Write it down in `specs/review/feedback.md`, in their words. **Never say yes in the room.**
