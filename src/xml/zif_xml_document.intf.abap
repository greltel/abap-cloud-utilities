"! <p class="shorttext synchronized" lang="EN">XML document</p>
"! An XML document as an element tree: the result of parsing with
"! {@link zcl_xml.METH:parse} or of building with {@link zif_xml_builder}.
"! Serializes back to XML 1.0 in UTF-8 without an XML declaration, which the
"! sXML writer does not emit and XML does not require for UTF-8; texts and
"! attribute values are escaped, namespaces are declared where they are used.
INTERFACE zif_xml_document
  PUBLIC.

  "! Root element of the document.
  "! @parameter result | Root element
  METHODS root
    RETURNING VALUE(result) TYPE REF TO zif_xml_node.

  "! The document as compact text, without line breaks between elements.
  "! @parameter result  | XML text, without an XML declaration
  "! @raising   zcx_xml | The document cannot be written
  METHODS to_string
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_xml.

  "! The document as readable text: every element on its own line, indented
  "! by depth. Meant for logs and people rather than for other systems.
  "! @parameter result  | XML text, without an XML declaration
  "! @raising   zcx_xml | The document cannot be written
  METHODS to_indented_string
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_xml.

  "! The document as compact UTF-8 bytes, for example for an HTTP body.
  "! @parameter result  | XML bytes, without an XML declaration
  "! @raising   zcx_xml | The document cannot be written
  METHODS to_xstring
    RETURNING VALUE(result) TYPE xstring
    RAISING   zcx_xml.

  "! The document as readable UTF-8 bytes, for example for a file.
  "! @parameter result  | XML bytes, without an XML declaration
  "! @raising   zcx_xml | The document cannot be written
  METHODS to_indented_xstring
    RETURNING VALUE(result) TYPE xstring
    RAISING   zcx_xml.

ENDINTERFACE.
