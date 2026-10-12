# Repository

> **Today SQLite, tomorrow a cloud database.** The rule reads and saves through a small, collection-like interface in glossary words. Only the repository knows SQL.

## When to use it

- The rule needs to save or find things, and you want to test it without a database.
- The storage may change (local file → managed database in Session 16–17).
- You want one place where every query lives — so a reviewer can check them all for injection.

## When not to

- A one-off script or report that is *only* a query. Run the query.
- Do not wrap your ORM in a repository that has a method for every ORM method — that is the ORM again, with extra steps.

## Structure

```
the rule ──▶ PaymentRepository (port: add, for_flat, exists)
                 ├── InMemoryPaymentRepository   ← tests, demos
                 └── SqlitePaymentRepository     ← the real one; all SQL here
```

`repository_example.py` · `test_repository.py` — **one contract test runs against both**. When you
add a cloud repository, it must pass the same test (that is Liskov substitution, see
[`../../principles/solid/l-liskov-substitution/`](../../principles/solid/l-liskov-substitution/)).

## In plan §12

| Component | Its one job | Exposes | Depends on | Pattern | Requirement IDs |
|---|---|---|---|---|---|
| SqlitePaymentRepository | Save and find payments | `PaymentRepository` | — | Repository | FR-001, C-001 |

Name methods in the client's words (`for_flat`, `exists`) — not `select_where`.

## In constitution §5

```markdown
| E-004 | The rule depends on nothing outside it — storage sits behind a repository interface | A test that runs the rule with the in-memory repository | Dependency inversion · ADR <nnnn> |
| E-017 | All database access is inside repositories; every query uses parameters, never string-building | Review; linter (ruff S608 / SpotBugs SQL injection / eslint-plugin-security) | W-004 · security |
```

If your constitution has a **never delete** rule (C-…), leave `delete` off the interface — then the
rule *cannot* break it.

## Misuse smell

- SQL, ORM sessions or `cursor` objects outside the repository folder.
- A repository that returns database rows instead of your own types.
- Business decisions inside the repository ("if overdue, also mark…").
