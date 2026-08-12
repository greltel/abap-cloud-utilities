*"* use this source file for your ABAP unit test classes
CLASS ltc_view DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_read_then_same_text FOR TESTING.
    METHODS when_empty_then_no_text FOR TESTING.
    METHODS when_length_then_char_count FOR TESTING.
    METHODS when_empty_then_length_zero FOR TESTING.
    METHODS when_blanks_then_length_kept FOR TESTING.
    METHODS when_trim_then_source_kept FOR TESTING.

ENDCLASS.


CLASS ltc_view IMPLEMENTATION.

  METHOD when_read_then_same_text.
    DATA(cut) = zcl_string=>for_text( `Hello world` ).

    cl_abap_unit_assert=>assert_equals( act = cut->as_text( )
                                        exp = `Hello world`
                                        msg = 'The view must hand back the text it was built with' ).
  ENDMETHOD.

  METHOD when_empty_then_no_text.
    DATA(cut) = zcl_string=>for_text( `` ).

    cl_abap_unit_assert=>assert_initial( act = cut->as_text( )
                                         msg = 'An empty text must stay empty' ).
  ENDMETHOD.

  METHOD when_length_then_char_count.
    DATA(cut) = zcl_string=>for_text( `abcde` ).

    cl_abap_unit_assert=>assert_equals( act = cut->length( )
                                        exp = 5
                                        msg = 'Length must count every character' ).
  ENDMETHOD.

  METHOD when_empty_then_length_zero.
    DATA(cut) = zcl_string=>for_text( `` ).

    cl_abap_unit_assert=>assert_equals( act = cut->length( )
                                        exp = 0
                                        msg = 'An empty text has no characters' ).
  ENDMETHOD.

  METHOD when_blanks_then_length_kept.
    DATA(cut) = zcl_string=>for_text( `ab  ` ).

    cl_abap_unit_assert=>assert_equals( act = cut->length( )
                                        exp = 4
                                        msg = 'Trailing blanks of a string must not be cut off' ).
  ENDMETHOD.

  METHOD when_trim_then_source_kept.
    DATA(cut) = zcl_string=>for_text( ` abc ` ).

    DATA(trimmed) = cut->trim( ).

    cl_abap_unit_assert=>assert_equals( act = cut->as_text( )
                                        exp = ` abc `
                                        msg = 'Trimming must not change the original view' ).
    cl_abap_unit_assert=>assert_equals( act = trimmed->as_text( )
                                        exp = `abc`
                                        msg = 'Trimming must return a view on the trimmed text' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_trim DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_blanks_then_trimmed FOR TESTING.
    METHODS when_inner_blanks_then_kept FOR TESTING.
    METHODS when_chars_given_then_trimmed FOR TESTING.
    METHODS when_char_set_then_trimmed FOR TESTING.
    METHODS when_only_blanks_then_empty FOR TESTING.
    METHODS when_no_chars_then_unchanged FOR TESTING.
    METHODS when_nothing_to_trim_then_eq FOR TESTING.
    METHODS when_empty_text_then_empty FOR TESTING.
    METHODS when_trim_chained_then_split FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_trim IMPLEMENTATION.

  METHOD when_blanks_then_trimmed.
    DATA(result) = zcl_string=>for_text( `  abc  ` )->trim( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `abc`
                                        msg = 'Leading and trailing blanks must be removed' ).
  ENDMETHOD.

  METHOD when_inner_blanks_then_kept.
    DATA(result) = zcl_string=>for_text( `  a b  ` )->trim( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `a b`
                                        msg = 'Blanks inside the text must survive trimming' ).
  ENDMETHOD.

  METHOD when_chars_given_then_trimmed.
    DATA(result) = zcl_string=>for_text( `xxabcxx` )->trim( `x` )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `abc`
                                        msg = 'The given character must be removed from both ends' ).
  ENDMETHOD.

  METHOD when_char_set_then_trimmed.
    DATA(result) = zcl_string=>for_text( `-*-abc*-` )->trim( `-*` )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `abc`
                                        msg = 'Every character of the set must be removed' ).
  ENDMETHOD.

  METHOD when_only_blanks_then_empty.
    DATA(result) = zcl_string=>for_text( `   ` )->trim( )->as_text( ).

    cl_abap_unit_assert=>assert_initial( act = result
                                         msg = 'A text of blanks must trim down to nothing' ).
  ENDMETHOD.

  METHOD when_no_chars_then_unchanged.
    DATA(result) = zcl_string=>for_text( ` abc ` )->trim( `` )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = ` abc `
                                        msg = 'Without characters to remove the text stays as it is' ).
  ENDMETHOD.

  METHOD when_nothing_to_trim_then_eq.
    DATA(result) = zcl_string=>for_text( `abc` )->trim( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `abc`
                                        msg = 'A text without blanks must come back untouched' ).
  ENDMETHOD.

  METHOD when_empty_text_then_empty.
    DATA(result) = zcl_string=>for_text( `` )->trim( )->as_text( ).

    cl_abap_unit_assert=>assert_initial( act = result
                                         msg = 'Trimming an empty text must not fail' ).
  ENDMETHOD.

  METHOD when_trim_chained_then_split.
    DATA(parts) = zcl_string=>for_text( ` a,b ` )->trim( )->split_by( `,` ).

    cl_abap_unit_assert=>assert_equals( act = parts
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `b` ) )
                                        msg = 'A trimmed view must stay usable for splitting' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_split_by DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_csv_then_all_parts FOR TESTING RAISING cx_static_check.
    METHODS when_empty_parts_then_kept FOR TESTING RAISING cx_static_check.
    METHODS when_no_delim_found_then_one FOR TESTING RAISING cx_static_check.
    METHODS when_empty_text_then_one_row FOR TESTING RAISING cx_static_check.
    METHODS when_long_delim_then_parts FOR TESTING RAISING cx_static_check.
    METHODS when_trailing_delim_then_gap FOR TESTING RAISING cx_static_check.
    METHODS when_leading_delim_then_gap FOR TESTING RAISING cx_static_check.
    METHODS when_delim_empty_then_error FOR TESTING.

ENDCLASS.


CLASS ltc_split_by IMPLEMENTATION.

  METHOD when_csv_then_all_parts.
    DATA(parts) = zcl_string=>for_text( `a,b,c` )->split_by( `,` ).

    cl_abap_unit_assert=>assert_equals( act = parts
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `b` ) ( `c` ) )
                                        msg = 'Every part between the commas must be returned' ).
  ENDMETHOD.

  METHOD when_empty_parts_then_kept.
    DATA(parts) = zcl_string=>for_text( `a,,c` )->split_by( `,` ).

    cl_abap_unit_assert=>assert_equals( act = parts
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `` ) ( `c` ) )
                                        msg = 'An empty part must be kept as an empty row' ).
  ENDMETHOD.

  METHOD when_no_delim_found_then_one.
    DATA(parts) = zcl_string=>for_text( `abc` )->split_by( `,` ).

    cl_abap_unit_assert=>assert_equals( act = parts
                                        exp = VALUE zif_string=>segments( ( `abc` ) )
                                        msg = 'Without a hit the whole text is the only part' ).
  ENDMETHOD.

  METHOD when_empty_text_then_one_row.
    DATA(parts) = zcl_string=>for_text( `` )->split_by( `,` ).

    cl_abap_unit_assert=>assert_equals( act = lines( parts )
                                        exp = 1
                                        msg = 'An empty text is one empty part' ).
  ENDMETHOD.

  METHOD when_long_delim_then_parts.
    DATA(parts) = zcl_string=>for_text( `a::b::c` )->split_by( `::` ).

    cl_abap_unit_assert=>assert_equals( act = parts
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `b` ) ( `c` ) )
                                        msg = 'A delimiter of several characters must work' ).
  ENDMETHOD.

  METHOD when_trailing_delim_then_gap.
    DATA(parts) = zcl_string=>for_text( `a,b,` )->split_by( `,` ).

    cl_abap_unit_assert=>assert_equals( act = parts
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `b` ) ( `` ) )
                                        msg = 'A closing delimiter must open one more part' ).
  ENDMETHOD.

  METHOD when_leading_delim_then_gap.
    DATA(parts) = zcl_string=>for_text( `,a` )->split_by( `,` ).

    cl_abap_unit_assert=>assert_equals( act = parts
                                        exp = VALUE zif_string=>segments( ( `` ) ( `a` ) )
                                        msg = 'A leading delimiter must open an empty part' ).
  ENDMETHOD.

  METHOD when_delim_empty_then_error.
    TRY.
        zcl_string=>for_text( `a,b` )->split_by( `` ).
        cl_abap_unit_assert=>fail( msg = 'An empty delimiter must be rejected' ).
      CATCH zcx_string INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial( act = error->get_text( )
                                                 msg = 'The error must explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_split_tokens DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_spaced_csv_then_clean FOR TESTING RAISING cx_static_check.
    METHODS when_empty_parts_then_dropped FOR TESTING RAISING cx_static_check.
    METHODS when_blank_parts_then_dropped FOR TESTING RAISING cx_static_check.
    METHODS when_empty_text_then_no_rows FOR TESTING RAISING cx_static_check.
    METHODS when_delim_empty_then_error FOR TESTING.

ENDCLASS.


CLASS ltc_split_tokens IMPLEMENTATION.

  METHOD when_spaced_csv_then_clean.
    DATA(tokens) = zcl_string=>for_text( `a , b ,c` )->split_tokens( `,` ).

    cl_abap_unit_assert=>assert_equals( act = tokens
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `b` ) ( `c` ) )
                                        msg = 'Every token must come back without blanks' ).
  ENDMETHOD.

  METHOD when_empty_parts_then_dropped.
    DATA(tokens) = zcl_string=>for_text( `a,,b` )->split_tokens( `,` ).

    cl_abap_unit_assert=>assert_equals( act = tokens
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `b` ) )
                                        msg = 'An empty part must not become a token' ).
  ENDMETHOD.

  METHOD when_blank_parts_then_dropped.
    DATA(tokens) = zcl_string=>for_text( `a, ,b` )->split_tokens( `,` ).

    cl_abap_unit_assert=>assert_equals( act = tokens
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `b` ) )
                                        msg = 'A part of blanks must not become a token' ).
  ENDMETHOD.

  METHOD when_empty_text_then_no_rows.
    DATA(tokens) = zcl_string=>for_text( `` )->split_tokens( `,` ).

    cl_abap_unit_assert=>assert_initial( act = tokens
                                         msg = 'An empty text carries no token' ).
  ENDMETHOD.

  METHOD when_delim_empty_then_error.
    TRY.
        zcl_string=>for_text( `a,b` )->split_tokens( `` ).
        cl_abap_unit_assert=>fail( msg = 'An empty delimiter must be rejected' ).
      CATCH zcx_string INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial( act = error->get_text( )
                                                 msg = 'The error must explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_split_lines DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_unix_breaks_then_lines FOR TESTING.
    METHODS when_win_breaks_then_lines FOR TESTING.
    METHODS when_mac_breaks_then_lines FOR TESTING.
    METHODS when_mixed_breaks_then_lines FOR TESTING.
    METHODS when_last_break_then_no_gap FOR TESTING.
    METHODS when_double_break_then_gap FOR TESTING.
    METHODS when_inner_break_then_gap FOR TESTING.
    METHODS when_empty_text_then_no_lines FOR TESTING.
    METHODS when_no_break_then_one_line FOR TESTING.

ENDCLASS.


CLASS ltc_split_lines IMPLEMENTATION.

  METHOD when_unix_breaks_then_lines.
    DATA(rows) = zcl_string=>for_text( |a\nb\nc| )->split_lines( ).

    cl_abap_unit_assert=>assert_equals( act = rows
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `b` ) ( `c` ) )
                                        msg = 'Unix line breaks must separate the lines' ).
  ENDMETHOD.

  METHOD when_win_breaks_then_lines.
    DATA(rows) = zcl_string=>for_text( |a\r\nb| )->split_lines( ).

    cl_abap_unit_assert=>assert_equals( act = rows
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `b` ) )
                                        msg = 'A Windows line break must not leave a stray sign' ).
  ENDMETHOD.

  METHOD when_mac_breaks_then_lines.
    DATA(rows) = zcl_string=>for_text( |a\rb| )->split_lines( ).

    cl_abap_unit_assert=>assert_equals( act = rows
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `b` ) )
                                        msg = 'A single carriage return must separate lines too' ).
  ENDMETHOD.

  METHOD when_mixed_breaks_then_lines.
    DATA(rows) = zcl_string=>for_text( |a\r\nb\nc\rd| )->split_lines( ).

    cl_abap_unit_assert=>assert_equals( act = rows
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `b` ) ( `c` ) ( `d` ) )
                                        msg = 'Mixed line breaks in one text must all be honored' ).
  ENDMETHOD.

  METHOD when_last_break_then_no_gap.
    DATA(rows) = zcl_string=>for_text( |a\nb\n| )->split_lines( ).

    cl_abap_unit_assert=>assert_equals( act = rows
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `b` ) )
                                        msg = 'A closing line break must not open an empty line' ).
  ENDMETHOD.

  METHOD when_double_break_then_gap.
    DATA(rows) = zcl_string=>for_text( |a\n\n| )->split_lines( ).

    cl_abap_unit_assert=>assert_equals( act = rows
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `` ) )
                                        msg = 'Only the last of two closing breaks is a terminator' ).
  ENDMETHOD.

  METHOD when_inner_break_then_gap.
    DATA(rows) = zcl_string=>for_text( |a\n\nb| )->split_lines( ).

    cl_abap_unit_assert=>assert_equals( act = rows
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `` ) ( `b` ) )
                                        msg = 'An empty line inside the text must be kept' ).
  ENDMETHOD.

  METHOD when_empty_text_then_no_lines.
    DATA(rows) = zcl_string=>for_text( `` )->split_lines( ).

    cl_abap_unit_assert=>assert_initial( act = rows
                                         msg = 'An empty text carries no line' ).
  ENDMETHOD.

  METHOD when_no_break_then_one_line.
    DATA(rows) = zcl_string=>for_text( `abc` )->split_lines( ).

    cl_abap_unit_assert=>assert_equals( act = rows
                                        exp = VALUE zif_string=>segments( ( `abc` ) )
                                        msg = 'A text without a break is a single line' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_split_fixed DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_exact_fit_then_chunks FOR TESTING RAISING cx_static_check.
    METHODS when_rest_then_last_shorter FOR TESTING RAISING cx_static_check.
    METHODS when_size_over_len_then_one FOR TESTING RAISING cx_static_check.
    METHODS when_size_one_then_chars FOR TESTING RAISING cx_static_check.
    METHODS when_empty_text_then_no_rows FOR TESTING RAISING cx_static_check.
    METHODS when_size_zero_then_error FOR TESTING.
    METHODS when_size_negative_then_error FOR TESTING.
    METHODS when_only_break_then_one_line FOR TESTING.

ENDCLASS.


CLASS ltc_split_fixed IMPLEMENTATION.

  METHOD when_exact_fit_then_chunks.
    DATA(chunks) = zcl_string=>for_text( `abcdef` )->split_fixed( 2 ).

    cl_abap_unit_assert=>assert_equals( act = chunks
                                        exp = VALUE zif_string=>segments( ( `ab` ) ( `cd` ) ( `ef` ) )
                                        msg = 'A text that fits must break into equal chunks' ).
  ENDMETHOD.

  METHOD when_rest_then_last_shorter.
    DATA(chunks) = zcl_string=>for_text( `abcde` )->split_fixed( 2 ).

    cl_abap_unit_assert=>assert_equals( act = chunks
                                        exp = VALUE zif_string=>segments( ( `ab` ) ( `cd` ) ( `e` ) )
                                        msg = 'The rest must land in a shorter last chunk' ).
  ENDMETHOD.

  METHOD when_size_over_len_then_one.
    DATA(chunks) = zcl_string=>for_text( `abc` )->split_fixed( 10 ).

    cl_abap_unit_assert=>assert_equals( act = chunks
                                        exp = VALUE zif_string=>segments( ( `abc` ) )
                                        msg = 'A chunk wider than the text holds it completely' ).
  ENDMETHOD.

  METHOD when_size_one_then_chars.
    DATA(chunks) = zcl_string=>for_text( `abc` )->split_fixed( 1 ).

    cl_abap_unit_assert=>assert_equals( act = chunks
                                        exp = VALUE zif_string=>segments( ( `a` ) ( `b` ) ( `c` ) )
                                        msg = 'Size one must break the text into characters' ).
  ENDMETHOD.

  METHOD when_empty_text_then_no_rows.
    DATA(chunks) = zcl_string=>for_text( `` )->split_fixed( 3 ).

    cl_abap_unit_assert=>assert_initial( act = chunks
                                         msg = 'An empty text produces no chunk at all' ).
  ENDMETHOD.

  METHOD when_size_zero_then_error.
    TRY.
        zcl_string=>for_text( `abc` )->split_fixed( 0 ).
        cl_abap_unit_assert=>fail( msg = 'A chunk size of zero must be rejected' ).
      CATCH zcx_string INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial( act = error->get_text( )
                                                 msg = 'The error must explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD when_size_negative_then_error.
    TRY.
        zcl_string=>for_text( `abc` )->split_fixed( -1 ).
        cl_abap_unit_assert=>fail( msg = 'A negative chunk size must be rejected' ).
      CATCH zcx_string INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial( act = error->get_text( )
                                                 msg = 'The error must explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD when_only_break_then_one_line.
    DATA(rows) = zcl_string=>for_text( |\n| )->split_lines( ).

    cl_abap_unit_assert=>assert_equals( act = rows
                                        exp = VALUE zif_string=>segments( ( `` ) )
                                        msg = 'A text that is only a line break is one empty line' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_split_pairs DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_pairs_then_name_value FOR TESTING RAISING cx_static_check.
    METHODS when_spaced_then_trimmed FOR TESTING RAISING cx_static_check.
    METHODS when_no_value_then_empty FOR TESTING RAISING cx_static_check.
    METHODS when_value_empty_then_empty FOR TESTING RAISING cx_static_check.
    METHODS when_no_name_then_empty_name FOR TESTING RAISING cx_static_check.
    METHODS when_duplicates_then_all_kept FOR TESTING RAISING cx_static_check.
    METHODS when_query_string_then_pairs FOR TESTING RAISING cx_static_check.
    METHODS when_empty_text_then_no_pairs FOR TESTING RAISING cx_static_check.
    METHODS when_long_delims_then_pairs FOR TESTING RAISING cx_static_check.
    METHODS when_value_delim_empty_error FOR TESTING.
    METHODS when_pair_delim_empty_error FOR TESTING.

ENDCLASS.


CLASS ltc_split_pairs IMPLEMENTATION.

  METHOD when_pairs_then_name_value.
    DATA(cut) = zcl_string=>for_text( `COLOR=RED;SIZE=L` ).

    DATA(pairs) = cut->split_pairs( pair_delimiter  = `;`
                                    value_delimiter = `=` ).

    cl_abap_unit_assert=>assert_equals( act = pairs
                                        exp = VALUE zif_string=>pairs( ( name = `COLOR` value = `RED` )
                                                                       ( name = `SIZE` value = `L` ) )
                                        msg = 'Name and value must be taken apart' ).
  ENDMETHOD.

  METHOD when_spaced_then_trimmed.
    DATA(cut) = zcl_string=>for_text( ` COLOR = RED ; SIZE = L ` ).

    DATA(pairs) = cut->split_pairs( pair_delimiter  = `;`
                                    value_delimiter = `=` ).

    cl_abap_unit_assert=>assert_equals( act = pairs
                                        exp = VALUE zif_string=>pairs( ( name = `COLOR` value = `RED` )
                                                                       ( name = `SIZE` value = `L` ) )
                                        msg = 'Names and values must arrive without blanks' ).
  ENDMETHOD.

  METHOD when_no_value_then_empty.
    DATA(cut) = zcl_string=>for_text( `FLAG;SIZE=L` ).

    DATA(pairs) = cut->split_pairs( pair_delimiter  = `;`
                                    value_delimiter = `=` ).

    cl_abap_unit_assert=>assert_equals( act = pairs
                                        exp = VALUE zif_string=>pairs( ( name = `FLAG` value = `` )
                                                                       ( name = `SIZE` value = `L` ) )
                                        msg = 'An entry without a value must keep its name' ).
  ENDMETHOD.

  METHOD when_value_empty_then_empty.
    DATA(cut) = zcl_string=>for_text( `COLOR=;SIZE=L` ).

    DATA(pairs) = cut->split_pairs( pair_delimiter  = `;`
                                    value_delimiter = `=` ).

    cl_abap_unit_assert=>assert_equals( act = pairs
                                        exp = VALUE zif_string=>pairs( ( name = `COLOR` value = `` )
                                                                       ( name = `SIZE` value = `L` ) )
                                        msg = 'A delimiter without a value gives an empty value' ).
  ENDMETHOD.

  METHOD when_no_name_then_empty_name.
    DATA(cut) = zcl_string=>for_text( `=RED` ).

    DATA(pairs) = cut->split_pairs( pair_delimiter  = `;`
                                    value_delimiter = `=` ).

    cl_abap_unit_assert=>assert_equals( act = pairs
                                        exp = VALUE zif_string=>pairs( ( name = `` value = `RED` ) )
                                        msg = 'A missing name must not swallow the value' ).
  ENDMETHOD.

  METHOD when_duplicates_then_all_kept.
    DATA(cut) = zcl_string=>for_text( `a=1;a=2` ).

    DATA(pairs) = cut->split_pairs( pair_delimiter  = `;`
                                    value_delimiter = `=` ).

    cl_abap_unit_assert=>assert_equals( act = pairs
                                        exp = VALUE zif_string=>pairs( ( name = `a` value = `1` )
                                                                       ( name = `a` value = `2` ) )
                                        msg = 'A repeated name must not drop an entry' ).
  ENDMETHOD.

  METHOD when_query_string_then_pairs.
    DATA(cut) = zcl_string=>for_text( `id=42&name=Smith` ).

    DATA(pairs) = cut->split_pairs( pair_delimiter  = `&`
                                    value_delimiter = `=` ).

    cl_abap_unit_assert=>assert_equals( act = pairs
                                        exp = VALUE zif_string=>pairs( ( name = `id` value = `42` )
                                                                       ( name = `name` value = `Smith` ) )
                                        msg = 'A query string must be readable as pairs' ).
  ENDMETHOD.

  METHOD when_empty_text_then_no_pairs.
    DATA(cut) = zcl_string=>for_text( `` ).

    DATA(pairs) = cut->split_pairs( pair_delimiter  = `;`
                                    value_delimiter = `=` ).

    cl_abap_unit_assert=>assert_initial( act = pairs
                                         msg = 'An empty text carries no pair' ).
  ENDMETHOD.

  METHOD when_long_delims_then_pairs.
    DATA(cut) = zcl_string=>for_text( `a::1||b::2` ).

    DATA(pairs) = cut->split_pairs( pair_delimiter  = `||`
                                    value_delimiter = `::` ).

    cl_abap_unit_assert=>assert_equals( act = pairs
                                        exp = VALUE zif_string=>pairs( ( name = `a` value = `1` )
                                                                       ( name = `b` value = `2` ) )
                                        msg = 'Delimiters of several characters must work' ).
  ENDMETHOD.

  METHOD when_value_delim_empty_error.
    TRY.
        zcl_string=>for_text( `a=1` )->split_pairs( pair_delimiter  = `;`
                                                    value_delimiter = `` ).
        cl_abap_unit_assert=>fail( msg = 'An empty value delimiter must be rejected' ).
      CATCH zcx_string INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial( act = error->get_text( )
                                                 msg = 'The error must explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD when_pair_delim_empty_error.
    TRY.
        zcl_string=>for_text( `a=1` )->split_pairs( pair_delimiter  = ``
                                                    value_delimiter = `=` ).
        cl_abap_unit_assert=>fail( msg = 'An empty pair delimiter must be rejected' ).
      CATCH zcx_string INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial( act = error->get_text( )
                                                 msg = 'The error must explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_extract_one DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_markers_then_inner_text FOR TESTING.
    METHODS when_after_missing_then_empty FOR TESTING.
    METHODS when_before_gone_then_empty FOR TESTING.
    METHODS when_before_empty_then_empty FOR TESTING.
    METHODS when_after_empty_then_empty FOR TESTING.
    METHODS when_repeated_then_first_one FOR TESTING.
    METHODS when_no_content_then_empty FOR TESTING.
    METHODS when_extracted_then_chainable FOR TESTING.

ENDCLASS.


CLASS ltc_extract_one IMPLEMENTATION.

  METHOD when_markers_then_inner_text.
    DATA(cut) = zcl_string=>for_text( `<a>hello</a>` ).

    DATA(part) = cut->extract_between( after  = `<a>`
                                       before = `</a>` ).

    cl_abap_unit_assert=>assert_equals( act = part->as_text( )
                                        exp = `hello`
                                        msg = 'The text between the markers must be returned' ).
  ENDMETHOD.

  METHOD when_after_missing_then_empty.
    DATA(cut) = zcl_string=>for_text( `<a>hello</a>` ).

    DATA(part) = cut->extract_between( after  = `<x>`
                                       before = `</a>` ).

    cl_abap_unit_assert=>assert_initial( act = part->as_text( )
                                         msg = 'A missing opening marker must give nothing' ).
  ENDMETHOD.

  METHOD when_before_gone_then_empty.
    DATA(cut) = zcl_string=>for_text( `<a>hello` ).

    DATA(part) = cut->extract_between( after  = `<a>`
                                       before = `</a>` ).

    cl_abap_unit_assert=>assert_initial( act = part->as_text( )
                                         msg = 'A missing closing marker must give nothing' ).
  ENDMETHOD.

  METHOD when_before_empty_then_empty.
    DATA(cut) = zcl_string=>for_text( `<a>hello</a>` ).

    DATA(part) = cut->extract_between( after  = `<a>`
                                       before = `` ).

    cl_abap_unit_assert=>assert_initial( act = part->as_text( )
                                         msg = 'A marker of no length cannot enclose a text' ).
  ENDMETHOD.

  METHOD when_after_empty_then_empty.
    DATA(cut) = zcl_string=>for_text( `<a>hello</a>` ).

    DATA(part) = cut->extract_between( after  = ``
                                       before = `</a>` ).

    cl_abap_unit_assert=>assert_initial( act = part->as_text( )
                                         msg = 'A marker of no length cannot open a text' ).
  ENDMETHOD.

  METHOD when_repeated_then_first_one.
    DATA(cut) = zcl_string=>for_text( `[1][2]` ).

    DATA(part) = cut->extract_between( after  = `[`
                                       before = `]` ).

    cl_abap_unit_assert=>assert_equals( act = part->as_text( )
                                        exp = `1`
                                        msg = 'Only the first enclosed text must be returned' ).
  ENDMETHOD.

  METHOD when_no_content_then_empty.
    DATA(cut) = zcl_string=>for_text( `<a></a>` ).

    DATA(part) = cut->extract_between( after  = `<a>`
                                       before = `</a>` ).

    cl_abap_unit_assert=>assert_initial( act = part->as_text( )
                                         msg = 'Markers without content must give an empty text' ).
  ENDMETHOD.

  METHOD when_extracted_then_chainable.
    DATA(cut) = zcl_string=>for_text( `<a> x </a>` ).

    DATA(part) = cut->extract_between( after  = `<a>`
                                       before = `</a>` ).

    cl_abap_unit_assert=>assert_equals( act = part->trim( )->as_text( )
                                        exp = `x`
                                        msg = 'The extracted view must stay usable for trimming' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_extract_all DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_all_then_every_match FOR TESTING.
    METHODS when_noise_then_only_inside FOR TESTING.
    METHODS when_no_match_then_no_rows FOR TESTING.
    METHODS when_unclosed_last_then_skip FOR TESTING.
    METHODS when_empty_mark_then_no_rows FOR TESTING.
    METHODS when_long_marks_then_all FOR TESTING.

ENDCLASS.


CLASS ltc_extract_all IMPLEMENTATION.

  METHOD when_all_then_every_match.
    DATA(cut) = zcl_string=>for_text( `[1][2][3]` ).

    DATA(parts) = cut->extract_all_between( after  = `[`
                                            before = `]` ).

    cl_abap_unit_assert=>assert_equals( act = parts
                                        exp = VALUE zif_string=>segments( ( `1` ) ( `2` ) ( `3` ) )
                                        msg = 'Every enclosed text must be collected' ).
  ENDMETHOD.

  METHOD when_noise_then_only_inside.
    DATA(cut) = zcl_string=>for_text( `x[1]y[2]z` ).

    DATA(parts) = cut->extract_all_between( after  = `[`
                                            before = `]` ).

    cl_abap_unit_assert=>assert_equals( act = parts
                                        exp = VALUE zif_string=>segments( ( `1` ) ( `2` ) )
                                        msg = 'Text outside the markers must be ignored' ).
  ENDMETHOD.

  METHOD when_no_match_then_no_rows.
    DATA(cut) = zcl_string=>for_text( `abc` ).

    DATA(parts) = cut->extract_all_between( after  = `[`
                                            before = `]` ).

    cl_abap_unit_assert=>assert_initial( act = parts
                                         msg = 'Without a match nothing must be collected' ).
  ENDMETHOD.

  METHOD when_unclosed_last_then_skip.
    DATA(cut) = zcl_string=>for_text( `[1][2` ).

    DATA(parts) = cut->extract_all_between( after  = `[`
                                            before = `]` ).

    cl_abap_unit_assert=>assert_equals( act = parts
                                        exp = VALUE zif_string=>segments( ( `1` ) )
                                        msg = 'An unclosed last marker must be left out' ).
  ENDMETHOD.

  METHOD when_empty_mark_then_no_rows.
    DATA(cut) = zcl_string=>for_text( `[1][2]` ).

    DATA(parts) = cut->extract_all_between( after  = `[`
                                            before = `` ).

    cl_abap_unit_assert=>assert_initial( act = parts
                                         msg = 'A marker of no length must end the search at once' ).
  ENDMETHOD.

  METHOD when_long_marks_then_all.
    DATA(cut) = zcl_string=>for_text( `<b>x</b><b>y</b>` ).

    DATA(parts) = cut->extract_all_between( after  = `<b>`
                                            before = `</b>` ).

    cl_abap_unit_assert=>assert_equals( act = parts
                                        exp = VALUE zif_string=>segments( ( `x` ) ( `y` ) )
                                        msg = 'Markers of several characters must work' ).
  ENDMETHOD.

ENDCLASS.
