"! <p class="shorttext synchronized" lang="EN">CSV utility demo</p>
"! Smoke test for {@link zcl_csv}: writes a table in two dialects, reads a
"! document back into a typed table, lists raw records and shows a rejected
"! document. Run with F9 in ADT.
CLASS zcl_csv_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    TYPES: BEGIN OF product,
             product_id TYPE string,
             name       TYPE string,
             price      TYPE p LENGTH 9 DECIMALS 2,
             stock      TYPE i,
           END OF product.
    TYPES products TYPE STANDARD TABLE OF product WITH EMPTY KEY.

    METHODS sample_products
      RETURNING VALUE(result) TYPE products.

    METHODS show_writing
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_csv.

    METHODS show_typed_reading
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_csv.

    METHODS show_raw_reading
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_csv.

    METHODS show_rejected_document
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

ENDCLASS.


CLASS zcl_csv_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_writing( out ).
        show_typed_reading( out ).
        show_raw_reading( out ).
        show_rejected_document( out ).
      CATCH zcx_csv INTO DATA(error).
        out->write( |CSV demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD sample_products.
    result = VALUE #( ( product_id = `K-1` name = `Keyboard, wireless` price = '49.90' stock = 12 )
                      ( product_id = `M-2` name = `Mouse "Pro"` price = '19.99' stock = 30 ) ).
  ENDMETHOD.

  METHOD show_writing.
    DATA(products) = sample_products( ).

    out->write( `Default dialect - comma, CRLF, header of component names:` ).
    out->write( zcl_csv=>for_table( products )->to_string( ) ).

    out->write( `Semicolon, LF and custom labels:` ).
    out->write( zcl_csv=>for_table( products
                  )->with_delimiter( `;`
                  )->with_line_break( CONV #( cl_abap_char_utilities=>newline )
                  )->with_labels( VALUE #( ( `Id` ) ( `Name` ) ( `Price` ) ( `Stock` ) )
                  )->to_string( ) ).
  ENDMETHOD.

  METHOD show_typed_reading.
    DATA products TYPE products.

    " Columns are matched by name, so their order and case do not matter
    DATA(document) = |name,PRODUCT_ID,price{ cl_abap_char_utilities=>cr_lf }| &&
                     |"Cable, USB-C",C-3,9.50{ cl_abap_char_utilities=>cr_lf }| &&
                     |Monitor,D-4,199.00{ cl_abap_char_utilities=>cr_lf }|.

    zcl_csv=>for_string( document )->read_into( IMPORTING rows = products ).

    out->write( |Read { lines( products ) } product(s) by header name:| ).
    out->write( products ).
  ENDMETHOD.

  METHOD show_raw_reading.
    DATA(document) = |Quarterly report{ cl_abap_char_utilities=>newline }| &&
                     |Q1,Q2,Q3,Q4{ cl_abap_char_utilities=>newline }| &&
                     |10,20,30,40|.

    DATA(records) = zcl_csv=>for_string( document )->read_records( ).

    out->write( |Read { lines( records ) } raw record(s) of varying width:| ).
    LOOP AT records INTO DATA(record).
      DATA(fields) = concat_lines_of( table = record
                                      sep   = ` | ` ).
      out->write( |  { lines( record ) } field(s): { fields }| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD show_rejected_document.
    TRY.
        zcl_csv=>for_string( `"unclosed,1` )->read_records( ).

        out->write( `An unclosed quote was unexpectedly accepted` ).
      CATCH zcx_csv INTO DATA(error).
        out->write( |Rejected as expected: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
