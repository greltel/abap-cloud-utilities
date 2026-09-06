"! <p class="shorttext synchronized" lang="EN">Number range utility</p>
"! Entry point for drawing numbers from a customer number range object on top
"! of the released CL_NUMBERRANGE_RUNTIME API. Standalone - depends on
"! nothing but SAP released APIs.
CLASS zcl_number_range DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Addresses an interval of a number range object. Nothing is read yet;
    "! the interval is looked up with the first request. Object and interval
    "! number are case insensitive, surrounding blanks are ignored.
    "! @parameter object           | Number range object, up to 10 characters
    "! @parameter interval         | Interval number as maintained, for example 01
    "! @parameter result           | Interval that hands out numbers
    "! @raising   zcx_number_range | Object or interval number is empty or too long
    CLASS-METHODS for_interval
      IMPORTING object        TYPE string
                interval      TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_number_range
      RAISING   zcx_number_range.

ENDCLASS.


CLASS zcl_number_range IMPLEMENTATION.

  METHOD for_interval.
    DATA(target) = VALUE settings( object   = lcl_identifier=>object( object )
                                   interval = lcl_identifier=>interval( interval ) ).

    result = NEW lcl_number_range( settings = target
                                   runtime  = NEW lcl_runtime( ) ).
  ENDMETHOD.

ENDCLASS.

