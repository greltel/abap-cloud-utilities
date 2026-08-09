"! <p class="shorttext synchronized" lang="EN">XString utility</p>
"! Entry point for reading, converting and assembling byte strings. Standalone -
"! depends on nothing but SAP released APIs.
CLASS zcl_xstring DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF code_page,
        utf_8      TYPE string VALUE `UTF-8`,
        utf_16be   TYPE string VALUE `UTF-16BE`,
        utf_16le   TYPE string VALUE `UTF-16LE`,
        iso_8859_1 TYPE string VALUE `ISO-8859-1`,
        iso_8859_7 TYPE string VALUE `ISO-8859-7`,
      END OF code_page.

    "! Opens raw bytes for reading.
    "! @parameter bytes  | Byte string, may be empty
    "! @parameter result | Read access to the bytes
    CLASS-METHODS for_xstring
      IMPORTING bytes         TYPE xstring
      RETURNING VALUE(result) TYPE REF TO zif_xstring_reader.

    "! Encodes text and opens the resulting bytes for reading.
    "! @parameter text        | Text to encode
    "! @parameter code_page   | Code page name, UTF-8 when left empty
    "! @parameter result      | Read access to the encoded bytes
    "! @raising   zcx_xstring | Unknown code page, or the text cannot be encoded
    CLASS-METHODS for_text
      IMPORTING text          TYPE string
                code_page     TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE REF TO zif_xstring_reader
      RAISING   zcx_xstring.

    "! Decodes a Base64 string and opens the resulting bytes for reading.
    "! @parameter base64      | Base64 string without line breaks or blanks
    "! @parameter result      | Read access to the decoded bytes
    "! @raising   zcx_xstring | The input is not a valid Base64 string
    CLASS-METHODS for_base64
      IMPORTING base64        TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_xstring_reader
      RAISING   zcx_xstring.

    "! Decodes a hexadecimal string and opens the resulting bytes for reading.
    "! @parameter hex         | Hexadecimal string, two characters per byte
    "! @parameter result      | Read access to the decoded bytes
    "! @raising   zcx_xstring | The input is not a valid hexadecimal string
    CLASS-METHODS for_hex
      IMPORTING hex           TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_xstring_reader
      RAISING   zcx_xstring.

    "! Opens an empty byte string for assembling.
    "! @parameter result | Write access to a new, empty byte string
    CLASS-METHODS builder
      RETURNING VALUE(result) TYPE REF TO zif_xstring_writer.

ENDCLASS.


CLASS zcl_xstring IMPLEMENTATION.

  METHOD for_xstring.
    result = NEW lcl_reader( bytes ).
  ENDMETHOD.

  METHOD for_text.
    DATA(bytes) = lcl_codec=>text_to_bytes( text      = text
                                            code_page = code_page ).

    result = NEW lcl_reader( bytes ).
  ENDMETHOD.

  METHOD for_base64.
    result = NEW lcl_reader( lcl_codec=>base64_to_bytes( base64 ) ).
  ENDMETHOD.

  METHOD for_hex.
    result = NEW lcl_reader( lcl_codec=>hex_to_bytes( hex ) ).
  ENDMETHOD.

  METHOD builder.
    result = NEW lcl_writer( ).
  ENDMETHOD.

ENDCLASS.
