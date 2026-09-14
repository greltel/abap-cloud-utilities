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

    DATA(json) = zcl_acu_json=>for_data( original )->to_string( ).
    zcl_acu_json=>for_string( json )->read_into( IMPORTING data = read_back ).

    cl_abap_unit_assert=>assert_equals(
      act = read_back
      exp = original
      msg = 'A default round trip did not preserve the data' ).
  ENDMETHOD.

  METHOD given_camel_then_names_match.
    DATA(json) = zcl_acu_json=>for_data( sample_order( ) )->as_camel_case( )->to_string( ).

    cl_abap_unit_assert=>assert_equals(
      act = xsdbool( contains( val = json
                               sub = `"orderId"` ) )
      exp = abap_true
      msg = 'The member names were not rendered in camelCase' ).
  ENDMETHOD.

  METHOD given_camel_then_round_trip.
    DATA read_back TYPE order.
    DATA(original) = sample_order( ).

    DATA(json) = zcl_acu_json=>for_data( original )->as_camel_case( )->to_string( ).
    zcl_acu_json=>for_string( json )->from_camel_case( )->read_into( IMPORTING data = read_back ).

    cl_abap_unit_assert=>assert_equals(
      act = read_back
      exp = original
      msg = 'A camelCase round trip did not preserve the data' ).
  ENDMETHOD.

  METHOD given_pascal_then_round_trip.
    DATA read_back TYPE order.
    DATA(original) = sample_order( ).

    DATA(json) = zcl_acu_json=>for_data( original )->as_pascal_case( )->to_string( ).
    zcl_acu_json=>for_string( json )->from_pascal_case( )->read_into( IMPORTING data = read_back ).

    cl_abap_unit_assert=>assert_equals(
      act = read_back
      exp = original
      msg = 'A PascalCase round trip did not preserve the data' ).
  ENDMETHOD.

  METHOD given_bool_json_then_abap_bool.
    DATA read_back TYPE order.

    zcl_acu_json=>for_string( `{ "ORDER_ID": "4711", "IS_URGENT": true }`
      )->booleans_to_abap_bool(
      )->read_into( IMPORTING data = read_back ).

    cl_abap_unit_assert=>assert_equals(
      act = read_back-is_urgent
      exp = abap_true
      msg = 'The JSON boolean true was not converted to abap_true' ).
  ENDMETHOD.

  METHOD given_extra_member_ignored.
    DATA read_back TYPE order.

    zcl_acu_json=>for_string( `{ "ORDER_ID": "4711", "UNKNOWN_MEMBER": 1 }`
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
        zcl_acu_json=>for_data( row ).

        cl_abap_unit_assert=>fail( 'A structure with a reference component was accepted' ).
      CATCH zcx_acu_json.
    ENDTRY.
  ENDMETHOD.

  METHOD given_ref_in_line_then_raises.
    DATA rows TYPE dynamic_rows.

    TRY.
        zcl_acu_json=>for_data( rows ).

        cl_abap_unit_assert=>fail( 'A table whose line type has a reference component was accepted' ).
      CATCH zcx_acu_json.
    ENDTRY.
  ENDMETHOD.

  METHOD given_ref_target_then_raises.
    DATA row TYPE dynamic_row.

    TRY.
        zcl_acu_json=>for_string( `{ "ID": "1" }` )->read_into( IMPORTING data = row ).

        cl_abap_unit_assert=>fail( 'A target with a reference component was accepted' ).
      CATCH zcx_acu_json.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

CLASS ltc_booleans DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    TYPES: BEGIN OF stock_item,
             sku      TYPE string,
             in_stock TYPE abap_bool,
           END OF stock_item.
    TYPES stock_items TYPE STANDARD TABLE OF stock_item WITH EMPTY KEY.

    TYPES: BEGIN OF customer,
             name TYPE string,
             vip  TYPE abap_bool,
           END OF customer.

    TYPES: BEGIN OF order,
             order_id  TYPE string,
             is_urgent TYPE abap_bool,
             is_paid   TYPE abap_bool,
             code      TYPE c LENGTH 1,
             customer  TYPE customer,
             items     TYPE stock_items,
           END OF order.

    METHODS sample_order
      RETURNING VALUE(result) TYPE order.

    METHODS written_with_booleans
      RETURNING VALUE(result) TYPE REF TO zif_json_node
      RAISING   zcx_acu_json.

    METHODS given_default_then_x_string FOR TESTING RAISING cx_static_check.
    METHODS given_true_then_json_true FOR TESTING RAISING cx_static_check.
    METHODS given_false_then_json_false FOR TESTING RAISING cx_static_check.
    METHODS given_nested_then_boolean FOR TESTING RAISING cx_static_check.
    METHODS given_table_then_booleans FOR TESTING RAISING cx_static_check.
    METHODS given_char_x_then_kept_string FOR TESTING RAISING cx_static_check.
    METHODS given_camel_then_booleans FOR TESTING RAISING cx_static_check.
    METHODS given_booleans_then_round_trip FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_booleans IMPLEMENTATION.

  METHOD sample_order.
    result = VALUE #( order_id  = `ORD-1001`
                      is_urgent = abap_true
                      is_paid   = abap_false
                      code      = 'X'
                      customer  = VALUE #( name = `ACME` vip = abap_true )
                      items     = VALUE #( ( sku = `KB-1` in_stock = abap_true )
                                           ( sku = `MS-7` in_stock = abap_false ) ) ).
  ENDMETHOD.

  METHOD written_with_booleans.
    result = zcl_acu_json=>parse( zcl_acu_json=>for_data( sample_order( )
                                    )->abap_bool_to_booleans(
                                    )->to_string( ) ).
  ENDMETHOD.

  METHOD given_default_then_x_string.
    DATA(document) = zcl_acu_json=>parse( zcl_acu_json=>for_data( sample_order( ) )->to_string( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = document->child( `IS_URGENT` )->text( )
      exp = `X`
      msg = 'Without the option an abap_bool component is not written as the character X' ).
  ENDMETHOD.

  METHOD given_true_then_json_true.
    DATA(is_urgent) = written_with_booleans( )->child( `IS_URGENT` ).

    cl_abap_unit_assert=>assert_equals(
      act = is_urgent->is_boolean( )
      exp = abap_true
      msg = 'abap_true is not written as a JSON boolean' ).
    cl_abap_unit_assert=>assert_equals(
      act = is_urgent->as_boolean( )
      exp = abap_true
      msg = 'abap_true is not written as the JSON value true' ).
  ENDMETHOD.

  METHOD given_false_then_json_false.
    DATA(is_paid) = written_with_booleans( )->child( `IS_PAID` ).

    cl_abap_unit_assert=>assert_equals(
      act = is_paid->is_boolean( )
      exp = abap_true
      msg = 'abap_false is not written as a JSON boolean' ).
    cl_abap_unit_assert=>assert_equals(
      act = is_paid->as_boolean( )
      exp = abap_false
      msg = 'abap_false is not written as the JSON value false' ).
  ENDMETHOD.

  METHOD given_nested_then_boolean.
    cl_abap_unit_assert=>assert_equals(
      act = written_with_booleans( )->descendant( `CUSTOMER/VIP` )->is_boolean( )
      exp = abap_true
      msg = 'An abap_bool component inside a nested structure is not written as a JSON boolean' ).
  ENDMETHOD.

  METHOD given_table_then_booleans.
    DATA(document) = written_with_booleans( ).

    cl_abap_unit_assert=>assert_equals(
      act = document->descendant( `ITEMS/1/IN_STOCK` )->as_boolean( )
      exp = abap_true
      msg = 'An abap_bool component of the first table line is not written as true' ).
    cl_abap_unit_assert=>assert_equals(
      act = document->descendant( `ITEMS/2/IN_STOCK` )->is_boolean( )
      exp = abap_true
      msg = 'An abap_bool component of the second table line is not written as a JSON boolean' ).
  ENDMETHOD.

  METHOD given_char_x_then_kept_string.
    DATA(code) = written_with_booleans( )->child( `CODE` ).

    cl_abap_unit_assert=>assert_equals(
      act = code->is_string( )
      exp = abap_true
      msg = 'A plain character component holding X is mistaken for an abap_bool' ).
    cl_abap_unit_assert=>assert_equals(
      act = code->text( )
      exp = `X`
      msg = 'A plain character component loses its text' ).
  ENDMETHOD.

  METHOD given_camel_then_booleans.
    DATA(document) = zcl_acu_json=>parse( zcl_acu_json=>for_data( sample_order( )
                                            )->as_camel_case(
                                            )->abap_bool_to_booleans(
                                            )->to_string( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = document->child( `isUrgent` )->as_boolean( )
      exp = abap_true
      msg = 'JSON booleans and camelCase member names do not combine' ).
  ENDMETHOD.

  METHOD given_booleans_then_round_trip.
    DATA read_back TYPE order.

    DATA(json) = zcl_acu_json=>for_data( sample_order( ) )->abap_bool_to_booleans( )->to_string( ).

    zcl_acu_json=>for_string( json )->booleans_to_abap_bool( )->read_into( IMPORTING data = read_back ).

    cl_abap_unit_assert=>assert_equals(
      act = read_back
      exp = sample_order( )
      msg = 'An order written with JSON booleans does not survive the round trip' ).
  ENDMETHOD.

ENDCLASS.

CLASS ltc_tree DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA root TYPE REF TO zif_json_node.

    METHODS setup RAISING cx_static_check.

    METHODS sample_order
      RETURNING VALUE(result) TYPE string.

    METHODS given_object_then_is_object FOR TESTING RAISING cx_static_check.
    METHODS given_object_then_size_7 FOR TESTING RAISING cx_static_check.
    METHODS given_object_then_member_names FOR TESTING RAISING cx_static_check.
    METHODS given_string_then_text FOR TESTING RAISING cx_static_check.
    METHODS given_escapes_then_decoded FOR TESTING RAISING cx_static_check.
    METHODS given_number_then_text_as_is FOR TESTING RAISING cx_static_check.
    METHODS given_number_then_as_number FOR TESTING RAISING cx_static_check.
    METHODS given_string_then_no_number FOR TESTING.
    METHODS given_true_then_as_boolean FOR TESTING RAISING cx_static_check.
    METHODS given_false_then_not_boolean FOR TESTING RAISING cx_static_check.
    METHODS given_text_true_then_false FOR TESTING RAISING cx_static_check.
    METHODS given_null_then_is_null FOR TESTING RAISING cx_static_check.
    METHODS given_null_then_has_child FOR TESTING RAISING cx_static_check.
    METHODS given_missing_then_no_child FOR TESTING RAISING cx_static_check.
    METHODS given_missing_then_raises FOR TESTING.
    METHODS given_missing_then_empty_text FOR TESTING RAISING cx_static_check.
    METHODS given_array_then_child_raises FOR TESTING.
    METHODS given_array_then_elements FOR TESTING RAISING cx_static_check.
    METHODS given_array_then_at_3 FOR TESTING RAISING cx_static_check.
    METHODS given_array_then_at_4_raises FOR TESTING.
    METHODS given_scalar_then_at_raises FOR TESTING.
    METHODS given_path_then_descendant FOR TESTING RAISING cx_static_check.
    METHODS given_path_then_number FOR TESTING RAISING cx_static_check.
    METHODS given_slashes_then_ignored FOR TESTING RAISING cx_static_check.
    METHODS given_bad_path_then_raises FOR TESTING.
    METHODS given_digit_member_then_child FOR TESTING RAISING cx_static_check.
    METHODS given_root_array_then_at FOR TESTING RAISING cx_static_check.
    METHODS given_malformed_then_rejected FOR TESTING.
    METHODS given_empty_then_rejected FOR TESTING.

ENDCLASS.


CLASS ltc_tree IMPLEMENTATION.

  METHOD setup.
    root = zcl_acu_json=>parse( sample_order( ) ).
  ENDMETHOD.

  METHOD sample_order.
    result = `{ "orderId": "ORD-1001", "netAmount": 199.90, "isUrgent": true, "note": null,`
          && ` "customer": { "name": "ACME \"Ltd\"", "vip": false, "kind": "true" },`
          && ` "items": [ { "sku": "KB-1", "qty": 2 }, { "sku": "MS-7", "qty": 1 } ],`
          && ` "tags": [ "a", "b", "c" ] }`.
  ENDMETHOD.

  METHOD given_object_then_is_object.
    cl_abap_unit_assert=>assert_equals(
      act = root->is_object( )
      exp = abap_true
      msg = 'The root of an object document is not reported as an object' ).
  ENDMETHOD.

  METHOD given_object_then_size_7.
    cl_abap_unit_assert=>assert_equals(
      act = root->size( )
      exp = 7
      msg = 'The member count of the root object is wrong' ).
  ENDMETHOD.

  METHOD given_object_then_member_names.
    DATA(names) = VALUE string_table( FOR member IN root->children( ) ( member->name( ) ) ).

    cl_abap_unit_assert=>assert_equals(
      act = names
      exp = VALUE string_table( ( `orderId` ) ( `netAmount` ) ( `isUrgent` ) ( `note` )
                                ( `customer` ) ( `items` ) ( `tags` ) )
      msg = 'The members are not returned with their names in document order' ).
  ENDMETHOD.

  METHOD given_string_then_text.
    cl_abap_unit_assert=>assert_equals(
      act = root->child( `orderId` )->text( )
      exp = `ORD-1001`
      msg = 'The text of a string member is not returned' ).
  ENDMETHOD.

  METHOD given_escapes_then_decoded.
    cl_abap_unit_assert=>assert_equals(
      act = root->descendant( `customer/name` )->text( )
      exp = `ACME "Ltd"`
      msg = 'Escaped quotes inside a string are not decoded' ).
  ENDMETHOD.

  METHOD given_number_then_text_as_is.
    cl_abap_unit_assert=>assert_equals(
      act = root->child( `netAmount` )->text( )
      exp = `199.90`
      msg = 'The text of a number is not kept as written in the document' ).
  ENDMETHOD.

  METHOD given_number_then_as_number.
    cl_abap_unit_assert=>assert_equals(
      act = root->child( `netAmount` )->as_number( )
      exp = CONV decfloat34( '199.90' )
      msg = 'A number member is not converted to a number' ).
  ENDMETHOD.

  METHOD given_string_then_no_number.
    TRY.
        root->child( `orderId` )->as_number( ).

        cl_abap_unit_assert=>fail( 'A string member was converted to a number' ).
      CATCH zcx_acu_json INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_true_then_as_boolean.
    cl_abap_unit_assert=>assert_equals(
      act = root->child( `isUrgent` )->as_boolean( )
      exp = abap_true
      msg = 'The JSON value true is not read as abap_true' ).
  ENDMETHOD.

  METHOD given_false_then_not_boolean.
    DATA(vip) = root->descendant( `customer/vip` ).

    cl_abap_unit_assert=>assert_equals(
      act = vip->is_boolean( )
      exp = abap_true
      msg = 'The JSON value false is not reported as a boolean' ).
    cl_abap_unit_assert=>assert_equals(
      act = vip->as_boolean( )
      exp = abap_false
      msg = 'The JSON value false is not read as abap_false' ).
  ENDMETHOD.

  METHOD given_text_true_then_false.
    cl_abap_unit_assert=>assert_equals(
      act = root->descendant( `customer/kind` )->as_boolean( )
      exp = abap_false
      msg = 'A string holding the text true is read as a boolean' ).
  ENDMETHOD.

  METHOD given_null_then_is_null.
    DATA(note) = root->child( `note` ).

    cl_abap_unit_assert=>assert_equals(
      act = note->is_null( )
      exp = abap_true
      msg = 'The JSON value null is not reported as null' ).
    cl_abap_unit_assert=>assert_initial( act = note->text( )
                                         msg = 'The text of null is not empty' ).
  ENDMETHOD.

  METHOD given_null_then_has_child.
    cl_abap_unit_assert=>assert_equals(
      act = root->has_child( `note` )
      exp = abap_true
      msg = 'A member holding null is not reported as present' ).
  ENDMETHOD.

  METHOD given_missing_then_no_child.
    cl_abap_unit_assert=>assert_equals(
      act = root->has_child( `orderid` )
      exp = abap_false
      msg = 'Member names are not matched case sensitively' ).
  ENDMETHOD.

  METHOD given_missing_then_raises.
    TRY.
        root->child( `currency` ).

        cl_abap_unit_assert=>fail( 'A missing member was returned' ).
      CATCH zcx_acu_json INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_missing_then_empty_text.
    cl_abap_unit_assert=>assert_initial( act = root->child_text( `currency` )
                                         msg = 'The text of a missing member is not empty' ).
  ENDMETHOD.

  METHOD given_array_then_child_raises.
    TRY.
        root->child( `tags` )->child( `a` ).

        cl_abap_unit_assert=>fail( 'An array answered a member lookup' ).
      CATCH zcx_acu_json INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_array_then_elements.
    DATA(tags) = root->child( `tags` ).

    cl_abap_unit_assert=>assert_equals(
      act = tags->is_array( )
      exp = abap_true
      msg = 'An array member is not reported as an array' ).
    cl_abap_unit_assert=>assert_equals(
      act = tags->size( )
      exp = 3
      msg = 'The element count of the array is wrong' ).
    cl_abap_unit_assert=>assert_initial( act = tags->at( 1 )->name( )
                                         msg = 'An array element carries a member name' ).
  ENDMETHOD.

  METHOD given_array_then_at_3.
    cl_abap_unit_assert=>assert_equals(
      act = root->child( `tags` )->at( 3 )->text( )
      exp = `c`
      msg = 'Positions do not count from 1 in document order' ).
  ENDMETHOD.

  METHOD given_array_then_at_4_raises.
    TRY.
        root->child( `tags` )->at( 4 ).

        cl_abap_unit_assert=>fail( 'A position beyond the last element was answered' ).
      CATCH zcx_acu_json INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_scalar_then_at_raises.
    TRY.
        root->child( `orderId` )->at( 1 ).

        cl_abap_unit_assert=>fail( 'A string answered a position lookup' ).
      CATCH zcx_acu_json INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_path_then_descendant.
    cl_abap_unit_assert=>assert_equals(
      act = root->descendant( `items/2/sku` )->text( )
      exp = `MS-7`
      msg = 'A path mixing member names and a position does not resolve' ).
  ENDMETHOD.

  METHOD given_path_then_number.
    cl_abap_unit_assert=>assert_equals(
      act = root->descendant( `items/1/qty` )->as_number( )
      exp = CONV decfloat34( 2 )
      msg = 'A number reached through a path is not converted' ).
  ENDMETHOD.

  METHOD given_slashes_then_ignored.
    cl_abap_unit_assert=>assert_equals(
      act = root->descendant( `/customer//name/` )->text( )
      exp = `ACME "Ltd"`
      msg = 'Empty path steps are not ignored' ).
  ENDMETHOD.

  METHOD given_bad_path_then_raises.
    TRY.
        root->descendant( `items/3/sku` ).

        cl_abap_unit_assert=>fail( 'A path through a missing position resolved' ).
      CATCH zcx_acu_json INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_digit_member_then_child.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_acu_json=>parse( `{ "1": "first", "2": "second" }` )->descendant( `2` )->text( )
      exp = `second`
      msg = 'A digit step on an object is not taken as a member name' ).
  ENDMETHOD.

  METHOD given_root_array_then_at.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_acu_json=>parse( `[ 10, 20 ]` )->at( 2 )->as_number( )
      exp = CONV decfloat34( 20 )
      msg = 'A document whose root is an array is not navigable by position' ).
  ENDMETHOD.

  METHOD given_malformed_then_rejected.
    TRY.
        zcl_acu_json=>parse( `{ "orderId": "ORD-1001", }` ).

        cl_abap_unit_assert=>fail( 'A document with a trailing comma was accepted' ).
      CATCH zcx_acu_json INTO DATA(rejection).
        cl_abap_unit_assert=>assert_bound( act = rejection->previous
                                           msg = 'The parse error is not kept as the cause' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_empty_then_rejected.
    TRY.
        zcl_acu_json=>parse( `` ).

        cl_abap_unit_assert=>fail( 'An empty string was accepted as a JSON document' ).
      CATCH zcx_acu_json INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
