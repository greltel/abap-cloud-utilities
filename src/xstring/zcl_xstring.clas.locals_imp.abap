*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
"! Converts between byte strings and their text representations. Both the
"! reader and the writer route through this class, so a conversion behaves the
"! same no matter which direction the caller came from.
CLASS lcl_codec DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS text_to_bytes
      IMPORTING text          TYPE string
                code_page     TYPE string
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_xstring.

    CLASS-METHODS bytes_to_text
      IMPORTING bytes         TYPE xstring
                code_page     TYPE string
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_xstring.

    CLASS-METHODS base64_to_bytes
      IMPORTING base64        TYPE string
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_xstring.

    CLASS-METHODS bytes_to_base64
      IMPORTING bytes         TYPE xstring
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_xstring.

    CLASS-METHODS hex_to_bytes
      IMPORTING hex           TYPE string
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_xstring.

  PRIVATE SECTION.
    CONSTANTS default_code_page TYPE string VALUE `UTF-8`.
    CONSTANTS hex_digits TYPE string VALUE `0123456789ABCDEF`.
    CONSTANTS hex_digits_per_byte TYPE i VALUE 2.
    CONSTANTS base64_padding TYPE string VALUE `=`.
    CONSTANTS base64_block_size TYPE i VALUE 4.
    CONSTANTS max_base64_padding TYPE i VALUE 2.
    CONSTANTS base64_digits TYPE string
                            VALUE `ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/`.

    CLASS-METHODS effective_code_page
      IMPORTING code_page     TYPE string
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS reject_invalid_base64
      IMPORTING base64 TYPE string
      RAISING   zcx_xstring.

    CLASS-METHODS reject_invalid_hex
      IMPORTING hex TYPE string
      RAISING   zcx_xstring.

ENDCLASS.


"! Immutable reader on a byte string.
CLASS lcl_reader DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_xstring_reader.

    METHODS constructor
      IMPORTING bytes TYPE xstring.

  PRIVATE SECTION.
    CONSTANTS not_found TYPE i VALUE -1.

    DATA bytes TYPE xstring.

    METHODS offset_of_part
      IMPORTING part          TYPE xstring
      RETURNING VALUE(result) TYPE i.

ENDCLASS.


"! Buffer that grows with every append and is handed out as a reader.
CLASS lcl_writer DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_xstring_writer.

  PRIVATE SECTION.
    DATA buffer TYPE xstring.

    METHODS append
      IMPORTING bytes TYPE xstring.

ENDCLASS.


CLASS lcl_codec IMPLEMENTATION.

  METHOD effective_code_page.
    result = COND string( WHEN code_page IS INITIAL THEN default_code_page
                          ELSE code_page ).
  ENDMETHOD.

  METHOD text_to_bytes.
    DATA(page) = effective_code_page( code_page ).

    TRY.
        result = cl_abap_conv_codepage=>create_out( codepage = page )->convert( text ).
      CATCH cx_parameter_invalid_range INTO DATA(unknown_page).
        RAISE EXCEPTION NEW zcx_xstring( text     = |Code page { page } is not supported|
                                         previous = unknown_page ).
      CATCH cx_sy_conversion_codepage INTO DATA(encoding_error).
        RAISE EXCEPTION NEW zcx_xstring( text     = |Text cannot be encoded in code page { page }|
                                         previous = encoding_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD bytes_to_text.
    DATA(page) = effective_code_page( code_page ).

    TRY.
        result = cl_abap_conv_codepage=>create_in( codepage = page )->convert( bytes ).
      CATCH cx_parameter_invalid_range INTO DATA(unknown_page).
        RAISE EXCEPTION NEW zcx_xstring( text     = |Code page { page } is not supported|
                                         previous = unknown_page ).
      CATCH cx_sy_conversion_codepage INTO DATA(decoding_error).
        RAISE EXCEPTION NEW zcx_xstring( text     = |Bytes cannot be decoded with code page { page }|
                                         previous = decoding_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD bytes_to_base64.
    TRY.
        result = xco_cp=>xstring( bytes )->as_string( xco_cp_binary=>text_encoding->base64 )->value.
      CATCH cx_xco_runtime_exception INTO DATA(encoding_error).
        RAISE EXCEPTION NEW zcx_xstring( text     = |Bytes cannot be encoded as Base64|
                                         previous = encoding_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD base64_to_bytes.
    reject_invalid_base64( base64 ).

    IF base64 IS NOT INITIAL.
      TRY.
          result = xco_cp=>string( base64 )->as_xstring( xco_cp_binary=>text_encoding->base64 )->value.
        CATCH cx_xco_runtime_exception INTO DATA(decoding_error).
          RAISE EXCEPTION NEW zcx_xstring( text     = |Base64 input cannot be decoded|
                                           previous = decoding_error ).
      ENDTRY.
    ENDIF.
  ENDMETHOD.

  METHOD hex_to_bytes.
    reject_invalid_hex( hex ).

    result = CONV xstring( to_upper( hex ) ).
  ENDMETHOD.

  METHOD reject_invalid_base64.
    DATA(size) = strlen( base64 ).

    IF size MOD base64_block_size <> 0.
      RAISE EXCEPTION NEW zcx_xstring( |Base64 length { size } is not a multiple of { base64_block_size }| ).
    ENDIF.

    DATA(padding) = count( val = base64
                           sub = base64_padding ).

    IF padding > max_base64_padding.
      RAISE EXCEPTION NEW zcx_xstring( |Base64 input carries { padding } padding characters| ).
    ENDIF.

    DATA(payload_length) = size - padding.

    IF contains_any_not_of( val = substring( val = base64
                                             len = payload_length )
                            sub = base64_digits ).
      RAISE EXCEPTION NEW zcx_xstring( |Base64 input contains characters outside the alphabet| ).
    ENDIF.
  ENDMETHOD.

  METHOD reject_invalid_hex.
    IF strlen( hex ) MOD hex_digits_per_byte <> 0.
      RAISE EXCEPTION NEW zcx_xstring( |Hexadecimal input has an odd number of characters| ).
    ENDIF.

    IF contains_any_not_of( val = to_upper( hex )
                            sub = hex_digits ).
      RAISE EXCEPTION NEW zcx_xstring( |Hexadecimal input contains non hexadecimal characters| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_reader IMPLEMENTATION.

  METHOD constructor.
    me->bytes = bytes.
  ENDMETHOD.

  METHOD zif_xstring_reader~as_xstring.
    result = bytes.
  ENDMETHOD.

  METHOD zif_xstring_reader~length.
    result = xstrlen( bytes ).
  ENDMETHOD.

  METHOD zif_xstring_reader~as_text.
    result = lcl_codec=>bytes_to_text( bytes     = bytes
                                       code_page = code_page ).
  ENDMETHOD.

  METHOD zif_xstring_reader~as_base64.
    result = lcl_codec=>bytes_to_base64( bytes ).
  ENDMETHOD.

  METHOD zif_xstring_reader~as_hex.
    result = CONV string( bytes ).
  ENDMETHOD.

  METHOD zif_xstring_reader~section.
    DATA(size) = xstrlen( bytes ).

    IF offset < 0 OR length < 0 OR offset + length > size.
      RAISE EXCEPTION NEW zcx_xstring( |Bytes { offset } to { offset + length } exceed the size { size }| ).
    ENDIF.

    DATA(selected) = bytes+offset(length).

    result = NEW lcl_reader( selected ).
  ENDMETHOD.

  METHOD zif_xstring_reader~starts_with.
    DATA(prefix_length) = xstrlen( prefix ).
    DATA(size) = xstrlen( bytes ).

    IF prefix_length > 0 AND prefix_length <= size.
      DATA(head) = bytes+0(prefix_length).

      result = xsdbool( head = prefix ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_xstring_reader~ends_with.
    DATA(suffix_length) = xstrlen( suffix ).
    DATA(size) = xstrlen( bytes ).

    IF suffix_length > 0 AND suffix_length <= size.
      DATA(suffix_offset) = size - suffix_length.
      DATA(tail) = bytes+suffix_offset(suffix_length).

      result = xsdbool( tail = suffix ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_xstring_reader~has_part.
    result = xsdbool( offset_of_part( part ) <> not_found ).
  ENDMETHOD.

  METHOD zif_xstring_reader~offset_of.
    result = offset_of_part( part ).

    IF result = not_found.
      RAISE EXCEPTION NEW zcx_xstring( |Bytes { CONV string( part ) } do not occur| ).
    ENDIF.
  ENDMETHOD.

  METHOD offset_of_part.
    result = not_found.

    DATA(part_length) = xstrlen( part ).
    DATA(last_offset) = xstrlen( bytes ) - part_length.

    IF part_length > 0 AND last_offset >= 0.
      DATA(candidates) = last_offset + 1.

      DO candidates TIMES.
        DATA(candidate) = sy-index - 1.
        DATA(chunk) = bytes+candidate(part_length).

        IF chunk = part.
          result = candidate.
          EXIT.
        ENDIF.
      ENDDO.
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_writer IMPLEMENTATION.

  METHOD append.
    CONCATENATE buffer bytes INTO buffer IN BYTE MODE.
  ENDMETHOD.

  METHOD zif_xstring_writer~append_bytes.
    append( bytes ).

    self = me.
  ENDMETHOD.

  METHOD zif_xstring_writer~append_text.
    append( lcl_codec=>text_to_bytes( text      = text
                                      code_page = code_page ) ).

    self = me.
  ENDMETHOD.

  METHOD zif_xstring_writer~append_base64.
    append( lcl_codec=>base64_to_bytes( base64 ) ).

    self = me.
  ENDMETHOD.

  METHOD zif_xstring_writer~append_hex.
    append( lcl_codec=>hex_to_bytes( hex ) ).

    self = me.
  ENDMETHOD.

  METHOD zif_xstring_writer~build.
    result = NEW lcl_reader( buffer ).
  ENDMETHOD.

ENDCLASS.
