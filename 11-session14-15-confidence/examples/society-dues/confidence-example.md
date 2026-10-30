# Confidence - CONFIDENT

*deploy · commit abc123 · 8 of 8 signals met · thresholds from specs/design/test-strategy.md*

| ID | Signal | Measured | Threshold | Source | Result |
|---|---|---|---|---|---|
| CS-001 | Unit, integration and scenario tests pass | 100 | = 100 | W-003, QG-007 | met |
| CS-002 | The suite only grows | 39 | >= 39 | ratchet — count at L5 start | met |
| CS-003 | Line coverage | 99.5 | >= 95 | ratchet — today's baseline | met |
| CS-004 | API checks pass on the running service | 100 | = 100 | FR-001, 003, 004, 006, 008, C-002 | met |
| CS-005 | The deployed service is this commit | 1 | = 1 | deploy | met |
| CS-006 | The treasurer's journey works end to end | 100 | = 100 | FR-008 | met |
| CS-007 | Dues answer, 95th percentile | 12.6 | <= 2000 | NFR-001 | met |
| CS-008 | Requests failing under load | 0 | < 1 | NFR-002, DEF-001 | met |

A signal that could not be measured is not confidence. Fix the report path, or the job that makes it.
