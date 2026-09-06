"! <p class="shorttext synchronized" lang="EN">CSV utility</p>
"! Entry point for reading and writing CSV documents (RFC 4180) from and to
"! internal tables. Pure ABAP - depends on nothing but the language and RTTI.
CLASS zcl_csv DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Opens a CSV document for reading. Nothing is parsed until one of the
    "! read methods is called, so the dialect can be configured first.
    "! @parameter text   | Complete CSV document
    "! @parameter result | Read access to the document
    CLASS-METHODS for_string
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_csv_reader.

    "! Opens an internal table for writing. Every row becomes one record and
    "! every component one field, formatted like in a string template: numbers
    "! with a leading sign and a decimal point, dates as YYYYMMDD, times as
    "! HHMMSS. The header row is made of the component names.
    "! @parameter rows    | Source table; its line type must be a structure of elementary components
    "! @parameter result  | Write access to the document
    "! @raising   zcx_csv | The line type is not supported
    CLASS-METHODS for_table
      IMPORTING rows          TYPE STANDARD TABLE
      RETURNING VALUE(result) TYPE REF TO zif_csv_writer
      RAISING   zcx_csv.

    "! Opens ready-made records for writing, for example the result of
    "! {@link zif_csv_reader.METH:read_records}. Records may differ in their
    "! field count and are written as they are.
    "! @parameter records | Records in the order they are to be written
    "! @parameter result  | Write access to the document
    CLASS-METHODS for_records
      IMPORTING records       TYPE zif_csv_reader=>records
      RETURNING VALUE(result) TYPE REF TO zif_csv_writer.

ENDCLASS.


CLASS zcl_csv IMPLEMENTATION.

  METHOD for_string.
    RETURN NEW lcl_reader( text ).
  ENDMETHOD.

  METHOD for_table.
    DATA(row_type) = lcl_row_type=>of_table( rows ).

    RETURN NEW lcl_writer( records = row_type->to_records( rows )
                           header  = row_type->component_names( ) ).
  ENDMETHOD.

  METHOD for_records.
    RETURN NEW lcl_writer( records = records ).
  ENDMETHOD.

ENDCLASS.
