"! ZCL_LOCK
"! <p class="shorttext synchronized" lang="EN">Lock utility</p>
"! Entry point for setting and releasing locks of a customer lock object on top
"! of the released CL_ABAP_LOCK_OBJECT_FACTORY. Standalone - depends on
"! nothing but SAP released APIs.
CLASS zcl_lock DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Lock modes for with_mode( ). write (E) allows the same user to lock
    "! again, exclusive (X) does not; shared (S) lets several users read;
    "! optimistic (O) is set while data is displayed and promote_optimistic (R)
    "! turns it into an exclusive lock before the change is saved.
    CONSTANTS:
      BEGIN OF mode,
        write              TYPE if_abap_lock_object=>tv_mode VALUE if_abap_lock_object=>cs_mode-write_lock,
        shared             TYPE if_abap_lock_object=>tv_mode VALUE if_abap_lock_object=>cs_mode-shared_lock,
        exclusive          TYPE if_abap_lock_object=>tv_mode VALUE if_abap_lock_object=>cs_mode-exclusive_lock,
        optimistic         TYPE if_abap_lock_object=>tv_mode VALUE if_abap_lock_object=>cs_mode-optimistic_lock,
        promote_optimistic TYPE if_abap_lock_object=>tv_mode VALUE if_abap_lock_object=>cs_mode-promote_optimistic_lock,
      END OF mode.

    "! Lock owners for in_scope( ). dialog keeps the lock in the session until
    "! it is released or the session ends; update, the default, passes it to
    "! the update task with COMMIT WORK; dialog_and_update does both.
    CONSTANTS:
      BEGIN OF scope,
        dialog            TYPE if_abap_lock_object=>tv_scope VALUE if_abap_lock_object=>cs_scope-no_update_program,
        update            TYPE if_abap_lock_object=>tv_scope VALUE if_abap_lock_object=>cs_scope-update_program,
        dialog_and_update TYPE if_abap_lock_object=>tv_scope
                          VALUE if_abap_lock_object=>cs_scope-interactive_and_update_program,
      END OF scope.

    "! Addresses a lock object. Nothing is locked yet; the object is looked up
    "! when a request is acquired. The name is case insensitive, surrounding
    "! blanks are ignored.
    "! @parameter name     | Lock object, up to 30 characters
    "! @parameter result   | Request for the update owner that does not wait
    "! @raising   zcx_lock | The name is empty or too long
    CLASS-METHODS for_object
      IMPORTING name          TYPE csequence
      RETURNING VALUE(result) TYPE REF TO zif_lock_request
      RAISING   zcx_lock.

    "! Releases every lock the session holds, whichever request set it. Locks
    "! that COMMIT WORK has already passed to the update task belong to the
    "! update task and are released when it ends.
    CLASS-METHODS release_all.

ENDCLASS.


CLASS zcl_lock IMPLEMENTATION.

  METHOD for_object.
    DATA(target) = VALUE request( object = lcl_identifier=>object( name )
                                  scope  = scope-update
                                  wait   = if_abap_lock_object=>cs_wait-no ).

    result = NEW lcl_request( request = target
                              engine  = NEW lcl_engine( ) ).
  ENDMETHOD.

  METHOD release_all.
    NEW lcl_engine( )->lif_engine~dequeue_all( ).
  ENDMETHOD.

ENDCLASS.
