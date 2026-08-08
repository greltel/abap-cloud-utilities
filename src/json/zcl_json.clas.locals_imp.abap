*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
"! Rejects data objects the XCO JSON APIs cannot convert. Reference components
"! (TYPE REF TO data / TYPE REF TO object) end in the runtime error
"! XML_FORMAT_ERROR instead of a catchable exception, so they are caught here
"! up front.
CLASS lcl_type_guard DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS ensure_convertible
      IMPORTING data TYPE data
      RAISING   zcx_json.

  PRIVATE SECTION.
    CLASS-METHODS ensure_type_convertible
      IMPORTING type TYPE REF TO cl_abap_typedescr
                name TYPE string
      RAISING   zcx_json.

ENDCLASS.


CLASS lcl_type_guard IMPLEMENTATION.

  METHOD ensure_convertible.
    ensure_type_convertible( type = cl_abap_typedescr=>describe_by_data( data )
                             name = `The data object` ).
  ENDMETHOD.

  METHOD ensure_type_convertible.
    CASE type->kind.
      WHEN cl_abap_typedescr=>kind_ref.
        RAISE EXCEPTION NEW zcx_json( text = |{ name } is a reference type and cannot be converted| ).

      WHEN cl_abap_typedescr=>kind_struct.
        LOOP AT CAST cl_abap_structdescr( type )->get_components( ) INTO DATA(component).
          ensure_type_convertible( type = component-type
                                   name = |Component { component-name }| ).
        ENDLOOP.

      WHEN cl_abap_typedescr=>kind_table.
        ensure_type_convertible( type = CAST cl_abap_tabledescr( type )->get_table_line_type( )
                                 name = |The line type of { name }| ).
    ENDCASE.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_reader DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_json_reader.

    METHODS constructor
      IMPORTING json TYPE string
      RAISING   zcx_json.

  PRIVATE SECTION.
    DATA document               TYPE REF TO if_xco_cp_json_data.
    DATA name_transformation    TYPE REF TO if_xco_json_transformation.
    DATA boolean_transformation TYPE REF TO if_xco_json_transformation.

    METHODS transformations
      RETURNING VALUE(result) TYPE sxco_t_json_transformations.

ENDCLASS.


CLASS lcl_reader IMPLEMENTATION.

  METHOD constructor.
    TRY.
        document = xco_cp_json=>data->from_string( json ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_json( text     = `The string could not be opened as a JSON document`
                                      previous = xco_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_json_reader~from_camel_case.
    name_transformation = xco_cp_json=>transformation->camel_case_to_underscore.
    self = me.
  ENDMETHOD.

  METHOD zif_json_reader~from_pascal_case.
    name_transformation = xco_cp_json=>transformation->pascal_case_to_underscore.
    self = me.
  ENDMETHOD.

  METHOD zif_json_reader~booleans_to_abap_bool.
    boolean_transformation = xco_cp_json=>transformation->boolean_to_abap_bool.
    self = me.
  ENDMETHOD.

  METHOD zif_json_reader~read_into.
    CLEAR data.

    lcl_type_guard=>ensure_convertible( data ).

    TRY.
        DATA(json_data) = document.
        DATA(steps) = transformations( ).

        IF steps IS NOT INITIAL.
          json_data = json_data->apply( steps ).
        ENDIF.

        json_data->write_to( REF #( data ) ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_json( text     = `The JSON document could not be mapped to the data object`
                                      previous = xco_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD transformations.
    IF name_transformation IS BOUND.
      INSERT name_transformation INTO TABLE result.
    ENDIF.

    IF boolean_transformation IS BOUND.
      INSERT boolean_transformation INTO TABLE result.
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_writer DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_json_writer.

    METHODS constructor
      IMPORTING data TYPE data
      RAISING   zcx_json.

  PRIVATE SECTION.
    DATA document            TYPE REF TO if_xco_cp_json_data.
    DATA name_transformation TYPE REF TO if_xco_json_transformation.

ENDCLASS.


CLASS lcl_writer IMPLEMENTATION.

  METHOD constructor.
    lcl_type_guard=>ensure_convertible( data ).

    TRY.
        document = xco_cp_json=>data->from_abap( data ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_json( text     = `The data object could not be opened as a JSON document`
                                      previous = xco_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_json_writer~as_camel_case.
    name_transformation = xco_cp_json=>transformation->underscore_to_camel_case.
    self = me.
  ENDMETHOD.

  METHOD zif_json_writer~as_pascal_case.
    name_transformation = xco_cp_json=>transformation->underscore_to_pascal_case.
    self = me.
  ENDMETHOD.

  METHOD zif_json_writer~to_string.
    TRY.
        DATA(json_data) = document.

        IF name_transformation IS BOUND.
          json_data = json_data->apply( VALUE #( ( name_transformation ) ) ).
        ENDIF.

        result = json_data->to_string( ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_json( text     = `The JSON string could not be generated`
                                      previous = xco_error ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
