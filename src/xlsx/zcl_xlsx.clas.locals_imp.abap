CLASS lcl_reader DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_xlsx_reader.

    METHODS constructor
      IMPORTING file_content TYPE xstring
      RAISING   zcx_xlsx.

  PRIVATE SECTION.
    "! Safety net for the worksheet enumeration loop.
    CONSTANTS max_worksheets TYPE i VALUE 1000.

    DATA workbook TYPE REF TO if_xco_xlsx_ra_workbook.

    "! Raw handle for a position. Does NOT check whether the worksheet exists.
    METHODS worksheet_handle
      IMPORTING position      TYPE i
      RETURNING VALUE(result) TYPE REF TO if_xco_xlsx_ra_worksheet
      RAISING   zcx_xlsx.

    METHODS worksheet_for_name
      IMPORTING sheet_name    TYPE string
      RETURNING VALUE(result) TYPE REF TO if_xco_xlsx_ra_worksheet
      RAISING   zcx_xlsx.

    METHODS worksheet_at_position
      IMPORTING position      TYPE i
      RETURNING VALUE(result) TYPE REF TO if_xco_xlsx_ra_worksheet
      RAISING   zcx_xlsx.

    METHODS read_worksheet
      IMPORTING worksheet TYPE REF TO if_xco_xlsx_ra_worksheet
                from_row  TYPE i
                sheet_id  TYPE string
      EXPORTING rows      TYPE STANDARD TABLE
      RAISING   zcx_xlsx.

ENDCLASS.


CLASS lcl_reader IMPLEMENTATION.

  METHOD constructor.
    TRY.
        workbook = xco_cp_xlsx=>document->for_file_content( file_content
                                       )->read_access(
                                       )->get_workbook( ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_xlsx( text     = `The file content could not be opened as an .xlsx document`
                                      previous = xco_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_xlsx_reader~count_sheets.
    DATA(position) = zif_xlsx_reader=>first_sheet.

    WHILE position <= max_worksheets.
      IF worksheet_handle( position )->exists( ) = abap_false.
        result = position - 1.
        RETURN.
      ENDIF.

      position += 1.
    ENDWHILE.

    RAISE EXCEPTION NEW zcx_xlsx( text = |Worksheet enumeration stopped after { max_worksheets } positions| ).
  ENDMETHOD.

  METHOD zif_xlsx_reader~has_sheet.
    TRY.
        result = workbook->worksheet->for_name( sheet_name )->exists( ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_xlsx( text     = |Worksheet { sheet_name } could not be accessed|
                                      previous = xco_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_xlsx_reader~read_sheet.
    read_worksheet( EXPORTING worksheet = worksheet_for_name( sheet_name )
                              from_row  = from_row
                              sheet_id  = sheet_name
                    IMPORTING rows      = rows ).
  ENDMETHOD.

  METHOD zif_xlsx_reader~read_sheet_at_position.
    read_worksheet( EXPORTING worksheet = worksheet_at_position( position )
                              from_row  = from_row
                              sheet_id  = |at position { position }|
                    IMPORTING rows      = rows ).
  ENDMETHOD.

  METHOD worksheet_handle.
    TRY.
        result = workbook->worksheet->at_position( position ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_xlsx( text     = |Worksheet at position { position } could not be accessed|
                                      previous = xco_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD worksheet_for_name.
    TRY.
        result = workbook->worksheet->for_name( sheet_name ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_xlsx( text     = |Worksheet { sheet_name } could not be accessed|
                                      previous = xco_error ).
    ENDTRY.

    IF result->exists( ) = abap_false.
      RAISE EXCEPTION NEW zcx_xlsx( text = |Worksheet { sheet_name } does not exist in the document| ).
    ENDIF.
  ENDMETHOD.

  METHOD worksheet_at_position.
    IF position < zif_xlsx_reader=>first_sheet.
      RAISE EXCEPTION NEW zcx_xlsx( text = |Worksheet position { position } is invalid, positions start at 1| ).
    ENDIF.

    result = worksheet_handle( position ).

    IF result->exists( ) = abap_false.
      RAISE EXCEPTION NEW zcx_xlsx( text = |The document has no worksheet at position { position }| ).
    ENDIF.
  ENDMETHOD.

  METHOD read_worksheet.
    IF from_row < zif_xlsx_reader=>first_row.
      RAISE EXCEPTION NEW zcx_xlsx( text = |Row { from_row } is invalid, worksheet rows start at 1| ).
    ENDIF.

    TRY.
        DATA(pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to(
                          )->from_row( xco_cp_xlsx=>coordinate->for_numeric_value( from_row )
                          )->get_pattern( ).

        worksheet->select( pattern
                  )->row_stream(
                  )->operation->write_to( REF #( rows )
                  )->if_xco_xlsx_ra_operation~execute( ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_xlsx( text     = |Worksheet { sheet_id } could not be read|
                                      previous = xco_error ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_writer DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_xlsx_writer.

    METHODS constructor
      RAISING zcx_xlsx.

  PRIVATE SECTION.
    "! Position of the worksheet that ships with an empty document.
    CONSTANTS default_sheet_position TYPE i VALUE 1.
    "! Topmost row of a worksheet.
    CONSTANTS first_row              TYPE i VALUE 1.
    "! First row below a generated header row.
    CONSTANTS first_data_row         TYPE i VALUE 2.
    "! Decimal floating point is not supported by the XLSX write value
    "! transformation in this release - it silently writes zeros.
    CONSTANTS decimal_hint TYPE string VALUE `use type P with DECIMALS instead`.

    DATA document    TYPE REF TO if_xco_xlsx_wa_document.
    DATA added_count TYPE i.

    METHODS check_sheet_name
      IMPORTING sheet_name TYPE string
      RAISING   zcx_xlsx.

    METHODS add_worksheet
      IMPORTING sheet_name    TYPE string
      RETURNING VALUE(result) TYPE REF TO if_xco_xlsx_wa_worksheet.

    "! Writes one internal table into the worksheet starting at the given row.
    "! XCO failures propagate - the caller adds the worksheet context.
    METHODS write_block
      IMPORTING worksheet TYPE REF TO if_xco_xlsx_wa_worksheet
                table     TYPE REF TO data
                from_row  TYPE i.

    METHODS structure_of
      IMPORTING rows          TYPE STANDARD TABLE
      RETURNING VALUE(result) TYPE REF TO cl_abap_structdescr
      RAISING   zcx_xlsx.

    METHODS check_components
      IMPORTING row_type TYPE REF TO cl_abap_structdescr
      RAISING   zcx_xlsx.

    METHODS labels_for
      IMPORTING row_type      TYPE REF TO cl_abap_structdescr
                labels        TYPE zif_xlsx_writer=>column_labels
      RETURNING VALUE(result) TYPE zif_xlsx_writer=>column_labels
      RAISING   zcx_xlsx.

    METHODS header_type_for
      IMPORTING row_type      TYPE REF TO cl_abap_structdescr
      RETURNING VALUE(result) TYPE REF TO cl_abap_tabledescr
      RAISING   zcx_xlsx.

    METHODS header_table
      IMPORTING rows          TYPE STANDARD TABLE
                labels        TYPE zif_xlsx_writer=>column_labels
      RETURNING VALUE(result) TYPE REF TO data
      RAISING   zcx_xlsx.

ENDCLASS.


CLASS lcl_writer IMPLEMENTATION.

  METHOD constructor.
    TRY.
        document = xco_cp_xlsx=>document->empty( )->write_access( ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_xlsx( text     = `An empty .xlsx document could not be created`
                                      previous = xco_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_xlsx_writer~add_sheet.
    check_sheet_name( sheet_name ).

    TRY.
        write_block( worksheet = add_worksheet( sheet_name )
                     table     = REF #( rows )
                     from_row  = first_row ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_xlsx( text     = |Worksheet { sheet_name } could not be written|
                                      previous = xco_error ).
    ENDTRY.

    self = me.
  ENDMETHOD.

  METHOD zif_xlsx_writer~add_sheet_from_structure.
    check_sheet_name( sheet_name ).

    " Built before the worksheet is added, so that a rejected line type leaves
    " no half-populated worksheet behind in the document.
    DATA(header) = header_table( rows   = rows
                                 labels = labels ).

    TRY.
        DATA(worksheet) = add_worksheet( sheet_name ).

        write_block( worksheet = worksheet
                     table     = header
                     from_row  = first_row ).

        IF rows IS NOT INITIAL.
          write_block( worksheet = worksheet
                       table     = REF #( rows )
                       from_row  = first_data_row ).
        ENDIF.
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_xlsx( text     = |Worksheet { sheet_name } could not be written|
                                      previous = xco_error ).
    ENDTRY.

    self = me.
  ENDMETHOD.

  METHOD zif_xlsx_writer~get_file_content.
    TRY.
        result = document->get_file_content( ).
      CATCH cx_xco_runtime_exception INTO DATA(xco_error).
        RAISE EXCEPTION NEW zcx_xlsx( text     = `The .xlsx file content could not be generated`
                                      previous = xco_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD check_sheet_name.
    IF sheet_name IS INITIAL.
      RAISE EXCEPTION NEW zcx_xlsx( text = `A worksheet name must not be empty` ).
    ENDIF.

    DATA(limit) = zif_xlsx_writer=>max_sheet_name_length.

    IF strlen( sheet_name ) > limit.
      RAISE EXCEPTION NEW zcx_xlsx( text = |Worksheet name { sheet_name } exceeds { limit } characters| ).
    ENDIF.
  ENDMETHOD.

  METHOD add_worksheet.
    IF added_count = 0.
      " Reuse the worksheet that ships with an empty document instead of leaving
      " it behind unused next to the sheets we add.
      result = document->get_workbook( )->worksheet->at_position( default_sheet_position
                                                     )->set_name( sheet_name ).
    ELSE.
      document->get_workbook( )->add_new_sheet( iv_name = sheet_name ).
      result = document->get_workbook( )->worksheet->at_position( default_sheet_position + added_count ).
    ENDIF.

    added_count += 1.
  ENDMETHOD.

  METHOD write_block.
    DATA(pattern) = xco_cp_xlsx_selection=>pattern_builder->simple_from_to(
                      )->from_row( xco_cp_xlsx=>coordinate->for_numeric_value( from_row )
                      )->get_pattern( ).

    worksheet->select( pattern )->row_stream( )->operation->write_from( table )->execute( ).
  ENDMETHOD.

  METHOD structure_of.
    TRY.
        DATA(table_type) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( rows ) ).
        result = CAST cl_abap_structdescr( table_type->get_table_line_type( ) ).
      CATCH cx_sy_move_cast_error INTO DATA(cast_error).
        RAISE EXCEPTION NEW zcx_xlsx( text     = `The line type of the table must be a structure, not elementary`
                                      previous = cast_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD check_components.
    LOOP AT row_type->components INTO DATA(component).
      IF component-type_kind = cl_abap_typedescr=>typekind_struct1
        OR component-type_kind = cl_abap_typedescr=>typekind_struct2
        OR component-type_kind = cl_abap_typedescr=>typekind_table
        OR component-type_kind = cl_abap_typedescr=>typekind_dref
        OR component-type_kind = cl_abap_typedescr=>typekind_oref.
        RAISE EXCEPTION NEW zcx_xlsx( text = |Component { component-name } is not elementary and cannot be column| ).
      ENDIF.

      IF component-type_kind = cl_abap_typedescr=>typekind_decfloat16
        OR component-type_kind = cl_abap_typedescr=>typekind_decfloat34.
        RAISE EXCEPTION NEW zcx_xlsx( text = |Component { component-name } is dec. floating point, { decimal_hint }| ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD labels_for.
    DATA(column_count) = lines( row_type->components ).

    IF labels IS INITIAL.
      result = VALUE #( FOR component IN row_type->components ( CONV string( component-name ) ) ).
      RETURN.
    ENDIF.

    IF lines( labels ) <> column_count.
      RAISE EXCEPTION NEW zcx_xlsx( text = |{ lines( labels ) } labels were supplied for { column_count } columns| ).
    ENDIF.

    result = labels.
  ENDMETHOD.

  METHOD header_type_for.
    TRY.
        DATA(header_line) = cl_abap_structdescr=>create(
          VALUE #( FOR component IN row_type->components
                   ( name = component-name
                     type = cl_abap_elemdescr=>get_string( ) ) ) ).

        result = cl_abap_tabledescr=>create( p_line_type  = header_line
                                             p_table_kind = cl_abap_tabledescr=>tablekind_std
                                             p_unique     = abap_false ).
      CATCH cx_sy_struct_creation cx_sy_table_creation INTO DATA(creation_error).
        RAISE EXCEPTION NEW zcx_xlsx( text     = `The header row type could not be built`
                                      previous = creation_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD header_table.
    DATA(row_type) = structure_of( rows ).
    check_components( row_type ).

    DATA(texts) = labels_for( row_type = row_type
                              labels   = labels ).

    DATA(header_type) = header_type_for( row_type ).
    CREATE DATA result TYPE HANDLE header_type.

    FIELD-SYMBOLS <header_rows> TYPE STANDARD TABLE.
    ASSIGN result->* TO <header_rows>.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_xlsx( text = `The header row table could not be accessed` ).
    ENDIF.

    FIELD-SYMBOLS <header_row> TYPE any.
    INSERT INITIAL LINE INTO TABLE <header_rows> ASSIGNING <header_row>.

    LOOP AT texts INTO DATA(text).
      DATA(column) = sy-tabix.

      ASSIGN COMPONENT column OF STRUCTURE <header_row> TO FIELD-SYMBOL(<cell>).
      IF sy-subrc <> 0.
        RAISE EXCEPTION NEW zcx_xlsx( text = |Column { column } is missing in the header row| ).
      ENDIF.

      <cell> = text.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
