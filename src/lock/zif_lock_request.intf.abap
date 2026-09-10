"! ZIF_LOCK_REQUEST
"! <p class="shorttext synchronized" lang="EN">Lock request</p>
"! Describes one lock to set: the lock object, the values of its lock
"! parameters, the lock mode per table, the owner and whether to wait for a
"! foreign lock. Immutable: every configuration method returns a new request
"! while the original keeps its settings, so one base request serves many keys.
INTERFACE zif_lock_request
  PUBLIC.

  "! Sets the value of one lock parameter. Parameters that are not set are
  "! generic: the lock then covers every value of that field. The name is case
  "! insensitive, surrounding blanks are ignored. The value keeps its type on
  "! the way to the lock server, so pass it in the type of the locked field.
  "! @parameter name     | Lock parameter as named in the lock object, usually the field name
  "! @parameter value    | Value to lock
  "! @parameter result   | New request with the parameter set
  "! @raising   zcx_lock | The name is empty, longer than 30 characters or already set
  METHODS with
    IMPORTING name          TYPE csequence
              value         TYPE simple
    RETURNING VALUE(result) TYPE REF TO zif_lock_request
    RAISING   zcx_lock.

  "! Overrides the lock mode for one of the tables of the lock object. Without
  "! an override the mode maintained in the lock object applies.
  "! @parameter table    | Table as listed in the lock object
  "! @parameter mode     | One of the mode constants of {@link zcl_lock}
  "! @parameter result   | New request with the mode set
  "! @raising   zcx_lock | The table name is empty, longer than 30 characters or already set,
  "!                      or the mode is not one of the constants
  METHODS with_mode
    IMPORTING table         TYPE csequence
              mode          TYPE if_abap_lock_object=>tv_mode
    RETURNING VALUE(result) TYPE REF TO zif_lock_request
    RAISING   zcx_lock.

  "! Sets the lock owner. The default is the update owner: the lock is passed
  "! to the update task with COMMIT WORK and released when the update ends.
  "! @parameter scope    | One of the scope constants of {@link zcl_lock}
  "! @parameter result   | New request with the scope set
  "! @raising   zcx_lock | The scope is not one of the constants
  METHODS in_scope
    IMPORTING scope         TYPE if_abap_lock_object=>tv_scope
    RETURNING VALUE(result) TYPE REF TO zif_lock_request
    RAISING   zcx_lock.

  "! Lets acquire( ) wait for a foreign lock to be released instead of failing
  "! at once. How long it waits is a system setting; when the lock is still
  "! held afterwards, acquire( ) fails as it would without waiting.
  "! @parameter result | New request that waits
  METHODS waiting
    RETURNING VALUE(result) TYPE REF TO zif_lock_request.

  "! Sets the lock.
  "! @parameter result   | The lock held; release it with release( )
  "! @raising   zcx_lock | Another user holds the lock (is_foreign_lock( ) is true and
  "!                      locked_by( ) names the user), the lock object does not exist,
  "!                      a parameter is not defined in it, or a value does not fit its field
  METHODS acquire
    RETURNING VALUE(result) TYPE REF TO zif_lock
    RAISING   zcx_lock.

ENDINTERFACE.
