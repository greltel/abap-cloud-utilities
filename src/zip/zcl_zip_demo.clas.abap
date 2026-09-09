"! <p class="shorttext synchronized" lang="EN">ZIP utility demo</p>
"! Runnable showcase for {@link zcl_zip}. Start it with F9 in ADT.
CLASS zcl_zip_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS readme TYPE string VALUE `readme.txt`.
    CONSTANTS report TYPE string VALUE `data/report.csv`.
    CONSTANTS readme_text TYPE string VALUE `Built with ZCL_ZIP on ABAP Cloud. `.
    CONSTANTS report_header TYPE string VALUE `id;name;amount`.
    CONSTANTS report_line TYPE string VALUE `4711;Keyboard;49.90`.
    CONSTANTS repetitions TYPE i VALUE 50.
    CONSTANTS not_an_archive TYPE xstring VALUE 'DEADBEEF'.

    METHODS build_archive
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_zip.

    METHODS show_entries
      IMPORTING out     TYPE REF TO if_oo_adt_classrun_out
                archive TYPE REF TO zif_zip_archive.

    METHODS show_extraction
      IMPORTING out     TYPE REF TO if_oo_adt_classrun_out
                archive TYPE REF TO zif_zip_archive
      RAISING   zcx_zip.

    METHODS show_gzip
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_zip.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS as_yes_no
      IMPORTING flag          TYPE abap_bool
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_zip_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(archive) = zcl_zip=>open( build_archive( ) ).

        show_entries( out     = out
                      archive = archive ).
        show_extraction( out     = out
                         archive = archive ).
        show_gzip( out ).
        show_rejected_input( out ).
      CATCH zcx_zip INTO DATA(error).
        out->write( |ZIP demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD build_archive.
    DATA(report_text) = |{ report_header }{ cl_abap_char_utilities=>newline }{ report_line }|.

    result = zcl_zip=>builder( )->with_timestamp( date = '20240102'
                                                  time = '101112'
                               )->add_text( name = readme
                                            text = readme_text
                               )->add_text( name = report
                                            text = report_text
                               )->build( ).
  ENDMETHOD.

  METHOD show_entries.
    out->write( `--- Entries ---` ).
    out->write( |Count      : { archive->entry_count( ) }| ).

    LOOP AT archive->entries( ) INTO DATA(entry).
      out->write( |{ entry-name WIDTH = 20 } { entry-size WIDTH = 6 ALIGN = RIGHT } bytes | &&
                  |{ entry-date DATE = ISO } { entry-time TIME = ISO }| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD show_extraction.
    out->write( `--- Extraction ---` ).
    out->write( |Has readme : { as_yes_no( archive->has( readme ) ) }| ).
    out->write( |Readme     : { archive->extract_text( readme ) }| ).
    out->write( |Report     : { xstrlen( archive->extract( report ) ) } bytes| ).
    out->write( |Report text: { archive->extract_text( report ) }| ).
    out->write( |Files      : { lines( archive->extract_all( ) ) }| ).
  ENDMETHOD.

  METHOD show_gzip.
    DATA(codec) = zcl_zip=>gzip( )->with_level( zcl_zip=>level-best ).
    DATA(text) = repeat( val = readme_text
                         occ = repetitions ).
    DATA(gzip) = codec->compress_text( text ).
    DATA(is_restored) = xsdbool( codec->decompress_text( gzip ) = text ).

    out->write( `--- GZIP ---` ).
    out->write( |Original   : { strlen( text ) } characters| ).
    out->write( |Compressed : { xstrlen( gzip ) } bytes| ).
    out->write( |Signature  : { as_yes_no( codec->is_gzip( gzip ) ) }| ).
    out->write( |Restored   : { as_yes_no( is_restored ) }| ).
  ENDMETHOD.

  METHOD show_rejected_input.
    out->write( `--- Rejected input ---` ).

    TRY.
        zcl_zip=>builder( )->add_text( name = readme
                                       text = readme_text
                          )->add_text( name = readme
                                       text = readme_text
                          )->build( ).

        out->write( `A duplicate entry name was unexpectedly accepted` ).
      CATCH zcx_zip INTO DATA(duplicate).
        out->write( |Rejected as expected: { duplicate->get_text( ) }| ).
    ENDTRY.

    TRY.
        zcl_zip=>open( not_an_archive ).

        out->write( `Bytes that are no archive were unexpectedly opened` ).
      CATCH zcx_zip INTO DATA(garbage).
        out->write( |Rejected as expected: { garbage->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD as_yes_no.
    result = COND string( WHEN flag = abap_true THEN `yes`
                          ELSE `no` ).
  ENDMETHOD.

ENDCLASS.
