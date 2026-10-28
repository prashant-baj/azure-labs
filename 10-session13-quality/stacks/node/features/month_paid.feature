# A starter, not your case: RULE-002 from the society-dues worked example, in this stack.
# In your repo the feature files live in specs/NNN-<slice>/features/ - point the runner there.
@US-002
Feature: A flat has paid when this month's payments cover its dues
  The treasurer reminds only the flats that still owe.

  @FR-008 @RULE-002
  Scenario Outline: One payment or several, as long as they cover the dues
    Given the dues for the month are <dues>
    And the flat has paid <payments>
    When the treasurer checks the month
    Then the flat is <status> with a balance of <balance>

    Examples:
      | example   | dues | payments    | status   | balance |
      | RULE-002a | 2500 | 2500        | paid     | 0       |
      | RULE-002b | 2500 | 1500 + 1000 | paid     | 0       |
      | RULE-002c | 2500 | 1000        | not paid | 1500    |
      | RULE-002d | 2500 | nothing     | not paid | 2500    |
