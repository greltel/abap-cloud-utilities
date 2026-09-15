" ZCX_TIMESTAMP
"! <p class="shorttext synchronized" lang="EN">Time stamp processing error</p>
"! Raised when a value does not describe a point in time, when a text is not
"! an ISO 8601 / RFC 3339 time stamp, when a time zone is not known to the
"! system, or when a calculation would leave the time line.
CLASS zcx_timestamp DEFINITION
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


CLASS zcx_timestamp IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    description = text.
  ENDMETHOD.

  METHOD get_text.
    result = description.
  ENDMETHOD.

ENDCLASS.
