*"* use this source file for your ABAP unit test classes
"! Checked exception of the test tasks. It keeps the constructor it inherits,
"! so a task can hand over a cause with previous.
CLASS lcx_work_failed DEFINITION FINAL INHERITING FROM cx_static_check.

  PUBLIC SECTION.
    METHODS get_text REDEFINITION.

ENDCLASS.


CLASS lcx_work_failed IMPLEMENTATION.

  METHOD get_text.
    result = `The work failed on purpose`.
  ENDMETHOD.

ENDCLASS.


"! Task that squares a number. The result exists only on the executed copy.
CLASS ltd_square_task DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES zif_parallel_task.

    METHODS constructor
      IMPORTING number TYPE i.

    METHODS square
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    DATA number TYPE i.
    DATA squared TYPE i.

ENDCLASS.


CLASS ltd_square_task IMPLEMENTATION.

  METHOD constructor.
    me->number = number.
  ENDMETHOD.

  METHOD zif_parallel_task~execute.
    squared = number * number.
  ENDMETHOD.

  METHOD square.
    result = squared.
  ENDMETHOD.

ENDCLASS.


"! Task whose work fails with a checked exception.
CLASS ltd_failing_task DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES zif_parallel_task.

ENDCLASS.


CLASS ltd_failing_task IMPLEMENTATION.

  METHOD zif_parallel_task~execute.
    RAISE EXCEPTION NEW lcx_work_failed( ).
  ENDMETHOD.

ENDCLASS.


"! Task whose work fails with a checked exception that wraps its cause.
CLASS ltd_wrapping_task DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES zif_parallel_task.

ENDCLASS.


CLASS ltd_wrapping_task IMPLEMENTATION.

  METHOD zif_parallel_task~execute.
    RAISE EXCEPTION NEW lcx_work_failed( previous = NEW cx_sy_zerodivide( ) ).
  ENDMETHOD.

ENDCLASS.


"! Task with a programming error: an exception it does not declare leaves it.
CLASS ltd_careless_task DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES zif_parallel_task.

  PRIVATE SECTION.
    DATA divisor TYPE i.
    DATA quotient TYPE i.

ENDCLASS.


CLASS ltd_careless_task IMPLEMENTATION.

  METHOD zif_parallel_task~execute.
    quotient = 1 / divisor.
  ENDMETHOD.

ENDCLASS.


"! Task that cannot cross a session boundary: it refers to data whose type has
"! no name, and serialization rejects such a reference.
CLASS ltd_unserializable_task DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES zif_parallel_task.

    METHODS constructor.

  PRIVATE SECTION.
    DATA scratch TYPE REF TO data.

ENDCLASS.


CLASS ltd_unserializable_task IMPLEMENTATION.

  METHOD constructor.
    " a type that exists only as a property of this variable has no name
    DATA unnamed TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    CREATE DATA scratch LIKE unnamed.
  ENDMETHOD.

  METHOD zif_parallel_task~execute.
    " never reached: the task does not get past serialization
  ENDMETHOD.

ENDCLASS.


"! Fake engine. It executes the envelopes on the spot, without a copy and
"! without a session, remembers the limits it was called with, and can be told
"! to report a task as aborted or to lose a result - what the parallel
"! framework does when a session is terminated.
CLASS ltd_engine DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES lif_engine.

    METHODS abort_task
      IMPORTING position TYPE i
                reason   TYPE string.

    METHODS lose_last_result.

    METHODS received_limits
      RETURNING VALUE(result) TYPE run_limits.

    METHODS was_called
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF abortion,
        position TYPE i,
        reason   TYPE string,
      END OF abortion.
    TYPES abortions TYPE SORTED TABLE OF abortion WITH UNIQUE KEY position.

    DATA abortions_to_report TYPE abortions.
    DATA loses_last_result TYPE abap_bool.
    DATA limits TYPE run_limits.
    DATA is_called TYPE abap_bool.

ENDCLASS.


CLASS ltd_engine IMPLEMENTATION.

  METHOD abort_task.
    INSERT VALUE #( position = position
                    reason   = reason ) INTO TABLE abortions_to_report.
  ENDMETHOD.

  METHOD lose_last_result.
    loses_last_result = abap_true.
  ENDMETHOD.

  METHOD received_limits.
    result = limits.
  ENDMETHOD.

  METHOD was_called.
    result = is_called.
  ENDMETHOD.

  METHOD lif_engine~execute.
    me->limits = limits.
    is_called = abap_true.

    LOOP AT envelopes INTO DATA(envelope).
      DATA(position) = sy-tabix.

      IF line_exists( abortions_to_report[ position = position ] ).
        INSERT VALUE #( abort_reason = abortions_to_report[ position = position ]-reason ) INTO TABLE result.
      ELSE.
        envelope->if_abap_parallel~do( ).
        INSERT VALUE #( envelope = envelope ) INTO TABLE result.
      ENDIF.
    ENDLOOP.

    IF loses_last_result = abap_true.
      DELETE result INDEX lines( result ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_sequential_run DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zif_parallel_runner.

    METHODS setup.

    METHODS given_tasks_then_each_executed FOR TESTING RAISING zcx_parallel.
    METHODS then_outcomes_keep_task_order FOR TESTING RAISING zcx_parallel.
    METHODS given_run_then_original_intact FOR TESTING RAISING zcx_parallel.
    METHODS given_no_task_then_empty_run FOR TESTING RAISING zcx_parallel.
    METHODS given_unbound_task_then_raises FOR TESTING.
    METHODS given_unserializable_raises FOR TESTING.

ENDCLASS.


CLASS ltc_sequential_run IMPLEMENTATION.

  METHOD setup.
    cut = zcl_parallel=>sequential( ).
  ENDMETHOD.

  METHOD given_tasks_then_each_executed.
    DATA(tasks) = VALUE zif_parallel_task=>tasks( ( NEW ltd_square_task( 3 ) )
                                                  ( NEW ltd_square_task( 4 ) ) ).

    DATA(outcomes) = cut->run( tasks )->outcomes( ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( outcomes )
      exp = 2
      msg = `The run does not report one outcome per task` ).
    cl_abap_unit_assert=>assert_equals(
      act = CAST ltd_square_task( outcomes[ 1 ]->executed_task( ) )->square( )
      exp = 9
      msg = `The first task was not executed` ).
    cl_abap_unit_assert=>assert_equals(
      act = CAST ltd_square_task( outcomes[ 2 ]->executed_task( ) )->square( )
      exp = 16
      msg = `The second task was not executed` ).
  ENDMETHOD.

  METHOD then_outcomes_keep_task_order.
    DATA(tasks) = VALUE zif_parallel_task=>tasks( ( NEW ltd_square_task( 3 ) )
                                                  ( NEW ltd_failing_task( ) )
                                                  ( NEW ltd_square_task( 4 ) ) ).

    DATA(outcomes) = cut->run( tasks )->outcomes( ).

    cl_abap_unit_assert=>assert_equals(
      act = outcomes[ 1 ]->position( )
      exp = 1
      msg = `The first outcome does not belong to the first task` ).
    cl_abap_unit_assert=>assert_equals(
      act = outcomes[ 2 ]->position( )
      exp = 2
      msg = `A failed task does not keep its position` ).
    cl_abap_unit_assert=>assert_equals(
      act = outcomes[ 3 ]->position( )
      exp = 3
      msg = `The last outcome does not belong to the last task` ).
  ENDMETHOD.

  METHOD given_run_then_original_intact.
    DATA(original) = NEW ltd_square_task( 3 ).

    DATA(outcomes) = cut->run( VALUE #( ( original ) ) )->outcomes( ).

    cl_abap_unit_assert=>assert_initial(
      act = original->square( )
      msg = `The instance handed to the runner was executed instead of a copy` ).
    cl_abap_unit_assert=>assert_equals(
      act = CAST ltd_square_task( outcomes[ 1 ]->executed_task( ) )->square( )
      exp = 9
      msg = `The executed copy does not carry the result` ).
  ENDMETHOD.

  METHOD given_no_task_then_empty_run.
    DATA(run) = cut->run( VALUE #( ) ).

    cl_abap_unit_assert=>assert_initial(
      act = run->outcomes( )
      msg = `A run without tasks reports outcomes` ).
    cl_abap_unit_assert=>assert_false(
      act = run->has_failures( )
      msg = `A run without tasks reports a failure` ).
  ENDMETHOD.

  METHOD given_unbound_task_then_raises.
    DATA unbound TYPE REF TO zif_parallel_task.
    DATA(tasks) = VALUE zif_parallel_task=>tasks( ( NEW ltd_square_task( 3 ) )
                                                  ( unbound ) ).

    TRY.
        cut->run( tasks ).

        cl_abap_unit_assert=>fail( `A task reference that is not bound was accepted` ).
      CATCH zcx_parallel INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          act = error->get_text( )
          exp = `Task 2 is not bound`
          msg = `The exception does not name the position of the unbound task` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_unserializable_raises.
    DATA(tasks) = VALUE zif_parallel_task=>tasks( ( NEW ltd_square_task( 3 ) )
                                                  ( NEW ltd_unserializable_task( ) ) ).

    TRY.
        cut->run( tasks ).

        cl_abap_unit_assert=>fail( `A task that cannot be serialized was accepted` ).
      CATCH zcx_parallel INTO DATA(error).
        cl_abap_unit_assert=>assert_char_cp(
          act = error->get_text( )
          exp = `Task 2 cannot be serialized:*`
          msg = `The exception does not name the task that cannot be serialized` ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_failures DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zif_parallel_runner.

    METHODS setup.

    METHODS given_raising_task_then_failed FOR TESTING RAISING zcx_parallel.
    METHODS given_failure_then_others_run FOR TESTING RAISING zcx_parallel.
    METHODS given_cause_then_reason_has_it FOR TESTING RAISING zcx_parallel.
    METHODS given_undeclared_then_failed FOR TESTING RAISING zcx_parallel.
    METHODS given_failed_when_task_raises FOR TESTING RAISING zcx_parallel.
    METHODS given_failure_then_run_has_it FOR TESTING RAISING zcx_parallel.
    METHODS given_all_done_then_no_failure FOR TESTING RAISING zcx_parallel.
    METHODS given_done_then_no_reason FOR TESTING RAISING zcx_parallel.

ENDCLASS.


CLASS ltc_failures IMPLEMENTATION.

  METHOD setup.
    cut = zcl_parallel=>sequential( ).
  ENDMETHOD.

  METHOD given_raising_task_then_failed.
    DATA(outcomes) = cut->run( VALUE #( ( NEW ltd_failing_task( ) ) ) )->outcomes( ).

    cl_abap_unit_assert=>assert_true(
      act = outcomes[ 1 ]->has_failed( )
      msg = `A task that raised is not reported as failed` ).
    cl_abap_unit_assert=>assert_equals(
      act = outcomes[ 1 ]->failure_reason( )
      exp = `LCX_WORK_FAILED: The work failed on purpose`
      msg = `The reason does not carry the class and the text of the exception` ).
  ENDMETHOD.

  METHOD given_failure_then_others_run.
    DATA(tasks) = VALUE zif_parallel_task=>tasks( ( NEW ltd_failing_task( ) )
                                                  ( NEW ltd_square_task( 4 ) ) ).

    DATA(outcomes) = cut->run( tasks )->outcomes( ).

    cl_abap_unit_assert=>assert_false(
      act = outcomes[ 2 ]->has_failed( )
      msg = `The failure of one task is reported for another one` ).
    cl_abap_unit_assert=>assert_equals(
      act = CAST ltd_square_task( outcomes[ 2 ]->executed_task( ) )->square( )
      exp = 16
      msg = `A task after a failed one was not executed` ).
  ENDMETHOD.

  METHOD given_cause_then_reason_has_it.
    DATA(outcomes) = cut->run( VALUE #( ( NEW ltd_wrapping_task( ) ) ) )->outcomes( ).

    cl_abap_unit_assert=>assert_char_cp(
      act = outcomes[ 1 ]->failure_reason( )
      exp = `LCX_WORK_FAILED: The work failed on purpose; caused by CX_SY_ZERODIVIDE:*`
      msg = `The reason does not name the cause of the exception` ).
  ENDMETHOD.

  METHOD given_undeclared_then_failed.
    DATA(outcomes) = cut->run( VALUE #( ( NEW ltd_careless_task( ) ) ) )->outcomes( ).

    cl_abap_unit_assert=>assert_true(
      act = outcomes[ 1 ]->has_failed( )
      msg = `An exception the task does not declare is not reported as its failure` ).
    cl_abap_unit_assert=>assert_char_cp(
      act = outcomes[ 1 ]->failure_reason( )
      exp = `*CX_SY_ZERODIVIDE*`
      msg = `The reason does not name the exception the task did not declare` ).
  ENDMETHOD.

  METHOD given_failed_when_task_raises.
    DATA(outcomes) = cut->run( VALUE #( ( NEW ltd_failing_task( ) ) ) )->outcomes( ).

    TRY.
        outcomes[ 1 ]->executed_task( ).

        cl_abap_unit_assert=>fail( `A failed task handed out an executed copy` ).
      CATCH zcx_parallel INTO DATA(error).
        cl_abap_unit_assert=>assert_char_cp(
          act = error->get_text( )
          exp = `Task 1 failed, so there is no executed copy: LCX_WORK_FAILED:*`
          msg = `The exception does not name the task and the reason of its failure` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_failure_then_run_has_it.
    DATA(tasks) = VALUE zif_parallel_task=>tasks( ( NEW ltd_square_task( 3 ) )
                                                  ( NEW ltd_failing_task( ) ) ).

    DATA(run) = cut->run( tasks ).

    cl_abap_unit_assert=>assert_true(
      act = run->has_failures( )
      msg = `A run with a failed task reports no failure` ).
  ENDMETHOD.

  METHOD given_all_done_then_no_failure.
    DATA(tasks) = VALUE zif_parallel_task=>tasks( ( NEW ltd_square_task( 3 ) )
                                                  ( NEW ltd_square_task( 4 ) ) ).

    DATA(run) = cut->run( tasks ).

    cl_abap_unit_assert=>assert_false(
      act = run->has_failures( )
      msg = `A run in which every task completed reports a failure` ).
  ENDMETHOD.

  METHOD given_done_then_no_reason.
    DATA(outcomes) = cut->run( VALUE #( ( NEW ltd_square_task( 3 ) ) ) )->outcomes( ).

    cl_abap_unit_assert=>assert_false(
      act = outcomes[ 1 ]->has_failed( )
      msg = `A task that completed is reported as failed` ).
    cl_abap_unit_assert=>assert_initial(
      act = outcomes[ 1 ]->failure_reason( )
      msg = `A task that completed carries a failure reason` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_limits DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA engine TYPE REF TO ltd_engine.
    DATA cut TYPE REF TO zif_parallel_builder.

    METHODS setup.

    METHODS given_limits_then_engine_gets FOR TESTING RAISING zcx_parallel.
    METHODS given_no_limit_then_none_set FOR TESTING RAISING zcx_parallel.
    METHODS given_new_value_then_replaced FOR TESTING RAISING zcx_parallel.
    METHODS given_one_process_then_built FOR TESTING RAISING zcx_parallel.
    METHODS given_one_second_then_built FOR TESTING RAISING zcx_parallel.
    METHODS given_zero_processes_raises FOR TESTING.
    METHODS given_zero_timeout_then_raises FOR TESTING.
    METHODS given_two_mistakes_then_first FOR TESTING.

    METHODS one_task
      RETURNING VALUE(result) TYPE zif_parallel_task=>tasks.

ENDCLASS.


CLASS ltc_limits IMPLEMENTATION.

  METHOD setup.
    engine = NEW #( ).
    cut = NEW lcl_builder( engine ).
  ENDMETHOD.

  METHOD given_limits_then_engine_gets.
    DATA(runner) = cut->with_max_processes( 4 )->with_timeout( 60 )->build( ).

    runner->run( one_task( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = engine->received_limits( )
      exp = VALUE run_limits( max_processes   = 4
                              timeout_seconds = 60 )
      msg = `The configured limits do not reach the engine` ).
  ENDMETHOD.

  METHOD given_no_limit_then_none_set.
    DATA(runner) = cut->build( ).

    runner->run( one_task( ) ).

    cl_abap_unit_assert=>assert_initial(
      act = engine->received_limits( )
      msg = `A runner built without limits hands limits to the engine` ).
  ENDMETHOD.

  METHOD given_new_value_then_replaced.
    DATA(runner) = cut->with_timeout( 60 )->with_timeout( 30 )->build( ).

    runner->run( one_task( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = engine->received_limits( )-timeout_seconds
      exp = 30
      msg = `A later call does not replace the limit of an earlier one` ).
  ENDMETHOD.

  METHOD given_one_process_then_built.
    DATA(runner) = cut->with_max_processes( 1 )->build( ).

    cl_abap_unit_assert=>assert_bound(
      act = runner
      msg = `The smallest allowed number of work processes was rejected` ).
  ENDMETHOD.

  METHOD given_one_second_then_built.
    DATA(runner) = cut->with_timeout( 1 )->build( ).

    cl_abap_unit_assert=>assert_bound(
      act = runner
      msg = `The smallest allowed time limit was rejected` ).
  ENDMETHOD.

  METHOD given_zero_processes_raises.
    TRY.
        cut->with_max_processes( 0 )->build( ).

        cl_abap_unit_assert=>fail( `A limit of zero work processes was accepted` ).
      CATCH zcx_parallel INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          act = error->get_text( )
          exp = `The limit of work processes must be 1 or more, but is 0`
          msg = `The exception does not name the rejected limit and its value` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_zero_timeout_then_raises.
    TRY.
        cut->with_timeout( 0 )->build( ).

        cl_abap_unit_assert=>fail( `A time limit of zero seconds was accepted` ).
      CATCH zcx_parallel INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          act = error->get_text( )
          exp = `The time limit of a task must be 1 or more seconds, but is 0`
          msg = `The exception does not name the rejected limit and its value` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_two_mistakes_then_first.
    TRY.
        cut->with_timeout( -5 )->with_max_processes( 0 )->build( ).

        cl_abap_unit_assert=>fail( `Two limits that are not allowed were accepted` ).
      CATCH zcx_parallel INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          act = error->get_text( )
          exp = `The time limit of a task must be 1 or more seconds, but is -5`
          msg = `The first mistake of the chain is not the one reported` ).
    ENDTRY.
  ENDMETHOD.

  METHOD one_task.
    result = VALUE #( ( NEW ltd_square_task( 3 ) ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_engine_reports DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA engine TYPE REF TO ltd_engine.
    DATA cut TYPE REF TO zif_parallel_runner.

    METHODS setup.

    METHODS given_aborted_task_then_failed FOR TESTING RAISING zcx_parallel.
    METHODS given_silent_abort_then_reason FOR TESTING RAISING zcx_parallel.
    METHODS given_abort_then_others_done FOR TESTING RAISING zcx_parallel.
    METHODS given_lost_result_then_raises FOR TESTING.
    METHODS given_no_task_then_engine_idle FOR TESTING RAISING zcx_parallel.

    METHODS two_tasks
      RETURNING VALUE(result) TYPE zif_parallel_task=>tasks.

ENDCLASS.


CLASS ltc_engine_reports IMPLEMENTATION.

  METHOD setup.
    engine = NEW #( ).
    cut = NEW lcl_runner( engine = engine
                          limits = VALUE #( ) ).
  ENDMETHOD.

  METHOD given_aborted_task_then_failed.
    engine->abort_task( position = 2
                        reason   = `Time limit exceeded` ).

    DATA(outcomes) = cut->run( two_tasks( ) )->outcomes( ).

    cl_abap_unit_assert=>assert_true(
      act = outcomes[ 2 ]->has_failed( )
      msg = `A task the engine has no executed copy of is not reported as failed` ).
    cl_abap_unit_assert=>assert_equals(
      act = outcomes[ 2 ]->failure_reason( )
      exp = `Time limit exceeded`
      msg = `The reason is not what the engine reported for the task` ).
  ENDMETHOD.

  METHOD given_silent_abort_then_reason.
    engine->abort_task( position = 1
                        reason   = `` ).

    DATA(outcomes) = cut->run( two_tasks( ) )->outcomes( ).

    cl_abap_unit_assert=>assert_true(
      act = outcomes[ 1 ]->has_failed( )
      msg = `A task that came back without a copy and without a text is not reported as failed` ).
    cl_abap_unit_assert=>assert_equals(
      act = outcomes[ 1 ]->failure_reason( )
      exp = `The task was not executed`
      msg = `A task that came back without a text has no failure reason` ).
  ENDMETHOD.

  METHOD given_abort_then_others_done.
    engine->abort_task( position = 1
                        reason   = `Time limit exceeded` ).

    DATA(outcomes) = cut->run( two_tasks( ) )->outcomes( ).

    cl_abap_unit_assert=>assert_false(
      act = outcomes[ 2 ]->has_failed( )
      msg = `The abort of one task is reported for another one` ).
  ENDMETHOD.

  METHOD given_lost_result_then_raises.
    engine->lose_last_result( ).

    TRY.
        cut->run( two_tasks( ) ).

        cl_abap_unit_assert=>fail( `A run that did not report every task was accepted` ).
      CATCH zcx_parallel INTO DATA(error).
        cl_abap_unit_assert=>assert_equals(
          act = error->get_text( )
          exp = `The run reported 1 results for 2 tasks`
          msg = `The exception does not say how many results are missing` ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_no_task_then_engine_idle.
    cut->run( VALUE #( ) ).

    cl_abap_unit_assert=>assert_false(
      act = engine->was_called( )
      msg = `The engine was called although there was no task to execute` ).
  ENDMETHOD.

  METHOD two_tasks.
    result = VALUE #( ( NEW ltd_square_task( 3 ) )
                      ( NEW ltd_square_task( 4 ) ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_facade DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_runner_then_ready FOR TESTING.
    METHODS when_configured_then_ready FOR TESTING RAISING zcx_parallel.
    METHODS given_bad_limit_then_raises FOR TESTING.

ENDCLASS.


CLASS ltc_facade IMPLEMENTATION.

  METHOD when_runner_then_ready.
    cl_abap_unit_assert=>assert_bound(
      act = zcl_parallel=>runner( )
      msg = `The facade hands out no runner` ).
  ENDMETHOD.

  METHOD when_configured_then_ready.
    DATA(runner) = zcl_parallel=>configure( )->with_max_processes( 2 )->with_timeout( 30 )->build( ).

    cl_abap_unit_assert=>assert_bound(
      act = runner
      msg = `The builder of the facade builds no runner` ).
  ENDMETHOD.

  METHOD given_bad_limit_then_raises.
    TRY.
        zcl_parallel=>configure( )->with_max_processes( 0 )->build( ).

        cl_abap_unit_assert=>fail( `The builder of the facade accepted a limit of zero work processes` ).
      CATCH zcx_parallel INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial(
          act = error->get_text( )
          msg = `The exception carries no message` ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
