"! <p class="shorttext synchronized" lang="EN">User context could not be determined</p>
"! Raised when a released context API cannot supply the requested value.
"! The causing exception is kept in the previous attribute.
CLASS zcx_sy DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Creates the exception with a fixed English text.
    "! @parameter text     | Description of what could not be determined
    "! @parameter previous | Exception that caused this one
    METHODS constructor
      IMPORTING text     TYPE string
                previous TYPE REF TO cx_root OPTIONAL.

    METHODS get_text REDEFINITION.

  PRIVATE SECTION.
    DATA description TYPE string.

ENDCLASS.


CLASS zcx_sy IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    description = text.
  ENDMETHOD.

  METHOD get_text.
    result = description.
  ENDMETHOD.

ENDCLASS.
