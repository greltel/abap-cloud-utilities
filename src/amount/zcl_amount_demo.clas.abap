"! ZCL_AMOUNT_DEMO
"! <p class="shorttext synchronized" lang="EN">Currency amount utility demo</p>
"! Runnable showcase for {@link zcl_amount}. Start it with F9 in ADT.
"! The conversion part needs exchange rates of type M valid today from EUR
"! to USD and from JPY to EUR; point the constants to currencies your system
"! maintains rates for.
CLASS zcl_amount_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS euro TYPE string VALUE `EUR`.
    CONSTANTS dollar TYPE string VALUE `USD`.
    CONSTANTS yen TYPE string VALUE `JPY`.
    CONSTANTS net_price TYPE string VALUE `19.99`.
    CONSTANTS quantity TYPE i VALUE 3.
    CONSTANTS tax_rate TYPE string VALUE `0.24`.
    CONSTANTS half_cent TYPE string VALUE `2.345`.
    CONSTANTS yen_amount TYPE i VALUE 1000.
    CONSTANTS stored_yen TYPE string VALUE `10.00`.
    CONSTANTS sample_amount TYPE i VALUE 100.

    METHODS show_rounding
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_representations
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_conversion
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

ENDCLASS.


CLASS zcl_amount_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    show_rounding( out ).
    show_representations( out ).
    show_conversion( out ).
    show_rejected_input( out ).
  ENDMETHOD.

  METHOD show_rounding.
    out->write( `--- Arithmetic and rounding ---` ).

    TRY.
        DATA(net) = zcl_amount=>of( value    = net_price
                                    currency = euro )->multiply_by( quantity ).
        DATA(tax) = net->multiply_by( tax_rate ).
        DATA(gross) = net->add( tax ).

        out->write( |Net          : { net->as_raw_text( ) } { net->currency( ) }| ).
        out->write( |Tax, exact   : { tax->as_decimal( ) }| ).
        out->write( |Tax, rounded : { tax->round( )->as_raw_text( ) }| ).
        out->write( |Gross        : { gross->round( )->as_text_with_currency( ) }| ).

        DATA(half) = zcl_amount=>of( value    = half_cent
                                     currency = euro ).

        out->write( |{ half_cent } commercial: { half->round( )->as_raw_text( ) }| ).
        out->write( |{ half_cent } banker's  : { half->round( cl_abap_math=>round_half_even )->as_raw_text( ) }| ).
      CATCH zcx_amount INTO DATA(error).
        out->write( |Amount demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_representations.
    out->write( `--- Currency units and database representation ---` ).

    TRY.
        DATA(yen_units) = zcl_amount=>of( value    = yen_amount
                                          currency = yen ).

        out->write( |{ yen_units->as_text_with_currency( ) } is stored as { yen_units->as_internal( ) }| ).

        DATA(from_field) = zcl_amount=>of_internal( value    = stored_yen
                                                    currency = yen ).

        out->write( |A stored { stored_yen } { yen } is { from_field->as_text_with_currency( ) }| ).
        out->write( |Decimals of { yen }: { zcl_amount=>decimals_of( yen ) }| ).
        out->write( |Decimals of { euro }: { zcl_amount=>decimals_of( euro ) }| ).
      CATCH zcx_amount INTO DATA(error).
        out->write( |Amount demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_conversion.
    out->write( `--- Conversion ---` ).

    DATA(today) = cl_abap_context_info=>get_system_date( ).

    TRY.
        DATA(euros) = zcl_amount=>of( value    = sample_amount
                                      currency = euro ).
        DATA(dollars) = euros->convert_to( currency = dollar
                                           date     = today ).

        out->write( |{ euros->as_text_with_currency( ) } = { dollars->as_text_with_currency( ) } on { today DATE = USER }| ).

        DATA(yen_in_euro) = zcl_amount=>of( value    = yen_amount
                                            currency = yen )->convert_to( currency = euro
                                                                          date     = today ).

        out->write( |{ yen_amount } { yen } = { yen_in_euro->as_text_with_currency( ) } - compare with the rate maintained| ).
      CATCH zcx_amount INTO DATA(error).
        out->write( |Conversion failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_rejected_input.
    out->write( `--- Rejected input ---` ).

    TRY.
        zcl_amount=>of( value    = `ten`
                        currency = euro ).

        out->write( `A value that is not a number was unexpectedly accepted` ).
      CATCH zcx_amount INTO DATA(not_a_number).
        out->write( |Rejected as expected: { not_a_number->get_text( ) }| ).
    ENDTRY.

    TRY.
        zcl_amount=>of( value    = sample_amount
                        currency = euro )->add( zcl_amount=>of( value    = sample_amount
                                                                currency = dollar ) ).

        out->write( `Adding amounts of different currencies was unexpectedly accepted` ).
      CATCH zcx_amount INTO DATA(mixed).
        out->write( |Rejected as expected: { mixed->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
