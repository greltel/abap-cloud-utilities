"! <p class="shorttext synchronized" lang="EN">Outcome of a parallel task</p>
"! What became of one task of a run: the executed copy, or the reason why
"! there is none. Immutable.
INTERFACE zif_parallel_outcome
  PUBLIC.

  "! Outcomes of one run, one per task, in the order of the tasks.
  TYPES outcomes TYPE STANDARD TABLE OF REF TO zif_parallel_outcome WITH EMPTY KEY.

  "! Position of the task in the table handed to the runner.
  "!
  "! @parameter result | 1 for the first task
  METHODS position
    RETURNING VALUE(result) TYPE i.

  "! Tells whether the task did not complete.
  "!
  "! @parameter result | abap_true when the task raised, was terminated or was never started
  METHODS has_failed
    RETURNING VALUE(result) TYPE abap_bool.

  "! Why the task did not complete: the exception that left it with its class
  "! and text, followed by its causes, or what the session reported when it
  "! was terminated.
  "!
  "! @parameter result | Technical reason; empty when the task completed
  METHODS failure_reason
    RETURNING VALUE(result) TYPE string.

  "! The copy of the task that was executed, in the state it had when its work
  "! was done. Cast it to the task class to read the result.
  "!
  "! @parameter result       | Executed copy, never the instance handed to the runner
  "! @raising   zcx_parallel | The task failed, so there is no executed copy
  METHODS executed_task
    RETURNING VALUE(result) TYPE REF TO zif_parallel_task
    RAISING   zcx_parallel.

ENDINTERFACE.
