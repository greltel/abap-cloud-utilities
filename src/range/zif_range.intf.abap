"! <p class="shorttext synchronized" lang="EN">Range of values</p>
"! Immutable set of selection conditions - the content of a RANGE OF table,
"! detached from the type of the field it is applied to. Instances are created
"! through {@link zcl_acu_range}.
"! <p>The conditions follow the rules of the ABAP operator IN. A range without
"! conditions covers every value. Otherwise a value is covered when it meets
"! at least one including condition - or there is none - and no excluding
"! condition: exclusions always win.</p>
"! <p>The values of the conditions are held as text and take a type only when
"! they are used: in the type of the value handed to
"! {@link zif_range.METH:covers}, or in the type of the table handed to
"! {@link zif_range.METH:write_to}.</p>
INTERFACE zif_range
  PUBLIC.

  "! Sign of a condition, one of the constants of {@link zif_range.DATA:sign}.
  TYPES ty_sign TYPE c LENGTH 1.
  "! Option of a condition, one of the constants of {@link zif_range.DATA:option}.
  TYPES ty_option TYPE c LENGTH 2.

  TYPES:
    "! One condition with its values as text, in the layout of a row of a
    "! RANGE OF table. high is filled for the two interval options only.
    BEGIN OF ty_condition,
      sign   TYPE ty_sign,
      option TYPE ty_option,
      low    TYPE string,
      high   TYPE string,
    END OF ty_condition.
  "! The conditions of a range. The table is itself a ranges table with string
  "! columns, the shape in which a RAP query hands over its filter.
  TYPES ty_conditions TYPE STANDARD TABLE OF ty_condition WITH EMPTY KEY.

  CONSTANTS:
    "! Whether a condition adds values to the range or takes them out of it.
    BEGIN OF sign,
      including TYPE ty_sign VALUE 'I',
      excluding TYPE ty_sign VALUE 'E',
    END OF sign.

  CONSTANTS:
    "! Comparison a condition applies to a value.
    BEGIN OF option,
      equal            TYPE ty_option VALUE 'EQ',
      not_equal        TYPE ty_option VALUE 'NE',
      greater_than     TYPE ty_option VALUE 'GT',
      greater_or_equal TYPE ty_option VALUE 'GE',
      less_than        TYPE ty_option VALUE 'LT',
      less_or_equal    TYPE ty_option VALUE 'LE',
      between          TYPE ty_option VALUE 'BT',
      not_between      TYPE ty_option VALUE 'NB',
      pattern          TYPE ty_option VALUE 'CP',
      not_pattern      TYPE ty_option VALUE 'NP',
    END OF option.

  "! Tests whether the range covers a value - the answer of value IN range,
  "! without a database access and without a typed copy of the range.
  "! <p>The conditions are compared in the kind of the value, never cut to
  "! its length or rounded to its decimals: character fields and strings as
  "! text, the blanks that pad a character field left aside; integers, packed
  "! numbers, floating point numbers and numeric text as numbers; dates,
  "! times, UTC time stamps and byte fields as what they are. Each kind of
  "! value is prepared once per range, so a call inside a loop stays cheap.</p>
  "! @parameter value     | Elementary value to test, for example a field of a table row
  "! @parameter result    | abap_true when the range has no conditions, or the value meets
  "!                        one of the including conditions and none of the excluding ones
  "! @raising   zcx_range | A condition cannot be compared with a value of this kind: a text
  "!                        with a number, a formatted date with a date field, a pattern with
  "!                        anything but text - or the value is of no type a ranges table can
  "!                        be defined for, such as a structure
  METHODS covers
    IMPORTING value         TYPE simple
    RETURNING VALUE(result) TYPE abap_bool
    RAISING   zcx_range.

  "! Tests whether the range has no conditions. Such a range covers every
  "! value and restricts nothing in a WHERE clause - guard with this method
  "! when a list of values that came out empty must select nothing instead
  "! of everything.
  "! @parameter result | abap_true when there is no condition
  METHODS is_empty
    RETURNING VALUE(result) TYPE abap_bool.

  "! The conditions with their values as text, in the order they were added.
  "! Values read the way a string template writes them without formatting
  "! options: numbers with a decimal point and a leading minus sign, dates as
  "! YYYYMMDD, times as hhmmss, character fields without the blanks at the end.
  "! @parameter result | One row per condition; empty for a range that covers everything
  METHODS conditions
    RETURNING VALUE(result) TYPE ty_conditions.

  "! Fills a RANGE OF table with the conditions, converted to the type of its
  "! low and high columns: for a WHERE ... IN clause, or to hand the range to
  "! an API. The previous content of the table is replaced; when the method
  "! raises, the table is left as it was.
  "! <p>Nothing is cut off or rounded on the way. Values are taken as they are
  "! stored on the database: a number for a numeric text column is padded with
  "! leading zeros, but no conversion exit runs for a character column.</p>
  "! @parameter range     | Reference to the table to fill, REF #( my_range ); any internal table
  "!                        whose rows have the components sign, option, low and high
  "! @raising   zcx_range | The reference does not point to such a table, or a condition does
  "!                        not fit its columns: a text longer than the column, a text for a
  "!                        numeric column, a number that would be rounded or is too large, a
  "!                        pattern for a column that is neither a character field nor a string
  METHODS write_to
    IMPORTING range TYPE REF TO data
    RAISING   zcx_range.

ENDINTERFACE.
