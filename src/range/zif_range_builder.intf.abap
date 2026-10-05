"! <p class="shorttext synchronized" lang="EN">Range builder</p>
"! Collects the conditions of a range, one call per condition, and is closed
"! with {@link zif_range_builder.METH:build}. Obtained from
"! {@link zcl_acu_range.METH:builder}.
"! <p>Conditions are either including - the value may be one of these - or
"! excluding, the methods starting with not_: the value must be none of
"! these. Including conditions are alternatives of each other, and an
"! excluding condition overrules all of them. A range with excluding
"! conditions only covers everything else.</p>
"! <p>Values are taken in the form they have in a table field, not in the form
"! a user types them; every elementary type is accepted. A condition added
"! twice is kept once. The chain itself never raises - a call that cannot be
"! turned into conditions is remembered and reported by build( ).</p>
INTERFACE zif_range_builder
  PUBLIC.

  "! Includes one value.
  "! @parameter value | Value the range shall cover
  "! @parameter self  | Same instance, for chaining
  METHODS equal
    IMPORTING value       TYPE simple
    RETURNING VALUE(self) TYPE REF TO zif_range_builder.

  "! Excludes one value.
  "! @parameter value | Value the range shall not cover, whatever the including conditions say
  "! @parameter self  | Same instance, for chaining
  METHODS not_equal
    IMPORTING value       TYPE simple
    RETURNING VALUE(self) TYPE REF TO zif_range_builder.

  "! Includes an interval, both borders included. An interval whose lower
  "! border lies above the upper one covers nothing, as in ABAP.
  "! @parameter low  | Lower border
  "! @parameter high | Upper border
  "! @parameter self | Same instance, for chaining
  METHODS between
    IMPORTING low         TYPE simple
              high        TYPE simple
    RETURNING VALUE(self) TYPE REF TO zif_range_builder.

  "! Excludes an interval, both borders included.
  "! @parameter low  | Lower border
  "! @parameter high | Upper border
  "! @parameter self | Same instance, for chaining
  METHODS not_between
    IMPORTING low         TYPE simple
              high        TYPE simple
    RETURNING VALUE(self) TYPE REF TO zif_range_builder.

  "! Includes every text that matches a pattern in the notation of the ABAP
  "! operator CP: * stands for any text, also none, + for exactly one
  "! character, and # takes the special meaning from the character after it.
  "! <p>{@link zif_range.METH:covers} matches as CP does, ignoring upper and
  "! lower case. In a WHERE clause the database matches the same pattern case
  "! sensitively.</p>
  "! @parameter mask | Pattern, for example 4* or A+C
  "! @parameter self | Same instance, for chaining
  METHODS pattern
    IMPORTING mask        TYPE csequence
    RETURNING VALUE(self) TYPE REF TO zif_range_builder.

  "! Excludes every text that matches a pattern.
  "! @parameter mask | Pattern as in {@link zif_range_builder.METH:pattern}
  "! @parameter self | Same instance, for chaining
  METHODS not_pattern
    IMPORTING mask        TYPE csequence
    RETURNING VALUE(self) TYPE REF TO zif_range_builder.

  "! Includes everything above a value.
  "! @parameter value | Border, itself not included
  "! @parameter self  | Same instance, for chaining
  METHODS greater_than
    IMPORTING value       TYPE simple
    RETURNING VALUE(self) TYPE REF TO zif_range_builder.

  "! Includes a value and everything above it.
  "! @parameter value | Border, itself included
  "! @parameter self  | Same instance, for chaining
  METHODS greater_or_equal
    IMPORTING value       TYPE simple
    RETURNING VALUE(self) TYPE REF TO zif_range_builder.

  "! Includes everything below a value.
  "! @parameter value | Border, itself not included
  "! @parameter self  | Same instance, for chaining
  METHODS less_than
    IMPORTING value       TYPE simple
    RETURNING VALUE(self) TYPE REF TO zif_range_builder.

  "! Includes a value and everything below it.
  "! @parameter value | Border, itself included
  "! @parameter self  | Same instance, for chaining
  METHODS less_or_equal
    IMPORTING value       TYPE simple
    RETURNING VALUE(self) TYPE REF TO zif_range_builder.

  "! Includes every value of a list - one including condition per value.
  "! <p>An empty list adds nothing. A range that is left without any
  "! condition covers every value; see {@link zif_range.METH:is_empty}.</p>
  "! @parameter values | Internal table of elementary values, of any table kind
  "! @parameter self   | Same instance, for chaining
  METHODS from_list
    IMPORTING values      TYPE ANY TABLE
    RETURNING VALUE(self) TYPE REF TO zif_range_builder.

  "! Excludes every value of a list - one excluding condition per value.
  "! @parameter values | Internal table of elementary values, of any table kind
  "! @parameter self   | Same instance, for chaining
  METHODS not_in
    IMPORTING values      TYPE ANY TABLE
    RETURNING VALUE(self) TYPE REF TO zif_range_builder.

  "! Takes over the rows of an existing ranges table as they are - a
  "! RANGE OF table handed down by a caller, or the filter ranges of a RAP
  "! query - so that conditions can be added to them. This is also the way to
  "! the options the other methods do not produce: not equal, not between and
  "! not pattern as including conditions.
  "! @parameter range | Table whose rows have the components sign, option, low and high,
  "!                    with sign I or E and one of the ten options of {@link zif_range.DATA:option}
  "! @parameter self  | Same instance, for chaining
  METHODS from_range
    IMPORTING range       TYPE ANY TABLE
    RETURNING VALUE(self) TYPE REF TO zif_range_builder.

  "! Finishes the range.
  "! @parameter result    | The range, immutable; without conditions it covers every value
  "! @raising   zcx_range | A call in the chain could not be turned into conditions: a list
  "!                        whose rows are not elementary values, or a table that is not a
  "!                        ranges table or holds an unknown sign or option
  METHODS build
    RETURNING VALUE(result) TYPE REF TO zif_range
    RAISING   zcx_range.

ENDINTERFACE.
