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
      RAISING   zcx_acu_json.

  PRIVATE SECTION.
    CLASS-METHODS ensure_type_convertible
      IMPORTING type TYPE REF TO cl_abap_typedescr
                name TYPE string
      RAISING   zcx_acu_json.

ENDCLASS.


CLASS lcl_type_guard IMPLEMENTATION.

  METHOD ensure_convertible.
    ensure_type_convertible( type = cl_abap_typedescr=>describe_by_data( data )
                             name = `The data object` ).
  ENDMETHOD.

  METHOD ensure_type_convertible.
    CASE type->kind.
      WHEN cl_abap_typedescr=>kind_ref.
        RAISE EXCEPTION NEW zcx_acu_json( text = |{ name } is a reference type and cannot be converted| ).

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
      RAISING   zcx_acu_json.

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
        RAISE EXCEPTION NEW zcx_acu_json( text     = `The string could not be opened as a JSON document`
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
        RAISE EXCEPTION NEW zcx_acu_json( text     = `The JSON document could not be mapped to the data object`
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

"! Paths of the abap_bool components of a data type, spelled the way the XCO
"! serializer names the members: upper case component names joined by
"! slashes, table lines adding no step. Consulted while a document is rebuilt
"! with JSON booleans.
CLASS lcl_boolean_paths DEFINITION FINAL.

  PUBLIC SECTION.
    TYPES paths TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line.

    CONSTANTS separator TYPE string VALUE `/`.

    CLASS-METHODS of
      IMPORTING type          TYPE REF TO cl_abap_typedescr
      RETURNING VALUE(result) TYPE paths.

  PRIVATE SECTION.
    " Relative names of the types the serializer renders as X and empty; the
    " relative name is the same whether the type comes from a type pool
    " (\TYPE-POOL=ABAP\TYPE=ABAP_BOOL) or from the dictionary (\TYPE=XSDBOOLEAN).
    CONSTANTS abap_bool_type TYPE string VALUE `ABAP_BOOL`.
    CONSTANTS abap_boolean_type TYPE string VALUE `ABAP_BOOLEAN`.
    CONSTANTS xsdboolean_type TYPE string VALUE `XSDBOOLEAN`.
    CONSTANTS boole_d_type TYPE string VALUE `BOOLE_D`.
    CONSTANTS xfeld_type TYPE string VALUE `XFELD`.

    CLASS-METHODS collect
      IMPORTING type   TYPE REF TO cl_abap_typedescr
                path   TYPE string
                suffix TYPE string
      CHANGING  paths  TYPE paths.

    CLASS-METHODS collect_components
      IMPORTING type   TYPE REF TO cl_abap_structdescr
                path   TYPE string
                suffix TYPE string
      CHANGING  paths  TYPE paths.

    CLASS-METHODS is_boolean
      IMPORTING type          TYPE REF TO cl_abap_typedescr
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS join
      IMPORTING path          TYPE string
                name          TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


"! Rebuilds a document through the XCO builder while the document is
"! traversed, turning the X / empty strings of abap_bool components into JSON
"! booleans. The traversal announces a member name before its value, so the
"! name announced last, below the open containers, is the path of the value
"! in hand.
CLASS lcl_boolean_rebuilder DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES if_xco_json_tree_visitor.

    METHODS constructor
      IMPORTING booleans TYPE lcl_boolean_paths=>paths.

    METHODS document
      RETURNING VALUE(result) TYPE REF TO if_xco_cp_json_data.

  PRIVATE SECTION.
    CONSTANTS true_flag TYPE string VALUE `X`.

    DATA booleans TYPE lcl_boolean_paths=>paths.
    DATA builder TYPE REF TO if_xco_cp_json_data_builder.
    DATA enclosing TYPE string_table.
    DATA member TYPE string.

    METHODS enter.

    METHODS leave.

    METHODS current_path
      RETURNING VALUE(result) TYPE string.

ENDCLASS.

CLASS lcl_writer DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_json_writer.

    METHODS constructor
      IMPORTING data TYPE data
      RAISING   zcx_acu_json.

  PRIVATE SECTION.
    DATA document            TYPE REF TO if_xco_cp_json_data.
    DATA type                TYPE REF TO cl_abap_typedescr.
    DATA name_transformation TYPE REF TO if_xco_json_transformation.
    DATA wants_booleans      TYPE abap_bool.

    METHODS with_booleans
      IMPORTING json_data     TYPE REF TO if_xco_cp_json_data
      RETURNING VALUE(result) TYPE REF TO if_xco_cp_json_data.

ENDCLASS.

CLASS lcl_boolean_paths IMPLEMENTATION.

  METHOD of.
    collect( EXPORTING type   = type
                       path   = ``
                       suffix = ``
             CHANGING  paths  = result ).
  ENDMETHOD.

  METHOD collect.
    CASE type->kind.
      WHEN cl_abap_typedescr=>kind_elem.
        IF is_boolean( type ) = abap_true.
          INSERT path INTO TABLE paths.
        ENDIF.

      WHEN cl_abap_typedescr=>kind_struct.
        collect_components( EXPORTING type   = CAST #( type )
                                      path   = path
                                      suffix = suffix
                            CHANGING  paths  = paths ).

      WHEN cl_abap_typedescr=>kind_table.
        collect( EXPORTING type   = CAST cl_abap_tabledescr( type )->get_table_line_type( )
                           path   = path
                           suffix = ``
                 CHANGING  paths  = paths ).
    ENDCASE.
  ENDMETHOD.

  METHOD collect_components.
    DATA(components) = type->get_components( ).

    " An included structure contributes its components in place, with the
    " suffix of the include, if any, appended to their names.
    LOOP AT components INTO DATA(component).
      IF component-as_include = abap_true.
        collect( EXPORTING type   = component-type
                           path   = path
                           suffix = component-suffix
                 CHANGING  paths  = paths ).
      ELSE.
        collect( EXPORTING type   = component-type
                           path   = join( path = path
                                          name = |{ component-name }{ suffix }| )
                           suffix = ``
                 CHANGING  paths  = paths ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD is_boolean.
    CASE type->get_relative_name( ).
      WHEN abap_bool_type OR abap_boolean_type OR xsdboolean_type OR boole_d_type OR xfeld_type.
        result = abap_true.
      WHEN OTHERS.
        result = abap_false.
    ENDCASE.
  ENDMETHOD.

  METHOD join.
    result = COND #( WHEN path IS INITIAL THEN name
                     ELSE |{ path }{ separator }{ name }| ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_boolean_rebuilder IMPLEMENTATION.

  METHOD constructor.
    me->booleans = booleans.
    builder = xco_cp_json=>data->builder( ).
  ENDMETHOD.

  METHOD document.
    result = builder->get_data( ).
  ENDMETHOD.

  METHOD enter.
    INSERT member INTO TABLE enclosing.
    CLEAR member.
  ENDMETHOD.

  METHOD leave.
    DATA(last) = lines( enclosing ).

    member = enclosing[ last ].
    DELETE enclosing INDEX last.
  ENDMETHOD.

  METHOD current_path.
    DATA(steps) = VALUE string_table( FOR step IN enclosing WHERE ( table_line IS NOT INITIAL ) ( step ) ).

    IF member IS NOT INITIAL.
      INSERT member INTO TABLE steps.
    ENDIF.

    result = concat_lines_of( table = steps
                              sep   = lcl_boolean_paths=>separator ).
  ENDMETHOD.

  METHOD if_xco_json_tree_visitor~on_start.
    " The builder is ready from construction; nothing to prepare.
  ENDMETHOD.

  METHOD if_xco_json_tree_visitor~on_end.
    " The last leave( ) already balanced the containers; nothing to finish.
  ENDMETHOD.

  METHOD if_xco_json_tree_visitor~enter_object.
    builder->begin_object( ).
    enter( ).
  ENDMETHOD.

  METHOD if_xco_json_tree_visitor~leave_object.
    builder->end_object( ).
    leave( ).
  ENDMETHOD.

  METHOD if_xco_json_tree_visitor~enter_array.
    builder->begin_array( ).
    enter( ).
  ENDMETHOD.

  METHOD if_xco_json_tree_visitor~leave_array.
    builder->end_array( ).
    leave( ).
  ENDMETHOD.

  METHOD if_xco_json_tree_visitor~visit_member.
    member = iv_name.
    builder->add_member( iv_name ).
  ENDMETHOD.

  METHOD if_xco_json_tree_visitor~visit_string.
    DATA(path) = current_path( ).

    IF line_exists( booleans[ table_line = path ] ).
      builder->add_boolean( xsdbool( iv_value = true_flag ) ).
    ELSE.
      builder->add_string( iv_value ).
    ENDIF.
  ENDMETHOD.

  METHOD if_xco_json_tree_visitor~visit_number.
    builder->add_number( iv_value ).
  ENDMETHOD.

  METHOD if_xco_json_tree_visitor~visit_boolean.
    builder->add_boolean( iv_value ).
  ENDMETHOD.

  METHOD if_xco_json_tree_visitor~visit_null.
    builder->add_null( ).
  ENDMETHOD.

ENDCLASS.

CLASS lcl_writer IMPLEMENTATION.

  METHOD constructor.
    lcl_type_guard=>ensure_convertible( data ).

    type = cl_abap_typedescr=>describe_by_data( data ).

    TRY.
        document = xco_cp_json=>data->from_abap( data ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_acu_json( text     = `The data object could not be opened as a JSON document`
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

  METHOD zif_json_writer~abap_bool_to_booleans.
    wants_booleans = abap_true.
    self = me.
  ENDMETHOD.

  METHOD zif_json_writer~to_string.
    TRY.
        DATA(json_data) = document.

        IF wants_booleans = abap_true.
          json_data = with_booleans( json_data ).
        ENDIF.

        IF name_transformation IS BOUND.
          json_data = json_data->apply( VALUE #( ( name_transformation ) ) ).
        ENDIF.

        result = json_data->to_string( ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_acu_json( text     = `The JSON string could not be generated`
                                          previous = xco_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD with_booleans.
    DATA(rebuilder) = NEW lcl_boolean_rebuilder( lcl_boolean_paths=>of( type ) ).

    json_data->traverse( rebuilder ).

    result = rebuilder->document( ).
  ENDMETHOD.

ENDCLASS.

"! One value of a parsed document. Objects and arrays hold their members and
"! elements in document order; scalars hold their text. The kind is the
"! element name the sXML JSON reader reports for the value.
CLASS lcl_node DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_json_node.

    METHODS constructor
      IMPORTING kind TYPE string
                name TYPE string.

    METHODS add_child
      IMPORTING child TYPE REF TO lcl_node.

    METHODS set_text
      IMPORTING text TYPE string.

  PRIVATE SECTION.
    CONSTANTS object_kind TYPE string VALUE `object`.
    CONSTANTS array_kind TYPE string VALUE `array`.
    CONSTANTS string_kind TYPE string VALUE `str`.
    CONSTANTS number_kind TYPE string VALUE `num`.
    CONSTANTS boolean_kind TYPE string VALUE `bool`.
    CONSTANTS null_kind TYPE string VALUE `null`.
    CONSTANTS true_text TYPE string VALUE `true`.
    CONSTANTS path_separator TYPE c LENGTH 1 VALUE '/'.
    CONSTANTS digits TYPE string VALUE `0123456789`.

    DATA kind TYPE string.
    DATA name TYPE string.
    DATA text TYPE string.
    DATA children TYPE zif_json_node=>nodes.

    METHODS find_child
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_json_node.

    METHODS step
      IMPORTING from          TYPE REF TO zif_json_node
                segment       TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_json_node
      RAISING   zcx_acu_json.

    METHODS label
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


"! Builds the node tree from the JSON-XML events of the released sXML reader.
"! Every value arrives as an element named object, array, str, num, bool or
"! null, carrying its member name as an attribute; scalars are followed by one
"! value node with their text. Malformed documents surface as a parse error
"! here, before any node exists.
CLASS lcl_tree DEFINITION FINAL.

  PUBLIC SECTION.
    METHODS parse
      IMPORTING json          TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_json_node
      RAISING   zcx_acu_json.

  PRIVATE SECTION.
    CONSTANTS name_attribute TYPE string VALUE `name`.

    DATA root TYPE REF TO lcl_node.
    DATA open_values TYPE STANDARD TABLE OF REF TO lcl_node WITH EMPTY KEY.

    METHODS to_utf8
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_acu_json.

    METHODS read_nodes
      IMPORTING reader TYPE REF TO if_sxml_reader
      RAISING   cx_sxml_parse_error.

    METHODS open_value
      IMPORTING element TYPE REF TO if_sxml_open_element.

    METHODS member_name
      IMPORTING element       TYPE REF TO if_sxml_open_element
      RETURNING VALUE(result) TYPE string.

    METHODS close_value.

    METHODS set_text
      IMPORTING value TYPE REF TO if_sxml_value_node.

    METHODS current_value
      RETURNING VALUE(result) TYPE REF TO lcl_node.

    METHODS describe
      IMPORTING error         TYPE REF TO cx_sxml_parse_error
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS lcl_node IMPLEMENTATION.

  METHOD constructor.
    me->kind = kind.
    me->name = name.
  ENDMETHOD.

  METHOD add_child.
    INSERT child INTO TABLE children.
  ENDMETHOD.

  METHOD set_text.
    me->text = text.
  ENDMETHOD.

  METHOD find_child.
    LOOP AT children INTO DATA(candidate).
      IF candidate->name( ) = name.
        result = candidate.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD step.
    DATA(is_position) = xsdbool( segment CO digits AND from->is_array( ) = abap_true ).

    IF is_position = abap_true.
      result = from->at( CONV i( segment ) ).
    ELSE.
      result = from->child( segment ).
    ENDIF.
  ENDMETHOD.

  METHOD label.
    result = COND #( WHEN name IS INITIAL THEN |The { kind } value|
                     ELSE |Member { name }| ).
  ENDMETHOD.

  METHOD zif_json_node~name.
    result = name.
  ENDMETHOD.

  METHOD zif_json_node~is_object.
    result = xsdbool( kind = object_kind ).
  ENDMETHOD.

  METHOD zif_json_node~is_array.
    result = xsdbool( kind = array_kind ).
  ENDMETHOD.

  METHOD zif_json_node~is_string.
    result = xsdbool( kind = string_kind ).
  ENDMETHOD.

  METHOD zif_json_node~is_number.
    result = xsdbool( kind = number_kind ).
  ENDMETHOD.

  METHOD zif_json_node~is_boolean.
    result = xsdbool( kind = boolean_kind ).
  ENDMETHOD.

  METHOD zif_json_node~is_null.
    result = xsdbool( kind = null_kind ).
  ENDMETHOD.

  METHOD zif_json_node~text.
    result = text.
  ENDMETHOD.

  METHOD zif_json_node~as_number.
    IF kind <> number_kind.
      RAISE EXCEPTION NEW zcx_acu_json( |{ label( ) } is not a number| ).
    ENDIF.

    TRY.
        result = CONV decfloat34( text ).
      CATCH cx_sy_conversion_error INTO DATA(error).
        RAISE EXCEPTION NEW zcx_acu_json( text     = |{ label( ) } holds { text }, which is not a number|
                                          previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_json_node~as_boolean.
    result = xsdbool( kind = boolean_kind AND text = true_text ).
  ENDMETHOD.

  METHOD zif_json_node~size.
    result = lines( children ).
  ENDMETHOD.

  METHOD zif_json_node~children.
    result = children.
  ENDMETHOD.

  METHOD zif_json_node~has_child.
    result = xsdbool( find_child( name ) IS BOUND ).
  ENDMETHOD.

  METHOD zif_json_node~child.
    IF kind <> object_kind.
      RAISE EXCEPTION NEW zcx_acu_json( |{ label( ) } is not an object and has no member { name }| ).
    ENDIF.

    result = find_child( name ).

    IF result IS NOT BOUND.
      RAISE EXCEPTION NEW zcx_acu_json( |{ label( ) } has no member { name }| ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_json_node~child_text.
    DATA(member) = find_child( name ).

    IF member IS BOUND.
      result = member->text( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_json_node~at.
    DATA(count) = lines( children ).

    IF position < 1 OR position > count.
      RAISE EXCEPTION NEW zcx_acu_json( |{ label( ) } has no position { position }, it holds { count } value(s)| ).
    ENDIF.

    result = children[ position ].
  ENDMETHOD.

  METHOD zif_json_node~descendant.
    SPLIT path AT path_separator INTO TABLE DATA(segments).

    result = me.

    LOOP AT segments INTO DATA(segment) WHERE table_line IS NOT INITIAL.
      result = step( from    = result
                     segment = segment ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_tree IMPLEMENTATION.

  METHOD parse.
    TRY.
        read_nodes( cl_sxml_string_reader=>create( to_utf8( json ) ) ).
      CATCH cx_sxml_parse_error INTO DATA(error).
        RAISE EXCEPTION NEW zcx_acu_json( text     = describe( error )
                                          previous = error ).
    ENDTRY.

    IF root IS NOT BOUND.
      RAISE EXCEPTION NEW zcx_acu_json( `The string holds no JSON value` ).
    ENDIF.

    result = root.
  ENDMETHOD.

  METHOD to_utf8.
    TRY.
        result = cl_abap_conv_codepage=>create_out( )->convert( text ).
      CATCH cx_parameter_invalid_range cx_sy_conversion_codepage INTO DATA(error).
        RAISE EXCEPTION NEW zcx_acu_json( text     = |The text cannot be encoded as UTF-8: { error->get_text( ) }|
                                          previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD read_nodes.
    DO.
      DATA(node) = reader->read_next_node( ).
      IF node IS NOT BOUND.
        EXIT.
      ENDIF.

      CASE node->type.
        WHEN if_sxml_node=>co_nt_element_open.
          open_value( CAST if_sxml_open_element( node ) ).
        WHEN if_sxml_node=>co_nt_element_close.
          close_value( ).
        WHEN if_sxml_node=>co_nt_value.
          set_text( CAST if_sxml_value_node( node ) ).
        WHEN if_sxml_node=>co_nt_final.
          EXIT.
      ENDCASE.
    ENDDO.
  ENDMETHOD.

  METHOD open_value.
    DATA(node) = NEW lcl_node( kind = element->qname-name
                               name = member_name( element ) ).

    IF open_values IS INITIAL.
      root = node.
    ELSE.
      current_value( )->add_child( node ).
    ENDIF.

    INSERT node INTO TABLE open_values.
  ENDMETHOD.

  METHOD member_name.
    DATA(attributes) = element->get_attributes( ).

    LOOP AT attributes INTO DATA(attribute).
      IF attribute->qname-name = name_attribute.
        result = attribute->get_value( ).
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD close_value.
    DELETE open_values INDEX lines( open_values ).
  ENDMETHOD.

  METHOD set_text.
    current_value( )->set_text( value->get_value( ) ).
  ENDMETHOD.

  METHOD current_value.
    result = open_values[ lines( open_values ) ].
  ENDMETHOD.

  METHOD describe.
    DATA(detail) = COND string( WHEN error->error_text IS INITIAL
                                THEN error->get_text( )
                                ELSE error->error_text ).

    result = |The string is not a JSON document, error at byte { error->xml_offset }: { detail }|.
  ENDMETHOD.

ENDCLASS.
