"! <p class="shorttext synchronized" lang="EN">Hash utility</p>
"! Entry point for message digests and keyed hashes (HMAC). Standalone -
"! depends on nothing but SAP released APIs.
CLASS zcl_hash DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF algorithm,
        md5     TYPE string VALUE `MD5`,
        sha_1   TYPE string VALUE `SHA1`,
        sha_256 TYPE string VALUE `SHA256`,
        sha_384 TYPE string VALUE `SHA384`,
        sha_512 TYPE string VALUE `SHA512`,
      END OF algorithm.

    "! MD5. Kept for interoperability with legacy checksums only.
    "! @parameter result | Hasher for MD5
    CLASS-METHODS md5
      RETURNING VALUE(result) TYPE REF TO zif_hasher.

    "! SHA-1. Kept for interoperability only; prefer SHA-256 for new designs.
    "! @parameter result | Hasher for SHA-1
    CLASS-METHODS sha_1
      RETURNING VALUE(result) TYPE REF TO zif_hasher.

    "! SHA-256, the sensible default.
    "! @parameter result | Hasher for SHA-256
    CLASS-METHODS sha_256
      RETURNING VALUE(result) TYPE REF TO zif_hasher.

    "! SHA-384.
    "! @parameter result | Hasher for SHA-384
    CLASS-METHODS sha_384
      RETURNING VALUE(result) TYPE REF TO zif_hasher.

    "! SHA-512.
    "! @parameter result | Hasher for SHA-512
    CLASS-METHODS sha_512
      RETURNING VALUE(result) TYPE REF TO zif_hasher.

    "! Any algorithm the system supports, addressed by name. The name is
    "! matched without regard to letter case and validated immediately.
    "! @parameter name     | Algorithm name, see the algorithm constants
    "! @parameter result   | Hasher for the algorithm
    "! @raising   zcx_hash | The algorithm is unknown on this system
    CLASS-METHODS for_algorithm
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_hasher
      RAISING   zcx_hash.

ENDCLASS.


CLASS zcl_hash IMPLEMENTATION.

  METHOD md5.
    result = NEW lcl_hasher( algorithm = algorithm-md5 ).
  ENDMETHOD.

  METHOD sha_1.
    result = NEW lcl_hasher( algorithm = algorithm-sha_1 ).
  ENDMETHOD.

  METHOD sha_256.
    result = NEW lcl_hasher( algorithm = algorithm-sha_256 ).
  ENDMETHOD.

  METHOD sha_384.
    result = NEW lcl_hasher( algorithm = algorithm-sha_384 ).
  ENDMETHOD.

  METHOD sha_512.
    result = NEW lcl_hasher( algorithm = algorithm-sha_512 ).
  ENDMETHOD.

  METHOD for_algorithm.
    DATA(normalised) = to_upper( condense( name ) ).

    lcl_engine=>ensure_known( normalised ).

    result = NEW lcl_hasher( algorithm = normalised ).
  ENDMETHOD.

ENDCLASS.

