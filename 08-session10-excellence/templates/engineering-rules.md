# Engineering rules — the starter list

Pick **five to seven** for `constitution.md` section 5. Keep only what your group will actually check.
A rule nobody checks is a wish. You can add more later — through the change log, like any rule.

| ID | Rule | Checked by | Comes from |
|---|---|---|---|
| E-001 | Names come from the glossary — the client's words in code, tables and APIs | Review — MR checklist | Constitution section 1 |
| E-002 | One job per module or class. If you need "and" to say what it does, split it | Review | Single responsibility |
| E-003 | Functions stay small and simple — a complexity limit is set in the linter | Linter | Clean code |
| E-004 | The rule depends on nothing outside it. Inputs, storage and notifications sit behind interfaces (ports); the rule imports no framework, database or HTTP library | A test that runs the rule with no database; an architecture check | Dependency inversion |
| E-005 | No magic values — thresholds, codes and messages have names | Review; linter where your stack has a rule | Clean code |
| E-006 | No silent failures — no catch-all that hides an error. Every failure reaches a person or a log | Linter (blind or empty catch) | W-006 |
| E-007 | One rule, one place — no copy-pasted logic | Duplication check | Clean code |
| E-008 | Configuration and secrets come from the environment, never from code | Secret scan in the pipeline | W-004 |
| E-009 | Every requirement ID has at least one test that names it | `check-excellence` | W-002 |
| E-010 | Formatting is the formatter's job, not the reviewer's | Formatter in the pipeline | — |
| E-011 | Comments say **why**, not what | Review | Clean code |
| E-012 | No code without a task — every commit names a task ID | `check-excellence` | W-002 |

## Optional rules — from principles and patterns

Add one of these **only when your spec has the situation it describes**. Examples, smells and
tests for each are in the labs repository: `08-session10-excellence/principles/` and `patterns/`.

| ID | Rule | Checked by | Comes from |
|---|---|---|---|
| E-013 | A rule that varies by type is one strategy per variant behind one interface — no if/elif chain on the type | Review; a test that adds a variant without editing old ones | Open–closed · Strategy |
| E-014 | Every port's promise (inputs, outputs, errors) is written on the interface; one contract test runs against every adapter and every fake | Contract test, parametrised over all implementations | Liskov substitution |
| E-015 | Components depend on the smallest interface they use; read-only components get a read-only interface | Review against plan §12 "Depends on" | Interface segregation |
| E-016 | Outside formats stop at an adapter — no partner field names past the adapters folder | Review; a pipeline grep for partner field names | Adapter |
| E-017 | All database access is inside repositories; every query uses parameters, never string-building | Review; ruff `S608` / SpotBugs / eslint-plugin-security | Repository · W-004 |
| E-018 | One use case per user goal, named verb + object; controllers only translate the request and call it | Review against plan §12 | Use case · single responsibility |
| E-019 | Follow-ups to a domain event are listeners, not calls inside the component that raised it | Review against plan §12 | Publisher · open–closed |

## Your stack, your tools

Use what fits the stack in your ADR. If a tool is not in the ADR, adding it is a small decision —
note it in the ADR's consequences or in a new ADR.

| Check | Python | Java | Node / TypeScript | .NET |
|---|---|---|---|---|
| Format (E-010) | `ruff format` | Spotless | Prettier | `dotnet format` |
| Lint and complexity (E-003, E-006) | `ruff` — `C901`, `BLE` | Checkstyle, PMD | ESLint — `complexity`, `no-empty` | Roslyn analyzers |
| Duplication (E-007) | jscpd | PMD CPD | jscpd | jscpd |
| Architecture (E-004) | import-linter | ArchUnit | dependency-cruiser | NetArchTest |
| Secrets (E-008) | gitleaks | gitleaks | gitleaks | gitleaks |
| Tests, with a JUnit report | `pytest --junitxml` | Maven Surefire | Jest with `jest-junit`, or Vitest | `dotnet test` with a JUnit logger |

## How to write it into the constitution

```markdown
## 5. Engineering rules — how we write code

| ID | Rule | Checked by | Source |
|---|---|---|---|
| E-002 | One job per module. If you need "and" to say what it does, split it | Review | `specs/design/nfr-register.md` — maintainability |
```

The **Source** column works as before: your maintainability NFR, a W- rule, your ADR, or this
starter list. Add a row to the constitution's change log.
