*"* use this source file for your ABAP unit test classes
"! Shared assertions for the negative paths.
CLASS lth_failure DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PUBLIC SECTION.
    "! Asserts that the text is rejected as XML.
    CLASS-METHODS assert_parse_fails
      IMPORTING xml TYPE string
                msg TYPE string.

    "! Asserts that build( ) reports a mistake in the chain.
    CLASS-METHODS assert_build_fails
      IMPORTING builder TYPE REF TO zif_xml_builder
                msg     TYPE string.

ENDCLASS.


CLASS lth_failure IMPLEMENTATION.

  METHOD assert_parse_fails.
    TRY.
        zcl_xml=>parse( xml ).
        cl_abap_unit_assert=>fail( msg ).
      CATCH zcx_xml INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial( act = error->get_text( )
                                                 msg = 'A rejected document must come with a description' ).
    ENDTRY.
  ENDMETHOD.

  METHOD assert_build_fails.
    TRY.
        builder->build( ).
        cl_abap_unit_assert=>fail( msg ).
      CATCH zcx_xml INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial( act = error->get_text( )
                                                 msg = 'A rejected chain must come with a description' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_parsing DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS given_element_then_name_text      FOR TESTING RAISING cx_static_check.
    METHODS given_declaration_then_parsed     FOR TESTING RAISING cx_static_check.
    METHODS given_attributes_then_read        FOR TESTING RAISING cx_static_check.
    METHODS given_no_attribute_then_empty     FOR TESTING RAISING cx_static_check.
    METHODS given_entities_then_decoded       FOR TESTING RAISING cx_static_check.
    METHODS given_cdata_then_text             FOR TESTING RAISING cx_static_check.
    METHODS given_empty_element_then_empty    FOR TESTING RAISING cx_static_check.
    METHODS given_indented_then_no_blanks     FOR TESTING RAISING cx_static_check.
    METHODS given_mixed_content_then_kept     FOR TESTING RAISING cx_static_check.
    METHODS given_prefix_then_local_name      FOR TESTING RAISING cx_static_check.
    METHODS given_default_ns_then_no_pfx      FOR TESTING RAISING cx_static_check.
    METHODS given_prefixed_attr_then_pair     FOR TESTING RAISING cx_static_check.
    METHODS given_xstring_then_parsed         FOR TESTING RAISING cx_static_check.
    METHODS given_wrong_end_tag_raises        FOR TESTING RAISING cx_static_check.
    METHODS given_empty_text_then_raises      FOR TESTING RAISING cx_static_check.
    METHODS given_no_markup_then_raises       FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_parsing IMPLEMENTATION.

  METHOD given_element_then_name_text.
    DATA(root) = zcl_xml=>parse( `<greeting>Hello</greeting>` )->root( ).

    cl_abap_unit_assert=>assert_equals( act = root->name( )
                                        exp = `greeting`
                                        msg = 'The root element must carry the name of the outermost tag' ).
    cl_abap_unit_assert=>assert_equals( act = root->text( )
                                        exp = `Hello`
                                        msg = 'The text between the tags must be the element text' ).
  ENDMETHOD.

  METHOD given_declaration_then_parsed.
    DATA(root) = zcl_xml=>parse( `<?xml version="1.0" encoding="UTF-8"?><order/>` )->root( ).

    cl_abap_unit_assert=>assert_equals( act = root->name( )
                                        exp = `order`
                                        msg = 'An XML declaration must be accepted in front of the root' ).
  ENDMETHOD.

  METHOD given_attributes_then_read.
    DATA(root) = zcl_xml=>parse( `<order id="4711" currency="EUR"/>` )->root( ).

    cl_abap_unit_assert=>assert_equals( act = root->attribute( `currency` )
                                        exp = `EUR`
                                        msg = 'An attribute must be read by name' ).
    cl_abap_unit_assert=>assert_equals( act = root->has_attribute( `id` )
                                        exp = abap_true
                                        msg = 'A present attribute must be reported as present' ).
    cl_abap_unit_assert=>assert_equals( act = root->attributes( )
                                        exp = VALUE zif_xml_node=>attribute_pairs( ( name  = `id`
                                                                                     value = `4711` )
                                                                                   ( name  = `currency`
                                                                                     value = `EUR` ) )
                                        msg = 'All attributes must be listed in document order' ).
  ENDMETHOD.

  METHOD given_no_attribute_then_empty.
    DATA(root) = zcl_xml=>parse( `<order id="4711"/>` )->root( ).

    cl_abap_unit_assert=>assert_initial( act = root->attribute( `currency` )
                                         msg = 'A missing attribute must read as empty text' ).
    cl_abap_unit_assert=>assert_equals( act = root->has_attribute( `currency` )
                                        exp = abap_false
                                        msg = 'A missing attribute must be reported as missing' ).
  ENDMETHOD.

  METHOD given_entities_then_decoded.
    DATA(root) = zcl_xml=>parse( `<a k="&lt;&amp;&quot;">1 &lt; 2 &amp; 3</a>` )->root( ).

    cl_abap_unit_assert=>assert_equals( act = root->text( )
                                        exp = `1 < 2 & 3`
                                        msg = 'Entities in text must be decoded' ).
    cl_abap_unit_assert=>assert_equals( act = root->attribute( `k` )
                                        exp = `<&"`
                                        msg = 'Entities in attribute values must be decoded' ).
  ENDMETHOD.

  METHOD given_cdata_then_text.
    DATA(root) = zcl_xml=>parse( `<a><![CDATA[<raw> & more]]></a>` )->root( ).

    cl_abap_unit_assert=>assert_equals( act = root->text( )
                                        exp = `<raw> & more`
                                        msg = 'A CDATA section must become plain text' ).
  ENDMETHOD.

  METHOD given_empty_element_then_empty.
    DATA(root) = zcl_xml=>parse( `<a/>` )->root( ).

    cl_abap_unit_assert=>assert_initial( act = root->text( )
                                         msg = 'An empty element has no text' ).
    cl_abap_unit_assert=>assert_initial( act = root->children( )
                                         msg = 'An empty element has no children' ).
  ENDMETHOD.

  METHOD given_indented_then_no_blanks.
    DATA(lf) = cl_abap_char_utilities=>newline.
    DATA(xml) = |<order>{ lf }  <item>Pen</item>{ lf }  <item>Ink</item>{ lf }</order>{ lf }|.

    DATA(root) = zcl_xml=>parse( xml )->root( ).

    cl_abap_unit_assert=>assert_equals( act = lines( root->children( ) )
                                        exp = 2
                                        msg = 'Whitespace between elements must not become content' ).
    cl_abap_unit_assert=>assert_initial( act = root->text( )
                                         msg = 'Whitespace between elements must not become text' ).
    DATA(children) = root->children( ).
    cl_abap_unit_assert=>assert_equals( act = children[ 2 ]->text( )
                                        exp = `Ink`
                                        msg = 'Texts of the children must be unaffected' ).
  ENDMETHOD.

  METHOD given_mixed_content_then_kept.
    DATA(root) = zcl_xml=>parse( `<p>Hello <b>World</b>!</p>` )->root( ).

    cl_abap_unit_assert=>assert_equals( act = root->text( )
                                        exp = `Hello !`
                                        msg = 'The direct texts must be joined, child text excluded' ).
    cl_abap_unit_assert=>assert_equals( act = root->child_text( `b` )
                                        exp = `World`
                                        msg = 'The child element must keep its own text' ).
  ENDMETHOD.

  METHOD given_prefix_then_local_name.
    DATA(root) = zcl_xml=>parse( `<s:env xmlns:s="urn:x"><s:body/></s:env>` )->root( ).

    cl_abap_unit_assert=>assert_equals( act = root->name( )
                                        exp = `env`
                                        msg = 'The element name must be the local name without prefix' ).
    cl_abap_unit_assert=>assert_equals( act = root->namespace( )
                                        exp = `urn:x`
                                        msg = 'The namespace URI must be resolved from the prefix' ).
    cl_abap_unit_assert=>assert_equals( act = root->prefix( )
                                        exp = `s`
                                        msg = 'The prefix used in the document must be kept' ).
    cl_abap_unit_assert=>assert_equals( act = root->child( `body` )->namespace( )
                                        exp = `urn:x`
                                        msg = 'A prefixed child must resolve to the same namespace' ).
  ENDMETHOD.

  METHOD given_default_ns_then_no_pfx.
    DATA(root) = zcl_xml=>parse( `<order xmlns="urn:shop"><item/></order>` )->root( ).

    cl_abap_unit_assert=>assert_equals( act = root->namespace( )
                                        exp = `urn:shop`
                                        msg = 'A default namespace must apply to the declaring element' ).
    cl_abap_unit_assert=>assert_initial( act = root->prefix( )
                                         msg = 'A default namespace has no prefix' ).
    cl_abap_unit_assert=>assert_equals( act = root->child( `item` )->namespace( )
                                        exp = `urn:shop`
                                        msg = 'A default namespace must be inherited by the children' ).
  ENDMETHOD.

  METHOD given_prefixed_attr_then_pair.
    DATA(root) = zcl_xml=>parse( `<a xmlns:x="urn:x" x:nil="true"/>` )->root( ).

    cl_abap_unit_assert=>assert_equals( act = root->attribute( `nil` )
                                        exp = `true`
                                        msg = 'A prefixed attribute must be read by its local name' ).
    cl_abap_unit_assert=>assert_equals( act = root->attributes( )
                                        exp = VALUE zif_xml_node=>attribute_pairs( ( name      = `nil`
                                                                                     value     = `true`
                                                                                     namespace = `urn:x`
                                                                                     prefix    = `x` ) )
                                        msg = 'xmlns is no attribute; the prefixed attribute keeps its namespace' ).
  ENDMETHOD.

  METHOD given_xstring_then_parsed.
    DATA(bytes) = cl_abap_conv_codepage=>create_out( )->convert( `<order><id>1</id></order>` ).

    DATA(root) = zcl_xml=>parse_xstring( bytes )->root( ).

    cl_abap_unit_assert=>assert_equals( act = root->child_text( `id` )
                                        exp = `1`
                                        msg = 'UTF-8 bytes must parse like the text they encode' ).
  ENDMETHOD.

  METHOD given_wrong_end_tag_raises.
    lth_failure=>assert_parse_fails( xml = `<order><item>Pen</order>`
                                     msg = 'A mismatched end tag must be rejected' ).
  ENDMETHOD.

  METHOD given_empty_text_then_raises.
    lth_failure=>assert_parse_fails( xml = ``
                                     msg = 'An empty text is no XML document' ).
  ENDMETHOD.

  METHOD given_no_markup_then_raises.
    lth_failure=>assert_parse_fails( xml = `just text`
                                     msg = 'Text without a root element is no XML document' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_navigation DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    DATA order TYPE REF TO zif_xml_node.

    METHODS setup RAISING zcx_xml.

    METHODS given_children_then_in_order      FOR TESTING RAISING cx_static_check.
    METHODS given_name_then_only_those        FOR TESTING RAISING cx_static_check.
    METHODS given_child_then_first_match      FOR TESTING RAISING cx_static_check.
    METHODS given_no_child_then_raises        FOR TESTING RAISING cx_static_check.
    METHODS given_has_child_then_bool         FOR TESTING RAISING cx_static_check.
    METHODS given_no_child_then_empty_text    FOR TESTING RAISING cx_static_check.
    METHODS given_path_then_descendant        FOR TESTING RAISING cx_static_check.
    METHODS given_slashes_then_ignored        FOR TESTING RAISING cx_static_check.
    METHODS given_bad_path_then_raises        FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_navigation IMPLEMENTATION.

  METHOD setup.
    order = zcl_xml=>parse( `<order>` &&
                            `<header><buyer><id>B-1</id></buyer></header>` &&
                            `<item sku="K-1">Keyboard</item>` &&
                            `<note>rush</note>` &&
                            `<item sku="M-2">Mouse</item>` &&
                            `</order>` )->root( ).
  ENDMETHOD.

  METHOD given_children_then_in_order.
    DATA(children) = order->children( ).

    DATA(names) = VALUE string_table( FOR child IN children ( child->name( ) ) ).

    cl_abap_unit_assert=>assert_equals( act = names
                                        exp = VALUE string_table( ( `header` ) ( `item` ) ( `note` ) ( `item` ) )
                                        msg = 'Children must be listed in document order' ).
  ENDMETHOD.

  METHOD given_name_then_only_those.
    DATA(items) = order->children_named( `item` ).

    cl_abap_unit_assert=>assert_equals( act = lines( items )
                                        exp = 2
                                        msg = 'Only the children with the given name must be listed' ).
    cl_abap_unit_assert=>assert_equals( act = items[ 2 ]->attribute( `sku` )
                                        exp = `M-2`
                                        msg = 'Named children must keep their document order' ).
  ENDMETHOD.

  METHOD given_child_then_first_match.
    cl_abap_unit_assert=>assert_equals( act = order->child( `item` )->text( )
                                        exp = `Keyboard`
                                        msg = 'child( ) must return the first child with that name' ).
  ENDMETHOD.

  METHOD given_no_child_then_raises.
    TRY.
        order->child( `footer` ).
        cl_abap_unit_assert=>fail( 'A missing child must raise' ).
      CATCH zcx_xml INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial( act = error->get_text( )
                                                 msg = 'The error must name the missing child' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_has_child_then_bool.
    cl_abap_unit_assert=>assert_equals( act = order->has_child( `note` )
                                        exp = abap_true
                                        msg = 'An existing child must be reported' ).
    cl_abap_unit_assert=>assert_equals( act = order->has_child( `footer` )
                                        exp = abap_false
                                        msg = 'A missing child must not be reported' ).
  ENDMETHOD.

  METHOD given_no_child_then_empty_text.
    cl_abap_unit_assert=>assert_equals( act = order->child_text( `note` )
                                        exp = `rush`
                                        msg = 'child_text( ) must return the text of the child' ).
    cl_abap_unit_assert=>assert_initial( act = order->child_text( `footer` )
                                         msg = 'child_text( ) of a missing child must be empty, not an error' ).
  ENDMETHOD.

  METHOD given_path_then_descendant.
    cl_abap_unit_assert=>assert_equals( act = order->descendant( `header/buyer/id` )->text( )
                                        exp = `B-1`
                                        msg = 'A path must be resolved step by step' ).
  ENDMETHOD.

  METHOD given_slashes_then_ignored.
    cl_abap_unit_assert=>assert_equals( act = order->descendant( `/header//buyer/` )->name( )
                                        exp = `buyer`
                                        msg = 'Leading, doubled and trailing slashes must not matter' ).
  ENDMETHOD.

  METHOD given_bad_path_then_raises.
    TRY.
        order->descendant( `header/seller/id` ).
        cl_abap_unit_assert=>fail( 'A path with an unknown segment must raise' ).
      CATCH zcx_xml INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial( act = error->get_text( )
                                                 msg = 'The error must name the unresolved segment' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_building DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS given_chain_then_compact_xml      FOR TESTING RAISING cx_static_check.
    METHODS given_document_then_no_decl      FOR TESTING RAISING cx_static_check.
    METHODS given_no_content_then_closed      FOR TESTING RAISING cx_static_check.
    METHODS given_mixed_content_then_order    FOR TESTING RAISING cx_static_check.
    METHODS given_open_then_auto_closed       FOR TESTING RAISING cx_static_check.
    METHODS given_special_chars_escaped       FOR TESTING RAISING cx_static_check.
    METHODS given_indent_then_line_breaks     FOR TESTING RAISING cx_static_check.
    METHODS given_prefix_then_ns_declared     FOR TESTING RAISING cx_static_check.
    METHODS given_default_ns_then_declared    FOR TESTING RAISING cx_static_check.
    METHODS given_xstring_then_round_trip     FOR TESTING RAISING cx_static_check.
    METHODS given_parsed_then_written_same    FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_building IMPLEMENTATION.

  METHOD given_chain_then_compact_xml.
    DATA(xml) = zcl_xml=>builder( )->element( `order`
                                 )->attribute( name  = `id`
                                               value = `1`
                                 )->leaf( name  = `item`
                                          value = `Pen`
                                 )->build( )->to_string( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( contains( val = xml
                                                               sub = `<order id="1"><item>Pen</item></order>` ) )
                                      msg = |Compact output must hold elements, attributes and text: { xml }| ).
  ENDMETHOD.

  METHOD given_document_then_no_decl.
    DATA(xml) = zcl_xml=>builder( )->element( `a` )->build( )->to_string( ).

    cl_abap_unit_assert=>assert_equals( act = xml
                                        exp = `<a/>`
                                        msg = 'The output is the document alone, without an XML declaration' ).
  ENDMETHOD.

  METHOD given_no_content_then_closed.
    DATA(xml) = zcl_xml=>builder( )->element( `a` )->element( `b` )->build( )->to_string( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( contains( val = xml
                                                               sub = `<a><b/></a>` ) )
                                      msg = |An element without content must be self-closing: { xml }| ).
  ENDMETHOD.

  METHOD given_mixed_content_then_order.
    DATA(xml) = zcl_xml=>builder( )->element( `p`
                                 )->text( `Hello `
                                 )->leaf( name  = `b`
                                          value = `World`
                                 )->text( `!`
                                 )->build( )->to_string( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( contains( val = xml
                                                               sub = `<p>Hello <b>World</b>!</p>` ) )
                                      msg = |Texts and elements must keep the order they were added in: { xml }| ).
  ENDMETHOD.

  METHOD given_open_then_auto_closed.
    DATA(root) = zcl_xml=>builder( )->element( `a` )->element( `b` )->element( `c` )->build( )->root( ).

    cl_abap_unit_assert=>assert_equals( act = root->descendant( `b/c` )->name( )
                                        exp = `c`
                                        msg = 'Elements left open at build( ) must be nested as opened' ).
  ENDMETHOD.

  METHOD given_special_chars_escaped.
    DATA(text) = `1 < 2 & "two" > 'one'`.

    DATA(xml) = zcl_xml=>builder( )->element( `a`
                                 )->attribute( name  = `k`
                                               value = text
                                 )->text( text
                                 )->build( )->to_string( ).
    DATA(root) = zcl_xml=>parse( xml )->root( ).

    cl_abap_unit_assert=>assert_equals( act = root->text( )
                                        exp = text
                                        msg = 'Special characters in text must survive a round trip' ).
    cl_abap_unit_assert=>assert_equals( act = root->attribute( `k` )
                                        exp = text
                                        msg = 'Special characters in attributes must survive a round trip' ).
  ENDMETHOD.

  METHOD given_indent_then_line_breaks.
    DATA(document) = zcl_xml=>builder( )->element( `a` )->leaf( name  = `b`
                                                                value = `1` )->build( ).

    DATA(compact) = document->to_string( ).
    DATA(indented) = document->to_indented_string( ).

    cl_abap_unit_assert=>assert_false( act = xsdbool( contains( val = compact
                                                                sub = cl_abap_char_utilities=>newline ) )
                                       msg = 'Compact output must have no line breaks' ).
    cl_abap_unit_assert=>assert_true( act = xsdbool( contains( val = indented
                                                               sub = cl_abap_char_utilities=>newline ) )
                                      msg = 'Indented output must have line breaks' ).
    cl_abap_unit_assert=>assert_equals( act = zcl_xml=>parse( indented )->root( )->child_text( `b` )
                                        exp = `1`
                                        msg = 'Indentation must not change the content' ).
  ENDMETHOD.

  METHOD given_prefix_then_ns_declared.
    DATA(xml) = zcl_xml=>builder( )->element( name      = `Envelope`
                                              namespace = `urn:soap`
                                              prefix    = `s`
                                 )->element( name      = `Body`
                                             namespace = `urn:soap`
                                             prefix    = `s`
                                 )->build( )->to_string( ).
    DATA(root) = zcl_xml=>parse( xml )->root( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( contains( val = xml
                                                               sub = `xmlns:s="urn:soap"` ) )
                                      msg = |The namespace must be declared with its prefix: { xml }| ).
    cl_abap_unit_assert=>assert_equals( act = root->child( `Body` )->namespace( )
                                        exp = `urn:soap`
                                        msg = 'The namespace must survive a round trip' ).
    cl_abap_unit_assert=>assert_equals( act = root->child( `Body` )->prefix( )
                                        exp = `s`
                                        msg = 'The prefix must survive a round trip' ).
  ENDMETHOD.

  METHOD given_default_ns_then_declared.
    DATA(xml) = zcl_xml=>builder( )->element( name      = `order`
                                              namespace = `urn:shop`
                                 )->leaf( name  = `id`
                                          value = `1`
                                 )->build( )->to_string( ).
    DATA(root) = zcl_xml=>parse( xml )->root( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( contains( val = xml
                                                               sub = `xmlns="urn:shop"` ) )
                                      msg = |A namespace without prefix must be declared as default: { xml }| ).
    cl_abap_unit_assert=>assert_equals( act = root->namespace( )
                                        exp = `urn:shop`
                                        msg = 'The default namespace must survive a round trip' ).
  ENDMETHOD.

  METHOD given_xstring_then_round_trip.
    DATA(bytes) = zcl_xml=>builder( )->element( `a`
                                   )->leaf( name  = `b`
                                            value = `x`
                                   )->build( )->to_xstring( ).

    cl_abap_unit_assert=>assert_equals( act = zcl_xml=>parse_xstring( bytes )->root( )->child_text( `b` )
                                        exp = `x`
                                        msg = 'Bytes written must parse back to the same tree' ).
  ENDMETHOD.

  METHOD given_parsed_then_written_same.
    DATA(source) = `<order id="1"><item sku="K-1">Pen &amp; Ink</item><empty/></order>`.

    DATA(xml) = zcl_xml=>parse( source )->to_string( ).

    cl_abap_unit_assert=>assert_true( act = xsdbool( contains( val = xml
                                                               sub = source ) )
                                      msg = |A parsed document must be written back unchanged: { xml }| ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_builder_errors DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS given_no_element_then_raises      FOR TESTING RAISING cx_static_check.
    METHODS given_attr_first_then_raises      FOR TESTING RAISING cx_static_check.
    METHODS given_text_first_then_raises      FOR TESTING RAISING cx_static_check.
    METHODS given_second_root_then_raises     FOR TESTING RAISING cx_static_check.
    METHODS given_extra_close_then_raises     FOR TESTING RAISING cx_static_check.
    METHODS given_twice_attr_then_raises      FOR TESTING RAISING cx_static_check.
    METHODS given_space_in_name_raises        FOR TESTING RAISING cx_static_check.
    METHODS given_digit_first_then_raises     FOR TESTING RAISING cx_static_check.
    METHODS given_colon_in_name_raises        FOR TESTING RAISING cx_static_check.
    METHODS given_prefix_no_ns_then_raises    FOR TESTING RAISING cx_static_check.
    METHODS given_errors_then_first_wins      FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_builder_errors IMPLEMENTATION.

  METHOD given_no_element_then_raises.
    lth_failure=>assert_build_fails( builder = zcl_xml=>builder( )
                                     msg     = 'A document without elements must be rejected' ).
  ENDMETHOD.

  METHOD given_attr_first_then_raises.
    lth_failure=>assert_build_fails( builder = zcl_xml=>builder( )->attribute( name  = `id`
                                                                               value = `1` )
                                     msg     = 'An attribute before the first element must be rejected' ).
  ENDMETHOD.

  METHOD given_text_first_then_raises.
    lth_failure=>assert_build_fails( builder = zcl_xml=>builder( )->text( `loose` )->element( `a` )
                                     msg     = 'Text before the first element must be rejected' ).
  ENDMETHOD.

  METHOD given_second_root_then_raises.
    lth_failure=>assert_build_fails( builder = zcl_xml=>builder( )->element( `a` )->close( )->element( `b` )
                                     msg     = 'A second root element must be rejected' ).
  ENDMETHOD.

  METHOD given_extra_close_then_raises.
    lth_failure=>assert_build_fails( builder = zcl_xml=>builder( )->element( `a` )->close( )->close( )
                                     msg     = 'A close( ) without an open element must be rejected' ).
  ENDMETHOD.

  METHOD given_twice_attr_then_raises.
    lth_failure=>assert_build_fails( builder = zcl_xml=>builder( )->element( `a`
                                                               )->attribute( name  = `k`
                                                                             value = `1`
                                                               )->attribute( name  = `k`
                                                                             value = `2` )
                                     msg     = 'An attribute set twice on one element must be rejected' ).
  ENDMETHOD.

  METHOD given_space_in_name_raises.
    lth_failure=>assert_build_fails( builder = zcl_xml=>builder( )->element( `my element` )
                                     msg     = 'An element name with a space must be rejected' ).
  ENDMETHOD.

  METHOD given_digit_first_then_raises.
    lth_failure=>assert_build_fails( builder = zcl_xml=>builder( )->element( `1st` )
                                     msg     = 'An element name starting with a digit must be rejected' ).
  ENDMETHOD.

  METHOD given_colon_in_name_raises.
    lth_failure=>assert_build_fails( builder = zcl_xml=>builder( )->element( `s:Envelope` )
                                     msg     = 'A prefix inside the name must be rejected, it is passed separately' ).
  ENDMETHOD.

  METHOD given_prefix_no_ns_then_raises.
    lth_failure=>assert_build_fails( builder = zcl_xml=>builder( )->element( name   = `Envelope`
                                                                             prefix = `s` )
                                     msg     = 'A prefix without a namespace URI must be rejected' ).
  ENDMETHOD.

  METHOD given_errors_then_first_wins.
    TRY.
        zcl_xml=>builder( )->close( )->element( `a` )->attribute( name  = `k`
                                                                  value = `1`
                                                     )->attribute( name  = `k`
                                                                   value = `2` )->build( ).
        cl_abap_unit_assert=>fail( 'A chain with mistakes must not build' ).
      CATCH zcx_xml INTO DATA(error).
        cl_abap_unit_assert=>assert_true( act = xsdbool( contains( val = error->get_text( )
                                                                   sub = `close( )` ) )
                                          msg = 'The first mistake in the chain must be the one reported' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
