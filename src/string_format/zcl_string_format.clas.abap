"! <p class="shorttext synchronized" lang="EN">String formatting utility</p>
"! Entry point of the string formatting utility. Hands out an immutable view
"! on a text for padding, alignment and case conversion, and parses text
"! templates with named placeholders.
CLASS zcl_string_format DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Opens a formatting view on the given text.
    "! @parameter text   | Text to format, may be empty
    "! @parameter result | View on the text
    CLASS-METHODS for_text
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_string_format.

    "! Parses a template with named placeholders such as Hello {name}.
    "! @parameter text              | Template text, may be empty
    "! @parameter result            | Parsed template without values
    "! @raising   zcx_string_format | A brace is unbalanced or a placeholder name is invalid
    CLASS-METHODS template
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_string_template
      RAISING   zcx_string_format.

ENDCLASS.


CLASS zcl_string_format IMPLEMENTATION.

  METHOD for_text.
    result = NEW lcl_formatter( text ).
  ENDMETHOD.

  METHOD template.
    result = NEW lcl_template( lcl_template_parser=>parse( text ) ).
  ENDMETHOD.

ENDCLASS.
