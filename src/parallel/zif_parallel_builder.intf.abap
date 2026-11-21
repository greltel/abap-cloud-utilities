"! <p class="shorttext synchronized" lang="EN">Parallel runner builder</p>
"! Configures a runner step by step. Every method returns the same instance,
"! so the calls can be chained, and a later call replaces the value of an
"! earlier one. The chain never raises: a value that is not allowed is
"! remembered and reported by {@link zif_parallel_builder.METH:build}.
INTERFACE zif_parallel_builder
  PUBLIC.

  "! Limits how many tasks run at the same time. Without a call the parallel
  "! framework decides.
  "!
  "! @parameter processes | Upper limit of work processes used at the same time, 1 or more
  "! @parameter self      | Same instance, for chaining
  METHODS with_max_processes
    IMPORTING processes   TYPE i
    RETURNING VALUE(self) TYPE REF TO zif_parallel_builder.

  "! Limits how long a single task may run. A task that takes longer is
  "! terminated and reported as failed. Without a call the parallel framework
  "! decides.
  "!
  "! @parameter seconds | Time limit of one task, 1 or more
  "! @parameter self    | Same instance, for chaining
  METHODS with_timeout
    IMPORTING seconds     TYPE i
    RETURNING VALUE(self) TYPE REF TO zif_parallel_builder.

  "! Finishes the configuration.
  "!
  "! @parameter result       | Runner that works within the configured limits
  "! @raising   zcx_parallel | A limit in the chain was smaller than 1
  METHODS build
    RETURNING VALUE(result) TYPE REF TO zif_parallel_runner
    RAISING   zcx_parallel.

ENDINTERFACE.
