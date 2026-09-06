"! <p class="shorttext synchronized" lang="EN">XML builder</p>
"! Builds an XML document element by element, in writing order. An element
"! opened with {@link zif_xml_builder.METH:element} is the current element
"! until {@link zif_xml_builder.METH:close}; elements still open at
"! {@link zif_xml_builder.METH:build} are closed implicitly. Texts and
"! attribute values are escaped when the document is written, so they may
"! contain any character. A mistake in the chain - an attribute before the
"! first element, a second root, a duplicate attribute, an invalid name - is
"! remembered and reported by build( ), which keeps the chain itself free of
"! exceptions.
INTERFACE zif_xml_builder
  PUBLIC.

  "! Opens a child element of the current element, or the root element when
  "! nothing is open yet. It becomes the current element.
  "! @parameter name      | Element name; a namespace prefix is passed separately, not as part of the name
  "! @parameter namespace | Namespace URI; declared on this element unless an outer element declared it
  "! @parameter prefix    | Prefix for the namespace URI; empty makes it the default namespace
  "! @parameter self      | Same instance, for chaining
  METHODS element
    IMPORTING name        TYPE string
              namespace   TYPE string OPTIONAL
              prefix      TYPE string OPTIONAL
    RETURNING VALUE(self) TYPE REF TO zif_xml_builder.

  "! Adds an attribute to the current element.
  "! @parameter name  | Attribute name, unique within the element
  "! @parameter value | Attribute value, unescaped
  "! @parameter self  | Same instance, for chaining
  METHODS attribute
    IMPORTING name        TYPE string
              value       TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_xml_builder.

  "! Adds text to the current element, after the content added so far.
  "! @parameter value | Text, unescaped
  "! @parameter self  | Same instance, for chaining
  METHODS text
    IMPORTING value       TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_xml_builder.

  "! Adds a child element that holds only the given text and closes it at
  "! once - the shorthand for element( )->text( )->close( ).
  "! @parameter name  | Element name
  "! @parameter value | Text, unescaped
  "! @parameter self  | Same instance, for chaining
  METHODS leaf
    IMPORTING name        TYPE string
              value       TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_xml_builder.

  "! Closes the current element; its parent becomes the current element.
  "! @parameter self | Same instance, for chaining
  METHODS close
    RETURNING VALUE(self) TYPE REF TO zif_xml_builder.

  "! Finishes the document.
  "! @parameter result  | Document holding the built element tree
  "! @raising   zcx_xml | No element was added, or a call in the chain was invalid
  METHODS build
    RETURNING VALUE(result) TYPE REF TO zif_xml_document
    RAISING   zcx_xml.

ENDINTERFACE.
