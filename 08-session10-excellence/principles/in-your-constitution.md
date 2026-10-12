# From principle to constitution §5

A principle in a slide is a wish. A principle in `constitution.md` **with a "Checked by"** is a
rule the reviewer, the linter, the tests — and the AI review in Session 11 — will hold your code to.

## The test for every rule you add

1. **Can someone check it?** Name the reviewer question, the linter rule or the test. No checker → no rule.
2. **Will you actually check it?** Seven rules you check beat twelve you ignore.
3. **Does it trace back?** The *Source* column points at the glossary, an NFR, an ADR or a W-rule.

## Rows you can copy

The first block comes from `templates/engineering-rules.md` (already in your repo after
`setup-excellence`). The second block is **optional** — add a row only when your spec has the
situation it describes.

```markdown
## 5. Engineering rules — how we write code

| ID | Rule | Checked by | Source |
|---|---|---|---|
| E-001 | Names come from the glossary — the client's words in code, tables and APIs | Review — MR checklist | Section 1 · glossary |
| E-002 | One job per module or class. If you need "and" to say what it does, split it | Review against plan §12 | Single responsibility |
| E-003 | Functions stay small and simple — complexity at most <n> | Linter: ruff C901 / PMD / ESLint complexity | Clean code |
| E-004 | The rule depends on nothing outside it — storage, clock and notifications sit behind ports | A test that runs the rule with no database; import-linter / ArchUnit / dependency-cruiser | Dependency inversion · ADR <nnnn> |
| E-005 | No magic values — thresholds, codes and messages have names | Review | Clean code |
| E-006 | No silent failures — no catch-all that hides an error | Linter: ruff BLE / ESLint no-empty / SpotBugs | W-006 |
| E-011 | Comments say why, not what | Review | Clean code |
```

```markdown
| E-013 | A rule that varies by type is one class per variant behind one interface — no if/elif chain on the type | Review; a test that adds a variant without editing old ones | Open–closed · FR-<id> |
| E-014 | Every port's promise (inputs, outputs, errors) is written on the interface; one contract test runs against every adapter and fake | Contract test, parametrised over all implementations | Liskov substitution |
| E-015 | Components depend on the smallest interface they use; read-only components get a read-only interface | Review against plan §12 "Depends on" | Interface segregation · C-<id> |
```

Replace `<n>`, `<nnnn>`, `<id>` with **your** numbers. Do not copy a row whose checker you will not
set up.

## Where each principle shows up in your repo

| Principle | constitution §5 | plan §12 | Code review asks |
|---|---|---|---|
| Clean code | E-001, E-003, E-005, E-006, E-011 | — | "Would the treasurer recognise these names?" |
| Single responsibility | E-002 | *Its one job — no "and"* column | "Who would ask for this to change?" |
| Open–closed | E-013 | *Pattern* column: Strategy | "When the next one comes, which files change?" |
| Liskov substitution | E-014 | Ports listed with their promise | "Does the fake keep the same promise as the real adapter?" |
| Interface segregation | E-015 | *Depends on (interfaces only)* column | "Which of these methods does it actually use?" |
| Dependency inversion | E-004 | Component diagram arrows point inward | "Read only the imports — anything from outside?" |

## Ask the assistant, then decide yourselves

```text
/spec-engineering-rules
```

It proposes §5 from your stack, NFRs and W-rules. Hold its proposal against the three tests above.
**The group decides which rows stay** — and records the change in the constitution's change log.
