"! ZCL_LOCK_DEMO
"! <p class="shorttext synchronized" lang="EN">Lock utility demo</p>
"! Runnable showcase for {@link zcl_lock}. Start it with F9 in ADT.
"! Needs a lock object; point the constants to one that exists in your system
"! and to one of its lock parameters.
CLASS zcl_lock_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS demo_object TYPE string VALUE `EZ_DEMO_ORDER`.
    CONSTANTS demo_parameter TYPE string VALUE `ORDER_ID`.
    CONSTANTS demo_value TYPE string VALUE `4711`.
    CONSTANTS demo_table TYPE string VALUE `ZDEMO_ORDER`.
    CONSTANTS unknown_mode TYPE if_abap_lock_object=>tv_mode VALUE 'Q'.

    METHODS show_lifecycle
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_configuration
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_failure
      IMPORTING out   TYPE REF TO if_oo_adt_classrun_out
                error TYPE REF TO zcx_lock.

    METHODS as_yes_no
      IMPORTING flag          TYPE abap_bool
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_lock_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    show_lifecycle( out ).
    show_configuration( out ).
    show_rejected_input( out ).

    zcl_lock=>release_all( ).
    out->write( `All locks of the session released` ).
  ENDMETHOD.

  METHOD show_lifecycle.
    out->write( `--- Acquire and release ---` ).

    TRY.
        DATA(lock) = zcl_lock=>for_object( demo_object
                              )->with( name  = demo_parameter
                                       value = demo_value
                              )->acquire( ).

        out->write( |Acquired   : { lock->describe( ) }| ).
        out->write( |Held       : { as_yes_no( lock->is_held( ) ) }| ).

        lock->release( ).

        out->write( |Released   : { as_yes_no( xsdbool( lock->is_held( ) = abap_false ) ) }| ).
      CATCH zcx_lock INTO DATA(error).
        show_failure( out   = out
                      error = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_configuration.
    out->write( `--- Dialog owner, shared mode, waiting ---` ).

    TRY.
        DATA(lock) = zcl_lock=>for_object( demo_object
                              )->with( name  = demo_parameter
                                       value = demo_value
                              )->with_mode( table = demo_table
                                            mode  = zcl_lock=>mode-shared
                              )->in_scope( zcl_lock=>scope-dialog
                              )->waiting(
                              )->acquire( ).

        out->write( |Acquired   : { lock->describe( ) }| ).

        lock->release( ).
        lock->release( ).

        out->write( |Released twice, harmless: { as_yes_no( xsdbool( lock->is_held( ) = abap_false ) ) }| ).
      CATCH zcx_lock INTO DATA(error).
        show_failure( out   = out
                      error = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_rejected_input.
    out->write( `--- Rejected input ---` ).

    TRY.
        zcl_lock=>for_object( demo_object )->with( name  = ``
                                                   value = demo_value ).

        out->write( `An empty parameter name was unexpectedly accepted` ).
      CATCH zcx_lock INTO DATA(empty_name).
        out->write( |Rejected as expected: { empty_name->get_text( ) }| ).
    ENDTRY.

    TRY.
        zcl_lock=>for_object( demo_object )->with_mode( table = demo_table
                                                        mode  = unknown_mode ).

        out->write( `An unknown lock mode was unexpectedly accepted` ).
      CATCH zcx_lock INTO DATA(bad_mode).
        out->write( |Rejected as expected: { bad_mode->get_text( ) }| ).
    ENDTRY.

    TRY.
        zcl_lock=>for_object( demo_object )->with( name  = demo_parameter
                                                   value = demo_value
                                          )->with( name  = demo_parameter
                                                   value = demo_value ).

        out->write( `A parameter set twice was unexpectedly accepted` ).
      CATCH zcx_lock INTO DATA(duplicate).
        out->write( |Rejected as expected: { duplicate->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_failure.
    IF error->is_foreign_lock( ) = abap_true.
      out->write( |Held by another user: { error->locked_by( ) }| ).
    ELSE.
      out->write( |Lock demo failed: { error->get_text( ) }| ).
    ENDIF.
  ENDMETHOD.

  METHOD as_yes_no.
    result = COND string( WHEN flag = abap_true THEN `yes`
                          ELSE `no` ).
  ENDMETHOD.

ENDCLASS.
