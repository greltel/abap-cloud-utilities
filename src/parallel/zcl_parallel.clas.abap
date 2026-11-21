"! <p class="shorttext synchronized" lang="EN">Parallel processing utility</p>
"! Entry point for executing tasks in parallel sessions on top of the released
"! CL_ABAP_PARALLEL. Standalone - depends on nothing but SAP released APIs.
CLASS zcl_parallel DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Runner without limits of its own: the parallel framework decides how many
    "! work processes it uses and how long a task may run.
    "!
    "! @parameter result | Runner backed by CL_ABAP_PARALLEL
    CLASS-METHODS runner
      RETURNING VALUE(result) TYPE REF TO zif_parallel_runner.

    "! Starts the configuration of a runner with limits of its own.
    "!
    "! @parameter result | Builder to be closed with build( )
    CLASS-METHODS configure
      RETURNING VALUE(result) TYPE REF TO zif_parallel_builder.

    "! Runner that executes the tasks one after the other in the session of the
    "! caller. It works on serialized copies and reports failures like a
    "! parallel run, which makes it the stand-in for unit tests of classes that
    "! take a {@link zif_parallel_runner}. It applies no limits and, unlike a
    "! parallel run, leaves the database transaction of the caller open.
    "!
    "! @parameter result | Runner that starts no session
    CLASS-METHODS sequential
      RETURNING VALUE(result) TYPE REF TO zif_parallel_runner.

ENDCLASS.


CLASS zcl_parallel IMPLEMENTATION.

  METHOD runner.
    result = NEW lcl_runner( engine = NEW lcl_parallel_engine( )
                             limits = VALUE #( ) ).
  ENDMETHOD.

  METHOD configure.
    result = NEW lcl_builder( NEW lcl_parallel_engine( ) ).
  ENDMETHOD.

  METHOD sequential.
    result = NEW lcl_runner( engine = NEW lcl_sequential_engine( )
                             limits = VALUE #( ) ).
  ENDMETHOD.

ENDCLASS.
