# O · Open–closed

> **Add new behaviour by adding code, not by editing code that already works.**

## The problem

`ocp_before.py` — one `if / elif` chain per unit type. The committee adds "shop" units and someone
edits the function that the residential and commercial fees already depend on. Every new type
re-opens tested code, and the chain grows every month.

## The fix

`ocp_after.py` — each rule is a small class with the same `fee()` method (the **Strategy** pattern,
see [`../../../patterns/strategy/`](../../../patterns/strategy/)). A registry maps unit type to rule.
A new unit type is **one new class and one new line**; the existing rules are not touched.

`test_ocp.py` runs the same cases against both versions, then adds a "shop" rule **without editing
`ocp_after.py`**.

## How to spot it

- A growing `if / elif` or `switch` on a *type* or *kind* field.
- The same `switch` appears in more than one place.
- A merge request for a new kind of thing edits five files that have nothing new in them.

## Review tip

Ask: *"When the client adds the next one, which files change?"* The answer should be "a new file
and one line", not "this function, again".

## In your constitution

An **optional** rule — add it to §5 only if your spec has rules that vary by type. (E-001…E-012 come from `templates/engineering-rules.md`; extras start at E-013.)

```markdown
| E-013 | A rule that varies by type (plan §12 names it) is one class per variant behind one interface — no if/elif chain on the type. | Review; a test that adds a variant without editing old ones |
```

## Do not overdo it

Two cases that will never be three do not need a registry. Use it when the spec **already** lists
several variants, or the client has said more are coming.
