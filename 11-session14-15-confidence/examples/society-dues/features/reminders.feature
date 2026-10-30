# Spec 001 - match payments, show dues.  Story US-002 (stories.md).
# RULE-002 was found in the example-mapping session (example-map.md) - open question 1, answered by the treasurer.
@US-002
Feature: The reminder list leaves out every flat that has paid this month
  The treasurer sends reminders only to flats that still owe - never to someone who paid this morning.

  Background:
    Given this month's dues are 2500 for every flat
    And the society has the flats B-304, C-101 and D-210

  @FR-008 @RULE-002
  Scenario Outline: A flat is paid when its payments this month cover the dues
    Given <flat> has paid <payments> this month
    When the treasurer asks for the reminder list
    Then the reminder list <shows or leaves out> <flat>
    And the balance of <flat> is <balance>

    Examples:
      | example   | flat  | payments    | shows or leaves out | balance |
      | RULE-002a | B-304 | 2500        | leaves out          | 0       |
      | RULE-002b | B-304 | 1500 + 1000 | leaves out          | 0       |
      | RULE-002c | B-304 | 1000        | shows               | 1500    |
      | RULE-002d | B-304 | nothing     | shows               | 2500    |

  @FR-008
  Scenario: A flat that paid by UPI this morning is not reminded
    Given C-101 paid 2500 by UPI this morning
    When the treasurer asks for the reminder list
    Then C-101 is not on the list
    And B-304 and D-210 are on the list
