*"* use this source file for your ABAP unit test classes
CLASS ltc_digests DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS abc TYPE string VALUE `abc`.
    CONSTANTS abc_bytes TYPE xstring VALUE '616263'.
    CONSTANTS sha_256_of_abc TYPE string
                             VALUE `BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD`.
    CONSTANTS sha_256_of_abc_b64 TYPE string VALUE `ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0=`.
    CONSTANTS sha_1_of_abc TYPE string VALUE `A9993E364706816ABA3E25717850C26C9CD0D89D`.
    CONSTANTS md5_of_empty TYPE string VALUE `D41D8CD98F00B204E9800998ECF8427E`.
    CONSTANTS sha_384_of_abc TYPE string
                             VALUE `CB00753F45A35E8BB5A03D699AC65007272C32AB0EDED163` &
                                   `1A8B605A43FF5BED8086072BA1E7CC2358BAECA134C825A7`.
    CONSTANTS sha_512_of_abc_start TYPE string VALUE `DDAF35A193617ABACC417349AE20413112E6FA4E89A97EA2`.
    CONSTANTS sha_512_length TYPE i VALUE 64.
    CONSTANTS e_acute_utf8 TYPE xstring VALUE 'C3A9'.

    METHODS given_abc_when_sha256_then_hex FOR TESTING RAISING cx_static_check.
    METHODS given_abc_when_sha256_then_b64 FOR TESTING RAISING cx_static_check.
    METHODS given_abc_when_sha1_then_hex FOR TESTING RAISING cx_static_check.
    METHODS given_empty_when_md5_then_hex FOR TESTING RAISING cx_static_check.
    METHODS given_abc_when_sha384_then_hex FOR TESTING RAISING cx_static_check.
    METHODS given_abc_when_sha512_then_len FOR TESTING RAISING cx_static_check.
    METHODS given_abc_when_sha512_then_hex FOR TESTING RAISING cx_static_check.
    METHODS given_text_and_bytes_then_same FOR TESTING RAISING cx_static_check.
    METHODS given_non_ascii_then_utf8_hash FOR TESTING RAISING cx_static_check.
    METHODS given_empty_bytes_then_digest FOR TESTING RAISING cx_static_check.
    METHODS given_sha256_when_name_then_up FOR TESTING RAISING cx_static_check.
    METHODS given_lower_name_then_normal FOR TESTING RAISING cx_static_check.
    METHODS given_unknown_name_then_raise FOR TESTING.
    METHODS given_empty_name_then_raise FOR TESTING.

ENDCLASS.


CLASS ltc_digests IMPLEMENTATION.

  METHOD given_abc_when_sha256_then_hex.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hash=>sha_256( )->of_text( abc )->as_hex( )
      exp = sha_256_of_abc
      msg = 'SHA-256 of abc does not match the published test vector' ).
  ENDMETHOD.

  METHOD given_abc_when_sha256_then_b64.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hash=>sha_256( )->of_text( abc )->as_base64( )
      exp = sha_256_of_abc_b64
      msg = 'Base64 rendering of the SHA-256 digest is wrong' ).
  ENDMETHOD.

  METHOD given_abc_when_sha1_then_hex.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hash=>sha_1( )->of_text( abc )->as_hex( )
      exp = sha_1_of_abc
      msg = 'SHA-1 of abc does not match the published test vector' ).
  ENDMETHOD.

  METHOD given_empty_when_md5_then_hex.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hash=>md5( )->of_text( `` )->as_hex( )
      exp = md5_of_empty
      msg = 'MD5 of the empty text does not match the published test vector' ).
  ENDMETHOD.

  METHOD given_abc_when_sha384_then_hex.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hash=>sha_384( )->of_text( abc )->as_hex( )
      exp = sha_384_of_abc
      msg = 'SHA-384 of abc does not match the published test vector' ).
  ENDMETHOD.

  METHOD given_abc_when_sha512_then_len.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hash=>sha_512( )->of_text( abc )->length( )
      exp = sha_512_length
      msg = 'A SHA-512 digest is not 64 bytes long' ).
  ENDMETHOD.

  METHOD given_abc_when_sha512_then_hex.
    DATA(hex) = zcl_hash=>sha_512( )->of_text( abc )->as_hex( ).

    cl_abap_unit_assert=>assert_equals(
      act = substring( val = hex
                       len = strlen( sha_512_of_abc_start ) )
      exp = sha_512_of_abc_start
      msg = 'SHA-512 of abc does not match the published test vector' ).
  ENDMETHOD.

  METHOD given_text_and_bytes_then_same.
    DATA(from_text) = zcl_hash=>sha_256( )->of_text( abc ).
    DATA(from_bytes) = zcl_hash=>sha_256( )->of_bytes( abc_bytes ).

    cl_abap_unit_assert=>assert_equals(
      act = from_text->equals( from_bytes )
      exp = abap_true
      msg = 'Hashing text and hashing its UTF-8 bytes give different digests' ).
  ENDMETHOD.

  METHOD given_non_ascii_then_utf8_hash.
    DATA(e_acute) = cl_abap_conv_codepage=>create_in( )->convert( e_acute_utf8 ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_hash=>sha_256( )->of_text( e_acute )->as_hex( )
      exp = zcl_hash=>sha_256( )->of_bytes( e_acute_utf8 )->as_hex( )
      msg = 'A non ASCII character is not hashed through its UTF-8 encoding' ).
  ENDMETHOD.

  METHOD given_empty_bytes_then_digest.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hash=>md5( )->of_bytes( VALUE xstring( ) )->as_hex( )
      exp = md5_of_empty
      msg = 'An empty byte string is not hashed like the empty text' ).
  ENDMETHOD.

  METHOD given_sha256_when_name_then_up.
    DATA(digest) = zcl_hash=>sha_256( )->of_text( abc ).

    cl_abap_unit_assert=>assert_equals(
      act = digest->algorithm( )
      exp = zcl_hash=>algorithm-sha_256
      msg = 'The digest does not report the algorithm that produced it' ).
  ENDMETHOD.

  METHOD given_lower_name_then_normal.
    DATA(hasher) = zcl_hash=>for_algorithm( ` sha256 ` ).

    cl_abap_unit_assert=>assert_equals(
      act = hasher->name( )
      exp = zcl_hash=>algorithm-sha_256
      msg = 'A lower case algorithm name with blanks is not normalised' ).
  ENDMETHOD.

  METHOD given_unknown_name_then_raise.
    TRY.
        zcl_hash=>for_algorithm( `NO-SUCH-ALGORITHM` ).

        cl_abap_unit_assert=>fail( 'An unknown algorithm name was unexpectedly accepted' ).
      CATCH zcx_hash INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_empty_name_then_raise.
    TRY.
        zcl_hash=>for_algorithm( `` ).

        cl_abap_unit_assert=>fail( 'An empty algorithm name was unexpectedly accepted' ).
      CATCH zcx_hash INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_keyed DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS key_text TYPE string VALUE `key`.
    CONSTANTS key_bytes TYPE xstring VALUE '6B6579'.
    CONSTANTS message TYPE string VALUE `The quick brown fox jumps over the lazy dog`.
    CONSTANTS hmac_sha_256 TYPE string
                           VALUE `F7BC83F430538424B13298E6AA6FB143EF4D59A14946175997479DBC2D1A3CD8`.
    CONSTANTS hmac_sha_256_name TYPE string VALUE `HMAC-SHA256`.

    METHODS given_key_when_sha256_then_hex FOR TESTING RAISING cx_static_check.
    METHODS given_text_key_then_same_hmac FOR TESTING RAISING cx_static_check.
    METHODS given_key_when_name_then_hmac FOR TESTING RAISING cx_static_check.
    METHODS given_key_then_digest_labelled FOR TESTING RAISING cx_static_check.
    METHODS given_key_then_plain_unchanged FOR TESTING RAISING cx_static_check.
    METHODS given_key_then_differs_plain FOR TESTING RAISING cx_static_check.
    METHODS given_two_keys_then_last_wins FOR TESTING RAISING cx_static_check.
    METHODS given_empty_key_then_raise FOR TESTING.
    METHODS given_empty_text_key_raises FOR TESTING.

ENDCLASS.


CLASS ltc_keyed IMPLEMENTATION.

  METHOD given_key_when_sha256_then_hex.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hash=>sha_256( )->keyed_with( key_bytes )->of_text( message )->as_hex( )
      exp = hmac_sha_256
      msg = 'HMAC-SHA256 does not match the published test vector' ).
  ENDMETHOD.

  METHOD given_text_key_then_same_hmac.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hash=>sha_256( )->keyed_with_text( key_text )->of_text( message )->as_hex( )
      exp = hmac_sha_256
      msg = 'A text key is not applied through its UTF-8 bytes' ).
  ENDMETHOD.

  METHOD given_key_when_name_then_hmac.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hash=>sha_256( )->keyed_with( key_bytes )->name( )
      exp = hmac_sha_256_name
      msg = 'A keyed hasher does not announce itself as HMAC' ).
  ENDMETHOD.

  METHOD given_key_then_digest_labelled.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_hash=>sha_256( )->keyed_with( key_bytes )->of_text( message )->algorithm( )
      exp = hmac_sha_256_name
      msg = 'A keyed digest does not report the HMAC algorithm' ).
  ENDMETHOD.

  METHOD given_key_then_plain_unchanged.
    DATA(plain) = zcl_hash=>sha_256( ).

    plain->keyed_with( key_bytes ).

    cl_abap_unit_assert=>assert_equals(
      act = plain->name( )
      exp = zcl_hash=>algorithm-sha_256
      msg = 'keyed_with changed the hasher it was called on instead of returning a new one' ).
  ENDMETHOD.

  METHOD given_key_then_differs_plain.
    DATA(plain) = zcl_hash=>sha_256( )->of_text( message ).
    DATA(keyed) = zcl_hash=>sha_256( )->keyed_with( key_bytes )->of_text( message ).

    cl_abap_unit_assert=>assert_equals(
      act = keyed->equals( plain )
      exp = abap_false
      msg = 'A keyed digest equals the plain digest of the same message' ).
  ENDMETHOD.

  METHOD given_two_keys_then_last_wins.
    DATA(rekeyed) = zcl_hash=>sha_256( )->keyed_with_text( `other` )->keyed_with( key_bytes ).

    cl_abap_unit_assert=>assert_equals(
      act = rekeyed->of_text( message )->as_hex( )
      exp = hmac_sha_256
      msg = 'Setting a key twice does not replace the first key' ).
  ENDMETHOD.

  METHOD given_empty_key_then_raise.
    TRY.
        zcl_hash=>sha_256( )->keyed_with( VALUE xstring( ) ).

        cl_abap_unit_assert=>fail( 'An empty key was unexpectedly accepted' ).
      CATCH zcx_hash INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_empty_text_key_raises.
    TRY.
        zcl_hash=>sha_256( )->keyed_with_text( `` ).

        cl_abap_unit_assert=>fail( 'An empty text key was unexpectedly accepted' ).
      CATCH zcx_hash INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_comparison DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS abc TYPE string VALUE `abc`.
    CONSTANTS sha_1_of_abc TYPE string VALUE `A9993E364706816ABA3E25717850C26C9CD0D89D`.
    CONSTANTS sha_1_of_abc_bytes TYPE xstring VALUE 'A9993E364706816ABA3E25717850C26C9CD0D89D'.

    DATA digest TYPE REF TO zif_hash.

    METHODS setup RAISING cx_static_check.

    METHODS given_same_digest_then_equal FOR TESTING RAISING cx_static_check.
    METHODS given_other_text_then_differ FOR TESTING RAISING cx_static_check.
    METHODS given_unbound_then_not_equal FOR TESTING.
    METHODS given_same_bytes_then_match FOR TESTING.
    METHODS given_other_bytes_then_no_hit FOR TESTING.
    METHODS given_upper_hex_then_match FOR TESTING.
    METHODS given_lower_hex_then_match FOR TESTING.
    METHODS given_other_hex_then_no_match FOR TESTING.
    METHODS given_odd_hex_then_no_match FOR TESTING.
    METHODS given_non_hex_then_no_match FOR TESTING.
    METHODS given_digest_then_xstring FOR TESTING.

ENDCLASS.


CLASS ltc_comparison IMPLEMENTATION.

  METHOD setup.
    digest = zcl_hash=>sha_1( )->of_text( abc ).
  ENDMETHOD.

  METHOD given_same_digest_then_equal.
    cl_abap_unit_assert=>assert_equals(
      act = digest->equals( zcl_hash=>sha_1( )->of_text( abc ) )
      exp = abap_true
      msg = 'Two digests of the same text are not equal' ).
  ENDMETHOD.

  METHOD given_other_text_then_differ.
    cl_abap_unit_assert=>assert_equals(
      act = digest->equals( zcl_hash=>sha_1( )->of_text( `abd` ) )
      exp = abap_false
      msg = 'Digests of different texts are reported equal' ).
  ENDMETHOD.

  METHOD given_unbound_then_not_equal.
    DATA nothing TYPE REF TO zif_hash.

    cl_abap_unit_assert=>assert_equals(
      act = digest->equals( nothing )
      exp = abap_false
      msg = 'An unbound reference is reported equal to a digest' ).
  ENDMETHOD.

  METHOD given_same_bytes_then_match.
    cl_abap_unit_assert=>assert_equals(
      act = digest->matches_bytes( sha_1_of_abc_bytes )
      exp = abap_true
      msg = 'The digest does not match its own bytes' ).
  ENDMETHOD.

  METHOD given_other_bytes_then_no_hit.
    cl_abap_unit_assert=>assert_equals(
      act = digest->matches_bytes( CONV xstring( 'A9993E' ) )
      exp = abap_false
      msg = 'A prefix of the digest is reported as a match' ).
  ENDMETHOD.

  METHOD given_upper_hex_then_match.
    cl_abap_unit_assert=>assert_equals(
      act = digest->matches_hex( sha_1_of_abc )
      exp = abap_true
      msg = 'The digest does not match its own upper case hexadecimal rendering' ).
  ENDMETHOD.

  METHOD given_lower_hex_then_match.
    cl_abap_unit_assert=>assert_equals(
      act = digest->matches_hex( to_lower( sha_1_of_abc ) )
      exp = abap_true
      msg = 'A lower case hexadecimal string is not recognised' ).
  ENDMETHOD.

  METHOD given_other_hex_then_no_match.
    cl_abap_unit_assert=>assert_equals(
      act = digest->matches_hex( `A9993E364706816ABA3E25717850C26C9CD0D89E` )
      exp = abap_false
      msg = 'A hexadecimal string differing in the last digit is reported as a match' ).
  ENDMETHOD.

  METHOD given_odd_hex_then_no_match.
    cl_abap_unit_assert=>assert_equals(
      act = digest->matches_hex( `A9993E3` )
      exp = abap_false
      msg = 'A hexadecimal string with an odd length is reported as a match' ).
  ENDMETHOD.

  METHOD given_non_hex_then_no_match.
    cl_abap_unit_assert=>assert_equals(
      act = digest->matches_hex( `not hex at all!` )
      exp = abap_false
      msg = 'A non hexadecimal string is reported as a match' ).
  ENDMETHOD.

  METHOD given_digest_then_xstring.
    cl_abap_unit_assert=>assert_equals(
      act = digest->as_xstring( )
      exp = sha_1_of_abc_bytes
      msg = 'The raw digest bytes do not match the hexadecimal rendering' ).
  ENDMETHOD.

ENDCLASS.
