"! <p class="shorttext synchronized" lang="EN">XString read access</p>
"! Immutable view on a byte string. Converts it into the usual text
"! representations and gives positional access to the single bytes.
INTERFACE zif_xstring_reader
  PUBLIC.

  "! The bytes behind this reader.
  "! @parameter result | Raw byte string
  METHODS as_xstring
    RETURNING VALUE(result) TYPE xstring.

  "! Number of bytes.
  "! @parameter result | Byte count, zero for an empty byte string
  METHODS length
    RETURNING VALUE(result) TYPE i.

  "! Decodes the bytes into text.
  "! @parameter code_page   | Code page name, UTF-8 when left empty
  "! @parameter result      | Decoded text
  "! @raising   zcx_xstring | Unknown code page, or the bytes cannot be decoded
  METHODS as_text
    IMPORTING code_page     TYPE string OPTIONAL
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_xstring.

  "! The bytes in their Base64 representation.
  "! @parameter result      | Base64 string, padded with = when needed
  "! @raising   zcx_xstring | The bytes cannot be encoded
  METHODS as_base64
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_xstring.

  "! The bytes as an uppercase hexadecimal string, two characters per byte.
  "! @parameter result | Hexadecimal string, empty for an empty byte string
  METHODS as_hex
    RETURNING VALUE(result) TYPE string.

  "! Cuts a part out of the byte string.
  "! @parameter offset      | Zero based position of the first byte
  "! @parameter length      | Number of bytes to cut
  "! @parameter result      | Reader on the cut out bytes
  "! @raising   zcx_xstring | The requested part lies outside the byte string
  METHODS section
    IMPORTING offset        TYPE i
              length        TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_xstring_reader
    RAISING   zcx_xstring.

  "! Tests whether the byte string begins with the given bytes.
  "! @parameter prefix | Bytes expected at the beginning
  "! @parameter result | abap_true when the byte string begins with prefix
  METHODS starts_with
    IMPORTING prefix        TYPE xstring
    RETURNING VALUE(result) TYPE abap_bool.

  "! Tests whether the byte string ends with the given bytes.
  "! @parameter suffix | Bytes expected at the end
  "! @parameter result | abap_true when the byte string ends with suffix
  METHODS ends_with
    IMPORTING suffix        TYPE xstring
    RETURNING VALUE(result) TYPE abap_bool.

  "! Tests whether the given bytes occur anywhere in the byte string.
  "! @parameter part   | Bytes to look for
  "! @parameter result | abap_true when part occurs at least once
  METHODS has_part
    IMPORTING part          TYPE xstring
    RETURNING VALUE(result) TYPE abap_bool.

  "! Position of the first occurrence of the given bytes.
  "! Guard the call with {@link zif_xstring_reader.METH:has_part} when the
  "! absence of part is a regular case rather than an error.
  "! @parameter part        | Bytes to look for
  "! @parameter result      | Zero based position of the first occurrence
  "! @raising   zcx_xstring | part does not occur in the byte string
  METHODS offset_of
    IMPORTING part          TYPE xstring
    RETURNING VALUE(result) TYPE i
    RAISING   zcx_xstring.

ENDINTERFACE.
