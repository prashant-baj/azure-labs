# Tasks 001 — match payments, show dues

*Built from: `plan.md` as of Session 9*

Format: `- [ ] T001 [P] <verb> <what> — FR-001 · done when: <check>`

## Phase 1 · Set up
- [ ] T001 Create the project skeleton with one passing test and a health check — W-002 · done when: the pipeline is green

## Phase 2 · Tests first — contracts and rule examples
- [ ] T002 Write the five RULE-001 examples as one table-driven test — RULE-001, FR-003 · done when: the test runs and fails for the right reason
- [ ] T003 [P] Write the contract test for the UPI payment message, including a malformed one — FR-001, FR-006 · done when: runs and fails
- [ ] T004 [P] Write the contract test for the statement file, including an unreadable line — FR-002, NFR-002 · done when: runs and fails
- [ ] T005 [P] Write the duplicate test: same bank reference from message and file — FR-004 · done when: runs and fails

## Phase 3 · The rule
- [ ] T006 Build the matcher so the RULE-001 examples pass — RULE-001, FR-003 · done when: T002 green
- [ ] T007 Add de-duplication by bank reference — FR-004 · done when: T005 green
- [ ] T008 Send unmatched payments to the unmatched list with the reason — FR-006 · done when: the RULE-001c and RULE-001e cases appear on the list

## Phase 4 · What comes in
- [ ] T009 Build the UPI receiver — FR-001 · done when: T003 green
- [ ] T010 [P] Build the statement loader with the in = recorded + unmatched count — FR-002, NFR-002 · done when: T004 green and the count is shown

## Phase 5 · What it keeps, and gives back
- [ ] T011 Write the test for a dues answer carrying source and time — FR-005 · done when: runs and fails
- [ ] T012 Build the dues answer, with the role check — FR-005, C-002 · done when: T011 green; a resident role is refused

## Phase 6 · What happens next
- [ ] T013 Write the test: a flat that paid this morning is not on the reminder list — FR-008 · done when: runs and fails
- [ ] T014 Build the reminder list — FR-008 · done when: T013 green

## Phase 7 · When it goes wrong
- [ ] T015 Write the test: no file today means a warning on every answer — FR-007 · done when: runs and fails
- [ ] T016 Build the missing-file warning — FR-007 · done when: T015 green

## Phase 8 · Quality checks
- [ ] T017 Run a load test with a month of payments and record the 95th percentile — NFR-001 · done when: the figure is written next to the threshold
- [ ] T018 Run the end-to-end path: UPI, file, dues, reminder list — FR-001, FR-002, FR-004, FR-005, FR-008 · done when: one flat goes through all of it, counted once

## Not yet

- Part payments on the reminder list — FR-008 — waiting for spec question 1
