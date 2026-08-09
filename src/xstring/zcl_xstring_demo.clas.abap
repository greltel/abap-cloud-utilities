"! <p class="shorttext synchronized" lang="EN">XString utility demo</p>
"! Runnable showcase for {@link zcl_xstring}. Start it with F9 in ADT.
CLASS zcl_xstring_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS pdf_signature TYPE string VALUE `255044462D`.
    CONSTANTS pdf_version TYPE string VALUE `312E37`.

    METHODS show_conversions
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_xstring.

    METHODS show_parsing
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_xstring.

    METHODS show_assembling
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_xstring.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

ENDCLASS.


CLASS zcl_xstring_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_conversions( out ).
        show_parsing( out ).
        show_assembling( out ).
        show_rejected_input( out ).
      CATCH zcx_xstring INTO DATA(error).
        out->write( |XString demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_conversions.
    DATA(payload) = zcl_xstring=>for_text( `Clean Core` ).

    out->write( `--- Conversions ---` ).
    out->write( |Bytes      : { payload->length( ) }| ).
    out->write( |Hex        : { payload->as_hex( ) }| ).
    out->write( |Base64     : { payload->as_base64( ) }| ).
    out->write( |Round trip : { zcl_xstring=>for_base64( payload->as_base64( ) )->as_text( ) }| ).
  ENDMETHOD.

  METHOD show_parsing.
    DATA(signature) = zcl_xstring=>for_hex( pdf_signature )->as_xstring( ).
    DATA(document) = zcl_xstring=>for_hex( |{ pdf_signature }{ pdf_version }| ).

    out->write( `--- Parsing ---` ).
    out->write( |Content    : { document->as_text( ) }| ).
    out->write( |Is a PDF   : { document->starts_with( signature ) }| ).
    out->write( |Header ends: { document->offset_of( signature ) + xstrlen( signature ) }| ).
    out->write( |Version    : { document->section( offset = 5
                                                   length = 3 )->as_text( ) }| ).
  ENDMETHOD.

  METHOD show_assembling.
    DATA(message) = zcl_xstring=>builder(
      )->append_text( `id=`
      )->append_hex( `3432`
      )->append_base64( `Lw==`
      )->build( ).

    out->write( `--- Assembling ---` ).
    out->write( |Assembled  : { message->as_text( ) }| ).
    out->write( |Hex        : { message->as_hex( ) }| ).
  ENDMETHOD.

  METHOD show_rejected_input.
    out->write( `--- Rejected input ---` ).

    TRY.
        zcl_xstring=>for_hex( `4A4` ).

        out->write( `An odd hexadecimal string was unexpectedly accepted` ).
      CATCH zcx_xstring INTO DATA(rejection).
        out->write( |Rejected as expected: { rejection->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
