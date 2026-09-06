*"* use this source file for your ABAP unit test classes
"! Stands in for the number range runtime. Keeps a number level, hands out
"! consecutive numbers until a configurable remainder is used up, reports a
"! configurable status code and records what it was asked for.
CLASS ltd_runtime DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    INTERFACES lif_runtime.

    TYPES:
      BEGIN OF recording,
        settings     TYPE settings,
        quantity     TYPE i,
        get_calls    TYPE i,
        status_calls TYPE i,
      END OF recording.

    METHODS constructor
      IMPORTING level     TYPE i DEFAULT 0
                remaining TYPE i DEFAULT 1000.

    METHODS reporting
      IMPORTING returncode  TYPE cl_numberrange_runtime=>nr_returncode
      RETURNING VALUE(self) TYPE REF TO ltd_runtime.

    METHODS failing_with
      IMPORTING failure     TYPE REF TO cx_number_ranges
      RETURNING VALUE(self) TYPE REF TO ltd_runtime.

    METHODS recorded
      RETURNING VALUE(result) TYPE recording.

  PRIVATE SECTION.
    CONSTANTS short_supply TYPE cl_numberrange_runtime=>nr_returncode VALUE '3'.

    DATA level TYPE i.
    DATA remaining TYPE i.
    DATA returncode TYPE cl_numberrange_runtime=>nr_returncode.
    DATA failure TYPE REF TO cx_number_ranges.
    DATA log TYPE recording.

ENDCLASS.


CLASS ltd_runtime IMPLEMENTATION.

  METHOD constructor.
    me->level = level.
    me->remaining = remaining.
  ENDMETHOD.

  METHOD reporting.
    me->returncode = returncode.

    self = me.
  ENDMETHOD.

  METHOD failing_with.
    me->failure = failure.

    self = me.
  ENDMETHOD.

  METHOD recorded.
    result = log.
  ENDMETHOD.

  METHOD lif_runtime~number_get.
    log-settings = settings.
    log-quantity = quantity.
    log-get_calls = log-get_calls + 1.

    IF failure IS BOUND.
      RAISE EXCEPTION failure.
    ENDIF.

    DATA(assigned) = nmin( val1 = CONV i( quantity )
                           val2 = remaining ).

    level = level + assigned.
    remaining = remaining - assigned.

    result = VALUE #( number            = level
                      returned_quantity = assigned
                      returncode        = COND #( WHEN assigned < quantity THEN short_supply
                                                  ELSE returncode ) ).
  ENDMETHOD.

  METHOD lif_runtime~number_status.
    log-settings = settings.
    log-status_calls = log-status_calls + 1.

    IF failure IS BOUND.
      RAISE EXCEPTION failure.
    ENDIF.

    result = level.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_identifiers DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_plain_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_padded_then_trimmed FOR TESTING RAISING cx_static_check.
    METHODS given_lower_then_upper FOR TESTING RAISING cx_static_check.
    METHODS given_max_length_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_empty_then_raises FOR TESTING.
    METHODS given_blanks_then_raises FOR TESTING.
    METHODS given_too_long_then_raises FOR TESTING.
    METHODS given_long_interval_then_raise FOR TESTING.
    METHODS given_year_2026_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_year_0_then_raises FOR TESTING.
    METHODS given_year_10000_then_raises FOR TESTING.
    METHODS given_facade_then_bound FOR TESTING RAISING cx_static_check.
    METHODS given_bad_object_then_raises FOR TESTING.
    METHODS given_bad_interval_then_raises FOR TESTING.

    METHODS assert_object_rejected
      IMPORTING value TYPE string.

ENDCLASS.


CLASS ltc_identifiers IMPLEMENTATION.

  METHOD given_plain_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_identifier=>object( `ZINVOICE` )
      exp = 'ZINVOICE'
      msg = 'A plain object name is changed' ).
  ENDMETHOD.

  METHOD given_padded_then_trimmed.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_identifier=>object( `  ZINVOICE  ` )
      exp = 'ZINVOICE'
      msg = 'Blanks around the object name are not removed' ).
  ENDMETHOD.

  METHOD given_lower_then_upper.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_identifier=>object( `zinvoice` )
      exp = 'ZINVOICE'
      msg = 'A lower case object name is not converted to upper case' ).
  ENDMETHOD.

  METHOD given_max_length_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_identifier=>object( `Z123456789` )
      exp = 'Z123456789'
      msg = 'An object name of exactly 10 characters is rejected' ).
  ENDMETHOD.

  METHOD given_empty_then_raises.
    assert_object_rejected( `` ).
  ENDMETHOD.

  METHOD given_blanks_then_raises.
    assert_object_rejected( `   ` ).
  ENDMETHOD.

  METHOD given_too_long_then_raises.
    assert_object_rejected( `Z1234567890` ).
  ENDMETHOD.

  METHOD given_long_interval_then_raise.
    TRY.
        lcl_identifier=>interval( `001` ).

        cl_abap_unit_assert=>fail( 'An interval number of 3 characters was unexpectedly accepted' ).
      CATCH zcx_number_range INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_year_2026_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_identifier=>year( 2026 )
      exp = '2026'
      msg = 'A valid year is changed' ).
  ENDMETHOD.

  METHOD given_year_0_then_raises.
    TRY.
        lcl_identifier=>year( 0 ).

        cl_abap_unit_assert=>fail( 'Year 0 was unexpectedly accepted' ).
      CATCH zcx_number_range INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_year_10000_then_raises.
    TRY.
        lcl_identifier=>year( 10000 ).

        cl_abap_unit_assert=>fail( 'Year 10000 was unexpectedly accepted' ).
      CATCH zcx_number_range INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_facade_then_bound.
    cl_abap_unit_assert=>assert_bound(
      act = zcl_number_range=>for_interval( object   = `ZINVOICE`
                                            interval = `01` )
      msg = 'The facade does not return an interval' ).
  ENDMETHOD.

  METHOD given_bad_object_then_raises.
    TRY.
        zcl_number_range=>for_interval( object   = ``
                                        interval = `01` ).

        cl_abap_unit_assert=>fail( 'An empty object name was unexpectedly accepted by the facade' ).
      CATCH zcx_number_range INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_bad_interval_then_raises.
    TRY.
        zcl_number_range=>for_interval( object   = `ZINVOICE`
                                        interval = `` ).

        cl_abap_unit_assert=>fail( 'An empty interval number was unexpectedly accepted by the facade' ).
      CATCH zcx_number_range INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD assert_object_rejected.
    TRY.
        lcl_identifier=>object( value ).

        cl_abap_unit_assert=>fail( |Object name '{ value }' was unexpectedly accepted| ).
      CATCH zcx_number_range INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_assigning DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS level TYPE i VALUE 41.
    CONSTANTS critical TYPE cl_numberrange_runtime=>nr_returncode VALUE '1'.
    CONSTANTS exhausted TYPE cl_numberrange_runtime=>nr_returncode VALUE '2'.

    DATA runtime TYPE REF TO ltd_runtime.
    DATA cut TYPE REF TO zif_number_range.

    METHODS setup.
    METHODS teardown.

    METHODS given_level_41_then_next_42 FOR TESTING RAISING cx_static_check.
    METHODS given_next_then_asks_for_one FOR TESTING RAISING cx_static_check.
    METHODS given_next_then_settings_sent FOR TESTING RAISING cx_static_check.
    METHODS given_two_next_then_ascending FOR TESTING RAISING cx_static_check.
    METHODS given_block_5_then_42_to_46 FOR TESTING RAISING cx_static_check.
    METHODS given_rc_blank_then_no_flags FOR TESTING RAISING cx_static_check.
    METHODS given_rc_1_then_critical FOR TESTING RAISING cx_static_check.
    METHODS given_rc_2_then_exhausted FOR TESTING RAISING cx_static_check.
    METHODS given_short_supply_then_3_of_5 FOR TESTING RAISING cx_static_check.
    METHODS given_numbers_3_then_3_lines FOR TESTING RAISING cx_static_check.
    METHODS given_numbers_short_then_raise FOR TESTING.
    METHODS given_quantity_0_then_rejected FOR TESTING.
    METHODS given_negative_qty_then_raises FOR TESTING.
    METHODS given_nothing_left_then_raises FOR TESTING.
    METHODS given_runtime_fails_then_wrap FOR TESTING.
    METHODS given_status_then_level_back FOR TESTING RAISING cx_static_check.
    METHODS given_status_then_no_consume FOR TESTING RAISING cx_static_check.
    METHODS given_status_fails_then_wrap FOR TESTING.

    METHODS given_runtime
      IMPORTING double TYPE REF TO ltd_runtime.

    METHODS number
      IMPORTING value         TYPE i
      RETURNING VALUE(result) TYPE zif_number_range=>number.

    METHODS assert_wrapped
      IMPORTING rejection TYPE REF TO zcx_number_range
                cause     TYPE REF TO cx_number_ranges.

ENDCLASS.


CLASS ltc_assigning IMPLEMENTATION.

  METHOD setup.
    given_runtime( NEW ltd_runtime( level = level ) ).
  ENDMETHOD.

  METHOD teardown.
    CLEAR cut.
    CLEAR runtime.
  ENDMETHOD.

  METHOD given_runtime.
    runtime = double.
    cut = NEW lcl_number_range( settings = VALUE #( object   = 'ZINVOICE'
                                                    interval = '01' )
                                runtime  = runtime ).
  ENDMETHOD.

  METHOD number.
    result = value.
  ENDMETHOD.

  METHOD assert_wrapped.
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( rejection->previous = cause )
      msg = 'The runtime exception is not kept as the cause' ).
    cl_abap_unit_assert=>assert_not_initial(
      act = rejection->get_text( )
      msg = 'The wrapped exception does not explain itself' ).
  ENDMETHOD.

  METHOD given_level_41_then_next_42.
    cl_abap_unit_assert=>assert_equals(
      act = cut->next( )
      exp = number( 42 )
      msg = 'The number after level 41 is not 42' ).
  ENDMETHOD.

  METHOD given_next_then_asks_for_one.
    cut->next( ).

    cl_abap_unit_assert=>assert_equals(
      act = runtime->recorded( )-quantity
      exp = 1
      msg = 'A single number is not requested as quantity 1' ).
  ENDMETHOD.

  METHOD given_next_then_settings_sent.
    cut->next( ).

    cl_abap_unit_assert=>assert_equals(
      act = runtime->recorded( )-settings
      exp = VALUE settings( object   = 'ZINVOICE'
                            interval = '01' )
      msg = 'Object and interval are not passed to the runtime as given' ).
  ENDMETHOD.

  METHOD given_two_next_then_ascending.
    cut->next( ).

    cl_abap_unit_assert=>assert_equals(
      act = cut->next( )
      exp = number( 43 )
      msg = 'The second request does not yield the number after the first one' ).
  ENDMETHOD.

  METHOD given_block_5_then_42_to_46.
    DATA(block) = cut->next_block( 5 ).

    cl_abap_unit_assert=>assert_equals(
      act = block-first
      exp = number( 42 )
      msg = 'The block does not start right after the level' ).
    cl_abap_unit_assert=>assert_equals(
      act = block-last
      exp = number( 46 )
      msg = 'The block does not end at the last number assigned' ).
    cl_abap_unit_assert=>assert_equals(
      act = block-quantity
      exp = 5
      msg = 'The block does not report the requested quantity' ).
  ENDMETHOD.

  METHOD given_rc_blank_then_no_flags.
    DATA(block) = cut->next_block( 1 ).

    cl_abap_unit_assert=>assert_false(
      act = block-is_critical
      msg = 'A normal assignment is reported as critical' ).
    cl_abap_unit_assert=>assert_false(
      act = block-is_exhausted
      msg = 'A normal assignment is reported as exhausted' ).
  ENDMETHOD.

  METHOD given_rc_1_then_critical.
    given_runtime( NEW ltd_runtime( level = level )->reporting( critical ) ).

    DATA(block) = cut->next_block( 1 ).

    cl_abap_unit_assert=>assert_true(
      act = block-is_critical
      msg = 'Return code 1 is not reported as critical' ).
    cl_abap_unit_assert=>assert_false(
      act = block-is_exhausted
      msg = 'Return code 1 is reported as exhausted' ).
  ENDMETHOD.

  METHOD given_rc_2_then_exhausted.
    given_runtime( NEW ltd_runtime( level = level )->reporting( exhausted ) ).

    DATA(block) = cut->next_block( 1 ).

    cl_abap_unit_assert=>assert_true(
      act = block-is_exhausted
      msg = 'Return code 2 is not reported as exhausted' ).
    cl_abap_unit_assert=>assert_false(
      act = block-is_critical
      msg = 'Return code 2 is reported as critical' ).
  ENDMETHOD.

  METHOD given_short_supply_then_3_of_5.
    given_runtime( NEW ltd_runtime( level     = level
                                    remaining = 3 ) ).

    DATA(block) = cut->next_block( 5 ).

    cl_abap_unit_assert=>assert_equals(
      act = block-quantity
      exp = 3
      msg = 'A short block does not report the quantity actually assigned' ).
    cl_abap_unit_assert=>assert_equals(
      act = block-last
      exp = number( 44 )
      msg = 'A short block does not end at the last number assigned' ).
    cl_abap_unit_assert=>assert_equals(
      act = block-first
      exp = number( 42 )
      msg = 'A short block does not start right after the level' ).
  ENDMETHOD.

  METHOD given_numbers_3_then_3_lines.
    cl_abap_unit_assert=>assert_equals(
      act = cut->next_numbers( 3 )
      exp = VALUE zif_number_range=>number_table( ( number( 42 ) ) ( number( 43 ) ) ( number( 44 ) ) )
      msg = 'Three requested numbers are not returned as three ascending lines' ).
  ENDMETHOD.

  METHOD given_numbers_short_then_raise.
    given_runtime( NEW ltd_runtime( level     = level
                                    remaining = 3 ) ).

    TRY.
        cut->next_numbers( 5 ).

        cl_abap_unit_assert=>fail( 'A short assignment was unexpectedly returned as a table' ).
      CATCH zcx_number_range INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_quantity_0_then_rejected.
    TRY.
        cut->next_block( 0 ).

        cl_abap_unit_assert=>fail( 'Quantity 0 was unexpectedly accepted' ).
      CATCH zcx_number_range INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.

    cl_abap_unit_assert=>assert_equals(
      act = runtime->recorded( )-get_calls
      exp = 0
      msg = 'The runtime is called although the quantity was rejected' ).
  ENDMETHOD.

  METHOD given_negative_qty_then_raises.
    TRY.
        cut->next_numbers( -1 ).

        cl_abap_unit_assert=>fail( 'A negative quantity was unexpectedly accepted' ).
      CATCH zcx_number_range INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_nothing_left_then_raises.
    given_runtime( NEW ltd_runtime( level     = level
                                    remaining = 0 ) ).

    TRY.
        cut->next( ).

        cl_abap_unit_assert=>fail( 'An assignment of zero numbers was unexpectedly returned as a number' ).
      CATCH zcx_number_range INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_runtime_fails_then_wrap.
    DATA(cause) = NEW cx_nr_object_not_found( ).

    given_runtime( NEW ltd_runtime( )->failing_with( cause ) ).

    TRY.
        cut->next( ).

        cl_abap_unit_assert=>fail( 'A failing runtime unexpectedly produced a number' ).
      CATCH zcx_number_range INTO DATA(rejection).
        assert_wrapped( rejection = rejection
                        cause     = cause ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_status_then_level_back.
    cl_abap_unit_assert=>assert_equals(
      act = cut->last_assigned( )
      exp = number( 41 )
      msg = 'The number level is not passed through' ).
  ENDMETHOD.

  METHOD given_status_then_no_consume.
    cut->last_assigned( ).

    DATA(recorded) = runtime->recorded( ).

    cl_abap_unit_assert=>assert_equals(
      act = recorded-get_calls
      exp = 0
      msg = 'Reading the level assigns a number' ).
    cl_abap_unit_assert=>assert_equals(
      act = recorded-status_calls
      exp = 1
      msg = 'Reading the level does not ask the runtime for the status' ).
  ENDMETHOD.

  METHOD given_status_fails_then_wrap.
    DATA(cause) = NEW cx_nr_object_not_found( ).

    given_runtime( NEW ltd_runtime( )->failing_with( cause ) ).

    TRY.
        cut->last_assigned( ).

        cl_abap_unit_assert=>fail( 'A failing runtime unexpectedly produced a number level' ).
      CATCH zcx_number_range INTO DATA(rejection).
        assert_wrapped( rejection = rejection
                        cause     = cause ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_configuring DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA runtime TYPE REF TO ltd_runtime.
    DATA cut TYPE REF TO zif_number_range.

    METHODS setup.
    METHODS teardown.

    METHODS given_subobject_then_passed FOR TESTING RAISING cx_static_check.
    METHODS given_year_then_passed FOR TESTING RAISING cx_static_check.
    METHODS given_bypass_then_flag_passed FOR TESTING RAISING cx_static_check.
    METHODS given_chain_then_all_kept FOR TESTING RAISING cx_static_check.
    METHODS given_derived_then_orig_same FOR TESTING RAISING cx_static_check.
    METHODS given_subobj_7_chars_raises FOR TESTING.
    METHODS given_empty_subobj_then_raise FOR TESTING.
    METHODS given_bad_year_then_raises FOR TESTING.

    METHODS assert_subobject_rejected
      IMPORTING value TYPE string.

ENDCLASS.


CLASS ltc_configuring IMPLEMENTATION.

  METHOD setup.
    runtime = NEW ltd_runtime( ).
    cut = NEW lcl_number_range( settings = VALUE #( object   = 'ZINVOICE'
                                                    interval = '01' )
                                runtime  = runtime ).
  ENDMETHOD.

  METHOD teardown.
    CLEAR cut.
    CLEAR runtime.
  ENDMETHOD.

  METHOD assert_subobject_rejected.
    TRY.
        cut->in_subobject( value ).

        cl_abap_unit_assert=>fail( |Subobject '{ value }' was unexpectedly accepted| ).
      CATCH zcx_number_range INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_subobject_then_passed.
    cut->in_subobject( ` gr01 ` )->next( ).

    cl_abap_unit_assert=>assert_equals(
      act = runtime->recorded( )-settings-subobject
      exp = 'GR01'
      msg = 'The subobject is not passed to the runtime normalised' ).
  ENDMETHOD.

  METHOD given_year_then_passed.
    cut->for_year( 2026 )->next( ).

    cl_abap_unit_assert=>assert_equals(
      act = runtime->recorded( )-settings-year
      exp = '2026'
      msg = 'The year is not passed to the runtime' ).
  ENDMETHOD.

  METHOD given_bypass_then_flag_passed.
    cut->bypassing_buffer( )->next( ).

    cl_abap_unit_assert=>assert_equals(
      act = runtime->recorded( )-settings-ignore_buffer
      exp = abap_true
      msg = 'Bypassing the buffer is not passed to the runtime' ).
  ENDMETHOD.

  METHOD given_chain_then_all_kept.
    cut->in_subobject( `GR01` )->for_year( 2026 )->bypassing_buffer( )->next( ).

    cl_abap_unit_assert=>assert_equals(
      act = runtime->recorded( )-settings
      exp = VALUE settings( object        = 'ZINVOICE'
                            interval      = '01'
                            subobject     = 'GR01'
                            year          = '2026'
                            ignore_buffer = abap_true )
      msg = 'Chained configuration loses a setting on the way' ).
  ENDMETHOD.

  METHOD given_derived_then_orig_same.
    cut->in_subobject( `GR01` )->for_year( 2026 ).

    cut->next( ).

    cl_abap_unit_assert=>assert_equals(
      act = runtime->recorded( )-settings
      exp = VALUE settings( object   = 'ZINVOICE'
                            interval = '01' )
      msg = 'Deriving a configured interval changes the original' ).
  ENDMETHOD.

  METHOD given_subobj_7_chars_raises.
    assert_subobject_rejected( `GR01234` ).
  ENDMETHOD.

  METHOD given_empty_subobj_then_raise.
    assert_subobject_rejected( `  ` ).
  ENDMETHOD.

  METHOD given_bad_year_then_raises.
    TRY.
        cut->for_year( -1 ).

        cl_abap_unit_assert=>fail( 'Year -1 was unexpectedly accepted' ).
      CATCH zcx_number_range INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
