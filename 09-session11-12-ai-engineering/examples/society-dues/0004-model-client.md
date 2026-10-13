# ADR 0004 — A client library for the suggestion model

*Date: Session 12 · Status: accepted · Decided by: the group (invented)*

## Context
FR-009 needs a model. ADR 0003 named no library for calling one. Finding 7 in `L3-validation.md`.

## Decision
We will call the model through its official Python client, only from `dues/claude_suggester.py`,
listed separately in `requirements-ai.txt` so the rest of the system builds and tests without it.

## Alternatives considered
- **Plain HTTP calls** — one less library, but we would write retries and error handling ourselves.
- **No model; a stricter rule instead** — kept as the fallback: FR-011 means the system works without it.

## Consequences
**Good:** one file knows about the model; tests use a fake.
**Bad:** a new dependency to keep up to date.
**Later:** if the society changes provider, only the adapter changes — a new ADR first.
