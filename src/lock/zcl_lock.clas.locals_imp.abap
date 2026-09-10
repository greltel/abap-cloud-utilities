"! ZCL_LOCK - Local Types
*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
TYPES:
  "! One lock parameter: its name, the value in its own type for the lock
  "! server and the same value as text for messages.
  BEGIN OF parameter,
    name  TYPE if_abap_lock_object=>tv_parameter_name,
    value TYPE REF TO data,
    text  TYPE string,
  END OF parameter.
TYPES parameters TYPE HASHED TABLE OF parameter WITH UNIQUE KEY name.

TYPES:
  "! Everything the lock server needs for one lock, in the types of the
  "! released API. The facade fills object, scope and wait; the configuration
  "! methods of the request add the rest.
  BEGIN OF request,
    object      TYPE if_abap_lock_object=>tv_name,
    parameters  TYPE parameters,
    table_modes TYPE if_abap_lock_object=>tt_table_mode,
    scope       TYPE if_abap_lock_object=>tv_scope,
    wait        TYPE if_abap_lock_object=>tv_wait,
  END OF request.


"! Normalises and checks what goes into a request before it reaches the lock
"! server. The API types have a fixed length, so a name that is too long would
"! be cut silently and address the wrong object.
CLASS lcl_identifier DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS object
      IMPORTING value         TYPE csequence
      RETURNING VALUE(result) TYPE if_abap_lock_object=>tv_name
      RAISING   zcx_lock.

    CLASS-METHODS parameter
      IMPORTING value         TYPE csequence
      RETURNING VALUE(result) TYPE if_abap_lock_object=>tv_parameter_name
      RAISING   zcx_lock.

    CLASS-METHODS table
      IMPORTING value         TYPE csequence
      RETURNING VALUE(result) TYPE if_abap_lock_object=>tv_table_name
      RAISING   zcx_lock.

    CLASS-METHODS mode
      IMPORTING value         TYPE if_abap_lock_object=>tv_mode
      RETURNING VALUE(result) TYPE if_abap_lock_object=>tv_mode
      RAISING   zcx_lock.

    CLASS-METHODS scope
      IMPORTING value         TYPE if_abap_lock_object=>tv_scope
      RETURNING VALUE(result) TYPE if_abap_lock_object=>tv_scope
      RAISING   zcx_lock.

  PRIVATE SECTION.
    CONSTANTS name_length TYPE i VALUE 30.

    CLASS-METHODS normalise
      IMPORTING value         TYPE csequence
                what          TYPE string
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_lock.

ENDCLASS.


"! Renders a request for messages and logs.
CLASS lcl_description DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS of
      IMPORTING request       TYPE request
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


"! Seam to the lock server, one method per API call. Kept as thin as possible
"! so that everything above it can be tested with a double.
INTERFACE lif_engine.

  METHODS enqueue
    IMPORTING request TYPE request
    RAISING   cx_abap_foreign_lock
              cx_abap_lock_failure.

  METHODS dequeue
    IMPORTING request TYPE request
    RAISING   cx_abap_lock_failure.

  METHODS dequeue_all.

ENDINTERFACE.


"! The only class that touches CL_ABAP_LOCK_OBJECT_FACTORY.
CLASS lcl_engine DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES lif_engine.

  PRIVATE SECTION.
    CLASS-METHODS api_parameters
      IMPORTING parameters    TYPE parameters
      RETURNING VALUE(result) TYPE if_abap_lock_object=>tt_parameter.

ENDCLASS.


"! One lock that has been set. Knows how it was set so that it can be released
"! the same way, and remembers whether it still holds the lock.
CLASS lcl_lock DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_lock.

    METHODS constructor
      IMPORTING request TYPE request
                engine  TYPE REF TO lif_engine.

  PRIVATE SECTION.
    DATA request TYPE request.
    DATA engine TYPE REF TO lif_engine.
    DATA held TYPE abap_bool.

ENDCLASS.


"! One request. Immutable: the configuration methods hand the changed request
"! to a new instance. Translates acquire( ) into a call on the engine seam and
"! the answer into a lock or a domain exception.
CLASS lcl_request DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_lock_request.

    METHODS constructor
      IMPORTING request TYPE request
                engine  TYPE REF TO lif_engine.

  PRIVATE SECTION.
    DATA request TYPE request.
    DATA engine TYPE REF TO lif_engine.

    METHODS copy_with
      IMPORTING request       TYPE request
      RETURNING VALUE(result) TYPE REF TO zif_lock_request.

    METHODS foreign_lock
      IMPORTING error         TYPE REF TO cx_abap_foreign_lock
      RETURNING VALUE(result) TYPE REF TO zcx_lock.

ENDCLASS.


CLASS lcl_identifier IMPLEMENTATION.

  METHOD object.
    result = normalise( value = value
                        what  = `Lock object` ).
  ENDMETHOD.

  METHOD parameter.
    result = normalise( value = value
                        what  = `Lock parameter` ).
  ENDMETHOD.

  METHOD table.
    result = normalise( value = value
                        what  = `Table` ).
  ENDMETHOD.

  METHOD mode.
    CASE value.
      WHEN zcl_lock=>mode-write
          OR zcl_lock=>mode-shared
          OR zcl_lock=>mode-exclusive
          OR zcl_lock=>mode-optimistic
          OR zcl_lock=>mode-promote_optimistic.
        result = value.
      WHEN OTHERS.
        RAISE EXCEPTION NEW zcx_lock( |Lock mode { value } is not one of the modes of ZCL_LOCK| ).
    ENDCASE.
  ENDMETHOD.

  METHOD scope.
    CASE value.
      WHEN zcl_lock=>scope-dialog
          OR zcl_lock=>scope-update
          OR zcl_lock=>scope-dialog_and_update.
        result = value.
      WHEN OTHERS.
        RAISE EXCEPTION NEW zcx_lock( |Lock scope { value } is not one of the scopes of ZCL_LOCK| ).
    ENDCASE.
  ENDMETHOD.

  METHOD normalise.
    result = to_upper( condense( value ) ).

    IF result IS INITIAL.
      RAISE EXCEPTION NEW zcx_lock( |{ what } name is empty| ).
    ENDIF.

    IF strlen( result ) > name_length.
      RAISE EXCEPTION NEW zcx_lock( |{ what } name { result } exceeds { name_length } characters| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_description IMPLEMENTATION.

  METHOD of.
    result = |Lock { request-object }|.

    IF request-parameters IS INITIAL.
      RETURN.
    ENDIF.

    DATA(values) = VALUE string_table( FOR parameter IN request-parameters
                                       ( |{ parameter-name } = { parameter-text }| ) ).

    result = |{ result } with { concat_lines_of( table = values
                                                 sep   = `, ` ) }|.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_engine IMPLEMENTATION.

  METHOD lif_engine~enqueue.
    cl_abap_lock_object_factory=>get_instance( request-object
                                 )->enqueue( it_table_mode = request-table_modes
                                             it_parameter  = api_parameters( request-parameters )
                                             _scope        = request-scope
                                             _wait         = request-wait ).
  ENDMETHOD.

  METHOD lif_engine~dequeue.
    cl_abap_lock_object_factory=>get_instance( request-object
                                 )->dequeue( it_table_mode = request-table_modes
                                             it_parameter  = api_parameters( request-parameters )
                                             _scope        = request-scope ).
  ENDMETHOD.

  METHOD lif_engine~dequeue_all.
    cl_abap_lock_object_factory=>dequeue_all( ).
  ENDMETHOD.

  METHOD api_parameters.
    result = VALUE #( FOR parameter IN parameters
                      ( name  = parameter-name
                        value = parameter-value ) ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_lock IMPLEMENTATION.

  METHOD constructor.
    me->request = request.
    me->engine = engine.
    held = abap_true.
  ENDMETHOD.

  METHOD zif_lock~release.
    IF held = abap_false.
      RETURN.
    ENDIF.

    DATA(description) = zif_lock~describe( ).

    TRY.
        engine->dequeue( request ).
      CATCH cx_abap_lock_failure INTO DATA(error).
        RAISE EXCEPTION NEW zcx_lock( text     = |{ description } could not be released: { error->get_text( ) }|
                                      previous = error ).
    ENDTRY.

    held = abap_false.
  ENDMETHOD.

  METHOD zif_lock~is_held.
    result = held.
  ENDMETHOD.

  METHOD zif_lock~object.
    result = request-object.
  ENDMETHOD.

  METHOD zif_lock~describe.
    result = lcl_description=>of( request ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_request IMPLEMENTATION.

  METHOD constructor.
    me->request = request.
    me->engine = engine.
  ENDMETHOD.

  METHOD zif_lock_request~with.
    DATA(parameter) = VALUE parameter( name = lcl_identifier=>parameter( name )
                                       text = |{ value }| ).

    IF line_exists( request-parameters[ name = parameter-name ] ).
      RAISE EXCEPTION NEW zcx_lock( |Lock parameter { parameter-name } is already set| ).
    ENDIF.

    " A copy in the type of the caller's variable, so that the lock server
    " receives the value in the type of the field and not as text
    CREATE DATA parameter-value LIKE value.
    parameter-value->* = value.

    DATA(changed) = request.
    INSERT parameter INTO TABLE changed-parameters.

    result = copy_with( changed ).
  ENDMETHOD.

  METHOD zif_lock_request~with_mode.
    DATA(table_mode) = VALUE if_abap_lock_object=>ts_table_mode(
                         table_name = lcl_identifier=>table( table )
                         mode       = lcl_identifier=>mode( mode ) ).

    IF line_exists( request-table_modes[ table_name = table_mode-table_name ] ).
      RAISE EXCEPTION NEW zcx_lock( |Lock mode for table { table_mode-table_name } is already set| ).
    ENDIF.

    DATA(changed) = request.
    INSERT table_mode INTO TABLE changed-table_modes.

    result = copy_with( changed ).
  ENDMETHOD.

  METHOD zif_lock_request~in_scope.
    result = copy_with( VALUE #( BASE request scope = lcl_identifier=>scope( scope ) ) ).
  ENDMETHOD.

  METHOD zif_lock_request~waiting.
    result = copy_with( VALUE #( BASE request wait = if_abap_lock_object=>cs_wait-yes ) ).
  ENDMETHOD.

  METHOD zif_lock_request~acquire.
    DATA(description) = lcl_description=>of( request ).

    TRY.
        engine->enqueue( request ).
      CATCH cx_abap_foreign_lock INTO DATA(foreign).
        DATA(rejection) = foreign_lock( foreign ).
        RAISE EXCEPTION rejection.
      CATCH cx_abap_lock_failure INTO DATA(failure).
        RAISE EXCEPTION NEW zcx_lock( text     = |{ description } could not be set: { failure->get_text( ) }|
                                      previous = failure ).
    ENDTRY.

    result = NEW lcl_lock( request = request
                           engine  = engine ).
  ENDMETHOD.

  METHOD copy_with.
    result = NEW lcl_request( request = request
                              engine  = engine ).
  ENDMETHOD.

  METHOD foreign_lock.
    DATA(holder) = condense( CONV string( error->user_name ) ).
    DATA(description) = lcl_description=>of( request ).

    result = NEW zcx_lock( text      = COND #( WHEN holder IS INITIAL
                                               THEN |{ description }: { error->get_text( ) }|
                                               ELSE |{ description } is held by user { holder }| )
                           previous  = error
                           locked_by = holder ).
  ENDMETHOD.

ENDCLASS.
