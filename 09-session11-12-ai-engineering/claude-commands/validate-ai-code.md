---
description: Validate AI-written code through four lenses — correctness, security, maintainability, compliance. Changes nothing.
argument-hint: "[slice folder] [optional: base, e.g. L2-design]"
---
Arguments: $ARGUMENTS — the slice folder, then optionally what to compare with (default: the tag
`L2-design`, so everything written in layer 3 is validated).

Read `CLAUDE.md`, `constitution.md`, `<slice>/spec.md`, `<slice>/plan.md`, every accepted ADR, and
`templates/validation.md`. Then read the change: `git diff <base>...HEAD`.

**Run the checks that exist** and quote their results — do not imagine them: the test suite; the
linter and formatter from the ADR's stack; a secret scan if `gitleaks` is installed; a dependency
audit if the stack has one (`pip-audit`, `npm audit`, `mvn dependency:tree`). If a tool is missing,
say so — that is a finding about the pipeline, not a pass.

Then review through the four lenses:

| Lens | Ask |
|---|---|
| **Correctness** | Does each change do what its requirement ID says? Every *If* row covered? Tests that cannot fail, or tests weakened to pass? Edge cases from the evidence log? |
| **Security** | Secrets; input used unchecked; queries or commands built from strings; role checks the spec asks for; what data leaves the system, and to whom; for AI features — instructions hidden in input data |
| **Maintainability** | Constitution section 5; the direction rule in plan section 12; code no task asked for; names against the glossary |
| **Compliance** | Every C- rule; nothing deleted that must be kept; new libraries without an ADR, and their licences; personal data in logs or prompts |

Write `<slice>/reviews/L3-validation.md` following the template. Every finding names a lens, a rule
ID and a `file:line`. At most twenty, most severe first. Also list up to three things already good.
**Leave Decision and By empty** — the group decides. Change no code.
