*"* use this source file for your ABAP unit test classes
CLASS ltc_conversion DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS hello_text TYPE string VALUE `Hello`.
    CONSTANTS hello_hex TYPE string VALUE `48656C6C6F`.
    CONSTANTS hello_base64 TYPE string VALUE `SGVsbG8=`.

    METHODS given_text_when_hex_then_bytes FOR TESTING RAISING cx_static_check.
    METHODS given_hex_when_hex_then_upper FOR TESTING RAISING cx_static_check.
    METHODS given_text_when_b64_then_enc FOR TESTING RAISING cx_static_check.
    METHODS given_b64_when_text_then_dec FOR TESTING RAISING cx_static_check.
    METHODS given_utf8_2byte_then_one_char FOR TESTING RAISING cx_static_check.
    METHODS given_latin1_2byte_then_2_char FOR TESTING RAISING cx_static_check.
    METHODS given_empty_when_length_zero FOR TESTING RAISING cx_static_check.
    METHODS given_bad_code_page_then_raise FOR TESTING.
    METHODS given_bad_cp_when_read_raises FOR TESTING RAISING cx_static_check.
    METHODS given_broken_utf8_then_raise FOR TESTING RAISING cx_static_check.
    METHODS given_alien_char_then_raise FOR TESTING RAISING cx_static_check.
    METHODS given_raw_bytes_then_hex FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_conversion IMPLEMENTATION.

  METHOD given_text_when_hex_then_bytes.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_xstring=>for_text( hello_text )->as_hex( )
      exp = hello_hex
      msg = 'UTF-8 encoding of Hello does not match the expected bytes' ).
  ENDMETHOD.

  METHOD given_hex_when_hex_then_upper.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_xstring=>for_hex( to_lower( hello_hex ) )->as_hex( )
      exp = hello_hex
      msg = 'Lower case hexadecimal input is not normalised to upper case' ).
  ENDMETHOD.

  METHOD given_text_when_b64_then_enc.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_xstring=>for_text( hello_text )->as_base64( )
      exp = hello_base64
      msg = 'Base64 encoding of Hello does not match the expected string' ).
  ENDMETHOD.

  METHOD given_b64_when_text_then_dec.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_xstring=>for_base64( hello_base64 )->as_text( )
      exp = hello_text
      msg = 'Base64 round trip does not return the original text' ).
  ENDMETHOD.

  METHOD given_utf8_2byte_then_one_char.
    cl_abap_unit_assert=>assert_equals(
      act = strlen( zcl_xstring=>for_hex( `C3A9` )->as_text( ) )
      exp = 1
      msg = 'Two UTF-8 bytes are not decoded into a single character' ).
  ENDMETHOD.

  METHOD given_latin1_2byte_then_2_char.
    cl_abap_unit_assert=>assert_equals(
      act = strlen( zcl_xstring=>for_hex( `C3A9` )->as_text( zcl_xstring=>code_page-iso_8859_1 ) )
      exp = 2
      msg = 'Two ISO-8859-1 bytes are not decoded into two characters' ).
  ENDMETHOD.

  METHOD given_empty_when_length_zero.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_xstring=>for_text( `` )->length( )
      exp = 0
      msg = 'An empty text does not encode into an empty byte string' ).
  ENDMETHOD.

  METHOD given_bad_code_page_then_raise.
    TRY.
        zcl_xstring=>for_text( text      = hello_text
                               code_page = `NO-SUCH-CODE-PAGE` ).

        cl_abap_unit_assert=>fail( 'An unknown code page was unexpectedly accepted' ).
      CATCH zcx_xstring INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_bad_cp_when_read_raises.
    DATA(payload) = zcl_xstring=>for_text( hello_text ).

    TRY.
        payload->as_text( `NO-SUCH-CODE-PAGE` ).

        cl_abap_unit_assert=>fail( 'An unknown code page was accepted while decoding' ).
      CATCH zcx_xstring INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_broken_utf8_then_raise.
    DATA(truncated) = zcl_xstring=>for_hex( `C3` ).

    TRY.
        truncated->as_text( ).

        cl_abap_unit_assert=>fail( 'An incomplete UTF-8 sequence was decoded without complaint' ).
      CATCH zcx_xstring INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_alien_char_then_raise.
    DATA(euro_sign) = zcl_xstring=>for_hex( `E282AC` )->as_text( ).

    TRY.
        zcl_xstring=>for_text( text      = euro_sign
                               code_page = zcl_xstring=>code_page-iso_8859_1 ).

        cl_abap_unit_assert=>fail( 'A character outside the target code page was accepted' ).
      CATCH zcx_xstring INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_raw_bytes_then_hex.
    DATA(raw) = zcl_xstring=>for_hex( hello_hex )->as_xstring( ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_xstring=>for_xstring( raw )->as_hex( )
      exp = hello_hex
      msg = 'Raw bytes handed to the facade do not come back unchanged' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_input_guards DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_odd_hex_then_raise FOR TESTING.
    METHODS given_non_hex_then_raise FOR TESTING.
    METHODS given_short_b64_then_raise FOR TESTING.
    METHODS given_non_b64_then_raise FOR TESTING.
    METHODS given_inner_pad_then_raise FOR TESTING.
    METHODS given_over_padded_then_raise FOR TESTING.

ENDCLASS.


CLASS ltc_input_guards IMPLEMENTATION.

  METHOD given_odd_hex_then_raise.
    TRY.
        zcl_xstring=>for_hex( `4A4` ).

        cl_abap_unit_assert=>fail( 'An odd hexadecimal string was unexpectedly accepted' ).
      CATCH zcx_xstring INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_non_hex_then_raise.
    TRY.
        zcl_xstring=>for_hex( `4G` ).

        cl_abap_unit_assert=>fail( 'A non hexadecimal character was unexpectedly accepted' ).
      CATCH zcx_xstring INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_short_b64_then_raise.
    TRY.
        zcl_xstring=>for_base64( `SGVsbG8` ).

        cl_abap_unit_assert=>fail( 'A truncated Base64 string was unexpectedly accepted' ).
      CATCH zcx_xstring INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_non_b64_then_raise.
    TRY.
        zcl_xstring=>for_base64( `SGVs*G8=` ).

        cl_abap_unit_assert=>fail( 'A Base64 string with an alien character was accepted' ).
      CATCH zcx_xstring INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_inner_pad_then_raise.
    TRY.
        zcl_xstring=>for_base64( `SG=sbG8=` ).

        cl_abap_unit_assert=>fail( 'Base64 padding in the middle was unexpectedly accepted' ).
      CATCH zcx_xstring INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_over_padded_then_raise.
    TRY.
        zcl_xstring=>for_base64( `A===` ).

        cl_abap_unit_assert=>fail( 'A Base64 string with three padding characters was accepted' ).
      CATCH zcx_xstring INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_parsing DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS sample_hex TYPE string VALUE `001122334455`.

    DATA cut TYPE REF TO zif_xstring_reader.

    METHODS setup RAISING cx_static_check.

    METHODS given_mid_offset_then_section FOR TESTING RAISING cx_static_check.
    METHODS given_last_offset_then_section FOR TESTING RAISING cx_static_check.
    METHODS given_over_size_section_raises FOR TESTING.
    METHODS given_prefix_then_starts_with FOR TESTING RAISING cx_static_check.
    METHODS given_alien_then_no_prefix FOR TESTING RAISING cx_static_check.
    METHODS given_suffix_then_ends_with FOR TESTING RAISING cx_static_check.
    METHODS given_part_then_offset_found FOR TESTING RAISING cx_static_check.
    METHODS given_absent_part_then_raises FOR TESTING.
    METHODS given_part_then_has_part FOR TESTING RAISING cx_static_check.
    METHODS given_absent_then_has_no_part FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_parsing IMPLEMENTATION.

  METHOD setup.
    cut = zcl_xstring=>for_hex( sample_hex ).
  ENDMETHOD.

  METHOD given_mid_offset_then_section.
    cl_abap_unit_assert=>assert_equals(
      act = cut->section( offset = 2
                          length = 2 )->as_hex( )
      exp = `2233`
      msg = 'Section in the middle of the byte string returns the wrong bytes' ).
  ENDMETHOD.

  METHOD given_last_offset_then_section.
    cl_abap_unit_assert=>assert_equals(
      act = cut->section( offset = 4
                          length = 2 )->as_hex( )
      exp = `4455`
      msg = 'Section up to the last byte returns the wrong bytes' ).
  ENDMETHOD.

  METHOD given_over_size_section_raises.
    TRY.
        cut->section( offset = 4
                      length = 3 ).

        cl_abap_unit_assert=>fail( 'A section beyond the last byte was unexpectedly accepted' ).
      CATCH zcx_xstring INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_prefix_then_starts_with.
    cl_abap_unit_assert=>assert_equals(
      act = cut->starts_with( zcl_xstring=>for_hex( `0011` )->as_xstring( ) )
      exp = abap_true
      msg = 'The leading bytes are not recognised as a prefix' ).
  ENDMETHOD.

  METHOD given_alien_then_no_prefix.
    cl_abap_unit_assert=>assert_equals(
      act = cut->starts_with( zcl_xstring=>for_hex( `2233` )->as_xstring( ) )
      exp = abap_false
      msg = 'Bytes from the middle are wrongly recognised as a prefix' ).
  ENDMETHOD.

  METHOD given_suffix_then_ends_with.
    cl_abap_unit_assert=>assert_equals(
      act = cut->ends_with( zcl_xstring=>for_hex( `4455` )->as_xstring( ) )
      exp = abap_true
      msg = 'The trailing bytes are not recognised as a suffix' ).
  ENDMETHOD.

  METHOD given_part_then_offset_found.
    cl_abap_unit_assert=>assert_equals(
      act = cut->offset_of( zcl_xstring=>for_hex( `2233` )->as_xstring( ) )
      exp = 2
      msg = 'The position of an embedded byte sequence is wrong' ).
  ENDMETHOD.

  METHOD given_absent_part_then_raises.
    TRY.
        cut->offset_of( zcl_xstring=>for_hex( `AFFE` )->as_xstring( ) ).

        cl_abap_unit_assert=>fail( 'An absent byte sequence was unexpectedly reported as found' ).
      CATCH zcx_xstring INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_part_then_has_part.
    cl_abap_unit_assert=>assert_equals(
      act = cut->has_part( zcl_xstring=>for_hex( `2233` )->as_xstring( ) )
      exp = abap_true
      msg = 'An embedded byte sequence is not reported as present' ).
  ENDMETHOD.

  METHOD given_absent_then_has_no_part.
    cl_abap_unit_assert=>assert_equals(
      act = cut->has_part( zcl_xstring=>for_hex( `AFFE` )->as_xstring( ) )
      exp = abap_false
      msg = 'An absent byte sequence is wrongly reported as present' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_assembling DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_parts_then_build_joins FOR TESTING RAISING cx_static_check.
    METHODS given_nothing_when_build_empty FOR TESTING RAISING cx_static_check.
    METHODS given_raw_bytes_then_appended FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_assembling IMPLEMENTATION.

  METHOD given_parts_then_build_joins.
    DATA(assembled) = zcl_xstring=>builder(
      )->append_text( `AB`
      )->append_hex( `00FF`
      )->append_base64( `eg==`
      )->build( ).

    cl_abap_unit_assert=>assert_equals(
      act = assembled->as_hex( )
      exp = `414200FF7A`
      msg = 'The assembled byte string does not contain all parts in order' ).
  ENDMETHOD.

  METHOD given_nothing_when_build_empty.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_xstring=>builder( )->build( )->length( )
      exp = 0
      msg = 'A builder without any append does not produce an empty byte string' ).
  ENDMETHOD.

  METHOD given_raw_bytes_then_appended.
    DATA(raw) = zcl_xstring=>for_hex( `CAFE` )->as_xstring( ).

    DATA(assembled) = zcl_xstring=>builder( )->append_bytes( raw )->append_bytes( raw )->build( ).

    cl_abap_unit_assert=>assert_equals(
      act = assembled->as_hex( )
      exp = `CAFECAFE`
      msg = 'Appending raw bytes twice does not double the byte string' ).
  ENDMETHOD.

ENDCLASS.
