"! <p class="shorttext synchronized" lang="EN">JSON processing error</p>
"! Raised for any failure while reading or writing a JSON document.
CLASS zcx_json DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Creates the exception with a technical description of the failure.
    "! @parameter text     | What could not be done
    "! @parameter previous | Original exception, when a foreign one is wrapped
    METHODS constructor
      IMPORTING text     TYPE string
                previous TYPE REF TO cx_root OPTIONAL.

    METHODS get_text REDEFINITION.

  PRIVATE SECTION.
    DATA description TYPE string.

ENDCLASS.


CLASS zcx_json IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    description = text.
  ENDMETHOD.

  METHOD get_text.
    result = description.
  ENDMETHOD.

ENDCLASS.
