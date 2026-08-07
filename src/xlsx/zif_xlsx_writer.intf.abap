"! <p class="shorttext synchronized" lang="EN">XLSX write access</p>
"! Builds a new .xlsx document in memory.
INTERFACE zif_xlsx_writer
  PUBLIC.

  "! Maximum length Excel accepts for a worksheet name.
  CONSTANTS max_sheet_name_length TYPE i VALUE 31.

  "! Column labels for a generated header row.
  TYPES column_labels TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  "! Adds a worksheet and fills it with the rows of the given table, starting at
  "! cell A1. A header row must be the first row of the table.
  "! @parameter sheet_name | Name of the worksheet
  "! @parameter rows       | Source table; components must be flat and elementary
  "! @parameter self       | Same instance, for chaining
  "! @raising   zcx_xlsx   | Name is not accepted or the worksheet could not be written
  METHODS add_sheet
    IMPORTING sheet_name  TYPE string
              rows        TYPE STANDARD TABLE
    RETURNING VALUE(self) TYPE REF TO zif_xlsx_writer
    RAISING   zcx_xlsx.

  "! Complete .xlsx file content, ready to be downloaded or attached to a mail.
  "! @parameter result   | Binary content of the .xlsx file
  "! @raising   zcx_xlsx | The file content could not be generated
  METHODS get_file_content
    RETURNING VALUE(result) TYPE xstring
    RAISING   zcx_xlsx.

  "! Adds a worksheet with a generated header row in row 1 and the rows of the
  "! given table from row 2 onwards. Unlike {@link zif_xlsx_writer.METH:add_sheet}
  "! the table may be strongly typed - dates, times and numbers keep their type
  "! in the worksheet.
  "! <p><strong>Decimal columns must be typed P with DECIMALS.</strong> Fields
  "! typed DECFLOAT16 or DECFLOAT34 are rejected, because the underlying write
  "! value transformation writes zeros for them in this release.</p>
  "! @parameter sheet_name | Name of the worksheet
  "! @parameter rows       | Source table; its line type must be a structure of elementary fields
  "! @parameter labels     | Column labels; when empty, the component names are used
  "! @parameter self       | Same instance, for chaining
  "! @raising   zcx_xlsx   | Line type unsupported, label count wrong, or write failed
  METHODS add_sheet_from_structure
    IMPORTING sheet_name  TYPE string
              rows        TYPE STANDARD TABLE
              labels      TYPE column_labels OPTIONAL
    RETURNING VALUE(self) TYPE REF TO zif_xlsx_writer
    RAISING   zcx_xlsx.

ENDINTERFACE.
