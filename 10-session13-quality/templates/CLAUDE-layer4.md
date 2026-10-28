
## Layer 4 — quality first: set the bar, prove the behaviour (Session 13)

- **Quality gates live in the spec**: `specs/design/quality-gates.md`. Each gate names the rule it enforces, its
  tool, threshold, whether it blocks, and today's baseline. `ci/quality.yml` follows it — never the other way.
- **Never lower a gate, widen a suppression or raise a baseline to make a finding pass.** Findings are triaged
  one at a time (`/triage-findings`): fix, false positive (inline, that line only, with the reason), accepted
  risk (with a review date) or debt. A real secret is never accepted — it is revoked, then removed.
- Before proposing a push, suggest running `quality-local` from the lab folder.

- **The spec changes first.** Examples and answers go into `spec.md` (rule rows, §10, §11) before any story,
  scenario or code. Never invent an outcome, number or client decision — write `[NEEDS CLARIFICATION]`.
- **Stories plan, requirements rule.** `stories.md` — every story names the FR/RULE IDs it delivers; every AC
  is Given/When/Then and names what it proves.
- **Scenarios live with the spec**: `specs/<slice>/features/*.feature`. Every scenario is tagged with the IDs
  it proves. Declarative, business words, one behaviour each. Outline rows = rule rows, word for word.
- **Steps are thin.** A step calls the application. It never contains the rule.
- **Test first, seen red.** One example per cycle (`/tdd-cycle`): red for the right reason, the simplest green,
  refactor on green. A test that passes at once is broken on purpose before it is kept. Never edit a test to
  make it pass. Commit each step: `test: … (red)`, `feat: … (green)`, `refactor: …`.
- Scenarios and unit tests run in the pipeline on every push, with a junit report.

### Commands (layer 4)

| Command | What it does |
|---|---|
| `/quality-gates` | Writes `specs/design/quality-gates.md` from the rules and `.quality/local-report.md`; then aligns `ci/quality.yml` |
| `/triage-findings <gate>` | One finding at a time: fix, false positive, accepted risk or debt — each with a reason |
| `/example-map <slice> <ID>` | Scribe for an example-mapping session: story, rules, examples, questions. Writes `example-map.md` |
| `/spec-stories <slice>` | Map → spec rule rows and questions, then stories and AC. Every diff shown; applied on a yes |
| `/spec-scenarios <slice> <US-0nn>` | Gherkin from the AC, tagged with IDs, in `specs/<slice>/features/`. Runs them red |
| `/tdd-cycle <slice> <example>` | One red–green–refactor cycle. Stops for you between steps. Appends `tdd-log.md` |
| `/review-scenarios <slice>` | BDD smells and ID gaps. Finds; never fixes |
