*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
"! Wraps the released digest and HMAC kernel classes. Every hashing path of the
"! module ends here, so text and bytes are guaranteed to give the same digest
"! for the same UTF-8 payload.
CLASS lcl_engine DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS ensure_known
      IMPORTING algorithm TYPE string
      RAISING   zcx_hash.

    CLASS-METHODS keyed_name
      IMPORTING algorithm     TYPE string
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS text_to_bytes
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_hash.

    CLASS-METHODS digest
      IMPORTING algorithm     TYPE string
                bytes         TYPE xstring
      RETURNING VALUE(result) TYPE REF TO zif_hash
      RAISING   zcx_hash.

    CLASS-METHODS keyed_digest
      IMPORTING algorithm     TYPE string
                key           TYPE xstring
                bytes         TYPE xstring
      RETURNING VALUE(result) TYPE REF TO zif_hash
      RAISING   zcx_hash.

  PRIVATE SECTION.
    CONSTANTS keyed_prefix TYPE string VALUE `HMAC-`.

ENDCLASS.


"! Immutable digest value.
CLASS lcl_digest DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_hash.

    METHODS constructor
      IMPORTING algorithm TYPE string
                bytes     TYPE xstring
                base64    TYPE string.

  PRIVATE SECTION.
    CONSTANTS hex_digits TYPE string VALUE `0123456789ABCDEF`.
    CONSTANTS hex_digits_per_byte TYPE i VALUE 2.

    DATA algorithm TYPE string.
    DATA bytes TYPE xstring.
    DATA base64 TYPE string.

    METHODS is_hex
      IMPORTING hex           TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


"! Immutable algorithm configuration. A key turns it into the HMAC variant.
CLASS lcl_hasher DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_hasher.

    METHODS constructor
      IMPORTING algorithm TYPE string
                key       TYPE xstring OPTIONAL.

  PRIVATE SECTION.
    DATA algorithm TYPE string.
    DATA key TYPE xstring.

    METHODS is_keyed
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS lcl_engine IMPLEMENTATION.

  METHOD ensure_known.
    TRY.
        cl_abap_message_digest=>get_instance( algorithm ).
      CATCH cx_abap_message_digest INTO DATA(rejection).
        RAISE EXCEPTION NEW zcx_hash( text     = |Hash algorithm { algorithm } is not supported|
                                      previous = rejection ).
    ENDTRY.
  ENDMETHOD.

  METHOD keyed_name.
    result = |{ keyed_prefix }{ algorithm }|.
  ENDMETHOD.

  METHOD text_to_bytes.
    TRY.
        result = cl_abap_message_digest=>string_to_xstring( text ).
      CATCH cx_abap_message_digest INTO DATA(encoding_error).
        RAISE EXCEPTION NEW zcx_hash( text     = |Text cannot be encoded as UTF-8 for hashing|
                                      previous = encoding_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD digest.
    TRY.
        cl_abap_message_digest=>calculate_hash_for_raw( EXPORTING if_algorithm     = algorithm
                                                                  if_data          = bytes
                                                        IMPORTING ef_hashxstring   = DATA(digest_bytes)
                                                                  ef_hashb64string = DATA(base64) ).
      CATCH cx_abap_message_digest INTO DATA(failure).
        RAISE EXCEPTION NEW zcx_hash( text     = |{ algorithm } digest cannot be calculated|
                                      previous = failure ).
    ENDTRY.

    result = NEW lcl_digest( algorithm = algorithm
                             bytes     = digest_bytes
                             base64    = base64 ).
  ENDMETHOD.

  METHOD keyed_digest.
    TRY.
        cl_abap_hmac=>calculate_hmac_for_raw( EXPORTING if_algorithm     = algorithm
                                                        if_key           = key
                                                        if_data          = bytes
                                              IMPORTING ef_hmacxstring   = DATA(mac_bytes)
                                                        ef_hmacb64string = DATA(base64) ).
      CATCH cx_abap_message_digest INTO DATA(failure).
        RAISE EXCEPTION NEW zcx_hash( text     = |{ keyed_name( algorithm ) } cannot be calculated|
                                      previous = failure ).
    ENDTRY.

    result = NEW lcl_digest( algorithm = keyed_name( algorithm )
                             bytes     = mac_bytes
                             base64    = base64 ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_digest IMPLEMENTATION.

  METHOD constructor.
    me->algorithm = algorithm.
    me->bytes = bytes.
    me->base64 = base64.
  ENDMETHOD.

  METHOD zif_hash~algorithm.
    result = algorithm.
  ENDMETHOD.

  METHOD zif_hash~as_xstring.
    result = bytes.
  ENDMETHOD.

  METHOD zif_hash~as_hex.
    result = CONV string( bytes ).
  ENDMETHOD.

  METHOD zif_hash~as_base64.
    result = base64.
  ENDMETHOD.

  METHOD zif_hash~length.
    result = xstrlen( bytes ).
  ENDMETHOD.

  METHOD zif_hash~equals.
    IF other IS BOUND.
      result = zif_hash~matches_bytes( other->as_xstring( ) ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_hash~matches_bytes.
    result = cl_abap_message_digest=>is_equal( if_digesta = bytes
                                               if_digestb = expected ).
  ENDMETHOD.

  METHOD zif_hash~matches_hex.
    DATA(candidate) = to_upper( hex ).

    IF is_hex( candidate ) = abap_true.
      result = zif_hash~matches_bytes( CONV xstring( candidate ) ).
    ENDIF.
  ENDMETHOD.

  METHOD is_hex.
    DATA(has_whole_bytes) = xsdbool( strlen( hex ) MOD hex_digits_per_byte = 0 ).
    DATA(has_hex_digits_only) = xsdbool( NOT contains_any_not_of( val = hex
                                                                  sub = hex_digits ) ).

    result = xsdbool( has_whole_bytes = abap_true AND has_hex_digits_only = abap_true ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_hasher IMPLEMENTATION.

  METHOD constructor.
    me->algorithm = algorithm.
    me->key = key.
  ENDMETHOD.

  METHOD is_keyed.
    result = xsdbool( key IS NOT INITIAL ).
  ENDMETHOD.

  METHOD zif_hasher~name.
    result = COND string( WHEN is_keyed( ) = abap_true THEN lcl_engine=>keyed_name( algorithm )
                          ELSE algorithm ).
  ENDMETHOD.

  METHOD zif_hasher~of_text.
    result = zif_hasher~of_bytes( lcl_engine=>text_to_bytes( text ) ).
  ENDMETHOD.

  METHOD zif_hasher~of_bytes.
    IF is_keyed( ) = abap_true.
      result = lcl_engine=>keyed_digest( algorithm = algorithm
                                         key       = key
                                         bytes     = bytes ).
    ELSE.
      result = lcl_engine=>digest( algorithm = algorithm
                                   bytes     = bytes ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_hasher~keyed_with.
    IF key IS INITIAL.
      RAISE EXCEPTION NEW zcx_hash( |A keyed hash needs a non empty key| ).
    ENDIF.

    result = NEW lcl_hasher( algorithm = algorithm
                             key       = key ).
  ENDMETHOD.

  METHOD zif_hasher~keyed_with_text.
    result = zif_hasher~keyed_with( lcl_engine=>text_to_bytes( key ) ).
  ENDMETHOD.

ENDCLASS.
