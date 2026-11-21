"! <p class="shorttext synchronized" lang="EN">Result of a parallel run</p>
"! What a finished run reports. Immutable.
INTERFACE zif_parallel_run
  PUBLIC.

  "! One outcome per task, in the order of the tasks.
  "!
  "! @parameter result | Outcomes; empty when the run had no task
  METHODS outcomes
    RETURNING VALUE(result) TYPE zif_parallel_outcome=>outcomes.

  "! Tells whether at least one task did not complete.
  "!
  "! @parameter result | abap_true when an outcome reports a failure
  METHODS has_failures
    RETURNING VALUE(result) TYPE abap_bool.

ENDINTERFACE.
