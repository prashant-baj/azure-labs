# Measuring the qualities — a reference card

Every line in your register needs a **metric** (what you measure) and a **threshold** (the number).
The targets below are **examples of the shape**, not standards to copy. Your numbers come from the
business, with a person's name against each one.

| Quality | What you measure | Example target | How you check it |
|---|---|---|---|
| Performance | Response time at the 95th percentile (not the average). Throughput: requests per second. | 95% of status lookups return within 2 seconds, at month-end load. | A load test before release. Application Insights in production. |
| Scalability | The highest load at which the speed target still holds. Time to add capacity. | Handles three times today's peak volume with the same response time. | Step the load test up until the target breaks. Note where. |
| Availability | Uptime % = time it worked ÷ total time, over a stated period. | 99.5% a month, round the clock (about 3.6 hours down allowed in a 30-day month). | An outside check that calls it every few minutes. |
| Reliability | Error rate. Messages that failed or were doubled. Mean time to recover (MTTR). | Fewer than 1 in 1,000 messages land in the failed queue. Back within 30 minutes. | Count the failed-message queue. Time every incident. |
| Security | Open critical vulnerabilities, and their age. Secrets found in code. | No critical vulnerability open longer than 7 days. Zero secrets in the repository. | Dependency and secret scanning on every commit. |
| Maintainability | Lead time for a change (commit to production). How often a change breaks something. | A one-line rule change reaches production within a day. | Timestamps in the pipeline. |
| Usability | Task success rate. Time on task. Number of steps. | 4 out of 5 new users find an order's status in 3 steps or fewer, without help. | Watch five real users try it. Don't help them. |

**Two more that belong on the register:** operability (who gets called, and what they will see) and
compliance (rules you are handed, not requirements you gather).

**Why the 95th percentile?** Line up every response from fastest to slowest. The 95th percentile is
the time that 95 out of 100 requests beat. The average can look fine while one user in twenty waits
far too long.

**Available is not the same as reliable.** Available means it answers. Reliable means the answer is
right — every time.
