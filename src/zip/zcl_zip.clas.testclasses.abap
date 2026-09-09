*"* use this source file for your ABAP unit test classes
CLASS ltc_builder DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS readme TYPE string VALUE `readme.txt`.
    CONSTANTS report TYPE string VALUE `data/report.csv`.
    CONSTANTS greeting TYPE string VALUE `Hello, ZIP`.
    CONSTANTS payload TYPE xstring VALUE '00FF10FE'.
    CONSTANTS e_acute_utf8 TYPE xstring VALUE 'C3A9'.

    METHODS given_two_entries_then_listed FOR TESTING RAISING cx_static_check.
    METHODS given_text_then_extract_same FOR TESTING RAISING cx_static_check.
    METHODS given_bytes_then_extract_same FOR TESTING RAISING cx_static_check.
    METHODS given_empty_text_then_size_0 FOR TESTING RAISING cx_static_check.
    METHODS given_backslash_then_slash FOR TESTING RAISING cx_static_check.
    METHODS given_leading_slash_then_cut FOR TESTING RAISING cx_static_check.
    METHODS given_stored_level_then_same FOR TESTING RAISING cx_static_check.
    METHODS given_timestamp_then_dated FOR TESTING RAISING cx_static_check.
    METHODS given_non_ascii_then_utf8 FOR TESTING RAISING cx_static_check.
    METHODS given_duplicate_then_raises FOR TESTING.
    METHODS given_empty_name_then_raises FOR TESTING.
    METHODS given_folder_name_then_raises FOR TESTING.
    METHODS given_parent_seg_then_raises FOR TESTING.
    METHODS given_bad_level_then_raises FOR TESTING.
    METHODS given_old_date_then_raises FOR TESTING.
    METHODS given_no_entries_then_raises FOR TESTING.
    METHODS given_two_errors_then_first FOR TESTING.

    METHODS failure_of
      IMPORTING builder       TYPE REF TO zif_zip_builder
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS ltc_builder IMPLEMENTATION.

  METHOD given_two_entries_then_listed.
    DATA(archive) = zcl_zip=>builder( )->add_text( name = readme
                                                   text = greeting
                                      )->add( name    = report
                                              content = payload
                                      )->build( ).

    DATA(names) = zcl_zip=>open( archive )->names( ).

    cl_abap_unit_assert=>assert_equals(
      act = names
      exp = VALUE zif_zip_archive=>name_table( ( readme ) ( report ) )
      msg = 'The entries are not listed in the order they were added' ).
  ENDMETHOD.

  METHOD given_text_then_extract_same.
    DATA(archive) = zcl_zip=>builder( )->add_text( name = readme
                                                   text = greeting
                                      )->build( ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_zip=>open( archive )->extract_text( readme )
      exp = greeting
      msg = 'A text entry does not survive the round trip' ).
  ENDMETHOD.

  METHOD given_bytes_then_extract_same.
    DATA(archive) = zcl_zip=>builder( )->add( name    = report
                                              content = payload
                                      )->build( ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_zip=>open( archive )->extract( report )
      exp = payload
      msg = 'A binary entry does not survive the round trip' ).
  ENDMETHOD.

  METHOD given_empty_text_then_size_0.
    DATA(archive) = zcl_zip=>builder( )->add_text( name = readme
                                                   text = ``
                                      )->build( ).

    DATA(entry) = zcl_zip=>open( archive )->entry( readme ).

    cl_abap_unit_assert=>assert_equals(
      act = entry-size
      exp = 0
      msg = 'An empty entry does not report size zero' ).
  ENDMETHOD.

  METHOD given_backslash_then_slash.
    DATA(archive) = zcl_zip=>builder( )->add( name    = `data\report.csv`
                                              content = payload
                                      )->build( ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_zip=>open( archive )->has( report )
      exp = abap_true
      msg = 'A backslash in the entry name is not turned into a slash' ).
  ENDMETHOD.

  METHOD given_leading_slash_then_cut.
    DATA(archive) = zcl_zip=>builder( )->add( name    = `/data/report.csv`
                                              content = payload
                                      )->build( ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_zip=>open( archive )->has( report )
      exp = abap_true
      msg = 'A leading slash in the entry name is not dropped' ).
  ENDMETHOD.

  METHOD given_stored_level_then_same.
    DATA(archive) = zcl_zip=>builder( )->with_level( zcl_zip=>level-stored
                                      )->add( name    = report
                                              content = payload
                                      )->build( ).

    DATA(opened) = zcl_zip=>open( archive ).

    cl_abap_unit_assert=>assert_equals(
      act = opened->extract( report )
      exp = payload
      msg = 'A stored entry does not survive the round trip' ).
    cl_abap_unit_assert=>assert_equals(
      act = opened->entry( report )-size
      exp = xstrlen( payload )
      msg = 'A stored entry does not report its uncompressed size' ).
  ENDMETHOD.

  METHOD given_timestamp_then_dated.
    DATA(archive) = zcl_zip=>builder( )->with_timestamp( date = '20240102'
                                                         time = '101112'
                                      )->add_text( name = readme
                                                   text = greeting
                                      )->build( ).

    DATA(entry) = zcl_zip=>open( archive )->entry( readme ).

    cl_abap_unit_assert=>assert_equals(
      act = entry-date
      exp = CONV d( '20240102' )
      msg = 'The entry does not carry the given date' ).
    cl_abap_unit_assert=>assert_equals(
      act = entry-time
      exp = CONV t( '101112' )
      msg = 'The entry does not carry the given time' ).
  ENDMETHOD.

  METHOD given_non_ascii_then_utf8.
    DATA(e_acute) = cl_abap_conv_codepage=>create_in( )->convert( e_acute_utf8 ).

    DATA(archive) = zcl_zip=>builder( )->add_text( name = readme
                                                   text = e_acute
                                      )->build( ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_zip=>open( archive )->extract( readme )
      exp = e_acute_utf8
      msg = 'A text entry is not stored as UTF-8' ).
  ENDMETHOD.

  METHOD given_duplicate_then_raises.
    DATA(builder) = zcl_zip=>builder( )->add_text( name = readme
                                                   text = greeting
                                      )->add( name    = readme
                                              content = payload ).

    cl_abap_unit_assert=>assert_not_initial(
      act = failure_of( builder )
      msg = 'Two entries with the same name are accepted' ).
  ENDMETHOD.

  METHOD given_empty_name_then_raises.
    DATA(builder) = zcl_zip=>builder( )->add( name    = ``
                                              content = payload ).

    cl_abap_unit_assert=>assert_not_initial(
      act = failure_of( builder )
      msg = 'An entry without a name is accepted' ).
  ENDMETHOD.

  METHOD given_folder_name_then_raises.
    DATA(builder) = zcl_zip=>builder( )->add( name    = `data/`
                                              content = payload ).

    cl_abap_unit_assert=>assert_not_initial(
      act = failure_of( builder )
      msg = 'An entry named like a folder is accepted' ).
  ENDMETHOD.

  METHOD given_parent_seg_then_raises.
    DATA(builder) = zcl_zip=>builder( )->add( name    = `data/../etc/passwd`
                                              content = payload ).

    cl_abap_unit_assert=>assert_not_initial(
      act = failure_of( builder )
      msg = 'An entry name with a .. segment is accepted' ).
  ENDMETHOD.

  METHOD given_bad_level_then_raises.
    DATA(builder) = zcl_zip=>builder( )->with_level( 10 ).
    builder->add( name    = report
                  content = payload ).

    cl_abap_unit_assert=>assert_not_initial(
      act = failure_of( builder )
      msg = 'A compression level above 9 is accepted' ).
  ENDMETHOD.

  METHOD given_old_date_then_raises.
    DATA(builder) = zcl_zip=>builder( )->with_timestamp( date = '19791231'
                                                         time = '000000'
                                      )->add( name    = report
                                              content = payload ).

    cl_abap_unit_assert=>assert_not_initial(
      act = failure_of( builder )
      msg = 'A date before 1980 is accepted although the format cannot store it' ).
  ENDMETHOD.

  METHOD given_no_entries_then_raises.
    cl_abap_unit_assert=>assert_not_initial(
      act = failure_of( zcl_zip=>builder( ) )
      msg = 'An archive without entries is built' ).
  ENDMETHOD.

  METHOD given_two_errors_then_first.
    DATA(builder) = zcl_zip=>builder( )->add( name    = ``
                                              content = payload
                                      )->with_level( 10 ).

    cl_abap_unit_assert=>assert_equals(
      act = failure_of( builder )
      exp = `An entry needs a name`
      msg = 'build( ) does not report the first mistake of the chain' ).
  ENDMETHOD.

  METHOD failure_of.
    TRY.
        builder->build( ).

        cl_abap_unit_assert=>fail( 'build( ) was expected to raise ZCX_ZIP' ).
      CATCH zcx_zip INTO DATA(failure).
        result = failure->get_text( ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_archive DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS readme TYPE string VALUE `readme.txt`.
    CONSTANTS report TYPE string VALUE `data/report.csv`.
    CONSTANTS folder TYPE string VALUE `docs/`.
    CONSTANTS greeting TYPE string VALUE `Hello, ZIP`.
    CONSTANTS payload TYPE xstring VALUE '00FF10FE'.

    DATA archive TYPE REF TO zif_zip_archive.

    METHODS setup RAISING cx_static_check.

    METHODS given_garbage_when_open_raise FOR TESTING.
    METHODS given_empty_when_open_raise FOR TESTING.
    METHODS extract_unknown_then_raises FOR TESTING.
    METHODS given_unknown_when_entry_raise FOR TESTING.
    METHODS given_known_name_then_has FOR TESTING.
    METHODS given_unknown_name_then_no_has FOR TESTING.
    METHODS given_other_case_then_has_not FOR TESTING.
    METHODS when_entry_count_then_two FOR TESTING.
    METHODS when_entries_then_order FOR TESTING.
    METHODS when_entry_then_text_size FOR TESTING RAISING cx_static_check.
    METHODS when_extract_all_then_files FOR TESTING RAISING cx_static_check.
    METHODS given_folder_then_flagged FOR TESTING RAISING cx_static_check.
    METHODS given_folder_then_not_in_files FOR TESTING RAISING cx_static_check.

    METHODS with_folder_entry
      RETURNING VALUE(result) TYPE REF TO zif_zip_archive
      RAISING   zcx_zip.

ENDCLASS.


CLASS ltc_archive IMPLEMENTATION.

  METHOD setup.
    archive = zcl_zip=>open( zcl_zip=>builder( )->add_text( name = readme
                                                            text = greeting
                                               )->add( name    = report
                                                       content = payload
                                               )->build( ) ).
  ENDMETHOD.

  METHOD given_garbage_when_open_raise.
    TRY.
        zcl_zip=>open( payload ).

        cl_abap_unit_assert=>fail( 'Bytes that are no ZIP archive were opened' ).
      CATCH zcx_zip.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD given_empty_when_open_raise.
    TRY.
        zcl_zip=>open( VALUE xstring( ) ).

        cl_abap_unit_assert=>fail( 'An empty byte string was opened as ZIP archive' ).
      CATCH zcx_zip.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD extract_unknown_then_raises.
    TRY.
        archive->extract( `missing.txt` ).

        cl_abap_unit_assert=>fail( 'Extracting an unknown entry did not raise' ).
      CATCH zcx_zip.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD given_unknown_when_entry_raise.
    TRY.
        archive->entry( `missing.txt` ).

        cl_abap_unit_assert=>fail( 'Reading an unknown entry did not raise' ).
      CATCH zcx_zip.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD given_known_name_then_has.
    cl_abap_unit_assert=>assert_equals(
      act = archive->has( report )
      exp = abap_true
      msg = 'An existing entry is not found by name' ).
  ENDMETHOD.

  METHOD given_unknown_name_then_no_has.
    cl_abap_unit_assert=>assert_equals(
      act = archive->has( `missing.txt` )
      exp = abap_false
      msg = 'A missing entry is reported as present' ).
  ENDMETHOD.

  METHOD given_other_case_then_has_not.
    cl_abap_unit_assert=>assert_equals(
      act = archive->has( to_upper( readme ) )
      exp = abap_false
      msg = 'Entry names are not matched case sensitively' ).
  ENDMETHOD.

  METHOD when_entry_count_then_two.
    cl_abap_unit_assert=>assert_equals(
      act = archive->entry_count( )
      exp = 2
      msg = 'The entry count does not match the entries added' ).
  ENDMETHOD.

  METHOD when_entries_then_order.
    DATA(entries) = archive->entries( ).

    cl_abap_unit_assert=>assert_equals(
      act = entries[ 1 ]-name
      exp = readme
      msg = 'The first entry is not the first one added' ).
    cl_abap_unit_assert=>assert_equals(
      act = entries[ 2 ]-name
      exp = report
      msg = 'The second entry is not the second one added' ).
  ENDMETHOD.

  METHOD when_entry_then_text_size.
    DATA(entry) = archive->entry( readme ).

    cl_abap_unit_assert=>assert_equals(
      act = entry-size
      exp = strlen( greeting )
      msg = 'The size of an ASCII text entry is not its character count' ).
    cl_abap_unit_assert=>assert_equals(
      act = entry-is_folder
      exp = abap_false
      msg = 'A file entry is flagged as folder' ).
  ENDMETHOD.

  METHOD when_extract_all_then_files.
    DATA(files) = archive->extract_all( ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( files )
      exp = 2
      msg = 'extract_all( ) does not return every file' ).
    cl_abap_unit_assert=>assert_equals(
      act = files[ 2 ]
      exp = VALUE zif_zip_archive=>zip_file( name    = report
                                             content = payload )
      msg = 'extract_all( ) returns wrong content for an entry' ).
  ENDMETHOD.

  METHOD given_folder_then_flagged.
    DATA(entry) = with_folder_entry( )->entry( folder ).

    cl_abap_unit_assert=>assert_equals(
      act = entry-is_folder
      exp = abap_true
      msg = 'An entry whose name ends with a slash is not flagged as folder' ).
  ENDMETHOD.

  METHOD given_folder_then_not_in_files.
    DATA(files) = with_folder_entry( )->extract_all( ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( files )
      exp = 1
      msg = 'extract_all( ) does not skip folder entries' ).
    cl_abap_unit_assert=>assert_equals(
      act = files[ 1 ]-name
      exp = readme
      msg = 'extract_all( ) skips the wrong entry' ).
  ENDMETHOD.

  METHOD with_folder_entry.
    " The builder refuses folder entries; a foreign archiver writes them, so
    " the kernel class is used directly to produce one.
    DATA(kernel) = NEW cl_abap_zip( ).
    kernel->add( name    = folder
                 content = VALUE xstring( ) ).
    kernel->add( name    = readme
                 content = payload ).

    result = zcl_zip=>open( kernel->save( ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_gzip DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS greeting TYPE string VALUE `Hello, GZIP`.
    CONSTANTS payload TYPE xstring VALUE '00FF10FE'.
    CONSTANTS e_acute_utf8 TYPE xstring VALUE 'C3A9'.
    CONSTANTS gzip_signature TYPE xstring VALUE '1F8B'.
    CONSTANTS repetitions TYPE i VALUE 100.

    METHODS when_bytes_roundtrip_then_same FOR TESTING RAISING cx_static_check.
    METHODS when_text_roundtrip_then_same FOR TESTING RAISING cx_static_check.
    METHODS when_empty_roundtrip_then_same FOR TESTING RAISING cx_static_check.
    METHODS when_compress_then_signature FOR TESTING RAISING cx_static_check.
    METHODS given_repetitive_then_smaller FOR TESTING RAISING cx_static_check.
    METHODS given_non_ascii_then_utf8 FOR TESTING RAISING cx_static_check.
    METHODS given_best_level_then_same FOR TESTING RAISING cx_static_check.
    METHODS given_stored_level_then_same FOR TESTING RAISING cx_static_check.
    METHODS inflate_garbage_then_raises FOR TESTING.
    METHODS given_empty_when_inflate_raise FOR TESTING.
    METHODS inflate_corrupt_then_raises FOR TESTING.
    METHODS given_level_ten_then_raises FOR TESTING.
    METHODS given_level_minus_1_then_raise FOR TESTING.
    METHODS given_signature_then_is_gzip FOR TESTING.
    METHODS given_no_signature_then_false FOR TESTING.

    METHODS assert_inflate_raises
      IMPORTING gzip TYPE xstring.

ENDCLASS.


CLASS ltc_gzip IMPLEMENTATION.

  METHOD when_bytes_roundtrip_then_same.
    DATA(codec) = zcl_zip=>gzip( ).

    cl_abap_unit_assert=>assert_equals(
      act = codec->decompress( codec->compress( payload ) )
      exp = payload
      msg = 'Bytes do not survive the GZIP round trip' ).
  ENDMETHOD.

  METHOD when_text_roundtrip_then_same.
    DATA(codec) = zcl_zip=>gzip( ).

    cl_abap_unit_assert=>assert_equals(
      act = codec->decompress_text( codec->compress_text( greeting ) )
      exp = greeting
      msg = 'Text does not survive the GZIP round trip' ).
  ENDMETHOD.

  METHOD when_empty_roundtrip_then_same.
    DATA(codec) = zcl_zip=>gzip( ).

    cl_abap_unit_assert=>assert_initial(
      act = codec->decompress( codec->compress( VALUE xstring( ) ) )
      msg = 'Empty bytes do not survive the GZIP round trip' ).
  ENDMETHOD.

  METHOD when_compress_then_signature.
    DATA(gzip) = zcl_zip=>gzip( )->compress( payload ).

    cl_abap_unit_assert=>assert_equals(
      act = zcl_zip=>gzip( )->is_gzip( gzip )
      exp = abap_true
      msg = 'A compressed stream does not start with the GZIP signature' ).
  ENDMETHOD.

  METHOD given_repetitive_then_smaller.
    DATA(text) = repeat( val = greeting
                         occ = repetitions ).

    DATA(gzip) = zcl_zip=>gzip( )->compress_text( text ).

    cl_abap_unit_assert=>assert_true(
      act = xsdbool( xstrlen( gzip ) < strlen( text ) )
      msg = 'Repetitive text is not compressed to fewer bytes' ).
  ENDMETHOD.

  METHOD given_non_ascii_then_utf8.
    DATA(e_acute) = cl_abap_conv_codepage=>create_in( )->convert( e_acute_utf8 ).
    DATA(codec) = zcl_zip=>gzip( ).

    cl_abap_unit_assert=>assert_equals(
      act = codec->decompress( codec->compress_text( e_acute ) )
      exp = e_acute_utf8
      msg = 'Text is not compressed through its UTF-8 encoding' ).
  ENDMETHOD.

  METHOD given_best_level_then_same.
    DATA(codec) = zcl_zip=>gzip( )->with_level( zcl_zip=>level-best ).

    cl_abap_unit_assert=>assert_equals(
      act = codec->decompress_text( codec->compress_text( greeting ) )
      exp = greeting
      msg = 'Text does not survive the round trip at the best level' ).
  ENDMETHOD.

  METHOD given_stored_level_then_same.
    DATA(codec) = zcl_zip=>gzip( )->with_level( zcl_zip=>level-stored ).

    cl_abap_unit_assert=>assert_equals(
      act = codec->decompress( codec->compress( payload ) )
      exp = payload
      msg = 'Bytes do not survive the round trip at the stored level' ).
  ENDMETHOD.

  METHOD inflate_garbage_then_raises.
    assert_inflate_raises( payload ).
  ENDMETHOD.

  METHOD given_empty_when_inflate_raise.
    assert_inflate_raises( VALUE xstring( ) ).
  ENDMETHOD.

  METHOD inflate_corrupt_then_raises.
    assert_inflate_raises( CONV xstring( |{ gzip_signature }{ payload }| ) ).
  ENDMETHOD.

  METHOD given_level_ten_then_raises.
    TRY.
        zcl_zip=>gzip( )->with_level( 10 ).

        cl_abap_unit_assert=>fail( 'A compression level above 9 was accepted' ).
      CATCH zcx_zip.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD given_level_minus_1_then_raise.
    TRY.
        zcl_zip=>gzip( )->with_level( -1 ).

        cl_abap_unit_assert=>fail( 'A negative compression level was accepted' ).
      CATCH zcx_zip.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD given_signature_then_is_gzip.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_zip=>gzip( )->is_gzip( gzip_signature )
      exp = abap_true
      msg = 'The GZIP signature is not recognised' ).
  ENDMETHOD.

  METHOD given_no_signature_then_false.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_zip=>gzip( )->is_gzip( payload )
      exp = abap_false
      msg = 'Bytes without the GZIP signature are taken for a stream' ).
  ENDMETHOD.

  METHOD assert_inflate_raises.
    TRY.
        zcl_zip=>gzip( )->decompress( gzip ).

        cl_abap_unit_assert=>fail( 'Decompressing invalid bytes did not raise' ).
      CATCH zcx_zip.
        RETURN.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
