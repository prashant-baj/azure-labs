# Spec 001 - match payments, show dues.  Story US-001 (stories.md).
# Every scenario carries the IDs it proves. The examples are RULE-001 from spec.md section 5 - same rows, same words.
@US-001
Feature: Each payment is matched to a flat, or set aside with a reason
  The treasurer stops matching payments by hand.
  "If they wrote the flat number, believe it - unless the flat doesn't exist.
   If they didn't, see who usually pays for that flat. If you still can't tell, don't guess."

  Background:
    Given the society has these flats
      | flat  | usual payer |
      | B-304 | Asha        |
      | C-101 | Ravi        |
      | C-102 | Ravi        |

  @FR-003 @RULE-001
  Scenario Outline: The flat comes from the remark, or from who usually pays
    When a payment arrives from <payer> with the remark "<remark>"
    Then it is matched to <flat>

    Examples:
      | example   | payer | remark          | flat  |
      | RULE-001a | Asha  | B-304 Oct maint | B-304 |
      | RULE-001b | Asha  | B304            | B-304 |
      | RULE-001d | Asha  | Oct maint       | B-304 |

  @FR-006 @RULE-001
  Scenario Outline: When the flat cannot be told, the payment is set aside with the reason
    When a payment arrives from <payer> with the remark "<remark>"
    Then it is not matched to any flat
    And the unmatched list shows it with the reason "<reason>"

    Examples:
      | example   | payer | remark    | reason                            |
      | RULE-001c | Asha  | Z-999     | flat in remark does not exist     |
      | RULE-001e | Ravi  | Oct maint | payer pays for more than one flat |

  @FR-004
  Scenario: The same payment from the UPI message and the morning file is counted once
    Given a payment from Asha with the remark "B-304" arrived by UPI
    When the morning statement brings the same payment again
    Then B-304 has one payment counted
