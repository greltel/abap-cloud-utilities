*"* use this source file for your ABAP unit test classes
"! Stands in for the currency master data with a fixed set of currencies:
"! EUR and USD with two decimals, JPY with none, KWD with three.
CLASS ltd_currencies DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    INTERFACES lif_currencies.

    METHODS constructor.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF known_currency,
        currency TYPE currency_key,
        decimals TYPE i,
      END OF known_currency.
    TYPES known_currencies TYPE HASHED TABLE OF known_currency WITH UNIQUE KEY currency.

    DATA known TYPE known_currencies.

ENDCLASS.


CLASS ltd_currencies IMPLEMENTATION.

  METHOD constructor.
    known = VALUE #( ( currency = 'EUR' decimals = 2 )
                     ( currency = 'USD' decimals = 2 )
                     ( currency = 'JPY' decimals = 0 )
                     ( currency = 'KWD' decimals = 3 ) ).
  ENDMETHOD.

  METHOD lif_currencies~decimals_of.
    IF NOT line_exists( known[ currency = currency ] ).
      RAISE EXCEPTION NEW zcx_amount( |Currency { currency } is unknown| ).
    ENDIF.

    result = known[ currency = currency ]-decimals.
  ENDMETHOD.

ENDCLASS.


"! Stands in for the exchange rate service. Records the request it receives
"! and answers with the amount a test configured, or refuses on demand.
CLASS ltd_rates DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    INTERFACES lif_rates.

    METHODS answering_with
      IMPORTING amount      TYPE api_amount
      RETURNING VALUE(self) TYPE REF TO ltd_rates.

    METHODS refusing
      RETURNING VALUE(self) TYPE REF TO ltd_rates.

    METHODS recorded
      RETURNING VALUE(result) TYPE conversion.

    METHODS calls
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    DATA answer TYPE api_amount.
    DATA refuses TYPE abap_bool.
    DATA request TYPE conversion.
    DATA call_count TYPE i.

ENDCLASS.


CLASS ltd_rates IMPLEMENTATION.

  METHOD answering_with.
    answer = amount.

    self = me.
  ENDMETHOD.

  METHOD refusing.
    refuses = abap_true.

    self = me.
  ENDMETHOD.

  METHOD recorded.
    result = request.
  ENDMETHOD.

  METHOD calls.
    result = call_count.
  ENDMETHOD.

  METHOD lif_rates~convert.
    request = conversion.
    call_count = call_count + 1.

    IF refuses = abap_true.
      RAISE EXCEPTION NEW cx_exchange_rates( ).
    ENDIF.

    result = answer.
  ENDMETHOD.

ENDCLASS.


"! Builds amounts on the test doubles, the way the facade builds them on the
"! real collaborators.
CLASS lth_amounts DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    CLASS-METHODS of
      IMPORTING value         TYPE simple
                currency      TYPE currency_key
                rates         TYPE REF TO lif_rates OPTIONAL
      RETURNING VALUE(result) TYPE REF TO zif_amount
      RAISING   zcx_amount.

ENDCLASS.


CLASS lth_amounts IMPLEMENTATION.

  METHOD of.
    DATA(currencies) = NEW ltd_currencies( ).

    result = NEW lcl_amount( money      = VALUE #( value    = CONV decfloat34( value )
                                                   currency = currency
                                                   decimals = currencies->lif_currencies~decimals_of( currency ) )
                             currencies = currencies
                             rates      = COND #( WHEN rates IS BOUND
                                                  THEN rates
                                                  ELSE NEW ltd_rates( ) ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_currency_keys DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_plain_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_lower_padded_then_normal FOR TESTING RAISING cx_static_check.
    METHODS given_max_length_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_empty_then_raises FOR TESTING.
    METHODS given_blanks_then_raises FOR TESTING.
    METHODS given_too_long_then_raises FOR TESTING.

    METHODS assert_rejected
      IMPORTING value TYPE string.

ENDCLASS.


CLASS ltc_currency_keys IMPLEMENTATION.

  METHOD given_plain_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_currency_key=>of( `EUR` )
      exp = 'EUR'
      msg = `A plain currency key is changed` ).
  ENDMETHOD.

  METHOD given_lower_padded_then_normal.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_currency_key=>of( `  eur ` )
      exp = 'EUR'
      msg = `A padded lower case currency key is not normalised` ).
  ENDMETHOD.

  METHOD given_max_length_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_currency_key=>of( `ABCDE` )
      exp = 'ABCDE'
      msg = `A currency key of exactly 5 characters is rejected` ).
  ENDMETHOD.

  METHOD given_empty_then_raises.
    assert_rejected( `` ).
  ENDMETHOD.

  METHOD given_blanks_then_raises.
    assert_rejected( `   ` ).
  ENDMETHOD.

  METHOD given_too_long_then_raises.
    assert_rejected( `EUROPE` ).
  ENDMETHOD.

  METHOD assert_rejected.
    TRY.
        lcl_currency_key=>of( value ).

        cl_abap_unit_assert=>fail( |Currency key '{ value }' was unexpectedly accepted| ).
      CATCH zcx_amount INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = `The rejection does not explain itself` ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_numbers DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_text_then_number FOR TESTING RAISING cx_static_check.
    METHODS given_packed_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_integer_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_garbage_then_raises FOR TESTING.

ENDCLASS.


CLASS ltc_numbers IMPLEMENTATION.

  METHOD given_text_then_number.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_number=>of( `1234.57` )
      exp = CONV decfloat34( '1234.57' )
      msg = `A number given as text is not read` ).
  ENDMETHOD.

  METHOD given_packed_then_kept.
    DATA packed TYPE p LENGTH 8 DECIMALS 3 VALUE '-0.125'.

    cl_abap_unit_assert=>assert_equals(
      act = lcl_number=>of( packed )
      exp = CONV decfloat34( '-0.125' )
      msg = `A packed number loses its value` ).
  ENDMETHOD.

  METHOD given_integer_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_number=>of( 1000 )
      exp = CONV decfloat34( 1000 )
      msg = `An integer loses its value` ).
  ENDMETHOD.

  METHOD given_garbage_then_raises.
    TRY.
        lcl_number=>of( `12,50 EUR` ).

        cl_abap_unit_assert=>fail( `A text that is not a number was unexpectedly accepted` ).
      CATCH zcx_amount INTO DATA(rejection).
        cl_abap_unit_assert=>assert_bound( act = rejection->previous
                                           msg = `The conversion error is not kept as previous` ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_scale DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_2_decimals_then_same FOR TESTING.
    METHODS given_0_decimals_then_shrunk FOR TESTING.
    METHODS given_3_decimals_then_grown FOR TESTING.
    METHODS given_internal_0_then_grown FOR TESTING.
    METHODS given_internal_3_then_shrunk FOR TESTING.
    METHODS given_round_trip_then_same FOR TESTING.

ENDCLASS.


CLASS ltc_scale IMPLEMENTATION.

  METHOD given_2_decimals_then_same.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_scale=>to_internal( value    = CONV decfloat34( '1234.56' )
                                    decimals = 2 )
      exp = CONV decfloat34( '1234.56' )
      msg = `A two-decimal currency is shifted` ).
  ENDMETHOD.

  METHOD given_0_decimals_then_shrunk.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_scale=>to_internal( value    = CONV decfloat34( 1000 )
                                    decimals = 0 )
      exp = CONV decfloat34( 10 )
      msg = `JPY 1000 is not stored as 10.00` ).
  ENDMETHOD.

  METHOD given_3_decimals_then_grown.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_scale=>to_internal( value    = CONV decfloat34( '1.234' )
                                    decimals = 3 )
      exp = CONV decfloat34( '12.34' )
      msg = `KWD 1.234 is not stored as 12.34` ).
  ENDMETHOD.

  METHOD given_internal_0_then_grown.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_scale=>to_external( value    = CONV decfloat34( 10 )
                                    decimals = 0 )
      exp = CONV decfloat34( 1000 )
      msg = `A stored 10.00 JPY is not read as 1000` ).
  ENDMETHOD.

  METHOD given_internal_3_then_shrunk.
    cl_abap_unit_assert=>assert_equals(
      act = lcl_scale=>to_external( value    = CONV decfloat34( '12.34' )
                                    decimals = 3 )
      exp = CONV decfloat34( '1.234' )
      msg = `A stored 12.34 KWD is not read as 1.234` ).
  ENDMETHOD.

  METHOD given_round_trip_then_same.
    DATA(internal) = lcl_scale=>to_internal( value    = CONV decfloat34( '9876.54321' )
                                             decimals = 5 ).

    cl_abap_unit_assert=>assert_equals(
      act = lcl_scale=>to_external( value    = internal
                                    decimals = 5 )
      exp = CONV decfloat34( '9876.54321' )
      msg = `Shifting to the database representation and back changes the value` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_values DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_eur_then_2_decimals FOR TESTING RAISING cx_static_check.
    METHODS given_key_then_string FOR TESTING RAISING cx_static_check.
    METHODS given_jpy_then_internal_shift FOR TESTING RAISING cx_static_check.
    METHODS given_kwd_then_internal_shift FOR TESTING RAISING cx_static_check.
    METHODS given_half_then_away_from_0 FOR TESTING RAISING cx_static_check.
    METHODS given_neg_half_then_away FOR TESTING RAISING cx_static_check.
    METHODS given_half_even_then_banker FOR TESTING RAISING cx_static_check.
    METHODS given_jpy_then_rounds_to_unit FOR TESTING RAISING cx_static_check.
    METHODS given_round_then_orig_kept FOR TESTING RAISING cx_static_check.
    METHODS given_3_decimals_not_rounded FOR TESTING RAISING cx_static_check.
    METHODS given_2_decimals_is_rounded FOR TESTING RAISING cx_static_check.
    METHODS given_add_then_sum FOR TESTING RAISING cx_static_check.
    METHODS given_subtract_then_diff FOR TESTING RAISING cx_static_check.
    METHODS given_add_other_curr_raises FOR TESTING RAISING cx_static_check.
    METHODS given_multiply_then_unrounded FOR TESTING RAISING cx_static_check.
    METHODS given_multiply_text_then_prod FOR TESTING RAISING cx_static_check.
    METHODS given_negate_then_sign_flips FOR TESTING RAISING cx_static_check.
    METHODS given_zero_then_is_zero FOR TESTING RAISING cx_static_check.
    METHODS given_negative_then_flagged FOR TESTING RAISING cx_static_check.
    METHODS given_same_value_then_equal FOR TESTING RAISING cx_static_check.
    METHODS given_other_curr_then_unequal FOR TESTING RAISING cx_static_check.
    METHODS given_eur_then_raw_text FOR TESTING RAISING cx_static_check.
    METHODS given_jpy_then_raw_text FOR TESTING RAISING cx_static_check.
    METHODS given_kwd_then_raw_text FOR TESTING RAISING cx_static_check.
    METHODS given_text_then_curr_appended FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_values IMPLEMENTATION.

  METHOD given_eur_then_2_decimals.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = 1
                             currency = 'EUR' )->decimals( )
      exp = 2
      msg = `EUR does not have two decimals` ).
  ENDMETHOD.

  METHOD given_key_then_string.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = 1
                             currency = 'EUR' )->currency( )
      exp = `EUR`
      msg = `The currency key is not returned as plain text` ).
  ENDMETHOD.

  METHOD given_jpy_then_internal_shift.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = 1000
                             currency = 'JPY' )->as_internal( )
      exp = CONV decfloat34( 10 )
      msg = `JPY 1000 is not 10.00 in the database representation` ).
  ENDMETHOD.

  METHOD given_kwd_then_internal_shift.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = `1.234`
                             currency = 'KWD' )->as_internal( )
      exp = CONV decfloat34( '12.34' )
      msg = `KWD 1.234 is not 12.34 in the database representation` ).
  ENDMETHOD.

  METHOD given_half_then_away_from_0.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = `2.345`
                             currency = 'EUR' )->round( )->as_decimal( )
      exp = CONV decfloat34( '2.35' )
      msg = `Commercial rounding does not round a half up` ).
  ENDMETHOD.

  METHOD given_neg_half_then_away.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = `-2.345`
                             currency = 'EUR' )->round( )->as_decimal( )
      exp = CONV decfloat34( '-2.35' )
      msg = `Commercial rounding does not round a negative half away from zero` ).
  ENDMETHOD.

  METHOD given_half_even_then_banker.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = `2.345`
                             currency = 'EUR' )->round( cl_abap_math=>round_half_even )->as_decimal( )
      exp = CONV decfloat34( '2.34' )
      msg = `Banker's rounding does not round a half to the even neighbour` ).
  ENDMETHOD.

  METHOD given_jpy_then_rounds_to_unit.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = `1234.5`
                             currency = 'JPY' )->round( )->as_decimal( )
      exp = CONV decfloat34( 1235 )
      msg = `A JPY amount is not rounded to whole units` ).
  ENDMETHOD.

  METHOD given_round_then_orig_kept.
    DATA(original) = lth_amounts=>of( value    = `2.345`
                                      currency = 'EUR' ).

    original->round( ).

    cl_abap_unit_assert=>assert_equals(
      act = original->as_decimal( )
      exp = CONV decfloat34( '2.345' )
      msg = `Rounding changes the original amount` ).
  ENDMETHOD.

  METHOD given_3_decimals_not_rounded.
    cl_abap_unit_assert=>assert_false(
      act = lth_amounts=>of( value    = `2.345`
                             currency = 'EUR' )->is_rounded( )
      msg = `An amount with more decimals than its currency counts as rounded` ).
  ENDMETHOD.

  METHOD given_2_decimals_is_rounded.
    cl_abap_unit_assert=>assert_true(
      act = lth_amounts=>of( value    = `2.30`
                             currency = 'EUR' )->is_rounded( )
      msg = `An amount with the decimals of its currency does not count as rounded` ).
  ENDMETHOD.

  METHOD given_add_then_sum.
    DATA(first) = lth_amounts=>of( value    = `1.10`
                                   currency = 'EUR' ).
    DATA(second) = lth_amounts=>of( value    = `2.20`
                                    currency = 'EUR' ).

    cl_abap_unit_assert=>assert_equals(
      act = first->add( second )->as_decimal( )
      exp = CONV decfloat34( '3.30' )
      msg = `Two amounts are not added` ).
  ENDMETHOD.

  METHOD given_subtract_then_diff.
    DATA(first) = lth_amounts=>of( value    = `1.10`
                                   currency = 'EUR' ).
    DATA(second) = lth_amounts=>of( value    = `2.20`
                                    currency = 'EUR' ).

    cl_abap_unit_assert=>assert_equals(
      act = first->subtract( second )->as_decimal( )
      exp = CONV decfloat34( '-1.10' )
      msg = `Two amounts are not subtracted` ).
  ENDMETHOD.

  METHOD given_add_other_curr_raises.
    DATA(euros) = lth_amounts=>of( value    = 1
                                   currency = 'EUR' ).
    DATA(dollars) = lth_amounts=>of( value    = 1
                                     currency = 'USD' ).

    TRY.
        euros->add( dollars ).

        cl_abap_unit_assert=>fail( `Adding amounts of different currencies was unexpectedly accepted` ).
      CATCH zcx_amount INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = `The rejection does not explain itself` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_multiply_then_unrounded.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = `19.99`
                             currency = 'EUR' )->multiply_by( 3 )->as_decimal( )
      exp = CONV decfloat34( '59.97' )
      msg = `An amount is not multiplied by a quantity` ).
  ENDMETHOD.

  METHOD given_multiply_text_then_prod.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = `10.05`
                             currency = 'EUR' )->multiply_by( `0.19` )->as_decimal( )
      exp = CONV decfloat34( '1.9095' )
      msg = `A tax rate given as text is not applied, or the product is rounded` ).
  ENDMETHOD.

  METHOD given_negate_then_sign_flips.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = `1.5`
                             currency = 'EUR' )->negate( )->as_decimal( )
      exp = CONV decfloat34( '-1.5' )
      msg = `The sign is not reversed` ).
  ENDMETHOD.

  METHOD given_zero_then_is_zero.
    cl_abap_unit_assert=>assert_true(
      act = lth_amounts=>of( value    = 0
                             currency = 'EUR' )->is_zero( )
      msg = `A zero amount is not recognised` ).
  ENDMETHOD.

  METHOD given_negative_then_flagged.
    cl_abap_unit_assert=>assert_true(
      act = lth_amounts=>of( value    = `-0.01`
                             currency = 'EUR' )->is_negative( )
      msg = `A negative amount is not recognised` ).
  ENDMETHOD.

  METHOD given_same_value_then_equal.
    DATA(short_form) = lth_amounts=>of( value    = `1.5`
                                        currency = 'EUR' ).
    DATA(long_form) = lth_amounts=>of( value    = `1.50`
                                       currency = 'EUR' ).

    cl_abap_unit_assert=>assert_true(
      act = short_form->equals( long_form )
      msg = `1.5 and 1.50 of the same currency are not equal` ).
  ENDMETHOD.

  METHOD given_other_curr_then_unequal.
    DATA(euro) = lth_amounts=>of( value    = 1
                                  currency = 'EUR' ).
    DATA(dollar) = lth_amounts=>of( value    = 1
                                    currency = 'USD' ).

    cl_abap_unit_assert=>assert_false(
      act = euro->equals( dollar )
      msg = `Equal values of different currencies are treated as equal` ).
  ENDMETHOD.

  METHOD given_eur_then_raw_text.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = `-1234.5`
                             currency = 'EUR' )->as_raw_text( )
      exp = `-1234.50`
      msg = `The technical text is not sign, decimal point and two decimals` ).
  ENDMETHOD.

  METHOD given_jpy_then_raw_text.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = `1234.5`
                             currency = 'JPY' )->as_raw_text( )
      exp = `1235`
      msg = `The technical text of a JPY amount is not rounded to whole units` ).
  ENDMETHOD.

  METHOD given_kwd_then_raw_text.
    cl_abap_unit_assert=>assert_equals(
      act = lth_amounts=>of( value    = `1.2`
                             currency = 'KWD' )->as_raw_text( )
      exp = `1.200`
      msg = `The technical text of a KWD amount does not show three decimals` ).
  ENDMETHOD.

  METHOD given_text_then_curr_appended.
    DATA(amount) = lth_amounts=>of( value    = `1234.5`
                                    currency = 'EUR' ).

    cl_abap_unit_assert=>assert_equals(
      act = amount->as_text_with_currency( )
      exp = |{ amount->as_text( ) } EUR|
      msg = `The currency is not appended to the user text` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_conversion DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS rate_date TYPE d VALUE '20260911'.

    DATA rates TYPE REF TO ltd_rates.

    METHODS setup.
    METHODS teardown.

    METHODS given_own_currency_then_self FOR TESTING RAISING cx_static_check.
    METHODS given_jpy_then_internal_sent FOR TESTING RAISING cx_static_check.
    METHODS given_unrounded_then_rounded FOR TESTING RAISING cx_static_check.
    METHODS given_request_then_all_passed FOR TESTING RAISING cx_static_check.
    METHODS given_lower_target_then_upper FOR TESTING RAISING cx_static_check.
    METHODS given_eur_answer_then_external FOR TESTING RAISING cx_static_check.
    METHODS given_jpy_answer_then_external FOR TESTING RAISING cx_static_check.
    METHODS given_kwd_answer_then_external FOR TESTING RAISING cx_static_check.
    METHODS given_unknown_target_raises FOR TESTING RAISING cx_static_check.
    METHODS given_no_date_then_raises FOR TESTING RAISING cx_static_check.
    METHODS given_no_rate_type_then_raises FOR TESTING RAISING cx_static_check.
    METHODS given_refusal_then_wrapped FOR TESTING RAISING cx_static_check.
    METHODS given_huge_amount_then_raises FOR TESTING RAISING cx_static_check.

    METHODS euros
      IMPORTING value         TYPE simple
      RETURNING VALUE(result) TYPE REF TO zif_amount
      RAISING   zcx_amount.

ENDCLASS.


CLASS ltc_conversion IMPLEMENTATION.

  METHOD setup.
    rates = NEW ltd_rates( ).
  ENDMETHOD.

  METHOD teardown.
    CLEAR rates.
  ENDMETHOD.

  METHOD euros.
    result = lth_amounts=>of( value    = value
                              currency = 'EUR'
                              rates    = rates ).
  ENDMETHOD.

  METHOD given_own_currency_then_self.
    DATA(amount) = euros( `1.005` ).

    DATA(converted) = amount->convert_to( currency = `eur`
                                          date     = rate_date ).

    cl_abap_unit_assert=>assert_equals(
      act = converted
      exp = amount
      msg = `Converting into the own currency does not return the amount itself` ).
    cl_abap_unit_assert=>assert_equals(
      act = rates->calls( )
      exp = 0
      msg = `Converting into the own currency calls the exchange rate service` ).
  ENDMETHOD.

  METHOD given_jpy_then_internal_sent.
    lth_amounts=>of( value    = 1000
                     currency = 'JPY'
                     rates    = rates )->convert_to( currency = `EUR`
                                                     date     = rate_date ).

    cl_abap_unit_assert=>assert_equals(
      act = rates->recorded( )-amount
      exp = CONV api_amount( 10 )
      msg = `JPY 1000 does not reach the service as 10.00` ).
  ENDMETHOD.

  METHOD given_unrounded_then_rounded.
    euros( `10.005` )->convert_to( currency = `USD`
                                   date     = rate_date ).

    cl_abap_unit_assert=>assert_equals(
      act = rates->recorded( )-amount
      exp = CONV api_amount( '10.01' )
      msg = `The amount is not rounded to its currency before conversion` ).
  ENDMETHOD.

  METHOD given_request_then_all_passed.
    euros( 100 )->convert_to( currency  = `USD`
                              date      = rate_date
                              rate_type = zif_amount=>rate_type-bank_selling ).

    DATA(request) = rates->recorded( ).

    cl_abap_unit_assert=>assert_equals(
      act = request-currency
      exp = 'EUR'
      msg = `The source currency does not reach the service` ).
    cl_abap_unit_assert=>assert_equals(
      act = request-target
      exp = 'USD'
      msg = `The target currency does not reach the service` ).
    cl_abap_unit_assert=>assert_equals(
      act = request-date
      exp = rate_date
      msg = `The date does not reach the service` ).
    cl_abap_unit_assert=>assert_equals(
      act = request-rate_type
      exp = zif_amount=>rate_type-bank_selling
      msg = `The rate type does not reach the service` ).
  ENDMETHOD.

  METHOD given_lower_target_then_upper.
    DATA(converted) = euros( 100 )->convert_to( currency = ` usd `
                                                date     = rate_date ).

    cl_abap_unit_assert=>assert_equals(
      act = converted->currency( )
      exp = `USD`
      msg = `The target currency is not normalised` ).
  ENDMETHOD.

  METHOD given_eur_answer_then_external.
    rates->answering_with( CONV api_amount( '108.50' ) ).

    DATA(converted) = euros( 100 )->convert_to( currency = `USD`
                                                date     = rate_date ).

    cl_abap_unit_assert=>assert_equals(
      act = converted->as_decimal( )
      exp = CONV decfloat34( '108.50' )
      msg = `A two-decimal answer is not taken over as it is` ).
  ENDMETHOD.

  METHOD given_jpy_answer_then_external.
    rates->answering_with( CONV api_amount( '1625.00' ) ).

    DATA(converted) = euros( 10 )->convert_to( currency = `JPY`
                                               date     = rate_date ).

    cl_abap_unit_assert=>assert_equals(
      act = converted->as_decimal( )
      exp = CONV decfloat34( 162500 )
      msg = `A JPY answer of 1625.00 is not read as 162500 yen` ).
    cl_abap_unit_assert=>assert_equals(
      act = converted->decimals( )
      exp = 0
      msg = `The converted amount does not carry the decimals of the target currency` ).
  ENDMETHOD.

  METHOD given_kwd_answer_then_external.
    rates->answering_with( CONV api_amount( '30.75' ) ).

    DATA(converted) = euros( 100 )->convert_to( currency = `KWD`
                                                date     = rate_date ).

    cl_abap_unit_assert=>assert_equals(
      act = converted->as_decimal( )
      exp = CONV decfloat34( '3.075' )
      msg = `A KWD answer of 30.75 is not read as 3.075 dinar` ).
  ENDMETHOD.

  METHOD given_unknown_target_raises.
    TRY.
        euros( 100 )->convert_to( currency = `XXX`
                                  date     = rate_date ).

        cl_abap_unit_assert=>fail( `An unknown target currency was unexpectedly accepted` ).
      CATCH zcx_amount INTO DATA(rejection).
        cl_abap_unit_assert=>assert_equals( act = rates->calls( )
                                            exp = 0
                                            msg = `The service is called for an unknown target currency` ).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = `The rejection does not explain itself` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_no_date_then_raises.
    TRY.
        euros( 100 )->convert_to( currency = `USD`
                                  date     = VALUE #( ) ).

        cl_abap_unit_assert=>fail( `An empty exchange rate date was unexpectedly accepted` ).
      CATCH zcx_amount INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = `The rejection does not explain itself` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_no_rate_type_then_raises.
    TRY.
        euros( 100 )->convert_to( currency  = `USD`
                                  date      = rate_date
                                  rate_type = VALUE #( ) ).

        cl_abap_unit_assert=>fail( `An empty exchange rate type was unexpectedly accepted` ).
      CATCH zcx_amount INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = `The rejection does not explain itself` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_refusal_then_wrapped.
    rates->refusing( ).

    TRY.
        euros( 100 )->convert_to( currency = `USD`
                                  date     = rate_date ).

        cl_abap_unit_assert=>fail( `A refusal of the service did not surface` ).
      CATCH zcx_amount INTO DATA(failure).
        cl_abap_unit_assert=>assert_true(
          act = xsdbool( failure->previous IS INSTANCE OF cx_exchange_rates )
          msg = `The service exception is not kept as previous` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_huge_amount_then_raises.
    TRY.
        euros( `1E30` )->convert_to( currency = `USD`
                                     date     = rate_date ).

        cl_abap_unit_assert=>fail( `An amount beyond the packed range of the service was unexpectedly accepted` ).
      CATCH zcx_amount INTO DATA(rejection).
        cl_abap_unit_assert=>assert_equals( act = rates->calls( )
                                            exp = 0
                                            msg = `The service is called with an amount that does not fit` ).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = `The rejection does not explain itself` ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_facade DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_empty_currency_raises FOR TESTING.
    METHODS given_garbage_value_raises FOR TESTING.
    METHODS given_long_currency_raises FOR TESTING.

ENDCLASS.


CLASS ltc_facade IMPLEMENTATION.

  METHOD given_empty_currency_raises.
    TRY.
        zcl_amount=>of( value    = 1
                        currency = `` ).

        cl_abap_unit_assert=>fail( `An empty currency key was unexpectedly accepted by the facade` ).
      CATCH zcx_amount INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = `The rejection does not explain itself` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_garbage_value_raises.
    TRY.
        zcl_amount=>of( value    = `ten`
                        currency = `EUR` ).

        cl_abap_unit_assert=>fail( `A value that is not a number was unexpectedly accepted by the facade` ).
      CATCH zcx_amount INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = `The rejection does not explain itself` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_long_currency_raises.
    TRY.
        zcl_amount=>decimals_of( `EUROPE` ).

        cl_abap_unit_assert=>fail( `A currency key of 6 characters was unexpectedly accepted by the facade` ).
      CATCH zcx_amount INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = `The rejection does not explain itself` ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
