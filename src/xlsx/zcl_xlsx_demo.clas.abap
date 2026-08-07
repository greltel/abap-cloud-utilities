"! <p class="shorttext synchronized" lang="EN">XLSX utility demo</p>
"! Round-trip smoke test for {@link zcl_xlsx}: builds a workbook in memory and
"! reads it back. Run with F9 in ADT.
CLASS zcl_xlsx_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    " Strongly typed - the header row is generated from the component names,
    " so dates and amounts keep their type instead of becoming text.
    TYPES: BEGIN OF employee,
             id         TYPE n LENGTH 5,
             name       TYPE string,
             department TYPE string,
             hired_on   TYPE d,
             salary     TYPE p LENGTH 9 DECIMALS 2,
           END OF employee.
    TYPES employees TYPE STANDARD TABLE OF employee WITH EMPTY KEY.

    TYPES: BEGIN OF department_total,
             department TYPE string,
             headcount  TYPE i,
             total      TYPE p LENGTH 11 DECIMALS 2,
           END OF department_total.
    TYPES department_totals TYPE STANDARD TABLE OF department_total WITH EMPTY KEY.

    CONSTANTS employees_sheet TYPE string       VALUE `Employees`.
    CONSTANTS totals_sheet    TYPE string       VALUE `Totals`.
    CONSTANTS header_row      TYPE i            VALUE 1.
    CONSTANTS first_data_row  TYPE i            VALUE 2.
    "! Set to abap_true to dump the generated file as Base64 to the console.
    CONSTANTS dump_base64     TYPE abap_bool    VALUE abap_false.

    METHODS sample_employees
      RETURNING VALUE(result) TYPE employees.

    METHODS totals_of
      IMPORTING staff         TYPE employees
      RETURNING VALUE(result) TYPE department_totals.

    METHODS build_file
      IMPORTING out           TYPE REF TO if_oo_adt_classrun_out
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_xlsx.

    METHODS show_metadata
      IMPORTING reader TYPE REF TO zif_xlsx_reader
                out    TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_xlsx.

    METHODS show_data
      IMPORTING reader TYPE REF TO zif_xlsx_reader
                out    TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_xlsx.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

ENDCLASS.


CLASS zcl_xlsx_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(reader) = zcl_xlsx=>for_file_content( build_file( out ) ).

        show_metadata( reader = reader
                       out    = out ).

        show_data( reader = reader
                   out    = out ).

        show_rejected_input( out ).

        out->write( `Round trip completed` ).

      CATCH zcx_xlsx INTO DATA(error).
        out->write( |FAILED: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD sample_employees.
    result = VALUE #(
      ( id = '10001' name = `Alkinoos` department = `Logistics` hired_on = '20230411' salary = '2850.00' )
      ( id = '10002' name = `Rania`    department = `Finance`   hired_on = '20240902' salary = '3410.50' )
      ( id = '10003' name = `Petros`   department = `Logistics` hired_on = '20250120' salary = '2640.75' )
      ( id = '10004' name = `Despoina` department = `Finance`   hired_on = '20260302' salary = '3120.00' ) ).
  ENDMETHOD.

  METHOD totals_of.

    LOOP AT staff INTO DATA(person)
         GROUP BY ( department = person-department )
         INTO DATA(unit).

      DATA(line) = VALUE department_total( department = unit-department ).

      LOOP AT GROUP unit INTO DATA(member).
        line-headcount += 1.
        line-total     += member-salary.
      ENDLOOP.

      INSERT line INTO TABLE result.
    ENDLOOP.

  ENDMETHOD.

  METHOD build_file.
    DATA(staff)  = sample_employees( ).
    DATA(totals) = totals_of( staff ).

    result = zcl_xlsx=>empty(
                     )->add_sheet_from_structure( sheet_name = employees_sheet
                                                  rows       = staff
                     )->add_sheet_from_structure(
                          sheet_name = totals_sheet
                          rows       = totals
                          labels     = VALUE zif_xlsx_writer=>column_labels(
                                         ( `Department` ) ( `Headcount` ) ( `Total salary` ) )
                     )->get_file_content( ).

    out->write( |Wrote { lines( staff ) } employees and { lines( totals ) } totals| ).
    out->write( |Generated file size: { xstrlen( result ) } bytes| ).

    IF dump_base64 = abap_true.
      out->write( xco_cp=>xstring( result
                            )->as_string( xco_cp_binary=>text_encoding->base64
                            )->value ).
    ENDIF.
  ENDMETHOD.

  METHOD show_metadata.
    out->write( |Workbook contains { reader->count_sheets( ) } worksheet(s)| ).

    DATA(found) = COND string( WHEN reader->has_sheet( employees_sheet ) = abap_true
                               THEN `yes`
                               ELSE `no` ).
    out->write( |Sheet { employees_sheet } present: { found }| ).
  ENDMETHOD.

  METHOD show_data.
    " Row 1 holds the generated header, so a typed table starts at row 2.
    DATA staff TYPE employees.
    reader->read_sheet( EXPORTING sheet_name = employees_sheet
                                  from_row   = first_data_row
                        IMPORTING rows       = staff ).

    out->write( |Read { lines( staff ) } employees from sheet { employees_sheet }| ).
    out->write( staff ).

    " The generated header itself, read into an all-string structure.
    TYPES: BEGIN OF header_line,
             c1 TYPE string,
             c2 TYPE string,
             c3 TYPE string,
             c4 TYPE string,
             c5 TYPE string,
           END OF header_line.
    TYPES header_lines TYPE STANDARD TABLE OF header_line WITH EMPTY KEY.

    DATA headers TYPE header_lines.
    reader->read_sheet( EXPORTING sheet_name = employees_sheet
                        IMPORTING rows       = headers ).

    DATA(labels) = headers[ header_row ].
    out->write( |Generated header: { labels-c1 } / { labels-c2 } / { labels-c3 }| &&
                | / { labels-c4 } / { labels-c5 }| ).

    DATA totals TYPE department_totals.
    reader->read_sheet_at_position( EXPORTING position = 2
                                              from_row = first_data_row
                                    IMPORTING rows     = totals ).

    out->write( |Read { lines( totals ) } totals from position 2| ).
    out->write( totals ).

    " Proof that the date survived as a real date and not as text.
    DATA(first_hire) = staff[ 1 ]-hired_on.
    out->write( |First hire date as ABAP date: { first_hire DATE = ISO }| ).
  ENDMETHOD.

  METHOD show_rejected_input.
    TYPES: BEGIN OF unsupported,
             reference TYPE string,
             amount    TYPE decfloat34,
           END OF unsupported.
    TYPES unsupported_rows TYPE STANDARD TABLE OF unsupported WITH EMPTY KEY.

    TRY.
        zcl_xlsx=>empty( )->add_sheet_from_structure(
          sheet_name = `Unsupported`
          rows       = VALUE unsupported_rows( ( reference = `X-1` amount = '1.5' ) ) ).

        out->write( `WARNING: a decfloat column was accepted, it would contain zeros` ).

      CATCH zcx_xlsx INTO DATA(error).
        out->write( |Rejected as expected: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
