"! <p class="shorttext synchronized" lang="EN">Comparison error</p>
"! Raised when two data objects cannot be compared because they are not
"! structures of the same type, when a component is asked for that the
"! compared structure does not have, or when a structure handed in to take
"! the changed components is not a structure of flags.
CLASS zcx_compare DEFINITION
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


CLASS zcx_compare IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    description = text.
  ENDMETHOD.

  METHOD get_text.
    result = description.
  ENDMETHOD.

ENDCLASS.
