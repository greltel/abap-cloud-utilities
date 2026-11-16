*"* use this source file for your ABAP unit test classes
"! Checks that a rejection names what was rejected, so that the message
"! alone tells a developer which data object or component to look at.
CLASS lth_rejection DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    CLASS-METHODS assert_names
      IMPORTING rejection TYPE REF TO zcx_compare
                culprit   TYPE string.

ENDCLASS.


CLASS lth_rejection IMPLEMENTATION.

  METHOD assert_names.
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( contains( val = rejection->get_text( )
                               sub = culprit ) )
      msg = |The rejection "{ rejection->get_text( ) }" does not name "{ culprit }"| ).
  ENDMETHOD.

ENDCLASS.


"! The structure most tests compare: an order with elementary components, a
"! nested structure, an internal table, a reference and the administrative
"! fields a comparison usually ignores.
CLASS lth_order DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    TYPES ty_price TYPE p LENGTH 7 DECIMALS 2.
    TYPES ty_items TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_address,
        city    TYPE string,
        country TYPE c LENGTH 2,
      END OF ty_address.
    TYPES:
      BEGIN OF ty_order,
        id         TYPE i,
        status     TYPE c LENGTH 1,
        price      TYPE ty_price,
        address    TYPE ty_address,
        items      TYPE ty_items,
        attachment TYPE REF TO data,
        changed_by TYPE string,
        changed_on TYPE d,
      END OF ty_order.

    CLASS-METHODS open_order
      RETURNING VALUE(result) TYPE ty_order.

ENDCLASS.


CLASS lth_order IMPLEMENTATION.

  METHOD open_order.
    result = VALUE #( id         = 4711
                      status     = 'O'
                      price      = '100.00'
                      address    = VALUE #( city    = `Athens`
                                            country = 'GR' )
                      items      = VALUE #( ( `Keyboard` ) )
                      changed_by = `ANNA`
                      changed_on = '20260115' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_difference DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_twin_address,
        city    TYPE string,
        country TYPE c LENGTH 2,
      END OF ty_twin_address.

    METHODS when_equal_then_no_changes FOR TESTING RAISING cx_static_check.
    METHODS when_one_differs_then_listed FOR TESTING RAISING cx_static_check.
    METHODS when_several_then_struct_order FOR TESTING RAISING cx_static_check.
    METHODS when_differs_then_has_changes FOR TESTING RAISING cx_static_check.
    METHODS when_nested_differs_then_path FOR TESTING RAISING cx_static_check.
    METHODS when_table_differs_then_rows FOR TESTING RAISING cx_static_check.
    METHODS when_same_rows_then_no_change FOR TESTING RAISING cx_static_check.
    METHODS when_ref_differs_then_bound FOR TESTING RAISING cx_static_check.
    METHODS given_twin_type_then_compared FOR TESTING RAISING cx_static_check.
    METHODS when_source_edited_then_kept FOR TESTING RAISING cx_static_check.
    METHODS when_built_then_compares_all FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_difference IMPLEMENTATION.

  METHOD when_equal_then_no_changes.
    DATA(before) = lth_order=>open_order( ).
    DATA(after) = lth_order=>open_order( ).

    DATA(difference) = zcl_compare=>difference( before = before
                                                after  = after ).

    cl_abap_unit_assert=>assert_initial(
      act = difference->changes( )
      msg = `Two equal structures are reported with changes` ).
    cl_abap_unit_assert=>assert_false(
      act = difference->has_changes( )
      msg = `has_changes( ) is true for two equal structures` ).
  ENDMETHOD.

  METHOD when_one_differs_then_listed.
    DATA(before) = lth_order=>open_order( ).
    DATA(after) = lth_order=>open_order( ).
    after-status = 'C'.

    DATA(changes) = zcl_compare=>difference( before = before
                                             after  = after )->changes( ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `STATUS` before = `O` after = `C` ) )
      msg = `The changed component is not listed with its value before and after` ).
  ENDMETHOD.

  METHOD when_several_then_struct_order.
    DATA(before) = lth_order=>open_order( ).
    DATA(after) = lth_order=>open_order( ).
    after-changed_by = `BORIS`.
    after-price = '120.50'.
    after-id = 4712.

    DATA(changes) = zcl_compare=>difference( before = before
                                             after  = after )->changes( ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `ID` before = `4711` after = `4712` )
                                                      ( component = `PRICE` before = `100.00` after = `120.50` )
                                                      ( component = `CHANGED_BY` before = `ANNA` after = `BORIS` ) )
      msg = `The changes do not follow the order of the components in the structure` ).
  ENDMETHOD.

  METHOD when_differs_then_has_changes.
    DATA(before) = lth_order=>open_order( ).
    DATA(after) = lth_order=>open_order( ).
    after-status = 'C'.

    DATA(difference) = zcl_compare=>difference( before = before
                                                after  = after ).

    cl_abap_unit_assert=>assert_true(
      act = difference->has_changes( )
      msg = `has_changes( ) is false although a component differs` ).
  ENDMETHOD.

  METHOD when_nested_differs_then_path.
    DATA(before) = lth_order=>open_order( ).
    DATA(after) = lth_order=>open_order( ).
    after-address-city = `Lamia`.

    DATA(changes) = zcl_compare=>difference( before = before
                                             after  = after )->changes( ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes(
                    ( component = `ADDRESS-CITY` before = `Athens` after = `Lamia` ) )
      msg = `A component of a nested structure is not reported under its path` ).
  ENDMETHOD.

  METHOD when_table_differs_then_rows.
    DATA(before) = lth_order=>open_order( ).
    DATA(after) = lth_order=>open_order( ).
    INSERT `Mouse` INTO TABLE after-items.

    DATA(changes) = zcl_compare=>difference( before = before
                                             after  = after )->changes( ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `ITEMS` before = `[1 row]` after = `[2 rows]` ) )
      msg = `A changed internal table is not described by its number of rows` ).
  ENDMETHOD.

  METHOD when_same_rows_then_no_change.
    DATA(before) = lth_order=>open_order( ).
    DATA(after) = lth_order=>open_order( ).
    after-items = VALUE #( ( `Keyboard` ) ).

    DATA(difference) = zcl_compare=>difference( before = before
                                                after  = after ).

    cl_abap_unit_assert=>assert_false(
      act = difference->has_changes( )
      msg = `A table with the same rows, filled a second time, is reported as changed` ).
  ENDMETHOD.

  METHOD when_ref_differs_then_bound.
    DATA(before) = lth_order=>open_order( ).
    DATA(after) = lth_order=>open_order( ).
    after-attachment = NEW string( `Invoice` ).

    DATA(changes) = zcl_compare=>difference( before = before
                                             after  = after )->changes( ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes(
                    ( component = `ATTACHMENT` before = `[initial]` after = `[bound]` ) )
      msg = `A changed reference is not described as initial and bound` ).
  ENDMETHOD.

  METHOD given_twin_type_then_compared.
    DATA(before) = VALUE lth_order=>ty_address( city    = `Athens`
                                                country = 'GR' ).
    DATA(after) = VALUE ty_twin_address( city    = `Lamia`
                                         country = 'GR' ).

    DATA(changes) = zcl_compare=>difference( before = before
                                             after  = after )->changes( ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `CITY` before = `Athens` after = `Lamia` ) )
      msg = `Two structures of compatible types, declared separately, are not compared` ).
  ENDMETHOD.

  METHOD when_source_edited_then_kept.
    DATA(before) = lth_order=>open_order( ).
    DATA(after) = lth_order=>open_order( ).
    after-status = 'C'.
    DATA(difference) = zcl_compare=>difference( before = before
                                                after  = after ).

    after-status = 'X'.
    before-id = 1.

    cl_abap_unit_assert=>assert_equals(
      act = difference->changes( )
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `STATUS` before = `O` after = `C` ) )
      msg = `The difference follows later changes of the compared structures` ).
  ENDMETHOD.

  METHOD when_built_then_compares_all.
    DATA(before) = lth_order=>open_order( ).
    DATA(after) = lth_order=>open_order( ).
    after-changed_on = '20260116'.

    DATA(changes) = zcl_compare=>builder( )->build( )->difference( before = before
                                                                   after  = after )->changes( ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes(
                    ( component = `CHANGED_ON` before = `20260115` after = `20260116` ) )
      msg = `A comparison built without an ignore list does not compare every component` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_values DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ENUM ty_light STRUCTURE light,
        red,
        green,
      END OF ENUM ty_light STRUCTURE light.
    TYPES:
      BEGIN OF ty_values,
        quantity TYPE i,
        amount   TYPE p LENGTH 7 DECIMALS 2,
        day      TYPE d,
        hour     TYPE t,
        code     TYPE c LENGTH 10,
        period   TYPE n LENGTH 3,
        bytes    TYPE x LENGTH 2,
        is_paid  TYPE abap_bool,
        light    TYPE ty_light,
      END OF ty_values.

    METHODS when_number_then_leading_sign FOR TESTING RAISING cx_static_check.
    METHODS when_date_time_then_digits FOR TESTING RAISING cx_static_check.
    METHODS when_text_then_no_end_blanks FOR TESTING RAISING cx_static_check.
    METHODS when_numeric_text_then_zeros FOR TESTING RAISING cx_static_check.
    METHODS when_bytes_then_hex_digits FOR TESTING RAISING cx_static_check.
    METHODS when_flag_then_x_or_empty FOR TESTING RAISING cx_static_check.
    METHODS when_enum_then_constant_name FOR TESTING RAISING cx_static_check.

    METHODS changes_between
      IMPORTING before        TYPE ty_values
                after         TYPE ty_values
      RETURNING VALUE(result) TYPE zif_compare_difference=>ty_changes
      RAISING   zcx_compare.

ENDCLASS.


CLASS ltc_values IMPLEMENTATION.

  METHOD when_number_then_leading_sign.
    DATA(changes) = changes_between( before = VALUE #( quantity = 5
                                                       amount   = '12.50' )
                                     after  = VALUE #( quantity = -5
                                                       amount   = '-12.50' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `QUANTITY` before = `5` after = `-5` )
                                                      ( component = `AMOUNT` before = `12.50` after = `-12.50` ) )
      msg = `Numbers do not read with a decimal point and a leading minus sign` ).
  ENDMETHOD.

  METHOD when_date_time_then_digits.
    DATA(changes) = changes_between( before = VALUE #( day  = '20260115'
                                                       hour = '101500' )
                                     after  = VALUE #( day  = '20260116'
                                                       hour = '235959' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `DAY` before = `20260115` after = `20260116` )
                                                      ( component = `HOUR` before = `101500` after = `235959` ) )
      msg = `A date does not read as YYYYMMDD or a time not as hhmmss` ).
  ENDMETHOD.

  METHOD when_text_then_no_end_blanks.
    DATA(changes) = changes_between( before = VALUE #( code = 'AB' )
                                     after  = VALUE #( code = 'A B' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `CODE` before = `AB` after = `A B` ) )
      msg = `A character field does not read without the blanks at its end` ).
  ENDMETHOD.

  METHOD when_numeric_text_then_zeros.
    DATA(changes) = changes_between( before = VALUE #( period = '007' )
                                     after  = VALUE #( period = '012' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `PERIOD` before = `007` after = `012` ) )
      msg = `A numeric text does not read with its leading zeros` ).
  ENDMETHOD.

  METHOD when_bytes_then_hex_digits.
    DATA(changes) = changes_between( before = VALUE #( bytes = '0AFF' )
                                     after  = VALUE #( bytes = '0B00' ) ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `BYTES` before = `0AFF` after = `0B00` ) )
      msg = `A byte field does not read as hexadecimal digits` ).
  ENDMETHOD.

  METHOD when_flag_then_x_or_empty.
    DATA(changes) = changes_between( before = VALUE #( is_paid = abap_false )
                                     after  = VALUE #( is_paid = abap_true ) ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `IS_PAID` before = `` after = `X` ) )
      msg = `A truth value does not read as X or as an empty text` ).
  ENDMETHOD.

  METHOD when_enum_then_constant_name.
    DATA(changes) = changes_between( before = VALUE #( light = light-red )
                                     after  = VALUE #( light = light-green ) ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `LIGHT` before = `RED` after = `GREEN` ) )
      msg = `An enumerated value does not read as the name of its constant` ).
  ENDMETHOD.

  METHOD changes_between.
    result = zcl_compare=>difference( before = before
                                      after  = after )->changes( ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_ignoring DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA before TYPE lth_order=>ty_order.
    DATA after TYPE lth_order=>ty_order.

    METHODS setup.

    METHODS when_ignored_then_not_listed FOR TESTING RAISING cx_static_check.
    METHODS when_only_ignored_then_equal FOR TESTING RAISING cx_static_check.
    METHODS when_lower_case_then_ignored FOR TESTING RAISING cx_static_check.
    METHODS when_parent_ignored_then_none FOR TESTING RAISING cx_static_check.
    METHODS when_path_ignored_then_rest FOR TESTING RAISING cx_static_check.
    METHODS when_list_then_each_ignored FOR TESTING RAISING cx_static_check.
    METHODS when_unknown_name_then_no_harm FOR TESTING RAISING cx_static_check.
    METHODS when_built_then_independent FOR TESTING RAISING cx_static_check.
    METHODS given_blank_name_then_raises FOR TESTING.
    METHODS given_blank_in_list_raises FOR TESTING.

ENDCLASS.


CLASS ltc_ignoring IMPLEMENTATION.

  METHOD setup.
    before = lth_order=>open_order( ).
    after = lth_order=>open_order( ).
    after-status = 'C'.
    after-changed_by = `BORIS`.
    after-changed_on = '20260116'.
  ENDMETHOD.

  METHOD when_ignored_then_not_listed.
    DATA(comparison) = zcl_compare=>builder( )->ignoring( `CHANGED_BY` )->ignoring( `CHANGED_ON` )->build( ).

    DATA(changes) = comparison->difference( before = before
                                            after  = after )->changes( ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `STATUS` before = `O` after = `C` ) )
      msg = `Ignored components are listed, or the remaining change is missing` ).
  ENDMETHOD.

  METHOD when_only_ignored_then_equal.
    after-status = before-status.
    DATA(comparison) = zcl_compare=>builder( )->ignoring( `CHANGED_BY` )->ignoring( `CHANGED_ON` )->build( ).

    DATA(difference) = comparison->difference( before = before
                                               after  = after ).

    cl_abap_unit_assert=>assert_false(
      act = difference->has_changes( )
      msg = `Structures that differ in ignored components only are reported as changed` ).
  ENDMETHOD.

  METHOD when_lower_case_then_ignored.
    DATA(comparison) = zcl_compare=>builder( )->ignoring( ` Changed_By ` )->ignoring( 'changed_on' )->build( ).

    DATA(changes) = comparison->difference( before = before
                                            after  = after )->changes( ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( changes )
      exp = 1
      msg = `A name in lower case or with blanks around it does not ignore the component` ).
  ENDMETHOD.

  METHOD when_parent_ignored_then_none.
    after-address = VALUE #( city    = `Lamia`
                             country = 'DE' ).
    DATA(comparison) = zcl_compare=>builder( )->ignoring( `ADDRESS` )->build( ).

    DATA(difference) = comparison->difference( before = before
                                               after  = after ).

    cl_abap_unit_assert=>assert_false(
      act = difference->has_changed( `ADDRESS` )
      msg = `Ignoring a nested structure does not ignore the components below it` ).
  ENDMETHOD.

  METHOD when_path_ignored_then_rest.
    after-address = VALUE #( city    = `Lamia`
                             country = 'DE' ).
    DATA(comparison) = zcl_compare=>builder( )->ignoring_list( VALUE #( ( `ADDRESS-CITY` )
                                                                        ( `STATUS` )
                                                                        ( `CHANGED_BY` )
                                                                        ( `CHANGED_ON` ) ) )->build( ).

    DATA(changes) = comparison->difference( before = before
                                            after  = after )->changes( ).

    cl_abap_unit_assert=>assert_equals(
      act = changes
      exp = VALUE zif_compare_difference=>ty_changes( ( component = `ADDRESS-COUNTRY` before = `GR` after = `DE` ) )
      msg = `Ignoring one component of a nested structure does not leave the others compared` ).
  ENDMETHOD.

  METHOD when_list_then_each_ignored.
    DATA(administrative) = VALUE string_table( ( `CHANGED_BY` ) ( `CHANGED_ON` ) ( `STATUS` ) ).

    DATA(difference) = zcl_compare=>builder( )->ignoring_list( administrative )->build( )->difference(
                         before = before
                         after  = after ).

    cl_abap_unit_assert=>assert_false(
      act = difference->has_changes( )
      msg = `Not every component of the ignore list was ignored` ).
  ENDMETHOD.

  METHOD when_unknown_name_then_no_harm.
    DATA(comparison) = zcl_compare=>builder( )->ignoring( `DELETED_ON` )->ignoring( `ADDRESS-ZIP_CODE` )->build( ).

    DATA(changes) = comparison->difference( before = before
                                            after  = after )->changes( ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( changes )
      exp = 3
      msg = `An ignored name the structure does not have disturbs the comparison` ).
  ENDMETHOD.

  METHOD when_built_then_independent.
    DATA(builder) = zcl_compare=>builder( )->ignoring( `CHANGED_BY` ).
    DATA(comparison) = builder->build( ).

    builder->ignoring( `STATUS` )->ignoring( `CHANGED_ON` ).

    DATA(changes) = comparison->difference( before = before
                                            after  = after )->changes( ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( changes )
      exp = 2
      msg = `A comparison picks up names the builder was given after build( )` ).
  ENDMETHOD.

  METHOD given_blank_name_then_raises.
    TRY.
        zcl_compare=>builder( )->ignoring( ` ` )->ignoring( `STATUS` )->build( ).

        cl_abap_unit_assert=>fail( `A component without a name was accepted on the ignore list` ).
      CATCH zcx_compare INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `without a name` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_blank_in_list_raises.
    TRY.
        zcl_compare=>builder( )->ignoring_list( VALUE #( ( `STATUS` ) ( `` ) ) )->build( ).

        cl_abap_unit_assert=>fail( `A list with a component without a name was accepted` ).
      CATCH zcx_compare INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `without a name` ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_has_changed DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA difference TYPE REF TO zif_compare_difference.

    METHODS setup RAISING zcx_compare.

    METHODS when_changed_then_true FOR TESTING RAISING cx_static_check.
    METHODS when_unchanged_then_false FOR TESTING RAISING cx_static_check.
    METHODS when_ignored_then_false FOR TESTING RAISING cx_static_check.
    METHODS when_below_changed_then_parent FOR TESTING RAISING cx_static_check.
    METHODS when_path_then_that_component FOR TESTING RAISING cx_static_check.
    METHODS when_lower_case_then_found FOR TESTING RAISING cx_static_check.
    METHODS given_unknown_name_then_raises FOR TESTING.
    METHODS given_unknown_path_then_raises FOR TESTING.
    METHODS given_path_below_field_raises FOR TESTING.

ENDCLASS.


CLASS ltc_has_changed IMPLEMENTATION.

  METHOD setup.
    DATA(before) = lth_order=>open_order( ).
    DATA(after) = lth_order=>open_order( ).
    after-status = 'C'.
    after-address-city = `Lamia`.
    after-changed_by = `BORIS`.

    difference = zcl_compare=>builder( )->ignoring( `CHANGED_BY` )->build( )->difference( before = before
                                                                                          after  = after ).
  ENDMETHOD.

  METHOD when_changed_then_true.
    cl_abap_unit_assert=>assert_true(
      act = difference->has_changed( `STATUS` )
      msg = `A component whose value differs is not reported as changed` ).
  ENDMETHOD.

  METHOD when_unchanged_then_false.
    cl_abap_unit_assert=>assert_false(
      act = difference->has_changed( `PRICE` )
      msg = `A component with the same value on both sides is reported as changed` ).
  ENDMETHOD.

  METHOD when_ignored_then_false.
    cl_abap_unit_assert=>assert_false(
      act = difference->has_changed( `CHANGED_BY` )
      msg = `An ignored component is reported as changed` ).
  ENDMETHOD.

  METHOD when_below_changed_then_parent.
    cl_abap_unit_assert=>assert_true(
      act = difference->has_changed( `ADDRESS` )
      msg = `A nested structure is not reported as changed although a component below it differs` ).
  ENDMETHOD.

  METHOD when_path_then_that_component.
    cl_abap_unit_assert=>assert_true(
      act = difference->has_changed( `ADDRESS-CITY` )
      msg = `The changed component of a nested structure is not found by its path` ).
    cl_abap_unit_assert=>assert_false(
      act = difference->has_changed( `ADDRESS-COUNTRY` )
      msg = `The unchanged component of a nested structure is reported as changed` ).
  ENDMETHOD.

  METHOD when_lower_case_then_found.
    cl_abap_unit_assert=>assert_true(
      act = difference->has_changed( 'address-City' )
      msg = `A name in mixed case does not find the component` ).
  ENDMETHOD.

  METHOD given_unknown_name_then_raises.
    TRY.
        difference->has_changed( `STATUS_CODE` ).

        cl_abap_unit_assert=>fail( `A component the structure does not have was answered as not changed` ).
      CATCH zcx_compare INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `STATUS_CODE` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_unknown_path_then_raises.
    TRY.
        difference->has_changed( `ADDRESS-ZIP_CODE` ).

        cl_abap_unit_assert=>fail( `A path to a component the nested structure does not have was accepted` ).
      CATCH zcx_compare INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `ADDRESS-ZIP_CODE` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_path_below_field_raises.
    TRY.
        difference->has_changed( `PRICE-CURRENCY` ).

        cl_abap_unit_assert=>fail( `A path that leads through an elementary component was accepted` ).
      CATCH zcx_compare INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `PRICE-CURRENCY` ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_control DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES:
      "! The shape of %control in a RAP derived type: one byte per field.
      BEGIN OF ty_control,
        id      TYPE abp_behv_flag,
        status  TYPE abp_behv_flag,
        price   TYPE abp_behv_flag,
        address TYPE abp_behv_flag,
        remark  TYPE abp_behv_flag,
      END OF ty_control.
    TYPES:
      BEGIN OF ty_address_control,
        city    TYPE abp_behv_flag,
        country TYPE abp_behv_flag,
      END OF ty_address_control.
    TYPES:
      BEGIN OF ty_deep_control,
        status  TYPE abp_behv_flag,
        address TYPE ty_address_control,
      END OF ty_deep_control.
    TYPES:
      "! The shape of the X structure of a BAPI: the key as it is, one character per field.
      BEGIN OF ty_x_structure,
        id     TYPE i,
        status TYPE abap_bool,
        price  TYPE abap_bool,
      END OF ty_x_structure.
    TYPES:
      BEGIN OF ty_no_flags,
        id         TYPE i,
        changed_by TYPE string,
      END OF ty_no_flags.

    DATA difference TYPE REF TO zif_compare_difference.

    METHODS setup RAISING zcx_compare.

    METHODS when_changed_then_flag_on FOR TESTING RAISING cx_static_check.
    METHODS when_unchanged_then_flag_off FOR TESTING RAISING cx_static_check.
    METHODS when_below_changed_then_parent FOR TESTING RAISING cx_static_check.
    METHODS when_deep_control_then_by_path FOR TESTING RAISING cx_static_check.
    METHODS when_no_counterpart_then_off FOR TESTING RAISING cx_static_check.
    METHODS when_character_flags_then_x FOR TESTING RAISING cx_static_check.
    METHODS when_not_a_flag_then_untouched FOR TESTING RAISING cx_static_check.
    METHODS when_equal_then_all_off FOR TESTING RAISING cx_static_check.
    METHODS given_unbound_ref_then_raises FOR TESTING.
    METHODS given_table_then_raises FOR TESTING.
    METHODS given_no_flags_then_raises FOR TESTING.

ENDCLASS.


CLASS ltc_control IMPLEMENTATION.

  METHOD setup.
    DATA(before) = lth_order=>open_order( ).
    DATA(after) = lth_order=>open_order( ).
    after-status = 'C'.
    after-address-city = `Lamia`.
    after-changed_by = `BORIS`.

    difference = zcl_compare=>difference( before = before
                                          after  = after ).
  ENDMETHOD.

  METHOD when_changed_then_flag_on.
    DATA control TYPE ty_control.

    difference->write_control( REF #( control ) ).

    cl_abap_unit_assert=>assert_equals(
      act = control-status
      exp = if_abap_behv=>mk-on
      msg = `The flag of a changed component is not switched on` ).
  ENDMETHOD.

  METHOD when_unchanged_then_flag_off.
    DATA(control) = VALUE ty_control( id    = if_abap_behv=>mk-on
                                      price = if_abap_behv=>mk-on ).

    difference->write_control( REF #( control ) ).

    cl_abap_unit_assert=>assert_equals(
      act = control
      exp = VALUE ty_control( status  = if_abap_behv=>mk-on
                              address = if_abap_behv=>mk-on )
      msg = `Flags of unchanged components that were on before are not switched off` ).
  ENDMETHOD.

  METHOD when_below_changed_then_parent.
    DATA control TYPE ty_control.

    difference->write_control( REF #( control ) ).

    cl_abap_unit_assert=>assert_equals(
      act = control-address
      exp = if_abap_behv=>mk-on
      msg = `The flag named like a nested structure is off although a component below it changed` ).
  ENDMETHOD.

  METHOD when_deep_control_then_by_path.
    DATA control TYPE ty_deep_control.

    difference->write_control( REF #( control ) ).

    cl_abap_unit_assert=>assert_equals(
      act = control
      exp = VALUE ty_deep_control( status  = if_abap_behv=>mk-on
                                   address = VALUE #( city = if_abap_behv=>mk-on ) )
      msg = `The flags of a nested control structure are not found by the path of the component` ).
  ENDMETHOD.

  METHOD when_no_counterpart_then_off.
    DATA(control) = VALUE ty_control( remark = if_abap_behv=>mk-on ).

    difference->write_control( REF #( control ) ).

    cl_abap_unit_assert=>assert_equals(
      act = control-remark
      exp = if_abap_behv=>mk-off
      msg = `A flag without a component of its name in the compared structure stays on` ).
  ENDMETHOD.

  METHOD when_character_flags_then_x.
    DATA(flags) = VALUE ty_x_structure( price = abap_true ).

    difference->write_control( REF #( flags ) ).

    cl_abap_unit_assert=>assert_equals(
      act = flags
      exp = VALUE ty_x_structure( status = abap_true )
      msg = `Flags of one character are not set to X for changed and to blank for unchanged components` ).
  ENDMETHOD.

  METHOD when_not_a_flag_then_untouched.
    DATA(flags) = VALUE ty_x_structure( id = 4711 ).

    difference->write_control( REF #( flags ) ).

    cl_abap_unit_assert=>assert_equals(
      act = flags-id
      exp = 4711
      msg = `A component that is not a flag, such as a key field, was overwritten` ).
  ENDMETHOD.

  METHOD when_equal_then_all_off.
    DATA(order) = lth_order=>open_order( ).
    DATA(control) = VALUE ty_control( status = if_abap_behv=>mk-on ).

    zcl_compare=>difference( before = order
                             after  = order )->write_control( REF #( control ) ).

    cl_abap_unit_assert=>assert_initial(
      act = control
      msg = `Flags stay on although the compared structures are equal` ).
  ENDMETHOD.

  METHOD given_unbound_ref_then_raises.
    DATA nothing TYPE REF TO data.

    TRY.
        difference->write_control( nothing ).

        cl_abap_unit_assert=>fail( `An unbound reference was accepted as a control structure` ).
      CATCH zcx_compare INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `points to no control structure` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_table_then_raises.
    DATA controls TYPE STANDARD TABLE OF ty_control WITH EMPTY KEY.

    TRY.
        difference->write_control( REF #( controls ) ).

        cl_abap_unit_assert=>fail( `An internal table was accepted as a control structure` ).
      CATCH zcx_compare INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `does not point to a structure` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_no_flags_then_raises.
    DATA(row) = VALUE ty_no_flags( id         = 4711
                                   changed_by = `ANNA` ).

    TRY.
        difference->write_control( REF #( row ) ).

        cl_abap_unit_assert=>fail( `A structure without a single flag was accepted as a control structure` ).
      CATCH zcx_compare INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `not a control structure` ).
    ENDTRY.

    cl_abap_unit_assert=>assert_equals(
      act = row
      exp = VALUE ty_no_flags( id         = 4711
                               changed_by = `ANNA` )
      msg = `The rejected structure was changed` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_rejections DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES ty_orders TYPE STANDARD TABLE OF lth_order=>ty_order WITH EMPTY KEY.

    METHODS given_elementary_then_raises FOR TESTING.
    METHODS given_table_then_raises FOR TESTING.
    METHODS given_other_type_then_raises FOR TESTING.
    METHODS given_no_structure_then_raises FOR TESTING.

ENDCLASS.


CLASS ltc_rejections IMPLEMENTATION.

  METHOD given_elementary_then_raises.
    TRY.
        zcl_compare=>difference( before = `A`
                                 after  = `B` ).

        cl_abap_unit_assert=>fail( `Two elementary values were accepted for a comparison by component` ).
      CATCH zcx_compare INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `an elementary value` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_table_then_raises.
    DATA(orders) = VALUE ty_orders( ( lth_order=>open_order( ) ) ).

    TRY.
        zcl_compare=>difference( before = orders
                                 after  = orders ).

        cl_abap_unit_assert=>fail( `Two internal tables were accepted for a comparison by component` ).
      CATCH zcx_compare INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `an internal table` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_other_type_then_raises.
    DATA(order) = lth_order=>open_order( ).

    TRY.
        zcl_compare=>difference( before = order
                                 after  = order-address ).

        cl_abap_unit_assert=>fail( `Structures of two different types were compared` ).
      CATCH zcx_compare INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `not of the type of the first` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_no_structure_then_raises.
    DATA(order) = lth_order=>open_order( ).

    TRY.
        zcl_compare=>difference( before = order
                                 after  = order-id ).

        cl_abap_unit_assert=>fail( `A structure was compared with an elementary value` ).
      CATCH zcx_compare INTO DATA(rejection).
        lth_rejection=>assert_names( rejection = rejection
                                     culprit   = `not of the type of the first` ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
