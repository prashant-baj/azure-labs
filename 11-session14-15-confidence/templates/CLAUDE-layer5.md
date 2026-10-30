
## Layer 5 — automate the confidence (Sessions 14 and 15)

- **The test strategy is spec**: `specs/design/test-strategy.md`. Its *Confidence thresholds* table is what the
  pipeline decides on (`ci/confidence.py`). Thresholds change only there, in a merge request, decided by the
  group — never in `ci/confidence.yml`, and never to make a scorecard pass.
- **The pipeline is drawn from the strategy** (section 6): every threshold row has a job that measures it, every
  job a row. Checks designed but not built yet are `(planned)` jobs that end orange — never green — and rows with a
  `planned.<name>` measure. Never make a placeholder pass, and never delete one without a line under
  "Not automated yet".
- **Every performance threshold quotes an NFR row.** No NFR? `[NEEDS CLARIFICATION]`, and ask who decides.
  Coverage and test counts are ratchets — today's measured number, never a round target.
- **A test at the lowest layer that can catch the problem.** Few end-to-end journeys — the ones the client
  would notice. Every test name starts with or contains the ID it proves (`FR-0nn`, `NFR-0nn`, `DEF-0nn`).
- **AI-suggested tests** are marked `ai_suggested`, seen red against a broken version before they are kept, and
  logged in `reviews/ai-tests.md`. An expected outcome the spec does not give is a question, not a test.
- **A failing check is evidence, not noise** (`/analyse-failure`): classify it, reproduce it at the lowest layer,
  pin it with a `DEF-0nn` test, then fix. Never re-run until green and call it fixed.
- No secrets, tokens or personal data in Postman collections, environments or test data. Secrets are pipeline
  variables passed in at run time.

### Commands (layer 5)

| Command | What it does |
|---|---|
| `/test-strategy <slice>` | Risks, layers, regression, AI-suggested tests, and the confidence thresholds — section by section, on a yes |
| `/suggest-tests <slice> <ID>` | Up to six tests for one requirement; each seen red before it is kept; logged |
| `/api-tests <slice> [url]` | The Postman collection from the spec — happy and failure paths, every test named after its ID |
| `/analyse-failure <job or test>` | Evidence, classification (real, test, environment, flaky), the regression test, the smallest fix |
