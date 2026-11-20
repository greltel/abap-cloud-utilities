"! <p class="shorttext synchronized" lang="EN">Parallel runner</p>
"! Executes tasks and returns when all of them are done. Consumers inject this
"! interface; in their unit tests {@link zcl_parallel.METH:sequential} takes
"! its place, so no test ever starts a session.
INTERFACE zif_parallel_runner
  PUBLIC.

  "! Executes every task and reports one outcome per task. A task that fails
  "! neither stops the others nor raises: the failure is in its outcome. The
  "! method commits nothing itself, but handing work to other sessions ends
  "! the database transaction of the caller, so it is not called while changes
  "! of the caller are pending.
  "!
  "! @parameter tasks        | Tasks to execute; an empty table gives a result without outcomes
  "! @parameter result       | Outcomes of the run
  "! @raising   zcx_parallel | The tasks cannot be run as handed in - a reference is not bound,
  "!                          a task cannot be serialized - or not every task was reported
  METHODS run
    IMPORTING tasks         TYPE zif_parallel_task=>tasks
    RETURNING VALUE(result) TYPE REF TO zif_parallel_run
    RAISING   zcx_parallel.

ENDINTERFACE.
