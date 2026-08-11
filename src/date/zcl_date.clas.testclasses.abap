*"* use this source file for your ABAP unit test classes
CLASS ltc_creation DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS mid_june TYPE d VALUE '20250616'.

    METHODS given_date_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_date_then_iso_rendered FOR TESTING RAISING cx_static_check.
    METHODS given_iso_then_parsed FOR TESTING RAISING cx_static_check.
    METHODS given_parts_then_assembled FOR TESTING RAISING cx_static_check.
    METHODS given_valid_then_confirmed FOR TESTING.
    METHODS given_feb_30_then_denied FOR TESTING.
    METHODS given_month_13_then_denied FOR TESTING.
    METHODS given_feb_30_then_rejected FOR TESTING.
    METHODS given_initial_then_rejected FOR TESTING.
    METHODS given_letters_then_rejected FOR TESTING.
    METHODS given_feb_29_leap_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_feb_29_plain_rejected FOR TESTING.
    METHODS given_short_iso_then_rejected FOR TESTING.
    METHODS given_bad_sep_then_rejected FOR TESTING.
    METHODS given_month_13_then_rejected FOR TESTING.

ENDCLASS.


CLASS ltc_calendar_parts DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_date_then_parts_split FOR TESTING RAISING cx_static_check.
    METHODS given_dates_then_quarters FOR TESTING RAISING cx_static_check.
    METHODS given_monday_then_weekday_1 FOR TESTING RAISING cx_static_check.
    METHODS given_sunday_then_weekday_7 FOR TESTING RAISING cx_static_check.
    METHODS given_pre_1900_then_weekday FOR TESTING RAISING cx_static_check.
    METHODS given_date_then_day_of_year FOR TESTING RAISING cx_static_check.
    METHODS given_months_then_lengths FOR TESTING RAISING cx_static_check.
    METHODS given_feb_leap_then_29_days FOR TESTING RAISING cx_static_check.
    METHODS given_years_then_leap_flag FOR TESTING RAISING cx_static_check.
    METHODS given_century_then_not_leap FOR TESTING RAISING cx_static_check.
    METHODS given_sat_sun_then_weekend FOR TESTING RAISING cx_static_check.
    METHODS given_monday_then_no_weekend FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_iso_week DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_new_year_then_week_1 FOR TESTING RAISING cx_static_check.
    METHODS given_dec_30_then_week_1 FOR TESTING RAISING cx_static_check.
    METHODS given_dec_30_then_next_year FOR TESTING RAISING cx_static_check.
    METHODS given_dec_31_then_next_year FOR TESTING RAISING cx_static_check.
    METHODS given_jan_1_then_week_53 FOR TESTING RAISING cx_static_check.
    METHODS given_jan_1_then_prev_year FOR TESTING RAISING cx_static_check.
    METHODS given_mid_year_then_week_25 FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_boundaries DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_date_then_month_start FOR TESTING RAISING cx_static_check.
    METHODS given_date_then_month_end FOR TESTING RAISING cx_static_check.
    METHODS given_feb_leap_then_29_end FOR TESTING RAISING cx_static_check.
    METHODS given_date_then_quarter_start FOR TESTING RAISING cx_static_check.
    METHODS given_date_then_quarter_end FOR TESTING RAISING cx_static_check.
    METHODS given_date_then_year_start FOR TESTING RAISING cx_static_check.
    METHODS given_date_then_year_end FOR TESTING RAISING cx_static_check.
    METHODS given_sunday_then_week_start FOR TESTING RAISING cx_static_check.
    METHODS given_sunday_then_week_end FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_arithmetic DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_days_then_moved FOR TESTING RAISING cx_static_check.
    METHODS given_neg_days_then_moved FOR TESTING RAISING cx_static_check.
    METHODS given_max_date_then_rejected FOR TESTING RAISING cx_static_check.
    METHODS given_jan_31_then_feb_28 FOR TESTING RAISING cx_static_check.
    METHODS given_jan_31_leap_then_feb29 FOR TESTING RAISING cx_static_check.
    METHODS given_feb_28_then_mar_28 FOR TESTING RAISING cx_static_check.
    METHODS given_feb_28_ult_then_mar_31 FOR TESTING RAISING cx_static_check.
    METHODS given_jan_31_ult_then_feb_28 FOR TESTING RAISING cx_static_check.
    METHODS given_mid_ult_then_keeps_day FOR TESTING RAISING cx_static_check.
    METHODS given_neg_months_then_moved FOR TESTING RAISING cx_static_check.
    METHODS given_neg_month_end_then_clamp FOR TESTING RAISING cx_static_check.
    METHODS given_max_month_then_rejected FOR TESTING RAISING cx_static_check.
    METHODS given_years_then_moved FOR TESTING RAISING cx_static_check.
    METHODS given_leap_day_then_feb_28 FOR TESTING RAISING cx_static_check.
    METHODS given_dates_then_day_gap FOR TESTING RAISING cx_static_check.
    METHODS given_earlier_then_neg_gap FOR TESTING RAISING cx_static_check.
    METHODS given_period_then_inside FOR TESTING RAISING cx_static_check.
    METHODS given_period_then_outside FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_creation IMPLEMENTATION.

  METHOD given_date_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( mid_june )->as_date( )
      exp = mid_june
      msg = 'An ABAP date does not survive the round trip through the utility' ).
  ENDMETHOD.

  METHOD given_date_then_iso_rendered.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( mid_june )->as_iso( )
      exp = `2025-06-16`
      msg = 'The ISO 8601 rendering does not follow YYYY-MM-DD' ).
  ENDMETHOD.

  METHOD given_iso_then_parsed.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_iso( `2025-06-16` )->as_date( )
      exp = mid_june
      msg = 'An ISO 8601 date is not parsed into the matching ABAP date' ).
  ENDMETHOD.

  METHOD given_parts_then_assembled.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_parts( year  = 2025
                                 month = 6
                                 day   = 16 )->as_date( )
      exp = mid_june
      msg = 'Calendar components are not assembled into the matching date' ).
  ENDMETHOD.

  METHOD given_valid_then_confirmed.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>is_valid( mid_june )
      exp = abap_true
      msg = 'An existing calendar date is not recognised as valid' ).
  ENDMETHOD.

  METHOD given_feb_30_then_denied.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>is_valid( '20250230' )
      exp = abap_false
      msg = '30 February is reported as an existing calendar date' ).
  ENDMETHOD.

  METHOD given_month_13_then_denied.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>is_valid( '20251301' )
      exp = abap_false
      msg = 'Month 13 is reported as an existing calendar month' ).
  ENDMETHOD.

  METHOD given_feb_30_then_rejected.
    TRY.
        zcl_date=>for_date( '20250230' ).

        cl_abap_unit_assert=>fail( '30 February was accepted as a calendar date' ).
      CATCH zcx_date INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_initial_then_rejected.
    TRY.
        zcl_date=>for_date( '        ' ).

        cl_abap_unit_assert=>fail( 'An initial date was accepted' ).
      CATCH zcx_date INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_letters_then_rejected.
    TRY.
        zcl_date=>for_date( '2025AB16' ).

        cl_abap_unit_assert=>fail( 'A date holding letters was accepted' ).
      CATCH zcx_date INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_feb_29_leap_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20240229' )->as_iso( )
      exp = `2024-02-29`
      msg = '29 February of a leap year is not accepted' ).
  ENDMETHOD.

  METHOD given_feb_29_plain_rejected.
    TRY.
        zcl_date=>for_date( '20250229' ).

        cl_abap_unit_assert=>fail( '29 February was accepted in a non leap year' ).
      CATCH zcx_date INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_short_iso_then_rejected.
    TRY.
        zcl_date=>for_iso( `20250616` ).

        cl_abap_unit_assert=>fail( 'An ISO string without separators was accepted' ).
      CATCH zcx_date INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_bad_sep_then_rejected.
    TRY.
        zcl_date=>for_iso( `2025/06/16` ).

        cl_abap_unit_assert=>fail( 'An ISO string with wrong separators was accepted' ).
      CATCH zcx_date INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_month_13_then_rejected.
    TRY.
        zcl_date=>for_parts( year  = 2025
                             month = 13
                             day   = 1 ).

        cl_abap_unit_assert=>fail( 'Month 13 was accepted as a calendar month' ).
      CATCH zcx_date INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_calendar_parts IMPLEMENTATION.

  METHOD given_date_then_parts_split.
    DATA(date) = zcl_date=>for_date( '20250616' ).

    cl_abap_unit_assert=>assert_equals( act = date->year( )
                                        exp = 2025
                                        msg = 'The year is not read from the date' ).
    cl_abap_unit_assert=>assert_equals( act = date->month( )
                                        exp = 6
                                        msg = 'The month is not read from the date' ).
    cl_abap_unit_assert=>assert_equals( act = date->day( )
                                        exp = 16
                                        msg = 'The day is not read from the date' ).
  ENDMETHOD.

  METHOD given_dates_then_quarters.
    cl_abap_unit_assert=>assert_equals( act = zcl_date=>for_date( '20250101' )->quarter( )
                                        exp = 1
                                        msg = 'January does not fall into the first quarter' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_date=>for_date( '20250616' )->quarter( )
                                        exp = 2
                                        msg = 'June does not fall into the second quarter' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_date=>for_date( '20250731' )->quarter( )
                                        exp = 3
                                        msg = 'July does not fall into the third quarter' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_date=>for_date( '20251231' )->quarter( )
                                        exp = 4
                                        msg = 'December does not fall into the fourth quarter' ).
  ENDMETHOD.

  METHOD given_monday_then_weekday_1.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->weekday( )
      exp = 1
      msg = 'Monday is not the first day of the ISO week' ).
  ENDMETHOD.

  METHOD given_sunday_then_weekday_7.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250615' )->weekday( )
      exp = 7
      msg = 'Sunday is not the last day of the ISO week' ).
  ENDMETHOD.

  METHOD given_pre_1900_then_weekday.
    " Guards the negative remainder in the weekday calculation, which counts
    " from a Monday in 1900 and therefore goes negative for earlier dates.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '18000101' )->weekday( )
      exp = 3
      msg = '1 January 1800 is not reported as a Wednesday' ).
  ENDMETHOD.

  METHOD given_date_then_day_of_year.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->day_of_year( )
      exp = 167
      msg = '16 June 2025 is not the 167th day of the year' ).
  ENDMETHOD.

  METHOD given_months_then_lengths.
    cl_abap_unit_assert=>assert_equals( act = zcl_date=>for_date( '20250101' )->days_in_month( )
                                        exp = 31
                                        msg = 'January is not counted with 31 days' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_date=>for_date( '20250401' )->days_in_month( )
                                        exp = 30
                                        msg = 'April is not counted with 30 days' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_date=>for_date( '20250201' )->days_in_month( )
                                        exp = 28
                                        msg = 'February 2025 is not counted with 28 days' ).
  ENDMETHOD.

  METHOD given_feb_leap_then_29_days.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20240201' )->days_in_month( )
      exp = 29
      msg = 'February of a leap year is not counted with 29 days' ).
  ENDMETHOD.

  METHOD given_years_then_leap_flag.
    cl_abap_unit_assert=>assert_equals( act = zcl_date=>for_date( '20240101' )->is_leap_year( )
                                        exp = abap_true
                                        msg = '2024 is not recognised as a leap year' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_date=>for_date( '20250101' )->is_leap_year( )
                                        exp = abap_false
                                        msg = '2025 is wrongly recognised as a leap year' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_date=>for_date( '20000101' )->is_leap_year( )
                                        exp = abap_true
                                        msg = '2000 is not recognised as a leap year' ).
  ENDMETHOD.

  METHOD given_century_then_not_leap.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '19000101' )->is_leap_year( )
      exp = abap_false
      msg = '1900 is wrongly recognised as a leap year' ).
  ENDMETHOD.

  METHOD given_sat_sun_then_weekend.
    cl_abap_unit_assert=>assert_equals( act = zcl_date=>for_date( '20250614' )->is_weekend( )
                                        exp = abap_true
                                        msg = 'Saturday is not recognised as weekend' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_date=>for_date( '20250615' )->is_weekend( )
                                        exp = abap_true
                                        msg = 'Sunday is not recognised as weekend' ).
  ENDMETHOD.

  METHOD given_monday_then_no_weekend.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->is_weekend( )
      exp = abap_false
      msg = 'Monday is wrongly recognised as weekend' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_iso_week IMPLEMENTATION.

  METHOD given_new_year_then_week_1.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250101' )->iso_week( )
      exp = 1
      msg = '1 January 2025 does not fall into ISO week 1' ).
  ENDMETHOD.

  METHOD given_dec_30_then_week_1.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20241230' )->iso_week( )
      exp = 1
      msg = '30 December 2024 does not fall into ISO week 1' ).
  ENDMETHOD.

  METHOD given_dec_30_then_next_year.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20241230' )->iso_year( )
      exp = 2025
      msg = '30 December 2024 does not belong to the ISO week year 2025' ).
  ENDMETHOD.

  METHOD given_dec_31_then_next_year.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20241231' )->iso_year( )
      exp = 2025
      msg = '31 December 2024 does not belong to the ISO week year 2025' ).
  ENDMETHOD.

  METHOD given_jan_1_then_week_53.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20210101' )->iso_week( )
      exp = 53
      msg = '1 January 2021 does not fall into ISO week 53' ).
  ENDMETHOD.

  METHOD given_jan_1_then_prev_year.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20210101' )->iso_year( )
      exp = 2020
      msg = '1 January 2021 does not belong to the ISO week year 2020' ).
  ENDMETHOD.

  METHOD given_mid_year_then_week_25.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->iso_week( )
      exp = 25
      msg = '16 June 2025 does not fall into ISO week 25' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_boundaries IMPLEMENTATION.

  METHOD given_date_then_month_start.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->first_day_of_month( )->as_iso( )
      exp = `2025-06-01`
      msg = 'The first day of June is not found' ).
  ENDMETHOD.

  METHOD given_date_then_month_end.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->last_day_of_month( )->as_iso( )
      exp = `2025-06-30`
      msg = 'The last day of June is not found' ).
  ENDMETHOD.

  METHOD given_feb_leap_then_29_end.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20240215' )->last_day_of_month( )->as_iso( )
      exp = `2024-02-29`
      msg = 'The last day of February in a leap year is not found' ).
  ENDMETHOD.

  METHOD given_date_then_quarter_start.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->first_day_of_quarter( )->as_iso( )
      exp = `2025-04-01`
      msg = 'The second quarter does not start on 1 April' ).
  ENDMETHOD.

  METHOD given_date_then_quarter_end.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->last_day_of_quarter( )->as_iso( )
      exp = `2025-06-30`
      msg = 'The second quarter does not end on 30 June' ).
  ENDMETHOD.

  METHOD given_date_then_year_start.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->first_day_of_year( )->as_iso( )
      exp = `2025-01-01`
      msg = 'The year does not start on 1 January' ).
  ENDMETHOD.

  METHOD given_date_then_year_end.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->last_day_of_year( )->as_iso( )
      exp = `2025-12-31`
      msg = 'The year does not end on 31 December' ).
  ENDMETHOD.

  METHOD given_sunday_then_week_start.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250615' )->first_day_of_week( )->as_iso( )
      exp = `2025-06-09`
      msg = 'The ISO week of a Sunday does not start on the Monday before' ).
  ENDMETHOD.

  METHOD given_sunday_then_week_end.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250615' )->last_day_of_week( )->as_iso( )
      exp = `2025-06-15`
      msg = 'The ISO week of a Sunday does not end on that Sunday' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_arithmetic IMPLEMENTATION.

  METHOD given_days_then_moved.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->add_days( 10 )->as_iso( )
      exp = `2025-06-26`
      msg = 'Adding ten days does not reach the expected date' ).
  ENDMETHOD.

  METHOD given_neg_days_then_moved.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250601' )->add_days( -1 )->as_iso( )
      exp = `2025-05-31`
      msg = 'Subtracting one day does not cross the month border' ).
  ENDMETHOD.

  METHOD given_max_date_then_rejected.
    TRY.
        zcl_date=>for_date( '99991231' )->add_days( 1 ).

        cl_abap_unit_assert=>fail( 'A date beyond the calendar was accepted' ).
      CATCH zcx_date INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_jan_31_then_feb_28.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250131' )->add_months( 1 )->as_iso( )
      exp = `2025-02-28`
      msg = 'A day that does not exist in the target month is not clamped' ).
  ENDMETHOD.

  METHOD given_jan_31_leap_then_feb29.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20240131' )->add_months( 1 )->as_iso( )
      exp = `2024-02-29`
      msg = 'The clamped day ignores the extra day of a leap year' ).
  ENDMETHOD.

  METHOD given_feb_28_then_mar_28.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250228' )->add_months( 1 )->as_iso( )
      exp = `2025-03-28`
      msg = 'Adding a month does not keep the day of the month' ).
  ENDMETHOD.

  METHOD given_feb_28_ult_then_mar_31.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250228' )->add_months_ultimo( 1 )->as_iso( )
      exp = `2025-03-31`
      msg = 'A month end does not stay a month end when shifted' ).
  ENDMETHOD.

  METHOD given_jan_31_ult_then_feb_28.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250131' )->add_months_ultimo( 1 )->as_iso( )
      exp = `2025-02-28`
      msg = 'A month end is not moved to the shorter target month end' ).
  ENDMETHOD.

  METHOD given_mid_ult_then_keeps_day.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250315' )->add_months_ultimo( 1 )->as_iso( )
      exp = `2025-04-15`
      msg = 'A date in mid month is wrongly pulled to the end of the month' ).
  ENDMETHOD.

  METHOD given_neg_months_then_moved.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250315' )->add_months( -1 )->as_iso( )
      exp = `2025-02-15`
      msg = 'Subtracting a month does not reach the expected date' ).
  ENDMETHOD.

  METHOD given_neg_month_end_then_clamp.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250331' )->add_months( -1 )->as_iso( )
      exp = `2025-02-28`
      msg = 'Subtracting a month does not clamp to the shorter target month' ).
  ENDMETHOD.

  METHOD given_max_month_then_rejected.
    TRY.
        zcl_date=>for_date( '99991231' )->add_months( 1 ).

        cl_abap_unit_assert=>fail( 'A month shift beyond the calendar was accepted' ).
      CATCH zcx_date INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_years_then_moved.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->add_years( 2 )->as_iso( )
      exp = `2027-06-16`
      msg = 'Adding two years does not reach the expected date' ).
  ENDMETHOD.

  METHOD given_leap_day_then_feb_28.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20240229' )->add_years( 1 )->as_iso( )
      exp = `2025-02-28`
      msg = '29 February is not clamped when moved into a non leap year' ).
  ENDMETHOD.

  METHOD given_dates_then_day_gap.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->days_until( '20250626' )
      exp = 10
      msg = 'The distance to a later date is not counted correctly' ).
  ENDMETHOD.

  METHOD given_earlier_then_neg_gap.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->days_until( '20250606' )
      exp = -10
      msg = 'The distance to an earlier date is not negative' ).
  ENDMETHOD.

  METHOD given_period_then_inside.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->is_between( date_from = '20250601'
                                                          date_to   = '20250630' )
      exp = abap_true
      msg = 'A date inside the period is reported as outside' ).
  ENDMETHOD.

  METHOD given_period_then_outside.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_date=>for_date( '20250616' )->is_between( date_from = '20250701'
                                                          date_to   = '20250731' )
      exp = abap_false
      msg = 'A date outside the period is reported as inside' ).
  ENDMETHOD.

ENDCLASS.
