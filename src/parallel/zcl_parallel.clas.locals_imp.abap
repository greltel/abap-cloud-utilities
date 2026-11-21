*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
TYPES:
  "! Limits of a run. An initial component means that the consumer set no
  "! limit and the parallel framework applies its own.
  BEGIN OF run_limits,
    max_processes   TYPE i,
    timeout_seconds TYPE i,
  END OF run_limits.


"! Carries one task into another session and back. It is what the parallel
"! framework sees, so the task of the consumer has no part in IF_ABAP_PARALLEL.
"! An exception that leaves the task is kept as text: the exception object
"! itself is not guaranteed to survive the way back.
CLASS lcl_envelope DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES if_abap_parallel.

    METHODS constructor
      IMPORTING task TYPE REF TO zif_parallel_task.

    METHODS task
      RETURNING VALUE(result) TYPE REF TO zif_parallel_task.

    METHODS failure_reason
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    CONSTANTS cause_separator TYPE string VALUE `; caused by `.

    DATA payload TYPE REF TO zif_parallel_task.
    DATA failure TYPE string.

    METHODS reason_of
      IMPORTING error         TYPE REF TO cx_root
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


"! Envelopes of one run, in the order of the tasks.
TYPES envelopes TYPE STANDARD TABLE OF REF TO lcl_envelope WITH EMPTY KEY.

TYPES:
  "! What an engine reports for one envelope: the executed copy, or the reason
  "! why there is none.
  BEGIN OF execution,
    envelope     TYPE REF TO lcl_envelope,
    abort_reason TYPE string,
  END OF execution.

"! Executions of one run, one per envelope, in the order of the envelopes.
TYPES executions TYPE STANDARD TABLE OF execution WITH EMPTY KEY.


"! Seam to the place where envelopes are executed. Kept to one call, so that
"! everything above it can be tested with a fake that starts no session.
INTERFACE lif_engine.

  METHODS execute
    IMPORTING envelopes     TYPE envelopes
              limits        TYPE run_limits
    RETURNING VALUE(result) TYPE executions
    RAISING   zcx_parallel.

ENDINTERFACE.


"! The real engine: hands the envelopes to CL_ABAP_PARALLEL, which executes
"! each one in a dialog work process of its own and waits for all of them.
"! It is the only class that knows the parallel framework.
CLASS lcl_parallel_engine DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES lif_engine.

  PRIVATE SECTION.
    METHODS framework_for
      IMPORTING limits        TYPE run_limits
      RETURNING VALUE(result) TYPE REF TO cl_abap_parallel.

ENDCLASS.


"! Executes the envelopes one after the other in the session of the caller.
"! Each one is copied through serialization first, as a session boundary would
"! do it. A caller that tests with this engine therefore sees what a parallel
"! run does: the instance handed in stays untouched, and what does not survive
"! serialization is missing here as well.
CLASS lcl_sequential_engine DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES lif_engine.

  PRIVATE SECTION.
    METHODS copy_of
      IMPORTING envelope      TYPE REF TO lcl_envelope
                position      TYPE i
      RETURNING VALUE(result) TYPE REF TO lcl_envelope
      RAISING   zcx_parallel.

ENDCLASS.


"! Outcome of a task that did its work: it has the executed copy and no reason.
CLASS lcl_completed_outcome DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_parallel_outcome.

    METHODS constructor
      IMPORTING position TYPE i
                task     TYPE REF TO zif_parallel_task.

  PRIVATE SECTION.
    DATA position TYPE i.
    DATA task TYPE REF TO zif_parallel_task.

ENDCLASS.


"! Outcome of a task that raised, was terminated or was never started: it has
"! the reason and no executed copy. A class of its own instead of a flag, so
"! that asking a failed outcome for its task cannot return an unbound reference.
CLASS lcl_failed_outcome DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_parallel_outcome.

    METHODS constructor
      IMPORTING position TYPE i
                reason   TYPE string.

  PRIVATE SECTION.
    DATA position TYPE i.
    DATA reason TYPE string.

ENDCLASS.


"! Immutable result of a run. Holds the outcomes and hands out copies of the
"! table.
CLASS lcl_run DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_parallel_run.

    METHODS constructor
      IMPORTING outcomes TYPE zif_parallel_outcome=>outcomes.

  PRIVATE SECTION.
    DATA outcomes TYPE zif_parallel_outcome=>outcomes.

ENDCLASS.


"! Holds every rule of a run: it seals the tasks in envelopes, hands them to
"! the engine and turns what comes back into outcomes. Where the envelopes are
"! executed is the business of the engine.
CLASS lcl_runner DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_parallel_runner.

    METHODS constructor
      IMPORTING engine TYPE REF TO lif_engine
                limits TYPE run_limits.

  PRIVATE SECTION.
    CONSTANTS not_executed TYPE string VALUE `The task was not executed`.

    DATA engine TYPE REF TO lif_engine.
    DATA limits TYPE run_limits.

    METHODS envelopes_for
      IMPORTING tasks         TYPE zif_parallel_task=>tasks
      RETURNING VALUE(result) TYPE envelopes
      RAISING   zcx_parallel.

    METHODS outcome_of
      IMPORTING execution     TYPE execution
                position      TYPE i
      RETURNING VALUE(result) TYPE REF TO zif_parallel_outcome.

    METHODS failure_of
      IMPORTING execution     TYPE execution
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


"! Collects the limits of a runner. A value that is not allowed is remembered
"! and reported by build, which keeps the chain itself free of exceptions.
CLASS lcl_builder DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_parallel_builder.

    METHODS constructor
      IMPORTING engine TYPE REF TO lif_engine.

  PRIVATE SECTION.
    CONSTANTS smallest_limit TYPE i VALUE 1.

    DATA engine TYPE REF TO lif_engine.
    DATA limits TYPE run_limits.
    DATA first_mistake TYPE string.

    METHODS remember
      IMPORTING mistake TYPE string.

ENDCLASS.


CLASS lcl_envelope IMPLEMENTATION.

  METHOD constructor.
    payload = task.
  ENDMETHOD.

  METHOD if_abap_parallel~do.
    TRY.
        payload->execute( ).
      CATCH cx_root INTO DATA(error).
        " every exception, not only the declared ones: one that leaves this method
        " ends the session with a runtime error and takes its text with it
        failure = reason_of( error ).
    ENDTRY.
  ENDMETHOD.

  METHOD task.
    result = payload.
  ENDMETHOD.

  METHOD failure_reason.
    result = failure.
  ENDMETHOD.

  METHOD reason_of.
    DATA descriptions TYPE string_table.
    DATA(cause) = error.

    WHILE cause IS BOUND.
      DATA(class_name) = cl_abap_typedescr=>describe_by_object_ref( cause )->get_relative_name( ).
      INSERT |{ class_name }: { cause->get_text( ) }| INTO TABLE descriptions.
      cause = cause->previous.
    ENDWHILE.

    result = concat_lines_of( table = descriptions
                              sep   = cause_separator ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_parallel_engine IMPLEMENTATION.

  METHOD lif_engine~execute.
    DATA(framework) = framework_for( limits ).

    framework->run_inst( EXPORTING p_in_tab  = VALUE #( FOR envelope IN envelopes ( envelope ) )
                         IMPORTING p_out_tab = DATA(finished_tasks) ).

    result = VALUE #( FOR finished IN finished_tasks
                      ( envelope     = CAST #( finished-inst )
                        abort_reason = finished-message ) ).
  ENDMETHOD.

  METHOD framework_for.
    " a limit that was not set is not handed over at all, so that the framework
    " applies its own default instead of a value invented here
    result = COND #( WHEN limits IS INITIAL
                     THEN NEW cl_abap_parallel( )
                     WHEN limits-timeout_seconds IS INITIAL
                     THEN NEW cl_abap_parallel( p_num_processes = limits-max_processes )
                     WHEN limits-max_processes IS INITIAL
                     THEN NEW cl_abap_parallel( p_timeout = limits-timeout_seconds )
                     ELSE NEW cl_abap_parallel( p_num_processes = limits-max_processes
                                                p_timeout       = limits-timeout_seconds ) ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_sequential_engine IMPLEMENTATION.

  METHOD lif_engine~execute.
    " all copies first: a task that cannot be serialized stops the run before
    " any work is done, not half way through
    DATA(copies) = VALUE envelopes( FOR envelope IN envelopes INDEX INTO position
                                    ( copy_of( envelope = envelope
                                               position = position ) ) ).

    LOOP AT copies INTO DATA(copy).
      copy->if_abap_parallel~do( ).
      INSERT VALUE #( envelope = copy ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD copy_of.
    DATA serialized TYPE xstring.

    TRY.
        CALL TRANSFORMATION id SOURCE envelope = envelope RESULT XML serialized.
        CALL TRANSFORMATION id SOURCE XML serialized RESULT envelope = result.
      CATCH cx_transformation_error INTO DATA(error).
        RAISE EXCEPTION NEW zcx_parallel( text     = |Task { position } cannot be serialized: { error->get_text( ) }|
                                          previous = error ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_completed_outcome IMPLEMENTATION.

  METHOD constructor.
    me->position = position.
    me->task = task.
  ENDMETHOD.

  METHOD zif_parallel_outcome~position.
    result = position.
  ENDMETHOD.

  METHOD zif_parallel_outcome~has_failed.
    result = abap_false.
  ENDMETHOD.

  METHOD zif_parallel_outcome~failure_reason.
    CLEAR result.
  ENDMETHOD.

  METHOD zif_parallel_outcome~executed_task.
    result = task.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_failed_outcome IMPLEMENTATION.

  METHOD constructor.
    me->position = position.
    me->reason = reason.
  ENDMETHOD.

  METHOD zif_parallel_outcome~position.
    result = position.
  ENDMETHOD.

  METHOD zif_parallel_outcome~has_failed.
    result = abap_true.
  ENDMETHOD.

  METHOD zif_parallel_outcome~failure_reason.
    result = reason.
  ENDMETHOD.

  METHOD zif_parallel_outcome~executed_task.
    RAISE EXCEPTION NEW zcx_parallel( |Task { position } failed, so there is no executed copy: { reason }| ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_run IMPLEMENTATION.

  METHOD constructor.
    me->outcomes = outcomes.
  ENDMETHOD.

  METHOD zif_parallel_run~outcomes.
    result = outcomes.
  ENDMETHOD.

  METHOD zif_parallel_run~has_failures.
    LOOP AT outcomes INTO DATA(outcome).
      IF outcome->has_failed( ).
        result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_runner IMPLEMENTATION.

  METHOD constructor.
    me->engine = engine.
    me->limits = limits.
  ENDMETHOD.

  METHOD zif_parallel_runner~run.
    IF tasks IS INITIAL.
      result = NEW lcl_run( VALUE #( ) ).
      RETURN.
    ENDIF.

    DATA(executions) = engine->execute( envelopes = envelopes_for( tasks )
                                        limits    = limits ).

    IF lines( executions ) <> lines( tasks ).
      RAISE EXCEPTION NEW zcx_parallel(
        |The run reported { lines( executions ) } results for { lines( tasks ) } tasks| ).
    ENDIF.

    result = NEW lcl_run( VALUE #( FOR execution IN executions INDEX INTO position
                                   ( outcome_of( execution = execution
                                                 position  = position ) ) ) ).
  ENDMETHOD.

  METHOD envelopes_for.
    LOOP AT tasks INTO DATA(task).
      DATA(position) = sy-tabix.

      IF task IS NOT BOUND.
        RAISE EXCEPTION NEW zcx_parallel( |Task { position } is not bound| ).
      ENDIF.

      INSERT NEW lcl_envelope( task ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD outcome_of.
    DATA(reason) = failure_of( execution ).

    result = COND #( WHEN reason IS INITIAL
                     THEN NEW lcl_completed_outcome( position = position
                                                     task     = execution-envelope->task( ) )
                     ELSE NEW lcl_failed_outcome( position = position
                                                  reason   = reason ) ).
  ENDMETHOD.

  METHOD failure_of.
    result = COND #( WHEN execution-abort_reason IS NOT INITIAL THEN execution-abort_reason
                     WHEN execution-envelope IS NOT BOUND THEN not_executed
                     ELSE execution-envelope->failure_reason( ) ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_builder IMPLEMENTATION.

  METHOD constructor.
    me->engine = engine.
  ENDMETHOD.

  METHOD zif_parallel_builder~with_max_processes.
    IF processes < smallest_limit.
      remember( |The limit of work processes must be { smallest_limit } or more, but is { processes }| ).
    ELSE.
      limits-max_processes = processes.
    ENDIF.

    self = me.
  ENDMETHOD.

  METHOD zif_parallel_builder~with_timeout.
    IF seconds < smallest_limit.
      remember( |The time limit of a task must be { smallest_limit } or more seconds, but is { seconds }| ).
    ELSE.
      limits-timeout_seconds = seconds.
    ENDIF.

    self = me.
  ENDMETHOD.

  METHOD zif_parallel_builder~build.
    IF first_mistake IS NOT INITIAL.
      RAISE EXCEPTION NEW zcx_parallel( first_mistake ).
    ENDIF.

    result = NEW lcl_runner( engine = engine
                             limits = limits ).
  ENDMETHOD.

  METHOD remember.
    IF first_mistake IS INITIAL.
      first_mistake = mistake.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
