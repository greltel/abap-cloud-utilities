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
    INTERFACES zif_acu_date.

    CLASS-METHODS create
      IMPORTING date          TYPE d
      RETURNING VALUE(result) TYPE REF TO zif_acu_date
      RAISING   zcx_date.

    CLASS-METHODS create_from_iso
      IMPORTING iso           TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_acu_date
      RAISING   zcx_date.

    CLASS-METHODS create_from_parts
      IMPORTING year          TYPE i
                month         TYPE i
                day           TYPE i
      RETURNING VALUE(result) TYPE REF TO zif_acu_date
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
      RETURNING VALUE(result) TYPE REF TO zif_acu_date
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

      is_well_formed = xsdbool( first_separator = iso_separator
                                AND second_separator = iso_separator ).
    ENDIF.

    IF is_well_formed = abap_false.
      RAISE EXCEPTION NEW zcx_date( |{ iso } is not an ISO 8601 date,expected YYYY-MM-DD| ).
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

    DATA(year_fits) = xsdbool( candidate_year >= min_year ).
    DATA(month_fits) = xsdbool( candidate_month BETWEEN first_month AND months_per_year ).

    IF year_fits = abap_false OR month_fits = abap_false.
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

  METHOD zif_acu_date~as_date.
    result = date_value.
  ENDMETHOD.

  METHOD zif_acu_date~as_iso.
    result = |{ date_value DATE = ISO }|.
  ENDMETHOD.

  METHOD zif_acu_date~year.
    result = year.
  ENDMETHOD.

  METHOD zif_acu_date~month.
    result = month.
  ENDMETHOD.

  METHOD zif_acu_date~day.
    result = day.
  ENDMETHOD.

  METHOD zif_acu_date~quarter.
    result = quarter_of( month ).
  ENDMETHOD.

  METHOD zif_acu_date~weekday.
    result = weekday_of( date_value ).
  ENDMETHOD.

  METHOD zif_acu_date~day_of_year.
    DATA(year_start) = build_date( year  = year
                                   month = first_month
                                   day   = first_day ).

    result = date_value - year_start + 1.
  ENDMETHOD.

  METHOD zif_acu_date~days_in_month.
    result = month_length( year  = year
                           month = month ).
  ENDMETHOD.

  METHOD zif_acu_date~iso_week.
    DATA(thursday) = iso_thursday_of( date_value ).
    DATA(thursday_year) = thursday(4).

    DATA(year_start) = build_date( year  = CONV i( thursday_year )
                                   month = first_month
                                   day   = first_day ).

    result = ( thursday - year_start ) DIV days_per_week + 1.
  ENDMETHOD.

  METHOD zif_acu_date~iso_year.
    DATA(thursday) = iso_thursday_of( date_value ).
    DATA(thursday_year) = thursday(4).

    result = CONV i( thursday_year ).
  ENDMETHOD.

  METHOD zif_acu_date~is_leap_year.
    result = is_leap( year ).
  ENDMETHOD.

  METHOD zif_acu_date~is_weekend.
    result = xsdbool( weekday_of( date_value ) >= saturday ).
  ENDMETHOD.

  METHOD zif_acu_date~is_between.
    result = xsdbool( date_value BETWEEN date_from AND date_to ).
  ENDMETHOD.

  METHOD zif_acu_date~days_until.
    result = other - date_value.
  ENDMETHOD.

  METHOD zif_acu_date~first_day_of_month.
    result = create( build_date( year  = year
                                 month = month
                                 day   = first_day ) ).
  ENDMETHOD.

  METHOD zif_acu_date~last_day_of_month.
    DATA(last_day) = month_length( year  = year
                                   month = month ).

    result = create( build_date( year  = year
                                 month = month
                                 day   = last_day ) ).
  ENDMETHOD.

  METHOD zif_acu_date~first_day_of_quarter.
    DATA(opening_month) = ( quarter_of( month ) - 1 ) * months_per_quarter + 1.

    result = create( build_date( year  = year
                                 month = opening_month
                                 day   = first_day ) ).
  ENDMETHOD.

  METHOD zif_acu_date~last_day_of_quarter.
    DATA(closing_month) = quarter_of( month ) * months_per_quarter.

    DATA(last_day) = month_length( year  = year
                                   month = closing_month ).

    result = create( build_date( year  = year
                                 month = closing_month
                                 day   = last_day ) ).
  ENDMETHOD.

  METHOD zif_acu_date~first_day_of_year.
    result = create( build_date( year  = year
                                 month = first_month
                                 day   = first_day ) ).
  ENDMETHOD.

  METHOD zif_acu_date~last_day_of_year.
    result = create( build_date( year  = year
                                 month = months_per_year
                                 day   = days_long_month ) ).
  ENDMETHOD.

  METHOD zif_acu_date~first_day_of_week.
    result = create( CONV d( date_value - weekday_of( date_value ) + 1 ) ).
  ENDMETHOD.

  METHOD zif_acu_date~last_day_of_week.
    result = create( CONV d( date_value - weekday_of( date_value ) + days_per_week ) ).
  ENDMETHOD.

  METHOD zif_acu_date~add_days.
    DATA(shifted) = CONV d( date_value + days ).

    IF is_valid( shifted ) = abap_false.
      RAISE EXCEPTION NEW zcx_date( |Moving { date_value DATE = ISO } by { days } days leaves the calendar| ).
    ENDIF.

    result = create( shifted ).
  ENDMETHOD.

  METHOD zif_acu_date~add_months.
    result = shift( months ).
  ENDMETHOD.

  METHOD zif_acu_date~add_months_ultimo.
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

  METHOD zif_acu_date~add_years.
    result = shift( years * months_per_year ).
  ENDMETHOD.

ENDCLASS.

"! Seam to the factory calendar runtime, one method per API call. Kept as
"! thin as possible so that everything above it can be tested with a double.
INTERFACE lif_calendar_runtime.

  METHODS to_factory_date
    IMPORTING date          TYPE d
              rounding      TYPE if_fhc_fcal_runtime=>te_correct_option
    RETURNING VALUE(result) TYPE i
    RAISING   cx_fhc_runtime.

  METHODS to_date
    IMPORTING factory_date  TYPE i
    RETURNING VALUE(result) TYPE d
    RAISING   cx_fhc_runtime.

ENDINTERFACE.


"! The only class that touches CL_FHC_CALENDAR_RUNTIME. The runtime object is
"! obtained with the first call, so an unknown calendar surfaces where an
"! answer is needed, not where the calendar is named.
CLASS lcl_calendar_runtime DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES lif_calendar_runtime.

    METHODS constructor
      IMPORTING id TYPE cl_fhc_calendar_runtime=>ty_fcal_id.

  PRIVATE SECTION.
    DATA id TYPE cl_fhc_calendar_runtime=>ty_fcal_id.
    DATA fcal TYPE REF TO if_fhc_fcal_runtime.

    METHODS connect
      RETURNING VALUE(result) TYPE REF TO if_fhc_fcal_runtime
      RAISING   cx_fhc_runtime.

ENDCLASS.


"! One factory calendar. Every question is answered with the two conversions
"! between calendar dates and factory dates: a factory date counts the working
"! days of the calendar, so working day arithmetic is plain integer arithmetic
"! on it. Foreign exceptions are wrapped here, at the boundary.
CLASS lcl_calendar DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_acu_calendar.

    CLASS-METHODS create
      IMPORTING id            TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_acu_calendar
      RAISING   zcx_date.

    METHODS constructor
      IMPORTING runtime TYPE REF TO lif_calendar_runtime.

  PRIVATE SECTION.
    " Length of CL_FHC_CALENDAR_RUNTIME=>TY_FCAL_ID.
    CONSTANTS id_length TYPE i VALUE 32.

    DATA runtime TYPE REF TO lif_calendar_runtime.

    METHODS factory_date
      IMPORTING date          TYPE d
                rounding      TYPE if_fhc_fcal_runtime=>te_correct_option
      RETURNING VALUE(result) TYPE i
      RAISING   zcx_date.

    METHODS calendar_date
      IMPORTING factory_date  TYPE i
      RETURNING VALUE(result) TYPE REF TO zif_acu_date
      RAISING   zcx_date.

ENDCLASS.


CLASS lcl_calendar_runtime IMPLEMENTATION.

  METHOD constructor.
    me->id = id.
  ENDMETHOD.

  METHOD connect.
    IF fcal IS NOT BOUND.
      fcal = cl_fhc_calendar_runtime=>create_factorycalendar_runtime( id ).
    ENDIF.

    result = fcal.
  ENDMETHOD.

  METHOD lif_calendar_runtime~to_factory_date.
    result = connect( )->convert_date_to_factorydate( iv_date           = date
                                                      iv_correct_option = rounding ).
  ENDMETHOD.

  METHOD lif_calendar_runtime~to_date.
    result = connect( )->convert_factorydate_to_date( factory_date ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_calendar IMPLEMENTATION.

  METHOD create.
    DATA(trimmed) = condense( id ).

    IF trimmed IS INITIAL.
      RAISE EXCEPTION NEW zcx_date( `Factory calendar identifier is empty` ).
    ENDIF.

    IF strlen( trimmed ) > id_length.
      RAISE EXCEPTION NEW zcx_date( |Factory calendar identifier { trimmed } exceeds { id_length } characters| ).
    ENDIF.

    result = NEW lcl_calendar( NEW lcl_calendar_runtime( CONV #( trimmed ) ) ).
  ENDMETHOD.

  METHOD constructor.
    me->runtime = runtime.
  ENDMETHOD.

  METHOD factory_date.
    TRY.
        result = runtime->to_factory_date( date     = date
                                           rounding = rounding ).
      CATCH cx_fhc_runtime INTO DATA(error).
        RAISE EXCEPTION NEW zcx_date( text     = |{ date DATE = ISO }: { error->get_text( ) }|
                                      previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD calendar_date.
    TRY.
        result = lcl_date=>create( runtime->to_date( factory_date ) ).
      CATCH cx_fhc_runtime INTO DATA(error).
        RAISE EXCEPTION NEW zcx_date( text     = |Factory date { factory_date }: { error->get_text( ) }|
                                      previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_acu_calendar~is_working_day.
    DATA(start) = lcl_date=>create( date )->as_date( ).

    DATA(on_or_after) = factory_date( date     = start
                                      rounding = if_fhc_fcal_runtime=>gc_correct_option_plus ).

    DATA(working_day) = calendar_date( on_or_after )->as_date( ).

    result = xsdbool( working_day = start ).
  ENDMETHOD.

  METHOD zif_acu_calendar~add_working_days.
    DATA(start) = lcl_date=>create( date ).

    IF days = 0.
      result = start.
      RETURN.
    ENDIF.

    " The start date is never counted: moving forward starts from the last
    " working day on or before it, moving backwards from the first working day
    " on or after it. A non-working start therefore reaches the neighbouring
    " working day with a single step, like a spreadsheet WORKDAY function.
    DATA(rounding) = COND #( WHEN days > 0 THEN if_fhc_fcal_runtime=>gc_correct_option_minus
                             ELSE if_fhc_fcal_runtime=>gc_correct_option_plus ).

    DATA(anchor) = factory_date( date     = start->as_date( )
                                 rounding = rounding ).

    result = calendar_date( anchor + days ).
  ENDMETHOD.

  METHOD zif_acu_calendar~next_working_day.
    result = zif_acu_calendar~add_working_days( date = date
                                                days = 1 ).
  ENDMETHOD.

  METHOD zif_acu_calendar~previous_working_day.
    result = zif_acu_calendar~add_working_days( date = date
                                                days = -1 ).
  ENDMETHOD.

ENDCLASS.
