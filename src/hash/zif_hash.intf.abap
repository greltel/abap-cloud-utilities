"! <p class="shorttext synchronized" lang="EN">Hash digest</p>
"! Immutable message digest, the outcome of hashing text or bytes with one
"! algorithm. Renders as raw bytes, hexadecimal or Base64, and compares in
"! constant time so a signature check does not leak timing information.
INTERFACE zif_hash
  PUBLIC.

  "! Name of the algorithm that produced this digest, upper case.
  "! Keyed digests carry the HMAC- prefix, for example HMAC-SHA256.
  "! @parameter result | Algorithm name
  METHODS algorithm
    RETURNING VALUE(result) TYPE string.

  "! The digest as raw bytes.
  "! @parameter result | Digest bytes
  METHODS as_xstring
    RETURNING VALUE(result) TYPE xstring.

  "! The digest as an upper case hexadecimal string, two characters per byte.
  "! @parameter result | Hexadecimal digest
  METHODS as_hex
    RETURNING VALUE(result) TYPE string.

  "! The digest in its Base64 representation.
  "! @parameter result | Base64 digest, padded with = when needed
  METHODS as_base64
    RETURNING VALUE(result) TYPE string.

  "! Number of bytes in the digest, for example 32 for SHA-256.
  "! @parameter result | Digest length in bytes
  METHODS length
    RETURNING VALUE(result) TYPE i.

  "! Compares with another digest in constant time.
  "! @parameter other  | Digest to compare with
  "! @parameter result | abap_true when both digests carry the same bytes
  METHODS equals
    IMPORTING other         TYPE REF TO zif_hash
    RETURNING VALUE(result) TYPE abap_bool.

  "! Compares with raw bytes in constant time.
  "! @parameter expected | Expected digest bytes
  "! @parameter result   | abap_true when the digest carries exactly these bytes
  METHODS matches_bytes
    IMPORTING expected      TYPE xstring
    RETURNING VALUE(result) TYPE abap_bool.

  "! Compares with a hexadecimal string in constant time. Letter case does
  "! not matter; a malformed hexadecimal string never matches.
  "! @parameter hex    | Expected digest as hexadecimal string
  "! @parameter result | abap_true when the digest renders to these characters
  METHODS matches_hex
    IMPORTING hex           TYPE string
    RETURNING VALUE(result) TYPE abap_bool.

ENDINTERFACE.
