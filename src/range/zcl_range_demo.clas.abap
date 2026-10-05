"! <p class="shorttext synchronized" lang="EN">Range utility demo</p>
"! Runnable showcase for {@link zcl_acu_range}. Start it with F9 in ADT.
CLASS zcl_range_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    TYPES ty_plant TYPE c LENGTH 4.
    TYPES ty_plants TYPE RANGE OF ty_plant.
    TYPES ty_period TYPE n LENGTH 3.
    TYPES ty_periods TYPE RANGE OF ty_period.
    TYPES ty_quarters TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    TYPES ty_dates TYPE RANGE OF d.

    CONSTANTS first_domestic_plant TYPE string VALUE `1000`.
    CONSTANTS last_domestic_plant TYPE string VALUE `1999`.
    CONSTANTS export_plant TYPE string VALUE `3000`.
    CONSTANTS test_plants TYPE string VALUE `19*`.
    CONSTANTS domestic_plant TYPE ty_plant VALUE '1500'.
    CONSTANTS test_plant TYPE ty_plant VALUE '1950'.
    CONSTANTS foreign_plant TYPE ty_plant VALUE '2000'.
    CONSTANTS plant_with_five_places TYPE string VALUE `10000`.
    CONSTANTS first_quarter_start TYPE string VALUE `20260101`.
    CONSTANTS first_quarter_end TYPE string VALUE `20260331`.
    CONSTANTS in_february TYPE d VALUE '20260215'.
    CONSTANTS in_april TYPE d VALUE '20260415'.
    CONSTANTS second_period TYPE ty_period VALUE '002'.
    CONSTANTS a_quantity TYPE i VALUE 5.
    CONSTANTS text_yes TYPE string VALUE `yes`.
    CONSTANTS text_no TYPE string VALUE `no`.

    METHODS show_builder
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_range.

    METHODS show_typed_table
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_range.

    METHODS show_list
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_range.

    METHODS show_existing_range
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_range.

    METHODS show_empty_range
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_range.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS plants
      RETURNING VALUE(result) TYPE REF TO zif_range
      RAISING   zcx_range.

    METHODS answer
      IMPORTING flag          TYPE abap_bool
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_range_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_builder( out ).
        show_typed_table( out ).
        show_list( out ).
        show_existing_range( out ).
        show_empty_range( out ).
        show_rejected_input( out ).
      CATCH zcx_range INTO DATA(error).
        out->write( |Range demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_builder.
    DATA(range) = plants( ).

    out->write( `--- A range from the builder: domestic plants and the export plant, without test plants ---` ).
    out->write( range->conditions( ) ).
    out->write( |{ domestic_plant } covered: { answer( range->covers( domestic_plant ) ) }| ).
    out->write( |{ test_plant } covered: { answer( range->covers( test_plant ) ) } - exclusions always win| ).
    out->write( |{ export_plant } covered: { answer( range->covers( export_plant ) ) }| ).
    out->write( |{ foreign_plant } covered: { answer( range->covers( foreign_plant ) ) }| ).
  ENDMETHOD.

  METHOD show_typed_table.
    DATA plant_range TYPE ty_plants.

    DATA(range) = plants( ).

    range->write_to( REF #( plant_range ) ).
    DATA(is_in_table) = xsdbool( test_plant IN plant_range ).

    out->write( `--- The same range as a RANGE OF table, ready for WHERE plant IN @plant_range ---` ).
    out->write( plant_range ).
    out->write( |{ test_plant } IN the table: { answer( is_in_table ) }, | &&
                |covered by the range: { answer( range->covers( test_plant ) ) }| ).
  ENDMETHOD.

  METHOD show_list.
    DATA period_range TYPE ty_periods.

    DATA(first_quarter) = zcl_acu_range=>from_list( VALUE ty_quarters( ( 1 ) ( 2 ) ( 3 ) ) ).

    first_quarter->write_to( REF #( period_range ) ).

    out->write( `--- A list of numbers as a range for a NUMC column: padded with leading zeros ---` ).
    out->write( period_range ).
    out->write( |Period { second_period } covered: { answer( first_quarter->covers( second_period ) ) }| ).
  ENDMETHOD.

  METHOD show_existing_range.
    DATA date_range TYPE ty_dates.

    " The shape in which a RAP query hands over its filter: every value is a string.
    DATA(filter) = VALUE if_rap_query_filter=>tt_range_option( ( sign   = zif_range=>sign-including
                                                                 option = zif_range=>option-between
                                                                 low    = first_quarter_start
                                                                 high   = first_quarter_end ) ).

    DATA(posting_dates) = zcl_acu_range=>from_range( filter ).

    posting_dates->write_to( REF #( date_range ) ).

    out->write( `--- The filter ranges of a RAP query, evaluated in memory and typed for a SELECT ---` ).
    out->write( |{ in_february DATE = ISO } covered: { answer( posting_dates->covers( in_february ) ) }| ).
    out->write( |{ in_april DATE = ISO } covered: { answer( posting_dates->covers( in_april ) ) }| ).
    out->write( date_range ).
  ENDMETHOD.

  METHOD show_empty_range.
    DATA(no_plants) = zcl_acu_range=>from_list( VALUE string_table( ) ).

    out->write( `--- An empty list: a range without conditions covers everything ---` ).
    out->write( |{ foreign_plant } covered: { answer( no_plants->covers( foreign_plant ) ) }| ).
    out->write( |is_empty( ) to guard a SELECT: { answer( no_plants->is_empty( ) ) }| ).
  ENDMETHOD.

  METHOD show_rejected_input.
    DATA plant_range TYPE ty_plants.

    out->write( `--- Rejected input ---` ).

    TRY.
        zcl_acu_range=>builder( )->equal( plant_with_five_places )->build( )->write_to( REF #( plant_range ) ).

        out->write( |{ plant_with_five_places } was unexpectedly cut to four places| ).
      CATCH zcx_range INTO DATA(rejection).
        out->write( rejection->get_text( ) ).
    ENDTRY.

    TRY.
        DATA(covered) = plants( )->covers( a_quantity ).

        out->write( |A number was unexpectedly compared with a pattern: { answer( covered ) }| ).
      CATCH zcx_range INTO rejection.
        out->write( rejection->get_text( ) ).
    ENDTRY.

    TRY.
        zcl_acu_range=>from_range( VALUE string_table( ( export_plant ) ) ).

        out->write( `A list of values was unexpectedly accepted as a ranges table` ).
      CATCH zcx_range INTO rejection.
        out->write( rejection->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD plants.
    result = zcl_acu_range=>builder( )->between( low  = first_domestic_plant
                                                 high = last_domestic_plant
                                 )->equal( export_plant
                                 )->not_pattern( test_plants
                                 )->build( ).
  ENDMETHOD.

  METHOD answer.
    result = COND #( WHEN flag = abap_true THEN text_yes ELSE text_no ).
  ENDMETHOD.

ENDCLASS.
