# Spec NNN - <slice>.  Story US-0nn (stories.md).
# Every scenario carries the IDs it proves. Outline rows = the spec's rule rows, word for word.
@US-0nn
Feature: <the outcome, in business words>
  <the story's "so that" - why the client wants it>

  Background:
    Given <state every scenario needs - or delete the Background>

  @FR-0nn @RULE-0nn
  Scenario Outline: <the rule, as a sentence>
    Given <state, using <column>>
    When <one event>
    Then <an outcome someone can see, using <column>>

    Examples:
      | example   | column | column |
      | RULE-0nna |        |        |
      | RULE-0nnb |        |        |

  @FR-0nn
  Scenario: <an If ... then requirement - what happens when it goes wrong>
    Given <state>
    When <the bad day>
    Then <what the system does about it>
