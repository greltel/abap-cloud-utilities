"! ZCX_LOCK
"! <p class="shorttext synchronized" lang="EN">Lock error</p>
"! Raised when a lock request is described incorrectly, when the lock is held
"! by another user or when the lock server refuses a request.
CLASS zcx_lock DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Creates the exception with a technical description of the failure.
    "! @parameter text      | What could not be done
    "! @parameter previous  | Original exception, when a foreign one is wrapped
    "! @parameter locked_by | User who holds the lock, when a foreign lock is the cause
    METHODS constructor
      IMPORTING text      TYPE string
                previous  TYPE REF TO cx_root OPTIONAL
                locked_by TYPE string OPTIONAL.

    METHODS get_text REDEFINITION.

    "! Tells whether the lock could not be set because another user holds it.
    "! Such a failure is transient: the request may succeed later.
    "! @parameter result | abap_true when a foreign lock is the cause
    METHODS is_foreign_lock
      RETURNING VALUE(result) TYPE abap_bool.

    "! Names the user who holds the lock.
    "! @parameter result | User name, empty when the cause is not a foreign lock
    METHODS locked_by
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    DATA description TYPE string.
    DATA holder TYPE string.

ENDCLASS.


CLASS zcx_lock IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    description = text.
    holder = locked_by.
  ENDMETHOD.

  METHOD get_text.
    result = description.
  ENDMETHOD.

  METHOD is_foreign_lock.
    result = xsdbool( previous IS INSTANCE OF cx_abap_foreign_lock ).
  ENDMETHOD.

  METHOD locked_by.
    result = holder.
  ENDMETHOD.

ENDCLASS.
