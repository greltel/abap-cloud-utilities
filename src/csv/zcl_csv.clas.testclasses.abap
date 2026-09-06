*"* use this source file for your ABAP unit test classes
"! Builds test documents with explicit line breaks.
CLASS lth_document DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PUBLIC SECTION.
    CONSTANTS lf   TYPE c LENGTH 1 VALUE cl_abap_char_utilities=>newline.
    CONSTANTS crlf TYPE c LENGTH 2 VALUE cl_abap_char_utilities=>cr_lf.

    "! Joins the lines with LF; add an empty last line for a trailing line break.
    CLASS-METHODS with_lf
      IMPORTING texts         TYPE zif_csv_reader=>record
      RETURNING VALUE(result) TYPE string.

    "! Joins the lines with CRLF; add an empty last line for a trailing line break.
    CLASS-METHODS with_crlf
      IMPORTING texts         TYPE zif_csv_reader=>record
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS lth_document IMPLEMENTATION.

  METHOD with_lf.
    result = concat_lines_of( table = texts
                              sep   = lf ).
  ENDMETHOD.

  METHOD with_crlf.
    result = concat_lines_of( table = texts
                              sep   = crlf ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_parsing DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS given_plain_then_fields_split     FOR TESTING RAISING cx_static_check.
    METHODS given_quoted_delim_then_kept      FOR TESTING RAISING cx_static_check.
    METHODS given_two_quotes_then_literal     FOR TESTING RAISING cx_static_check.
    METHODS given_quoted_break_then_kept      FOR TESTING RAISING cx_static_check.
    METHODS given_crlf_then_records_split     FOR TESTING RAISING cx_static_check.
    METHODS given_lone_cr_then_split          FOR TESTING RAISING cx_static_check.
    METHODS given_trailing_break_no_record    FOR TESTING RAISING cx_static_check.
    METHODS given_blank_lines_then_skipped    FOR TESTING RAISING cx_static_check.
    METHODS given_quoted_empty_then_record    FOR TESTING RAISING cx_static_check.
    METHODS given_end_delim_then_empty        FOR TESTING RAISING cx_static_check.
    METHODS given_empty_fields_then_kept      FOR TESTING RAISING cx_static_check.
    METHODS given_inner_quote_then_kept       FOR TESTING RAISING cx_static_check.
    METHODS given_semicolon_then_split        FOR TESTING RAISING cx_static_check.
    METHODS given_tab_then_split              FOR TESTING RAISING cx_static_check.
    METHODS given_single_quote_then_used      FOR TESTING RAISING cx_static_check.
    METHODS given_empty_text_then_none        FOR TESTING RAISING cx_static_check.
    METHODS given_header_then_returned_too    FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_parsing IMPLEMENTATION.

  METHOD given_plain_then_fields_split.
    DATA(records) = zcl_csv=>for_string( lth_document=>with_lf( VALUE #( ( `a,b,c` ) ( `1,2,3` ) ) ) )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = records
                                        exp = VALUE zif_csv_reader=>records( ( VALUE #( ( `a` ) ( `b` ) ( `c` ) ) )
                                                                             ( VALUE #( ( `1` ) ( `2` ) ( `3` ) ) ) )
                                        msg = 'Plain fields must be split at the delimiter and the line break' ).
  ENDMETHOD.

  METHOD given_quoted_delim_then_kept.
    DATA(records) = zcl_csv=>for_string( `"a,b",c` )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = records
                                        exp = VALUE zif_csv_reader=>records( ( VALUE #( ( `a,b` ) ( `c` ) ) ) )
                                        msg = 'A delimiter inside a quoted field must not split the field' ).
  ENDMETHOD.

  METHOD given_two_quotes_then_literal.
    DATA(records) = zcl_csv=>for_string( `"say ""hi""",x` )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = records[ 1 ][ 1 ]
                                        exp = `say "hi"`
                                        msg = 'A doubled quote inside a quoted field must become one quote' ).
  ENDMETHOD.

  METHOD given_quoted_break_then_kept.
    DATA(records) = zcl_csv=>for_string( |"line 1{ lth_document=>crlf }line 2",x| )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = lines( records )
                                        exp = 1
                                        msg = 'A line break inside a quoted field must not end the record' ).
    cl_abap_unit_assert=>assert_equals( act = records[ 1 ][ 1 ]
                                        exp = |line 1{ lth_document=>crlf }line 2|
                                        msg = 'A line break inside a quoted field must be kept as it is' ).
  ENDMETHOD.

  METHOD given_crlf_then_records_split.
    DATA(records) = zcl_csv=>for_string( lth_document=>with_crlf( VALUE #( ( `a,b` ) ( `c,d` ) ) ) )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = records
                                        exp = VALUE zif_csv_reader=>records( ( VALUE #( ( `a` ) ( `b` ) ) )
                                                                             ( VALUE #( ( `c` ) ( `d` ) ) ) )
                                        msg = 'CRLF must end a record without leaving the CR in a field' ).
  ENDMETHOD.

  METHOD given_lone_cr_then_split.
    DATA(cr) = substring( val = lth_document=>crlf
                          off = 0
                          len = 1 ).

    DATA(records) = zcl_csv=>for_string( |a{ cr }b| )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = lines( records )
                                        exp = 2
                                        msg = 'A lone CR must end a record like LF does' ).
  ENDMETHOD.

  METHOD given_trailing_break_no_record.
    DATA(records) = zcl_csv=>for_string( lth_document=>with_crlf( VALUE #( ( `a,b` ) ( `` ) ) ) )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = lines( records )
                                        exp = 1
                                        msg = 'A trailing line break must not produce an empty record' ).
  ENDMETHOD.

  METHOD given_blank_lines_then_skipped.
    DATA(document) = lth_document=>with_lf( VALUE #( ( `a` ) ( `` ) ( `` ) ( `b` ) ) ).

    DATA(records) = zcl_csv=>for_string( document )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = lines( records )
                                        exp = 2
                                        msg = 'Blank lines must be skipped' ).
  ENDMETHOD.

  METHOD given_quoted_empty_then_record.
    DATA(records) = zcl_csv=>for_string( lth_document=>with_lf( VALUE #( ( `""` ) ( `` ) ) ) )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = records
                                        exp = VALUE zif_csv_reader=>records( ( VALUE #( ( `` ) ) ) )
                                        msg = 'A quoted empty field is a record, unlike a blank line' ).
  ENDMETHOD.

  METHOD given_end_delim_then_empty.
    DATA(records) = zcl_csv=>for_string( `a,b,` )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = records[ 1 ]
                                        exp = VALUE zif_csv_reader=>record( ( `a` ) ( `b` ) ( `` ) )
                                        msg = 'A trailing delimiter must produce an empty last field' ).
  ENDMETHOD.

  METHOD given_empty_fields_then_kept.
    DATA(records) = zcl_csv=>for_string( `,,` )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = lines( records[ 1 ] )
                                        exp = 3
                                        msg = 'Delimiters alone must produce empty fields' ).
  ENDMETHOD.

  METHOD given_inner_quote_then_kept.
    DATA(records) = zcl_csv=>for_string( `27" monitor,x` )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = records[ 1 ][ 1 ]
                                        exp = `27" monitor`
                                        msg = 'A quote inside an unquoted field must be taken literally' ).
  ENDMETHOD.

  METHOD given_semicolon_then_split.
    DATA(records) = zcl_csv=>for_string( `a;b,c` )->with_delimiter( `;` )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = records[ 1 ]
                                        exp = VALUE zif_csv_reader=>record( ( `a` ) ( `b,c` ) )
                                        msg = 'Only the configured delimiter must split fields' ).
  ENDMETHOD.

  METHOD given_tab_then_split.
    DATA(tab) = cl_abap_char_utilities=>horizontal_tab.

    DATA(records) = zcl_csv=>for_string( |a{ tab }b| )->with_delimiter( CONV #( tab ) )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = lines( records[ 1 ] )
                                        exp = 2
                                        msg = 'A tab must work as delimiter' ).
  ENDMETHOD.

  METHOD given_single_quote_then_used.
    DATA(records) = zcl_csv=>for_string( `'a,b',"c"` )->with_quote( `'` )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = records[ 1 ]
                                        exp = VALUE zif_csv_reader=>record( ( `a,b` ) ( `"c"` ) )
                                        msg = 'Only the configured quote character must enclose fields' ).
  ENDMETHOD.

  METHOD given_empty_text_then_none.
    DATA(records) = zcl_csv=>for_string( `` )->read_records( ).

    cl_abap_unit_assert=>assert_initial( act = records
                                         msg = 'An empty document has no records' ).
  ENDMETHOD.

  METHOD given_header_then_returned_too.
    DATA(document) = lth_document=>with_lf( VALUE #( ( `ID,NAME` ) ( `1,Ada` ) ) ).

    DATA(records) = zcl_csv=>for_string( document )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = records[ 1 ]
                                        exp = VALUE zif_csv_reader=>record( ( `ID` ) ( `NAME` ) )
                                        msg = 'Raw records must include the header record' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_parsing_errors DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    METHODS given_open_quote_then_raises      FOR TESTING.
    METHODS given_text_after_quote_raises     FOR TESTING.
    METHODS given_long_delim_then_raises      FOR TESTING.
    METHODS given_empty_delim_then_raises     FOR TESTING.
    METHODS given_delim_eq_quote_raises       FOR TESTING.
    METHODS given_break_delim_then_raises     FOR TESTING.

    METHODS assert_raises
      IMPORTING reader TYPE REF TO zif_csv_reader
                msg    TYPE string.

ENDCLASS.


CLASS ltc_parsing_errors IMPLEMENTATION.

  METHOD given_open_quote_then_raises.
    assert_raises( reader = zcl_csv=>for_string( lth_document=>with_lf( VALUE #( ( `a,b` ) ( `"open,c` ) ) ) )
                   msg    = `A quoted field without a closing quote must be rejected` ).
  ENDMETHOD.

  METHOD given_text_after_quote_raises.
    assert_raises( reader = zcl_csv=>for_string( `"a"b,c` )
                   msg    = `Text after a closing quote must be rejected` ).
  ENDMETHOD.

  METHOD given_long_delim_then_raises.
    assert_raises( reader = zcl_csv=>for_string( `a;;b` )->with_delimiter( `;;` )
                   msg    = `A delimiter of two characters must be rejected` ).
  ENDMETHOD.

  METHOD given_empty_delim_then_raises.
    assert_raises( reader = zcl_csv=>for_string( `a,b` )->with_delimiter( `` )
                   msg    = `An empty delimiter must be rejected` ).
  ENDMETHOD.

  METHOD given_delim_eq_quote_raises.
    assert_raises( reader = zcl_csv=>for_string( `a"b` )->with_delimiter( `"` )
                   msg    = `A delimiter equal to the quote character must be rejected` ).
  ENDMETHOD.

  METHOD given_break_delim_then_raises.
    assert_raises( reader = zcl_csv=>for_string( `a,b` )->with_delimiter( CONV #( lth_document=>lf ) )
                   msg    = `A line break as delimiter must be rejected` ).
  ENDMETHOD.

  METHOD assert_raises.
    TRY.
        reader->read_records( ).

        cl_abap_unit_assert=>fail( msg ).
      CATCH zcx_csv INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial( act = error->get_text( )
                                                 msg = 'The error must carry a description' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_typed_reading DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    TYPES: BEGIN OF product,
             product_id TYPE string,
             name       TYPE string,
             price      TYPE p LENGTH 9 DECIMALS 2,
             stock      TYPE i,
             valid_from TYPE d,
             is_active  TYPE abap_bool,
           END OF product.
    TYPES products TYPE STANDARD TABLE OF product WITH EMPTY KEY.

    TYPES: BEGIN OF order,
             order_id TYPE string,
             items    TYPE products,
           END OF order.
    TYPES orders TYPE STANDARD TABLE OF order WITH EMPTY KEY.

    METHODS given_header_then_by_name         FOR TESTING RAISING cx_static_check.
    METHODS given_header_case_then_ignored    FOR TESTING RAISING cx_static_check.
    METHODS given_no_header_then_by_pos       FOR TESTING RAISING cx_static_check.
    METHODS given_extra_col_then_ignored      FOR TESTING RAISING cx_static_check.
    METHODS given_missing_column_then_init    FOR TESTING RAISING cx_static_check.
    METHODS given_fewer_fields_then_init      FOR TESTING RAISING cx_static_check.
    METHODS given_typed_then_converted        FOR TESTING RAISING cx_static_check.
    METHODS given_header_only_then_empty      FOR TESTING RAISING cx_static_check.
    METHODS given_empty_text_then_empty       FOR TESTING RAISING cx_static_check.
    METHODS given_bad_number_then_raises      FOR TESTING.
    METHODS given_count_off_then_raises       FOR TESTING.
    METHODS given_no_match_then_raises        FOR TESTING.
    METHODS given_dup_column_then_raises      FOR TESTING.
    METHODS given_too_many_fields_raises      FOR TESTING.
    METHODS given_deep_target_then_raises     FOR TESTING.
    METHODS given_elem_target_then_raises     FOR TESTING.

    METHODS assert_raises
      IMPORTING reader        TYPE REF TO zif_csv_reader
                msg           TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS ltc_typed_reading IMPLEMENTATION.

  METHOD given_header_then_by_name.
    DATA products TYPE products.

    zcl_csv=>for_string( lth_document=>with_lf( VALUE #( ( `NAME,PRODUCT_ID` ) ( `Keyboard,K-1` ) ) )
      )->read_into( IMPORTING rows = products ).

    cl_abap_unit_assert=>assert_equals( act = products
                                        exp = VALUE products( ( product_id = `K-1` name = `Keyboard` ) )
                                        msg = 'Columns must be mapped by header name, not by position' ).
  ENDMETHOD.

  METHOD given_header_case_then_ignored.
    DATA products TYPE products.

    zcl_csv=>for_string( lth_document=>with_lf( VALUE #( ( ` product_id ,Name` ) ( `K-1,Keyboard` ) ) )
      )->read_into( IMPORTING rows = products ).

    cl_abap_unit_assert=>assert_equals( act = products[ 1 ]-name
                                        exp = `Keyboard`
                                        msg = 'Header names must match case insensitively, blanks ignored' ).
  ENDMETHOD.

  METHOD given_no_header_then_by_pos.
    DATA products TYPE products.

    zcl_csv=>for_string( lth_document=>with_lf( VALUE #( ( `K-1,Keyboard` ) ( `M-2,Mouse` ) ) )
      )->without_header(
      )->read_into( IMPORTING rows = products ).

    cl_abap_unit_assert=>assert_equals( act = products
                                        exp = VALUE products( ( product_id = `K-1` name = `Keyboard` )
                                                              ( product_id = `M-2` name = `Mouse` ) )
                                        msg = 'Without a header the fields must be mapped by position' ).
  ENDMETHOD.

  METHOD given_extra_col_then_ignored.
    DATA products TYPE products.

    zcl_csv=>for_string( lth_document=>with_lf( VALUE #( ( `PRODUCT_ID,COLOR,NAME` ) ( `K-1,black,Keyboard` ) ) )
      )->read_into( IMPORTING rows = products ).

    cl_abap_unit_assert=>assert_equals( act = products[ 1 ]
                                        exp = VALUE product( product_id = `K-1` name = `Keyboard` )
                                        msg = 'A column without a matching component must be ignored' ).
  ENDMETHOD.

  METHOD given_missing_column_then_init.
    DATA products TYPE products.

    zcl_csv=>for_string( lth_document=>with_lf( VALUE #( ( `PRODUCT_ID` ) ( `K-1` ) ) )
      )->read_into( IMPORTING rows = products ).

    cl_abap_unit_assert=>assert_initial( act = products[ 1 ]-name
                                         msg = 'A component without a matching column must stay initial' ).
  ENDMETHOD.

  METHOD given_fewer_fields_then_init.
    DATA products TYPE products.

    zcl_csv=>for_string( `K-1,Keyboard` )->without_header( )->read_into( IMPORTING rows = products ).

    cl_abap_unit_assert=>assert_initial( act = products[ 1 ]-price
                                         msg = 'Components beyond the last field must stay initial' ).
  ENDMETHOD.

  METHOD given_typed_then_converted.
    DATA products TYPE products.

    zcl_csv=>for_string( lth_document=>with_lf( VALUE #( ( `PRODUCT_ID,PRICE,STOCK,VALID_FROM,IS_ACTIVE` )
                                                         ( `K-1,-19.99,42,20240115,X` ) ) )
      )->read_into( IMPORTING rows = products ).

    cl_abap_unit_assert=>assert_equals( act = products[ 1 ]
                                        exp = VALUE product( product_id = `K-1`
                                                             price      = '-19.99'
                                                             stock      = 42
                                                             valid_from = '20240115'
                                                             is_active  = abap_true )
                                        msg = 'Field texts must be converted to the component types' ).
  ENDMETHOD.

  METHOD given_header_only_then_empty.
    DATA products TYPE products.

    zcl_csv=>for_string( `PRODUCT_ID,NAME` )->read_into( IMPORTING rows = products ).

    cl_abap_unit_assert=>assert_initial( act = products
                                         msg = 'A document with only a header has no rows' ).
  ENDMETHOD.

  METHOD given_empty_text_then_empty.
    DATA products TYPE products.

    zcl_csv=>for_string( `` )->read_into( IMPORTING rows = products ).

    cl_abap_unit_assert=>assert_initial( act = products
                                         msg = 'An empty document has no rows' ).
  ENDMETHOD.

  METHOD given_bad_number_then_raises.
    DATA(text) = assert_raises(
      reader = zcl_csv=>for_string( lth_document=>with_lf( VALUE #( ( `PRODUCT_ID,STOCK` ) ( `K-1,many` ) ) ) )
      msg    = `A value that cannot be converted must be rejected` ).

    cl_abap_unit_assert=>assert_equals( act = xsdbool( contains( val = text
                                                                 sub = `Record 2` ) )
                                        exp = abap_true
                                        msg = 'The error must name the record with the unconvertible value' ).
  ENDMETHOD.

  METHOD given_count_off_then_raises.
    assert_raises( reader = zcl_csv=>for_string( lth_document=>with_lf( VALUE #( ( `PRODUCT_ID,NAME` )
                                                                                 ( `K-1,Keyboard,extra` ) ) ) )
                   msg    = `A record with a different field count must be rejected` ).
  ENDMETHOD.

  METHOD given_no_match_then_raises.
    DATA(document) = lth_document=>with_lf( VALUE #( ( `PRODUCT_ID;NAME` ) ( `K-1;Keyboard` ) ) ).

    assert_raises( reader = zcl_csv=>for_string( document )
                   msg    = `A header without any matching column must be rejected` ).
  ENDMETHOD.

  METHOD given_dup_column_then_raises.
    assert_raises( reader = zcl_csv=>for_string( lth_document=>with_lf( VALUE #( ( `NAME,name` ) ( `a,b` ) ) ) )
                   msg    = `A header that names the same component twice must be rejected` ).
  ENDMETHOD.

  METHOD given_too_many_fields_raises.
    assert_raises( reader = zcl_csv=>for_string( `1,2,3,4,5,6,7` )->without_header( )
                   msg    = `More fields than components must be rejected in positional mode` ).
  ENDMETHOD.

  METHOD given_deep_target_then_raises.
    DATA orders TYPE orders.

    TRY.
        zcl_csv=>for_string( `ORDER_ID` )->read_into( IMPORTING rows = orders ).

        cl_abap_unit_assert=>fail( 'A target with a table component was accepted' ).
      CATCH zcx_csv.
    ENDTRY.
  ENDMETHOD.

  METHOD given_elem_target_then_raises.
    DATA names TYPE zif_csv_reader=>record.

    TRY.
        zcl_csv=>for_string( `NAME` )->read_into( IMPORTING rows = names ).

        cl_abap_unit_assert=>fail( 'A target with an elementary line type was accepted' ).
      CATCH zcx_csv.
    ENDTRY.
  ENDMETHOD.

  METHOD assert_raises.
    DATA products TYPE products.

    TRY.
        reader->read_into( IMPORTING rows = products ).

        cl_abap_unit_assert=>fail( msg ).
      CATCH zcx_csv INTO DATA(error).
        result = error->get_text( ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_writing DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    TYPES: BEGIN OF product,
             product_id TYPE string,
             name       TYPE string,
             price      TYPE p LENGTH 9 DECIMALS 2,
             stock      TYPE i,
           END OF product.
    TYPES products TYPE STANDARD TABLE OF product WITH EMPTY KEY.

    TYPES: BEGIN OF order,
             order_id TYPE string,
             items    TYPE products,
           END OF order.
    TYPES orders TYPE STANDARD TABLE OF order WITH EMPTY KEY.

    METHODS given_table_then_header_rows      FOR TESTING RAISING cx_static_check.
    METHODS given_specials_then_quoted        FOR TESTING RAISING cx_static_check.
    METHODS given_numbers_then_raw_format     FOR TESTING RAISING cx_static_check.
    METHODS given_without_header_then_rows    FOR TESTING RAISING cx_static_check.
    METHODS given_labels_then_used            FOR TESTING RAISING cx_static_check.
    METHODS given_semicolon_then_used         FOR TESTING RAISING cx_static_check.
    METHODS given_lf_then_used                FOR TESTING RAISING cx_static_check.
    METHODS given_single_quote_then_used      FOR TESTING RAISING cx_static_check.
    METHODS given_empty_table_then_header     FOR TESTING RAISING cx_static_check.
    METHODS given_records_then_as_is          FOR TESTING RAISING cx_static_check.
    METHODS given_rec_labels_then_header      FOR TESTING RAISING cx_static_check.
    METHODS given_nothing_then_empty          FOR TESTING RAISING cx_static_check.
    METHODS given_label_count_off_raises      FOR TESTING.
    METHODS given_bad_break_then_raises       FOR TESTING.
    METHODS given_bad_delim_then_raises       FOR TESTING.
    METHODS given_deep_table_then_raises      FOR TESTING.

    METHODS sample_products
      RETURNING VALUE(result) TYPE products.

    METHODS assert_raises
      IMPORTING writer TYPE REF TO zif_csv_writer
                msg    TYPE string.

ENDCLASS.


CLASS ltc_writing IMPLEMENTATION.

  METHOD sample_products.
    result = VALUE #( ( product_id = `K-1` name = `Keyboard` price = '49.90' stock = 12 )
                      ( product_id = `M-2` name = `Mouse` price = '19.99' stock = 30 ) ).
  ENDMETHOD.

  METHOD given_table_then_header_rows.
    DATA(csv) = zcl_csv=>for_table( sample_products( ) )->to_string( ).

    cl_abap_unit_assert=>assert_equals( act = csv
                                        exp = lth_document=>with_crlf( VALUE #( ( `PRODUCT_ID,NAME,PRICE,STOCK` )
                                                                                ( `K-1,Keyboard,49.90,12` )
                                                                                ( `M-2,Mouse,19.99,30` )
                                                                                ( `` ) ) )
                                        msg = 'A table must be written with a header of component names and CRLF' ).
  ENDMETHOD.

  METHOD given_specials_then_quoted.
    DATA(products) = VALUE products( ( product_id = `C-3`
                                       name       = |Cable, "USB-C"{ lth_document=>lf }2 m| ) ).

    DATA(csv) = zcl_csv=>for_table( products )->without_header( )->to_string( ).

    DATA(expected) = |C-3,"Cable, ""USB-C""{ lth_document=>lf }2 m",0.00,0{ lth_document=>crlf }|.

    cl_abap_unit_assert=>assert_equals( act = csv
                                        exp = expected
                                        msg = 'Delimiters, quotes and line breaks must be enclosed, quotes doubled' ).
  ENDMETHOD.

  METHOD given_numbers_then_raw_format.
    DATA(products) = VALUE products( ( price = '-1234.50' stock = -7 ) ).

    DATA(csv) = zcl_csv=>for_table( products )->without_header( )->to_string( ).

    cl_abap_unit_assert=>assert_equals( act = csv
                                        exp = |,,-1234.50,-7{ lth_document=>crlf }|
                                        msg = 'Numbers must be written with a leading sign and a decimal point' ).
  ENDMETHOD.

  METHOD given_without_header_then_rows.
    DATA(csv) = zcl_csv=>for_table( sample_products( ) )->without_header( )->to_string( ).

    cl_abap_unit_assert=>assert_equals( act = csv
                                        exp = lth_document=>with_crlf( VALUE #( ( `K-1,Keyboard,49.90,12` )
                                                                                ( `M-2,Mouse,19.99,30` )
                                                                                ( `` ) ) )
                                        msg = 'Without a header only the rows must be written' ).
  ENDMETHOD.

  METHOD given_labels_then_used.
    DATA(csv) = zcl_csv=>for_table( sample_products( )
      )->with_labels( VALUE #( ( `Id` ) ( `Name` ) ( `Price` ) ( `Stock` ) )
      )->to_string( ).

    cl_abap_unit_assert=>assert_equals( act = substring_before( val = csv
                                                                sub = lth_document=>crlf )
                                        exp = `Id,Name,Price,Stock`
                                        msg = 'Labels must replace the component names in the header' ).
  ENDMETHOD.

  METHOD given_semicolon_then_used.
    DATA(csv) = zcl_csv=>for_table( sample_products( ) )->with_delimiter( `;` )->to_string( ).

    cl_abap_unit_assert=>assert_equals( act = substring_before( val = csv
                                                                sub = lth_document=>crlf )
                                        exp = `PRODUCT_ID;NAME;PRICE;STOCK`
                                        msg = 'The configured delimiter must separate the fields' ).
  ENDMETHOD.

  METHOD given_lf_then_used.
    DATA(csv) = zcl_csv=>for_table( sample_products( )
      )->without_header(
      )->with_line_break( CONV #( lth_document=>lf )
      )->to_string( ).

    cl_abap_unit_assert=>assert_equals( act = csv
                                        exp = lth_document=>with_lf( VALUE #( ( `K-1,Keyboard,49.90,12` )
                                                                              ( `M-2,Mouse,19.99,30` )
                                                                              ( `` ) ) )
                                        msg = 'The configured line break must end every record' ).
  ENDMETHOD.

  METHOD given_single_quote_then_used.
    DATA(products) = VALUE products( ( product_id = `K-1` name = `Bob's "Keys", black` ) ).

    DATA(csv) = zcl_csv=>for_table( products )->without_header( )->with_quote( `'` )->to_string( ).

    cl_abap_unit_assert=>assert_equals( act = csv
                                        exp = |K-1,'Bob''s "Keys", black',0.00,0{ lth_document=>crlf }|
                                        msg = 'The configured quote character must enclose and be doubled' ).
  ENDMETHOD.

  METHOD given_empty_table_then_header.
    DATA products TYPE products.

    DATA(csv) = zcl_csv=>for_table( products )->to_string( ).

    cl_abap_unit_assert=>assert_equals( act = csv
                                        exp = |PRODUCT_ID,NAME,PRICE,STOCK{ lth_document=>crlf }|
                                        msg = 'An empty table must still produce its header' ).
  ENDMETHOD.

  METHOD given_records_then_as_is.
    DATA(records) = VALUE zif_csv_reader=>records( ( VALUE #( ( `Report` ) ) )
                                                   ( VALUE #( ( `a` ) ( `b` ) ( `c` ) ) ) ).

    DATA(csv) = zcl_csv=>for_records( records )->to_string( ).

    cl_abap_unit_assert=>assert_equals( act = csv
                                        exp = lth_document=>with_crlf( VALUE #( ( `Report` ) ( `a,b,c` ) ( `` ) ) )
                                        msg = 'Records must be written as given, without a generated header' ).
  ENDMETHOD.

  METHOD given_rec_labels_then_header.
    DATA(records) = VALUE zif_csv_reader=>records( ( VALUE #( ( `1` ) ( `2` ) ) ) ).

    DATA(csv) = zcl_csv=>for_records( records )->with_labels( VALUE #( ( `A` ) ( `B` ) ) )->to_string( ).

    cl_abap_unit_assert=>assert_equals( act = csv
                                        exp = lth_document=>with_crlf( VALUE #( ( `A,B` ) ( `1,2` ) ( `` ) ) )
                                        msg = 'Labels must be written in front of ready-made records' ).
  ENDMETHOD.

  METHOD given_nothing_then_empty.
    DATA(csv) = zcl_csv=>for_records( VALUE #( ) )->to_string( ).

    cl_abap_unit_assert=>assert_initial( act = csv
                                         msg = 'Neither header nor records must produce an empty document' ).
  ENDMETHOD.

  METHOD given_label_count_off_raises.
    TRY.
        DATA(writer) = zcl_csv=>for_table( sample_products( ) )->with_labels( VALUE #( ( `Only one` ) ) ).
      CATCH zcx_csv.
        cl_abap_unit_assert=>fail( 'The sample table was not accepted' ).
    ENDTRY.

    assert_raises( writer = writer
                   msg    = `A label count that differs from the component count must be rejected` ).
  ENDMETHOD.

  METHOD given_bad_break_then_raises.
    assert_raises( writer = zcl_csv=>for_records( VALUE #( ) )->with_line_break( `;` )
                   msg    = `A line break other than CRLF or LF must be rejected` ).
  ENDMETHOD.

  METHOD given_bad_delim_then_raises.
    assert_raises( writer = zcl_csv=>for_records( VALUE #( ) )->with_delimiter( `, ` )
                   msg    = `A delimiter of two characters must be rejected` ).
  ENDMETHOD.

  METHOD given_deep_table_then_raises.
    DATA orders TYPE orders.

    TRY.
        zcl_csv=>for_table( orders ).

        cl_abap_unit_assert=>fail( 'A table whose line type has a table component was accepted' ).
      CATCH zcx_csv.
    ENDTRY.
  ENDMETHOD.

  METHOD assert_raises.
    TRY.
        writer->to_string( ).

        cl_abap_unit_assert=>fail( msg ).
      CATCH zcx_csv INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial( act = error->get_text( )
                                                 msg = 'The error must carry a description' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_round_trip DEFINITION FINAL FOR TESTING
  RISK LEVEL HARMLESS
  DURATION SHORT.

  PRIVATE SECTION.
    TYPES: BEGIN OF measurement,
             sensor     TYPE c LENGTH 10,
             label      TYPE string,
             reading    TYPE p LENGTH 12 DECIMALS 3,
             count      TYPE i,
             taken_on   TYPE d,
             taken_at   TYPE t,
             is_valid   TYPE abap_bool,
             checksum   TYPE x LENGTH 4,
             ratio      TYPE f,
             big_number TYPE int8,
           END OF measurement.
    TYPES measurements TYPE STANDARD TABLE OF measurement WITH EMPTY KEY.

    METHODS sample_measurements
      RETURNING VALUE(result) TYPE measurements.

    METHODS given_table_then_round_trip       FOR TESTING RAISING cx_static_check.
    METHODS given_dialect_then_round_trip     FOR TESTING RAISING cx_static_check.
    METHODS given_no_header_round_trip        FOR TESTING RAISING cx_static_check.
    METHODS given_records_then_round_trip     FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_round_trip IMPLEMENTATION.

  METHOD sample_measurements.
    result = VALUE #( ( sensor     = 'TEMP-01'
                        label      = |Hall "A", north{ lth_document=>crlf }wing|
                        reading    = '-273.150'
                        count      = 3
                        taken_on   = '20240115'
                        taken_at   = '093000'
                        is_valid   = abap_true
                        checksum   = 'DEADBEEF'
                        ratio      = '0.25'
                        big_number = 9007199254740993 )
                      ( sensor   = 'HUM-02'
                        label    = ``
                        reading  = '55.5'
                        count    = 0
                        is_valid = abap_false ) ).
  ENDMETHOD.

  METHOD given_table_then_round_trip.
    DATA read_back TYPE measurements.
    DATA(original) = sample_measurements( ).

    DATA(csv) = zcl_csv=>for_table( original )->to_string( ).
    zcl_csv=>for_string( csv )->read_into( IMPORTING rows = read_back ).

    cl_abap_unit_assert=>assert_equals( act = read_back
                                        exp = original
                                        msg = 'A default round trip did not preserve the data' ).
  ENDMETHOD.

  METHOD given_dialect_then_round_trip.
    DATA read_back TYPE measurements.
    DATA(original) = sample_measurements( ).

    DATA(csv) = zcl_csv=>for_table( original
      )->with_delimiter( `;`
      )->with_quote( `'`
      )->with_line_break( CONV #( lth_document=>lf )
      )->to_string( ).

    zcl_csv=>for_string( csv
      )->with_delimiter( `;`
      )->with_quote( `'`
      )->read_into( IMPORTING rows = read_back ).

    cl_abap_unit_assert=>assert_equals( act = read_back
                                        exp = original
                                        msg = 'A round trip in a custom dialect did not preserve the data' ).
  ENDMETHOD.

  METHOD given_no_header_round_trip.
    DATA read_back TYPE measurements.
    DATA(original) = sample_measurements( ).

    DATA(csv) = zcl_csv=>for_table( original )->without_header( )->to_string( ).
    zcl_csv=>for_string( csv )->without_header( )->read_into( IMPORTING rows = read_back ).

    cl_abap_unit_assert=>assert_equals( act = read_back
                                        exp = original
                                        msg = 'A positional round trip did not preserve the data' ).
  ENDMETHOD.

  METHOD given_records_then_round_trip.
    DATA(original) = VALUE zif_csv_reader=>records( ( VALUE #( ( `a,b` ) ( `` ) ( `"q"` ) ) )
                                                    ( VALUE #( ( |x{ lth_document=>lf }y| ) ) ) ).

    DATA(csv) = zcl_csv=>for_records( original )->to_string( ).
    DATA(read_back) = zcl_csv=>for_string( csv )->read_records( ).

    cl_abap_unit_assert=>assert_equals( act = read_back
                                        exp = original
                                        msg = 'A raw records round trip did not preserve the fields' ).
  ENDMETHOD.

ENDCLASS.
