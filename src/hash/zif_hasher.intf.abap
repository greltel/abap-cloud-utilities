"! <p class="shorttext synchronized" lang="EN">Hash algorithm</p>
"! A configured hash algorithm. Immutable: keyed_with( ) returns a new hasher
"! for the HMAC variant while the original keeps producing plain digests.
INTERFACE zif_hasher
  PUBLIC.

  "! Algorithm name in upper case, prefixed with HMAC- once a key was set.
  "! @parameter result | Algorithm name, for example SHA256 or HMAC-SHA256
  METHODS name
    RETURNING VALUE(result) TYPE string.

  "! Hashes text. The text is encoded as UTF-8 before hashing, so the digest
  "! equals of_bytes( ) called with the UTF-8 bytes of the same text.
  "! @parameter text     | Text to hash, may be empty
  "! @parameter result   | Digest of the text
  "! @raising   zcx_hash | The text cannot be encoded, or the algorithm is unavailable
  METHODS of_text
    IMPORTING text          TYPE string
    RETURNING VALUE(result) TYPE REF TO zif_hash
    RAISING   zcx_hash.

  "! Hashes raw bytes.
  "! @parameter bytes    | Bytes to hash, may be empty
  "! @parameter result   | Digest of the bytes
  "! @raising   zcx_hash | The algorithm is unavailable on this system
  METHODS of_bytes
    IMPORTING bytes         TYPE xstring
    RETURNING VALUE(result) TYPE REF TO zif_hash
    RAISING   zcx_hash.

  "! Turns the algorithm into its keyed variant (HMAC). Calling it on a hasher
  "! that already carries a key replaces the key.
  "! @parameter key      | Secret key as raw bytes
  "! @parameter result   | New hasher that produces keyed digests
  "! @raising   zcx_hash | The key is empty
  METHODS keyed_with
    IMPORTING key           TYPE xstring
    RETURNING VALUE(result) TYPE REF TO zif_hasher
    RAISING   zcx_hash.

  "! Turns the algorithm into its keyed variant (HMAC) with a text key.
  "! The key is encoded as UTF-8, so it equals keyed_with( ) called with the
  "! UTF-8 bytes of the same text.
  "! @parameter key      | Secret key as text
  "! @parameter result   | New hasher that produces keyed digests
  "! @raising   zcx_hash | The key is empty or cannot be encoded
  METHODS keyed_with_text
    IMPORTING key           TYPE string
    RETURNING VALUE(result) TYPE REF TO zif_hasher
    RAISING   zcx_hash.

ENDINTERFACE.
