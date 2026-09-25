# Story and acceptance criteria

## Story
As a **<specific role — from the concern sheet>**,
I need **<what>**,
so that **<why — the part you will defend when this is cut>**.

## Acceptance criteria

| Pattern | Use when | Example |
|---|---|---|
| `When <trigger>, the system shall <response>` | Something happens | When a partner reports a delivery, the system shall record the source and the time it arrived |
| `While <state>, the system shall <response>` | A state holds | While a consignment is in transit, the system shall show the most recent status received |
| `If <unwanted case>, then the system shall <response>` | The case nobody writes | If no update has been received past the promised date, then the system shall raise an exception |
| `The system shall <response>` | No condition | The system shall show the time at which each status was received |

## Before you accept a criterion
- [ ] Could a build fail this?
- [ ] If there is a number in it, who decided it and on what basis?
- [ ] Would two engineers read it the same way?
