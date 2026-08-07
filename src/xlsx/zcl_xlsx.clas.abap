"! <p class="shorttext synchronized" lang="EN">XLSX utility</p>
"! Entry point for reading and writing .xlsx documents on top of the released
"! XCO XLSX APIs. Standalone - depends on nothing but SAP released APIs.
CLASS zcl_xlsx DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Opens an existing .xlsx file content for reading.
    "! @parameter file_content | Complete binary content of the .xlsx file
    "! @parameter result       | Read access to the document
    "! @raising   zcx_xlsx     | The content is not a readable .xlsx document
    CLASS-METHODS for_file_content
      IMPORTING file_content  TYPE xstring
      RETURNING VALUE(result) TYPE REF TO zif_xlsx_reader
      RAISING   zcx_xlsx.

    "! Creates a new, empty workbook for writing.
    "! @parameter result   | Write access to the new document
    "! @raising   zcx_xlsx | The document could not be created
    CLASS-METHODS empty
      RETURNING VALUE(result) TYPE REF TO zif_xlsx_writer
      RAISING   zcx_xlsx.

ENDCLASS.


CLASS zcl_xlsx IMPLEMENTATION.

  METHOD for_file_content.
    RETURN NEW lcl_reader( file_content ).
  ENDMETHOD.

  METHOD empty.
    RETURN NEW lcl_writer( ).
  ENDMETHOD.

ENDCLASS.
