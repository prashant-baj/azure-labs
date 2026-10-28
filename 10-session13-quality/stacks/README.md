# BDD starters — one per stack

Each folder is a tiny project that **runs**: one feature file, thin step definitions, the rule built
test-first, unit tests. Same rule in all three (RULE-002 from the society-dues example), so you can compare.
Pick the one that matches your stack ADR. Do not copy the folder into your repo — copy the **wiring**
(dependencies, config, runner) and write your own scenarios and steps.

| Stack | Runner | Scenarios run with | Unit tests | Folder |
|---|---|---|---|---|
| Python | pytest-bdd | `python -m pytest tests/step_defs` | pytest | [`python/`](python/README.md) |
| Node / TypeScript | cucumber-js | `npx cucumber-js` | node:test, Jest or Vitest | [`node/`](node/README.md) |
| Java / Maven | Cucumber-JVM on the JUnit Platform | `mvn test -Dtest=RunScenariosTest` | JUnit 5 | [`java/`](java/README.md) |

Other stack (.NET, Go)? The ideas carry over: **Reqnroll** for .NET, **godog** for Go. Ask your facilitator,
and write the choice in an ADR.

## The same in every stack

- Feature files live **with the spec**: `specs/NNN-<slice>/features/`. Point the runner there.
- **Every scenario tagged** with the IDs it proves — `@FR-0nn`, `@RULE-0nn`, `@US-0nn`.
- **Steps are thin.** Turn words into a call, call the application, compare. The rule is never in a step —
  then the scenario would test the step, not your system.
- **Strict:** an undefined step is a failure, not a skip.
- **A junit report**, so each scenario shows by name in the merge request (`ci/scenarios.yml`).
- **Money is never a float.** `Decimal`, `BigDecimal`, or integer paise.

## Try one

```bash
cd python && pip install -r requirements.txt && python -m pytest -q
cd node   && npm install && npm test && npx cucumber-js
cd java   && mvn -q test
```

Then break the rule on purpose (`<= 0` → `< 0`) and watch two scenarios and two unit tests go red.
