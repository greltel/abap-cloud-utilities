*"* use this source file for your ABAP unit test classes
CLASS ltc_formatting DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS sample_x16 TYPE sysuuid_x16 VALUE 'BAF0A1E75FB01EDFB5E889F53894CA3A'.
    CONSTANTS sample_c32 TYPE sysuuid_c32 VALUE 'BAF0A1E75FB01EDFB5E889F53894CA3A'.
    CONSTANTS sample_c36 TYPE sysuuid_c36 VALUE 'BAF0A1E7-5FB0-1EDF-B5E8-89F53894CA3A'.
    CONSTANTS other_x16 TYPE sysuuid_x16 VALUE '00000000000000000000000000000001'.
    CONSTANTS c22_length TYPE i VALUE 22.

    DATA sample TYPE REF TO zif_uuid.

    METHODS setup.

    METHODS given_x16_when_x16_then_same FOR TESTING.
    METHODS given_x16_when_c32_then_hex FOR TESTING.
    METHODS given_x16_when_c36_then_dashed FOR TESTING.
    METHODS given_x16_when_c22_then_22_chr FOR TESTING.
    METHODS given_zero_then_is_nil FOR TESTING.
    METHODS given_value_then_not_nil FOR TESTING.
    METHODS given_same_bytes_then_equal FOR TESTING.
    METHODS given_other_bytes_then_differ FOR TESTING.
    METHODS given_unbound_then_not_equal FOR TESTING.

ENDCLASS.


CLASS ltc_formatting IMPLEMENTATION.

  METHOD setup.
    sample = zcl_uuid=>for_x16( sample_x16 ).
  ENDMETHOD.

  METHOD given_x16_when_x16_then_same.
    cl_abap_unit_assert=>assert_equals(
      act = sample->as_x16( )
      exp = sample_x16
      msg = 'The raw bytes handed to the facade do not come back unchanged' ).
  ENDMETHOD.

  METHOD given_x16_when_c32_then_hex.
    cl_abap_unit_assert=>assert_equals(
      act = sample->as_c32( )
      exp = sample_c32
      msg = 'The 32 character format is not the upper case hexadecimal of the bytes' ).
  ENDMETHOD.

  METHOD given_x16_when_c36_then_dashed.
    cl_abap_unit_assert=>assert_equals(
      act = sample->as_c36( )
      exp = sample_c36
      msg = 'The 36 character format does not follow the 8-4-4-4-12 pattern' ).
  ENDMETHOD.

  METHOD given_x16_when_c22_then_22_chr.
    cl_abap_unit_assert=>assert_equals(
      act = strlen( sample->as_c22( ) )
      exp = c22_length
      msg = 'The compact format is not 22 characters long' ).
  ENDMETHOD.

  METHOD given_zero_then_is_nil.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_uuid=>for_x16( VALUE sysuuid_x16( ) )->is_nil( )
      exp = abap_true
      msg = 'Sixteen zero bytes are not recognised as the nil UUID' ).
  ENDMETHOD.

  METHOD given_value_then_not_nil.
    cl_abap_unit_assert=>assert_equals(
      act = sample->is_nil( )
      exp = abap_false
      msg = 'A real identifier is reported as the nil UUID' ).
  ENDMETHOD.

  METHOD given_same_bytes_then_equal.
    cl_abap_unit_assert=>assert_equals(
      act = sample->equals( zcl_uuid=>for_x16( sample_x16 ) )
      exp = abap_true
      msg = 'Two identifiers with the same bytes are not equal' ).
  ENDMETHOD.

  METHOD given_other_bytes_then_differ.
    cl_abap_unit_assert=>assert_equals(
      act = sample->equals( zcl_uuid=>for_x16( other_x16 ) )
      exp = abap_false
      msg = 'Identifiers with different bytes are reported equal' ).
  ENDMETHOD.

  METHOD given_unbound_then_not_equal.
    DATA nothing TYPE REF TO zif_uuid.

    cl_abap_unit_assert=>assert_equals(
      act = sample->equals( nothing )
      exp = abap_false
      msg = 'An unbound reference is reported equal to an identifier' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_parsing DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS sample_x16 TYPE sysuuid_x16 VALUE 'BAF0A1E75FB01EDFB5E889F53894CA3A'.
    CONSTANTS sample_c32 TYPE string VALUE `BAF0A1E75FB01EDFB5E889F53894CA3A`.
    CONSTANTS sample_c36 TYPE string VALUE `BAF0A1E7-5FB0-1EDF-B5E8-89F53894CA3A`.

    METHODS given_c36_then_bytes FOR TESTING RAISING cx_static_check.
    METHODS given_lower_c36_then_bytes FOR TESTING RAISING cx_static_check.
    METHODS given_c32_then_bytes FOR TESTING RAISING cx_static_check.
    METHODS given_lower_c32_then_bytes FOR TESTING RAISING cx_static_check.
    METHODS given_c22_then_round_trip FOR TESTING RAISING cx_static_check.
    METHODS given_blanks_around_then_bytes FOR TESTING RAISING cx_static_check.
    METHODS given_c36_then_c32_same_bytes FOR TESTING RAISING cx_static_check.
    METHODS given_wrong_length_then_raise FOR TESTING.
    METHODS given_empty_then_raise FOR TESTING.
    METHODS given_non_hex_c32_then_raise FOR TESTING.
    METHODS given_moved_dash_then_raise FOR TESTING.
    METHODS given_no_dashes_c36_then_raise FOR TESTING.
    METHODS given_bad_c22_then_raise FOR TESTING.

    METHODS assert_rejected
      IMPORTING text TYPE string.

ENDCLASS.


CLASS ltc_parsing IMPLEMENTATION.

  METHOD given_c36_then_bytes.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_uuid=>for_text( sample_c36 )->as_x16( )
      exp = sample_x16
      msg = 'The 36 character form is not parsed into the right bytes' ).
  ENDMETHOD.

  METHOD given_lower_c36_then_bytes.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_uuid=>for_text( to_lower( sample_c36 ) )->as_x16( )
      exp = sample_x16
      msg = 'A lower case 36 character form is not accepted' ).
  ENDMETHOD.

  METHOD given_c32_then_bytes.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_uuid=>for_text( sample_c32 )->as_x16( )
      exp = sample_x16
      msg = 'The 32 character form is not parsed into the right bytes' ).
  ENDMETHOD.

  METHOD given_lower_c32_then_bytes.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_uuid=>for_text( to_lower( sample_c32 ) )->as_x16( )
      exp = sample_x16
      msg = 'A lower case 32 character form is not accepted' ).
  ENDMETHOD.

  METHOD given_c22_then_round_trip.
    DATA(compact) = CONV string( zcl_uuid=>for_x16( sample_x16 )->as_c22( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_uuid=>for_text( compact )->as_x16( )
      exp = sample_x16
      msg = 'The 22 character form does not parse back into the bytes it was made from' ).
  ENDMETHOD.

  METHOD given_blanks_around_then_bytes.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_uuid=>for_text( |  { sample_c36 }  | )->as_x16( )
      exp = sample_x16
      msg = 'Surrounding blanks are not ignored' ).
  ENDMETHOD.

  METHOD given_c36_then_c32_same_bytes.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_uuid=>for_text( sample_c36 )->equals( zcl_uuid=>for_text( sample_c32 ) )
      exp = abap_true
      msg = 'The same identifier parsed from two formats is not equal' ).
  ENDMETHOD.

  METHOD given_wrong_length_then_raise.
    assert_rejected( `BAF0A1E75FB01EDF` ).
  ENDMETHOD.

  METHOD given_empty_then_raise.
    assert_rejected( `` ).
  ENDMETHOD.

  METHOD given_non_hex_c32_then_raise.
    assert_rejected( `ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ` ).
  ENDMETHOD.

  METHOD given_moved_dash_then_raise.
    assert_rejected( `BAF0A1E75-FB0-1EDF-B5E8-89F53894CA3A` ).
  ENDMETHOD.

  METHOD given_no_dashes_c36_then_raise.
    assert_rejected( `BAF0A1E75FB01EDFB5E889F53894CA3A0000` ).
  ENDMETHOD.

  METHOD given_bad_c22_then_raise.
    assert_rejected( `!!!!!!!!!!!!!!!!!!!!!!` ).
  ENDMETHOD.

  METHOD assert_rejected.
    TRY.
        zcl_uuid=>for_text( text ).

        cl_abap_unit_assert=>fail( |{ text } was unexpectedly accepted as a UUID| ).
      CATCH zcx_uuid INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_generation DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_new_then_not_nil FOR TESTING.
    METHODS given_two_new_then_differ FOR TESTING.
    METHODS given_generator_then_differ FOR TESTING.
    METHODS given_new_then_c36_parses_back FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_generation IMPLEMENTATION.

  METHOD given_new_then_not_nil.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_uuid=>new( )->is_nil( )
      exp = abap_false
      msg = 'A freshly created identifier is the nil UUID' ).
  ENDMETHOD.

  METHOD given_two_new_then_differ.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_uuid=>new( )->equals( zcl_uuid=>new( ) )
      exp = abap_false
      msg = 'Two freshly created identifiers are equal' ).
  ENDMETHOD.

  METHOD given_generator_then_differ.
    DATA(generator) = zcl_uuid=>generator( ).

    cl_abap_unit_assert=>assert_equals(
      act = generator->next( )->equals( generator->next( ) )
      exp = abap_false
      msg = 'The generator hands out the same identifier twice' ).
  ENDMETHOD.

  METHOD given_new_then_c36_parses_back.
    DATA(fresh) = zcl_uuid=>new( ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_uuid=>for_text( CONV string( fresh->as_c36( ) ) )->equals( fresh )
      exp = abap_true
      msg = 'A fresh identifier does not survive the round trip through its 36 character form' ).
  ENDMETHOD.

ENDCLASS.
