"! <p class="shorttext synchronized" lang="EN">XString write access</p>
"! Assembles a byte string from parts of different representations. Every
"! append method returns the same instance, so the calls can be chained;
"! {@link zif_xstring_writer.METH:build} closes the chain.
INTERFACE zif_xstring_writer
  PUBLIC.

  "! Appends raw bytes.
  "! @parameter bytes | Bytes to append
  "! @parameter self  | Same instance, for chaining
  METHODS append_bytes
    IMPORTING bytes       TYPE xstring
    RETURNING VALUE(self) TYPE REF TO zif_xstring_writer.

  "! Encodes text and appends the resulting bytes.
  "! @parameter text        | Text to append
  "! @parameter code_page   | Code page name, UTF-8 when left empty
  "! @parameter self        | Same instance, for chaining
  "! @raising   zcx_xstring | Unknown code page, or the text cannot be encoded
  METHODS append_text
    IMPORTING text        TYPE string
              code_page   TYPE string OPTIONAL
    RETURNING VALUE(self) TYPE REF TO zif_xstring_writer
    RAISING   zcx_xstring.

  "! Decodes a Base64 string and appends the resulting bytes.
  "! @parameter base64      | Base64 string without line breaks or blanks
  "! @parameter self        | Same instance, for chaining
  "! @raising   zcx_xstring | The input is not a valid Base64 string
  METHODS append_base64
    IMPORTING base64      TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_xstring_writer
    RAISING   zcx_xstring.

  "! Decodes a hexadecimal string and appends the resulting bytes.
  "! @parameter hex         | Hexadecimal string, two characters per byte
  "! @parameter self        | Same instance, for chaining
  "! @raising   zcx_xstring | The input is not a valid hexadecimal string
  METHODS append_hex
    IMPORTING hex         TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_xstring_writer
    RAISING   zcx_xstring.

  "! Closes the chain and hands out the assembled byte string.
  "! @parameter result | Reader on everything appended so far
  METHODS build
    RETURNING VALUE(result) TYPE REF TO zif_xstring_reader.

ENDINTERFACE.
