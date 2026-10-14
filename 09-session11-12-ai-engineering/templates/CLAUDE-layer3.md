
## Layer 3 — make it work (Sessions 11 and 12)

- **One task at a time.** Plan first (`/task-plan`), wait for approval, then build (`/task-build`).
  Never touch a file the approved plan did not name without saying why first.
- **Test first, every task.** Name tests after requirement IDs. Never edit a test to make code pass.
- **Docs in the same change** — README "How to run", `trace.md`, an ADR when a decision changes.
- **Debug with evidence** — reproduce, quote the error, prove a cause, then the smallest fix and the
  test that would have caught it (`/debug-evidence`).
- **Reviews never decide.** `/review-mr` and the pipeline's AI review write findings with a rule ID
  and a place. People decide each one and resolve the thread. Never approve or merge.
- **The spec is reviewed, not rewritten.** `/spec-review` and `/spec-sync` find and ask; the group
  decides every change. Never edit `spec.md` without showing the diff and getting a yes. Never invent a
  number, rule or client decision — write `[NEEDS CLARIFICATION]`.
- **Improve with evidence.** Measure first, one improvement at a time, behaviour pinned by tests that
  pass without being edited (`/improve-component`).
- **Azure:** follow `specs/design/azure-lab-constraints.md`. Infrastructure is Terraform in `infra/`.
  Never write a secret value into a `.tf`/`.tfvars` file; never commit state; never run `apply` or
  `destroy` yourself — show the plan, a person applies.
- Your Claude Code login is for the coding tool only — never in the repository, a `.env` file or a CI
  variable for the product.

### Commands (layer 3)

| Command | What it does |
|---|---|
| `/task-plan <slice> <T0xx>` | Plans one task: files, tests, docs, risks, questions. Writes nothing |
| `/task-build <slice> <T0xx>` | Builds the approved plan, test first, docs in the same change. Does not commit |
| `/debug-evidence <symptom>` | Reproduce, evidence, hypotheses, proof, the missing test, the smallest fix |
| `/review-mr [base]` | The pipeline's review, run locally. Writes `ai-review.json` and `ai-review.md` |
| `/azure-gaps <slice>` | Maps the resources your specs need against the lab policy; asks pointed questions; writes `specs/design/azure-gaps.md` |
| `/azure-terraform <slice>` | Asks about your component, then writes `infra/` from `.claude/infra-starter/` (Container Apps). The person the team chose runs `apply`; every apply is logged in `infra/deployments.md` |
| `/validate-ai-code <slice>` | Four lenses — correctness, security, maintainability, compliance — with real tool results |
| `/spec-review <slice>` | Attacks the spec: ambiguity, untestable lines, missing If rows, conflicts, no source; asks the group; writes `reviews/spec-review.md` |
| `/spec-sync <slice> [base]` | Finds drift between spec, tasks, tests and code; the group decides spec change, code fix or debt |
| `/improve-component <slice> <component>` | Measures, proposes up to three improvements, makes the one the group picks — tests unedited |
