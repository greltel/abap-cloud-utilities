"! <p class="shorttext synchronized" lang="EN">JSON utility</p>
"! Entry point for converting between JSON strings and ABAP data on top of the
"! released XCO JSON APIs. Standalone - depends on nothing but SAP released APIs.
CLASS zcl_json DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Opens a JSON string for reading into ABAP data.
    "! @parameter json     | JSON document as a string
    "! @parameter result   | Read access to the document
    "! @raising   zcx_json | The string could not be opened as a JSON document
    CLASS-METHODS for_string
      IMPORTING json          TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_json_reader
      RAISING   zcx_json.

    "! Opens an ABAP data object for writing into a JSON string.
    "! @parameter data     | Source data object; structures, internal tables and
    "!                       elementary types are supported, reference components are not
    "! @parameter result   | Write access to the document
    "! @raising   zcx_json | The data object cannot be represented as JSON
    CLASS-METHODS for_data
      IMPORTING data          TYPE data
      RETURNING VALUE(result) TYPE REF TO zif_json_writer
      RAISING   zcx_json.

ENDCLASS.


CLASS zcl_json IMPLEMENTATION.

  METHOD for_string.
    RETURN NEW lcl_reader( json ).
  ENDMETHOD.

  METHOD for_data.
    RETURN NEW lcl_writer( data ).
  ENDMETHOD.

ENDCLASS.
