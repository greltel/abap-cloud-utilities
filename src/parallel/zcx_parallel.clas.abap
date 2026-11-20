"! <p class="shorttext synchronized" lang="EN">Parallel processing error</p>
"! Raised when a runner cannot be configured, when a run cannot be started or
"! is not reported completely, and when the executed copy of a failed task is
"! requested. A task that fails does not raise it: that is in its outcome.
CLASS zcx_parallel DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Creates the exception with a technical description of the failure.
    "!
    "! @parameter text     | What could not be done
    "! @parameter previous | Original exception, when a foreign one is wrapped
    METHODS constructor
      IMPORTING text     TYPE string
                previous TYPE REF TO cx_root OPTIONAL.

    METHODS get_text REDEFINITION.

  PRIVATE SECTION.
    DATA description TYPE string.

ENDCLASS.


CLASS zcx_parallel IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    description = text.
  ENDMETHOD.

  METHOD get_text.
    result = description.
  ENDMETHOD.

ENDCLASS.
