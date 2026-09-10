"! ZIF_LOCK
"! <p class="shorttext synchronized" lang="EN">Held lock</p>
"! A lock that acquire( ) has set. Release it as soon as the protected work is
"! done. A lock that is not released explicitly ends with its owner: with the
"! update task for update scope, with the session for dialog scope.
INTERFACE zif_lock
  PUBLIC.

  "! Releases the lock. Releasing twice is harmless: only the first call
  "! reaches the lock server.
  "! @raising zcx_lock | The lock server refused the release
  METHODS release
    RAISING zcx_lock.

  "! Tells whether this handle holds the lock: acquire( ) succeeded and
  "! release( ) has not been called yet. A release through release_all( ) or
  "! through the end of the update task is not visible here.
  "! @parameter result | abap_true while the lock is held through this handle
  METHODS is_held
    RETURNING VALUE(result) TYPE abap_bool.

  "! Name of the lock object.
  "! @parameter result | Lock object name in upper case
  METHODS object
    RETURNING VALUE(result) TYPE string.

  "! Describes the lock for logs and messages: the lock object and the
  "! parameter values, for example "Lock EZORDER with ORDER_ID = 4711".
  "! @parameter result | One line of text
  METHODS describe
    RETURNING VALUE(result) TYPE string.

ENDINTERFACE.
