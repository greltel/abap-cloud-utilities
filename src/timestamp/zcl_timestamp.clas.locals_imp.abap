" ZCL_TIMESTAMP - Local Types (CCIMP)
*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
"! Seam to the time zone customizing, one method per question. Kept as thin
"! as possible so that everything above it can be tested with a double.
INTERFACE lif_time_zones.

  METHODS exists
    IMPORTING zone          TYPE tznzone
    RETURNING VALUE(result) TYPE abap_bool.

ENDINTERFACE.


"! The only class that reads the time zone customizing. A zone found once is
"! remembered for the rest of the session, so a loop over time stamps costs
"! one database access per zone, not one per stamp.
CLASS lcl_time_zones DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES lif_time_zones.

  PRIVATE SECTION.
    CLASS-DATA known TYPE HASHED TABLE OF tznzone WITH UNIQUE KEY table_line.

ENDCLASS.


"! Turns the text a caller passes into the time zone key the kernel expects.
"! Surrounding blanks and lower case are tolerated; anything that cannot be a
"! key is rejected before the customizing is asked.
CLASS lcl_zone DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS resolve
      IMPORTING zone          TYPE csequence
                time_zones    TYPE REF TO lif_time_zones
      RETURNING VALUE(result) TYPE tznzone
      RAISING   zcx_timestamp.

  PRIVATE SECTION.
    " Length of the time zone key, TZNZONE.
    CONSTANTS key_length TYPE i VALUE 6.

ENDCLASS.


"! Validity of a date and a time of day as the kernel expects them, checked
"! here so that a rejected value explains itself instead of surfacing as a
"! kernel exception.
CLASS lcl_date_time_check DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS is_valid_date
      IMPORTING date          TYPE d
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS is_valid_time
      IMPORTING time          TYPE t
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    CONSTANTS digits TYPE string VALUE `0123456789`.
    CONSTANTS first_year TYPE i VALUE 1.
    CONSTANTS first_month TYPE i VALUE 1.
    CONSTANTS first_day TYPE i VALUE 1.
    CONSTANTS months_per_year TYPE i VALUE 12.
    CONSTANTS hours_per_day TYPE i VALUE 24.
    CONSTANTS minutes_per_hour TYPE i VALUE 60.
    CONSTANTS seconds_per_minute TYPE i VALUE 60.
    CONSTANTS february TYPE i VALUE 2.
    CONSTANTS april TYPE i VALUE 4.
    CONSTANTS june TYPE i VALUE 6.
    CONSTANTS september TYPE i VALUE 9.
    CONSTANTS november TYPE i VALUE 11.
    CONSTANTS days_short_month TYPE i VALUE 30.
    CONSTANTS days_long_month TYPE i VALUE 31.
    CONSTANTS days_february TYPE i VALUE 28.
    CONSTANTS days_february_leap TYPE i VALUE 29.
    CONSTANTS gregorian_cycle TYPE i VALUE 4.
    CONSTANTS gregorian_century TYPE i VALUE 100.
    CONSTANTS gregorian_long_cycle TYPE i VALUE 400.

    CLASS-METHODS is_leap
      IMPORTING year          TYPE i
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS month_length
      IMPORTING year          TYPE i
                month         TYPE i
      RETURNING VALUE(result) TYPE i.

ENDCLASS.


"! The only class that runs the kernel conversions between the UTC time line
"! and the wall clock of a time zone, in both directions, and the only one
"! that moves a point in time along the time line. The kernel's own refusals
"! are turned into the exception of this utility here, at the boundary.
"! <p>The kernel is only ever asked about whole seconds: the fraction of the
"! second is split off by arithmetic on the time line before a conversion
"! and put back afterwards, so no conversion ever has to round or cut.</p>
CLASS lcl_time_line DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CONSTANTS utc TYPE tznzone VALUE 'UTC'.

    TYPES:
      BEGIN OF ty_wall_clock,
        date               TYPE d,
        time               TYPE t,
        is_daylight_saving TYPE abap_bool,
      END OF ty_wall_clock.

    "! Wall clock of the zone at that point in time, in whole seconds - the
    "! fraction of the second is dropped, never rounded.
    CLASS-METHODS to_wall_clock
      IMPORTING instant       TYPE utclong
                zone          TYPE tznzone
      RETURNING VALUE(result) TYPE ty_wall_clock
      RAISING   zcx_timestamp.

    "! Point in time at which the wall clock of the zone shows the date and
    "! time.
    CLASS-METHODS to_instant
      IMPORTING date          TYPE d
                time          TYPE t
                zone          TYPE tznzone
      RETURNING VALUE(result) TYPE utclong
      RAISING   zcx_timestamp.

    "! Wall clock of UTC at that point in time, in whole seconds. UTC is
    "! always known and a point in time always has a date, so this cannot be
    "! refused.
    CLASS-METHODS utc_wall_clock
      IMPORTING instant       TYPE utclong
      RETURNING VALUE(result) TYPE ty_wall_clock.

    "! Point in time at which UTC shows a date and time that are known to be
    "! valid, for example because the kernel produced them.
    CLASS-METHODS utc_instant
      IMPORTING date          TYPE d
                time          TYPE t
      RETURNING VALUE(result) TYPE utclong.

    "! The point in time cut back to its whole second, never later than the
    "! point in time itself.
    CLASS-METHODS whole_second
      IMPORTING instant       TYPE utclong
      RETURNING VALUE(result) TYPE utclong.

    "! Fraction of the second of the point in time, 0 &lt;= fraction &lt; 1.
    CLASS-METHODS fraction_of
      IMPORTING instant       TYPE utclong
      RETURNING VALUE(result) TYPE decfloat34.

    "! The point in time moved along the time line, checked against its ends
    "! before the kernel is asked.
    CLASS-METHODS shifted
      IMPORTING instant       TYPE utclong
                seconds       TYPE decfloat34
      RETURNING VALUE(result) TYPE utclong
      RAISING   zcx_timestamp.

ENDCLASS.


"! Reads and writes the RFC 3339 profile of ISO 8601: a calendar date, a time
"! of day with an optional fraction, and a zone designator - Z or an offset.
"! Nothing here touches the time zone customizing; an offset is plain
"! arithmetic on the UTC time line.
CLASS lcl_iso_format DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_parts,
        date           TYPE d,
        time           TYPE t,
        "! From 0 included to 1 excluded
        fraction       TYPE decfloat34,
        "! Wall clock minus UTC
        offset_seconds TYPE i,
      END OF ty_parts.

    CLASS-METHODS parse
      IMPORTING text          TYPE csequence
      RETURNING VALUE(result) TYPE ty_parts
      RAISING   zcx_timestamp.

    CLASS-METHODS render
      IMPORTING parts         TYPE ty_parts
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_tokens,
        year           TYPE string,
        month          TYPE string,
        day            TYPE string,
        hour           TYPE string,
        minute         TYPE string,
        second         TYPE string,
        fraction       TYPE string,
        zulu           TYPE string,
        sign           TYPE string,
        offset_hours   TYPE string,
        offset_minutes TYPE string,
      END OF ty_tokens.

    " Assembled from its parts. ABAP compiles PCRE in extended mode, so the
    " blank that may replace the T is spelled as \x20.
    CONSTANTS date_pattern TYPE string VALUE `^(\d{4})-(\d{2})-(\d{2})`.
    CONSTANTS separator_pattern TYPE string VALUE `[Tt\x20]`.
    CONSTANTS time_pattern TYPE string VALUE `(\d{2}):(\d{2}):(\d{2})`.
    CONSTANTS fraction_pattern TYPE string VALUE `(?:\.(\d{1,7}))?`.
    CONSTANTS designator_pattern TYPE string VALUE `(?:([Zz])|([+-])(\d{2})(?::?(\d{2}))?)`.
    CONSTANTS end_pattern TYPE string VALUE `$`.

    CONSTANTS zulu TYPE string VALUE `Z`.
    CONSTANTS plus TYPE string VALUE `+`.
    CONSTANTS minus TYPE string VALUE `-`.
    CONSTANTS separator TYPE string VALUE `T`.
    CONSTANTS fraction_separator TYPE string VALUE `.`.
    CONSTANTS offset_separator TYPE string VALUE `:`.
    CONSTANTS zero TYPE string VALUE `0`.
    CONSTANTS fraction_digits TYPE i VALUE 7.
    CONSTANTS ticks_per_second TYPE i VALUE 10000000.
    CONSTANTS hours_per_day TYPE i VALUE 24.
    CONSTANTS minutes_per_hour TYPE i VALUE 60.
    CONSTANTS seconds_per_minute TYPE i VALUE 60.
    CONSTANTS seconds_per_hour TYPE i VALUE 3600.

    CLASS-METHODS tokenize
      IMPORTING text          TYPE csequence
      RETURNING VALUE(result) TYPE ty_tokens
      RAISING   zcx_timestamp.

    CLASS-METHODS offset_of
      IMPORTING tokens        TYPE ty_tokens
                text          TYPE csequence
      RETURNING VALUE(result) TYPE i
      RAISING   zcx_timestamp.

    CLASS-METHODS fraction_text
      IMPORTING fraction      TYPE decfloat34
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS designator
      IMPORTING offset_seconds TYPE i
      RETURNING VALUE(result)  TYPE string.

ENDCLASS.


"! Immutable point in time. The value is checked once on construction, so
"! every method below can trust its own state. Arithmetic and comparison are
"! native utclong operations; anything that involves a time zone is handed
"! to the local view.
CLASS lcl_timestamp DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_timestamp.

    CLASS-METHODS create
      IMPORTING instant       TYPE utclong
                time_zones    TYPE REF TO lif_time_zones
      RETURNING VALUE(result) TYPE REF TO zif_timestamp
      RAISING   zcx_timestamp.

    METHODS constructor
      IMPORTING instant    TYPE utclong
                time_zones TYPE REF TO lif_time_zones.

  PRIVATE SECTION.
    CONSTANTS unix_epoch TYPE utclong VALUE '1970-01-01 00:00:00.0000000'.
    " Kept as decfloat34 so that the multiplication with the caller's count
    " happens in decfloat34 and can never overflow an integer.
    CONSTANTS seconds_per_minute TYPE decfloat34 VALUE 60.
    CONSTANTS seconds_per_hour TYPE decfloat34 VALUE 3600.
    CONSTANTS seconds_per_day TYPE decfloat34 VALUE 86400.

    DATA instant TYPE utclong.
    DATA time_zones TYPE REF TO lif_time_zones.

    METHODS utc_parts
      RETURNING VALUE(result) TYPE lcl_iso_format=>ty_parts.

    METHODS moved
      IMPORTING seconds       TYPE decfloat34
      RETURNING VALUE(result) TYPE REF TO zif_timestamp
      RAISING   zcx_timestamp.

ENDCLASS.


"! One point in time seen from one time zone. The wall clock is read once on
"! construction; the borders of the day are derived from it by going back
"! through the kernel, so a day that is 23 or 25 hours long around a daylight
"! saving switch comes out right.
CLASS lcl_local DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_timestamp_local.

    METHODS constructor
      IMPORTING instant    TYPE utclong
                zone       TYPE tznzone
                time_zones TYPE REF TO lif_time_zones
      RAISING   zcx_timestamp.

  PRIVATE SECTION.
    CONSTANTS midnight TYPE t VALUE '000000'.
    CONSTANTS last_second_of_day TYPE t VALUE '235959'.
    CONSTANTS last_tick_of_second TYPE decfloat34 VALUE '0.9999999'.

    DATA instant TYPE utclong.
    DATA zone TYPE tznzone.
    DATA wall_clock TYPE lcl_time_line=>ty_wall_clock.
    DATA fraction TYPE decfloat34.
    DATA offset_seconds TYPE i.
    DATA time_zones TYPE REF TO lif_time_zones.

ENDCLASS.


"! Composition root of the utility: wires the time zone customizing into
"! every point in time it creates. The facade uses the production wiring,
"! tests pass a double.
CLASS lcl_factory DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS create
      RETURNING VALUE(result) TYPE REF TO lcl_factory.

    METHODS constructor
      IMPORTING time_zones TYPE REF TO lif_time_zones.

    METHODS for_utclong
      IMPORTING instant       TYPE utclong
      RETURNING VALUE(result) TYPE REF TO zif_timestamp
      RAISING   zcx_timestamp.

    METHODS for_timestamp
      IMPORTING stamp         TYPE timestampl
      RETURNING VALUE(result) TYPE REF TO zif_timestamp
      RAISING   zcx_timestamp.

    METHODS for_unix
      IMPORTING seconds       TYPE int8
      RETURNING VALUE(result) TYPE REF TO zif_timestamp
      RAISING   zcx_timestamp.

    METHODS for_iso
      IMPORTING text          TYPE csequence
      RETURNING VALUE(result) TYPE REF TO zif_timestamp
      RAISING   zcx_timestamp.

    METHODS for_date_time
      IMPORTING date          TYPE d
                time          TYPE t
                zone          TYPE csequence
      RETURNING VALUE(result) TYPE REF TO zif_timestamp
      RAISING   zcx_timestamp.

    METHODS is_known_zone
      IMPORTING zone          TYPE csequence
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    CONSTANTS unix_epoch TYPE utclong VALUE '1970-01-01 00:00:00.0000000'.
    " Divides YYYYMMDDhhmmss into its date and its time.
    CONSTANTS time_digits TYPE int8 VALUE 1000000.
    CONSTANTS date_length TYPE i VALUE 8.
    CONSTANTS time_length TYPE i VALUE 6.

    DATA time_zones TYPE REF TO lif_time_zones.

ENDCLASS.


CLASS lcl_time_zones IMPLEMENTATION.

  METHOD lif_time_zones~exists.
    IF line_exists( known[ table_line = zone ] ).
      result = abap_true.
      RETURN.
    ENDIF.

    SELECT SINGLE FROM i_timezone
      FIELDS timezoneid
      WHERE timezoneid = @zone
      INTO @DATA(found).

    IF found IS INITIAL.
      RETURN.
    ENDIF.

    INSERT found INTO TABLE known.
    result = abap_true.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_zone IMPLEMENTATION.

  METHOD resolve.
    DATA(key) = to_upper( condense( zone ) ).

    IF key IS INITIAL.
      RAISE EXCEPTION NEW zcx_timestamp( `Time zone is empty` ).
    ENDIF.

    DATA(fits_key) = xsdbool( strlen( key ) <= key_length ).

    IF fits_key = abap_false OR time_zones->exists( CONV #( key ) ) = abap_false.
      RAISE EXCEPTION NEW zcx_timestamp( |Time zone { key } is not known to the system| ).
    ENDIF.

    result = key.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_date_time_check IMPLEMENTATION.

  METHOD is_valid_date.
    IF date IS INITIAL OR date CN digits.
      RETURN.
    ENDIF.

    DATA(year_part) = date(4).
    DATA(month_part) = date+4(2).
    DATA(day_part) = date+6(2).

    DATA(year) = CONV i( year_part ).
    DATA(month) = CONV i( month_part ).
    DATA(day) = CONV i( day_part ).

    DATA(year_fits) = xsdbool( year >= first_year ).
    DATA(month_fits) = xsdbool( month BETWEEN first_month AND months_per_year ).

    IF year_fits = abap_false OR month_fits = abap_false.
      RETURN.
    ENDIF.

    DATA(last_day) = month_length( year  = year
                                   month = month ).

    result = xsdbool( day BETWEEN first_day AND last_day ).
  ENDMETHOD.

  METHOD is_valid_time.
    IF time CN digits.
      RETURN.
    ENDIF.

    DATA(hour_part) = time(2).
    DATA(minute_part) = time+2(2).
    DATA(second_part) = time+4(2).

    DATA(hour_fits) = xsdbool( CONV i( hour_part ) < hours_per_day ).
    DATA(minute_fits) = xsdbool( CONV i( minute_part ) < minutes_per_hour ).
    DATA(second_fits) = xsdbool( CONV i( second_part ) < seconds_per_minute ).

    result = xsdbool( hour_fits = abap_true AND minute_fits = abap_true AND second_fits = abap_true ).
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

ENDCLASS.


CLASS lcl_time_line IMPLEMENTATION.

  METHOD to_wall_clock.
    DATA(second) = whole_second( instant ).

    TRY.
        CONVERT UTCLONG second
          INTO DATE result-date TIME result-time DAYLIGHT SAVING TIME result-is_daylight_saving
          TIME ZONE zone.
      CATCH cx_sy_conversion_no_date_time INTO DATA(error).
        RAISE EXCEPTION NEW zcx_timestamp( text     = |{ instant } cannot be read in time zone { zone }|
                                           previous = error ).
    ENDTRY.

    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_timestamp( |{ instant } cannot be read in time zone { zone }| ).
    ENDIF.
  ENDMETHOD.

  METHOD to_instant.
    DATA(date_is_valid) = lcl_date_time_check=>is_valid_date( date ).
    DATA(time_is_valid) = lcl_date_time_check=>is_valid_time( time ).

    IF date_is_valid = abap_false OR time_is_valid = abap_false.
      RAISE EXCEPTION NEW zcx_timestamp( |{ date DATE = RAW } { time TIME = RAW } is not a date and time| ).
    ENDIF.

    DATA(wall_clock_text) = |{ date DATE = ISO } { time TIME = ISO }|.

    TRY.
        CONVERT DATE date TIME time TIME ZONE zone INTO UTCLONG result.
      CATCH cx_sy_conversion_no_date_time INTO DATA(error).
        RAISE EXCEPTION NEW zcx_timestamp( text     = |{ wall_clock_text } does not exist in time zone { zone }|
                                           previous = error ).
    ENDTRY.

    IF sy-subrc <> 0 OR result IS INITIAL.
      RAISE EXCEPTION NEW zcx_timestamp( |{ wall_clock_text } does not exist in time zone { zone }| ).
    ENDIF.
  ENDMETHOD.

  METHOD utc_wall_clock.
    DATA(second) = whole_second( instant ).

    CONVERT UTCLONG second INTO DATE result-date TIME result-time TIME ZONE utc.
  ENDMETHOD.

  METHOD utc_instant.
    DATA instant TYPE utclong.

    CONVERT DATE date TIME time TIME ZONE utc INTO UTCLONG instant.

    result = instant.
  ENDMETHOD.

  METHOD whole_second.
    result = utclong_add( val     = instant
                          seconds = 0 - fraction_of( instant ) ).
  ENDMETHOD.

  METHOD fraction_of.
    " Measured from the start of the time line, so the fraction is plain
    " arithmetic and no conversion has to decide how to treat it.
    DATA(since_start) = utclong_diff( high = instant
                                      low  = cl_abap_utclong=>min ).

    result = since_start - floor( since_start ).
  ENDMETHOD.

  METHOD shifted.
    DATA(room_ahead) = utclong_diff( high = cl_abap_utclong=>max
                                     low  = instant ).
    DATA(room_behind) = utclong_diff( high = instant
                                      low  = cl_abap_utclong=>min ).

    DATA(leaves_end) = xsdbool( seconds > room_ahead ).
    DATA(leaves_start) = xsdbool( seconds + room_behind < 0 ).

    IF leaves_end = abap_true OR leaves_start = abap_true.
      RAISE EXCEPTION NEW zcx_timestamp( |Moving { instant } by { seconds } seconds leaves the time line| ).
    ENDIF.

    result = utclong_add( val     = instant
                          seconds = seconds ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_iso_format IMPLEMENTATION.

  METHOD parse.
    " A text field loses its trailing blanks on the way to a string, so the
    " end anchor of the pattern sees the end of the text.
    DATA(candidate) = CONV string( text ).
    DATA(tokens) = tokenize( candidate ).

    result-date = |{ tokens-year }{ tokens-month }{ tokens-day }|.
    result-time = |{ tokens-hour }{ tokens-minute }{ tokens-second }|.

    DATA(date_is_valid) = lcl_date_time_check=>is_valid_date( result-date ).
    DATA(time_is_valid) = lcl_date_time_check=>is_valid_time( result-time ).

    IF date_is_valid = abap_false OR time_is_valid = abap_false.
      RAISE EXCEPTION NEW zcx_timestamp( |{ candidate } does not describe a date and time| ).
    ENDIF.

    IF tokens-fraction IS NOT INITIAL.
      result-fraction = |{ zero }{ fraction_separator }{ tokens-fraction }|.
    ENDIF.

    result-offset_seconds = offset_of( tokens = tokens
                                       text   = candidate ).
  ENDMETHOD.

  METHOD tokenize.
    DATA(pattern) = date_pattern && separator_pattern && time_pattern && fraction_pattern
                    && designator_pattern && end_pattern.

    FIND PCRE pattern IN text
      SUBMATCHES result-year result-month result-day result-hour result-minute result-second
                 result-fraction result-zulu result-sign result-offset_hours result-offset_minutes.

    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    " A well formed text without designator is a local time, not a point in
    " time - the most common mistake gets its own explanation.
    DATA(local_pattern) = date_pattern && separator_pattern && time_pattern && fraction_pattern && end_pattern.

    FIND PCRE local_pattern IN text.

    IF sy-subrc = 0.
      RAISE EXCEPTION NEW zcx_timestamp(   |{ text } carries no zone designator - expected Z or an offset like +02:00; a local time needs for_date_time| ).
    ENDIF.

    RAISE EXCEPTION NEW zcx_timestamp( |{ text } is not an ISO 8601 / RFC 3339 time stamp| ).
  ENDMETHOD.

  METHOD offset_of.
    IF tokens-sign IS INITIAL.
      RETURN.
    ENDIF.

    DATA(hours) = CONV i( tokens-offset_hours ).
    DATA(minutes) = COND i( WHEN tokens-offset_minutes IS INITIAL THEN 0
                            ELSE CONV i( tokens-offset_minutes ) ).

    IF hours >= hours_per_day OR minutes >= minutes_per_hour.
      RAISE EXCEPTION NEW zcx_timestamp( |{ text } carries an offset that is not a time zone offset| ).
    ENDIF.

    result = hours * seconds_per_hour + minutes * seconds_per_minute.

    IF tokens-sign = minus.
      result = 0 - result.
    ENDIF.
  ENDMETHOD.

  METHOD render.
    result = |{ parts-date DATE = ISO }{ separator }{ parts-time TIME = ISO }| &&
             |{ fraction_text( parts-fraction ) }{ designator( parts-offset_seconds ) }|.
  ENDMETHOD.

  METHOD fraction_text.
    IF fraction IS INITIAL.
      RETURN.
    ENDIF.

    DATA(ticks) = CONV i( ticks_per_second * fraction ).
    DATA(digits) = |{ ticks WIDTH = fraction_digits PAD = '0' ALIGN = RIGHT }|.
    DATA(significant_digits) = shift_right( val = digits
                                            sub = zero ).

    result = |{ fraction_separator }{ significant_digits }|.
  ENDMETHOD.

  METHOD designator.
    IF offset_seconds = 0.
      result = zulu.
      RETURN.
    ENDIF.

    DATA(magnitude) = abs( offset_seconds ).
    DATA(hours) = magnitude DIV seconds_per_hour.
    DATA(minutes) = ( magnitude MOD seconds_per_hour ) DIV seconds_per_minute.
    DATA(sign) = COND string( WHEN offset_seconds < 0 THEN minus
                              ELSE plus ).

    result = |{ sign }{ hours WIDTH = 2 PAD = '0' ALIGN = RIGHT }| &&
             |{ offset_separator }{ minutes WIDTH = 2 PAD = '0' ALIGN = RIGHT }|.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_timestamp IMPLEMENTATION.

  METHOD create.
    IF instant IS INITIAL.
      RAISE EXCEPTION NEW zcx_timestamp( `An initial value is not a point in time` ).
    ENDIF.

    result = NEW lcl_timestamp( instant    = instant
                                time_zones = time_zones ).
  ENDMETHOD.

  METHOD constructor.
    me->instant = instant.
    me->time_zones = time_zones.
  ENDMETHOD.

  METHOD utc_parts.
    DATA(wall_clock) = lcl_time_line=>utc_wall_clock( instant ).

    result = VALUE #( date     = wall_clock-date
                      time     = wall_clock-time
                      fraction = lcl_time_line=>fraction_of( instant ) ).
  ENDMETHOD.

  METHOD moved.
    DATA(target) = lcl_time_line=>shifted( instant = instant
                                           seconds = seconds ).

    result = NEW lcl_timestamp( instant    = target
                                time_zones = time_zones ).
  ENDMETHOD.

  METHOD zif_timestamp~as_utclong.
    result = instant.
  ENDMETHOD.

  METHOD zif_timestamp~as_timestamp.
    DATA(parts) = utc_parts( ).

    " The whole seconds are digits already; the fraction is added as a number
    " so that the packed value keeps every one of its seven decimals.
    result = CONV timestampl( |{ parts-date DATE = RAW }{ parts-time TIME = RAW }| ) + parts-fraction.
  ENDMETHOD.

  METHOD zif_timestamp~as_short_timestamp.
    DATA(parts) = utc_parts( ).

    result = |{ parts-date DATE = RAW }{ parts-time TIME = RAW }|.
  ENDMETHOD.

  METHOD zif_timestamp~as_unix_seconds.
    result = floor( utclong_diff( high = instant
                                  low  = unix_epoch ) ).
  ENDMETHOD.

  METHOD zif_timestamp~as_iso.
    result = lcl_iso_format=>render( utc_parts( ) ).
  ENDMETHOD.

  METHOD zif_timestamp~in_zone.
    DATA(key) = lcl_zone=>resolve( zone       = zone
                                   time_zones = time_zones ).

    result = NEW lcl_local( instant    = instant
                            zone       = key
                            time_zones = time_zones ).
  ENDMETHOD.

  METHOD zif_timestamp~truncate_to_seconds.
    result = NEW lcl_timestamp( instant    = lcl_time_line=>whole_second( instant )
                                time_zones = time_zones ).
  ENDMETHOD.

  METHOD zif_timestamp~add_seconds.
    result = moved( CONV decfloat34( seconds ) ).
  ENDMETHOD.

  METHOD zif_timestamp~add_minutes.
    DATA(seconds) = minutes * seconds_per_minute.

    result = moved( seconds ).
  ENDMETHOD.

  METHOD zif_timestamp~add_hours.
    DATA(seconds) = hours * seconds_per_hour.

    result = moved( seconds ).
  ENDMETHOD.

  METHOD zif_timestamp~add_days.
    DATA(seconds) = days * seconds_per_day.

    result = moved( seconds ).
  ENDMETHOD.

  METHOD zif_timestamp~seconds_until.
    IF other IS INITIAL.
      RAISE EXCEPTION NEW zcx_timestamp( `An initial value is not a point in time` ).
    ENDIF.

    result = utclong_diff( high = other
                           low  = instant ).
  ENDMETHOD.

  METHOD zif_timestamp~equals.
    result = xsdbool( instant = other ).
  ENDMETHOD.

  METHOD zif_timestamp~is_before.
    result = xsdbool( instant < other ).
  ENDMETHOD.

  METHOD zif_timestamp~is_after.
    result = xsdbool( instant > other ).
  ENDMETHOD.

  METHOD zif_timestamp~is_between.
    result = xsdbool( instant BETWEEN time_from AND time_to ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_local IMPLEMENTATION.

  METHOD constructor.
    me->instant = instant.
    me->zone = zone.
    me->time_zones = time_zones.

    wall_clock = lcl_time_line=>to_wall_clock( instant = instant
                                               zone    = zone ).
    fraction = lcl_time_line=>fraction_of( instant ).

    " Read as UTC, the wall clock lies exactly the offset of the zone away
    " from the point in time.
    DATA(wall_clock_as_utc) = lcl_time_line=>utc_instant( date = wall_clock-date
                                                          time = wall_clock-time ).

    offset_seconds = utclong_diff( high = wall_clock_as_utc
                                   low  = lcl_time_line=>whole_second( instant ) ).
  ENDMETHOD.

  METHOD zif_timestamp_local~zone.
    result = zone.
  ENDMETHOD.

  METHOD zif_timestamp_local~date.
    result = wall_clock-date.
  ENDMETHOD.

  METHOD zif_timestamp_local~time.
    result = wall_clock-time.
  ENDMETHOD.

  METHOD zif_timestamp_local~is_daylight_saving.
    result = wall_clock-is_daylight_saving.
  ENDMETHOD.

  METHOD zif_timestamp_local~utc_offset_seconds.
    result = offset_seconds.
  ENDMETHOD.

  METHOD zif_timestamp_local~as_iso.
    result = lcl_iso_format=>render( VALUE #( date           = wall_clock-date
                                              time           = wall_clock-time
                                              fraction       = fraction
                                              offset_seconds = offset_seconds ) ).
  ENDMETHOD.

  METHOD zif_timestamp_local~start_of_day.
    DATA(first_second) = lcl_time_line=>to_instant( date = wall_clock-date
                                                    time = midnight
                                                    zone = zone ).

    result = lcl_timestamp=>create( instant    = first_second
                                    time_zones = time_zones ).
  ENDMETHOD.

  METHOD zif_timestamp_local~end_of_day.
    DATA(last_second) = lcl_time_line=>to_instant( date = wall_clock-date
                                                   time = last_second_of_day
                                                   zone = zone ).

    DATA(last_tick) = lcl_time_line=>shifted( instant = last_second
                                              seconds = last_tick_of_second ).

    result = lcl_timestamp=>create( instant    = last_tick
                                    time_zones = time_zones ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_factory IMPLEMENTATION.

  METHOD create.
    result = NEW lcl_factory( NEW lcl_time_zones( ) ).
  ENDMETHOD.

  METHOD constructor.
    me->time_zones = time_zones.
  ENDMETHOD.

  METHOD for_utclong.
    result = lcl_timestamp=>create( instant    = instant
                                    time_zones = time_zones ).
  ENDMETHOD.

  METHOD for_timestamp.
    IF stamp <= 0.
      RAISE EXCEPTION NEW zcx_timestamp( |{ stamp } is not a UTC time stamp| ).
    ENDIF.

    DATA(whole_seconds) = CONV int8( trunc( stamp ) ).
    DATA(date_number) = whole_seconds DIV time_digits.
    DATA(time_number) = whole_seconds MOD time_digits.

    DATA(date) = CONV d( |{ date_number WIDTH = date_length PAD = '0' ALIGN = RIGHT }| ).
    DATA(time) = CONV t( |{ time_number WIDTH = time_length PAD = '0' ALIGN = RIGHT }| ).

    DATA(date_is_valid) = lcl_date_time_check=>is_valid_date( date ).
    DATA(time_is_valid) = lcl_date_time_check=>is_valid_time( time ).

    IF date_is_valid = abap_false OR time_is_valid = abap_false.
      RAISE EXCEPTION NEW zcx_timestamp( |{ stamp } is not a UTC time stamp| ).
    ENDIF.

    DATA(whole_second) = lcl_time_line=>utc_instant( date = date
                                                     time = time ).

    result = lcl_timestamp=>create( instant    = utclong_add( val     = whole_second
                                                              seconds = frac( stamp ) )
                                    time_zones = time_zones ).
  ENDMETHOD.

  METHOD for_unix.
    TRY.
        DATA(instant) = lcl_time_line=>shifted( instant = unix_epoch
                                                seconds = CONV #( seconds ) ).

        result = lcl_timestamp=>create( instant    = instant
                                        time_zones = time_zones ).
      CATCH zcx_timestamp INTO DATA(error).
        RAISE EXCEPTION NEW zcx_timestamp( text     = |Unix time { seconds } leaves the time line|
                                           previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD for_iso.
    DATA(parts) = lcl_iso_format=>parse( text ).

    DATA(wall_clock_as_utc) = lcl_time_line=>utc_instant( date = parts-date
                                                          time = parts-time ).

    " The designator says how far the wall clock ran ahead of UTC, so the
    " point in time lies that far back; the fraction goes on top.
    DATA(instant) = lcl_time_line=>shifted( instant = wall_clock_as_utc
                                            seconds = parts-fraction - parts-offset_seconds ).

    result = lcl_timestamp=>create( instant    = instant
                                    time_zones = time_zones ).
  ENDMETHOD.

  METHOD for_date_time.
    DATA(key) = lcl_zone=>resolve( zone       = zone
                                   time_zones = time_zones ).

    DATA(instant) = lcl_time_line=>to_instant( date = date
                                               time = time
                                               zone = key ).

    result = lcl_timestamp=>create( instant    = instant
                                    time_zones = time_zones ).
  ENDMETHOD.

  METHOD is_known_zone.
    TRY.
        lcl_zone=>resolve( zone       = zone
                           time_zones = time_zones ).
        result = abap_true.
      CATCH zcx_timestamp.
        result = abap_false.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
