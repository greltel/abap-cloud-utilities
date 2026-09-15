*"* use this source file for your ABAP unit test classes
"! Stands in for the time zone customizing with four zones: UTC, CET, EET
"! and INDIA. The kernel conversions for these zones run for real - the zones
"! are SAP standard content and behave the same on every system.
CLASS ltd_time_zones DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    INTERFACES lif_time_zones.

  PRIVATE SECTION.
    CONSTANTS utc TYPE tznzone VALUE 'UTC'.
    CONSTANTS central_europe TYPE tznzone VALUE 'CET'.
    CONSTANTS eastern_europe TYPE tznzone VALUE 'EET'.
    CONSTANTS india TYPE tznzone VALUE 'INDIA'.

ENDCLASS.


CLASS ltd_time_zones IMPLEMENTATION.

  METHOD lif_time_zones~exists.
    result = xsdbool( zone = utc OR zone = central_europe OR zone = eastern_europe OR zone = india ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_creation DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS ten_utc TYPE utclong VALUE '2026-09-15 10:00:00.0000000'.
    CONSTANTS ten_utc_stamp TYPE timestampl VALUE '20260915100000.0000000'.
    CONSTANTS ten_utc_short TYPE timestamp VALUE '20260915100000'.
    CONSTANTS ten_utc_unix TYPE int8 VALUE 1789466400.
    CONSTANTS precise TYPE utclong VALUE '2026-09-15 10:00:00.1234567'.
    CONSTANTS precise_stamp TYPE timestampl VALUE '20260915100000.1234567'.
    CONSTANTS feb_30_stamp TYPE timestampl VALUE '20250230100000.0000000'.
    CONSTANTS hour_24_stamp TYPE timestampl VALUE '20260915240000.0000000'.
    CONSTANTS beyond_year_9999 TYPE int8 VALUE 300000000000.
    CONSTANTS zero_stamp TYPE timestampl VALUE 0.
    CONSTANTS epoch_unix TYPE int8 VALUE 0.
    CONSTANTS second_before_epoch TYPE int8 VALUE -1.

    METHODS given_utclong_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_initial_then_rejected FOR TESTING.
    METHODS given_long_stamp_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_short_stamp_then_widened FOR TESTING RAISING cx_static_check.
    METHODS given_stamp_fraction_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_zero_stamp_then_rejected FOR TESTING.
    METHODS given_feb_30_stamp_rejected FOR TESTING.
    METHODS given_hour_24_stamp_rejected FOR TESTING.
    METHODS given_unix_then_instant FOR TESTING RAISING cx_static_check.
    METHODS given_unix_zero_then_epoch FOR TESTING RAISING cx_static_check.
    METHODS given_negative_unix_then_1969 FOR TESTING RAISING cx_static_check.
    METHODS given_huge_unix_then_rejected FOR TESTING.

ENDCLASS.


CLASS ltc_creation IMPLEMENTATION.

  METHOD given_utclong_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_utc )->as_utclong( )
      exp = ten_utc
      msg = 'The utclong value is not kept as passed' ).
  ENDMETHOD.

  METHOD given_initial_then_rejected.
    TRY.
        zcl_timestamp=>for_utclong( VALUE #( ) ).

        cl_abap_unit_assert=>fail( 'An initial utclong was accepted as a point in time' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_long_stamp_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_timestamp( ten_utc_stamp )->as_utclong( )
      exp = ten_utc
      msg = 'A TIMESTAMPL value is not converted to the matching utclong' ).
  ENDMETHOD.

  METHOD given_short_stamp_then_widened.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_short_timestamp( ten_utc_short )->as_utclong( )
      exp = ten_utc
      msg = 'A short TIMESTAMP value is not converted to the matching utclong' ).
  ENDMETHOD.

  METHOD given_stamp_fraction_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_timestamp( precise_stamp )->as_utclong( )
      exp = precise
      msg = 'The seven decimals of a TIMESTAMPL value are not kept' ).
  ENDMETHOD.

  METHOD given_zero_stamp_then_rejected.
    TRY.
        zcl_timestamp=>for_timestamp( zero_stamp ).

        cl_abap_unit_assert=>fail( 'A time stamp of zero was accepted as a point in time' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_feb_30_stamp_rejected.
    TRY.
        zcl_timestamp=>for_timestamp( feb_30_stamp ).

        cl_abap_unit_assert=>fail( 'A time stamp on 30 February was accepted' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_hour_24_stamp_rejected.
    TRY.
        zcl_timestamp=>for_timestamp( hour_24_stamp ).

        cl_abap_unit_assert=>fail( 'A time stamp with hour 24 was accepted' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_unix_then_instant.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_unix( ten_utc_unix )->as_utclong( )
      exp = ten_utc
      msg = 'A Unix time is not converted to the matching utclong' ).
  ENDMETHOD.

  METHOD given_unix_zero_then_epoch.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_unix( epoch_unix )->as_iso( )
      exp = `1970-01-01T00:00:00Z`
      msg = 'Unix time zero is not the epoch' ).
  ENDMETHOD.

  METHOD given_negative_unix_then_1969.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_unix( second_before_epoch )->as_iso( )
      exp = `1969-12-31T23:59:59Z`
      msg = 'A negative Unix time does not land before the epoch' ).
  ENDMETHOD.

  METHOD given_huge_unix_then_rejected.
    TRY.
        zcl_timestamp=>for_unix( beyond_year_9999 ).

        cl_abap_unit_assert=>fail( 'A Unix time after the year 9999 was accepted' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_iso_parsing DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS ten_utc TYPE utclong VALUE '2026-09-15 10:00:00.0000000'.
    CONSTANTS half_second TYPE utclong VALUE '2026-09-15 10:00:00.5000000'.
    CONSTANTS precise TYPE utclong VALUE '2026-09-15 10:00:00.1234567'.
    " Padded with blanks up to the length of the field.
    CONSTANTS padded_text TYPE c LENGTH 40 VALUE '2026-09-15T10:00:00Z'.

    METHODS given_zulu_then_parsed FOR TESTING RAISING cx_static_check.
    METHODS given_lower_case_then_parsed FOR TESTING RAISING cx_static_check.
    METHODS given_blank_then_parsed FOR TESTING RAISING cx_static_check.
    METHODS given_char_field_then_parsed FOR TESTING RAISING cx_static_check.
    METHODS given_plus_offset_shifted FOR TESTING RAISING cx_static_check.
    METHODS given_minus_offset_shifted FOR TESTING RAISING cx_static_check.
    METHODS given_compact_offset_then_ok FOR TESTING RAISING cx_static_check.
    METHODS given_hour_offset_then_ok FOR TESTING RAISING cx_static_check.
    METHODS given_one_digit_fraction_kept FOR TESTING RAISING cx_static_check.
    METHODS given_seven_digits_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_iso_then_round_trip FOR TESTING RAISING cx_static_check.
    METHODS given_eight_digits_rejected FOR TESTING.
    METHODS given_no_designator_rejected FOR TESTING.
    METHODS given_garbage_then_rejected FOR TESTING.
    METHODS given_empty_then_rejected FOR TESTING.
    METHODS given_feb_30_iso_rejected FOR TESTING.
    METHODS given_hour_24_iso_rejected FOR TESTING.
    METHODS given_leap_second_rejected FOR TESTING.
    METHODS given_offset_24_then_rejected FOR TESTING.
    METHODS given_offset_min_60_rejected FOR TESTING.
    METHODS given_trailing_text_rejected FOR TESTING.
    METHODS given_leading_blank_rejected FOR TESTING.
    METHODS given_before_year_1_rejected FOR TESTING.

    METHODS assert_rejected
      IMPORTING text TYPE string
                msg  TYPE string.

ENDCLASS.


CLASS ltc_iso_parsing IMPLEMENTATION.

  METHOD given_zulu_then_parsed.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_iso( `2026-09-15T10:00:00Z` )->as_utclong( )
      exp = ten_utc
      msg = 'A UTC text with Z designator is not parsed' ).
  ENDMETHOD.

  METHOD given_lower_case_then_parsed.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_iso( `2026-09-15t10:00:00z` )->as_utclong( )
      exp = ten_utc
      msg = 'Lower case t and z are not accepted' ).
  ENDMETHOD.

  METHOD given_blank_then_parsed.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_iso( `2026-09-15 10:00:00Z` )->as_utclong( )
      exp = ten_utc
      msg = 'A blank in place of the T is not accepted' ).
  ENDMETHOD.

  METHOD given_char_field_then_parsed.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_iso( padded_text )->as_utclong( )
      exp = ten_utc
      msg = 'A text field with trailing blanks is not parsed' ).
  ENDMETHOD.

  METHOD given_plus_offset_shifted.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_iso( `2026-09-15T12:00:00+02:00` )->as_utclong( )
      exp = ten_utc
      msg = 'A positive offset is not taken off the wall clock time' ).
  ENDMETHOD.

  METHOD given_minus_offset_shifted.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_iso( `2026-09-15T05:30:00-04:30` )->as_utclong( )
      exp = ten_utc
      msg = 'A negative offset is not added to the wall clock time' ).
  ENDMETHOD.

  METHOD given_compact_offset_then_ok.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_iso( `2026-09-15T12:00:00+0200` )->as_utclong( )
      exp = ten_utc
      msg = 'An offset without colon is not accepted' ).
  ENDMETHOD.

  METHOD given_hour_offset_then_ok.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_iso( `2026-09-15T12:00:00+02` )->as_utclong( )
      exp = ten_utc
      msg = 'An offset in whole hours is not accepted' ).
  ENDMETHOD.

  METHOD given_one_digit_fraction_kept.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_iso( `2026-09-15T10:00:00.5Z` )->as_utclong( )
      exp = half_second
      msg = 'A fraction with one digit is not kept' ).
  ENDMETHOD.

  METHOD given_seven_digits_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_iso( `2026-09-15T10:00:00.1234567Z` )->as_utclong( )
      exp = precise
      msg = 'A fraction with seven digits is not kept' ).
  ENDMETHOD.

  METHOD given_iso_then_round_trip.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_iso( `2026-09-15T10:00:00.25Z` )->as_iso( )
      exp = `2026-09-15T10:00:00.25Z`
      msg = 'Parsing and rendering do not round trip' ).
  ENDMETHOD.

  METHOD given_eight_digits_rejected.
    assert_rejected( text = `2026-09-15T10:00:00.12345678Z`
                     msg  = `A fraction with eight digits was accepted` ).
  ENDMETHOD.

  METHOD given_no_designator_rejected.
    TRY.
        zcl_timestamp=>for_iso( `2026-09-15T10:00:00` ).

        cl_abap_unit_assert=>fail( 'A text without zone designator was accepted as a point in time' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_char_cp( act = rejection->get_text( )
                                             exp = '*designator*'
                                             msg = 'The rejection does not name the missing designator' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_garbage_then_rejected.
    assert_rejected( text = `next tuesday`
                     msg  = `Free text was accepted as a time stamp` ).
  ENDMETHOD.

  METHOD given_empty_then_rejected.
    assert_rejected( text = ``
                     msg  = `An empty text was accepted as a time stamp` ).
  ENDMETHOD.

  METHOD given_feb_30_iso_rejected.
    assert_rejected( text = `2025-02-30T10:00:00Z`
                     msg  = `30 February was accepted as a calendar date` ).
  ENDMETHOD.

  METHOD given_hour_24_iso_rejected.
    assert_rejected( text = `2026-09-15T24:00:00Z`
                     msg  = `Hour 24 was accepted as a time of day` ).
  ENDMETHOD.

  METHOD given_leap_second_rejected.
    assert_rejected( text = `2026-06-30T23:59:60Z`
                     msg  = `A leap second was accepted although utclong cannot hold it` ).
  ENDMETHOD.

  METHOD given_offset_24_then_rejected.
    assert_rejected( text = `2026-09-15T10:00:00+24:00`
                     msg  = `An offset of 24 hours was accepted` ).
  ENDMETHOD.

  METHOD given_offset_min_60_rejected.
    assert_rejected( text = `2026-09-15T10:00:00+02:60`
                     msg  = `An offset with 60 minutes was accepted` ).
  ENDMETHOD.

  METHOD given_trailing_text_rejected.
    assert_rejected( text = `2026-09-15T10:00:00Z now`
                     msg  = `Text after the designator was accepted` ).
  ENDMETHOD.

  METHOD given_leading_blank_rejected.
    assert_rejected( text = ` 2026-09-15T10:00:00Z`
                     msg  = `A leading blank was accepted` ).
  ENDMETHOD.

  METHOD given_before_year_1_rejected.
    assert_rejected( text = `0001-01-01T00:00:00+01:00`
                     msg  = `A point in time before the year 1 was accepted` ).
  ENDMETHOD.

  METHOD assert_rejected.
    TRY.
        zcl_timestamp=>for_iso( text ).

        cl_abap_unit_assert=>fail( msg ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_rendering DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS ten_utc TYPE utclong VALUE '2026-09-15 10:00:00.0000000'.
    CONSTANTS ten_utc_12 TYPE utclong VALUE '2026-09-15 10:00:00.1200000'.
    CONSTANTS one_tick TYPE utclong VALUE '2026-09-15 10:00:00.0000001'.
    CONSTANTS last_tick TYPE utclong VALUE '2026-09-15 10:00:00.9999999'.
    CONSTANTS precise TYPE utclong VALUE '2026-09-15 10:00:00.1234567'.
    CONSTANTS epoch TYPE utclong VALUE '1970-01-01 00:00:00.0000000'.
    CONSTANTS before_epoch TYPE utclong VALUE '1969-12-31 23:59:59.5000000'.
    CONSTANTS precise_stamp TYPE timestampl VALUE '20260915100000.1234567'.
    CONSTANTS ten_utc_short TYPE timestamp VALUE '20260915100000'.
    CONSTANTS ten_utc_unix TYPE int8 VALUE 1789466400.

    METHODS given_whole_second_then_iso FOR TESTING RAISING cx_static_check.
    METHODS given_fraction_iso_trimmed FOR TESTING RAISING cx_static_check.
    METHODS given_one_tick_iso_7_digits FOR TESTING RAISING cx_static_check.
    METHODS given_max_then_iso FOR TESTING RAISING cx_static_check.
    METHODS given_fraction_then_long_stamp FOR TESTING RAISING cx_static_check.
    METHODS given_last_tick_short_stamp FOR TESTING RAISING cx_static_check.
    METHODS given_instant_then_unix FOR TESTING RAISING cx_static_check.
    METHODS given_epoch_then_unix_zero FOR TESTING RAISING cx_static_check.
    METHODS given_pre_epoch_unix_floored FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_rendering IMPLEMENTATION.

  METHOD given_whole_second_then_iso.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_utc )->as_iso( )
      exp = `2026-09-15T10:00:00Z`
      msg = 'A whole second is not rendered without fraction' ).
  ENDMETHOD.

  METHOD given_fraction_iso_trimmed.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_utc_12 )->as_iso( )
      exp = `2026-09-15T10:00:00.12Z`
      msg = 'The trailing zeros of the fraction are not trimmed' ).
  ENDMETHOD.

  METHOD given_one_tick_iso_7_digits.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( one_tick )->as_iso( )
      exp = `2026-09-15T10:00:00.0000001Z`
      msg = 'The smallest fraction is not rendered with seven digits' ).
  ENDMETHOD.

  METHOD given_max_then_iso.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( cl_abap_utclong=>max )->as_iso( )
      exp = `9999-12-31T23:59:59.9999999Z`
      msg = 'The end of the time line is not rendered' ).
  ENDMETHOD.

  METHOD given_fraction_then_long_stamp.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( precise )->as_timestamp( )
      exp = precise_stamp
      msg = 'The TIMESTAMPL value does not carry all seven decimals' ).
  ENDMETHOD.

  METHOD given_last_tick_short_stamp.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( last_tick )->as_short_timestamp( )
      exp = ten_utc_short
      msg = 'The short TIMESTAMP value rounds instead of dropping the fraction' ).
  ENDMETHOD.

  METHOD given_instant_then_unix.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_utc )->as_unix_seconds( )
      exp = ten_utc_unix
      msg = 'The Unix time of a point in time is wrong' ).
  ENDMETHOD.

  METHOD given_epoch_then_unix_zero.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( epoch )->as_unix_seconds( )
      exp = 0
      msg = 'The epoch is not Unix time zero' ).
  ENDMETHOD.

  METHOD given_pre_epoch_unix_floored.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( before_epoch )->as_unix_seconds( )
      exp = -1
      msg = 'A fraction before the epoch is not dropped towards the past' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_arithmetic DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS ten_utc TYPE utclong VALUE '2026-09-15 10:00:00.0000000'.
    CONSTANTS ten_01_30 TYPE utclong VALUE '2026-09-15 10:01:30.0000000'.
    CONSTANTS nine_59_59 TYPE utclong VALUE '2026-09-15 09:59:59.0000000'.
    CONSTANTS eleven_30 TYPE utclong VALUE '2026-09-15 11:30:00.0000000'.
    CONSTANTS next_day_01 TYPE utclong VALUE '2026-09-16 01:00:00.0000000'.
    CONSTANTS next_day_ten TYPE utclong VALUE '2026-09-16 10:00:00.0000000'.
    CONSTANTS feb_28 TYPE utclong VALUE '2026-02-28 10:00:00.0000000'.
    CONSTANTS mar_1 TYPE utclong VALUE '2026-03-01 10:00:00.0000000'.
    CONSTANTS precise TYPE utclong VALUE '2026-09-15 10:00:00.1234567'.
    CONSTANTS precise_plus_1 TYPE utclong VALUE '2026-09-15 10:00:01.1234567'.
    CONSTANTS last_tick TYPE utclong VALUE '2026-09-15 10:00:00.9999999'.
    CONSTANTS half_second TYPE utclong VALUE '2026-09-15 10:00:00.5000000'.
    CONSTANTS ninety TYPE decfloat34 VALUE 90.
    CONSTANTS minus_ninety TYPE decfloat34 VALUE -90.
    CONSTANTS half TYPE decfloat34 VALUE '0.5'.
    CONSTANTS one_day TYPE decfloat34 VALUE 86400.

    METHODS given_90_seconds_then_added FOR TESTING RAISING cx_static_check.
    METHODS given_minus_1_second_then_back FOR TESTING RAISING cx_static_check.
    METHODS given_90_minutes_then_added FOR TESTING RAISING cx_static_check.
    METHODS given_15_hours_then_next_day FOR TESTING RAISING cx_static_check.
    METHODS given_1_day_then_next_day FOR TESTING RAISING cx_static_check.
    METHODS given_feb_28_plus_day_is_mar_1 FOR TESTING RAISING cx_static_check.
    METHODS given_0_days_then_unchanged FOR TESTING RAISING cx_static_check.
    METHODS given_fraction_kept_on_add FOR TESTING RAISING cx_static_check.
    METHODS given_max_plus_1_rejected FOR TESTING.
    METHODS given_min_minus_1_rejected FOR TESTING.
    METHODS given_fraction_then_truncated FOR TESTING RAISING cx_static_check.
    METHODS given_later_then_positive_secs FOR TESTING RAISING cx_static_check.
    METHODS given_earlier_then_minus_secs FOR TESTING RAISING cx_static_check.
    METHODS given_half_second_then_half FOR TESTING RAISING cx_static_check.
    METHODS given_next_day_then_86400 FOR TESTING RAISING cx_static_check.
    METHODS given_initial_other_rejected FOR TESTING.

ENDCLASS.


CLASS ltc_arithmetic IMPLEMENTATION.

  METHOD given_90_seconds_then_added.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_utc )->add_seconds( 90 )->as_utclong( )
      exp = ten_01_30
      msg = 'Adding 90 seconds does not land on the expected point in time' ).
  ENDMETHOD.

  METHOD given_minus_1_second_then_back.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_utc )->add_seconds( -1 )->as_utclong( )
      exp = nine_59_59
      msg = 'Adding -1 second does not move into the past' ).
  ENDMETHOD.

  METHOD given_90_minutes_then_added.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_utc )->add_minutes( 90 )->as_utclong( )
      exp = eleven_30
      msg = 'Adding 90 minutes does not land on the expected point in time' ).
  ENDMETHOD.

  METHOD given_15_hours_then_next_day.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_utc )->add_hours( 15 )->as_utclong( )
      exp = next_day_01
      msg = 'Adding 15 hours does not cross into the next day' ).
  ENDMETHOD.

  METHOD given_1_day_then_next_day.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_utc )->add_days( 1 )->as_utclong( )
      exp = next_day_ten
      msg = 'Adding one day does not land on the same time of the next day' ).
  ENDMETHOD.

  METHOD given_feb_28_plus_day_is_mar_1.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( feb_28 )->add_days( 1 )->as_utclong( )
      exp = mar_1
      msg = 'Adding one day to 28 February 2026 does not reach 1 March' ).
  ENDMETHOD.

  METHOD given_0_days_then_unchanged.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_utc )->add_days( 0 )->as_utclong( )
      exp = ten_utc
      msg = 'Adding zero days changes the point in time' ).
  ENDMETHOD.

  METHOD given_fraction_kept_on_add.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( precise )->add_seconds( 1 )->as_utclong( )
      exp = precise_plus_1
      msg = 'The fraction of the second is lost when seconds are added' ).
  ENDMETHOD.

  METHOD given_max_plus_1_rejected.
    TRY.
        zcl_timestamp=>for_utclong( cl_abap_utclong=>max )->add_seconds( 1 ).

        cl_abap_unit_assert=>fail( 'Moving past the end of the time line was accepted' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_min_minus_1_rejected.
    TRY.
        zcl_timestamp=>for_utclong( cl_abap_utclong=>min )->add_seconds( -1 ).

        cl_abap_unit_assert=>fail( 'Moving before the start of the time line was accepted' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_fraction_then_truncated.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( last_tick )->truncate_to_seconds( )->as_utclong( )
      exp = ten_utc
      msg = 'Truncating does not drop the fraction of the second' ).
  ENDMETHOD.

  METHOD given_later_then_positive_secs.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_utc )->seconds_until( ten_01_30 )
      exp = ninety
      msg = 'The seconds to a later point in time are not positive 90' ).
  ENDMETHOD.

  METHOD given_earlier_then_minus_secs.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_01_30 )->seconds_until( ten_utc )
      exp = minus_ninety
      msg = 'The seconds to an earlier point in time are not negative 90' ).
  ENDMETHOD.

  METHOD given_half_second_then_half.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_utc )->seconds_until( half_second )
      exp = half
      msg = 'The fraction of a second is lost in the distance' ).
  ENDMETHOD.

  METHOD given_next_day_then_86400.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_timestamp=>for_utclong( ten_utc )->seconds_until( next_day_ten )
      exp = one_day
      msg = 'A day is not 86400 seconds on the UTC time line' ).
  ENDMETHOD.

  METHOD given_initial_other_rejected.
    TRY.
        zcl_timestamp=>for_utclong( ten_utc )->seconds_until( VALUE #( ) ).

        cl_abap_unit_assert=>fail( 'The distance to an initial value was calculated' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_comparison DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS nine TYPE utclong VALUE '2026-09-15 09:00:00.0000000'.
    CONSTANTS ten TYPE utclong VALUE '2026-09-15 10:00:00.0000000'.
    CONSTANTS ten_plus_tick TYPE utclong VALUE '2026-09-15 10:00:00.0000001'.
    CONSTANTS eleven TYPE utclong VALUE '2026-09-15 11:00:00.0000000'.

    DATA cut TYPE REF TO zif_timestamp.

    METHODS setup RAISING zcx_timestamp.

    METHODS given_same_instant_then_equal FOR TESTING.
    METHODS given_one_tick_apart_not_equal FOR TESTING.
    METHODS given_later_other_then_before FOR TESTING.
    METHODS given_earlier_other_not_before FOR TESTING.
    METHODS given_earlier_other_then_after FOR TESTING.
    METHODS given_same_then_not_before FOR TESTING.
    METHODS given_same_then_not_after FOR TESTING.
    METHODS given_inside_then_between FOR TESTING.
    METHODS given_on_start_then_between FOR TESTING.
    METHODS given_on_end_then_between FOR TESTING.
    METHODS given_outside_then_not_between FOR TESTING.

ENDCLASS.


CLASS ltc_comparison IMPLEMENTATION.

  METHOD setup.
    cut = zcl_timestamp=>for_utclong( ten ).
  ENDMETHOD.

  METHOD given_same_instant_then_equal.
    cl_abap_unit_assert=>assert_equals(
      act = cut->equals( ten )
      exp = abap_true
      msg = 'The same point in time is not recognised as equal' ).
  ENDMETHOD.

  METHOD given_one_tick_apart_not_equal.
    cl_abap_unit_assert=>assert_equals(
      act = cut->equals( ten_plus_tick )
      exp = abap_false
      msg = 'Points in time 100 nanoseconds apart are reported as equal' ).
  ENDMETHOD.

  METHOD given_later_other_then_before.
    cl_abap_unit_assert=>assert_equals(
      act = cut->is_before( eleven )
      exp = abap_true
      msg = '10:00 is not reported as before 11:00' ).
  ENDMETHOD.

  METHOD given_earlier_other_not_before.
    cl_abap_unit_assert=>assert_equals(
      act = cut->is_before( nine )
      exp = abap_false
      msg = '10:00 is reported as before 09:00' ).
  ENDMETHOD.

  METHOD given_earlier_other_then_after.
    cl_abap_unit_assert=>assert_equals(
      act = cut->is_after( nine )
      exp = abap_true
      msg = '10:00 is not reported as after 09:00' ).
  ENDMETHOD.

  METHOD given_same_then_not_before.
    cl_abap_unit_assert=>assert_equals(
      act = cut->is_before( ten )
      exp = abap_false
      msg = 'A point in time is reported as before itself' ).
  ENDMETHOD.

  METHOD given_same_then_not_after.
    cl_abap_unit_assert=>assert_equals(
      act = cut->is_after( ten )
      exp = abap_false
      msg = 'A point in time is reported as after itself' ).
  ENDMETHOD.

  METHOD given_inside_then_between.
    cl_abap_unit_assert=>assert_equals(
      act = cut->is_between( time_from = nine
                             time_to   = eleven )
      exp = abap_true
      msg = '10:00 is not reported as between 09:00 and 11:00' ).
  ENDMETHOD.

  METHOD given_on_start_then_between.
    cl_abap_unit_assert=>assert_equals(
      act = cut->is_between( time_from = ten
                             time_to   = eleven )
      exp = abap_true
      msg = 'The start of the period is not included' ).
  ENDMETHOD.

  METHOD given_on_end_then_between.
    cl_abap_unit_assert=>assert_equals(
      act = cut->is_between( time_from = nine
                             time_to   = ten )
      exp = abap_true
      msg = 'The end of the period is not included' ).
  ENDMETHOD.

  METHOD given_outside_then_not_between.
    cl_abap_unit_assert=>assert_equals(
      act = cut->is_between( time_from = ten_plus_tick
                             time_to   = eleven )
      exp = abap_false
      msg = 'A point in time 100 nanoseconds before the period is reported as inside' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_time_zone DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS summer_ten_utc TYPE utclong VALUE '2026-09-15 10:00:00.0000000'.
    CONSTANTS winter_ten_utc TYPE utclong VALUE '2026-01-15 10:00:00.0000000'.
    CONSTANTS summer_half_second TYPE utclong VALUE '2026-09-15 10:00:00.5000000'.
    CONSTANTS cet_day_start TYPE utclong VALUE '2026-09-14 22:00:00.0000000'.
    CONSTANTS cet_day_end TYPE utclong VALUE '2026-09-15 21:59:59.9999999'.
    CONSTANTS cet_day_end_stamp TYPE timestampl VALUE '20260915215959.9999999'.
    CONSTANTS utc_day_start TYPE utclong VALUE '2026-09-15 00:00:00.0000000'.
    CONSTANTS utc_day_end TYPE utclong VALUE '2026-09-15 23:59:59.9999999'.
    CONSTANTS spring_switch_noon TYPE utclong VALUE '2026-03-29 12:00:00.0000000'.
    CONSTANTS autumn_switch_noon TYPE utclong VALUE '2026-10-25 12:00:00.0000000'.
    CONSTANTS mid_september TYPE d VALUE '20260915'.
    CONSTANTS feb_30 TYPE d VALUE '20250230'.
    CONSTANTS noon TYPE t VALUE '120000'.
    CONSTANTS eleven TYPE t VALUE '110000'.
    CONSTANTS central_europe TYPE string VALUE `CET`.
    CONSTANTS india TYPE string VALUE `INDIA`.
    CONSTANTS utc TYPE string VALUE `UTC`.
    CONSTANTS summer_offset TYPE i VALUE 7200.
    CONSTANTS winter_offset TYPE i VALUE 3600.
    CONSTANTS india_offset TYPE i VALUE 19800.
    CONSTANTS short_day TYPE decfloat34 VALUE 82800.
    CONSTANTS long_day TYPE decfloat34 VALUE 90000.

    DATA factory TYPE REF TO lcl_factory.

    METHODS setup.

    METHODS given_summer_then_cet_plus_2h FOR TESTING RAISING cx_static_check.
    METHODS given_summer_then_cet_noon FOR TESTING RAISING cx_static_check.
    METHODS given_summer_then_cet_date FOR TESTING RAISING cx_static_check.
    METHODS given_summer_then_daylight FOR TESTING RAISING cx_static_check.
    METHODS given_winter_then_cet_plus_1h FOR TESTING RAISING cx_static_check.
    METHODS given_winter_then_cet_eleven FOR TESTING RAISING cx_static_check.
    METHODS given_winter_then_no_daylight FOR TESTING RAISING cx_static_check.
    METHODS given_india_then_plus_5h30 FOR TESTING RAISING cx_static_check.
    METHODS given_india_then_no_daylight FOR TESTING RAISING cx_static_check.
    METHODS given_utc_zone_then_zulu_iso FOR TESTING RAISING cx_static_check.
    METHODS given_summer_then_cet_iso FOR TESTING RAISING cx_static_check.
    METHODS given_winter_then_cet_iso FOR TESTING RAISING cx_static_check.
    METHODS given_fraction_then_local_iso FOR TESTING RAISING cx_static_check.
    METHODS given_india_then_iso FOR TESTING RAISING cx_static_check.
    METHODS given_padded_zone_then_key FOR TESTING RAISING cx_static_check.
    METHODS given_unknown_zone_rejected FOR TESTING.
    METHODS given_empty_zone_then_rejected FOR TESTING.
    METHODS given_long_zone_then_rejected FOR TESTING.
    METHODS given_known_zone_confirmed FOR TESTING.
    METHODS given_unknown_zone_then_denied FOR TESTING.
    METHODS given_cet_wall_clock_then_utc FOR TESTING RAISING cx_static_check.
    METHODS given_feb_30_clock_rejected FOR TESTING.
    METHODS given_bad_zone_clock_rejected FOR TESTING.
    METHODS given_cet_day_then_start FOR TESTING RAISING cx_static_check.
    METHODS given_cet_day_then_end FOR TESTING RAISING cx_static_check.
    METHODS given_cet_day_end_then_stamp FOR TESTING RAISING cx_static_check.
    METHODS given_utc_day_then_start FOR TESTING RAISING cx_static_check.
    METHODS given_utc_day_then_end FOR TESTING RAISING cx_static_check.
    METHODS given_spring_switch_then_23h FOR TESTING RAISING cx_static_check.
    METHODS given_autumn_switch_then_25h FOR TESTING RAISING cx_static_check.

    METHODS in_cet
      IMPORTING instant       TYPE utclong
      RETURNING VALUE(result) TYPE REF TO zif_timestamp_local
      RAISING   zcx_timestamp.

    METHODS day_length_in_cet
      IMPORTING instant       TYPE utclong
      RETURNING VALUE(result) TYPE decfloat34
      RAISING   zcx_timestamp.

ENDCLASS.


CLASS ltc_time_zone IMPLEMENTATION.

  METHOD setup.
    factory = NEW lcl_factory( NEW ltd_time_zones( ) ).
  ENDMETHOD.

  METHOD in_cet.
    result = factory->for_utclong( instant )->in_zone( central_europe ).
  ENDMETHOD.

  METHOD day_length_in_cet.
    DATA(next_day) = factory->for_utclong( instant )->add_days( 1 )->in_zone( central_europe ).

    result = in_cet( instant )->start_of_day( )->seconds_until( next_day->start_of_day( )->as_utclong( ) ).
  ENDMETHOD.

  METHOD given_summer_then_cet_plus_2h.
    cl_abap_unit_assert=>assert_equals(
      act = in_cet( summer_ten_utc )->utc_offset_seconds( )
      exp = summer_offset
      msg = 'CET is not two hours ahead of UTC in September' ).
  ENDMETHOD.

  METHOD given_summer_then_cet_noon.
    cl_abap_unit_assert=>assert_equals(
      act = in_cet( summer_ten_utc )->time( )
      exp = noon
      msg = '10:00 UTC is not noon in CET in September' ).
  ENDMETHOD.

  METHOD given_summer_then_cet_date.
    cl_abap_unit_assert=>assert_equals(
      act = in_cet( summer_ten_utc )->date( )
      exp = mid_september
      msg = 'The date on the CET wall clock is wrong' ).
  ENDMETHOD.

  METHOD given_summer_then_daylight.
    cl_abap_unit_assert=>assert_equals(
      act = in_cet( summer_ten_utc )->is_daylight_saving( )
      exp = abap_true
      msg = 'September in CET is not reported as daylight saving time' ).
  ENDMETHOD.

  METHOD given_winter_then_cet_plus_1h.
    cl_abap_unit_assert=>assert_equals(
      act = in_cet( winter_ten_utc )->utc_offset_seconds( )
      exp = winter_offset
      msg = 'CET is not one hour ahead of UTC in January' ).
  ENDMETHOD.

  METHOD given_winter_then_cet_eleven.
    cl_abap_unit_assert=>assert_equals(
      act = in_cet( winter_ten_utc )->time( )
      exp = eleven
      msg = '10:00 UTC is not 11:00 in CET in January' ).
  ENDMETHOD.

  METHOD given_winter_then_no_daylight.
    cl_abap_unit_assert=>assert_equals(
      act = in_cet( winter_ten_utc )->is_daylight_saving( )
      exp = abap_false
      msg = 'January in CET is reported as daylight saving time' ).
  ENDMETHOD.

  METHOD given_india_then_plus_5h30.
    cl_abap_unit_assert=>assert_equals(
      act = factory->for_utclong( summer_ten_utc )->in_zone( india )->utc_offset_seconds( )
      exp = india_offset
      msg = 'India is not five and a half hours ahead of UTC' ).
  ENDMETHOD.

  METHOD given_india_then_no_daylight.
    cl_abap_unit_assert=>assert_equals(
      act = factory->for_utclong( summer_ten_utc )->in_zone( india )->is_daylight_saving( )
      exp = abap_false
      msg = 'India is reported as daylight saving time' ).
  ENDMETHOD.

  METHOD given_utc_zone_then_zulu_iso.
    cl_abap_unit_assert=>assert_equals(
      act = factory->for_utclong( summer_ten_utc )->in_zone( utc )->as_iso( )
      exp = `2026-09-15T10:00:00Z`
      msg = 'The UTC wall clock is not rendered with Z' ).
  ENDMETHOD.

  METHOD given_summer_then_cet_iso.
    cl_abap_unit_assert=>assert_equals(
      act = in_cet( summer_ten_utc )->as_iso( )
      exp = `2026-09-15T12:00:00+02:00`
      msg = 'The CET wall clock in summer is not rendered with +02:00' ).
  ENDMETHOD.

  METHOD given_winter_then_cet_iso.
    cl_abap_unit_assert=>assert_equals(
      act = in_cet( winter_ten_utc )->as_iso( )
      exp = `2026-01-15T11:00:00+01:00`
      msg = 'The CET wall clock in winter is not rendered with +01:00' ).
  ENDMETHOD.

  METHOD given_fraction_then_local_iso.
    cl_abap_unit_assert=>assert_equals(
      act = in_cet( summer_half_second )->as_iso( )
      exp = `2026-09-15T12:00:00.5+02:00`
      msg = 'The fraction of the second is lost on the local wall clock' ).
  ENDMETHOD.

  METHOD given_india_then_iso.
    cl_abap_unit_assert=>assert_equals(
      act = factory->for_utclong( summer_ten_utc )->in_zone( india )->as_iso( )
      exp = `2026-09-15T15:30:00+05:30`
      msg = 'A half hour offset is not rendered as +05:30' ).
  ENDMETHOD.

  METHOD given_padded_zone_then_key.
    cl_abap_unit_assert=>assert_equals(
      act = factory->for_utclong( summer_ten_utc )->in_zone( ` cet ` )->zone( )
      exp = central_europe
      msg = 'Blanks and lower case around the zone are not tolerated' ).
  ENDMETHOD.

  METHOD given_unknown_zone_rejected.
    TRY.
        factory->for_utclong( summer_ten_utc )->in_zone( `MARS` ).

        cl_abap_unit_assert=>fail( 'An unknown time zone was accepted' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_empty_zone_then_rejected.
    TRY.
        factory->for_utclong( summer_ten_utc )->in_zone( `` ).

        cl_abap_unit_assert=>fail( 'An empty time zone was accepted' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_long_zone_then_rejected.
    TRY.
        factory->for_utclong( summer_ten_utc )->in_zone( `EUROPE/ATHENS` ).

        cl_abap_unit_assert=>fail( 'A time zone longer than the key was accepted' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_known_zone_confirmed.
    cl_abap_unit_assert=>assert_equals(
      act = factory->is_known_zone( `eet` )
      exp = abap_true
      msg = 'A known time zone is not confirmed' ).
  ENDMETHOD.

  METHOD given_unknown_zone_then_denied.
    cl_abap_unit_assert=>assert_equals(
      act = factory->is_known_zone( `MARS` )
      exp = abap_false
      msg = 'An unknown time zone is confirmed' ).
  ENDMETHOD.

  METHOD given_cet_wall_clock_then_utc.
    cl_abap_unit_assert=>assert_equals(
      act = factory->for_date_time( date = mid_september
                                    time = noon
                                    zone = central_europe )->as_utclong( )
      exp = summer_ten_utc
      msg = 'Noon on the CET wall clock in September is not 10:00 UTC' ).
  ENDMETHOD.

  METHOD given_feb_30_clock_rejected.
    TRY.
        factory->for_date_time( date = feb_30
                                time = noon
                                zone = central_europe ).

        cl_abap_unit_assert=>fail( '30 February was accepted as a wall clock date' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_bad_zone_clock_rejected.
    TRY.
        factory->for_date_time( date = mid_september
                                time = noon
                                zone = `MARS` ).

        cl_abap_unit_assert=>fail( 'A wall clock time in an unknown zone was accepted' ).
      CATCH zcx_timestamp INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_cet_day_then_start.
    cl_abap_unit_assert=>assert_equals(
      act = in_cet( summer_ten_utc )->start_of_day( )->as_utclong( )
      exp = cet_day_start
      msg = 'The CET day does not start at 22:00 UTC of the previous day' ).
  ENDMETHOD.

  METHOD given_cet_day_then_end.
    cl_abap_unit_assert=>assert_equals(
      act = in_cet( summer_ten_utc )->end_of_day( )->as_utclong( )
      exp = cet_day_end
      msg = 'The CET day does not end at 21:59:59.9999999 UTC' ).
  ENDMETHOD.

  METHOD given_cet_day_end_then_stamp.
    cl_abap_unit_assert=>assert_equals(
      act = in_cet( summer_ten_utc )->end_of_day( )->as_timestamp( )
      exp = cet_day_end_stamp
      msg = 'The end of the day is not usable as upper border for TIMESTAMPL' ).
  ENDMETHOD.

  METHOD given_utc_day_then_start.
    cl_abap_unit_assert=>assert_equals(
      act = factory->for_utclong( summer_ten_utc )->in_zone( utc )->start_of_day( )->as_utclong( )
      exp = utc_day_start
      msg = 'The UTC day does not start at midnight' ).
  ENDMETHOD.

  METHOD given_utc_day_then_end.
    cl_abap_unit_assert=>assert_equals(
      act = factory->for_utclong( summer_ten_utc )->in_zone( utc )->end_of_day( )->as_utclong( )
      exp = utc_day_end
      msg = 'The UTC day does not end at 23:59:59.9999999' ).
  ENDMETHOD.

  METHOD given_spring_switch_then_23h.
    cl_abap_unit_assert=>assert_equals(
      act = day_length_in_cet( spring_switch_noon )
      exp = short_day
      msg = 'The day of the switch to daylight saving time is not 23 hours long' ).
  ENDMETHOD.

  METHOD given_autumn_switch_then_25h.
    cl_abap_unit_assert=>assert_equals(
      act = day_length_in_cet( autumn_switch_noon )
      exp = long_day
      msg = 'The day of the switch back from daylight saving time is not 25 hours long' ).
  ENDMETHOD.

ENDCLASS.
