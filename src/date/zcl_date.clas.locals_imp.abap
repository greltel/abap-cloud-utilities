*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
"! Immutable calendar date. The date is validated once on construction, so
"! every method below can trust its own state and none of them needs to check
"! again. Native date arithmetic covers everything except shifting by whole
"! months - there the released XCO date API contributes the fallback to the
"! last day of a shorter target month.
CLASS lcl_date DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_date.

    CLASS-METHODS create
      IMPORTING date          TYPE d
      RETURNING VALUE(result) TYPE REF TO zif_date
      RAISING   zcx_date.

    CLASS-METHODS create_from_iso
      IMPORTING iso           TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_date
      RAISING   zcx_date.

    CLASS-METHODS create_from_parts
      IMPORTING year          TYPE i
                month         TYPE i
                day           TYPE i
      RETURNING VALUE(result) TYPE REF TO zif_date
      RAISING   zcx_date.

    CLASS-METHODS is_valid
      IMPORTING date          TYPE d
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS constructor
      IMPORTING date TYPE d.

  PRIVATE SECTION.
    CONSTANTS digits TYPE string VALUE `0123456789`.
    CONSTANTS iso_separator TYPE c LENGTH 1 VALUE '-'.
    CONSTANTS iso_length TYPE i VALUE 10.
    CONSTANTS days_per_week TYPE i VALUE 7.
    CONSTANTS months_per_year TYPE i VALUE 12.
    CONSTANTS months_per_quarter TYPE i VALUE 3.
    CONSTANTS iso_thursday TYPE i VALUE 4.
    CONSTANTS saturday TYPE i VALUE 6.
    CONSTANTS february TYPE i VALUE 2.
    CONSTANTS april TYPE i VALUE 4.
    CONSTANTS june TYPE i VALUE 6.
    CONSTANTS september TYPE i VALUE 9.
    CONSTANTS november TYPE i VALUE 11.
    CONSTANTS days_short_month TYPE i VALUE 30.
    CONSTANTS days_long_month TYPE i VALUE 31.
    CONSTANTS days_february TYPE i VALUE 28.
    CONSTANTS days_february_leap TYPE i VALUE 29.
    CONSTANTS first_month TYPE i VALUE 1.
    CONSTANTS first_day TYPE i VALUE 1.
    CONSTANTS min_year TYPE i VALUE 1.
    CONSTANTS max_year TYPE i VALUE 9999.
    CONSTANTS gregorian_cycle TYPE i VALUE 4.
    CONSTANTS gregorian_century TYPE i VALUE 100.
    CONSTANTS gregorian_long_cycle TYPE i VALUE 400.
    " 1 January 1900 was a Monday - the anchor for every weekday calculation.
    CONSTANTS reference_monday TYPE d VALUE '19000101'.

    DATA date_value TYPE d.
    DATA year TYPE i.
    DATA month TYPE i.
    DATA day TYPE i.

    CLASS-METHODS build_date
      IMPORTING year          TYPE i
                month         TYPE i
                day           TYPE i
      RETURNING VALUE(result) TYPE d.

    CLASS-METHODS is_leap
      IMPORTING year          TYPE i
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS month_length
      IMPORTING year          TYPE i
                month         TYPE i
      RETURNING VALUE(result) TYPE i.

    CLASS-METHODS quarter_of
      IMPORTING month         TYPE i
      RETURNING VALUE(result) TYPE i.

    CLASS-METHODS weekday_of
      IMPORTING date          TYPE d
      RETURNING VALUE(result) TYPE i.

    CLASS-METHODS iso_thursday_of
      IMPORTING date          TYPE d
      RETURNING VALUE(result) TYPE d.

    METHODS to_xco
      RETURNING VALUE(result) TYPE REF TO if_xco_cp_tm_date.

    METHODS shift
      IMPORTING months        TYPE i
      RETURNING VALUE(result) TYPE REF TO zif_date
      RAISING   zcx_date.

ENDCLASS.


CLASS lcl_date IMPLEMENTATION.

  METHOD constructor.
    date_value = date.

    DATA(year_part) = date(4).
    DATA(month_part) = date+4(2).
    DATA(day_part) = date+6(2).

    year = CONV i( year_part ).
    month = CONV i( month_part ).
    day = CONV i( day_part ).
  ENDMETHOD.

  METHOD create.
    IF is_valid( date ) = abap_false.
      RAISE EXCEPTION NEW zcx_date( |{ date DATE = RAW } is not a date of the Gregorian calendar| ).
    ENDIF.

    result = NEW lcl_date( date ).
  ENDMETHOD.

  METHOD create_from_iso.
    DATA(is_well_formed) = xsdbool( strlen( iso ) = iso_length ).

    IF is_well_formed = abap_true.
      DATA(first_separator) = iso+4(1).
      DATA(second_separator) = iso+7(1).

      is_well_formed = xsdbool(     first_separator = iso_separator
                                AND second_separator = iso_separator ).
    ENDIF.

    IF is_well_formed = abap_false.
      RAISE EXCEPTION NEW zcx_date( |{ iso } is not an ISO 8601 date, expected YYYY-MM-DD| ).
    ENDIF.

    DATA(year_part) = iso(4).
    DATA(month_part) = iso+5(2).
    DATA(day_part) = iso+8(2).

    result = create( CONV d( |{ year_part }{ month_part }{ day_part }| ) ).
  ENDMETHOD.

  METHOD create_from_parts.
    DATA(year_fits) = xsdbool( year BETWEEN min_year AND max_year ).
    DATA(month_fits) = xsdbool( month BETWEEN first_month AND months_per_year ).
    DATA(day_fits) = xsdbool( day BETWEEN first_day AND days_long_month ).

    IF year_fits = abap_false OR month_fits = abap_false OR day_fits = abap_false.
      RAISE EXCEPTION NEW zcx_date( |Year { year }, month { month }, day { day } is not a calendar date| ).
    ENDIF.

    result = create( build_date( year  = year
                                 month = month
                                 day   = day ) ).
  ENDMETHOD.

  METHOD is_valid.
    IF date IS INITIAL OR date CN digits.
      RETURN.
    ENDIF.

    DATA(year_part) = date(4).
    DATA(month_part) = date+4(2).
    DATA(day_part) = date+6(2).

    DATA(candidate_year) = CONV i( year_part ).
    DATA(candidate_month) = CONV i( month_part ).
    DATA(candidate_day) = CONV i( day_part ).

    IF candidate_year < min_year
       OR candidate_month < first_month
       OR candidate_month > months_per_year.
      RETURN.
    ENDIF.

    DATA(last_day) = month_length( year  = candidate_year
                                   month = candidate_month ).

    result = xsdbool( candidate_day BETWEEN first_day AND last_day ).
  ENDMETHOD.

  METHOD build_date.
    DATA(year_part) = |{ year WIDTH = 4 PAD = '0' ALIGN = RIGHT }|.
    DATA(month_part) = |{ month WIDTH = 2 PAD = '0' ALIGN = RIGHT }|.
    DATA(day_part) = |{ day WIDTH = 2 PAD = '0' ALIGN = RIGHT }|.

    result = |{ year_part }{ month_part }{ day_part }|.
  ENDMETHOD.

  METHOD is_leap.
    IF year MOD gregorian_long_cycle = 0.
      result = abap_true.
      RETURN.
    ENDIF.

    " Every other century breaks the four year cycle.
    IF year MOD gregorian_century = 0.
      RETURN.
    ENDIF.

    result = xsdbool( year MOD gregorian_cycle = 0 ).
  ENDMETHOD.

  METHOD month_length.
    IF month = february.
      result = COND i( WHEN is_leap( year ) = abap_true THEN days_february_leap
                       ELSE days_february ).
      RETURN.
    ENDIF.

    result = SWITCH i( month
                       WHEN april OR june OR september OR november THEN days_short_month
                       ELSE days_long_month ).
  ENDMETHOD.

  METHOD quarter_of.
    result = ( month - 1 ) DIV months_per_quarter + 1.
  ENDMETHOD.

  METHOD weekday_of.
    result = ( date - reference_monday ) MOD days_per_week + 1.
  ENDMETHOD.

  METHOD iso_thursday_of.
    result = CONV d( date - weekday_of( date ) + iso_thursday ).
  ENDMETHOD.

  METHOD to_xco.
    result = xco_cp_time=>date( iv_year  = CONV #( year )
                                iv_month = CONV #( month )
                                iv_day   = CONV #( day ) ).
  ENDMETHOD.

  METHOD shift.
    " Only the ULTIMO calculation of XCO is used: it falls back to the last day
    " of the target month, while PRESERVING insists on the day and ends in an
    " uncatchable CX_XCO_OUT_OF_BOUNDS_EXCEPTION. XCO stops at year 9999 the
    " same way, so the target year is checked here before XCO is entered.
    DATA(month_index) = year * months_per_year + month - 1 + months.
    DATA(target_year) = month_index DIV months_per_year.

    IF target_year < min_year OR target_year > max_year.
      RAISE EXCEPTION NEW zcx_date( |Moving { date_value DATE = ISO } by { months } months leaves the calendar| ).
    ENDIF.

    DATA(shifted) = to_xco( ).

    IF months < 0.
      shifted = shifted->subtract( iv_month       = abs( months )
                                   io_calculation = xco_cp_time=>date_calculation->ultimo ).
    ELSE.
      shifted = shifted->add( iv_month       = months
                              io_calculation = xco_cp_time=>date_calculation->ultimo ).
    ENDIF.

    result = create( build_date( year  = CONV i( shifted->year )
                                 month = CONV i( shifted->month )
                                 day   = CONV i( shifted->day ) ) ).
  ENDMETHOD.

  METHOD zif_date~as_date.
    result = date_value.
  ENDMETHOD.

  METHOD zif_date~as_iso.
    result = |{ date_value DATE = ISO }|.
  ENDMETHOD.

  METHOD zif_date~year.
    result = year.
  ENDMETHOD.

  METHOD zif_date~month.
    result = month.
  ENDMETHOD.

  METHOD zif_date~day.
    result = day.
  ENDMETHOD.

  METHOD zif_date~quarter.
    result = quarter_of( month ).
  ENDMETHOD.

  METHOD zif_date~weekday.
    result = weekday_of( date_value ).
  ENDMETHOD.

  METHOD zif_date~day_of_year.
    DATA(year_start) = build_date( year  = year
                                   month = first_month
                                   day   = first_day ).

    result = date_value - year_start + 1.
  ENDMETHOD.

  METHOD zif_date~days_in_month.
    result = month_length( year  = year
                           month = month ).
  ENDMETHOD.

  METHOD zif_date~iso_week.
    DATA(thursday) = iso_thursday_of( date_value ).
    DATA(thursday_year) = thursday(4).

    DATA(year_start) = build_date( year  = CONV i( thursday_year )
                                   month = first_month
                                   day   = first_day ).

    result = ( thursday - year_start ) DIV days_per_week + 1.
  ENDMETHOD.

  METHOD zif_date~iso_year.
    DATA(thursday) = iso_thursday_of( date_value ).
    DATA(thursday_year) = thursday(4).

    result = CONV i( thursday_year ).
  ENDMETHOD.

  METHOD zif_date~is_leap_year.
    result = is_leap( year ).
  ENDMETHOD.

  METHOD zif_date~is_weekend.
    result = xsdbool( weekday_of( date_value ) >= saturday ).
  ENDMETHOD.

  METHOD zif_date~is_between.
    result = xsdbool( date_value BETWEEN date_from AND date_to ).
  ENDMETHOD.

  METHOD zif_date~days_until.
    result = other - date_value.
  ENDMETHOD.

  METHOD zif_date~first_day_of_month.
    result = create( build_date( year  = year
                                 month = month
                                 day   = first_day ) ).
  ENDMETHOD.

  METHOD zif_date~last_day_of_month.
    DATA(last_day) = month_length( year  = year
                                   month = month ).

    result = create( build_date( year  = year
                                 month = month
                                 day   = last_day ) ).
  ENDMETHOD.

  METHOD zif_date~first_day_of_quarter.
    DATA(opening_month) = ( quarter_of( month ) - 1 ) * months_per_quarter + 1.

    result = create( build_date( year  = year
                                 month = opening_month
                                 day   = first_day ) ).
  ENDMETHOD.

  METHOD zif_date~last_day_of_quarter.
    DATA(closing_month) = quarter_of( month ) * months_per_quarter.

    DATA(last_day) = month_length( year  = year
                                   month = closing_month ).

    result = create( build_date( year  = year
                                 month = closing_month
                                 day   = last_day ) ).
  ENDMETHOD.

  METHOD zif_date~first_day_of_year.
    result = create( build_date( year  = year
                                 month = first_month
                                 day   = first_day ) ).
  ENDMETHOD.

  METHOD zif_date~last_day_of_year.
    result = create( build_date( year  = year
                                 month = months_per_year
                                 day   = days_long_month ) ).
  ENDMETHOD.

  METHOD zif_date~first_day_of_week.
    result = create( CONV d( date_value - weekday_of( date_value ) + 1 ) ).
  ENDMETHOD.

  METHOD zif_date~last_day_of_week.
    result = create( CONV d( date_value - weekday_of( date_value ) + days_per_week ) ).
  ENDMETHOD.

  METHOD zif_date~add_days.
    DATA(shifted) = CONV d( date_value + days ).

    IF is_valid( shifted ) = abap_false.
      RAISE EXCEPTION NEW zcx_date( |Moving { date_value DATE = ISO } by { days } days leaves the calendar| ).
    ENDIF.

    result = create( shifted ).
  ENDMETHOD.

  METHOD zif_date~add_months.
    result = shift( months ).
  ENDMETHOD.

  METHOD zif_date~add_months_ultimo.
    DATA(shifted) = shift( months ).

    " Staying at the end of the month is not an XCO strategy - a date that is
    " the last of its month is pulled to the last of the target month here.
    IF day < month_length( year  = year
                           month = month ).
      result = shifted.
      RETURN.
    ENDIF.

    result = shifted->last_day_of_month( ).
  ENDMETHOD.

  METHOD zif_date~add_years.
    result = shift( years * months_per_year ).
  ENDMETHOD.

ENDCLASS.
