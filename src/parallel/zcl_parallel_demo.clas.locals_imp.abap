*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
"! Raised by the demo task when there is nobody to split a bill among.
CLASS lcx_nobody_to_share DEFINITION FINAL INHERITING FROM cx_static_check.

  PUBLIC SECTION.
    METHODS get_text REDEFINITION.

ENDCLASS.


"! The task of the demo: splits an amount evenly. A task is an ordinary class
"! of the consumer - here a local one - that keeps its input and its result in
"! attributes, because the object is what travels to the other session.
CLASS lcl_split_task DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_parallel_task.

    METHODS constructor
      IMPORTING amount TYPE i
                people TYPE i.

    METHODS share
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    DATA amount TYPE i.
    DATA people TYPE i.
    DATA share_per_head TYPE i.

ENDCLASS.


CLASS lcx_nobody_to_share IMPLEMENTATION.

  METHOD get_text.
    result = `A bill cannot be split among nobody`.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_split_task IMPLEMENTATION.

  METHOD constructor.
    me->amount = amount.
    me->people = people.
  ENDMETHOD.

  METHOD zif_parallel_task~execute.
    IF people IS INITIAL.
      RAISE EXCEPTION NEW lcx_nobody_to_share( ).
    ENDIF.

    share_per_head = amount / people.
  ENDMETHOD.

  METHOD share.
    result = share_per_head.
  ENDMETHOD.

ENDCLASS.
