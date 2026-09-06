"! <p class="shorttext synchronized" lang="EN">XML element</p>
"! Read access to one element of an XML document: its name, attributes, text
"! and child elements. Names are local names - a namespace prefix such as
"! soap: is never part of them; the namespace URI is available separately.
"! Elements are obtained from {@link zif_xml_document.METH:root} and
"! navigated from there, they are never created directly.
INTERFACE zif_xml_node
  PUBLIC.

  "! One attribute. Namespace and prefix are filled only for a prefixed
  "! attribute such as xsi:nil, whose name is then the local name nil.
  TYPES: BEGIN OF attribute_pair,
           name      TYPE string,
           value     TYPE string,
           namespace TYPE string,
           prefix    TYPE string,
         END OF attribute_pair.
  "! Attributes in document order.
  TYPES attribute_pairs TYPE STANDARD TABLE OF attribute_pair WITH EMPTY KEY.
  "! Elements in document order.
  TYPES nodes TYPE STANDARD TABLE OF REF TO zif_xml_node WITH EMPTY KEY.

  "! Local name of the element, without a namespace prefix.
  "! @parameter result | Element name
  METHODS name
    RETURNING VALUE(result) TYPE string.

  "! Namespace URI of the element; empty when the element is in no namespace.
  "! @parameter result | Namespace URI
  METHODS namespace
    RETURNING VALUE(result) TYPE string.

  "! Namespace prefix the element is written with; empty for the default
  "! namespace and for an element in no namespace.
  "! @parameter result | Namespace prefix
  METHODS prefix
    RETURNING VALUE(result) TYPE string.

  "! Text directly inside the element, concatenated in document order. Text
  "! of child elements is not included; entities are already decoded.
  "! @parameter result | Text content, empty for an element without text
  METHODS text
    RETURNING VALUE(result) TYPE string.

  "! Value of one attribute.
  "! @parameter name   | Attribute name
  "! @parameter result | Attribute value, empty when the attribute is missing
  METHODS attribute
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE string.

  "! Whether the element carries the attribute.
  "! @parameter name   | Attribute name
  "! @parameter result | abap_true when the attribute is present
  METHODS has_attribute
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE abap_bool.

  "! All attributes in document order.
  "! @parameter result | Attributes, empty for an element without attributes
  METHODS attributes
    RETURNING VALUE(result) TYPE attribute_pairs.

  "! Direct child elements in document order.
  "! @parameter result | Child elements, empty for a leaf element
  METHODS children
    RETURNING VALUE(result) TYPE nodes.

  "! Direct child elements with the given name, in document order.
  "! @parameter name   | Element name
  "! @parameter result | Matching child elements, empty when there are none
  METHODS children_named
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE nodes.

  "! Whether at least one direct child element has the given name.
  "! @parameter name   | Element name
  "! @parameter result | abap_true when such a child exists
  METHODS has_child
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE abap_bool.

  "! First direct child element with the given name.
  "! @parameter name    | Element name
  "! @parameter result  | The child element
  "! @raising   zcx_xml | No such child
  METHODS child
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE REF TO zif_xml_node
    RAISING   zcx_xml.

  "! Text of the first direct child element with the given name - the
  "! shorthand for child( )->text( ) when the child is optional.
  "! @parameter name   | Element name
  "! @parameter result | Text of the child, empty when there is no such child
  METHODS child_text
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE string.

  "! Element reached by walking a path of child element names separated by
  "! slashes, for example header/buyer/id. Every step takes the first child
  "! with that name; empty path segments are ignored.
  "! @parameter path    | Slash-separated element names, relative to this element
  "! @parameter result  | The element at the end of the path
  "! @raising   zcx_xml | A path segment does not resolve
  METHODS descendant
    IMPORTING path          TYPE string
    RETURNING VALUE(result) TYPE REF TO zif_xml_node
    RAISING   zcx_xml.

ENDINTERFACE.
