# AI-suggested tests — review log

*`/suggest-tests` for FR-001 (a UPI payment is recorded) and FR-008 (the reminder list), Session 14.*

| ID | Suggested test | Decision | Seen red? | Why |
|---|---|---|---|---|
| FR-001 | Amount `0` is refused | **kept** (as a parametrize row) | yes — removed `gt=0` | The contract says a payment has a positive amount |
| FR-001 | Amount `12.345` is refused | **kept** | yes — removed `decimal_places=2` | Paise have two places; a third is a broken message |
| FR-001 | Amount `abc` is refused | **kept** | yes | Cheap, and the gateway has sent garbage before (evidence log row 9) |
| FR-001 | Amount above the month's dues is refused | **rejected** | — | The spec does not say so — overpayment is open question Q3. A test would have decided it for the client |
| FR-008 | A flat with two part payments covering the dues is not reminded | **not needed** | — | Already a scenario row (RULE-002b). But it showed there is no **API** check for it — on the homework list |
| FR-008 | The reminder list is sorted by balance | **rejected** | — | Nobody asked for an order. The assistant assumed one |

**Noticed:** two of six suggestions encoded a decision the client never made. Both were plausible. That is the
risk with AI-suggested tests: they look like requirements.
