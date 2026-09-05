"! <p class="shorttext synchronized" lang="EN">UUID utility demo</p>
"! Runnable showcase for {@link zcl_uuid}. Start it with F9 in ADT.
CLASS zcl_uuid_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS external_id TYPE string VALUE `baf0a1e7-5fb0-1edf-b5e8-89f53894ca3a`.

    METHODS show_generation
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_parsing
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_uuid.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS as_yes_no
      IMPORTING flag          TYPE abap_bool
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_uuid_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_generation( out ).
        show_parsing( out ).
        show_rejected_input( out ).
      CATCH zcx_uuid INTO DATA(error).
        out->write( |UUID demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_generation.
    DATA(fresh) = zcl_uuid=>new( ).

    out->write( `--- Generation ---` ).
    out->write( |X16        : { fresh->as_x16( ) }| ).
    out->write( |C22        : { fresh->as_c22( ) }| ).
    out->write( |C32        : { fresh->as_c32( ) }| ).
    out->write( |C36        : { fresh->as_c36( ) }| ).
    out->write( |Is nil     : { as_yes_no( fresh->is_nil( ) ) }| ).
  ENDMETHOD.

  METHOD show_parsing.
    DATA(parsed) = zcl_uuid=>for_text( external_id ).
    DATA(compact) = CONV string( parsed->as_c22( ) ).

    out->write( `--- Parsing ---` ).
    out->write( |Input      : { external_id }| ).
    out->write( |X16        : { parsed->as_x16( ) }| ).
    out->write( |C22        : { compact }| ).
    out->write( |Round trip : { as_yes_no( zcl_uuid=>for_text( compact )->equals( parsed ) ) }| ).
  ENDMETHOD.

  METHOD show_rejected_input.
    out->write( `--- Rejected input ---` ).

    TRY.
        zcl_uuid=>for_text( `not-a-uuid` ).

        out->write( `A malformed identifier was unexpectedly accepted` ).
      CATCH zcx_uuid INTO DATA(rejection).
        out->write( |Rejected as expected: { rejection->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD as_yes_no.
    result = COND string( WHEN flag = abap_true THEN `yes`
                          ELSE `no` ).
  ENDMETHOD.

ENDCLASS.

