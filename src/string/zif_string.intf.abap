"! <p class="shorttext synchronized" lang="EN">String parsing</p>
"! Immutable view on a text. Cuts the text into its parts and hands back
"! either the parts themselves or a new view on a derived text.
INTERFACE zif_string
  PUBLIC.

  "! Ordered list of text parts, as returned by every split operation.
  TYPES segments TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  TYPES:
    "! One name and value pair, as returned by split_pairs.
    BEGIN OF pair,
      name  TYPE string,
      value TYPE string,
    END OF pair.

  "! Ordered list of name and value pairs.
  TYPES pairs TYPE STANDARD TABLE OF pair WITH EMPTY KEY.

  "! The text behind this view.
  "! @parameter result | Raw text
  METHODS as_text
    RETURNING VALUE(result) TYPE string.

  "! Number of characters.
  "! @parameter result | Character count, zero for an empty text
  METHODS length
    RETURNING VALUE(result) TYPE i.

  "! Removes leading and trailing characters. Only the two ends are touched,
  "! the inner text stays as it is.
  "! @parameter characters | Characters to remove, blanks when left out
  "! @parameter result     | View on the trimmed text
  METHODS trim
    IMPORTING characters    TYPE string DEFAULT ` `
    RETURNING VALUE(result) TYPE REF TO zif_string.

  "! Cuts the text at every occurrence of the delimiter. Empty parts are kept,
  "! so the result mirrors the input one to one.
  "! @parameter delimiter  | Separator, must not be empty
  "! @parameter result     | All parts, one row each
  "! @raising   zcx_string | The delimiter is empty
  METHODS split_by
    IMPORTING delimiter     TYPE string
    RETURNING VALUE(result) TYPE segments
    RAISING   zcx_string.

  "! Cuts the text at every occurrence of the delimiter, trims the blanks off
  "! every part and drops the parts that stay empty.
  "! @parameter delimiter  | Separator, must not be empty
  "! @parameter result     | The parts that carry content
  "! @raising   zcx_string | The delimiter is empty
  METHODS split_tokens
    IMPORTING delimiter     TYPE string
    RETURNING VALUE(result) TYPE segments
    RAISING   zcx_string.

  "! Cuts the text into lines. Windows, Unix and classic Mac line breaks are
  "! all recognized, the line break itself is not part of the result.
  "! @parameter result | All lines, one row each
  METHODS split_lines
    RETURNING VALUE(result) TYPE segments.

  "! Cuts the text into chunks of equal size. The last chunk carries the rest
  "! and can be shorter.
  "! @parameter size       | Characters per chunk, at least one
  "! @parameter result     | All chunks, one row each
  "! @raising   zcx_string | The size is zero or negative
  METHODS split_fixed
    IMPORTING size          TYPE i
    RETURNING VALUE(result) TYPE segments
    RAISING   zcx_string.

  "! Reads the text as a list of name and value pairs, for example
  "! COLOR=RED;SIZE=L. Names and values are trimmed. An entry without the
  "! value delimiter becomes a pair with a name and an empty value.
  "! @parameter pair_delimiter  | Separator between two pairs
  "! @parameter value_delimiter | Separator between name and value
  "! @parameter result          | All pairs, in the order of the text
  "! @raising   zcx_string      | One of the delimiters is empty
  METHODS split_pairs
    IMPORTING pair_delimiter  TYPE string
              value_delimiter TYPE string
    RETURNING VALUE(result)   TYPE pairs
    RAISING   zcx_string.

  "! Cuts out the text enclosed by two markers, the markers excluded.
  "! @parameter after  | Marker in front of the wanted text
  "! @parameter before | Marker behind the wanted text, must not be empty
  "! @parameter result | View on the enclosed text, empty when nothing matches
  METHODS extract_between
    IMPORTING after         TYPE string
              before        TYPE string
    RETURNING VALUE(result) TYPE REF TO zif_string.

  "! Cuts out every text enclosed by the two markers.
  "! @parameter after  | Marker in front of the wanted text
  "! @parameter before | Marker behind the wanted text, must not be empty
  "! @parameter result | All enclosed texts, empty when nothing matches
  METHODS extract_all_between
    IMPORTING after         TYPE string
              before        TYPE string
    RETURNING VALUE(result) TYPE segments.

ENDINTERFACE.
