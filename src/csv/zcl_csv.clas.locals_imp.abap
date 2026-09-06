*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

"! Characters that shape a document. Only these two matter for reading -
"! line breaks are recognized in every form (CRLF, LF, CR).
TYPES: BEGIN OF dialect,
         delimiter TYPE string,
         quote     TYPE string,
       END OF dialect.


"! Defaults and validation of a dialect. Validation happens in the read and
"! write methods, so that the fluent configuration methods need not raise.
CLASS lcl_dialect DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS defaults
      RETURNING VALUE(result) TYPE dialect.

    CLASS-METHODS validate
      IMPORTING dialect TYPE dialect
      RAISING   zcx_csv.

  PRIVATE SECTION.
    CLASS-METHODS ensure_single_character
      IMPORTING value TYPE string
                role  TYPE string
      RAISING   zcx_csv.

ENDCLASS.


CLASS lcl_dialect IMPLEMENTATION.

  METHOD defaults.
    result = VALUE #( delimiter = `,`
                      quote     = `"` ).
  ENDMETHOD.

  METHOD validate.
    ensure_single_character( value = dialect-delimiter
                             role  = `delimiter` ).
    ensure_single_character( value = dialect-quote
                             role  = `quote character` ).

    IF dialect-delimiter = dialect-quote.
      RAISE EXCEPTION NEW zcx_csv( text = `The delimiter and the quote character must differ` ).
    ENDIF.
  ENDMETHOD.

  METHOD ensure_single_character.
    IF strlen( value ) <> 1.
      RAISE EXCEPTION NEW zcx_csv( text = |The { role } must be exactly one character, not "{ value }"| ).
    ENDIF.

    IF contains( val = cl_abap_char_utilities=>cr_lf
                 sub = value ).
      RAISE EXCEPTION NEW zcx_csv( text = |The { role } must not be a line break character| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


"! Line type of a table that is read or written: a structure whose components
"! are all elementary. Nested structures, tables and references have no CSV
"! representation and are rejected up front.
CLASS lcl_row_type DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS of_table
      IMPORTING rows          TYPE STANDARD TABLE
      RETURNING VALUE(result) TYPE REF TO lcl_row_type
      RAISING   zcx_csv.

    METHODS constructor
      IMPORTING names TYPE zif_csv_reader=>record.

    "! Component names in structure order, upper case as delivered by RTTI.
    METHODS component_names
      RETURNING VALUE(result) TYPE zif_csv_reader=>record.

    METHODS has_component
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! Every row of the table as one record of field texts, each formatted
    "! like in a string template.
    METHODS to_records
      IMPORTING rows          TYPE STANDARD TABLE
      RETURNING VALUE(result) TYPE zif_csv_reader=>records
      RAISING   zcx_csv.

  PRIVATE SECTION.
    TYPES typekinds TYPE STANDARD TABLE OF abap_typekind WITH EMPTY KEY.

    DATA names TYPE zif_csv_reader=>record.

    CLASS-METHODS structure_of
      IMPORTING rows          TYPE STANDARD TABLE
      RETURNING VALUE(result) TYPE REF TO cl_abap_structdescr
      RAISING   zcx_csv.

    CLASS-METHODS ensure_elementary
      IMPORTING components TYPE abap_compdescr_tab
      RAISING   zcx_csv.

    METHODS to_record
      IMPORTING row           TYPE any
      RETURNING VALUE(result) TYPE zif_csv_reader=>record
      RAISING   zcx_csv.

ENDCLASS.


CLASS lcl_row_type IMPLEMENTATION.

  METHOD of_table.
    DATA(structure) = structure_of( rows ).
    ensure_elementary( structure->components ).

    result = NEW #( VALUE #( FOR component IN structure->components ( CONV string( component-name ) ) ) ).
  ENDMETHOD.

  METHOD constructor.
    me->names = names.
  ENDMETHOD.

  METHOD component_names.
    result = names.
  ENDMETHOD.

  METHOD has_component.
    result = xsdbool( line_exists( names[ table_line = name ] ) ).
  ENDMETHOD.

  METHOD to_records.
    LOOP AT rows ASSIGNING FIELD-SYMBOL(<row>).
      INSERT to_record( <row> ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD structure_of.
    TRY.
        DATA(table_type) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( rows ) ).
        result = CAST cl_abap_structdescr( table_type->get_table_line_type( ) ).
      CATCH cx_sy_move_cast_error INTO DATA(cast_error).
        RAISE EXCEPTION NEW zcx_csv( text     = `The line type of the table must be a structure, not elementary`
                                     previous = cast_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD ensure_elementary.
    DATA(elementary) = VALUE typekinds(
      ( cl_abap_typedescr=>typekind_char )
      ( cl_abap_typedescr=>typekind_num )
      ( cl_abap_typedescr=>typekind_date )
      ( cl_abap_typedescr=>typekind_time )
      ( cl_abap_typedescr=>typekind_utclong )
      ( cl_abap_typedescr=>typekind_int )
      ( cl_abap_typedescr=>typekind_int1 )
      ( cl_abap_typedescr=>typekind_int2 )
      ( cl_abap_typedescr=>typekind_int8 )
      ( cl_abap_typedescr=>typekind_packed )
      ( cl_abap_typedescr=>typekind_float )
      ( cl_abap_typedescr=>typekind_decfloat16 )
      ( cl_abap_typedescr=>typekind_decfloat34 )
      ( cl_abap_typedescr=>typekind_hex )
      ( cl_abap_typedescr=>typekind_string )
      ( cl_abap_typedescr=>typekind_xstring ) ).

    LOOP AT components INTO DATA(component).
      IF NOT line_exists( elementary[ table_line = component-type_kind ] ).
        RAISE EXCEPTION NEW zcx_csv(
          text = |Component { component-name } is not elementary and has no CSV representation| ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD to_record.
    FIELD-SYMBOLS <value> TYPE simple.

    LOOP AT names INTO DATA(name).
      ASSIGN COMPONENT name OF STRUCTURE row TO <value>.
      IF sy-subrc <> 0.
        RAISE EXCEPTION NEW zcx_csv( text = |Component { name } could not be accessed| ).
      ENDIF.

      INSERT |{ <value> }| INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


"! Tokenizer for RFC 4180 text. Jumps from special character to special
"! character with find_any_of, so plain text between them is copied in one go.
CLASS lcl_parser DEFINITION FINAL.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING text    TYPE string
                dialect TYPE dialect.

    METHODS parse
      RETURNING VALUE(result) TYPE zif_csv_reader=>records
      RAISING   zcx_csv.

  PRIVATE SECTION.
    CONSTANTS not_found TYPE i VALUE -1.

    DATA text     TYPE string.
    DATA dialect  TYPE dialect.
    DATA length   TYPE i.
    "! Characters that end plain field text: delimiter, quote, CR and LF.
    DATA specials TYPE string.

    "! Offset of the next unread character.
    DATA position    TYPE i.
    DATA field       TYPE string.
    "! The current field was enclosed in quotes - after its closing quote only
    "! a delimiter or a line break may follow.
    DATA quoted      TYPE abap_bool.
    DATA record      TYPE zif_csv_reader=>record.
    "! Something was consumed for the current record; tells a record with one
    "! empty field apart from a blank line.
    DATA record_open TYPE abap_bool.
    DATA records     TYPE zif_csv_reader=>records.

    "! Appends the plain text between the current position and the offset.
    METHODS append_plain_text
      IMPORTING up_to TYPE i
      RAISING   zcx_csv.

    METHODS consume_special
      IMPORTING special TYPE string
      RAISING   zcx_csv.

    METHODS consume_quote
      RAISING zcx_csv.

    "! Reads the text of a quoted field up to and including its closing quote.
    METHODS consume_quoted_text
      RAISING zcx_csv.

    METHODS end_line
      IMPORTING line_break TYPE string.

    METHODS end_field.

    METHODS end_record.

    "! The character at the offset, empty at the end of the text.
    METHODS character_at
      IMPORTING offset        TYPE i
      RETURNING VALUE(result) TYPE string.

    METHODS current_record_number
      RETURNING VALUE(result) TYPE i.

ENDCLASS.


CLASS lcl_parser IMPLEMENTATION.

  METHOD constructor.
    me->text    = text.
    me->dialect = dialect.
    length      = strlen( text ).
    specials    = dialect-delimiter && dialect-quote && cl_abap_char_utilities=>cr_lf.
  ENDMETHOD.

  METHOD parse.
    WHILE position < length.
      DATA(next_special) = find_any_of( val = text
                                        sub = specials
                                        off = position ).

      IF next_special = not_found.
        append_plain_text( length ).
        position = length.
      ELSE.
        append_plain_text( next_special ).
        position = next_special + 1.
        consume_special( character_at( next_special ) ).
      ENDIF.
    ENDWHILE.

    " A document need not end with a line break
    IF record_open = abap_true.
      end_field( ).
      end_record( ).
    ENDIF.

    result = records.
  ENDMETHOD.

  METHOD append_plain_text.
    IF up_to = position.
      RETURN.
    ENDIF.

    IF quoted = abap_true.
      RAISE EXCEPTION NEW zcx_csv(
        text = |Record { current_record_number( ) }: only a delimiter or a line break may follow a closing quote| ).
    ENDIF.

    field = field && substring( val = text
                                off = position
                                len = up_to - position ).
    record_open = abap_true.
  ENDMETHOD.

  METHOD consume_special.
    CASE special.
      WHEN dialect-delimiter.
        end_field( ).
      WHEN dialect-quote.
        consume_quote( ).
      WHEN OTHERS.
        end_line( special ).
    ENDCASE.
  ENDMETHOD.

  METHOD consume_quote.
    " RFC 4180 does not allow quotes inside an unquoted field. Like most CSV
    " consumers, they are taken literally instead of rejecting the document.
    IF field IS NOT INITIAL.
      field = field && dialect-quote.
      RETURN.
    ENDIF.

    quoted      = abap_true.
    record_open = abap_true.
    consume_quoted_text( ).
  ENDMETHOD.

  METHOD consume_quoted_text.
    DO.
      DATA(closing) = COND i( WHEN position < length
                              THEN find( val = text
                                         sub = dialect-quote
                                         off = position )
                              ELSE not_found ).

      IF closing = not_found.
        RAISE EXCEPTION NEW zcx_csv( text = |Record { current_record_number( ) }: a quoted field is not closed| ).
      ENDIF.

      field = field && substring( val = text
                                  off = position
                                  len = closing - position ).
      position = closing + 1.

      " A doubled quote is a literal quote, a single one closes the field
      IF character_at( position ) <> dialect-quote.
        RETURN.
      ENDIF.

      field = field && dialect-quote.
      position += 1.
    ENDDO.
  ENDMETHOD.

  METHOD end_line.
    " CR followed by LF is one line break, not two
    IF line_break && character_at( position ) = cl_abap_char_utilities=>cr_lf.
      position += 1.
    ENDIF.

    " Blank lines are skipped, so a trailing line break adds no empty record
    IF record_open = abap_true.
      end_field( ).
      end_record( ).
    ENDIF.
  ENDMETHOD.

  METHOD end_field.
    INSERT field INTO TABLE record.
    CLEAR field.
    quoted      = abap_false.
    record_open = abap_true.
  ENDMETHOD.

  METHOD end_record.
    INSERT record INTO TABLE records.
    CLEAR record.
    record_open = abap_false.
  ENDMETHOD.

  METHOD character_at.
    IF offset < length.
      result = substring( val = text
                          off = offset
                          len = 1 ).
    ENDIF.
  ENDMETHOD.

  METHOD current_record_number.
    result = lines( records ) + 1.
  ENDMETHOD.

ENDCLASS.


"! Assignment of record fields to the components of a target row, derived
"! from the header (by name) or from the first record (by position).
CLASS lcl_column_map DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES: BEGIN OF column,
             index     TYPE i,
             label     TYPE string,
             component TYPE string,
           END OF column.
    TYPES column_mapping TYPE STANDARD TABLE OF column WITH EMPTY KEY.

    CLASS-METHODS by_header
      IMPORTING header        TYPE zif_csv_reader=>record
                row_type      TYPE REF TO lcl_row_type
      RETURNING VALUE(result) TYPE REF TO lcl_column_map
      RAISING   zcx_csv.

    CLASS-METHODS by_position
      IMPORTING first_record  TYPE zif_csv_reader=>record
                row_type      TYPE REF TO lcl_row_type
      RETURNING VALUE(result) TYPE REF TO lcl_column_map
      RAISING   zcx_csv.

    METHODS constructor
      IMPORTING columns        TYPE column_mapping
                expected_count TYPE i.

    "! Writes the mapped fields of the record into the row.
    METHODS fill
      IMPORTING record        TYPE zif_csv_reader=>record
                record_number TYPE i
      CHANGING  row           TYPE any
      RAISING   zcx_csv.

  PRIVATE SECTION.
    DATA columns        TYPE column_mapping.
    "! Field count of the header or the first record - every record must match it.
    DATA expected_count TYPE i.

    METHODS assign_value
      IMPORTING value         TYPE string
                column        TYPE column
                record_number TYPE i
      CHANGING  row           TYPE any
      RAISING   zcx_csv.

ENDCLASS.


CLASS lcl_column_map IMPLEMENTATION.

  METHOD by_header.
    DATA mapped TYPE column_mapping.

    LOOP AT header INTO DATA(label).
      DATA(index) = sy-tabix.
      DATA(component) = to_upper( condense( label ) ).

      IF row_type->has_component( component ) = abap_false.
        CONTINUE.
      ENDIF.

      IF line_exists( mapped[ component = component ] ).
        RAISE EXCEPTION NEW zcx_csv( text = |Column { label } appears more than once in the header| ).
      ENDIF.

      INSERT VALUE #( index     = index
                      label     = label
                      component = component ) INTO TABLE mapped.
    ENDLOOP.

    IF mapped IS INITIAL.
      RAISE EXCEPTION NEW zcx_csv(
        text = `No header column matches a component of the target row - check the column names and the delimiter` ).
    ENDIF.

    result = NEW #( columns        = mapped
                    expected_count = lines( header ) ).
  ENDMETHOD.

  METHOD by_position.
    DATA(names) = row_type->component_names( ).
    DATA(field_count) = lines( first_record ).

    IF field_count > lines( names ).
      RAISE EXCEPTION NEW zcx_csv(
        text = |Record 1 has { field_count } fields, but the target row has only { lines( names ) } components| ).
    ENDIF.

    result = NEW #( columns        = VALUE #( FOR field_index = 1 WHILE field_index <= field_count
                                              ( index     = field_index
                                                label     = names[ field_index ]
                                                component = names[ field_index ] ) )
                    expected_count = field_count ).
  ENDMETHOD.

  METHOD constructor.
    me->columns        = columns.
    me->expected_count = expected_count.
  ENDMETHOD.

  METHOD fill.
    IF lines( record ) <> expected_count.
      RAISE EXCEPTION NEW zcx_csv(
        text = |Record { record_number } has { lines( record ) } fields, expected { expected_count }| ).
    ENDIF.

    LOOP AT columns INTO DATA(column).
      assign_value( EXPORTING value         = record[ column-index ]
                              column        = column
                              record_number = record_number
                    CHANGING  row           = row ).
    ENDLOOP.
  ENDMETHOD.

  METHOD assign_value.
    ASSIGN COMPONENT column-component OF STRUCTURE row TO FIELD-SYMBOL(<target>).
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_csv( text = |Component { column-component } could not be accessed| ).
    ENDIF.

    TRY.
        <target> = value.
      CATCH cx_sy_conversion_error INTO DATA(conversion_error).
        RAISE EXCEPTION NEW zcx_csv(
          text     = |Record { record_number }, column { column-label }: "{ value }" cannot be converted|
          previous = conversion_error ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_reader DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_csv_reader.

    METHODS constructor
      IMPORTING text TYPE string.

  PRIVATE SECTION.
    DATA text       TYPE string.
    DATA dialect    TYPE dialect.
    DATA has_header TYPE abap_bool VALUE abap_true.

    METHODS parse
      RETURNING VALUE(result) TYPE zif_csv_reader=>records
      RAISING   zcx_csv.

    METHODS column_map_for
      IMPORTING first_record  TYPE zif_csv_reader=>record
                row_type      TYPE REF TO lcl_row_type
      RETURNING VALUE(result) TYPE REF TO lcl_column_map
      RAISING   zcx_csv.

ENDCLASS.


CLASS lcl_reader IMPLEMENTATION.

  METHOD constructor.
    me->text = text.
    dialect  = lcl_dialect=>defaults( ).
  ENDMETHOD.

  METHOD zif_csv_reader~with_delimiter.
    dialect-delimiter = delimiter.
    self = me.
  ENDMETHOD.

  METHOD zif_csv_reader~with_quote.
    dialect-quote = quote.
    self = me.
  ENDMETHOD.

  METHOD zif_csv_reader~without_header.
    has_header = abap_false.
    self = me.
  ENDMETHOD.

  METHOD zif_csv_reader~read_records.
    result = parse( ).
  ENDMETHOD.

  METHOD zif_csv_reader~read_into.
    CLEAR rows.

    " The target is checked first, so that a wrong table type is reported
    " even for an empty document
    DATA(row_type) = lcl_row_type=>of_table( rows ).
    DATA(records) = parse( ).

    IF records IS INITIAL.
      RETURN.
    ENDIF.

    DATA(column_map) = column_map_for( first_record = records[ 1 ]
                                       row_type     = row_type ).

    " With a header the data starts at the second record
    DATA(first_data_record) = COND i( WHEN has_header = abap_true THEN 2 ELSE 1 ).

    LOOP AT records INTO DATA(record) FROM first_data_record.
      DATA(record_number) = sy-tabix.

      INSERT INITIAL LINE INTO TABLE rows ASSIGNING FIELD-SYMBOL(<row>).
      column_map->fill( EXPORTING record        = record
                                  record_number = record_number
                        CHANGING  row           = <row> ).
    ENDLOOP.
  ENDMETHOD.

  METHOD parse.
    lcl_dialect=>validate( dialect ).

    result = NEW lcl_parser( text    = text
                             dialect = dialect )->parse( ).
  ENDMETHOD.

  METHOD column_map_for.
    IF has_header = abap_true.
      result = lcl_column_map=>by_header( header   = first_record
                                          row_type = row_type ).
    ELSE.
      result = lcl_column_map=>by_position( first_record = first_record
                                            row_type     = row_type ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_writer DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_csv_writer.

    "! @parameter records | Records to write, one field text per column
    "! @parameter header  | Default header row; empty when the records have no known structure
    METHODS constructor
      IMPORTING records TYPE zif_csv_reader=>records
                header  TYPE zif_csv_writer=>labels OPTIONAL.

  PRIVATE SECTION.
    TYPES output_lines TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    DATA records     TYPE zif_csv_reader=>records.
    DATA header      TYPE zif_csv_writer=>labels.
    DATA labels      TYPE zif_csv_writer=>labels.
    DATA with_header TYPE abap_bool VALUE abap_true.
    DATA dialect     TYPE dialect.
    DATA line_break  TYPE string.
    "! Characters that force a field to be enclosed in quotes.
    DATA specials    TYPE string.

    METHODS validate
      RAISING zcx_csv.

    "! The header row to write; empty when none is wanted or none is known.
    METHODS header_row
      RETURNING VALUE(result) TYPE zif_csv_writer=>labels
      RAISING   zcx_csv.

    METHODS format_record
      IMPORTING record        TYPE zif_csv_reader=>record
      RETURNING VALUE(result) TYPE string.

    METHODS format_field
      IMPORTING value         TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS lcl_writer IMPLEMENTATION.

  METHOD constructor.
    me->records = records.
    me->header  = header.
    dialect     = lcl_dialect=>defaults( ).
    line_break  = cl_abap_char_utilities=>cr_lf.
  ENDMETHOD.

  METHOD zif_csv_writer~with_delimiter.
    dialect-delimiter = delimiter.
    self = me.
  ENDMETHOD.

  METHOD zif_csv_writer~with_quote.
    dialect-quote = quote.
    self = me.
  ENDMETHOD.

  METHOD zif_csv_writer~with_line_break.
    me->line_break = line_break.
    self = me.
  ENDMETHOD.

  METHOD zif_csv_writer~with_labels.
    me->labels = labels.
    self = me.
  ENDMETHOD.

  METHOD zif_csv_writer~without_header.
    with_header = abap_false.
    self = me.
  ENDMETHOD.

  METHOD zif_csv_writer~to_string.
    validate( ).

    DATA output TYPE output_lines.

    DATA(heading) = header_row( ).
    IF heading IS NOT INITIAL.
      INSERT format_record( heading ) INTO TABLE output.
    ENDIF.

    LOOP AT records INTO DATA(record).
      INSERT format_record( record ) INTO TABLE output.
    ENDLOOP.

    IF output IS NOT INITIAL.
      result = concat_lines_of( table = output
                                sep   = line_break ) && line_break.
    ENDIF.
  ENDMETHOD.

  METHOD validate.
    lcl_dialect=>validate( dialect ).

    IF line_break <> cl_abap_char_utilities=>cr_lf AND line_break <> cl_abap_char_utilities=>newline.
      RAISE EXCEPTION NEW zcx_csv( text = `The line break must be CRLF or LF` ).
    ENDIF.

    specials = dialect-delimiter && dialect-quote && cl_abap_char_utilities=>cr_lf.
  ENDMETHOD.

  METHOD header_row.
    IF with_header = abap_false.
      RETURN.
    ENDIF.

    IF labels IS INITIAL.
      result = header.
      RETURN.
    ENDIF.

    IF header IS NOT INITIAL AND lines( labels ) <> lines( header ).
      RAISE EXCEPTION NEW zcx_csv( text = |{ lines( labels ) } labels were supplied for { lines( header ) } columns| ).
    ENDIF.

    result = labels.
  ENDMETHOD.

  METHOD format_record.
    DATA(fields) = VALUE zif_csv_reader=>record( FOR field IN record ( format_field( field ) ) ).

    result = concat_lines_of( table = fields
                              sep   = dialect-delimiter ).
  ENDMETHOD.

  METHOD format_field.
    " Only a field that would be misread is enclosed; a quote inside it is
    " written twice (RFC 4180)
    IF find_any_of( val = value
                    sub = specials ) < 0.
      result = value.
      RETURN.
    ENDIF.

    result = dialect-quote && replace( val  = value
                                       sub  = dialect-quote
                                       with = dialect-quote && dialect-quote
                                       occ  = 0 ) && dialect-quote.
  ENDMETHOD.

ENDCLASS.
