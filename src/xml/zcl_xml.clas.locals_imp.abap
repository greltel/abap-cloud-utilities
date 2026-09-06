*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

"! UTF-8 conversion between text and bytes; conversion failures are wrapped
"! into the utility's exception.
CLASS lcl_codepage DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS to_utf8
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_xml.

    CLASS-METHODS from_utf8
      IMPORTING bytes         TYPE xstring
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_xml.

ENDCLASS.


CLASS lcl_codepage IMPLEMENTATION.

  METHOD to_utf8.
    TRY.
        result = cl_abap_conv_codepage=>create_out( )->convert( text ).
      CATCH cx_parameter_invalid_range cx_sy_conversion_codepage INTO DATA(error).
        RAISE EXCEPTION NEW zcx_xml( text     = |The text cannot be encoded as UTF-8: { error->get_text( ) }|
                                     previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD from_utf8.
    TRY.
        result = cl_abap_conv_codepage=>create_in( )->convert( bytes ).
      CATCH cx_parameter_invalid_range cx_sy_conversion_codepage INTO DATA(error).
        RAISE EXCEPTION NEW zcx_xml( text     = |The bytes cannot be decoded as UTF-8: { error->get_text( ) }|
                                     previous = error ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


"! One element of the tree. The content keeps texts and child elements in
"! document order, so mixed content such as <p>Hello <b>World</b>!</p>
"! survives a round trip unchanged.
CLASS lcl_node DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_xml_node.

    ALIASES name          FOR zif_xml_node~name.
    ALIASES namespace     FOR zif_xml_node~namespace.
    ALIASES prefix        FOR zif_xml_node~prefix.
    ALIASES attributes    FOR zif_xml_node~attributes.
    ALIASES has_attribute FOR zif_xml_node~has_attribute.

    "! A text or a child element; a child element when is_element is set.
    TYPES: BEGIN OF content_item,
             is_element TYPE abap_bool,
             text       TYPE string,
             element    TYPE REF TO lcl_node,
           END OF content_item.
    TYPES content_items TYPE STANDARD TABLE OF content_item WITH EMPTY KEY.

    METHODS constructor
      IMPORTING name      TYPE string
                namespace TYPE string OPTIONAL
                prefix    TYPE string OPTIONAL.

    METHODS set_attribute
      IMPORTING attribute TYPE zif_xml_node=>attribute_pair.

    METHODS add_child
      IMPORTING element TYPE REF TO lcl_node.

    METHODS add_text
      IMPORTING value TYPE string.

    "! Texts and child elements in document order.
    METHODS content
      RETURNING VALUE(result) TYPE content_items.

  PRIVATE SECTION.
    DATA element_name TYPE string.
    DATA namespace_uri TYPE string.
    DATA namespace_prefix TYPE string.
    DATA attribute_pairs TYPE zif_xml_node=>attribute_pairs.
    DATA items TYPE content_items.

    METHODS first_child_named
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_xml_node.

ENDCLASS.


CLASS lcl_node IMPLEMENTATION.

  METHOD constructor.
    element_name     = name.
    namespace_uri    = namespace.
    namespace_prefix = prefix.
  ENDMETHOD.

  METHOD set_attribute.
    INSERT attribute INTO TABLE attribute_pairs.
  ENDMETHOD.

  METHOD add_child.
    INSERT VALUE #( is_element = abap_true
                    element    = element ) INTO TABLE items.
  ENDMETHOD.

  METHOD add_text.
    INSERT VALUE #( text = value ) INTO TABLE items.
  ENDMETHOD.

  METHOD content.
    result = items.
  ENDMETHOD.

  METHOD zif_xml_node~name.
    result = element_name.
  ENDMETHOD.

  METHOD zif_xml_node~namespace.
    result = namespace_uri.
  ENDMETHOD.

  METHOD zif_xml_node~prefix.
    result = namespace_prefix.
  ENDMETHOD.

  METHOD zif_xml_node~text.
    result = REDUCE #( INIT joined = ``
                       FOR item IN items WHERE ( is_element = abap_false )
                       NEXT joined = joined && item-text ).
  ENDMETHOD.

  METHOD zif_xml_node~attribute.
    result = VALUE #( attribute_pairs[ name = name ]-value OPTIONAL ).
  ENDMETHOD.

  METHOD zif_xml_node~has_attribute.
    result = xsdbool( line_exists( attribute_pairs[ name = name ] ) ).
  ENDMETHOD.

  METHOD zif_xml_node~attributes.
    result = attribute_pairs.
  ENDMETHOD.

  METHOD zif_xml_node~children.
    result = VALUE #( FOR item IN items WHERE ( is_element = abap_true ) ( item-element ) ).
  ENDMETHOD.

  METHOD zif_xml_node~children_named.
    LOOP AT items INTO DATA(item) WHERE is_element = abap_true.
      IF item-element->element_name = name.
        INSERT item-element INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_xml_node~has_child.
    DATA(child) = first_child_named( name ).
    result = xsdbool( child IS BOUND ).
  ENDMETHOD.

  METHOD zif_xml_node~child.
    result = first_child_named( name ).
    IF result IS NOT BOUND.
      RAISE EXCEPTION NEW zcx_xml( text = |Element "{ element_name }" has no child element "{ name }"| ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_xml_node~child_text.
    DATA(child) = first_child_named( name ).
    IF child IS BOUND.
      result = child->text( ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_xml_node~descendant.
    SPLIT path AT `/` INTO TABLE DATA(segments).

    result = me.
    LOOP AT segments INTO DATA(segment) WHERE table_line IS NOT INITIAL.
      result = result->child( segment ).
    ENDLOOP.
  ENDMETHOD.

  METHOD first_child_named.
    DATA(children) = zif_xml_node~children_named( name ).
    result = VALUE #( children[ 1 ] OPTIONAL ).
  ENDMETHOD.

ENDCLASS.


"! Writes a tree with the sXML string writer, which escapes texts and
"! attribute values, declares namespaces where they are first used and
"! starts the output with an XML declaration.
CLASS lcl_writer DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS serialize
      IMPORTING root          TYPE REF TO lcl_node
                indent        TYPE abap_bool
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_xml.

    METHODS constructor
      IMPORTING writer TYPE REF TO if_sxml_writer
                indent TYPE abap_bool.

  PRIVATE SECTION.
    DATA writer TYPE REF TO if_sxml_writer.

    METHODS write_element
      IMPORTING element TYPE REF TO lcl_node
      RAISING   cx_sxml_state_error
                cx_sxml_name_error.

    METHODS open_element
      IMPORTING element TYPE REF TO lcl_node
      RAISING   cx_sxml_state_error
                cx_sxml_name_error.

    METHODS write_attributes
      IMPORTING element TYPE REF TO lcl_node
      RAISING   cx_sxml_state_error
                cx_sxml_name_error.

    METHODS write_content
      IMPORTING element TYPE REF TO lcl_node
      RAISING   cx_sxml_state_error
                cx_sxml_name_error.

    "! The sXML writer generates a prefix for a namespace without one; the
    "! marker asks for the default namespace instead, as the tree means it.
    METHODS prefix_of
      IMPORTING element       TYPE REF TO lcl_node
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS lcl_writer IMPLEMENTATION.

  METHOD serialize.
    TRY.
        DATA(string_writer) = cl_sxml_string_writer=>create( ).

        NEW lcl_writer( writer = CAST if_sxml_writer( string_writer )
                        indent = indent )->write_element( root ).

        result = string_writer->get_output( ).
      CATCH cx_sxml_illegal_argument_error cx_sxml_state_error cx_sxml_name_error INTO DATA(error).
        RAISE EXCEPTION NEW zcx_xml( text     = |The XML document cannot be written: { error->get_text( ) }|
                                     previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD constructor.
    me->writer = writer.

    IF indent = abap_true.
      writer->set_option( if_sxml_writer=>co_opt_linebreaks ).
      writer->set_option( if_sxml_writer=>co_opt_indent ).
    ENDIF.
  ENDMETHOD.

  METHOD write_element.
    open_element( element ).
    write_attributes( element ).
    write_content( element ).
    writer->close_element( ).
  ENDMETHOD.

  METHOD open_element.
    IF element->namespace( ) IS INITIAL.
      writer->open_element( element->name( ) ).
    ELSE.
      writer->open_element( name   = element->name( )
                            nsuri  = element->namespace( )
                            prefix = prefix_of( element ) ).
    ENDIF.
  ENDMETHOD.

  METHOD prefix_of.
    result = COND #( WHEN element->prefix( ) IS INITIAL
                     THEN if_sxml_named=>co_use_default_xmlns
                     ELSE element->prefix( ) ).
  ENDMETHOD.

  METHOD write_attributes.
    DATA(attributes) = element->attributes( ).

    LOOP AT attributes INTO DATA(attribute).
      IF attribute-namespace IS INITIAL.
        writer->write_attribute( name  = attribute-name
                                 value = attribute-value ).
      ELSE.
        writer->write_attribute( name   = attribute-name
                                 nsuri  = attribute-namespace
                                 prefix = attribute-prefix
                                 value  = attribute-value ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD write_content.
    DATA(items) = element->content( ).

    LOOP AT items INTO DATA(item).
      IF item-is_element = abap_true.
        write_element( item-element ).
      ELSE.
        writer->write_value( item-text ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


"! The tree behind {@link zif_xml_document}.
CLASS lcl_document DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_xml_document.

    METHODS constructor
      IMPORTING root TYPE REF TO lcl_node.

  PRIVATE SECTION.
    DATA root TYPE REF TO lcl_node.

ENDCLASS.


CLASS lcl_document IMPLEMENTATION.

  METHOD constructor.
    me->root = root.
  ENDMETHOD.

  METHOD zif_xml_document~root.
    result = root.
  ENDMETHOD.

  METHOD zif_xml_document~to_string.
    result = lcl_codepage=>from_utf8( zif_xml_document~to_xstring( ) ).
  ENDMETHOD.

  METHOD zif_xml_document~to_indented_string.
    result = lcl_codepage=>from_utf8( zif_xml_document~to_indented_xstring( ) ).
  ENDMETHOD.

  METHOD zif_xml_document~to_xstring.
    result = lcl_writer=>serialize( root   = root
                                    indent = abap_false ).
  ENDMETHOD.

  METHOD zif_xml_document~to_indented_xstring.
    result = lcl_writer=>serialize( root   = root
                                    indent = abap_true ).
  ENDMETHOD.

ENDCLASS.


"! Parses XML into a tree with the sXML string reader. The reader checks
"! well-formedness, decodes entities and drops whitespace that only separates
"! elements, so the tree holds exactly the names, attributes and texts of the
"! document.
CLASS lcl_reader DEFINITION FINAL.

  PUBLIC SECTION.
    METHODS parse
      IMPORTING xml           TYPE xstring
      RETURNING VALUE(result) TYPE REF TO lcl_node
      RAISING   zcx_xml.

  PRIVATE SECTION.
    TYPES element_stack TYPE STANDARD TABLE OF REF TO lcl_node WITH EMPTY KEY.

    DATA root TYPE REF TO lcl_node.
    DATA open_elements TYPE element_stack.

    METHODS read_nodes
      IMPORTING reader TYPE REF TO if_sxml_reader
      RAISING   cx_sxml_parse_error.

    METHODS open_element
      IMPORTING element TYPE REF TO if_sxml_open_element.

    METHODS close_element.

    METHODS add_text
      IMPORTING value TYPE REF TO if_sxml_value_node.

    METHODS current_element
      RETURNING VALUE(result) TYPE REF TO lcl_node.

    METHODS describe
      IMPORTING error         TYPE REF TO cx_sxml_parse_error
      RETURNING VALUE(result) TYPE string.

    "! The reader may report the default namespace with a marker instead of
    "! the empty prefix that the document actually uses.
    METHODS document_prefix
      IMPORTING prefix        TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS lcl_reader IMPLEMENTATION.

  METHOD parse.
    TRY.
        read_nodes( cl_sxml_string_reader=>create( xml ) ).
      CATCH cx_sxml_parse_error INTO DATA(error).
        RAISE EXCEPTION NEW zcx_xml( text     = describe( error )
                                     previous = error ).
    ENDTRY.

    IF root IS NOT BOUND.
      RAISE EXCEPTION NEW zcx_xml( text = `The XML document has no root element` ).
    ENDIF.

    result = root.
  ENDMETHOD.

  METHOD read_nodes.
    DO.
      DATA(node) = reader->read_next_node( ).
      IF node IS NOT BOUND.
        EXIT.
      ENDIF.

      CASE node->type.
        WHEN if_sxml_node=>co_nt_element_open.
          open_element( CAST if_sxml_open_element( node ) ).
        WHEN if_sxml_node=>co_nt_element_close.
          close_element( ).
        WHEN if_sxml_node=>co_nt_value.
          add_text( CAST if_sxml_value_node( node ) ).
        WHEN if_sxml_node=>co_nt_final.
          EXIT.
      ENDCASE.
    ENDDO.
  ENDMETHOD.

  METHOD open_element.
    DATA(node) = NEW lcl_node( name      = element->qname-name
                               namespace = element->qname-namespace
                               prefix    = document_prefix( element->prefix ) ).

    DATA(attributes) = element->get_attributes( ).
    LOOP AT attributes INTO DATA(attribute).
      node->set_attribute( VALUE #( name      = attribute->qname-name
                                    value     = attribute->get_value( )
                                    namespace = attribute->qname-namespace
                                    prefix    = attribute->prefix ) ).
    ENDLOOP.

    IF open_elements IS INITIAL.
      root = node.
    ELSE.
      current_element( )->add_child( node ).
    ENDIF.

    INSERT node INTO TABLE open_elements.
  ENDMETHOD.

  METHOD close_element.
    DELETE open_elements INDEX lines( open_elements ).
  ENDMETHOD.

  METHOD add_text.
    current_element( )->add_text( value->get_value( ) ).
  ENDMETHOD.

  METHOD current_element.
    result = open_elements[ lines( open_elements ) ].
  ENDMETHOD.

  METHOD describe.
    DATA(detail) = COND string( WHEN error->error_text IS INITIAL
                                THEN error->get_text( )
                                ELSE error->error_text ).

    result = |The XML is not well-formed at byte { error->xml_offset }: { detail }|.
  ENDMETHOD.

  METHOD document_prefix.
    result = COND #( WHEN prefix = if_sxml_named=>co_use_default_xmlns
                     THEN ``
                     ELSE prefix ).
  ENDMETHOD.

ENDCLASS.


"! Collects the tree for {@link zif_xml_builder}. The current element is the
"! innermost open one; when none is open, the next element becomes the root.
"! Mistakes are remembered - the first one wins - and reported by build( ),
"! which is the only method of the chain that raises.
CLASS lcl_builder DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_xml_builder.

  PRIVATE SECTION.
    TYPES element_stack TYPE STANDARD TABLE OF REF TO lcl_node WITH EMPTY KEY.

    "! ASCII punctuation and whitespace that cannot appear in an XML name.
    "! The colon is rejected too: a namespace prefix is passed separately.
    CONSTANTS forbidden_name_chars TYPE string VALUE ` <>&"'/=?!,;:()[]{}@#$%^*+~|\`.
    "! Characters that may appear in an XML name but not start it.
    CONSTANTS forbidden_first_chars TYPE string VALUE `0123456789-.`.

    DATA root TYPE REF TO lcl_node.
    DATA open_elements TYPE element_stack.
    DATA first_error TYPE string.

    METHODS current_element
      RETURNING VALUE(result) TYPE REF TO lcl_node.

    METHODS remember
      IMPORTING error TYPE string.

    METHODS is_valid_name
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS lcl_builder IMPLEMENTATION.

  METHOD zif_xml_builder~element.
    self = me.

    IF is_valid_name( name ) = abap_false.
      remember( |Invalid element name "{ name }"| ).
      RETURN.
    ENDIF.

    IF prefix IS NOT INITIAL AND namespace IS INITIAL.
      remember( |Element "{ name }" has the prefix "{ prefix }" but no namespace URI| ).
      RETURN.
    ENDIF.

    IF root IS BOUND AND open_elements IS INITIAL.
      remember( |Element "{ name }" cannot follow the root element "{ root->name( ) }"| ).
      RETURN.
    ENDIF.

    DATA(element) = NEW lcl_node( name      = name
                                  namespace = namespace
                                  prefix    = prefix ).

    IF open_elements IS INITIAL.
      root = element.
    ELSE.
      current_element( )->add_child( element ).
    ENDIF.

    INSERT element INTO TABLE open_elements.
  ENDMETHOD.

  METHOD zif_xml_builder~attribute.
    self = me.

    IF open_elements IS INITIAL.
      remember( |Attribute "{ name }" has no element to belong to| ).
      RETURN.
    ENDIF.

    IF is_valid_name( name ) = abap_false.
      remember( |Invalid attribute name "{ name }"| ).
      RETURN.
    ENDIF.

    DATA(element) = current_element( ).
    IF element->has_attribute( name ) = abap_true.
      remember( |Attribute "{ name }" is set twice on element "{ element->name( ) }"| ).
      RETURN.
    ENDIF.

    element->set_attribute( VALUE #( name  = name
                                     value = value ) ).
  ENDMETHOD.

  METHOD zif_xml_builder~text.
    self = me.

    IF open_elements IS INITIAL.
      remember( `Text has no element to belong to` ).
      RETURN.
    ENDIF.

    current_element( )->add_text( value ).
  ENDMETHOD.

  METHOD zif_xml_builder~leaf.
    self = zif_xml_builder~element( name )->text( value )->close( ).
  ENDMETHOD.

  METHOD zif_xml_builder~close.
    self = me.

    IF open_elements IS INITIAL.
      remember( `close( ) was called without an open element` ).
      RETURN.
    ENDIF.

    DELETE open_elements INDEX lines( open_elements ).
  ENDMETHOD.

  METHOD zif_xml_builder~build.
    IF first_error IS NOT INITIAL.
      RAISE EXCEPTION NEW zcx_xml( text = first_error ).
    ENDIF.

    IF root IS NOT BOUND.
      RAISE EXCEPTION NEW zcx_xml( text = `The document has no root element - add one with element( )` ).
    ENDIF.

    result = NEW lcl_document( root ).
  ENDMETHOD.

  METHOD current_element.
    result = open_elements[ lines( open_elements ) ].
  ENDMETHOD.

  METHOD remember.
    IF first_error IS INITIAL.
      first_error = error.
    ENDIF.
  ENDMETHOD.

  METHOD is_valid_name.
    IF name IS INITIAL OR name CA forbidden_name_chars.
      result = abap_false.
      RETURN.
    ENDIF.

    DATA(first_char) = substring( val = name
                                  off = 0
                                  len = 1 ).
    result = xsdbool( first_char NA forbidden_first_chars ).
  ENDMETHOD.

ENDCLASS.
