*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
"! Wraps the released ZIP and GZIP kernel classes. Every call into the kernel
"! ends here, so the classic exceptions of CL_ABAP_ZIP and the dynamic ones
"! of CL_ABAP_GZIP are turned into {@link zcx_zip} in one place.
CLASS lcl_engine DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS new_archive
      RETURNING VALUE(result) TYPE REF TO cl_abap_zip.

    CLASS-METHODS load
      IMPORTING archive       TYPE xstring
      RETURNING VALUE(result) TYPE REF TO cl_abap_zip
      RAISING   zcx_zip.

    CLASS-METHODS extract
      IMPORTING zip           TYPE REF TO cl_abap_zip
                name          TYPE string
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_zip.

    CLASS-METHODS compress
      IMPORTING bytes         TYPE xstring
                level         TYPE i
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_zip.

    CLASS-METHODS decompress
      IMPORTING gzip          TYPE xstring
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_zip.

    CLASS-METHODS text_to_bytes
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE xstring
      RAISING   zcx_zip.

    CLASS-METHODS bytes_to_text
      IMPORTING bytes         TYPE xstring
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_zip.

    CLASS-METHODS is_valid_level
      IMPORTING level         TYPE i
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS is_zip_archive
      IMPORTING bytes         TYPE xstring
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS has_gzip_signature
      IMPORTING bytes         TYPE xstring
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    "! The two magic bytes every GZIP stream starts with (RFC 1952).
    CONSTANTS gzip_signature TYPE xstring VALUE '1F8B'.
    "! Signature of the end-of-central-directory record every ZIP archive,
    "! even an empty one, ends with. The kernel loader accepts bytes without
    "! it and reports zero entries, so the archive is checked here first.
    CONSTANTS zip_end_signature TYPE xstring VALUE '504B0506'.
    CONSTANTS rc_ok TYPE i VALUE 0.
    CONSTANTS rc_unknown_entry TYPE i VALUE 1.

ENDCLASS.


"! Read-only view on a loaded archive.
CLASS lcl_archive DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_zip_archive.

    METHODS constructor
      IMPORTING zip TYPE REF TO cl_abap_zip.

  PRIVATE SECTION.
    "! Matches a name that ends with the path separator - a folder entry.
    CONSTANTS folder_pattern TYPE string VALUE `*/`.

    DATA zip TYPE REF TO cl_abap_zip.
    DATA entries TYPE zif_zip_archive=>entry_table.

    METHODS is_folder_name
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


"! Collects the entries for {@link zif_zip_builder}. Mistakes are remembered -
"! the first one wins - and reported by build( ), which is the only method of
"! the chain that raises.
CLASS lcl_builder DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_zip_builder.

    METHODS constructor.

  PRIVATE SECTION.
    TYPES name_set TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.

    CONSTANTS path_separator TYPE string VALUE `/`.
    CONSTANTS windows_separator TYPE string VALUE `\`.
    CONSTANTS parent_segment TYPE string VALUE `..`.
    "! Matches a name that ends with the path separator.
    CONSTANTS folder_pattern TYPE string VALUE `*/`.
    "! The MS-DOS date the ZIP format stores counts from 1980.
    CONSTANTS earliest_date TYPE d VALUE '19800101'.

    DATA zip TYPE REF TO cl_abap_zip.
    DATA level TYPE i.
    DATA timestamp TYPE cl_abap_zip=>t_file_timestamp.
    DATA used_names TYPE name_set.
    DATA first_error TYPE string.

    METHODS remember
      IMPORTING error TYPE string.

    METHODS normalised_name
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE string.

    METHODS rejection_for
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE string.

    METHODS has_parent_segment
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS add_to_kernel
      IMPORTING name    TYPE string
                content TYPE xstring.

ENDCLASS.


"! Immutable GZIP codec with a fixed compression level.
CLASS lcl_gzip DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_gzip.

    METHODS constructor
      IMPORTING level TYPE i.

  PRIVATE SECTION.
    DATA level TYPE i.

ENDCLASS.


CLASS lcl_engine IMPLEMENTATION.

  METHOD new_archive.
    result = NEW cl_abap_zip( ).
    " UTF-8 names with the corresponding header flag are what current archivers
    " read and write; the kernel default encodes names in the legacy DOS code page.
    result->support_unicode_names = abap_true.
  ENDMETHOD.

  METHOD load.
    IF is_zip_archive( archive ) = abap_false.
      RAISE EXCEPTION NEW zcx_zip( text = `The bytes are not a ZIP archive` ).
    ENDIF.

    result = new_archive( ).
    result->load( EXPORTING zip              = archive
                  EXCEPTIONS zip_parse_error = 1
                             OTHERS          = 2 ).
    IF sy-subrc <> rc_ok.
      RAISE EXCEPTION NEW zcx_zip( text = `The bytes are not a ZIP archive` ).
    ENDIF.
  ENDMETHOD.

  METHOD is_zip_archive.
    FIND FIRST OCCURRENCE OF zip_end_signature IN bytes IN BYTE MODE.

    result = xsdbool( sy-subrc = rc_ok ).
  ENDMETHOD.

  METHOD extract.
    zip->get( EXPORTING name                     = name
              IMPORTING content                  = result
              EXCEPTIONS zip_index_error         = 1
                         zip_decompression_error = 2
                         OTHERS                  = 3 ).
    IF sy-subrc = rc_unknown_entry.
      RAISE EXCEPTION NEW zcx_zip( text = |The archive has no entry named "{ name }"| ).
    ENDIF.
    IF sy-subrc <> rc_ok.
      RAISE EXCEPTION NEW zcx_zip( text = |Entry "{ name }" cannot be decompressed, its data is corrupt| ).
    ENDIF.
  ENDMETHOD.

  METHOD compress.
    " Only the _with_header variants read and write the RFC 1952 header; the
    " plain compress_binary emits a bare deflate stream that gzip tools reject.
    TRY.
        cl_abap_gzip=>compress_binary_with_header( EXPORTING raw_in         = bytes
                                                             compress_level = level
                                                   IMPORTING gzip_out       = result ).
      CATCH cx_parameter_invalid_range cx_sy_buffer_overflow cx_sy_compression_error INTO DATA(failure).
        RAISE EXCEPTION NEW zcx_zip( text     = `The bytes cannot be compressed`
                                     previous = failure ).
    ENDTRY.
  ENDMETHOD.

  METHOD decompress.
    IF has_gzip_signature( gzip ) = abap_false.
      RAISE EXCEPTION NEW zcx_zip( text = `The bytes are not a GZIP stream` ).
    ENDIF.

    TRY.
        cl_abap_gzip=>decompress_binary_with_header( EXPORTING gzip_in = gzip
                                                     IMPORTING raw_out = result ).
      CATCH cx_parameter_invalid cx_sy_buffer_overflow cx_sy_compression_error INTO DATA(failure).
        RAISE EXCEPTION NEW zcx_zip( text     = `The GZIP stream is corrupt`
                                     previous = failure ).
    ENDTRY.
  ENDMETHOD.

  METHOD text_to_bytes.
    TRY.
        result = cl_abap_conv_codepage=>create_out( )->convert( text ).
      CATCH cx_parameter_invalid_range cx_sy_conversion_codepage INTO DATA(encoding_error).
        RAISE EXCEPTION NEW zcx_zip( text     = `The text cannot be encoded as UTF-8`
                                     previous = encoding_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD bytes_to_text.
    TRY.
        result = cl_abap_conv_codepage=>create_in( )->convert( bytes ).
      CATCH cx_parameter_invalid_range cx_sy_conversion_codepage INTO DATA(decoding_error).
        RAISE EXCEPTION NEW zcx_zip( text     = `The bytes are not UTF-8 text`
                                     previous = decoding_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD is_valid_level.
    result = xsdbool( level >= zcl_zip=>level-stored AND level <= zcl_zip=>level-best ).
  ENDMETHOD.

  METHOD has_gzip_signature.
    DATA(signature_length) = xstrlen( gzip_signature ).

    IF xstrlen( bytes ) < signature_length.
      result = abap_false.
      RETURN.
    ENDIF.

    DATA(head) = bytes(signature_length).
    result = xsdbool( head = gzip_signature ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_archive IMPLEMENTATION.

  METHOD constructor.
    me->zip = zip.
    entries = VALUE #( FOR kernel_entry IN zip->files
                       ( name      = kernel_entry-name
                         size      = kernel_entry-size
                         date      = kernel_entry-date
                         time      = kernel_entry-time
                         is_folder = is_folder_name( kernel_entry-name ) ) ).
  ENDMETHOD.

  METHOD is_folder_name.
    result = xsdbool( name CP folder_pattern ).
  ENDMETHOD.

  METHOD zif_zip_archive~entry_count.
    result = lines( entries ).
  ENDMETHOD.

  METHOD zif_zip_archive~entries.
    result = entries.
  ENDMETHOD.

  METHOD zif_zip_archive~names.
    result = VALUE #( FOR entry IN entries
                      ( entry-name ) ).
  ENDMETHOD.

  METHOD zif_zip_archive~has.
    result = xsdbool( line_exists( entries[ name = name ] ) ).
  ENDMETHOD.

  METHOD zif_zip_archive~entry.
    IF zif_zip_archive~has( name ) = abap_false.
      RAISE EXCEPTION NEW zcx_zip( text = |The archive has no entry named "{ name }"| ).
    ENDIF.

    result = entries[ name = name ].
  ENDMETHOD.

  METHOD zif_zip_archive~extract.
    result = lcl_engine=>extract( zip  = zip
                                  name = name ).
  ENDMETHOD.

  METHOD zif_zip_archive~extract_text.
    result = lcl_engine=>bytes_to_text( zif_zip_archive~extract( name ) ).
  ENDMETHOD.

  METHOD zif_zip_archive~extract_all.
    LOOP AT entries INTO DATA(entry) WHERE is_folder = abap_false.
      INSERT VALUE #( name    = entry-name
                      content = zif_zip_archive~extract( entry-name ) ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_builder IMPLEMENTATION.

  METHOD constructor.
    zip = lcl_engine=>new_archive( ).
    level = zcl_zip=>level-normal.
  ENDMETHOD.

  METHOD zif_zip_builder~add.
    self = me.

    DATA(entry_name) = normalised_name( name ).
    DATA(rejection) = rejection_for( entry_name ).
    IF rejection IS NOT INITIAL.
      remember( rejection ).
      RETURN.
    ENDIF.

    INSERT entry_name INTO TABLE used_names.
    add_to_kernel( name    = entry_name
                   content = content ).
  ENDMETHOD.

  METHOD zif_zip_builder~add_text.
    TRY.
        self = zif_zip_builder~add( name    = name
                                    content = lcl_engine=>text_to_bytes( text ) ).
      CATCH zcx_zip INTO DATA(encoding_error).
        self = me.
        remember( |Entry "{ name }": { encoding_error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_zip_builder~with_level.
    self = me.

    IF lcl_engine=>is_valid_level( level ) = abap_false.
      remember( |Compression level { level } is not supported, use 0 to 9| ).
      RETURN.
    ENDIF.

    me->level = level.
  ENDMETHOD.

  METHOD zif_zip_builder~with_timestamp.
    self = me.

    IF date < earliest_date.
      remember( |A ZIP entry cannot be dated { date }, the format starts at 1980-01-01| ).
      RETURN.
    ENDIF.

    timestamp = VALUE #( date = date
                         time = time ).
  ENDMETHOD.

  METHOD zif_zip_builder~build.
    IF first_error IS NOT INITIAL.
      RAISE EXCEPTION NEW zcx_zip( text = first_error ).
    ENDIF.

    IF used_names IS INITIAL.
      RAISE EXCEPTION NEW zcx_zip( text = `The archive has no entries - add one with add( ) or add_text( )` ).
    ENDIF.

    result = zip->save( ).
  ENDMETHOD.

  METHOD remember.
    IF first_error IS INITIAL.
      first_error = error.
    ENDIF.
  ENDMETHOD.

  METHOD normalised_name.
    DATA(with_slashes) = replace( val  = name
                                  sub  = windows_separator
                                  with = path_separator
                                  occ  = 0 ).

    result = shift_left( val = with_slashes
                         sub = path_separator ).
  ENDMETHOD.

  METHOD rejection_for.
    IF name IS INITIAL.
      result = `An entry needs a name`.
    ELSEIF name CP folder_pattern.
      result = |Entry name "{ name }" must not end with a slash|.
    ELSEIF has_parent_segment( name ) = abap_true.
      result = |Entry name "{ name }" must not contain a .. segment|.
    ELSEIF line_exists( used_names[ table_line = name ] ).
      result = |Entry name "{ name }" is added twice|.
    ENDIF.
  ENDMETHOD.

  METHOD has_parent_segment.
    SPLIT name AT path_separator INTO TABLE DATA(segments).

    result = xsdbool( line_exists( segments[ table_line = parent_segment ] ) ).
  ENDMETHOD.

  METHOD add_to_kernel.
    IF timestamp IS INITIAL.
      zip->add( name           = name
                content        = content
                compress_level = level ).
    ELSE.
      zip->add( name           = name
                content        = content
                compress_level = level
                file_timestamp = timestamp ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_gzip IMPLEMENTATION.

  METHOD constructor.
    me->level = level.
  ENDMETHOD.

  METHOD zif_gzip~with_level.
    IF lcl_engine=>is_valid_level( level ) = abap_false.
      RAISE EXCEPTION NEW zcx_zip( text = |Compression level { level } is not supported, use 0 to 9| ).
    ENDIF.

    result = NEW lcl_gzip( level ).
  ENDMETHOD.

  METHOD zif_gzip~compress.
    result = lcl_engine=>compress( bytes = bytes
                                   level = level ).
  ENDMETHOD.

  METHOD zif_gzip~compress_text.
    result = zif_gzip~compress( lcl_engine=>text_to_bytes( text ) ).
  ENDMETHOD.

  METHOD zif_gzip~decompress.
    result = lcl_engine=>decompress( gzip ).
  ENDMETHOD.

  METHOD zif_gzip~decompress_text.
    result = lcl_engine=>bytes_to_text( zif_gzip~decompress( gzip ) ).
  ENDMETHOD.

  METHOD zif_gzip~is_gzip.
    result = lcl_engine=>has_gzip_signature( bytes ).
  ENDMETHOD.

ENDCLASS.
