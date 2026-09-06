"! <p class="shorttext synchronized" lang="EN">XML utility</p>
"! Entry point for reading and writing XML documents on top of the released
"! sXML string reader and writer. A parsed document is an element tree that
"! is navigated by element name; a new document is built with a fluent
"! builder. Comments and processing instructions are not represented, and
"! whitespace that only separates elements is dropped when reading.
CLASS zcl_xml DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Parses an XML document given as text.
    "! @parameter xml     | Complete XML document; an encoding declaration in it must be absent or UTF-8
    "! @parameter result  | The parsed document
    "! @raising   zcx_xml | The text is not well-formed XML
    CLASS-METHODS parse
      IMPORTING xml           TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_xml_document
      RAISING   zcx_xml.

    "! Parses an XML document given as bytes, for example an HTTP body. The
    "! encoding is taken from the XML declaration, UTF-8 when there is none.
    "! @parameter xml     | Complete XML document
    "! @parameter result  | The parsed document
    "! @raising   zcx_xml | The bytes are not well-formed XML
    CLASS-METHODS parse_xstring
      IMPORTING xml           TYPE xstring
      RETURNING VALUE(result) TYPE REF TO zif_xml_document
      RAISING   zcx_xml.

    "! Starts a new document that is built element by element.
    "! @parameter result | Builder positioned before the root element
    CLASS-METHODS builder
      RETURNING VALUE(result) TYPE REF TO zif_xml_builder.

ENDCLASS.


CLASS zcl_xml IMPLEMENTATION.

  METHOD parse.
    RETURN parse_xstring( lcl_codepage=>to_utf8( xml ) ).
  ENDMETHOD.

  METHOD parse_xstring.
    RETURN NEW lcl_document( NEW lcl_reader( )->parse( xml ) ).
  ENDMETHOD.

  METHOD builder.
    RETURN NEW lcl_builder( ).
  ENDMETHOD.

ENDCLASS.
