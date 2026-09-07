"! <p class="shorttext synchronized" lang="EN">String formatting utility demo</p>
"! Runnable walk through ZCL_STRING_FORMAT. Press F9 in ADT to see the output.
CLASS zcl_string_format_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    TYPES: BEGIN OF shipment,
             order_id TYPE string,
             customer TYPE string,
             quantity TYPE i,
           END OF shipment.

    CONSTANTS column_width TYPE i VALUE 12.

    METHODS show_alignment
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_string_format.

    METHODS show_cutting
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_string_format.

    METHODS show_case
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_template
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_string_format.

    METHODS show_guards
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS table_row
      IMPORTING id            TYPE string
                name          TYPE string
                amount        TYPE string
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_string_format.

ENDCLASS.


CLASS zcl_string_format_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_alignment( out ).
        show_cutting( out ).
        show_case( out ).
        show_template( out ).
        show_guards( out ).
      CATCH zcx_string_format INTO DATA(error).
        out->write( |Formatting failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_alignment.
    out->write( `--- Padding and alignment ---` ).

    out->write( table_row( id     = `Id`
                           name   = `Product`
                           amount = `Amount` ) ).
    out->write( table_row( id     = `1`
                           name   = `Keyboard`
                           amount = `49.90` ) ).
    out->write( table_row( id     = `22`
                           name   = `Monitor`
                           amount = `329.00` ) ).

    DATA(zero_padded) = zcl_string_format=>for_text( `4711` )->align_right( width = 10
                                                                            fill  = `0` )->as_text( ).
    out->write( |Zero padded: { zero_padded }| ).

    DATA(banner) = zcl_string_format=>for_text( ` Report ` )->center( width = 30
                                                                      fill  = `=` )->as_text( ).
    out->write( banner ).
  ENDMETHOD.

  METHOD show_cutting.
    out->write( `--- Truncate and shorten ---` ).

    DATA(description) = `A very long product description that does not fit`.

    out->write( |Truncated: { zcl_string_format=>for_text( description )->truncate( 20 )->as_text( ) }| ).
    out->write( |Shortened: { zcl_string_format=>for_text( description )->shorten( 20 )->as_text( ) }| ).
    out->write( |Fits:      { zcl_string_format=>for_text( `short` )->shorten( 20 )->as_text( ) }| ).
  ENDMETHOD.

  METHOD show_case.
    out->write( `--- Case conversion ---` ).

    DATA(source) = `parseHTTPRequest_body v2`.
    DATA(text) = zcl_string_format=>for_text( source ).

    out->write( |Source:  { source }| ).
    out->write( |Words:   { concat_lines_of( table = text->words( )
                                             sep   = `, ` ) }| ).
    out->write( |Upper:   { text->to_upper_case( )->as_text( ) }| ).
    out->write( |Lower:   { text->to_lower_case( )->as_text( ) }| ).
    out->write( |Capital: { text->capitalize( )->as_text( ) }| ).
    out->write( |Title:   { text->to_title_case( )->as_text( ) }| ).
    out->write( |Camel:   { text->to_camel_case( )->as_text( ) }| ).
    out->write( |Pascal:  { text->to_pascal_case( )->as_text( ) }| ).
    out->write( |Snake:   { text->to_snake_case( )->as_text( ) }| ).
    out->write( |Kebab:   { text->to_kebab_case( )->as_text( ) }| ).
  ENDMETHOD.

  METHOD show_template.
    out->write( `--- Templates ---` ).

    DATA(notification) = zcl_string_format=>template(
      `Dear {customer}, order {order_id} with {quantity} item(s) ships on {ship_date}. Cost: {{fixed}}.` ).

    out->write( |Placeholders: { concat_lines_of( table = notification->placeholders( )
                                                  sep   = `, ` ) }| ).

    DATA(shipment) = VALUE shipment( order_id = `SO-1001`
                                     customer = `Anna`
                                     quantity = 3 ).

    out->write( notification->with_structure( shipment
                           )->with( name  = `ship_date`
                                    value = `2026-09-08`
                           )->render( ) ).

    DATA(partial) = notification->with_structure( shipment )->render_partial( ).
    out->write( |Partial: { partial }| ).
  ENDMETHOD.

  METHOD show_guards.
    out->write( `--- Guards ---` ).

    TRY.
        zcl_string_format=>for_text( `abc` )->align_left( width = 5
                                                          fill  = `ab` ).
      CATCH zcx_string_format INTO DATA(fill_error).
        out->write( |Rejected: { fill_error->get_text( ) }| ).
    ENDTRY.

    TRY.
        zcl_string_format=>template( `Hello {name` ).
      CATCH zcx_string_format INTO DATA(parse_error).
        out->write( |Rejected: { parse_error->get_text( ) }| ).
    ENDTRY.

    TRY.
        zcl_string_format=>template( `Hello {name}` )->render( ).
      CATCH zcx_string_format INTO DATA(render_error).
        out->write( |Rejected: { render_error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD table_row.
    DATA(id_column) = zcl_string_format=>for_text( id )->align_right( 4 )->as_text( ).
    DATA(name_column) = zcl_string_format=>for_text( name )->align_left( column_width )->as_text( ).
    DATA(amount_column) = zcl_string_format=>for_text( amount )->align_right( column_width )->as_text( ).

    result = |{ id_column } { name_column } { amount_column }|.
  ENDMETHOD.

ENDCLASS.
