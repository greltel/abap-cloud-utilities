"! <p class="shorttext synchronized" lang="EN">XML utility demo</p>
"! Smoke test for {@link zcl_xml}: builds a document, writes it compact and
"! indented, parses it back and navigates it by name and by path, reads and
"! rewrites a namespaced document and shows rejected input. Run with F9 in ADT.
CLASS zcl_xml_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    METHODS sample_order
      RETURNING VALUE(result) TYPE REF TO zif_xml_document
      RAISING   zcx_xml.

    METHODS show_writing
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_xml.

    METHODS show_reading
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_xml.

    METHODS show_namespaces
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_xml.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

ENDCLASS.


CLASS zcl_xml_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_writing( out ).
        show_reading( out ).
        show_namespaces( out ).
        show_rejected_input( out ).
      CATCH zcx_xml INTO DATA(error).
        out->write( |XML demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD sample_order.
    result = zcl_xml=>builder( )->element( `order`
                              )->attribute( name  = `id`
                                            value = `4711`
                              )->attribute( name  = `currency`
                                            value = `EUR`
                              )->leaf( name  = `customer`
                                       value = `Smith & Sons <Ltd>`
                              )->element( `items`
                              )->element( `item`
                              )->attribute( name  = `sku`
                                            value = `K-1`
                              )->leaf( name  = `name`
                                       value = `Keyboard`
                              )->leaf( name  = `quantity`
                                       value = `2`
                              )->close(
                              )->element( `item`
                              )->attribute( name  = `sku`
                                            value = `M-2`
                              )->leaf( name  = `name`
                                       value = `Mouse`
                              )->leaf( name  = `quantity`
                                       value = `1`
                              )->build( ).
  ENDMETHOD.

  METHOD show_writing.
    DATA(order) = sample_order( ).

    out->write( `Compact - special characters are escaped, open elements closed:` ).
    out->write( order->to_string( ) ).

    out->write( `Indented:` ).
    out->write( order->to_indented_string( ) ).
  ENDMETHOD.

  METHOD show_reading.
    DATA(order) = zcl_xml=>parse( sample_order( )->to_string( ) )->root( ).

    out->write( |Order { order->attribute( `id` ) } in { order->attribute( `currency` ) } | &&
                |for { order->child_text( `customer` ) }:| ).

    DATA(items) = order->child( `items` )->children_named( `item` ).
    LOOP AT items INTO DATA(item).
      out->write( |  { item->attribute( `sku` ) }: { item->child_text( `quantity` ) } x | &&
                  |{ item->child_text( `name` ) }| ).
    ENDLOOP.

    out->write( |First item by path items/item/name: { order->descendant( `items/item/name` )->text( ) }| ).
  ENDMETHOD.

  METHOD show_namespaces.
    DATA(envelope) = `<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>` &&
                     `<GetPrice xmlns="urn:shop"><sku>K-1</sku></GetPrice></soap:Body></soap:Envelope>`.

    DATA(root) = zcl_xml=>parse( envelope )->root( ).
    DATA(request) = root->descendant( `Body/GetPrice` ).

    out->write( |Root { root->name( ) } (prefix { root->prefix( ) }) in namespace { root->namespace( ) }| ).
    out->write( |Request { request->name( ) } in namespace { request->namespace( ) } | &&
                |for sku { request->child_text( `sku` ) }| ).

    out->write( `Built with namespaces - declared where they are first used:` ).
    out->write( zcl_xml=>builder( )->element( name      = `Envelope`
                                              namespace = `http://schemas.xmlsoap.org/soap/envelope/`
                                              prefix    = `soap`
                                 )->element( name      = `Body`
                                             namespace = `http://schemas.xmlsoap.org/soap/envelope/`
                                             prefix    = `soap`
                                 )->element( name      = `GetPriceResponse`
                                             namespace = `urn:shop`
                                 )->leaf( name  = `price`
                                          value = `49.90`
                                 )->build( )->to_string( ) ).
  ENDMETHOD.

  METHOD show_rejected_input.
    TRY.
        zcl_xml=>parse( `<order><item>Pen</order>` ).
        out->write( `A mismatched end tag was unexpectedly accepted` ).
      CATCH zcx_xml INTO DATA(parse_error).
        out->write( |Rejected as expected: { parse_error->get_text( ) }| ).
    ENDTRY.

    TRY.
        zcl_xml=>builder( )->attribute( name  = `id`
                                        value = `1` )->build( ).
        out->write( `An attribute without an element was unexpectedly accepted` ).
      CATCH zcx_xml INTO DATA(build_error).
        out->write( |Rejected as expected: { build_error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
