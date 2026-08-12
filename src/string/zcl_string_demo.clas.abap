"! <p class="shorttext synchronized" lang="EN">String parsing utility demo</p>
"! Runnable walk through ZCL_STRING. Press F9 in ADT to see the output.
CLASS zcl_string_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    METHODS show_split_by
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_string.

    METHODS show_split_tokens
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_string.

    METHODS show_split_lines
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_split_fixed
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_string.

    METHODS show_split_pairs
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_string.

    METHODS show_extract
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_trim
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_guards
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_segments
      IMPORTING out      TYPE REF TO if_oo_adt_classrun_out
                title    TYPE string
                segments TYPE zif_string=>segments.

    METHODS show_pairs
      IMPORTING out   TYPE REF TO if_oo_adt_classrun_out
                title TYPE string
                pairs TYPE zif_string=>pairs.

ENDCLASS.


CLASS zcl_string_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_split_by( out ).
        show_split_tokens( out ).
        show_split_lines( out ).
        show_split_fixed( out ).
        show_split_pairs( out ).
        show_extract( out ).
        show_trim( out ).
        show_guards( out ).
      CATCH zcx_string INTO DATA(error).
        out->write( |Unexpected failure: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_split_by.
    DATA(csv) = `4711,BOX,,12,`.

    out->write( `=== split_by - positional CSV, every empty field kept ===` ).
    out->write( |Input: [{ csv }]| ).

    show_segments( out      = out
                   title    = `Fields`
                   segments = zcl_string=>for_text( csv )->split_by( `,` ) ).
  ENDMETHOD.

  METHOD show_split_tokens.
    DATA(list) = ` DE , , FR ,IT `.

    out->write( `=== split_tokens - trimmed, empty parts dropped ===` ).
    out->write( |Input: [{ list }]| ).

    show_segments( out      = out
                   title    = `Countries`
                   segments = zcl_string=>for_text( list )->split_tokens( `,` ) ).
  ENDMETHOD.

  METHOD show_split_lines.
    DATA(document) = |First line\r\nSecond line\n\nFourth line\n|.

    out->write( `=== split_lines - CRLF, LF and CR, closing break is a terminator ===` ).

    show_segments( out      = out
                   title    = `Lines`
                   segments = zcl_string=>for_text( document )->split_lines( ) ).
  ENDMETHOD.

  METHOD show_split_fixed.
    DATA(note) = `Delivery blocked until the credit check has been released`.

    out->write( `=== split_fixed - wrapping a note into chunks of 20 ===` ).
    out->write( |Input: [{ note }]| ).

    show_segments( out      = out
                   title    = `Chunks`
                   segments = zcl_string=>for_text( note )->split_fixed( 20 ) ).
  ENDMETHOD.

  METHOD show_split_pairs.
    DATA(settings) = ` COLOR = RED ; SIZE = L ; GIFT_WRAP `.

    out->write( `=== split_pairs - reading a settings string ===` ).
    out->write( |Input: [{ settings }]| ).

    DATA(entries) = zcl_string=>for_text( settings )->split_pairs( pair_delimiter  = `;`
                                                                   value_delimiter = `=` ).

    show_pairs( out   = out
                title = `Settings`
                pairs = entries ).
  ENDMETHOD.

  METHOD show_extract.
    DATA(payload) = `<item>A100</item><item>B200</item>`.

    out->write( `=== extract_between and extract_all_between ===` ).
    out->write( |Input: [{ payload }]| ).

    DATA(first) = zcl_string=>for_text( payload )->extract_between( after  = `<item>`
                                                                    before = `</item>` ).
    out->write( |First item: [{ first->as_text( ) }]| ).

    DATA(items) = zcl_string=>for_text( payload )->extract_all_between( after  = `<item>`
                                                                        before = `</item>` ).

    show_segments( out      = out
                   title    = `All items`
                   segments = items ).
  ENDMETHOD.

  METHOD show_trim.
    DATA(raw) = `***0004711***`.

    out->write( `=== trim - character set, chained on the view ===` ).
    out->write( |Input:   [{ raw }]| ).
    out->write( |Trimmed: [{ zcl_string=>for_text( raw )->trim( `*` )->as_text( ) }]| ).
    out->write( `` ).
  ENDMETHOD.

  METHOD show_guards.
    out->write( `=== guards - invalid arguments raise ZCX_STRING ===` ).

    TRY.
        zcl_string=>for_text( `a,b` )->split_by( `` ).
      CATCH zcx_string INTO DATA(delimiter_error).
        out->write( |Caught: { delimiter_error->get_text( ) }| ).
    ENDTRY.

    TRY.
        zcl_string=>for_text( `abc` )->split_fixed( 0 ).
      CATCH zcx_string INTO DATA(size_error).
        out->write( |Caught: { size_error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_segments.
    out->write( |{ title } ({ lines( segments ) }):| ).

    LOOP AT segments INTO DATA(segment).
      out->write( |  { sy-tabix }: [{ segment }]| ).
    ENDLOOP.

    out->write( `` ).
  ENDMETHOD.

  METHOD show_pairs.
    out->write( |{ title } ({ lines( pairs ) }):| ).

    LOOP AT pairs INTO DATA(entry).
      out->write( |  { entry-name } = [{ entry-value }]| ).
    ENDLOOP.

    out->write( `` ).
  ENDMETHOD.

ENDCLASS.
