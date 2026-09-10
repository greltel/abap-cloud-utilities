"! ZCL_LOCK - Test Classes
*"* use this source file for your ABAP unit test classes
"! Stands in for the lock server. Records every request it receives and fails
"! on demand with the exception a test hands it.
CLASS ltd_engine DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    INTERFACES lif_engine.

    TYPES:
      BEGIN OF recording,
        enqueued          TYPE request,
        dequeued          TYPE request,
        enqueue_calls     TYPE i,
        dequeue_calls     TYPE i,
        dequeue_all_calls TYPE i,
      END OF recording.

    METHODS refusing_with
      IMPORTING failure     TYPE REF TO cx_static_check
      RETURNING VALUE(self) TYPE REF TO ltd_engine.

    METHODS releasing_fails_with
      IMPORTING failure     TYPE REF TO cx_abap_lock_failure
      RETURNING VALUE(self) TYPE REF TO ltd_engine.

    METHODS recorded
      RETURNING VALUE(result) TYPE recording.

  PRIVATE SECTION.
    DATA enqueue_failure TYPE REF TO cx_static_check.
    DATA dequeue_failure TYPE REF TO cx_abap_lock_failure.
    DATA log TYPE recording.

ENDCLASS.


CLASS ltd_engine IMPLEMENTATION.

  METHOD refusing_with.
    enqueue_failure = failure.

    self = me.
  ENDMETHOD.

  METHOD releasing_fails_with.
    dequeue_failure = failure.

    self = me.
  ENDMETHOD.

  METHOD recorded.
    result = log.
  ENDMETHOD.

  METHOD lif_engine~enqueue.
    log-enqueued = request.
    log-enqueue_calls = log-enqueue_calls + 1.

    IF enqueue_failure IS INSTANCE OF cx_abap_foreign_lock.
      RAISE EXCEPTION CAST cx_abap_foreign_lock( enqueue_failure ).
    ENDIF.

    IF enqueue_failure IS INSTANCE OF cx_abap_lock_failure.
      RAISE EXCEPTION CAST cx_abap_lock_failure( enqueue_failure ).
    ENDIF.
  ENDMETHOD.

  METHOD lif_engine~dequeue.
    log-dequeued = request.
    log-dequeue_calls = log-dequeue_calls + 1.

    IF dequeue_failure IS BOUND.
      RAISE EXCEPTION dequeue_failure.
    ENDIF.
  ENDMETHOD.

  METHOD lif_engine~dequeue_all.
    log-dequeue_all_calls = log-dequeue_all_calls + 1.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_identifiers DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS unknown_mode TYPE if_abap_lock_object=>tv_mode VALUE 'Q'.
    CONSTANTS unknown_scope TYPE if_abap_lock_object=>tv_scope VALUE '4'.

    METHODS given_plain_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_padded_then_trimmed FOR TESTING RAISING cx_static_check.
    METHODS given_lower_then_upper FOR TESTING RAISING cx_static_check.
    METHODS given_max_length_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_empty_then_raises FOR TESTING.
    METHODS given_blanks_then_raises FOR TESTING.
    METHODS given_too_long_then_raises FOR TESTING.
    METHODS given_write_mode_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_unknown_mode_then_raise FOR TESTING.
    METHODS given_check_mode_then_raises FOR TESTING.
    METHODS given_dialog_scope_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_unknown_scope_then_raise FOR TESTING.
    METHODS given_facade_then_bound FOR TESTING RAISING cx_static_check.
    METHODS given_facade_empty_then_raises FOR TESTING.

    METHODS assert_object_rejected
      IMPORTING value TYPE string.

ENDCLASS.


CLASS ltc_identifiers IMPLEMENTATION.

  METHOD given_plain_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_identifier=>object( `EZORDER` )
      exp = 'EZORDER'
      msg = 'A plain lock object name is changed' ).
  ENDMETHOD.

  METHOD given_padded_then_trimmed.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_identifier=>parameter( `  ORDER_ID  ` )
      exp = 'ORDER_ID'
      msg = 'Blanks around a parameter name are not removed' ).
  ENDMETHOD.

  METHOD given_lower_then_upper.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_identifier=>table( `zorder` )
      exp = 'ZORDER'
      msg = 'A lower case table name is not converted to upper case' ).
  ENDMETHOD.

  METHOD given_max_length_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_identifier=>object( `EZ3456789012345678901234567890` )
      exp = 'EZ3456789012345678901234567890'
      msg = 'A lock object name of exactly 30 characters is rejected' ).
  ENDMETHOD.

  METHOD given_empty_then_raises.
    assert_object_rejected( `` ).
  ENDMETHOD.

  METHOD given_blanks_then_raises.
    assert_object_rejected( `   ` ).
  ENDMETHOD.

  METHOD given_too_long_then_raises.
    assert_object_rejected( `EZ34567890123456789012345678901` ).
  ENDMETHOD.

  METHOD given_write_mode_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_identifier=>mode( zcl_lock=>mode-write )
      exp = zcl_lock=>mode-write
      msg = 'The write mode is changed' ).
  ENDMETHOD.

  METHOD given_unknown_mode_then_raise.
    TRY.
        lcl_identifier=>mode( unknown_mode ).

        cl_abap_unit_assert=>fail( 'An unknown lock mode was unexpectedly accepted' ).
      CATCH zcx_lock INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_check_mode_then_raises.
    TRY.
        lcl_identifier=>mode( if_abap_lock_object=>cs_mode-check_write_lock ).

        cl_abap_unit_assert=>fail( 'A check mode was unexpectedly accepted; acquire( ) would then hold nothing' ).
      CATCH zcx_lock INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_dialog_scope_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_identifier=>scope( zcl_lock=>scope-dialog )
      exp = zcl_lock=>scope-dialog
      msg = 'The dialog scope is changed' ).
  ENDMETHOD.

  METHOD given_unknown_scope_then_raise.
    TRY.
        lcl_identifier=>scope( unknown_scope ).

        cl_abap_unit_assert=>fail( 'An unknown lock scope was unexpectedly accepted' ).
      CATCH zcx_lock INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_facade_then_bound.
    cl_abap_unit_assert=>assert_bound(
      act = zcl_lock=>for_object( `EZORDER` )
      msg = 'The facade does not return a request' ).
  ENDMETHOD.

  METHOD given_facade_empty_then_raises.
    TRY.
        zcl_lock=>for_object( `` ).

        cl_abap_unit_assert=>fail( 'An empty lock object name was unexpectedly accepted by the facade' ).
      CATCH zcx_lock INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD assert_object_rejected.
    TRY.
        lcl_identifier=>object( value ).

        cl_abap_unit_assert=>fail( |Lock object name '{ value }' was unexpectedly accepted| ).
      CATCH zcx_lock INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_configuring DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS lock_object TYPE if_abap_lock_object=>tv_name VALUE 'EZORDER'.
    CONSTANTS order_table TYPE if_abap_lock_object=>tv_table_name VALUE 'ZORDER'.

    DATA engine TYPE REF TO ltd_engine.
    DATA cut TYPE REF TO zif_lock_request.

    METHODS setup.
    METHODS teardown.

    METHODS given_fresh_then_defaults FOR TESTING RAISING cx_static_check.
    METHODS given_with_then_name_upper FOR TESTING RAISING cx_static_check.
    METHODS given_with_then_text_kept FOR TESTING RAISING cx_static_check.
    METHODS given_with_int_then_type_kept FOR TESTING RAISING cx_static_check.
    METHODS given_with_char_then_type_kept FOR TESTING RAISING cx_static_check.
    METHODS given_two_with_then_both_sent FOR TESTING RAISING cx_static_check.
    METHODS given_same_name_twice_raises FOR TESTING.
    METHODS given_empty_name_then_raises FOR TESTING.
    METHODS given_mode_then_passed FOR TESTING RAISING cx_static_check.
    METHODS given_same_table_twice_raises FOR TESTING.
    METHODS given_bad_mode_then_raises FOR TESTING.
    METHODS given_scope_then_passed FOR TESTING RAISING cx_static_check.
    METHODS given_bad_scope_then_raises FOR TESTING.
    METHODS given_waiting_then_flag_passed FOR TESTING RAISING cx_static_check.
    METHODS given_chain_then_all_kept FOR TESTING RAISING cx_static_check.
    METHODS given_derived_then_orig_same FOR TESTING RAISING cx_static_check.

    METHODS sent
      RETURNING VALUE(result) TYPE request.

    METHODS type_kind_of
      IMPORTING value         TYPE REF TO data
      RETURNING VALUE(result) TYPE abap_typekind.

ENDCLASS.


CLASS ltc_configuring IMPLEMENTATION.

  METHOD setup.
    engine = NEW ltd_engine( ).
    cut = NEW lcl_request( request = VALUE #( object = lock_object
                                              scope  = zcl_lock=>scope-update
                                              wait   = if_abap_lock_object=>cs_wait-no )
                           engine  = engine ).
  ENDMETHOD.

  METHOD teardown.
    CLEAR cut.
    CLEAR engine.
  ENDMETHOD.

  METHOD sent.
    result = engine->recorded( )-enqueued.
  ENDMETHOD.

  METHOD type_kind_of.
    result = cl_abap_typedescr=>describe_by_data_ref( value )->type_kind.
  ENDMETHOD.

  METHOD given_fresh_then_defaults.
    cut->acquire( ).

    DATA(request) = sent( ).

    cl_abap_unit_assert=>assert_equals(
      act = request-scope
      exp = zcl_lock=>scope-update
      msg = 'A fresh request is not for the update owner' ).
    cl_abap_unit_assert=>assert_equals(
      act = request-wait
      exp = if_abap_lock_object=>cs_wait-no
      msg = 'A fresh request waits' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( request-parameters )
      exp = 0
      msg = 'A fresh request carries parameters' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( request-table_modes )
      exp = 0
      msg = 'A fresh request overrides a lock mode' ).
  ENDMETHOD.

  METHOD given_with_then_name_upper.
    cut->with( name  = ` order_id `
               value = 4711 )->acquire( ).

    DATA(request) = sent( ).

    cl_abap_unit_assert=>assert_true(
      act = xsdbool( line_exists( request-parameters[ name = 'ORDER_ID' ] ) )
      msg = 'The parameter name is not passed normalised' ).
  ENDMETHOD.

  METHOD given_with_then_text_kept.
    cut->with( name  = `ORDER_ID`
               value = 4711 )->acquire( ).

    DATA(request) = sent( ).

    cl_abap_unit_assert=>assert_equals(
      act = request-parameters[ name = 'ORDER_ID' ]-text
      exp = `4711`
      msg = 'The value is not kept as text for messages' ).
  ENDMETHOD.

  METHOD given_with_int_then_type_kept.
    cut->with( name  = `ORDER_ID`
               value = 4711 )->acquire( ).

    DATA(request) = sent( ).

    cl_abap_unit_assert=>assert_equals(
      act = type_kind_of( request-parameters[ name = 'ORDER_ID' ]-value )
      exp = cl_abap_typedescr=>typekind_int
      msg = 'An integer value does not reach the engine as an integer' ).
  ENDMETHOD.

  METHOD given_with_char_then_type_kept.
    cut->with( name  = `CARRIER`
               value = 'LH' )->acquire( ).

    DATA(request) = sent( ).

    cl_abap_unit_assert=>assert_equals(
      act = type_kind_of( request-parameters[ name = 'CARRIER' ]-value )
      exp = cl_abap_typedescr=>typekind_char
      msg = 'A character value does not reach the engine as a character field' ).
  ENDMETHOD.

  METHOD given_two_with_then_both_sent.
    cut->with( name  = `CARRIER`
               value = 'LH'
      )->with( name  = `CONNECTION`
               value = '0400'
      )->acquire( ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( sent( )-parameters )
      exp = 2
      msg = 'Two parameters do not both reach the engine' ).
  ENDMETHOD.

  METHOD given_same_name_twice_raises.
    TRY.
        cut->with( name  = `ORDER_ID`
                   value = 1
          )->with( name  = `order_id`
                   value = 2 ).

        cl_abap_unit_assert=>fail( 'Setting the same parameter twice was unexpectedly accepted' ).
      CATCH zcx_lock INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_empty_name_then_raises.
    TRY.
        cut->with( name  = ``
                   value = 1 ).

        cl_abap_unit_assert=>fail( 'An empty parameter name was unexpectedly accepted' ).
      CATCH zcx_lock INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_mode_then_passed.
    cut->with_mode( table = ` zorder `
                    mode  = zcl_lock=>mode-shared )->acquire( ).

    cl_abap_unit_assert=>assert_equals(
      act = sent( )-table_modes
      exp = VALUE if_abap_lock_object=>tt_table_mode( ( table_name = order_table
                                                        mode       = zcl_lock=>mode-shared ) )
      msg = 'The lock mode is not passed for the normalised table name' ).
  ENDMETHOD.

  METHOD given_same_table_twice_raises.
    TRY.
        cut->with_mode( table = order_table
                        mode  = zcl_lock=>mode-shared
          )->with_mode( table = order_table
                        mode  = zcl_lock=>mode-exclusive ).

        cl_abap_unit_assert=>fail( 'Setting the mode of the same table twice was unexpectedly accepted' ).
      CATCH zcx_lock INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_bad_mode_then_raises.
    TRY.
        cut->with_mode( table = order_table
                        mode  = if_abap_lock_object=>cs_mode-check_exclusive_lock ).

        cl_abap_unit_assert=>fail( 'A check mode was unexpectedly accepted' ).
      CATCH zcx_lock INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_scope_then_passed.
    cut->in_scope( zcl_lock=>scope-dialog )->acquire( ).

    cl_abap_unit_assert=>assert_equals(
      act = sent( )-scope
      exp = zcl_lock=>scope-dialog
      msg = 'The scope is not passed to the engine' ).
  ENDMETHOD.

  METHOD given_bad_scope_then_raises.
    TRY.
        cut->in_scope( '9' ).

        cl_abap_unit_assert=>fail( 'An unknown scope was unexpectedly accepted' ).
      CATCH zcx_lock INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_waiting_then_flag_passed.
    cut->waiting( )->acquire( ).

    cl_abap_unit_assert=>assert_equals(
      act = sent( )-wait
      exp = if_abap_lock_object=>cs_wait-yes
      msg = 'Waiting is not passed to the engine' ).
  ENDMETHOD.

  METHOD given_chain_then_all_kept.
    cut->with( name  = `ORDER_ID`
               value = 4711
      )->with_mode( table = order_table
                    mode  = zcl_lock=>mode-exclusive
      )->in_scope( zcl_lock=>scope-dialog_and_update
      )->waiting(
      )->acquire( ).

    DATA(request) = sent( ).

    cl_abap_unit_assert=>assert_equals(
      act = request-object
      exp = lock_object
      msg = 'Chained configuration loses the lock object' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( request-parameters )
      exp = 1
      msg = 'Chained configuration loses the parameter' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( request-table_modes )
      exp = 1
      msg = 'Chained configuration loses the lock mode' ).
    cl_abap_unit_assert=>assert_equals(
      act = request-scope
      exp = zcl_lock=>scope-dialog_and_update
      msg = 'Chained configuration loses the scope' ).
    cl_abap_unit_assert=>assert_equals(
      act = request-wait
      exp = if_abap_lock_object=>cs_wait-yes
      msg = 'Chained configuration loses the wait flag' ).
  ENDMETHOD.

  METHOD given_derived_then_orig_same.
    cut->with( name  = `ORDER_ID`
               value = 4711 )->waiting( ).

    cut->acquire( ).

    DATA(request) = sent( ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( request-parameters )
      exp = 0
      msg = 'Deriving a request adds the parameter to the original' ).
    cl_abap_unit_assert=>assert_equals(
      act = request-wait
      exp = if_abap_lock_object=>cs_wait-no
      msg = 'Deriving a request makes the original wait' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_locking DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS lock_object TYPE if_abap_lock_object=>tv_name VALUE 'EZORDER'.
    CONSTANTS other_user TYPE cx_abap_foreign_lock=>tv_user_name VALUE 'OTHER'.

    DATA engine TYPE REF TO ltd_engine.
    DATA cut TYPE REF TO zif_lock_request.

    METHODS setup.
    METHODS teardown.

    METHODS given_acquire_then_held FOR TESTING RAISING cx_static_check.
    METHODS given_acquire_then_object FOR TESTING RAISING cx_static_check.
    METHODS given_acquire_then_describe FOR TESTING RAISING cx_static_check.
    METHODS given_no_params_then_describe FOR TESTING RAISING cx_static_check.
    METHODS given_acquire_then_one_enqueue FOR TESTING RAISING cx_static_check.
    METHODS given_foreign_then_raises FOR TESTING.
    METHODS given_foreign_then_user_named FOR TESTING.
    METHODS given_foreign_no_user_then_txt FOR TESTING.
    METHODS given_failure_then_wrapped FOR TESTING.
    METHODS given_failure_then_not_foreign FOR TESTING.
    METHODS given_release_then_dequeued FOR TESTING RAISING cx_static_check.
    METHODS given_release_then_not_held FOR TESTING RAISING cx_static_check.
    METHODS given_release_twice_then_once FOR TESTING RAISING cx_static_check.
    METHODS given_release_fails_then_wrap FOR TESTING RAISING cx_static_check.
    METHODS given_release_fails_still_held FOR TESTING RAISING cx_static_check.

    METHODS given_engine
      IMPORTING double TYPE REF TO ltd_engine.

    METHODS order_lock
      RETURNING VALUE(result) TYPE REF TO zif_lock
      RAISING   zcx_lock.

    METHODS assert_wrapped
      IMPORTING rejection TYPE REF TO zcx_lock
                cause     TYPE REF TO cx_root.

ENDCLASS.


CLASS ltc_locking IMPLEMENTATION.

  METHOD setup.
    given_engine( NEW ltd_engine( ) ).
  ENDMETHOD.

  METHOD teardown.
    CLEAR cut.
    CLEAR engine.
  ENDMETHOD.

  METHOD given_engine.
    engine = double.
    cut = NEW lcl_request( request = VALUE #( object = lock_object
                                              scope  = zcl_lock=>scope-update
                                              wait   = if_abap_lock_object=>cs_wait-no )
                           engine  = engine ).
  ENDMETHOD.

  METHOD order_lock.
    result = cut->with( name  = `ORDER_ID`
                        value = 4711 )->acquire( ).
  ENDMETHOD.

  METHOD assert_wrapped.
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( rejection->previous = cause )
      msg = 'The lock server exception is not kept as the cause' ).
    cl_abap_unit_assert=>assert_not_initial(
      act = rejection->get_text( )
      msg = 'The wrapped exception does not explain itself' ).
  ENDMETHOD.

  METHOD given_acquire_then_held.
    cl_abap_unit_assert=>assert_true(
      act = order_lock( )->is_held( )
      msg = 'A lock just acquired is not reported as held' ).
  ENDMETHOD.

  METHOD given_acquire_then_object.
    cl_abap_unit_assert=>assert_equals(
      act = order_lock( )->object( )
      exp = `EZORDER`
      msg = 'The lock does not name its lock object' ).
  ENDMETHOD.

  METHOD given_acquire_then_describe.
    DATA(lock) = cut->with( name  = `CARRIER`
                            value = 'LH'
                   )->with( name  = `CONNECTION`
                            value = '0400'
                   )->acquire( ).

    cl_abap_unit_assert=>assert_equals(
      act = lock->describe( )
      exp = `Lock EZORDER with CARRIER = LH, CONNECTION = 0400`
      msg = 'The description does not list object and parameters' ).
  ENDMETHOD.

  METHOD given_no_params_then_describe.
    cl_abap_unit_assert=>assert_equals(
      act = cut->acquire( )->describe( )
      exp = `Lock EZORDER`
      msg = 'A lock without parameters is not described by its object alone' ).
  ENDMETHOD.

  METHOD given_acquire_then_one_enqueue.
    order_lock( ).

    DATA(recorded) = engine->recorded( ).

    cl_abap_unit_assert=>assert_equals(
      act = recorded-enqueue_calls
      exp = 1
      msg = 'Acquiring does not reach the lock server exactly once' ).
    cl_abap_unit_assert=>assert_equals(
      act = recorded-dequeue_calls
      exp = 0
      msg = 'Acquiring releases a lock' ).
  ENDMETHOD.

  METHOD given_foreign_then_raises.
    DATA(cause) = NEW cx_abap_foreign_lock( user_name = other_user ).

    given_engine( NEW ltd_engine( )->refusing_with( cause ) ).

    TRY.
        order_lock( ).

        cl_abap_unit_assert=>fail( 'A foreign lock unexpectedly produced a held lock' ).
      CATCH zcx_lock INTO DATA(rejection).
        assert_wrapped( rejection = rejection
                        cause     = cause ).
        cl_abap_unit_assert=>assert_true(
          act = rejection->is_foreign_lock( )
          msg = 'A foreign lock is not reported as such' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_foreign_then_user_named.
    given_engine( NEW ltd_engine( )->refusing_with( NEW cx_abap_foreign_lock( user_name = other_user ) ) ).

    TRY.
        order_lock( ).

        cl_abap_unit_assert=>fail( 'A foreign lock unexpectedly produced a held lock' ).
      CATCH zcx_lock INTO DATA(rejection).
        cl_abap_unit_assert=>assert_equals(
          act = rejection->locked_by( )
          exp = `OTHER`
          msg = 'The user holding the lock is not named' ).
        cl_abap_unit_assert=>assert_equals(
          act = rejection->get_text( )
          exp = `Lock EZORDER with ORDER_ID = 4711 is held by user OTHER`
          msg = 'The message does not name lock and user' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_foreign_no_user_then_txt.
    given_engine( NEW ltd_engine( )->refusing_with( NEW cx_abap_foreign_lock( ) ) ).

    TRY.
        order_lock( ).

        cl_abap_unit_assert=>fail( 'A foreign lock unexpectedly produced a held lock' ).
      CATCH zcx_lock INTO DATA(rejection).
        cl_abap_unit_assert=>assert_initial(
          act = rejection->locked_by( )
          msg = 'A user is named although the lock server did not report one' ).
        cl_abap_unit_assert=>assert_true(
          act = rejection->is_foreign_lock( )
          msg = 'A foreign lock without user is not reported as foreign' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_failure_then_wrapped.
    DATA(cause) = NEW cx_abap_lock_failure( ).

    given_engine( NEW ltd_engine( )->refusing_with( cause ) ).

    TRY.
        order_lock( ).

        cl_abap_unit_assert=>fail( 'A failing lock server unexpectedly produced a held lock' ).
      CATCH zcx_lock INTO DATA(rejection).
        assert_wrapped( rejection = rejection
                        cause     = cause ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_failure_then_not_foreign.
    given_engine( NEW ltd_engine( )->refusing_with( NEW cx_abap_lock_failure( ) ) ).

    TRY.
        order_lock( ).

        cl_abap_unit_assert=>fail( 'A failing lock server unexpectedly produced a held lock' ).
      CATCH zcx_lock INTO DATA(rejection).
        cl_abap_unit_assert=>assert_false(
          act = rejection->is_foreign_lock( )
          msg = 'A lock server failure is reported as a foreign lock' ).
        cl_abap_unit_assert=>assert_initial(
          act = rejection->locked_by( )
          msg = 'A lock server failure names a user' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_release_then_dequeued.
    order_lock( )->release( ).

    DATA(recorded) = engine->recorded( ).

    cl_abap_unit_assert=>assert_equals(
      act = recorded-dequeue_calls
      exp = 1
      msg = 'Releasing does not reach the lock server exactly once' ).
    cl_abap_unit_assert=>assert_equals(
      act = recorded-dequeued
      exp = recorded-enqueued
      msg = 'The lock is not released with the request that set it' ).
  ENDMETHOD.

  METHOD given_release_then_not_held.
    DATA(lock) = order_lock( ).

    lock->release( ).

    cl_abap_unit_assert=>assert_false(
      act = lock->is_held( )
      msg = 'A released lock is still reported as held' ).
  ENDMETHOD.

  METHOD given_release_twice_then_once.
    DATA(lock) = order_lock( ).

    lock->release( ).
    lock->release( ).

    cl_abap_unit_assert=>assert_equals(
      act = engine->recorded( )-dequeue_calls
      exp = 1
      msg = 'A second release reaches the lock server' ).
  ENDMETHOD.

  METHOD given_release_fails_then_wrap.
    DATA(cause) = NEW cx_abap_lock_failure( ).

    given_engine( NEW ltd_engine( )->releasing_fails_with( cause ) ).

    TRY.
        order_lock( )->release( ).

        cl_abap_unit_assert=>fail( 'A refused release was unexpectedly reported as success' ).
      CATCH zcx_lock INTO DATA(rejection).
        assert_wrapped( rejection = rejection
                        cause     = cause ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_release_fails_still_held.
    given_engine( NEW ltd_engine( )->releasing_fails_with( NEW cx_abap_lock_failure( ) ) ).

    DATA(lock) = order_lock( ).

    TRY.
        lock->release( ).

        cl_abap_unit_assert=>fail( 'A refused release was unexpectedly reported as success' ).
      CATCH zcx_lock.
        cl_abap_unit_assert=>assert_true(
          act = lock->is_held( )
          msg = 'A lock whose release was refused is no longer reported as held' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
