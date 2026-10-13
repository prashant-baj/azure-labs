
## Layer 3 — make it work (Sessions 11 and 12)

- **One task at a time.** Plan first (`/task-plan`), wait for approval, then build (`/task-build`).
  Never touch a file the approved plan did not name without saying why first.
- **Test first, every task.** Name tests after requirement IDs. Never edit a test to make code pass.
- **Docs in the same change** — README "How to run", `trace.md`, an ADR when a decision changes.
- **Debug with evidence** — reproduce, quote the error, prove a cause, then the smallest fix and the
  test that would have caught it (`/debug-evidence`).
- **Reviews never decide.** `/review-mr` and the pipeline's AI review write findings with a rule ID
  and a place. People decide each one and resolve the thread. Never approve or merge.
- **AI inside the product** suggests; a person decides. The model sits behind a port. Only the data
  the C- rule allows leaves the system. Every answer is checked against the allowed values.
- A product's model key is an API key from the environment — never a Claude Code login token, and
  never in the repository.

### Commands (layer 3)

| Command | What it does |
|---|---|
| `/task-plan <slice> <T0xx>` | Plans one task: files, tests, docs, risks, questions. Writes nothing |
| `/task-build <slice> <T0xx>` | Builds the approved plan, test first, docs in the same change. Does not commit |
| `/debug-evidence <symptom>` | Reproduce, evidence, hypotheses, proof, the missing test, the smallest fix |
| `/review-mr [base]` | The pipeline's review, run locally. Writes `ai-review.json` and `ai-review.md` |
| `/validate-ai-code <slice>` | Four lenses — correctness, security, maintainability, compliance — with real tool results |
| `/spec-ai-feature <slice> <idea>` | Writes the AI feature into the spec first: FR, If rows, data rule, eval set |
| `/build-ai-feature <slice>` | Builds it behind a port: fake for tests, real adapter by config, guardrails tested |
