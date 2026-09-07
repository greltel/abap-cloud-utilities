*"* use this source file for your ABAP unit test classes
CLASS ltc_align DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_left_then_padded_right FOR TESTING RAISING cx_static_check.
    METHODS when_right_then_padded_left FOR TESTING RAISING cx_static_check.
    METHODS when_zero_fill_then_number FOR TESTING RAISING cx_static_check.
    METHODS when_center_even_then_split FOR TESTING RAISING cx_static_check.
    METHODS when_center_odd_then_right FOR TESTING RAISING cx_static_check.
    METHODS when_wider_then_unchanged FOR TESTING RAISING cx_static_check.
    METHODS when_same_width_then_unchanged FOR TESTING RAISING cx_static_check.
    METHODS when_empty_then_only_fill FOR TESTING RAISING cx_static_check.
    METHODS when_width_zero_then_unchanged FOR TESTING RAISING cx_static_check.
    METHODS when_neg_width_then_raises FOR TESTING.
    METHODS when_long_fill_then_raises FOR TESTING.
    METHODS when_empty_fill_then_raises FOR TESTING.
    METHODS when_aligned_then_source_kept FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_align IMPLEMENTATION.

  METHOD when_left_then_padded_right.
    DATA(result) = zcl_string_format=>for_text( `abc` )->align_left( 6 )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `abc   `
                                        msg = `Left alignment must pad on the right` ).
  ENDMETHOD.

  METHOD when_right_then_padded_left.
    DATA(result) = zcl_string_format=>for_text( `abc` )->align_right( 6 )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `   abc`
                                        msg = `Right alignment must pad on the left` ).
  ENDMETHOD.

  METHOD when_zero_fill_then_number.
    DATA(result) = zcl_string_format=>for_text( `42` )->align_right( width = 8
                                                                     fill  = `0` )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `00000042`
                                        msg = `Right alignment with a zero must zero pad` ).
  ENDMETHOD.

  METHOD when_center_even_then_split.
    DATA(result) = zcl_string_format=>for_text( `ab` )->center( width = 6
                                                                fill  = `*` )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `**ab**`
                                        msg = `Even padding must be split in half` ).
  ENDMETHOD.

  METHOD when_center_odd_then_right.
    DATA(result) = zcl_string_format=>for_text( `ab` )->center( width = 5
                                                                fill  = `*` )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `*ab**`
                                        msg = `The odd fill character must go to the right` ).
  ENDMETHOD.

  METHOD when_wider_then_unchanged.
    DATA(result) = zcl_string_format=>for_text( `abcdef` )->align_right( 3 )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `abcdef`
                                        msg = `Alignment must never cut a text` ).
  ENDMETHOD.

  METHOD when_same_width_then_unchanged.
    DATA(result) = zcl_string_format=>for_text( `abc` )->center( 3 )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `abc`
                                        msg = `A text of the wanted width needs no padding` ).
  ENDMETHOD.

  METHOD when_empty_then_only_fill.
    DATA(result) = zcl_string_format=>for_text( `` )->align_left( width = 3
                                                                  fill  = `-` )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `---`
                                        msg = `An empty text must become pure fill` ).
  ENDMETHOD.

  METHOD when_width_zero_then_unchanged.
    DATA(result) = zcl_string_format=>for_text( `abc` )->align_left( 0 )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `abc`
                                        msg = `Width zero must leave the text as it is` ).
  ENDMETHOD.

  METHOD when_neg_width_then_raises.
    TRY.
        zcl_string_format=>for_text( `abc` )->align_left( -1 ).
        cl_abap_unit_assert=>fail( `A negative width must be rejected` ).
      CATCH zcx_string_format.
    ENDTRY.
  ENDMETHOD.

  METHOD when_long_fill_then_raises.
    TRY.
        zcl_string_format=>for_text( `abc` )->align_right( width = 5
                                                           fill  = `ab` ).
        cl_abap_unit_assert=>fail( `A fill of two characters must be rejected` ).
      CATCH zcx_string_format.
    ENDTRY.
  ENDMETHOD.

  METHOD when_empty_fill_then_raises.
    TRY.
        zcl_string_format=>for_text( `abc` )->center( width = 5
                                                      fill  = `` ).
        cl_abap_unit_assert=>fail( `An empty fill must be rejected` ).
      CATCH zcx_string_format.
    ENDTRY.
  ENDMETHOD.

  METHOD when_aligned_then_source_kept.
    DATA(cut) = zcl_string_format=>for_text( `abc` ).

    DATA(aligned) = cut->align_right( 5 ).

    cl_abap_unit_assert=>assert_equals( act = cut->as_text( )
                                        exp = `abc`
                                        msg = `Alignment must not change the original view` ).
    cl_abap_unit_assert=>assert_equals( act = aligned->as_text( )
                                        exp = `  abc`
                                        msg = `Alignment must return a view on the padded text` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_cut DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_truncate_then_cut FOR TESTING RAISING cx_static_check.
    METHODS when_truncate_fits_then_same FOR TESTING RAISING cx_static_check.
    METHODS when_truncate_zero_then_empty FOR TESTING RAISING cx_static_check.
    METHODS when_truncate_neg_then_raises FOR TESTING.
    METHODS when_shorten_then_marker FOR TESTING RAISING cx_static_check.
    METHODS when_shorten_fits_then_same FOR TESTING RAISING cx_static_check.
    METHODS when_own_marker_then_used FOR TESTING RAISING cx_static_check.
    METHODS when_marker_too_wide_raises FOR TESTING.
    METHODS when_fixed_width_then_chain FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_cut IMPLEMENTATION.

  METHOD when_truncate_then_cut.
    DATA(result) = zcl_string_format=>for_text( `abcdef` )->truncate( 4 )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `abcd`
                                        msg = `Truncate must keep the first characters only` ).
  ENDMETHOD.

  METHOD when_truncate_fits_then_same.
    DATA(result) = zcl_string_format=>for_text( `abc` )->truncate( 4 )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `abc`
                                        msg = `A text that fits must not be padded or cut` ).
  ENDMETHOD.

  METHOD when_truncate_zero_then_empty.
    DATA(result) = zcl_string_format=>for_text( `abc` )->truncate( 0 )->as_text( ).

    cl_abap_unit_assert=>assert_initial( act = result
                                         msg = `Width zero must cut everything` ).
  ENDMETHOD.

  METHOD when_truncate_neg_then_raises.
    TRY.
        zcl_string_format=>for_text( `abc` )->truncate( -1 ).
        cl_abap_unit_assert=>fail( `A negative width must be rejected` ).
      CATCH zcx_string_format.
    ENDTRY.
  ENDMETHOD.

  METHOD when_shorten_then_marker.
    DATA(result) = zcl_string_format=>for_text( `The quick brown fox` )->shorten( 9 )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `The qu...`
                                        msg = `Shorten must end the cut text with the marker inside the width` ).
  ENDMETHOD.

  METHOD when_shorten_fits_then_same.
    DATA(result) = zcl_string_format=>for_text( `short` )->shorten( 9 )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `short`
                                        msg = `A text that fits must not get a marker` ).
  ENDMETHOD.

  METHOD when_own_marker_then_used.
    DATA(result) = zcl_string_format=>for_text( `abcdefgh` )->shorten( width  = 5
                                                                       marker = `~` )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `abcd~`
                                        msg = `The given marker must replace the default one` ).
  ENDMETHOD.

  METHOD when_marker_too_wide_raises.
    TRY.
        zcl_string_format=>for_text( `abcdef` )->shorten( 2 ).
        cl_abap_unit_assert=>fail( `A width below the marker length must be rejected` ).
      CATCH zcx_string_format.
    ENDTRY.
  ENDMETHOD.

  METHOD when_fixed_width_then_chain.
    DATA(result) = zcl_string_format=>for_text( `Description that is long` )->truncate( 10
                                                                            )->align_left( 10
                                                                            )->to_upper_case(
                                                                            )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `DESCRIPTIO`
                                        msg = `Truncate and align must produce a fixed width field` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_case DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_upper_then_all_upper FOR TESTING.
    METHODS when_lower_then_all_lower FOR TESTING.
    METHODS when_capitalize_then_first FOR TESTING.
    METHODS when_capitalize_empty_then_ok FOR TESTING.
    METHODS when_title_then_words_spaced FOR TESTING.
    METHODS when_camel_from_snake FOR TESTING.
    METHODS when_camel_from_words FOR TESTING.
    METHODS when_pascal_from_kebab FOR TESTING.
    METHODS when_snake_from_camel FOR TESTING.
    METHODS when_snake_from_acronym FOR TESTING.
    METHODS when_kebab_from_pascal FOR TESTING.
    METHODS when_empty_then_stays_empty FOR TESTING.
    METHODS when_greek_then_lowered FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_case IMPLEMENTATION.

  METHOD when_upper_then_all_upper.
    DATA(result) = zcl_string_format=>for_text( `Order 12 ok` )->to_upper_case( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `ORDER 12 OK`
                                        msg = `Upper case must convert every letter and keep the rest` ).
  ENDMETHOD.

  METHOD when_lower_then_all_lower.
    DATA(result) = zcl_string_format=>for_text( `Order 12 OK` )->to_lower_case( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `order 12 ok`
                                        msg = `Lower case must convert every letter and keep the rest` ).
  ENDMETHOD.

  METHOD when_capitalize_then_first.
    DATA(result) = zcl_string_format=>for_text( `hello WORLD` )->capitalize( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `Hello WORLD`
                                        msg = `Capitalize must touch the first character only` ).
  ENDMETHOD.

  METHOD when_capitalize_empty_then_ok.
    DATA(result) = zcl_string_format=>for_text( `` )->capitalize( )->as_text( ).

    cl_abap_unit_assert=>assert_initial( act = result
                                         msg = `Capitalizing an empty text must return an empty text` ).
  ENDMETHOD.

  METHOD when_title_then_words_spaced.
    DATA(result) = zcl_string_format=>for_text( `sales_order-ITEM number` )->to_title_case( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `Sales Order Item Number`
                                        msg = `Title case must capitalize each word and join with one blank` ).
  ENDMETHOD.

  METHOD when_camel_from_snake.
    DATA(result) = zcl_string_format=>for_text( `sales_order_item` )->to_camel_case( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `salesOrderItem`
                                        msg = `Camel case must lower the first word and capitalize the rest` ).
  ENDMETHOD.

  METHOD when_camel_from_words.
    DATA(result) = zcl_string_format=>for_text( `  Sales   ORDER  item ` )->to_camel_case( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `salesOrderItem`
                                        msg = `Repeated separators and mixed case must not leak into camel case` ).
  ENDMETHOD.

  METHOD when_pascal_from_kebab.
    DATA(result) = zcl_string_format=>for_text( `sales-order-item` )->to_pascal_case( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `SalesOrderItem`
                                        msg = `Pascal case must capitalize every word without separators` ).
  ENDMETHOD.

  METHOD when_snake_from_camel.
    DATA(result) = zcl_string_format=>for_text( `salesOrderItem` )->to_snake_case( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `sales_order_item`
                                        msg = `Snake case must split at every case change` ).
  ENDMETHOD.

  METHOD when_snake_from_acronym.
    DATA(result) = zcl_string_format=>for_text( `parseHTTPRequest2Body` )->to_snake_case( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `parse_http_request2_body`
                                        msg = `An acronym must stay one word and digits must stay with their word` ).
  ENDMETHOD.

  METHOD when_kebab_from_pascal.
    DATA(result) = zcl_string_format=>for_text( `SalesOrderItem` )->to_kebab_case( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `sales-order-item`
                                        msg = `Kebab case must join lower case words with hyphens` ).
  ENDMETHOD.

  METHOD when_empty_then_stays_empty.
    DATA(result) = zcl_string_format=>for_text( `` )->to_camel_case( )->as_text( ).

    cl_abap_unit_assert=>assert_initial( act = result
                                         msg = `Case conversion of an empty text must stay empty` ).
  ENDMETHOD.

  METHOD when_greek_then_lowered.
    " UTF-8 bytes are used because the source must stay 7 bit ASCII
    DATA(decoder) = cl_abap_conv_codepage=>create_in( ).
    DATA(greek_words) = decoder->convert( CONV xstring( 'CEBACEB1CEBBCEAECE9CCEADCF81CEB1' ) ).
    DATA(expected) = decoder->convert( CONV xstring( 'CEBACEB1CEBBCEAE5FCEBCCEADCF81CEB1' ) ).

    DATA(result) = zcl_string_format=>for_text( greek_words )->to_snake_case( )->as_text( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = expected
                                        msg = `Greek letters must be recognized as letters and lowered` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_words DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_blanks_then_split FOR TESTING.
    METHODS when_punctuation_then_dropped FOR TESTING.
    METHODS when_camel_then_case_split FOR TESTING.
    METHODS when_acronym_then_kept FOR TESTING.
    METHODS when_digits_then_stay FOR TESTING.
    METHODS when_all_upper_then_one_word FOR TESTING.
    METHODS when_only_separators_then_none FOR TESTING.
    METHODS when_empty_then_no_words FOR TESTING.

ENDCLASS.


CLASS ltc_words IMPLEMENTATION.

  METHOD when_blanks_then_split.
    DATA(result) = zcl_string_format=>for_text( `one two  three` )->words( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = VALUE zif_string_format=>word_list( ( `one` ) ( `two` ) ( `three` ) )
                                        msg = `Blanks must separate words and never become words` ).
  ENDMETHOD.

  METHOD when_punctuation_then_dropped.
    DATA(result) = zcl_string_format=>for_text( `a.b,c;d/e-f_g` )->words( ).

    cl_abap_unit_assert=>assert_equals( act = lines( result )
                                        exp = 7
                                        msg = `Every character that is not a letter or digit must separate` ).
  ENDMETHOD.

  METHOD when_camel_then_case_split.
    DATA(result) = zcl_string_format=>for_text( `orderNumber` )->words( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = VALUE zif_string_format=>word_list( ( `order` ) ( `Number` ) )
                                        msg = `A change from lower to upper case must start a word` ).
  ENDMETHOD.

  METHOD when_acronym_then_kept.
    DATA(result) = zcl_string_format=>for_text( `HTTPRequest` )->words( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = VALUE zif_string_format=>word_list( ( `HTTP` ) ( `Request` ) )
                                        msg = `The last upper case letter before lower case starts the word` ).
  ENDMETHOD.

  METHOD when_digits_then_stay.
    DATA(result) = zcl_string_format=>for_text( `utf8Text v2` )->words( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = VALUE zif_string_format=>word_list( ( `utf8` ) ( `Text` ) ( `v2` ) )
                                        msg = `Digits must belong to the word they follow` ).
  ENDMETHOD.

  METHOD when_all_upper_then_one_word.
    DATA(result) = zcl_string_format=>for_text( `MATNR` )->words( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = VALUE zif_string_format=>word_list( ( `MATNR` ) )
                                        msg = `An all upper case text is one word` ).
  ENDMETHOD.

  METHOD when_only_separators_then_none.
    DATA(result) = zcl_string_format=>for_text( ` -_- ` )->words( ).

    cl_abap_unit_assert=>assert_initial( act = result
                                         msg = `Separators alone must not produce a word` ).
  ENDMETHOD.

  METHOD when_empty_then_no_words.
    DATA(result) = zcl_string_format=>for_text( `` )->words( ).

    cl_abap_unit_assert=>assert_initial( act = result
                                         msg = `An empty text has no words` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_template_parse DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_parsed_then_names_listed FOR TESTING RAISING cx_static_check.
    METHODS when_repeated_then_listed_once FOR TESTING RAISING cx_static_check.
    METHODS when_no_placeholder_then_none FOR TESTING RAISING cx_static_check.
    METHODS when_double_brace_then_literal FOR TESTING RAISING cx_static_check.
    METHODS when_unclosed_then_raises FOR TESTING.
    METHODS when_stray_closing_then_raises FOR TESTING.
    METHODS when_empty_name_then_raises FOR TESTING.
    METHODS when_blank_in_name_then_raises FOR TESTING.
    METHODS when_digit_first_then_raises FOR TESTING.
    METHODS when_empty_text_then_empty FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_template_parse IMPLEMENTATION.

  METHOD when_parsed_then_names_listed.
    DATA(result) = zcl_string_format=>template( `Dear {name}, order {order_id} of {Date}` )->placeholders( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = VALUE zif_string_template=>names( ( `name` ) ( `order_id` ) ( `Date` ) )
                                        msg = `Placeholders must be listed in order and as written` ).
  ENDMETHOD.

  METHOD when_repeated_then_listed_once.
    DATA(result) = zcl_string_format=>template( `{name} and {NAME} and {Name}` )->placeholders( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = VALUE zif_string_template=>names( ( `name` ) )
                                        msg = `The same name in another case is listed once, first spelling wins` ).
  ENDMETHOD.

  METHOD when_no_placeholder_then_none.
    DATA(result) = zcl_string_format=>template( `plain text` )->placeholders( ).

    cl_abap_unit_assert=>assert_initial( act = result
                                         msg = `A template without braces has no placeholders` ).
  ENDMETHOD.

  METHOD when_double_brace_then_literal.
    DATA(result) = zcl_string_format=>template( `json: {{"id": {id}}}` )->with( name  = `id`
                                                                                value = 7 )->render( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `json: {"id": 7}`
                                        msg = `Doubled braces must render as one literal brace` ).
  ENDMETHOD.

  METHOD when_unclosed_then_raises.
    TRY.
        zcl_string_format=>template( `Hello {name` ).
        cl_abap_unit_assert=>fail( `An unclosed placeholder must be rejected` ).
      CATCH zcx_string_format.
    ENDTRY.
  ENDMETHOD.

  METHOD when_stray_closing_then_raises.
    TRY.
        zcl_string_format=>template( `Hello name}` ).
        cl_abap_unit_assert=>fail( `A closing brace without opening brace must be rejected` ).
      CATCH zcx_string_format.
    ENDTRY.
  ENDMETHOD.

  METHOD when_empty_name_then_raises.
    TRY.
        zcl_string_format=>template( `Hello {}` ).
        cl_abap_unit_assert=>fail( `An empty placeholder name must be rejected` ).
      CATCH zcx_string_format.
    ENDTRY.
  ENDMETHOD.

  METHOD when_blank_in_name_then_raises.
    TRY.
        zcl_string_format=>template( `Hello {first name}` ).
        cl_abap_unit_assert=>fail( `A blank inside a placeholder name must be rejected` ).
      CATCH zcx_string_format.
    ENDTRY.
  ENDMETHOD.

  METHOD when_digit_first_then_raises.
    TRY.
        zcl_string_format=>template( `Hello {1st}` ).
        cl_abap_unit_assert=>fail( `A placeholder name starting with a digit must be rejected` ).
      CATCH zcx_string_format.
    ENDTRY.
  ENDMETHOD.

  METHOD when_empty_text_then_empty.
    DATA(result) = zcl_string_format=>template( `` )->render( ).

    cl_abap_unit_assert=>assert_initial( act = result
                                         msg = `An empty template must render to an empty text` ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_template_render DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES: BEGIN OF order,
             order_id TYPE string,
             quantity TYPE i,
             amount   TYPE p LENGTH 8 DECIMALS 2,
             tags     TYPE string_table,
           END OF order.

    METHODS when_values_then_rendered FOR TESTING RAISING cx_static_check.
    METHODS when_name_case_differs_then_ok FOR TESTING RAISING cx_static_check.
    METHODS when_number_then_converted FOR TESTING RAISING cx_static_check.
    METHODS when_same_name_twice_last_wins FOR TESTING RAISING cx_static_check.
    METHODS when_pairs_then_rendered FOR TESTING RAISING cx_static_check.
    METHODS when_structure_then_rendered FOR TESTING RAISING cx_static_check.
    METHODS when_not_structure_then_raises FOR TESTING.
    METHODS when_missing_then_raises FOR TESTING.
    METHODS when_missing_then_names_listed FOR TESTING.
    METHODS when_partial_then_kept FOR TESTING RAISING cx_static_check.
    METHODS when_partial_completed_later FOR TESTING RAISING cx_static_check.
    METHODS when_with_then_source_kept FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_template_render IMPLEMENTATION.

  METHOD when_values_then_rendered.
    DATA(result) = zcl_string_format=>template( `Dear {name}, your order {order_id} has shipped.`
                     )->with( name  = `name`
                              value = `Anna`
                     )->with( name  = `order_id`
                              value = `SO-1001`
                     )->render( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `Dear Anna, your order SO-1001 has shipped.`
                                        msg = `Every placeholder must be replaced by its value` ).
  ENDMETHOD.

  METHOD when_name_case_differs_then_ok.
    DATA(result) = zcl_string_format=>template( `Hello {Name}` )->with( name  = `NAME`
                                                                        value = `Anna` )->render( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `Hello Anna`
                                        msg = `Placeholder names must be matched without regard to case` ).
  ENDMETHOD.

  METHOD when_number_then_converted.
    DATA(result) = zcl_string_format=>template( `{count} items` )->with( name  = `count`
                                                                         value = 3 )->render( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `3 items`
                                        msg = `A number must be converted like a string template does` ).
  ENDMETHOD.

  METHOD when_same_name_twice_last_wins.
    DATA(result) = zcl_string_format=>template( `{x}` )->with( name  = `x`
                                                               value = `first`
                                                    )->with( name  = `x`
                                                             value = `second`
                                                    )->render( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `second`
                                        msg = `A later value for the same name must replace the earlier one` ).
  ENDMETHOD.

  METHOD when_pairs_then_rendered.
    DATA(pairs) = VALUE zif_string_template=>pairs( ( name = `a` value = `1` )
                                                    ( name = `b` value = `2` ) ).

    DATA(result) = zcl_string_format=>template( `{a}+{b}` )->with_pairs( pairs )->render( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `1+2`
                                        msg = `Every pair must be bound` ).
  ENDMETHOD.

  METHOD when_structure_then_rendered.
    DATA(order) = VALUE order( order_id = `SO-1`
                               quantity = 2
                               amount   = '19.90'
                               tags     = VALUE #( ( `a` ) ) ).

    DATA(result) = zcl_string_format=>template( `{order_id}: {quantity} x {amount}` )->with_structure( order
                     )->render( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `SO-1: 2 x 19.90`
                                        msg = `Elementary components must be bound by name, tables skipped` ).
  ENDMETHOD.

  METHOD when_not_structure_then_raises.
    TRY.
        zcl_string_format=>template( `{a}` )->with_structure( `not a structure` ).
        cl_abap_unit_assert=>fail( `An elementary value must be rejected as structure` ).
      CATCH zcx_string_format.
    ENDTRY.
  ENDMETHOD.

  METHOD when_missing_then_raises.
    TRY.
        zcl_string_format=>template( `Hello {name}` )->render( ).
        cl_abap_unit_assert=>fail( `A placeholder without value must fail a strict render` ).
      CATCH zcx_string_format.
    ENDTRY.
  ENDMETHOD.

  METHOD when_missing_then_names_listed.
    TRY.
        zcl_string_format=>template( `{a} {b}` )->render( ).
        cl_abap_unit_assert=>fail( `A placeholder without value must fail a strict render` ).
      CATCH zcx_string_format INTO DATA(error).
        cl_abap_unit_assert=>assert_char_cp( act = error->get_text( )
                                             exp = `*a, b*`
                                             msg = `The error text must name the unresolved placeholders` ).
    ENDTRY.
  ENDMETHOD.

  METHOD when_partial_then_kept.
    DATA(result) = zcl_string_format=>template( `{greeting} {name}` )->with( name  = `greeting`
                                                                             value = `Hello` )->render_partial( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `Hello {name}`
                                        msg = `A partial render must keep unresolved placeholders in place` ).
  ENDMETHOD.

  METHOD when_partial_completed_later.
    DATA(partial) = zcl_string_format=>template( `{greeting} {name}` )->with( name  = `greeting`
                                                                              value = `Hello` )->render_partial( ).

    DATA(result) = zcl_string_format=>template( partial )->with( name  = `name`
                                                                 value = `Anna` )->render( ).

    cl_abap_unit_assert=>assert_equals( act = result
                                        exp = `Hello Anna`
                                        msg = `A partial result must be a valid template again` ).
  ENDMETHOD.

  METHOD when_with_then_source_kept.
    DATA(template) = zcl_string_format=>template( `Hi {name}` ).

    DATA(anna) = template->with( name  = `name`
                                 value = `Anna` ).
    DATA(bob) = template->with( name  = `name`
                                value = `Bob` ).

    cl_abap_unit_assert=>assert_equals( act = anna->render( )
                                        exp = `Hi Anna`
                                        msg = `The first bound template must keep its own value` ).
    cl_abap_unit_assert=>assert_equals( act = bob->render( )
                                        exp = `Hi Bob`
                                        msg = `The second bound template must keep its own value` ).
    cl_abap_unit_assert=>assert_equals( act = template->render_partial( )
                                        exp = `Hi {name}`
                                        msg = `Binding a value must not change the original template` ).
  ENDMETHOD.

ENDCLASS.
