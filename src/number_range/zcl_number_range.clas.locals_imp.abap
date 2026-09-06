*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
TYPES:
  "! Everything the runtime needs to find an interval, in the types of the
  "! released API. The facade fills object and interval, the configuration
  "! methods of the interval add the rest.
  BEGIN OF settings,
    object        TYPE cl_numberrange_runtime=>nr_object,
    interval      TYPE cl_numberrange_runtime=>nr_interval,
    subobject     TYPE cl_numberrange_runtime=>nr_subobject,
    year          TYPE cl_numberrange_runtime=>nr_toyear,
    ignore_buffer TYPE cl_numberrange_runtime=>nr_ignore_buffer,
  END OF settings.

TYPES:
  "! What the runtime reports for one request: the last number assigned, how
  "! many numbers were assigned and the status code of the interval.
  BEGIN OF assignment,
    number            TYPE cl_numberrange_runtime=>nr_number,
    returned_quantity TYPE cl_numberrange_runtime=>nr_returned_quantity,
    returncode        TYPE cl_numberrange_runtime=>nr_returncode,
  END OF assignment.


"! Normalises and checks the identifiers of an interval before they reach the
"! runtime. The runtime types have a fixed length, so an identifier that is
"! too long would be cut silently and address the wrong interval.
CLASS lcl_identifier DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS object
      IMPORTING value         TYPE string
      RETURNING VALUE(result) TYPE cl_numberrange_runtime=>nr_object
      RAISING   zcx_number_range.

    CLASS-METHODS interval
      IMPORTING value         TYPE string
      RETURNING VALUE(result) TYPE cl_numberrange_runtime=>nr_interval
      RAISING   zcx_number_range.

    CLASS-METHODS subobject
      IMPORTING value         TYPE string
      RETURNING VALUE(result) TYPE cl_numberrange_runtime=>nr_subobject
      RAISING   zcx_number_range.

    CLASS-METHODS year
      IMPORTING value         TYPE i
      RETURNING VALUE(result) TYPE cl_numberrange_runtime=>nr_toyear
      RAISING   zcx_number_range.

  PRIVATE SECTION.
    CONSTANTS object_length TYPE i VALUE 10.
    CONSTANTS interval_length TYPE i VALUE 2.
    CONSTANTS subobject_length TYPE i VALUE 6.
    CONSTANTS earliest_year TYPE i VALUE 1.
    CONSTANTS latest_year TYPE i VALUE 9999.

    CLASS-METHODS normalise
      IMPORTING value         TYPE string
                what          TYPE string
                max_length    TYPE i
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_number_range.

ENDCLASS.


"! Seam to the number range runtime, one method per API call. Kept as thin as
"! possible so that everything above it can be tested with a double.
INTERFACE lif_runtime.

  METHODS number_get
    IMPORTING settings      TYPE settings
              quantity      TYPE cl_numberrange_runtime=>nr_quantity
    RETURNING VALUE(result) TYPE assignment
    RAISING   cx_number_ranges.

  METHODS number_status
    IMPORTING settings      TYPE settings
    RETURNING VALUE(result) TYPE cl_numberrange_runtime=>nr_number
    RAISING   cx_number_ranges.

ENDINTERFACE.


"! The only class that touches CL_NUMBERRANGE_RUNTIME.
CLASS lcl_runtime DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES lif_runtime.

ENDCLASS.


"! One interval. Translates requests into calls on the runtime seam and the
"! answers into the shape of the interface. Immutable: the configuration
"! methods hand the changed settings to a new instance.
CLASS lcl_number_range DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_number_range.

    METHODS constructor
      IMPORTING settings TYPE settings
                runtime  TYPE REF TO lif_runtime.

  PRIVATE SECTION.
    CONSTANTS critical_area TYPE cl_numberrange_runtime=>nr_returncode VALUE '1'.
    CONSTANTS last_number TYPE cl_numberrange_runtime=>nr_returncode VALUE '2'.

    DATA settings TYPE settings.
    DATA runtime TYPE REF TO lif_runtime.

    METHODS request
      IMPORTING quantity      TYPE i
      RETURNING VALUE(result) TYPE assignment
      RAISING   zcx_number_range.

    METHODS copy_with
      IMPORTING settings      TYPE settings
      RETURNING VALUE(result) TYPE REF TO zif_number_range.

    METHODS label
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS lcl_identifier IMPLEMENTATION.

  METHOD object.
    result = normalise( value      = value
                        what       = `Number range object`
                        max_length = object_length ).
  ENDMETHOD.

  METHOD interval.
    result = normalise( value      = value
                        what       = `Interval number`
                        max_length = interval_length ).
  ENDMETHOD.

  METHOD subobject.
    result = normalise( value      = value
                        what       = `Subobject`
                        max_length = subobject_length ).
  ENDMETHOD.

  METHOD year.
    IF value < earliest_year OR value > latest_year.
      RAISE EXCEPTION NEW zcx_number_range( |Year { value } is outside { earliest_year } to { latest_year }| ).
    ENDIF.

    result = value.
  ENDMETHOD.

  METHOD normalise.
    result = to_upper( condense( value ) ).

    IF result IS INITIAL.
      RAISE EXCEPTION NEW zcx_number_range( |{ what } is empty| ).
    ENDIF.

    IF strlen( result ) > max_length.
      RAISE EXCEPTION NEW zcx_number_range( |{ what } { result } exceeds { max_length } characters| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_runtime IMPLEMENTATION.

  METHOD lif_runtime~number_get.
    cl_numberrange_runtime=>number_get( EXPORTING nr_range_nr       = settings-interval
                                                  object            = settings-object
                                                  quantity          = quantity
                                                  subobject         = settings-subobject
                                                  toyear            = settings-year
                                                  ignore_buffer     = settings-ignore_buffer
                                        IMPORTING number            = result-number
                                                  returncode        = result-returncode
                                                  returned_quantity = result-returned_quantity ).
  ENDMETHOD.

  METHOD lif_runtime~number_status.
    cl_numberrange_runtime=>number_status( EXPORTING nr_range_nr = settings-interval
                                                     object      = settings-object
                                                     subobject   = settings-subobject
                                                     toyear      = settings-year
                                           IMPORTING number      = result ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_number_range IMPLEMENTATION.

  METHOD constructor.
    me->settings = settings.
    me->runtime = runtime.
  ENDMETHOD.

  METHOD zif_number_range~next.
    DATA(assignment) = request( 1 ).

    result = assignment-number.
  ENDMETHOD.

  METHOD zif_number_range~next_block.
    DATA(assignment) = request( quantity ).

    result = VALUE #( first        = assignment-number - assignment-returned_quantity + 1
                      last         = assignment-number
                      quantity     = assignment-returned_quantity
                      is_critical  = xsdbool( assignment-returncode = critical_area )
                      is_exhausted = xsdbool( assignment-returncode = last_number ) ).
  ENDMETHOD.

  METHOD zif_number_range~next_numbers.
    DATA(block) = zif_number_range~next_block( quantity ).

    IF block-quantity < quantity.
      RAISE EXCEPTION NEW zcx_number_range(
        |{ label( ) } could only assign { block-quantity } of the { quantity } numbers requested| ).
    ENDIF.

    result = VALUE #( FOR offset = 0 WHILE offset < block-quantity
                      ( block-first + offset ) ).
  ENDMETHOD.

  METHOD zif_number_range~last_assigned.
    TRY.
        result = runtime->number_status( settings ).
      CATCH cx_number_ranges INTO DATA(error).
        RAISE EXCEPTION NEW zcx_number_range( text     = |{ label( ) }: { error->get_text( ) }|
                                              previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_number_range~in_subobject.
    result = copy_with( VALUE #( BASE settings subobject = lcl_identifier=>subobject( subobject ) ) ).
  ENDMETHOD.

  METHOD zif_number_range~for_year.
    result = copy_with( VALUE #( BASE settings year = lcl_identifier=>year( year ) ) ).
  ENDMETHOD.

  METHOD zif_number_range~bypassing_buffer.
    result = copy_with( VALUE #( BASE settings ignore_buffer = abap_true ) ).
  ENDMETHOD.

  METHOD request.
    IF quantity < 1.
      RAISE EXCEPTION NEW zcx_number_range( |{ label( ) }: quantity { quantity } is below 1| ).
    ENDIF.

    TRY.
        result = runtime->number_get( settings = settings
                                      quantity = CONV #( quantity ) ).
      CATCH cx_number_ranges INTO DATA(error).
        RAISE EXCEPTION NEW zcx_number_range( text     = |{ label( ) }: { error->get_text( ) }|
                                              previous = error ).
    ENDTRY.

    IF result-returned_quantity = 0.
      RAISE EXCEPTION NEW zcx_number_range( |{ label( ) } assigned no numbers| ).
    ENDIF.
  ENDMETHOD.

  METHOD copy_with.
    result = NEW lcl_number_range( settings = settings
                                   runtime  = runtime ).
  ENDMETHOD.

  METHOD label.
    result = |Interval { settings-interval } of number range object { settings-object }|.

    IF settings-subobject IS NOT INITIAL.
      result = |{ result }, subobject { settings-subobject }|.
    ENDIF.

    IF settings-year IS NOT INITIAL.
      result = |{ result }, year { settings-year }|.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
