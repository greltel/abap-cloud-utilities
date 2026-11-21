"! <p class="shorttext synchronized" lang="EN">Parallel task</p>
"! One unit of work for a {@link zif_parallel_runner}, written by the consumer.
"! The runner sends a copy of the object to a session of its own, calls
"! {@link zif_parallel_task.METH:execute} there and brings the copy back. Only
"! what is serializable makes the journey: a reference to an object whose
"! class is not serializable arrives unbound. The instance handed to the
"! runner is never changed, so the result is read from
"! {@link zif_parallel_outcome.METH:executed_task}.
INTERFACE zif_parallel_task
  PUBLIC.

  INTERFACES if_serializable_object.

  "! Tasks of one run, in the order their outcomes are reported.
  TYPES tasks TYPE STANDARD TABLE OF REF TO zif_parallel_task WITH EMPTY KEY.

  "! Does the work of the task and keeps the result in the attributes of the
  "! object. The method runs in a session of its own: it shares no memory with
  "! the caller and takes care of saving what it changes. An exception that
  "! leaves the method is reported as the failure of this task; the other
  "! tasks of the run are not affected.
  "!
  "! @raising cx_static_check | The work could not be done
  METHODS execute
    RAISING cx_static_check.

ENDINTERFACE.
