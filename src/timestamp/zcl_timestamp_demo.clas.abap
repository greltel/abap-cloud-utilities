" ZCL_TIMESTAMP_DEMO
"! <p class="shorttext synchronized" lang="EN">Time stamp utility demo</p>
"! Runnable showcase for {@link zcl_timestamp}. Start it with F9 in ADT.
"! <p>The demo is the composition root, so this is the only place that reads
"! the clock and the user's time zone - the utility itself never does.</p>
CLASS zcl_timestamp_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS utc TYPE string VALUE `UTC`.
    CONSTANTS central_europe TYPE string VALUE `CET`.
    CONSTANTS eastern_europe TYPE string VALUE `EET`.
    CONSTANTS payload_stamp TYPE string VALUE `2026-09-15T14:30:00.25+02:00`.
    CONSTANTS compact_stamp TYPE string VALUE `2026-09-15 12:30:00Z`.
    CONSTANTS local_stamp TYPE string VALUE `2026-09-15T14:30:00`.
    CONSTANTS spring_switch TYPE d VALUE '20260329'.
    CONSTANTS autumn_switch TYPE d VALUE '20261025'.
    CONSTANTS half_past_two TYPE t VALUE '023000'.
    CONSTANTS noon TYPE t VALUE '120000'.
    CONSTANTS feb_30 TYPE d VALUE '20250230'.
    CONSTANTS ninety TYPE i VALUE 90.
    CONSTANTS one_week TYPE i VALUE 7.

    METHODS show_conversions
      IMPORTING now TYPE REF TO zif_timestamp
                out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_wall_clocks
      IMPORTING now       TYPE REF TO zif_timestamp
                user_zone TYPE csequence
                out       TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_timestamp.

    METHODS show_wall_clock
      IMPORTING now  TYPE REF TO zif_timestamp
                zone TYPE csequence
                out  TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_timestamp.

    METHODS show_iso_parsing
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_timestamp.

    METHODS show_arithmetic
      IMPORTING now TYPE REF TO zif_timestamp
                out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_timestamp.

    METHODS show_day_borders
      IMPORTING now TYPE REF TO zif_timestamp
                out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_timestamp.

    METHODS show_daylight_saving
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_timestamp.

    METHODS show_switch_hour
      IMPORTING date TYPE d
                out  TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

ENDCLASS.


CLASS zcl_timestamp_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(now) = zcl_timestamp=>for_utclong( utclong_current( ) ).
        DATA(user_zone) = cl_abap_context_info=>get_user_time_zone( ).

        show_conversions( now = now
                          out = out ).
        show_wall_clocks( now       = now
                          user_zone = user_zone
                          out       = out ).
        show_iso_parsing( out ).
        show_arithmetic( now = now
                         out = out ).
        show_day_borders( now = now
                          out = out ).
        show_daylight_saving( out ).
        show_rejected_input( out ).
      CATCH zcx_timestamp cx_abap_context_info_error INTO DATA(error).
        out->write( |Time stamp demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_conversions.
    out->write( `--- One point in time, five representations ---` ).
    out->write( |utclong   : { now->as_utclong( ) }| ).
    out->write( |TIMESTAMPL: { now->as_timestamp( ) }| ).
    out->write( |TIMESTAMP : { now->as_short_timestamp( ) }| ).
    out->write( |Unix time : { now->as_unix_seconds( ) }| ).
    out->write( |RFC 3339  : { now->as_iso( ) }| ).
  ENDMETHOD.

  METHOD show_wall_clocks.
    out->write( `--- The same moment on different wall clocks ---` ).

    show_wall_clock( now  = now
                     zone = utc
                     out  = out ).
    show_wall_clock( now  = now
                     zone = central_europe
                     out  = out ).
    show_wall_clock( now  = now
                     zone = eastern_europe
                     out  = out ).

    IF zcl_timestamp=>is_known_zone( user_zone ) = abap_true.
      show_wall_clock( now  = now
                       zone = user_zone
                       out  = out ).
    ELSE.
      out->write( |Your user has no time zone maintained| ).
    ENDIF.
  ENDMETHOD.

  METHOD show_wall_clock.
    DATA(local) = now->in_zone( zone ).

    out->write( |{ local->zone( ) WIDTH = 6 }: { local->as_iso( ) }| &&
                | - date { local->date( ) DATE = ISO }, time { local->time( ) TIME = ISO },| &&
                | offset { local->utc_offset_seconds( ) } s, daylight saving { local->is_daylight_saving( ) }| ).
  ENDMETHOD.

  METHOD show_iso_parsing.
    DATA(from_payload) = zcl_timestamp=>for_iso( payload_stamp ).
    DATA(from_compact) = zcl_timestamp=>for_iso( compact_stamp ).

    out->write( `--- Parsing RFC 3339 texts ---` ).
    out->write( |{ payload_stamp } is { from_payload->as_iso( ) }| ).
    out->write( |{ compact_stamp } is { from_compact->as_iso( ) }| ).
    DATA(same_second) = from_payload->truncate_to_seconds( )->equals( from_compact->as_utclong( ) ).

    out->write( |Both name the same second: { same_second }| ).
  ENDMETHOD.

  METHOD show_arithmetic.
    DATA(in_ninety_minutes) = now->add_minutes( ninety ).
    DATA(a_week_ago) = now->add_days( 0 - one_week ).
    DATA(inside_the_week) = now->is_between( time_from = a_week_ago->as_utclong( )
                                             time_to   = in_ninety_minutes->as_utclong( ) ).

    out->write( `--- Arithmetic and comparison ---` ).
    out->write( |Now                : { now->as_iso( ) }| ).
    out->write( |In ninety minutes  : { in_ninety_minutes->as_iso( ) }| ).
    out->write( |A week ago         : { a_week_ago->as_iso( ) }| ).
    out->write( |Seconds until then : { now->seconds_until( in_ninety_minutes->as_utclong( ) ) }| ).
    out->write( |Now before then    : { now->is_before( in_ninety_minutes->as_utclong( ) ) }| ).
    out->write( |Now inside the week: { inside_the_week }| ).
  ENDMETHOD.

  METHOD show_day_borders.
    DATA(today) = now->in_zone( central_europe ).
    DATA(day_start) = today->start_of_day( ).
    DATA(day_end) = today->end_of_day( ).

    out->write( |--- Today in { central_europe }, as borders for a BETWEEN selection ---| ).
    out->write( |Starts: { day_start->as_iso( ) } = { day_start->in_zone( central_europe )->as_iso( ) }| ).
    out->write( |Ends  : { day_end->as_iso( ) } = { day_end->in_zone( central_europe )->as_iso( ) }| ).
    out->write( |As TIMESTAMPL: { day_start->as_timestamp( ) } to { day_end->as_timestamp( ) }| ).
  ENDMETHOD.

  METHOD show_daylight_saving.
    DATA(spring_noon) = zcl_timestamp=>for_date_time( date = spring_switch
                                                      time = noon
                                                      zone = central_europe )->in_zone( central_europe ).
    DATA(autumn_noon) = zcl_timestamp=>for_date_time( date = autumn_switch
                                                      time = noon
                                                      zone = central_europe )->in_zone( central_europe ).

    DATA(spring_day) = spring_noon->start_of_day( )->seconds_until( spring_noon->end_of_day( )->as_utclong( ) ).
    DATA(autumn_day) = autumn_noon->start_of_day( )->seconds_until( autumn_noon->end_of_day( )->as_utclong( ) ).

    out->write( |--- Daylight saving switches in { central_europe } ---| ).
    out->write( |{ spring_switch DATE = ISO } lasts { spring_day } seconds| ).
    out->write( |{ autumn_switch DATE = ISO } lasts { autumn_day } seconds| ).

    show_switch_hour( date = spring_switch
                      out  = out ).
    show_switch_hour( date = autumn_switch
                      out  = out ).
  ENDMETHOD.

  METHOD show_switch_hour.
    " 02:30 is skipped by the switch forward and repeated by the switch back;
    " this shows how the kernel of this system answers both.
    TRY.
        DATA(moment) = zcl_timestamp=>for_date_time( date = date
                                                     time = half_past_two
                                                     zone = central_europe ).

        out->write( |{ date DATE = ISO } { half_past_two TIME = ISO } { central_europe } is { moment->as_iso( ) }| ).
      CATCH zcx_timestamp INTO DATA(rejection).
        out->write( rejection->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_rejected_input.
    out->write( `--- Rejected input ---` ).

    TRY.
        zcl_timestamp=>for_iso( local_stamp ).

        out->write( |{ local_stamp } was unexpectedly accepted| ).
      CATCH zcx_timestamp INTO DATA(rejection).
        out->write( rejection->get_text( ) ).
    ENDTRY.

    TRY.
        zcl_timestamp=>for_date_time( date = feb_30
                                      time = noon
                                      zone = central_europe ).

        out->write( `30 February was unexpectedly accepted` ).
      CATCH zcx_timestamp INTO rejection.
        out->write( rejection->get_text( ) ).
    ENDTRY.

    TRY.
        zcl_timestamp=>for_utclong( utclong_current( ) )->in_zone( `MARS` ).

        out->write( `Time zone MARS was unexpectedly accepted` ).
      CATCH zcx_timestamp INTO rejection.
        out->write( rejection->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
