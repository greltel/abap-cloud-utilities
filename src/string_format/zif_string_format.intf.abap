"! <p class="shorttext synchronized" lang="EN">String formatting</p>
"! Immutable view on a text that hands back a new view for every formatting
"! step: padding and alignment, cutting to a width and case conversion. The
"! chain is closed with as_text( ). Widths and lengths count characters.
INTERFACE zif_string_format
  PUBLIC.

  "! Ordered list of the words a text is made of.
  TYPES word_list TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  "! The text behind this view.
  "! @parameter result | Formatted text
  METHODS as_text
    RETURNING VALUE(result) TYPE string.

  "! Pads the text on the right until it reaches the width. A text that is
  "! already as wide or wider is returned unchanged.
  "! @parameter width             | Wanted width, zero or more
  "! @parameter fill              | Exactly one character, a blank when left out
  "! @parameter result            | View on the padded text
  "! @raising   zcx_string_format | The width is negative or the fill is not one character
  METHODS align_left
    IMPORTING width         TYPE i
              fill          TYPE string DEFAULT ` `
    RETURNING VALUE(result) TYPE REF TO zif_string_format
    RAISING   zcx_string_format.

  "! Pads the text on the left until it reaches the width. A text that is
  "! already as wide or wider is returned unchanged. With a zero as fill this
  "! is the classic zero padding of a number.
  "! @parameter width             | Wanted width, zero or more
  "! @parameter fill              | Exactly one character, a blank when left out
  "! @parameter result            | View on the padded text
  "! @raising   zcx_string_format | The width is negative or the fill is not one character
  METHODS align_right
    IMPORTING width         TYPE i
              fill          TYPE string DEFAULT ` `
    RETURNING VALUE(result) TYPE REF TO zif_string_format
    RAISING   zcx_string_format.

  "! Pads the text on both sides until it reaches the width. When the padding
  "! cannot be split evenly the right side gets one character more. A text
  "! that is already as wide or wider is returned unchanged.
  "! @parameter width             | Wanted width, zero or more
  "! @parameter fill              | Exactly one character, a blank when left out
  "! @parameter result            | View on the padded text
  "! @raising   zcx_string_format | The width is negative or the fill is not one character
  METHODS center
    IMPORTING width         TYPE i
              fill          TYPE string DEFAULT ` `
    RETURNING VALUE(result) TYPE REF TO zif_string_format
    RAISING   zcx_string_format.

  "! Cuts the text so that it is not wider than the width. A shorter text is
  "! returned unchanged and is not padded.
  "! @parameter width             | Maximum width, zero or more
  "! @parameter result            | View on the cut text
  "! @raising   zcx_string_format | The width is negative
  METHODS truncate
    IMPORTING width         TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_string_format
    RAISING   zcx_string_format.

  "! Cuts the text so that it is not wider than the width and ends the cut text
  "! with the marker, so the reader sees that something is missing. A text that
  "! fits is returned unchanged.
  "! @parameter width             | Maximum width including the marker
  "! @parameter marker            | Text that ends a cut text, three dots when left out
  "! @parameter result            | View on the shortened text
  "! @raising   zcx_string_format | The width is smaller than the marker
  METHODS shorten
    IMPORTING width         TYPE i
              marker        TYPE string DEFAULT `...`
    RETURNING VALUE(result) TYPE REF TO zif_string_format
    RAISING   zcx_string_format.

  "! Converts every letter to upper case.
  "! @parameter result | View on the converted text
  METHODS to_upper_case
    RETURNING VALUE(result) TYPE REF TO zif_string_format.

  "! Converts every letter to lower case.
  "! @parameter result | View on the converted text
  METHODS to_lower_case
    RETURNING VALUE(result) TYPE REF TO zif_string_format.

  "! Converts the first character to upper case and leaves the rest as it is.
  "! @parameter result | View on the converted text
  METHODS capitalize
    RETURNING VALUE(result) TYPE REF TO zif_string_format.

  "! Every word starts with an upper case letter and continues in lower case,
  "! words are separated by one blank: Order Number.
  "! @parameter result | View on the converted text
  METHODS to_title_case
    RETURNING VALUE(result) TYPE REF TO zif_string_format.

  "! First word in lower case, every further word capitalized, no separators:
  "! orderNumber.
  "! @parameter result | View on the converted text
  METHODS to_camel_case
    RETURNING VALUE(result) TYPE REF TO zif_string_format.

  "! Every word capitalized, no separators: OrderNumber.
  "! @parameter result | View on the converted text
  METHODS to_pascal_case
    RETURNING VALUE(result) TYPE REF TO zif_string_format.

  "! Every word in lower case, joined with underscores: order_number.
  "! @parameter result | View on the converted text
  METHODS to_snake_case
    RETURNING VALUE(result) TYPE REF TO zif_string_format.

  "! Every word in lower case, joined with hyphens: order-number.
  "! @parameter result | View on the converted text
  METHODS to_kebab_case
    RETURNING VALUE(result) TYPE REF TO zif_string_format.

  "! The words the text is made of, as the case conversions see them. A word
  "! ends at a character that is neither letter nor digit, at a change from
  "! lower to upper case and in front of the last upper case letter of a run
  "! that is followed by lower case: HTTPRequest is HTTP and Request. Digits
  "! stay with the word they follow.
  "! @parameter result | Words in the order of the text, separators dropped
  METHODS words
    RETURNING VALUE(result) TYPE word_list.

ENDINTERFACE.
