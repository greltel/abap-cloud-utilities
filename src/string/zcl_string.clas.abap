"! <p class="shorttext synchronized" lang="EN">String parsing utility</p>
"! Entry point of the string utility. Hands out an immutable view on a text
"! that cuts the text into the parts a caller is interested in.
CLASS zcl_string DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Opens a view on the given text.
    "! @parameter text   | Text to work on, may be empty
    "! @parameter result | View on the text
    CLASS-METHODS for_text
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_string.

ENDCLASS.


CLASS zcl_string IMPLEMENTATION.

  METHOD for_text.
    result = NEW lcl_string( text ).
  ENDMETHOD.

ENDCLASS.
