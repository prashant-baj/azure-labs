# Technical debt register

*Debt is fine when it is written down, with what it costs us and when we pay it back. Debt nobody
wrote down is not debt — it is a surprise waiting for a demo day.*

| ID | What | Where | Rule it breaks | Why we left it | What it costs while it stays | Pay back by | Owner | Status |
|---|---|---|---|---|---|---|---|---|
| TD-001 | The old notify key is in git history | commit before the refactor | W-004 | Removing it from code was quick; rotating it needs the committee | Anyone with repository access can read it | Layer 3 — before anything is deployed | Asha | open |
| TD-002 | Each record commits on its own; no transaction around a file load | `dues/sqlite_store.py` | NFR-002 | The loader is not built yet — no file load to wrap | A crash mid-file leaves a half-loaded day | Layer 3 — when the statement loader is built | Meena | open |
