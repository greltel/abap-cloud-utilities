"! <p class="shorttext synchronized" lang="EN">Regular expression match</p>
"! One occurrence of a pattern in a text: where it is, what it covers and what
"! its capture groups caught. Immutable. Group 0 is the whole match, groups
"! 1 to n follow the opening parentheses of the pattern from left to right.
INTERFACE zif_regex_match
  PUBLIC.

  "! Tells whether the pattern was found at all. The other methods return
  "! empty or zero values when it was not.
  "! @parameter result | abap_true when the text contains the pattern
  METHODS is_found
    RETURNING VALUE(result) TYPE abap_bool.

  "! The text covered by the whole match.
  "! @parameter result | Matched text, empty when nothing was found
  METHODS value
    RETURNING VALUE(result) TYPE string.

  "! Position of the match in the text, counted from zero.
  "! @parameter result | Offset of the first matched character, -1 when nothing was found
  METHODS offset
    RETURNING VALUE(result) TYPE i.

  "! Number of characters covered by the whole match.
  "! @parameter result | Length of the match, 0 when nothing was found
  METHODS length
    RETURNING VALUE(result) TYPE i.

  "! The text caught by one capture group.
  "! @parameter index  | Group number, 0 for the whole match
  "! @parameter result | Caught text; empty when the group did not take part in the match or does not exist
  METHODS group
    IMPORTING index         TYPE i
    RETURNING VALUE(result) TYPE string.

  "! The texts caught by all capture groups, in pattern order. Groups that did
  "! not take part in the match are present as empty lines, so the table has as
  "! many lines as the pattern has groups.
  "! @parameter result | One line per capture group, group 1 first
  METHODS groups
    RETURNING VALUE(result) TYPE string_table.

  "! Number of capture groups the pattern defines.
  "! @parameter result | Group count, 0 when the pattern has no groups or nothing was found
  METHODS group_count
    RETURNING VALUE(result) TYPE i.

ENDINTERFACE.
