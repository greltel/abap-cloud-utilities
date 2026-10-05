"! <p class="shorttext synchronized" lang="EN">Range utility</p>
"! Entry point for ranges of values: builds the content of a RANGE OF table
"! with a fluent builder, from a list of values or from an existing ranges
"! table, and evaluates a value against it without a database access.
"! Standalone - depends on nothing but SAP released APIs.
CLASS zcl_acu_range DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Starts a new range without conditions.
    "! @parameter result | Builder that collects the conditions and is closed with build( )
    CLASS-METHODS builder
      RETURNING VALUE(result) TYPE REF TO zif_range_builder.

    "! Creates the range that covers exactly the values of a list - one
    "! including condition per value, a value listed twice counted once. Short
    "! for builder( )->from_list( values )->build( ).
    "! <p>An empty list gives a range without conditions, which covers every
    "! value; see {@link zif_range.METH:is_empty}.</p>
    "! @parameter values    | Internal table of elementary values, of any table kind
    "! @parameter result    | The range, immutable
    "! @raising   zcx_range | The rows of the table are not elementary values
    CLASS-METHODS from_list
      IMPORTING values        TYPE ANY TABLE
      RETURNING VALUE(result) TYPE REF TO zif_range
      RAISING   zcx_range.

    "! Opens an existing ranges table - a RANGE OF table handed down by a
    "! caller, or the filter ranges of a RAP query - to evaluate values
    "! against it or to write it to a ranges table of another type. Short for
    "! builder( )->from_range( range )->build( ).
    "! @parameter range     | Table whose rows have the components sign, option, low and high
    "! @parameter result    | The range, immutable
    "! @raising   zcx_range | The table is not a ranges table, or a row holds a sign other
    "!                        than I and E or an unknown option
    CLASS-METHODS from_range
      IMPORTING range         TYPE ANY TABLE
      RETURNING VALUE(result) TYPE REF TO zif_range
      RAISING   zcx_range.

ENDCLASS.


CLASS zcl_acu_range IMPLEMENTATION.

  METHOD builder.
    result = NEW lcl_builder( ).
  ENDMETHOD.

  METHOD from_list.
    result = builder( )->from_list( values )->build( ).
  ENDMETHOD.

  METHOD from_range.
    result = builder( )->from_range( range )->build( ).
  ENDMETHOD.

ENDCLASS.
