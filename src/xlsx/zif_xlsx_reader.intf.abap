"! <p class="shorttext synchronized" lang="EN">XLSX read access</p>
"! Read access to the worksheets of an .xlsx document.
INTERFACE zif_xlsx_reader
  PUBLIC.

  "! Position of the leftmost worksheet in a workbook.
  CONSTANTS first_sheet TYPE i VALUE 1.
  "! Topmost row of a worksheet.
  CONSTANTS first_row   TYPE i VALUE 1.

  "! Number of worksheets in the workbook.
  "! @parameter result   | Worksheet count
  "! @raising   zcx_xlsx | The workbook could not be read
  METHODS count_sheets
    RETURNING VALUE(result) TYPE i
    RAISING   zcx_xlsx.

  "! Tells whether a worksheet with the given name exists.
  "! @parameter sheet_name | Worksheet name as shown in Excel
  "! @parameter result     | abap_true if the worksheet exists
  "! @raising   zcx_xlsx   | The workbook could not be read
  METHODS has_sheet
    IMPORTING sheet_name    TYPE string
    RETURNING VALUE(result) TYPE abap_bool
    RAISING   zcx_xlsx.

  "! Reads a worksheet into an internal table, one table row per worksheet row.
  "! Column n of the worksheet is written to component n of the row structure,
  "! starting at column A.
  "! @parameter sheet_name | Worksheet name as shown in Excel
  "! @parameter from_row   | First worksheet row to read; pass 2 to skip a header row
  "! @parameter rows       | Receiving table; components must be flat and elementary
  "! @raising   zcx_xlsx   | Worksheet is missing or its content could not be read
  METHODS read_sheet
    IMPORTING sheet_name TYPE string
              from_row   TYPE i DEFAULT first_row
    EXPORTING rows       TYPE STANDARD TABLE
    RAISING   zcx_xlsx.

  "! Reads the worksheet at the given position, 1 being the leftmost one.
  "! @parameter position | Position of the worksheet in the workbook
  "! @parameter from_row | First worksheet row to read; pass 2 to skip a header row
  "! @parameter rows     | Receiving table; components must be flat and elementary
  "! @raising   zcx_xlsx | Position is empty or its content could not be read
  METHODS read_sheet_at_position
    IMPORTING position TYPE i DEFAULT first_sheet
              from_row TYPE i DEFAULT first_row
    EXPORTING rows     TYPE STANDARD TABLE
    RAISING   zcx_xlsx.

ENDINTERFACE.
