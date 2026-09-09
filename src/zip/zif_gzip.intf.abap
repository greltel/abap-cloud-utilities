"! <p class="shorttext synchronized" lang="EN">GZIP codec</p>
"! Compresses and decompresses GZIP streams (RFC 1952), the format of HTTP
"! content encoding gzip and of .gz files. Immutable: with_level( ) returns a
"! new codec while the original keeps its level.
INTERFACE zif_gzip
  PUBLIC.

  "! Returns a codec that compresses with the given level.
  "! @parameter level   | 0 (stored) to 9 (best), see the level constants of {@link zcl_zip}
  "! @parameter result  | New codec with that level
  "! @raising   zcx_zip | The level is outside 0 to 9
  METHODS with_level
    IMPORTING level         TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_gzip
    RAISING   zcx_zip.

  "! Compresses bytes into a GZIP stream.
  "! @parameter bytes   | Bytes to compress, may be empty
  "! @parameter result  | GZIP stream
  "! @raising   zcx_zip | The kernel could not compress the bytes
  METHODS compress
    IMPORTING bytes         TYPE xstring
    RETURNING VALUE(result) TYPE xstring
    RAISING   zcx_zip.

  "! Compresses text into a GZIP stream. The text is encoded as UTF-8 first,
  "! so the stream equals compress( ) called with the UTF-8 bytes of the text.
  "! @parameter text    | Text to compress, may be empty
  "! @parameter result  | GZIP stream
  "! @raising   zcx_zip | The text cannot be encoded, or the kernel could not compress it
  METHODS compress_text
    IMPORTING text          TYPE string
    RETURNING VALUE(result) TYPE xstring
    RAISING   zcx_zip.

  "! Decompresses a GZIP stream.
  "! @parameter gzip    | GZIP stream
  "! @parameter result  | The original bytes
  "! @raising   zcx_zip | The bytes are not a GZIP stream, or the stream is corrupt
  METHODS decompress
    IMPORTING gzip          TYPE xstring
    RETURNING VALUE(result) TYPE xstring
    RAISING   zcx_zip.

  "! Decompresses a GZIP stream and decodes the result as UTF-8 text.
  "! @parameter gzip    | GZIP stream
  "! @parameter result  | The original text
  "! @raising   zcx_zip | The bytes are not a GZIP stream, the stream is corrupt, or it is not UTF-8
  METHODS decompress_text
    IMPORTING gzip          TYPE xstring
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_zip.

  "! Tells whether bytes start with the GZIP signature. A quick check for an
  "! HTTP body or a file before decompressing; it does not prove the stream
  "! is intact.
  "! @parameter bytes  | Bytes to inspect
  "! @parameter result | abap_true when the bytes carry the GZIP signature
  METHODS is_gzip
    IMPORTING bytes         TYPE xstring
    RETURNING VALUE(result) TYPE abap_bool.

ENDINTERFACE.
