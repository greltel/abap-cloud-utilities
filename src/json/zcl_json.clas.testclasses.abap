*"* use this source file for your ABAP unit test classes
CLASS ltc_round_trip DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    TYPES: BEGIN OF order_item,
             product  TYPE string,
             quantity TYPE i,
           END OF order_item.
    TYPES order_items TYPE STANDARD TABLE OF order_item WITH EMPTY KEY.

    TYPES: BEGIN OF order,
             order_id   TYPE string,
             net_amount TYPE p LENGTH 9 DECIMALS 2,
             is_urgent  TYPE abap_bool,
             items      TYPE order_items,
           END OF order.

    METHODS sample_order
      RETURNING VALUE(result) TYPE order.

    METHODS given_order_then_round_trip    FOR TESTING RAISING cx_static_check.
    METHODS given_camel_then_names_match   FOR TESTING RAISING cx_static_check.
    METHODS given_camel_then_round_trip    FOR TESTING RAISING cx_static_check.
    METHODS given_pascal_then_round_trip   FOR TESTING RAISING cx_static_check.
    METHODS given_bool_json_then_abap_bool FOR TESTING RAISING cx_static_check.
    METHODS given_extra_member_ignored     FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_round_trip IMPLEMENTATION.

  METHOD sample_order.
    result = VALUE #( order_id   = `ORD-1001`
                      net_amount = '199.90'
                      is_urgent  = abap_true
                      items      = VALUE #( ( product = `Keyboard` quantity = 2 )
                                            ( product = `Mouse` quantity = 1 ) ) ).
  ENDMETHOD.

  METHOD given_order_then_round_trip.
    DATA read_back TYPE order.
    DATA(original) = sample_order( ).

    DATA(json) = zcl_json=>for_data( original )->to_string( ).
    zcl_json=>for_string( json )->read_into( IMPORTING data = read_back ).

    cl_abap_unit_assert=>assert_equals(
      act = read_back
      exp = original
      msg = 'A default round trip did not preserve the data' ).
  ENDMETHOD.

  METHOD given_camel_then_names_match.
    DATA(json) = zcl_json=>for_data( sample_order( ) )->as_camel_case( )->to_string( ).

    cl_abap_unit_assert=>assert_equals(
      act = xsdbool( contains( val = json
                               sub = `"orderId"` ) )
      exp = abap_true
      msg = 'The member names were not rendered in camelCase' ).
  ENDMETHOD.

  METHOD given_camel_then_round_trip.
    DATA read_back TYPE order.
    DATA(original) = sample_order( ).

    DATA(json) = zcl_json=>for_data( original )->as_camel_case( )->to_string( ).
    zcl_json=>for_string( json )->from_camel_case( )->read_into( IMPORTING data = read_back ).

    cl_abap_unit_assert=>assert_equals(
      act = read_back
      exp = original
      msg = 'A camelCase round trip did not preserve the data' ).
  ENDMETHOD.

  METHOD given_pascal_then_round_trip.
    DATA read_back TYPE order.
    DATA(original) = sample_order( ).

    DATA(json) = zcl_json=>for_data( original )->as_pascal_case( )->to_string( ).
    zcl_json=>for_string( json )->from_pascal_case( )->read_into( IMPORTING data = read_back ).

    cl_abap_unit_assert=>assert_equals(
      act = read_back
      exp = original
      msg = 'A PascalCase round trip did not preserve the data' ).
  ENDMETHOD.

  METHOD given_bool_json_then_abap_bool.
    DATA read_back TYPE order.

    zcl_json=>for_string( `{ "ORDER_ID": "4711", "IS_URGENT": true }`
      )->booleans_to_abap_bool(
      )->read_into( IMPORTING data = read_back ).

    cl_abap_unit_assert=>assert_equals(
      act = read_back-is_urgent
      exp = abap_true
      msg = 'The JSON boolean true was not converted to abap_true' ).
  ENDMETHOD.

  METHOD given_extra_member_ignored.
    DATA read_back TYPE order.

    zcl_json=>for_string( `{ "ORDER_ID": "4711", "UNKNOWN_MEMBER": 1 }`
      )->read_into( IMPORTING data = read_back ).

    cl_abap_unit_assert=>assert_equals(
      act = read_back-order_id
      exp = `4711`
      msg = 'A member without a matching component broke the mapping' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_rejected_input DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    TYPES: BEGIN OF dynamic_row,
             id      TYPE string,
             payload TYPE REF TO data,
           END OF dynamic_row.
    TYPES dynamic_rows TYPE STANDARD TABLE OF dynamic_row WITH EMPTY KEY.

    METHODS given_ref_comp_then_raises    FOR TESTING.
    METHODS given_ref_in_line_then_raises FOR TESTING.
    METHODS given_ref_target_then_raises  FOR TESTING.

ENDCLASS.


CLASS ltc_rejected_input IMPLEMENTATION.

  METHOD given_ref_comp_then_raises.
    DATA row TYPE dynamic_row.

    TRY.
        zcl_json=>for_data( row ).

        cl_abap_unit_assert=>fail( 'A structure with a reference component was accepted' ).
      CATCH zcx_json.
    ENDTRY.
  ENDMETHOD.

  METHOD given_ref_in_line_then_raises.
    DATA rows TYPE dynamic_rows.

    TRY.
        zcl_json=>for_data( rows ).

        cl_abap_unit_assert=>fail( 'A table whose line type has a reference component was accepted' ).
      CATCH zcx_json.
    ENDTRY.
  ENDMETHOD.

  METHOD given_ref_target_then_raises.
    DATA row TYPE dynamic_row.

    TRY.
        zcl_json=>for_string( `{ "ID": "1" }` )->read_into( IMPORTING data = row ).

        cl_abap_unit_assert=>fail( 'A target with a reference component was accepted' ).
      CATCH zcx_json.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
