*"* use this source file for your ABAP unit test classes
CLASS ltc_writer_validation DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    TYPES: BEGIN OF decfloat_row,
             reference TYPE string,
             amount    TYPE decfloat34,
           END OF decfloat_row.
    TYPES decfloat_rows TYPE STANDARD TABLE OF decfloat_row WITH EMPTY KEY.

    TYPES: BEGIN OF flat_row,
             id   TYPE string,
             name TYPE string,
             city TYPE string,
           END OF flat_row.
    TYPES flat_rows TYPE STANDARD TABLE OF flat_row WITH EMPTY KEY.

    TYPES: BEGIN OF address,
             street TYPE string,
           END OF address.
    TYPES: BEGIN OF nested_row,
             id      TYPE string,
             located TYPE address,
           END OF nested_row.
    TYPES nested_rows TYPE STANDARD TABLE OF nested_row WITH EMPTY KEY.

    TYPES texts       TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! Exactly 31 characters - the longest name Excel accepts.
    CONSTANTS longest_name  TYPE string VALUE `1234567890123456789012345678901`.
    "! One character beyond the limit.
    CONSTANTS too_long_name TYPE string VALUE `12345678901234567890123456789012`.

    DATA cut TYPE REF TO zif_xlsx_writer.

    METHODS setup                         RAISING cx_static_check.
    METHODS teardown.

    METHODS given_empty_name_then_raises  FOR TESTING.
    METHODS given_long_name_then_raises   FOR TESTING.
    METHODS given_max_name_then_accepted  FOR TESTING RAISING cx_static_check.
    METHODS given_nested_row_then_raises  FOR TESTING.
    METHODS given_elem_line_then_raises   FOR TESTING.
    METHODS given_label_count_then_raises FOR TESTING.
    METHODS given_decfloat_then_raises    FOR TESTING.

ENDCLASS.


CLASS ltc_writer_validation IMPLEMENTATION.

  METHOD setup.
    cut = zcl_xlsx=>empty( ).
  ENDMETHOD.

  METHOD teardown.
    CLEAR cut.
  ENDMETHOD.

  METHOD given_empty_name_then_raises.
    TRY.
        cut->add_sheet( sheet_name = ``
                        rows       = VALUE flat_rows( ( id = `1` name = `A` city = `B` ) ) ).

        cl_abap_unit_assert=>fail( 'An empty worksheet name was accepted' ).
      CATCH zcx_xlsx.
    ENDTRY.
  ENDMETHOD.

  METHOD given_long_name_then_raises.
    TRY.
        cut->add_sheet( sheet_name = too_long_name
                        rows       = VALUE flat_rows( ( id = `1` name = `A` city = `B` ) ) ).

        cl_abap_unit_assert=>fail( 'A worksheet name longer than 31 characters was accepted' ).
      CATCH zcx_xlsx.
    ENDTRY.
  ENDMETHOD.

  METHOD given_max_name_then_accepted.
    cut->add_sheet_from_structure( sheet_name = longest_name
                                   rows       = VALUE flat_rows( ( id = `1` name = `A` city = `B` ) ) ).

    DATA(reader) = zcl_xlsx=>for_file_content( cut->get_file_content( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = reader->has_sheet( longest_name )
      exp = abap_true
      msg = 'A worksheet name of exactly the maximum length was rejected' ).
  ENDMETHOD.

  METHOD given_nested_row_then_raises.
    TRY.
        cut->add_sheet_from_structure( sheet_name = `Nested`
                                       rows       = VALUE nested_rows( ( id = `1` ) ) ).

        cl_abap_unit_assert=>fail( 'A structured component was accepted as a worksheet column' ).
      CATCH zcx_xlsx.
    ENDTRY.
  ENDMETHOD.

  METHOD given_elem_line_then_raises.
    TRY.
        cut->add_sheet_from_structure( sheet_name = `Texts`
                                       rows       = VALUE texts( ( `a` ) ( `b` ) ) ).

        cl_abap_unit_assert=>fail( 'A table with an elementary line type was accepted' ).
      CATCH zcx_xlsx.
    ENDTRY.
  ENDMETHOD.

  METHOD given_label_count_then_raises.
    TRY.
        cut->add_sheet_from_structure(
          sheet_name = `Labels`
          rows       = VALUE flat_rows( ( id = `1` name = `A` city = `B` ) )
          labels     = VALUE zif_xlsx_writer=>column_labels( ( `One` ) ( `Two` ) ) ).

        cl_abap_unit_assert=>fail( 'Two labels were accepted for a three column structure' ).
      CATCH zcx_xlsx.
    ENDTRY.
  ENDMETHOD.

  METHOD given_decfloat_then_raises.
    TRY.
        cut->add_sheet_from_structure( sheet_name = `Amounts`
                                       rows       = VALUE decfloat_rows( ( reference = `B-1` amount = '1.5' ) ) ).

        cl_abap_unit_assert=>fail('A decfloat column was accepted although it would be written as zero' ).
      CATCH zcx_xlsx.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_reader_validation DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    TYPES: BEGIN OF record,
             id   TYPE string,
             name TYPE string,
           END OF record.
    TYPES records TYPE STANDARD TABLE OF record WITH EMPTY KEY.

    CONSTANTS sheet          TYPE string VALUE `Data`.
    CONSTANTS invalid_row    TYPE i      VALUE 0.
    CONSTANTS beyond_last    TYPE i      VALUE 9.

    DATA cut TYPE REF TO zif_xlsx_reader.

    METHODS setup    RAISING cx_static_check.
    METHODS teardown.

    METHODS given_garbage_then_raises      FOR TESTING.
    METHODS given_unknown_sheet_then_raise FOR TESTING.
    METHODS given_row_zero_then_raises     FOR TESTING.
    METHODS given_position_zero_then_raise FOR TESTING.
    METHODS given_beyond_last_then_raises  FOR TESTING.

ENDCLASS.


CLASS ltc_reader_validation IMPLEMENTATION.

  METHOD setup.
    DATA(content) = zcl_xlsx=>empty(
                            )->add_sheet_from_structure( sheet_name = sheet
                                                         rows       = VALUE records( ( id = `1` name = `A` ) )
                            )->get_file_content( ).

    cut = zcl_xlsx=>for_file_content( content ).
  ENDMETHOD.

  METHOD teardown.
    CLEAR cut.
  ENDMETHOD.

  METHOD given_garbage_then_raises.
    " Not a ZIP container, so it cannot be an .xlsx document.
    DATA garbage TYPE xstring.
    garbage = 'FFFEFDFC'.

    TRY.
        zcl_xlsx=>for_file_content( garbage ).

        cl_abap_unit_assert=>fail( 'Arbitrary binary content was accepted as an .xlsx document' ).
      CATCH zcx_xlsx.
    ENDTRY.
  ENDMETHOD.

  METHOD given_unknown_sheet_then_raise.
    DATA target TYPE records.

    TRY.
        cut->read_sheet( EXPORTING sheet_name = `Missing`
                         IMPORTING rows       = target ).

        cl_abap_unit_assert=>fail( 'Reading a worksheet that does not exist did not raise' ).
      CATCH zcx_xlsx.
    ENDTRY.
  ENDMETHOD.

  METHOD given_row_zero_then_raises.
    DATA target TYPE records.

    TRY.
        cut->read_sheet( EXPORTING sheet_name = sheet
                                   from_row   = invalid_row
                         IMPORTING rows       = target ).

        cl_abap_unit_assert=>fail( 'Row 0 was accepted although worksheet rows start at 1' ).
      CATCH zcx_xlsx.
    ENDTRY.
  ENDMETHOD.

  METHOD given_position_zero_then_raise.
    DATA target TYPE records.

    TRY.
        cut->read_sheet_at_position( EXPORTING position = invalid_row
                                     IMPORTING rows     = target ).

        cl_abap_unit_assert=>fail( 'Position 0 was accepted although positions start at 1' ).
      CATCH zcx_xlsx.
    ENDTRY.
  ENDMETHOD.

  METHOD given_beyond_last_then_raises.
    DATA target TYPE records.

    TRY.
        cut->read_sheet_at_position( EXPORTING position = beyond_last
                                     IMPORTING rows     = target ).

        cl_abap_unit_assert=>fail( 'A position beyond the last worksheet did not raise' ).
      CATCH zcx_xlsx.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_round_trip DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    TYPES: BEGIN OF employee,
             id         TYPE string,
             name       TYPE string,
             department TYPE string,
           END OF employee.
    TYPES employees TYPE STANDARD TABLE OF employee WITH EMPTY KEY.

    TYPES: BEGIN OF booking,
             reference TYPE string,
             booked_on TYPE d,
             amount    TYPE p LENGTH 9 DECIMALS 2,
           END OF booking.
    TYPES bookings TYPE STANDARD TABLE OF booking WITH EMPTY KEY.

    CONSTANTS employees_sheet TYPE string VALUE `Employees`.
    CONSTANTS archive_sheet   TYPE string VALUE `Archive`.
    CONSTANTS bookings_sheet  TYPE string VALUE `Bookings`.
    CONSTANTS header_row      TYPE i      VALUE 1.
    CONSTANTS first_data_row  TYPE i      VALUE 2.

    METHODS sample_employees
      RETURNING VALUE(result) TYPE employees.

    METHODS employee_file
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_xlsx.

    METHODS given_rows_when_read_then_eq  FOR TESTING RAISING cx_static_check.
    METHODS given_header_then_labels_row1 FOR TESTING RAISING cx_static_check.
    METHODS given_labels_then_labels_used FOR TESTING RAISING cx_static_check.
    METHODS given_two_sheets_then_count_2 FOR TESTING RAISING cx_static_check.
    METHODS given_no_rows_then_header     FOR TESTING RAISING cx_static_check.
    METHODS given_written_then_has_sheet  FOR TESTING RAISING cx_static_check.
    METHODS given_date_col_then_restored  FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_round_trip IMPLEMENTATION.

  METHOD sample_employees.
    result = VALUE #( ( id = `10001` name = `Alkinoos` department = `Logistics` )
                      ( id = `10002` name = `Rania`    department = `Finance` )
                      ( id = `10003` name = `Petros`   department = `Logistics` ) ).
  ENDMETHOD.

  METHOD employee_file.
    result = zcl_xlsx=>empty(
                     )->add_sheet_from_structure( sheet_name = employees_sheet
                                                  rows       = sample_employees( )
                     )->get_file_content( ).
  ENDMETHOD.

  METHOD given_rows_when_read_then_eq.
    DATA(expected) = sample_employees( ).
    DATA(content)  = employee_file( ).

    DATA actual TYPE employees.
    zcl_xlsx=>for_file_content( content )->read_sheet( EXPORTING sheet_name = employees_sheet
                                                                 from_row   = first_data_row
                                                       IMPORTING rows       = actual ).

    cl_abap_unit_assert=>assert_equals( act = actual
                                        exp = expected
                                        msg = 'Data rows did not survive the write and read round trip' ).
  ENDMETHOD.

  METHOD given_header_then_labels_row1.
    DATA(content) = employee_file( ).

    DATA all_rows TYPE employees.
    zcl_xlsx=>for_file_content( content )->read_sheet( EXPORTING sheet_name = employees_sheet
                                                       IMPORTING rows       = all_rows ).

    cl_abap_unit_assert=>assert_equals(
      act = all_rows[ header_row ]
      exp = VALUE employee( id = `ID` name = `NAME` department = `DEPARTMENT` )
      msg = 'The header row was not derived from the component names' ).
  ENDMETHOD.

  METHOD given_labels_then_labels_used.
    DATA(content) = zcl_xlsx=>empty(
                            )->add_sheet_from_structure(
                                 sheet_name = employees_sheet
                                 rows       = sample_employees( )
                                 labels     = VALUE zif_xlsx_writer=>column_labels(
                                                ( `Employee` ) ( `Full name` ) ( `Unit` ) )
                            )->get_file_content( ).

    DATA all_rows TYPE employees.
    zcl_xlsx=>for_file_content( content )->read_sheet( EXPORTING sheet_name = employees_sheet
                                                       IMPORTING rows       = all_rows ).

    cl_abap_unit_assert=>assert_equals(
      act = all_rows[ header_row ]
      exp = VALUE employee( id = `Employee` name = `Full name` department = `Unit` )
      msg = 'Supplied column labels were not used for the header row' ).
  ENDMETHOD.

  METHOD given_two_sheets_then_count_2.
    DATA(content) = zcl_xlsx=>empty(
                            )->add_sheet_from_structure( sheet_name = employees_sheet
                                                         rows       = sample_employees( )
                            )->add_sheet_from_structure( sheet_name = archive_sheet
                                                         rows       = sample_employees( )
                            )->get_file_content( ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_xlsx=>for_file_content( content )->count_sheets( )
      exp = 2
      msg = 'Two added worksheets were not both present in the document' ).
  ENDMETHOD.

  METHOD given_no_rows_then_header.
    DATA(content) = zcl_xlsx=>empty(
                            )->add_sheet_from_structure( sheet_name = employees_sheet
                                                         rows       = VALUE employees( )
                            )->get_file_content( ).

    DATA all_rows TYPE employees.
    zcl_xlsx=>for_file_content( content )->read_sheet( EXPORTING sheet_name = employees_sheet
                                                       IMPORTING rows       = all_rows ).

    cl_abap_unit_assert=>assert_equals( act = lines( all_rows )
                                        exp = 1
                                        msg = 'An empty source table should produce a header only worksheet' ).
  ENDMETHOD.

  METHOD given_written_then_has_sheet.
    DATA(content) = employee_file( ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_xlsx=>for_file_content( content )->has_sheet( employees_sheet )
      exp = abap_true
      msg = 'The written worksheet was not found by its name' ).
  ENDMETHOD.

  METHOD given_date_col_then_restored.
    DATA(expected) = VALUE bookings( ( reference = `B-1` booked_on = '20250120' amount = '1234.56' )
                                     ( reference = `B-2` booked_on = '20260731' amount = '99.00' ) ).

    DATA(content) = zcl_xlsx=>empty(
                            )->add_sheet_from_structure( sheet_name = bookings_sheet
                                                         rows       = expected
                            )->get_file_content( ).

    DATA actual TYPE bookings.
    zcl_xlsx=>for_file_content( content )->read_sheet( EXPORTING sheet_name = bookings_sheet
                                                                 from_row   = first_data_row
                                                       IMPORTING rows       = actual ).

    cl_abap_unit_assert=>assert_equals( act = actual
                                        exp = expected
                                        msg = 'Typed date and amount columns did not survive the round trip' ).
  ENDMETHOD.

ENDCLASS.
