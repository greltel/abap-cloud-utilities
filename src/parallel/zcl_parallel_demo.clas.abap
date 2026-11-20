"! <p class="shorttext synchronized" lang="EN">Parallel processing utility demo</p>
"! Runnable showcase for {@link zcl_parallel}. Start it with F9 in ADT.
CLASS zcl_parallel_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF bill,
        rent        TYPE i VALUE 1200,
        electricity TYPE i VALUE 90,
        water       TYPE i VALUE 45,
      END OF bill.
    CONSTANTS flatmates TYPE i VALUE 3.
    CONSTANTS nobody TYPE i VALUE 0.
    CONSTANTS process_limit TYPE i VALUE 2.
    CONSTANTS timeout_seconds TYPE i VALUE 60.
    CONSTANTS no_process TYPE i VALUE 0.

    METHODS show_parallel_run
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_parallel.

    METHODS show_sequential_run
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_parallel.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS bills_to_split
      RETURNING VALUE(result) TYPE zif_parallel_task=>tasks.

    METHODS write_outcomes
      IMPORTING run TYPE REF TO zif_parallel_run
                out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_parallel.

ENDCLASS.


CLASS zcl_parallel_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_parallel_run( out ).
        show_sequential_run( out ).
        show_rejected_input( out ).
      CATCH zcx_parallel INTO DATA(error).
        out->write( |Parallel demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_parallel_run.
    DATA(runner) = zcl_parallel=>configure( )->with_max_processes( process_limit
                                            )->with_timeout( timeout_seconds
                                            )->build( ).

    out->write( `--- Parallel sessions ---` ).
    write_outcomes( run = runner->run( bills_to_split( ) )
                    out = out ).
  ENDMETHOD.

  METHOD show_sequential_run.
    DATA(runner) = zcl_parallel=>sequential( ).

    out->write( `--- Same tasks, one after the other in this session ---` ).
    write_outcomes( run = runner->run( bills_to_split( ) )
                    out = out ).
  ENDMETHOD.

  METHOD show_rejected_input.
    out->write( `--- Rejected input ---` ).

    TRY.
        zcl_parallel=>configure( )->with_max_processes( no_process )->build( ).

        out->write( `A limit of zero work processes was unexpectedly accepted` ).
      CATCH zcx_parallel INTO DATA(rejection).
        out->write( |Rejected as expected: { rejection->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD bills_to_split.
    result = VALUE #( ( NEW lcl_split_task( amount = bill-rent
                                            people = flatmates ) )
                      ( NEW lcl_split_task( amount = bill-electricity
                                            people = flatmates ) )
                      ( NEW lcl_split_task( amount = bill-water
                                            people = nobody ) ) ).
  ENDMETHOD.

  METHOD write_outcomes.
    LOOP AT run->outcomes( ) INTO DATA(outcome).
      IF outcome->has_failed( ).
        out->write( |Task { outcome->position( ) } failed: { outcome->failure_reason( ) }| ).
      ELSE.
        DATA(split) = CAST lcl_split_task( outcome->executed_task( ) ).
        out->write( |Task { outcome->position( ) }: { split->share( ) } per head| ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
