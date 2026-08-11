"! <p class="shorttext synchronized" lang="EN">Date utility demo</p>
"! Runnable showcase for {@link zcl_date}. Start it with F9 in ADT.
"! <p>The demo is the composition root, so this is the only place that reads
"! the system date - the utility itself never does.</p>
CLASS zcl_date_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS reporting_date TYPE d VALUE '20250131'.

    METHODS show_calendar_parts
      IMPORTING date TYPE REF TO zif_date
                out  TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_boundaries
      IMPORTING date TYPE REF TO zif_date
                out  TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_date.

    METHODS show_month_shifting
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_date.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

ENDCLASS.


CLASS zcl_date_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(today) = zcl_date=>for_date( cl_abap_context_info=>get_system_date( ) ).

        show_calendar_parts( date = today
                             out  = out ).
        show_boundaries( date = today
                         out  = out ).
        show_month_shifting( out ).
        show_rejected_input( out ).
      CATCH zcx_date INTO DATA(error).
        out->write( |Date demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_calendar_parts.
    out->write( `--- Calendar parts ---` ).
    out->write( |Today      : { date->as_iso( ) }| ).
    out->write( |Quarter    : { date->quarter( ) }| ).
    out->write( |ISO week   : { date->iso_week( ) } of { date->iso_year( ) }| ).
    out->write( |Weekday    : { date->weekday( ) }| ).
    out->write( |Day of year: { date->day_of_year( ) }| ).
    out->write( |Month has  : { date->days_in_month( ) } days| ).
    out->write( |Leap year  : { date->is_leap_year( ) }| ).
    out->write( |Weekend    : { date->is_weekend( ) }| ).
  ENDMETHOD.

  METHOD show_boundaries.
    DATA(month_start) = date->first_day_of_month( )->as_iso( ).
    DATA(month_end) = date->last_day_of_month( )->as_iso( ).
    DATA(quarter_start) = date->first_day_of_quarter( )->as_iso( ).
    DATA(quarter_end) = date->last_day_of_quarter( )->as_iso( ).
    DATA(year_start) = date->first_day_of_year( )->as_iso( ).
    DATA(year_end) = date->last_day_of_year( )->as_iso( ).
    DATA(week_start) = date->first_day_of_week( )->as_iso( ).
    DATA(week_end) = date->last_day_of_week( )->as_iso( ).

    out->write( `--- Boundaries ---` ).
    out->write( |Month  : { month_start } to { month_end }| ).
    out->write( |Quarter: { quarter_start } to { quarter_end }| ).
    out->write( |Year   : { year_start } to { year_end }| ).
    out->write( |Week   : { week_start } to { week_end }| ).
  ENDMETHOD.

  METHOD show_month_shifting.
    DATA(closing) = zcl_date=>for_date( reporting_date ).

    out->write( `--- Month shifting ---` ).
    out->write( |Start          : { closing->as_iso( ) }| ).
    out->write( |Keep the day   : { closing->add_months( 1 )->as_iso( ) }| ).
    out->write( |Keep the ultimo: { closing->add_months_ultimo( 1 )->as_iso( ) }| ).
    out->write( |One year later : { closing->add_years( 1 )->as_iso( ) }| ).
    out->write( |Ninety days on : { closing->add_days( 90 )->as_iso( ) }| ).
    out->write( |Days to 31 Dec : { closing->days_until( '20251231' ) }| ).
  ENDMETHOD.

  METHOD show_rejected_input.
    out->write( `--- Rejected input ---` ).

    TRY.
        zcl_date=>for_iso( `2025-02-30` ).

        out->write( `30 February was unexpectedly accepted` ).
      CATCH zcx_date INTO DATA(rejection).
        out->write( rejection->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

