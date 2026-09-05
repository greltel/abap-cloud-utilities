*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
"! Renders raw bytes in the character formats through XCO. The value object and
"! the parser share it, so a format is produced by exactly one piece of code.
CLASS lcl_formatter DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS c22
      IMPORTING uuid          TYPE sysuuid_x16
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS c32
      IMPORTING uuid          TYPE sysuuid_x16
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS c36
      IMPORTING uuid          TYPE sysuuid_x16
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


"! Turns a character representation back into raw bytes. The kernel does the
"! decoding; the result is then rendered again and must reproduce the input,
"! which rejects malformed text no matter how leniently the kernel decoded it.
CLASS lcl_parser DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS parse
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE sysuuid_x16
      RAISING   zcx_uuid.

  PRIVATE SECTION.
    CONSTANTS c22_length TYPE i VALUE 22.
    CONSTANTS c32_length TYPE i VALUE 32.
    CONSTANTS c36_length TYPE i VALUE 36.

    CLASS-METHODS from_c22
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE sysuuid_x16
      RAISING   zcx_uuid.

    CLASS-METHODS from_c32
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE sysuuid_x16
      RAISING   zcx_uuid.

    CLASS-METHODS from_c36
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE sysuuid_x16
      RAISING   zcx_uuid.

    CLASS-METHODS ensure_reproduced
      IMPORTING text     TYPE string
                rendered TYPE string
      RAISING   zcx_uuid.

ENDCLASS.


"! Immutable identifier value.
CLASS lcl_uuid DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_uuid.

    METHODS constructor
      IMPORTING uuid TYPE sysuuid_x16.

  PRIVATE SECTION.
    DATA uuid TYPE sysuuid_x16.

ENDCLASS.


"! Hands out system UUIDs.
CLASS lcl_generator DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_uuid_generator.

ENDCLASS.


CLASS lcl_formatter IMPLEMENTATION.

  METHOD c22.
    result = xco_cp=>uuid( uuid )->as( xco_cp_uuid=>format->c22 )->value.
  ENDMETHOD.

  METHOD c32.
    result = xco_cp=>uuid( uuid )->as( xco_cp_uuid=>format->c32 )->value.
  ENDMETHOD.

  METHOD c36.
    result = xco_cp=>uuid( uuid )->as( xco_cp_uuid=>format->c36 )->value.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_parser IMPLEMENTATION.

  METHOD parse.
    DATA(candidate) = condense( text ).

    CASE strlen( candidate ).
      WHEN c22_length.
        result = from_c22( candidate ).
      WHEN c32_length.
        result = from_c32( to_upper( candidate ) ).
      WHEN c36_length.
        result = from_c36( to_upper( candidate ) ).
      WHEN OTHERS.
        RAISE EXCEPTION NEW zcx_uuid( |{ candidate } has neither 22, 32 nor 36 characters| ).
    ENDCASE.
  ENDMETHOD.

  METHOD from_c22.
    TRY.
        cl_system_uuid=>convert_uuid_c22_static( EXPORTING uuid     = CONV sysuuid_c22( text )
                                                 IMPORTING uuid_x16 = result ).
      CATCH cx_uuid_error INTO DATA(failure).
        RAISE EXCEPTION NEW zcx_uuid( text     = |{ text } is not a valid 22 character UUID|
                                      previous = failure ).
    ENDTRY.

    ensure_reproduced( text     = text
                       rendered = lcl_formatter=>c22( result ) ).
  ENDMETHOD.

  METHOD from_c32.
    TRY.
        cl_system_uuid=>convert_uuid_c32_static( EXPORTING uuid     = CONV sysuuid_c32( text )
                                                 IMPORTING uuid_x16 = result ).
      CATCH cx_uuid_error INTO DATA(failure).
        RAISE EXCEPTION NEW zcx_uuid( text     = |{ text } is not a valid 32 character UUID|
                                      previous = failure ).
    ENDTRY.

    ensure_reproduced( text     = text
                       rendered = lcl_formatter=>c32( result ) ).
  ENDMETHOD.

  METHOD from_c36.
    TRY.
        cl_system_uuid=>convert_uuid_c36_static( EXPORTING uuid     = CONV sysuuid_c36( text )
                                                 IMPORTING uuid_x16 = result ).
      CATCH cx_uuid_error INTO DATA(failure).
        RAISE EXCEPTION NEW zcx_uuid( text     = |{ text } is not a valid 36 character UUID|
                                      previous = failure ).
    ENDTRY.

    ensure_reproduced( text     = text
                       rendered = lcl_formatter=>c36( result ) ).
  ENDMETHOD.

  METHOD ensure_reproduced.
    IF rendered <> text.
      RAISE EXCEPTION NEW zcx_uuid( |{ text } is not a valid UUID representation| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_uuid IMPLEMENTATION.

  METHOD constructor.
    me->uuid = uuid.
  ENDMETHOD.

  METHOD zif_uuid~as_x16.
    result = uuid.
  ENDMETHOD.

  METHOD zif_uuid~as_c22.
    result = lcl_formatter=>c22( uuid ).
  ENDMETHOD.

  METHOD zif_uuid~as_c32.
    result = lcl_formatter=>c32( uuid ).
  ENDMETHOD.

  METHOD zif_uuid~as_c36.
    result = lcl_formatter=>c36( uuid ).
  ENDMETHOD.

  METHOD zif_uuid~is_nil.
    result = xsdbool( uuid IS INITIAL ).
  ENDMETHOD.

  METHOD zif_uuid~equals.
    IF other IS BOUND.
      result = xsdbool( uuid = other->as_x16( ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_generator IMPLEMENTATION.

  METHOD zif_uuid_generator~next.
    result = NEW lcl_uuid( xco_cp=>uuid( )->value ).
  ENDMETHOD.

ENDCLASS.
