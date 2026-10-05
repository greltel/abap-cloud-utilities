*"* use this source file for your ABAP unit test classes
"! Checks that a rejection names what was rejected, so that the message
"! alone tells a developer which value or table to look at.
CLASS lth_rejection DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    CLASS-METHODS assert_names
      IMPORTING rejection TYPE REF TO zcx_range
                culprit   TYPE string.

ENDCLASS.


CLASS lth_rejection IMPLEMENTATION.

  METHOD assert_names.
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( contains( val = rejection->get_text( )
                               sub = culprit ) )
      msg = |The rejection "{ rejection->get_text( ) }" does not name "{ culprit }"| ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_builder DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_order,
        id     TYPE i,
        status TYPE string,
      END OF ty_order.
    TYPES ty_orders TYPE STANDARD TABLE OF ty_order WITH EMPTY KEY.
    TYPES ty_period TYPE n LENGTH 3.
    TYPES ty_price TYPE p LENGTH 7 DECIMALS 2.
    TYPES ty_code TYPE x LENGTH 2.

    METHODS when_equal_then_including_eq FOR TESTING RAISING cx_static_check.
    METHODS when_not_equal_then_excl_eq FOR TESTING RAISING cx_static_check.
    METHODS when_between_then_interval FOR TESTING RAISING cx_static_check.
    METHODS when_not_between_then_excl_bt FOR TESTING RAISING cx_static_check.
    METHODS when_pattern_then_cp FOR TESTING RAISING cx_static_check.
    METHODS when_not_pattern_then_excl_cp FOR TESTING RAISING cx_static_check.
    METHODS when_borders_then_gt_ge_lt_le FOR TESTING RAISING cx_static_check.
    METHODS when_from_list_then_eq_each FOR TESTING RAISING cx_static_check.
    METHODS when_not_in_then_excl_eq_each FOR TESTING RAISING cx_static_check.
    METHODS when_added_twice_then_once FOR TESTING RAISING cx_static_check.
    METHODS when_typed_then_stored_form FOR TESTING RAISING cx_static_check.
    METHODS when_nothing_added_then_empty FOR TESTING RAISING cx_static_check.
    METHODS when_condition_then_not_empty FOR TESTING RAISING cx_static_check.
    METHODS when_built_then_independent FOR TESTING RAISING cx_static_check.
    METHODS given_row_list_then_raises FOR TESTING.
    METHODS given_mistake_then_first_kept FOR TESTING.

ENDCLASS.


CLASS ltc_builder IMPLEMENTATION.

  METHOD when_equal_then_including_eq.
    DATA(conditions) = zcl_acu_range=>builder( )->equal( `A` )->build( )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'EQ' low = `A` ) )
      msg = `equal( ) does not add an including EQ condition` ).
  ENDMETHOD.

  METHOD when_not_equal_then_excl_eq.
    DATA(conditions) = zcl_acu_range=>builder( )->not_equal( `A` )->build( )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'E' option = 'EQ' low = `A` ) )
      msg = `not_equal( ) does not add an excluding EQ condition` ).
  ENDMETHOD.

  METHOD when_between_then_interval.
    DATA(conditions) = zcl_acu_range=>builder( )->between( low  = `A`
                                                           high = `C` )->build( )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'BT' low = `A` high = `C` ) )
      msg = `between( ) does not add an including BT condition with both borders` ).
  ENDMETHOD.

  METHOD when_not_between_then_excl_bt.
    DATA(conditions) = zcl_acu_range=>builder( )->not_between( low  = `A`
                                                               high = `C` )->build( )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'E' option = 'BT' low = `A` high = `C` ) )
      msg = `not_between( ) does not add an excluding BT condition with both borders` ).
  ENDMETHOD.

  METHOD when_pattern_then_cp.
    DATA(conditions) = zcl_acu_range=>builder( )->pattern( `4*` )->build( )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'CP' low = `4*` ) )
      msg = `pattern( ) does not add an including CP condition` ).
  ENDMETHOD.

  METHOD when_not_pattern_then_excl_cp.
    DATA(conditions) = zcl_acu_range=>builder( )->not_pattern( `4*` )->build( )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'E' option = 'CP' low = `4*` ) )
      msg = `not_pattern( ) does not add an excluding CP condition` ).
  ENDMETHOD.

  METHOD when_borders_then_gt_ge_lt_le.
    DATA(conditions) = zcl_acu_range=>builder( )->greater_than( `A`
                                               )->greater_or_equal( `B`
                                               )->less_than( `C`
                                               )->less_or_equal( `D`
                                               )->build( )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'GT' low = `A` )
                                            ( sign = 'I' option = 'GE' low = `B` )
                                            ( sign = 'I' option = 'LT' low = `C` )
                                            ( sign = 'I' option = 'LE' low = `D` ) )
      msg = `The four border methods do not add GT, GE, LT and LE in the order of the calls` ).
  ENDMETHOD.

  METHOD when_from_list_then_eq_each.
    DATA(plants) = VALUE string_table( ( `1000` ) ( `2000` ) ).

    DATA(conditions) = zcl_acu_range=>builder( )->from_list( plants )->build( )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'EQ' low = `1000` )
                                            ( sign = 'I' option = 'EQ' low = `2000` ) )
      msg = `from_list( ) does not add one including EQ condition per value` ).
  ENDMETHOD.

  METHOD when_not_in_then_excl_eq_each.
    DATA(plants) = VALUE string_table( ( `1000` ) ( `2000` ) ).

    DATA(conditions) = zcl_acu_range=>builder( )->not_in( plants )->build( )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'E' option = 'EQ' low = `1000` )
                                            ( sign = 'E' option = 'EQ' low = `2000` ) )
      msg = `not_in( ) does not add one excluding EQ condition per value` ).
  ENDMETHOD.

  METHOD when_added_twice_then_once.
    DATA(plants) = VALUE string_table( ( `1000` ) ( `2000` ) ( `1000` ) ).

    DATA(conditions) = zcl_acu_range=>builder( )->from_list( plants
                                               )->equal( `2000`
                                               )->not_equal( `2000`
                                               )->build( )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'EQ' low = `1000` )
                                            ( sign = 'I' option = 'EQ' low = `2000` )
                                            ( sign = 'E' option = 'EQ' low = `2000` ) )
      msg = `A condition added twice is not kept exactly once, or the order of the calls is lost` ).
  ENDMETHOD.

  METHOD when_typed_then_stored_form.
    DATA(conditions) = zcl_acu_range=>builder( )->equal( CONV d( '20260115' )
                                               )->equal( CONV ty_period( '007' )
                                               )->equal( CONV ty_price( '19.99' )
                                               )->equal( 5
                                               )->equal( CONV ty_code( 'CAFE' )
                                               )->build( )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'EQ' low = `20260115` )
                                            ( sign = 'I' option = 'EQ' low = `007` )
                                            ( sign = 'I' option = 'EQ' low = `19.99` )
                                            ( sign = 'I' option = 'EQ' low = `5` )
                                            ( sign = 'I' option = 'EQ' low = `CAFE` ) )
      msg = `Typed values are not held in the form a string template writes them` ).
  ENDMETHOD.

  METHOD when_nothing_added_then_empty.
    DATA(range) = zcl_acu_range=>builder( )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->is_empty( )
                                        exp = abap_true
                                        msg = `A range without conditions does not report itself as empty` ).
    cl_abap_unit_assert=>assert_initial( act = range->conditions( )
                                         msg = `A range without conditions returns conditions` ).
  ENDMETHOD.

  METHOD when_condition_then_not_empty.
    cl_abap_unit_assert=>assert_equals( act = zcl_acu_range=>builder( )->not_equal( `A` )->build( )->is_empty( )
                                        exp = abap_false
                                        msg = `A range with a condition reports itself as empty` ).
  ENDMETHOD.

  METHOD when_built_then_independent.
    DATA(builder) = zcl_acu_range=>builder( )->equal( `A` ).
    DATA(first) = builder->build( ).

    DATA(second) = builder->equal( `B` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = lines( first->conditions( ) )
                                        exp = 1
                                        msg = `A range changed after it was built` ).
    cl_abap_unit_assert=>assert_equals( act = lines( second->conditions( ) )
                                        exp = 2
                                        msg = `A builder cannot be continued after build( )` ).
  ENDMETHOD.

  METHOD given_row_list_then_raises.
    DATA(orders) = VALUE ty_orders( ( id = 1 status = `A` ) ).

    TRY.
        zcl_acu_range=>builder( )->from_list( orders )->build( ).

        cl_abap_unit_assert=>fail( `A table of structures was accepted as a list of values` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `list of values` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_mistake_then_first_kept.
    DATA(orders) = VALUE ty_orders( ( id = 1 status = `A` ) ).
    DATA(texts) = VALUE string_table( ( `A` ) ).

    TRY.
        zcl_acu_range=>builder( )->not_in( orders )->from_range( texts )->equal( `A` )->build( ).

        cl_abap_unit_assert=>fail( `A chain with a mistake was built` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `list of values` ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_from_range DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES ty_plant TYPE c LENGTH 4.
    TYPES ty_plants TYPE RANGE OF ty_plant.
    TYPES ty_quantities TYPE RANGE OF i.
    TYPES:
      BEGIN OF ty_half_row,
        sign   TYPE c LENGTH 1,
        option TYPE c LENGTH 2,
        low    TYPE string,
      END OF ty_half_row.
    TYPES ty_half_rows TYPE STANDARD TABLE OF ty_half_row WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_deep_row,
        sign   TYPE c LENGTH 1,
        option TYPE c LENGTH 2,
        low    TYPE string_table,
        high   TYPE string_table,
      END OF ty_deep_row.
    TYPES ty_deep_rows TYPE STANDARD TABLE OF ty_deep_row WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_text_row,
        sign   TYPE string,
        option TYPE string,
        low    TYPE string,
        high   TYPE string,
      END OF ty_text_row.
    TYPES ty_text_rows TYPE STANDARD TABLE OF ty_text_row WITH EMPTY KEY.

    METHODS given_typed_range_then_adopted FOR TESTING RAISING cx_static_check.
    METHODS given_number_range_then_text FOR TESTING RAISING cx_static_check.
    METHODS given_lower_case_then_upper FOR TESTING RAISING cx_static_check.
    METHODS given_high_no_interval_dropped FOR TESTING RAISING cx_static_check.
    METHODS given_including_ne_then_kept FOR TESTING RAISING cx_static_check.
    METHODS when_extended_then_both_kept FOR TESTING RAISING cx_static_check.
    METHODS given_list_when_facade_then_eq FOR TESTING RAISING cx_static_check.
    METHODS given_sorted_list_then_taken FOR TESTING RAISING cx_static_check.
    METHODS given_bad_sign_then_raises FOR TESTING.
    METHODS given_bad_option_then_raises FOR TESTING.
    METHODS given_wordy_sign_then_raises FOR TESTING.
    METHODS given_value_list_then_raises FOR TESTING.
    METHODS given_no_high_then_raises FOR TESTING.
    METHODS given_deep_low_then_raises FOR TESTING.
    METHODS given_row_list_facade_raises FOR TESTING.

ENDCLASS.


CLASS ltc_from_range IMPLEMENTATION.

  METHOD given_typed_range_then_adopted.
    DATA(plants) = VALUE ty_plants( ( sign = 'I' option = 'EQ' low = '1000' )
                                    ( sign = 'I' option = 'BT' low = '2000' high = '2999' )
                                    ( sign = 'E' option = 'CP' low = '21*' ) ).

    DATA(conditions) = zcl_acu_range=>from_range( plants )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'EQ' low = `1000` )
                                            ( sign = 'I' option = 'BT' low = `2000` high = `2999` )
                                            ( sign = 'E' option = 'CP' low = `21*` ) )
      msg = `The rows of a RANGE OF table are not taken over as they are` ).
  ENDMETHOD.

  METHOD given_number_range_then_text.
    DATA(quantities) = VALUE ty_quantities( ( sign = 'I' option = 'BT' low = 1 high = 10 ) ).

    DATA(range) = zcl_acu_range=>from_range( quantities ).

    cl_abap_unit_assert=>assert_equals(
      act = range->conditions( )
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'BT' low = `1` high = `10` ) )
      msg = `The values of a numeric ranges table are not taken over as text` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( 9 )
                                        exp = abap_true
                                        msg = `9 is not found between 1 and 10 - the borders are compared as text` ).
  ENDMETHOD.

  METHOD given_lower_case_then_upper.
    DATA(plants) = VALUE ty_plants( ( sign = 'i' option = 'bt' low = '2000' high = '2999' ) ).

    DATA(conditions) = zcl_acu_range=>from_range( plants )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'BT' low = `2000` high = `2999` ) )
      msg = `Sign and option in lower case are not normalized to upper case` ).
  ENDMETHOD.

  METHOD given_high_no_interval_dropped.
    DATA(plants) = VALUE ty_plants( ( sign = 'I' option = 'EQ' low = '1000' high = '9999' ) ).

    DATA(conditions) = zcl_acu_range=>from_range( plants )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'EQ' low = `1000` ) )
      msg = `The high value of a condition that is no interval is not dropped` ).
  ENDMETHOD.

  METHOD given_including_ne_then_kept.
    DATA(plants) = VALUE ty_plants( ( sign = 'I' option = 'NE' low = '1000' ) ).

    DATA(range) = zcl_acu_range=>from_range( plants ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `2000` )
                                        exp = abap_true
                                        msg = `An including NE condition does not cover another value` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `1000` )
                                        exp = abap_false
                                        msg = `An including NE condition covers its own value` ).
  ENDMETHOD.

  METHOD when_extended_then_both_kept.
    DATA(plants) = VALUE ty_plants( ( sign = 'I' option = 'BT' low = '2000' high = '2999' ) ).

    DATA(range) = zcl_acu_range=>builder( )->from_range( plants )->not_equal( `2100` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `2500` )
                                        exp = abap_true
                                        msg = `The interval taken over from the ranges table is lost` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `2100` )
                                        exp = abap_false
                                        msg = `The exclusion added after the ranges table is lost` ).
  ENDMETHOD.

  METHOD given_list_when_facade_then_eq.
    DATA(plants) = VALUE string_table( ( `1000` ) ( `2000` ) ( `1000` ) ).

    DATA(conditions) = zcl_acu_range=>from_list( plants )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'EQ' low = `1000` )
                                            ( sign = 'I' option = 'EQ' low = `2000` ) )
      msg = `from_list( ) of the facade does not give one including EQ condition per distinct value` ).
  ENDMETHOD.

  METHOD given_sorted_list_then_taken.
    DATA plants TYPE SORTED TABLE OF ty_plant WITH UNIQUE KEY table_line.

    plants = VALUE #( ( '2000' ) ( '1000' ) ).

    DATA(conditions) = zcl_acu_range=>from_list( plants )->conditions( ).

    cl_abap_unit_assert=>assert_equals(
      act = conditions
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'EQ' low = `1000` )
                                            ( sign = 'I' option = 'EQ' low = `2000` ) )
      msg = `A sorted table of values is not accepted as a list` ).
  ENDMETHOD.

  METHOD given_bad_sign_then_raises.
    DATA(plants) = VALUE ty_plants( ( sign = 'I' option = 'EQ' low = '1000' )
                                    ( sign = 'X' option = 'EQ' low = '2000' ) ).

    TRY.
        zcl_acu_range=>from_range( plants ).

        cl_abap_unit_assert=>fail( `A row with the sign X was accepted` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `Row 2` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_bad_option_then_raises.
    DATA(plants) = VALUE ty_plants( ( sign = 'I' option = 'XX' low = '1000' ) ).

    TRY.
        zcl_acu_range=>from_range( plants ).

        cl_abap_unit_assert=>fail( `A row with the option XX was accepted` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `XX` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_wordy_sign_then_raises.
    DATA(rows) = VALUE ty_text_rows( ( sign = `INCLUDE` option = `EQ` low = `1000` ) ).

    TRY.
        zcl_acu_range=>from_range( rows ).

        cl_abap_unit_assert=>fail( `The sign INCLUDE was cut to I and accepted` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `INCLUDE` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_value_list_then_raises.
    DATA(plants) = VALUE string_table( ( `1000` ) ).

    TRY.
        zcl_acu_range=>from_range( plants ).

        cl_abap_unit_assert=>fail( `A list of values was accepted as a ranges table` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `not a ranges table` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_no_high_then_raises.
    DATA(rows) = VALUE ty_half_rows( ( sign = 'I' option = 'EQ' low = `1000` ) ).

    TRY.
        zcl_acu_range=>from_range( rows ).

        cl_abap_unit_assert=>fail( `A table without the component high was accepted as a ranges table` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `HIGH` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_deep_low_then_raises.
    DATA(rows) = VALUE ty_deep_rows( ( sign = 'I' option = 'EQ' ) ).

    TRY.
        zcl_acu_range=>from_range( rows ).

        cl_abap_unit_assert=>fail( `A table whose low component is a table was accepted as a ranges table` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `LOW` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_row_list_facade_raises.
    DATA(rows) = VALUE ty_half_rows( ( sign = 'I' option = 'EQ' low = `1000` ) ).

    TRY.
        zcl_acu_range=>from_list( rows ).

        cl_abap_unit_assert=>fail( `A table of structures was accepted as a list of values` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `list of values` ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_covers_text DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES ty_short TYPE c LENGTH 2.
    TYPES ty_long TYPE c LENGTH 10.

    METHODS given_empty_then_covers_all FOR TESTING RAISING cx_static_check.
    METHODS given_equal_then_only_that FOR TESTING RAISING cx_static_check.
    METHODS given_exclusion_then_it_wins FOR TESTING RAISING cx_static_check.
    METHODS given_exclusions_then_the_rest FOR TESTING RAISING cx_static_check.
    METHODS given_interval_then_borders_in FOR TESTING RAISING cx_static_check.
    METHODS given_not_between_then_outside FOR TESTING RAISING cx_static_check.
    METHODS given_pattern_then_any_case FOR TESTING RAISING cx_static_check.
    METHODS given_plus_then_one_character FOR TESTING RAISING cx_static_check.
    METHODS given_not_pattern_then_others FOR TESTING RAISING cx_static_check.
    METHODS given_borders_then_open_ended FOR TESTING RAISING cx_static_check.
    METHODS given_list_then_members_only FOR TESTING RAISING cx_static_check.
    METHODS given_not_in_then_all_others FOR TESTING RAISING cx_static_check.
    METHODS given_char_field_then_as_text FOR TESTING RAISING cx_static_check.
    METHODS given_short_field_then_no_cut FOR TESTING RAISING cx_static_check.
    METHODS given_flag_then_blank_matches FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_covers_text IMPLEMENTATION.

  METHOD given_empty_then_covers_all.
    DATA(range) = zcl_acu_range=>builder( )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `anything` )
                                        exp = abap_true
                                        msg = `A range without conditions does not cover a text` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( 42 )
                                        exp = abap_true
                                        msg = `A range without conditions does not cover a number` ).
  ENDMETHOD.

  METHOD given_equal_then_only_that.
    DATA(range) = zcl_acu_range=>builder( )->equal( `A` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `A` )
                                        exp = abap_true
                                        msg = `The included value is not covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `B` )
                                        exp = abap_false
                                        msg = `A value that was not included is covered` ).
  ENDMETHOD.

  METHOD given_exclusion_then_it_wins.
    DATA(range) = zcl_acu_range=>builder( )->between( low  = `A`
                                                      high = `C` )->not_equal( `B` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `A` )
                                        exp = abap_true
                                        msg = `A value of the interval that is not excluded is not covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `B` )
                                        exp = abap_false
                                        msg = `An excluded value is covered because an including condition holds it` ).
  ENDMETHOD.

  METHOD given_exclusions_then_the_rest.
    DATA(range) = zcl_acu_range=>builder( )->not_equal( `B` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `A` )
                                        exp = abap_true
                                        msg = `A range with exclusions only does not cover the other values` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `B` )
                                        exp = abap_false
                                        msg = `A range with exclusions only covers the excluded value` ).
  ENDMETHOD.

  METHOD given_interval_then_borders_in.
    DATA(range) = zcl_acu_range=>builder( )->between( low  = `B`
                                                      high = `D` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `B` )
                                        exp = abap_true
                                        msg = `The lower border of an interval is not covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `D` )
                                        exp = abap_true
                                        msg = `The upper border of an interval is not covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `A` )
                                        exp = abap_false
                                        msg = `A value below the interval is covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `E` )
                                        exp = abap_false
                                        msg = `A value above the interval is covered` ).
  ENDMETHOD.

  METHOD given_not_between_then_outside.
    DATA(range) = zcl_acu_range=>builder( )->not_between( low  = `B`
                                                          high = `D` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `C` )
                                        exp = abap_false
                                        msg = `A value inside an excluded interval is covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `E` )
                                        exp = abap_true
                                        msg = `A value outside an excluded interval is not covered` ).
  ENDMETHOD.

  METHOD given_pattern_then_any_case.
    DATA(range) = zcl_acu_range=>builder( )->pattern( `AB*` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `ABC` )
                                        exp = abap_true
                                        msg = `A text that matches the pattern is not covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `AB` )
                                        exp = abap_true
                                        msg = `* does not stand for no character at all` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `abc` )
                                        exp = abap_true
                                        msg = `The pattern is not matched without regard to upper and lower case` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `BAB` )
                                        exp = abap_false
                                        msg = `A text that does not match the pattern is covered` ).
  ENDMETHOD.

  METHOD given_plus_then_one_character.
    DATA(range) = zcl_acu_range=>builder( )->pattern( `A+C` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `ABC` )
                                        exp = abap_true
                                        msg = `+ does not stand for one character` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `AC` )
                                        exp = abap_false
                                        msg = `+ stands for no character` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `ABBC` )
                                        exp = abap_false
                                        msg = `+ stands for two characters` ).
  ENDMETHOD.

  METHOD given_not_pattern_then_others.
    DATA(range) = zcl_acu_range=>builder( )->not_pattern( `TMP*` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `TMP_1` )
                                        exp = abap_false
                                        msg = `A text that matches an excluded pattern is covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `FINAL` )
                                        exp = abap_true
                                        msg = `A text that does not match an excluded pattern is not covered` ).
  ENDMETHOD.

  METHOD given_borders_then_open_ended.
    DATA(above) = zcl_acu_range=>builder( )->greater_than( `M` )->build( ).
    DATA(at_least) = zcl_acu_range=>builder( )->greater_or_equal( `M` )->build( ).
    DATA(below) = zcl_acu_range=>builder( )->less_than( `M` )->build( ).
    DATA(at_most) = zcl_acu_range=>builder( )->less_or_equal( `M` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = above->covers( `N` )
                                        exp = abap_true
                                        msg = `greater_than( ) does not cover a value above the border` ).
    cl_abap_unit_assert=>assert_equals( act = above->covers( `M` )
                                        exp = abap_false
                                        msg = `greater_than( ) covers the border itself` ).
    cl_abap_unit_assert=>assert_equals( act = at_least->covers( `M` )
                                        exp = abap_true
                                        msg = `greater_or_equal( ) does not cover the border itself` ).
    cl_abap_unit_assert=>assert_equals( act = below->covers( `L` )
                                        exp = abap_true
                                        msg = `less_than( ) does not cover a value below the border` ).
    cl_abap_unit_assert=>assert_equals( act = below->covers( `M` )
                                        exp = abap_false
                                        msg = `less_than( ) covers the border itself` ).
    cl_abap_unit_assert=>assert_equals( act = at_most->covers( `M` )
                                        exp = abap_true
                                        msg = `less_or_equal( ) does not cover the border itself` ).
  ENDMETHOD.

  METHOD given_list_then_members_only.
    DATA(range) = zcl_acu_range=>from_list( VALUE string_table( ( `1000` ) ( `2000` ) ) ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `2000` )
                                        exp = abap_true
                                        msg = `A value of the list is not covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `3000` )
                                        exp = abap_false
                                        msg = `A value that is not in the list is covered` ).
  ENDMETHOD.

  METHOD given_not_in_then_all_others.
    DATA(range) = zcl_acu_range=>builder( )->not_in( VALUE string_table( ( `1000` ) ( `2000` ) ) )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `2000` )
                                        exp = abap_false
                                        msg = `A value of the excluded list is covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `3000` )
                                        exp = abap_true
                                        msg = `A value that is not in the excluded list is not covered` ).
  ENDMETHOD.

  METHOD given_char_field_then_as_text.
    DATA field TYPE ty_long VALUE 'AB'.

    DATA(range) = zcl_acu_range=>builder( )->equal( `AB` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( field )
                                        exp = abap_true
                                        msg = `The blanks that pad a character field keep it from being covered` ).
  ENDMETHOD.

  METHOD given_short_field_then_no_cut.
    DATA field TYPE ty_short VALUE 'AB'.

    DATA(range) = zcl_acu_range=>builder( )->equal( `ABCD` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( field )
                                        exp = abap_false
                                        msg = `A condition was cut to the length of the field before it was compared` ).
  ENDMETHOD.

  METHOD given_flag_then_blank_matches.
    DATA(range) = zcl_acu_range=>builder( )->equal( abap_false )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( abap_false )
                                        exp = abap_true
                                        msg = `A condition on the blank value does not cover a blank field` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( abap_true )
                                        exp = abap_false
                                        msg = `A condition on the blank value covers a filled field` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_covers_typed DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES ty_period TYPE n LENGTH 3.
    TYPES ty_price TYPE p LENGTH 7 DECIMALS 2.
    TYPES ty_key TYPE x LENGTH 4.
    TYPES:
      BEGIN OF ty_flat,
        plant TYPE c LENGTH 4,
        area  TYPE c LENGTH 2,
      END OF ty_flat.

    CONSTANTS morning TYPE utclong VALUE '2026-09-15 08:00:00.0000000'.
    CONSTANTS noon TYPE utclong VALUE '2026-09-15 12:00:00.0000000'.
    CONSTANTS evening TYPE utclong VALUE '2026-09-15 20:00:00.0000000'.

    METHODS given_integers_then_numeric FOR TESTING RAISING cx_static_check.
    METHODS given_negatives_then_numeric FOR TESTING RAISING cx_static_check.
    METHODS given_packed_then_exact FOR TESTING RAISING cx_static_check.
    METHODS given_finer_border_no_rounding FOR TESTING RAISING cx_static_check.
    METHODS given_decfloat_then_numeric FOR TESTING RAISING cx_static_check.
    METHODS given_numeric_text_then_number FOR TESTING RAISING cx_static_check.
    METHODS given_dates_then_calendar FOR TESTING RAISING cx_static_check.
    METHODS given_times_then_clock FOR TESTING RAISING cx_static_check.
    METHODS given_utclong_then_time_line FOR TESTING RAISING cx_static_check.
    METHODS given_bytes_then_equal_bytes FOR TESTING RAISING cx_static_check.
    METHODS given_two_kinds_then_both_work FOR TESTING RAISING cx_static_check.
    METHODS given_text_for_number_raises FOR TESTING RAISING cx_static_check.
    METHODS given_pattern_on_number_raises FOR TESTING RAISING cx_static_check.
    METHODS given_formatted_date_raises FOR TESTING RAISING cx_static_check.
    METHODS given_structure_then_raises FOR TESTING RAISING cx_static_check.
    METHODS given_failure_then_fails_again FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_covers_typed IMPLEMENTATION.

  METHOD given_integers_then_numeric.
    DATA(range) = zcl_acu_range=>builder( )->between( low  = `1`
                                                      high = `10` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( 9 )
                                        exp = abap_true
                                        msg = `9 is not found between 1 and 10 - the borders are compared as text` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( 10 )
                                        exp = abap_true
                                        msg = `The upper border of a numeric interval is not covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( 11 )
                                        exp = abap_false
                                        msg = `A number above the interval is covered` ).
  ENDMETHOD.

  METHOD given_negatives_then_numeric.
    DATA(range) = zcl_acu_range=>builder( )->between( low  = -10
                                                      high = -1 )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( -5 )
                                        exp = abap_true
                                        msg = `A negative number inside a negative interval is not covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( 0 )
                                        exp = abap_false
                                        msg = `Zero is covered by an interval of negative numbers` ).
  ENDMETHOD.

  METHOD given_packed_then_exact.
    DATA price TYPE ty_price VALUE '19.99'.

    DATA(range) = zcl_acu_range=>builder( )->equal( price )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( price )
                                        exp = abap_true
                                        msg = `A packed number is not covered by a condition on the same number` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( CONV ty_price( '19.98' ) )
                                        exp = abap_false
                                        msg = `A packed number one cent away is covered` ).
  ENDMETHOD.

  METHOD given_finer_border_no_rounding.
    DATA price TYPE ty_price VALUE '19.99'.

    DATA(above) = zcl_acu_range=>builder( )->greater_than( `19.985` )->build( ).
    DATA(exactly) = zcl_acu_range=>builder( )->equal( `19.985` )->build( ).

    cl_abap_unit_assert=>assert_equals( act = above->covers( price )
                                        exp = abap_true
                                        msg = `The border was rounded to the decimals of the value before comparing` ).
    cl_abap_unit_assert=>assert_equals( act = exactly->covers( price )
                                        exp = abap_false
                                        msg = `A condition with more decimals was rounded onto the value` ).
  ENDMETHOD.

  METHOD given_decfloat_then_numeric.
    DATA(range) = zcl_acu_range=>builder( )->less_or_equal( CONV decfloat34( '0.5' ) )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( CONV decfloat34( '0.25' ) )
                                        exp = abap_true
                                        msg = `A decimal floating point number below the border is not covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( CONV decfloat34( '0.75' ) )
                                        exp = abap_false
                                        msg = `A decimal floating point number above the border is covered` ).
  ENDMETHOD.

  METHOD given_numeric_text_then_number.
    DATA period TYPE ty_period VALUE '007'.

    DATA(range) = zcl_acu_range=>builder( )->equal( 7 )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( period )
                                        exp = abap_true
                                        msg = `Numeric text 007 is not covered by a condition on the number 7` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( CONV ty_period( '008' ) )
                                        exp = abap_false
                                        msg = `Numeric text 008 is covered by a condition on the number 7` ).
  ENDMETHOD.

  METHOD given_dates_then_calendar.
    DATA(range) = zcl_acu_range=>builder( )->between( low  = CONV d( '20260101' )
                                                      high = CONV d( '20260331' ) )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( CONV d( '20260215' ) )
                                        exp = abap_true
                                        msg = `A date inside the interval is not covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( CONV d( '20260401' ) )
                                        exp = abap_false
                                        msg = `A date after the interval is covered` ).
  ENDMETHOD.

  METHOD given_times_then_clock.
    DATA(range) = zcl_acu_range=>builder( )->greater_or_equal( CONV t( '180000' ) )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( CONV t( '193000' ) )
                                        exp = abap_true
                                        msg = `A time after the border is not covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( CONV t( '120000' ) )
                                        exp = abap_false
                                        msg = `A time before the border is covered` ).
  ENDMETHOD.

  METHOD given_utclong_then_time_line.
    DATA(range) = zcl_acu_range=>builder( )->between( low  = morning
                                                      high = noon )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( noon )
                                        exp = abap_true
                                        msg = `A UTC time stamp on the border of the interval is not covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( evening )
                                        exp = abap_false
                                        msg = `A UTC time stamp after the interval is covered` ).
  ENDMETHOD.

  METHOD given_bytes_then_equal_bytes.
    DATA key TYPE ty_key VALUE 'CAFE0001'.

    DATA(range) = zcl_acu_range=>builder( )->equal( key )->build( ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( key )
                                        exp = abap_true
                                        msg = `A byte field is not covered by a condition on the same bytes` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( CONV ty_key( 'CAFE0002' ) )
                                        exp = abap_false
                                        msg = `A byte field with other bytes is covered` ).
  ENDMETHOD.

  METHOD given_two_kinds_then_both_work.
    DATA price TYPE ty_price VALUE '7.00'.

    DATA(range) = zcl_acu_range=>from_list( VALUE string_table( ( `5` ) ( `7` ) ) ).

    cl_abap_unit_assert=>assert_equals( act = range->covers( `7` )
                                        exp = abap_true
                                        msg = `The text 7 is not covered` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( price )
                                        exp = abap_true
                                        msg = `The number 7.00 is not covered by the range that covers the text 7` ).
    cl_abap_unit_assert=>assert_equals( act = range->covers( `7.00` )
                                        exp = abap_false
                                        msg = `The text 7.00 is covered - a text was compared as a number` ).
  ENDMETHOD.

  METHOD given_text_for_number_raises.
    DATA(range) = zcl_acu_range=>builder( )->equal( `ABC` )->build( ).

    TRY.
        range->covers( 5 ).

        cl_abap_unit_assert=>fail( `A number was compared with the text ABC` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `ABC` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_pattern_on_number_raises.
    DATA(range) = zcl_acu_range=>builder( )->pattern( `1*` )->build( ).

    TRY.
        range->covers( 15 ).

        cl_abap_unit_assert=>fail( `A number was compared with a pattern` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `1*` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_formatted_date_raises.
    DATA(range) = zcl_acu_range=>builder( )->equal( `2026-01-15` )->build( ).

    TRY.
        range->covers( CONV d( '20260115' ) ).

        cl_abap_unit_assert=>fail( `A date was compared with a text that is no date in the form YYYYMMDD` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `2026-01-15` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_structure_then_raises.
    DATA(range) = zcl_acu_range=>builder( )->equal( `1000` )->build( ).

    TRY.
        range->covers( VALUE ty_flat( plant = '1000' ) ).

        cl_abap_unit_assert=>fail( `A structure was accepted as a value` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `type` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_failure_then_fails_again.
    DATA(range) = zcl_acu_range=>builder( )->equal( `ABC` )->build( ).

    DO 2 TIMES.
      TRY.
          range->covers( 5 ).

          cl_abap_unit_assert=>fail( `A number was compared with the text ABC` ).
        CATCH zcx_range INTO DATA(rejection).
          lth_rejection=>assert_names( rejection = rejection
                                       culprit   = `ABC` ).
      ENDTRY.
    ENDDO.

    cl_abap_unit_assert=>assert_equals( act = range->covers( `ABC` )
                                        exp = abap_true
                                        msg = `A failed comparison with a number broke the comparison with a text` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_write_to DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES ty_plant TYPE c LENGTH 4.
    TYPES ty_plants TYPE RANGE OF ty_plant.
    TYPES ty_period TYPE n LENGTH 3.
    TYPES ty_periods TYPE RANGE OF ty_period.
    TYPES ty_price TYPE p LENGTH 7 DECIMALS 2.
    TYPES ty_prices TYPE RANGE OF ty_price.
    TYPES ty_small TYPE p LENGTH 2 DECIMALS 0.
    TYPES ty_smalls TYPE RANGE OF ty_small.
    TYPES ty_quantities TYPE RANGE OF i.
    TYPES ty_dates TYPE RANGE OF d.
    TYPES ty_instants TYPE RANGE OF utclong.
    TYPES ty_code TYPE x LENGTH 2.
    TYPES ty_codes TYPE RANGE OF ty_code.
    TYPES ty_plant_row TYPE LINE OF ty_plants.
    TYPES ty_sorted_plants TYPE SORTED TABLE OF ty_plant_row WITH NON-UNIQUE KEY low.

    CONSTANTS noon TYPE utclong VALUE '2026-09-15 12:00:00.0000000'.

    METHODS given_char_range_then_typed FOR TESTING RAISING cx_static_check.
    METHODS given_numc_range_then_padded FOR TESTING RAISING cx_static_check.
    METHODS given_packed_range_then_number FOR TESTING RAISING cx_static_check.
    METHODS given_int_range_then_signed FOR TESTING RAISING cx_static_check.
    METHODS given_date_range_then_dates FOR TESTING RAISING cx_static_check.
    METHODS given_utclong_range_then_stamp FOR TESTING RAISING cx_static_check.
    METHODS given_byte_range_then_bytes FOR TESTING RAISING cx_static_check.
    METHODS given_text_range_then_as_is FOR TESTING RAISING cx_static_check.
    METHODS given_sorted_table_then_filled FOR TESTING RAISING cx_static_check.
    METHODS given_old_rows_then_replaced FOR TESTING RAISING cx_static_check.
    METHODS given_empty_range_then_cleared FOR TESTING RAISING cx_static_check.
    METHODS given_trailing_blanks_then_fit FOR TESTING RAISING cx_static_check.
    METHODS given_leading_zeros_then_fit FOR TESTING RAISING cx_static_check.
    METHODS when_written_then_in_agrees FOR TESTING RAISING cx_static_check.
    METHODS given_long_value_then_raises FOR TESTING.
    METHODS given_failure_then_untouched FOR TESTING.
    METHODS given_text_for_number_raises FOR TESTING.
    METHODS given_rounding_then_raises FOR TESTING.
    METHODS given_overflow_then_raises FOR TESTING.
    METHODS given_pattern_for_numc_raises FOR TESTING.
    METHODS given_letters_for_numc_raises FOR TESTING.
    METHODS given_short_date_then_raises FOR TESTING.
    METHODS given_bad_hex_then_raises FOR TESTING.
    METHODS given_unbound_ref_then_raises FOR TESTING.
    METHODS given_no_table_then_raises FOR TESTING.
    METHODS given_value_list_then_raises FOR TESTING.

ENDCLASS.


CLASS ltc_write_to IMPLEMENTATION.

  METHOD given_char_range_then_typed.
    DATA plants TYPE ty_plants.

    zcl_acu_range=>builder( )->equal( `1000`
                            )->between( low  = `2000`
                                        high = `2999`
                            )->not_pattern( `21*`
                            )->build( )->write_to( REF #( plants ) ).

    cl_abap_unit_assert=>assert_equals(
      act = plants
      exp = VALUE ty_plants( ( sign = 'I' option = 'EQ' low = '1000' )
                             ( sign = 'I' option = 'BT' low = '2000' high = '2999' )
                             ( sign = 'E' option = 'CP' low = '21*' ) )
      msg = `The conditions are not written to a character ranges table as they were added` ).
  ENDMETHOD.

  METHOD given_numc_range_then_padded.
    DATA periods TYPE ty_periods.

    zcl_acu_range=>builder( )->between( low  = 1
                                        high = 12 )->build( )->write_to( REF #( periods ) ).

    cl_abap_unit_assert=>assert_equals(
      act = periods
      exp = VALUE ty_periods( ( sign = 'I' option = 'BT' low = '001' high = '012' ) )
      msg = `Numbers are not padded with leading zeros for a numeric text column` ).
  ENDMETHOD.

  METHOD given_packed_range_then_number.
    DATA prices TYPE ty_prices.

    zcl_acu_range=>builder( )->greater_or_equal( `19.9` )->build( )->write_to( REF #( prices ) ).

    cl_abap_unit_assert=>assert_equals(
      act = prices
      exp = VALUE ty_prices( ( sign = 'I' option = 'GE' low = '19.90' ) )
      msg = `A number as text is not converted for a packed column` ).
  ENDMETHOD.

  METHOD given_int_range_then_signed.
    DATA quantities TYPE ty_quantities.

    zcl_acu_range=>builder( )->between( low  = -10
                                        high = 10 )->build( )->write_to( REF #( quantities ) ).

    cl_abap_unit_assert=>assert_equals(
      act = quantities
      exp = VALUE ty_quantities( ( sign = 'I' option = 'BT' low = -10 high = 10 ) )
      msg = `A negative number does not arrive in an integer column with its sign` ).
  ENDMETHOD.

  METHOD given_date_range_then_dates.
    DATA dates TYPE ty_dates.

    zcl_acu_range=>builder( )->less_than( CONV d( '20260401' ) )->build( )->write_to( REF #( dates ) ).

    cl_abap_unit_assert=>assert_equals(
      act = dates
      exp = VALUE ty_dates( ( sign = 'I' option = 'LT' low = '20260401' ) )
      msg = `A date does not arrive in a date column, or the unused high column is not initial` ).
  ENDMETHOD.

  METHOD given_utclong_range_then_stamp.
    DATA instants TYPE ty_instants.

    zcl_acu_range=>builder( )->greater_than( noon )->build( )->write_to( REF #( instants ) ).

    cl_abap_unit_assert=>assert_equals(
      act = instants
      exp = VALUE ty_instants( ( sign = 'I' option = 'GT' low = noon ) )
      msg = `A UTC time stamp does not arrive in a utclong column` ).
  ENDMETHOD.

  METHOD given_byte_range_then_bytes.
    DATA codes TYPE ty_codes.

    zcl_acu_range=>builder( )->equal( CONV ty_code( 'CAFE' )
                            )->equal( `00ff`
                            )->build( )->write_to( REF #( codes ) ).

    cl_abap_unit_assert=>assert_equals(
      act = codes
      exp = VALUE ty_codes( ( sign = 'I' option = 'EQ' low = 'CAFE' )
                            ( sign = 'I' option = 'EQ' low = '00FF' ) )
      msg = `Bytes do not arrive in a byte column, from a byte field or from hexadecimal text in lower case` ).
  ENDMETHOD.

  METHOD given_text_range_then_as_is.
    DATA filter TYPE zif_range=>ty_conditions.

    zcl_acu_range=>builder( )->pattern( `*a text no fixed field would hold*` )->build( )->write_to( REF #( filter ) ).

    cl_abap_unit_assert=>assert_equals(
      act = filter
      exp = VALUE zif_range=>ty_conditions( ( sign = 'I' option = 'CP' low = `*a text no fixed field would hold*` ) )
      msg = `A ranges table with string columns does not take the conditions as they are` ).
  ENDMETHOD.

  METHOD given_sorted_table_then_filled.
    DATA plants TYPE ty_sorted_plants.

    zcl_acu_range=>from_list( VALUE string_table( ( `2000` ) ( `1000` ) ) )->write_to( REF #( plants ) ).

    cl_abap_unit_assert=>assert_equals(
      act = plants
      exp = VALUE ty_sorted_plants( ( sign = 'I' option = 'EQ' low = '1000' )
                                    ( sign = 'I' option = 'EQ' low = '2000' ) )
      msg = `A sorted ranges table is not filled in the order of its key` ).
  ENDMETHOD.

  METHOD given_old_rows_then_replaced.
    DATA(plants) = VALUE ty_plants( ( sign = 'I' option = 'EQ' low = '9999' ) ).

    zcl_acu_range=>builder( )->equal( `1000` )->build( )->write_to( REF #( plants ) ).

    cl_abap_unit_assert=>assert_equals(
      act = plants
      exp = VALUE ty_plants( ( sign = 'I' option = 'EQ' low = '1000' ) )
      msg = `The previous content of the ranges table is not replaced` ).
  ENDMETHOD.

  METHOD given_empty_range_then_cleared.
    DATA(plants) = VALUE ty_plants( ( sign = 'I' option = 'EQ' low = '9999' ) ).

    zcl_acu_range=>builder( )->build( )->write_to( REF #( plants ) ).

    cl_abap_unit_assert=>assert_initial( act = plants
                                         msg = `A range without conditions does not leave the ranges table empty` ).
  ENDMETHOD.

  METHOD given_trailing_blanks_then_fit.
    DATA plants TYPE ty_plants.

    zcl_acu_range=>builder( )->equal( `1000  ` )->build( )->write_to( REF #( plants ) ).

    cl_abap_unit_assert=>assert_equals(
      act = plants
      exp = VALUE ty_plants( ( sign = 'I' option = 'EQ' low = '1000' ) )
      msg = `Blanks at the end of a value count against the length of a character column` ).
  ENDMETHOD.

  METHOD given_leading_zeros_then_fit.
    DATA periods TYPE ty_periods.

    zcl_acu_range=>builder( )->equal( `0000007` )->build( )->write_to( REF #( periods ) ).

    cl_abap_unit_assert=>assert_equals(
      act = periods
      exp = VALUE ty_periods( ( sign = 'I' option = 'EQ' low = '007' ) )
      msg = `Leading zeros count against the length of a numeric text column` ).
  ENDMETHOD.

  METHOD when_written_then_in_agrees.
    DATA plants TYPE ty_plants.
    DATA plant TYPE ty_plant VALUE '2100'.

    DATA(range) = zcl_acu_range=>builder( )->between( low  = `2000`
                                                      high = `2999`
                                      )->not_pattern( `21*`
                                      )->build( ).

    range->write_to( REF #( plants ) ).

    cl_abap_unit_assert=>assert_equals( act = xsdbool( plant IN plants )
                                        exp = range->covers( plant )
                                        msg = `covers( ) and IN on the written table disagree on an excluded value` ).
    plant = '2200'.
    cl_abap_unit_assert=>assert_equals( act = xsdbool( plant IN plants )
                                        exp = range->covers( plant )
                                        msg = `covers( ) and IN on the written table disagree on an included value` ).
  ENDMETHOD.

  METHOD given_long_value_then_raises.
    DATA plants TYPE ty_plants.

    TRY.
        zcl_acu_range=>builder( )->equal( `10000` )->build( )->write_to( REF #( plants ) ).

        cl_abap_unit_assert=>fail( `A value of five characters was cut to a column of four` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `10000` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_failure_then_untouched.
    DATA(plants) = VALUE ty_plants( ( sign = 'I' option = 'EQ' low = '9999' ) ).

    TRY.
        zcl_acu_range=>builder( )->equal( `1000`
                                )->equal( `10000`
                                )->build( )->write_to( REF #( plants ) ).

        cl_abap_unit_assert=>fail( `A value of five characters was cut to a column of four` ).
      CATCH zcx_range.
        cl_abap_unit_assert=>assert_equals(
          act = plants
          exp = VALUE ty_plants( ( sign = 'I' option = 'EQ' low = '9999' ) )
          msg = `The ranges table was changed although the range could not be written` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_text_for_number_raises.
    DATA prices TYPE ty_prices.

    TRY.
        zcl_acu_range=>builder( )->equal( `cheap` )->build( )->write_to( REF #( prices ) ).

        cl_abap_unit_assert=>fail( `A text was written to a packed column` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `cheap` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_rounding_then_raises.
    DATA prices TYPE ty_prices.

    TRY.
        zcl_acu_range=>builder( )->equal( `19.985` )->build( )->write_to( REF #( prices ) ).

        cl_abap_unit_assert=>fail( `A number with three decimals was rounded into a column with two` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `19.985` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_overflow_then_raises.
    DATA smalls TYPE ty_smalls.

    TRY.
        zcl_acu_range=>builder( )->equal( 1000 )->build( )->write_to( REF #( smalls ) ).

        cl_abap_unit_assert=>fail( `A number of four digits was written to a packed column of three` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `1000` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_pattern_for_numc_raises.
    DATA periods TYPE ty_periods.

    TRY.
        zcl_acu_range=>builder( )->pattern( `01*` )->build( )->write_to( REF #( periods ) ).

        cl_abap_unit_assert=>fail( `A pattern was written to a numeric text column` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `01*` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_letters_for_numc_raises.
    DATA periods TYPE ty_periods.

    TRY.
        zcl_acu_range=>builder( )->equal( `A1` )->build( )->write_to( REF #( periods ) ).

        cl_abap_unit_assert=>fail( `Letters were written to a numeric text column` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `A1` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_short_date_then_raises.
    DATA dates TYPE ty_dates.

    TRY.
        zcl_acu_range=>builder( )->equal( `2026` )->build( )->write_to( REF #( dates ) ).

        cl_abap_unit_assert=>fail( `A year alone was written to a date column` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `2026` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_bad_hex_then_raises.
    DATA codes TYPE ty_codes.

    TRY.
        zcl_acu_range=>builder( )->equal( `CAFEBABE` )->build( )->write_to( REF #( codes ) ).

        cl_abap_unit_assert=>fail( `Four bytes were cut to a byte column of two` ).
      CATCH zcx_range INTO DATA(too_long).
        lth_rejection=>assert_names( rejection = too_long
                                     culprit   = `CAFEBABE` ).
    ENDTRY.

    TRY.
        zcl_acu_range=>builder( )->equal( `XYZ1` )->build( )->write_to( REF #( codes ) ).

        cl_abap_unit_assert=>fail( `A text that is not hexadecimal was written to a byte column` ).
      CATCH zcx_range INTO DATA(no_hex).
        lth_rejection=>assert_names( rejection = no_hex
                                     culprit   = `XYZ1` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_unbound_ref_then_raises.
    DATA nowhere TYPE REF TO data.

    TRY.
        zcl_acu_range=>builder( )->equal( `1000` )->build( )->write_to( nowhere ).

        cl_abap_unit_assert=>fail( `A reference that points to nothing was accepted` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `reference` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_no_table_then_raises.
    DATA plant TYPE ty_plant.

    TRY.
        zcl_acu_range=>builder( )->equal( `1000` )->build( )->write_to( REF #( plant ) ).

        cl_abap_unit_assert=>fail( `A field was accepted as a ranges table` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `not a table` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_value_list_then_raises.
    DATA plants TYPE string_table.

    TRY.
        zcl_acu_range=>builder( )->equal( `1000` )->build( )->write_to( REF #( plants ) ).

        cl_abap_unit_assert=>fail( `A list of values was accepted as a ranges table` ).
      CATCH zcx_range INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `not a ranges table` ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
