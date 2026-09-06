"! <p class="shorttext synchronized" lang="EN">Number range utility demo</p>
"! Runnable showcase for {@link zcl_number_range}. Start it with F9 in ADT.
"! Needs a number range object with an internal interval; point the two
"! constants to one that exists in your system. Every run consumes numbers.
CLASS zcl_number_range_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    "! The shape a consuming application usually stores the number in.
    TYPES document_number TYPE n LENGTH 10.

    CONSTANTS demo_object TYPE string VALUE `ZDEMO_NR`.
    CONSTANTS demo_interval TYPE string VALUE `01`.
    CONSTANTS block_size TYPE i VALUE 5.
    CONSTANTS list_size TYPE i VALUE 3.

    METHODS show_level
      IMPORTING out   TYPE REF TO if_oo_adt_classrun_out
                range TYPE REF TO zif_number_range
      RAISING   zcx_number_range.

    METHODS show_single
      IMPORTING out   TYPE REF TO if_oo_adt_classrun_out
                range TYPE REF TO zif_number_range
      RAISING   zcx_number_range.

    METHODS show_block
      IMPORTING out   TYPE REF TO if_oo_adt_classrun_out
                range TYPE REF TO zif_number_range
      RAISING   zcx_number_range.

    METHODS show_numbers
      IMPORTING out   TYPE REF TO if_oo_adt_classrun_out
                range TYPE REF TO zif_number_range
      RAISING   zcx_number_range.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS as_yes_no
      IMPORTING flag          TYPE abap_bool
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_number_range_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(range) = zcl_number_range=>for_interval( object   = demo_object
                                                      interval = demo_interval ).

        show_level( out   = out
                    range = range ).
        show_single( out   = out
                     range = range ).
        show_block( out   = out
                    range = range ).
        show_numbers( out   = out
                      range = range ).
        show_rejected_input( out ).
      CATCH zcx_number_range INTO DATA(error).
        out->write( |Number range demo failed: { error->get_text( ) }| ).
        out->write( |Create number range object { demo_object } with an internal interval { demo_interval }, | &&
                    |or point the constants of this class to an existing one| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_level.
    out->write( `--- Level before ---` ).
    out->write( |Last assigned : { range->last_assigned( ) ALPHA = OUT }| ).
  ENDMETHOD.

  METHOD show_single.
    DATA(number) = range->next( ).
    DATA(stored) = CONV document_number( number ).

    out->write( `--- Single number ---` ).
    out->write( |Raw           : { number }| ).
    out->write( |As NUMC 10    : { stored }| ).
    out->write( |For display   : { number ALPHA = OUT }| ).
  ENDMETHOD.

  METHOD show_block.
    DATA(block) = range->next_block( block_size ).

    out->write( |--- Block of { block_size } ---| ).
    out->write( |First         : { block-first ALPHA = OUT }| ).
    out->write( |Last          : { block-last ALPHA = OUT }| ).
    out->write( |Quantity      : { block-quantity }| ).
    out->write( |Critical area : { as_yes_no( block-is_critical ) }| ).
    out->write( |Exhausted     : { as_yes_no( block-is_exhausted ) }| ).
  ENDMETHOD.

  METHOD show_numbers.
    DATA(numbers) = range->next_numbers( list_size ).

    out->write( |--- Table of { list_size } ---| ).

    LOOP AT numbers INTO DATA(number).
      out->write( |  { number ALPHA = OUT }| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD show_rejected_input.
    out->write( `--- Rejected input ---` ).

    TRY.
        zcl_number_range=>for_interval( object   = `THIS_NAME_IS_TOO_LONG`
                                        interval = demo_interval ).

        out->write( `An object name of 21 characters was unexpectedly accepted` ).
      CATCH zcx_number_range INTO DATA(rejection).
        out->write( |Rejected as expected: { rejection->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD as_yes_no.
    result = COND string( WHEN flag = abap_true THEN `yes`
                          ELSE `no` ).
  ENDMETHOD.

ENDCLASS.

