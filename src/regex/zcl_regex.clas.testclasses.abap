*"* use this source file for your ABAP unit test classes
CLASS ltc_compilation DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS two_words TYPE string VALUE `a b`.

    DATA two_lines TYPE string.

    METHODS setup.

    METHODS given_valid_pattern_then_bound FOR TESTING RAISING cx_static_check.
    METHODS given_pattern_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_empty_pattern_then_error FOR TESTING.
    METHODS given_broken_pattern_then_err FOR TESTING.
    METHODS given_default_then_case_strict FOR TESTING RAISING cx_static_check.
    METHODS given_ignore_case_then_matches FOR TESTING RAISING cx_static_check.
    METHODS given_default_then_blank_kept FOR TESTING RAISING cx_static_check.
    METHODS given_extended_then_blank_skip FOR TESTING RAISING cx_static_check.
    METHODS given_default_then_anchor_ends FOR TESTING RAISING cx_static_check.
    METHODS given_multiline_then_line_ends FOR TESTING RAISING cx_static_check.
    METHODS given_default_then_dot_no_nl FOR TESTING RAISING cx_static_check.
    METHODS given_dot_all_then_dot_break FOR TESTING RAISING cx_static_check.

    METHODS assert_rejected
      IMPORTING pattern TYPE string.

ENDCLASS.


CLASS ltc_compilation IMPLEMENTATION.

  METHOD setup.
    two_lines = |a\nb|.
  ENDMETHOD.

  METHOD given_valid_pattern_then_bound.
    cl_abap_unit_assert=>assert_bound(
      act = zcl_regex=>of( `[0-9]+` )
      msg = 'A valid pattern did not compile into an expression' ).
  ENDMETHOD.

  METHOD given_pattern_then_kept.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_regex=>of( `[0-9]+` )->pattern( )
      exp = `[0-9]+`
      msg = 'The compiled expression does not report the pattern it was built from' ).
  ENDMETHOD.

  METHOD given_empty_pattern_then_error.
    assert_rejected( `` ).
  ENDMETHOD.

  METHOD given_broken_pattern_then_err.
    assert_rejected( `(unclosed` ).
  ENDMETHOD.

  METHOD given_default_then_case_strict.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_regex=>of( `abc` )->is_match( `ABC` )
      exp = abap_false
      msg = 'Letters of another case matched although ignore_case is off' ).
  ENDMETHOD.

  METHOD given_ignore_case_then_matches.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_regex=>of( pattern = `abc`
                           options = VALUE #( ignore_case = abap_true ) )->is_match( `ABC` )
      exp = abap_true
      msg = 'Letters of another case did not match although ignore_case is on' ).
  ENDMETHOD.

  METHOD given_default_then_blank_kept.
    DATA(regex) = zcl_regex=>of( two_words ).

    cl_abap_unit_assert=>assert_equals(
      act = regex->is_match( two_words )
      exp = abap_true
      msg = 'A blank in the pattern does not match a blank in the text' ).
    cl_abap_unit_assert=>assert_equals(
      act = regex->is_match( `ab` )
      exp = abap_false
      msg = 'A blank in the pattern was ignored although extended mode is off' ).
  ENDMETHOD.

  METHOD given_extended_then_blank_skip.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_regex=>of( pattern = two_words
                           options = VALUE #( extended = abap_true ) )->is_match( `ab` )
      exp = abap_true
      msg = 'A blank in the pattern was significant although extended mode is on' ).
  ENDMETHOD.

  METHOD given_default_then_anchor_ends.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_regex=>of( `^b$` )->occurs_in( two_lines )
      exp = abap_false
      msg = 'The anchors matched at a line break although multiline is off' ).
  ENDMETHOD.

  METHOD given_multiline_then_line_ends.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_regex=>of( pattern = `^b$`
                           options = VALUE #( multiline = abap_true ) )->occurs_in( two_lines )
      exp = abap_true
      msg = 'The anchors did not match at a line break although multiline is on' ).
  ENDMETHOD.

  METHOD given_default_then_dot_no_nl.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_regex=>of( `a.b` )->is_match( two_lines )
      exp = abap_false
      msg = 'The dot matched a line break although dot_all is off' ).
  ENDMETHOD.

  METHOD given_dot_all_then_dot_break.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_regex=>of( pattern = `a.b`
                           options = VALUE #( dot_all = abap_true ) )->is_match( two_lines )
      exp = abap_true
      msg = 'The dot did not match a line break although dot_all is on' ).
  ENDMETHOD.

  METHOD assert_rejected.
    TRY.
        zcl_regex=>of( pattern ).

        cl_abap_unit_assert=>fail( |Pattern { pattern } was unexpectedly accepted| ).
      CATCH zcx_regex INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial(
          act = rejection->get_text( )
          msg = 'The rejection carries no description' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_matching DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS sample TYPE string VALUE `id: abc-12, def-34`.
    CONSTANTS first_hit_offset TYPE i VALUE 4.
    CONSTANTS first_hit_length TYPE i VALUE 6.
    CONSTANTS not_found_offset TYPE i VALUE -1.

    DATA regex TYPE REF TO zif_regex.

    METHODS setup RAISING zcx_regex.

    METHODS given_whole_text_then_is_match FOR TESTING RAISING cx_static_check.
    METHODS given_part_then_not_match FOR TESTING RAISING cx_static_check.
    METHODS given_present_then_occurs FOR TESTING RAISING cx_static_check.
    METHODS given_absent_then_not_occurs FOR TESTING RAISING cx_static_check.
    METHODS given_two_hits_then_count_two FOR TESTING RAISING cx_static_check.
    METHODS given_hits_then_extract_all FOR TESTING RAISING cx_static_check.
    METHODS given_hits_then_all_in_order FOR TESTING RAISING cx_static_check.
    METHODS given_hit_then_first_value FOR TESTING RAISING cx_static_check.
    METHODS given_hit_then_first_position FOR TESTING RAISING cx_static_check.
    METHODS given_hit_then_groups FOR TESTING RAISING cx_static_check.
    METHODS given_hit_then_group_0_whole FOR TESTING RAISING cx_static_check.
    METHODS given_hit_then_group_count FOR TESTING RAISING cx_static_check.
    METHODS given_no_such_group_then_empty FOR TESTING RAISING cx_static_check.
    METHODS given_unused_group_then_empty FOR TESTING RAISING cx_static_check.
    METHODS given_no_hit_then_not_found FOR TESTING RAISING cx_static_check.
    METHODS given_no_hit_then_empty_match FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_matching IMPLEMENTATION.

  METHOD setup.
    regex = zcl_regex=>of( `([a-z]+)-([0-9]+)` ).
  ENDMETHOD.

  METHOD given_whole_text_then_is_match.
    cl_abap_unit_assert=>assert_equals(
      act = regex->is_match( `abc-12` )
      exp = abap_true
      msg = 'A text covered by the pattern from start to end is not a match' ).
  ENDMETHOD.

  METHOD given_part_then_not_match.
    cl_abap_unit_assert=>assert_equals(
      act = regex->is_match( sample )
      exp = abap_false
      msg = 'A text that merely contains the pattern is reported as a whole match' ).
  ENDMETHOD.

  METHOD given_present_then_occurs.
    cl_abap_unit_assert=>assert_equals(
      act = regex->occurs_in( sample )
      exp = abap_true
      msg = 'An occurrence inside the text was not found' ).
  ENDMETHOD.

  METHOD given_absent_then_not_occurs.
    cl_abap_unit_assert=>assert_equals(
      act = regex->occurs_in( `nothing here` )
      exp = abap_false
      msg = 'An occurrence was reported in a text without one' ).
  ENDMETHOD.

  METHOD given_two_hits_then_count_two.
    cl_abap_unit_assert=>assert_equals(
      act = regex->match_count( sample )
      exp = 2
      msg = 'The number of occurrences is wrong' ).
  ENDMETHOD.

  METHOD given_hits_then_extract_all.
    cl_abap_unit_assert=>assert_equals(
      act = regex->extract_all( sample )
      exp = VALUE string_table( ( `abc-12` ) ( `def-34` ) )
      msg = 'The matched texts are not extracted in text order' ).
  ENDMETHOD.

  METHOD given_hits_then_all_in_order.
    DATA(matches) = regex->all_matches( sample ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( matches )
      exp = 2
      msg = 'Not every occurrence became a match object' ).
    cl_abap_unit_assert=>assert_equals(
      act = matches[ 2 ]->value( )
      exp = `def-34`
      msg = 'The match objects are not in text order' ).
  ENDMETHOD.

  METHOD given_hit_then_first_value.
    cl_abap_unit_assert=>assert_equals(
      act = regex->first_match( sample )->value( )
      exp = `abc-12`
      msg = 'The first match does not carry the matched text' ).
  ENDMETHOD.

  METHOD given_hit_then_first_position.
    DATA(match) = regex->first_match( sample ).

    cl_abap_unit_assert=>assert_equals(
      act = match->offset( )
      exp = first_hit_offset
      msg = 'The offset of the first match is wrong' ).
    cl_abap_unit_assert=>assert_equals(
      act = match->length( )
      exp = first_hit_length
      msg = 'The length of the first match is wrong' ).
  ENDMETHOD.

  METHOD given_hit_then_groups.
    cl_abap_unit_assert=>assert_equals(
      act = regex->first_match( sample )->groups( )
      exp = VALUE string_table( ( `abc` ) ( `12` ) )
      msg = 'The capture groups are not returned in pattern order' ).
  ENDMETHOD.

  METHOD given_hit_then_group_0_whole.
    DATA(match) = regex->first_match( sample ).

    cl_abap_unit_assert=>assert_equals(
      act = match->group( 0 )
      exp = match->value( )
      msg = 'Group 0 is not the whole match' ).
  ENDMETHOD.

  METHOD given_hit_then_group_count.
    cl_abap_unit_assert=>assert_equals(
      act = regex->first_match( sample )->group_count( )
      exp = 2
      msg = 'The number of capture groups is wrong' ).
  ENDMETHOD.

  METHOD given_no_such_group_then_empty.
    cl_abap_unit_assert=>assert_equals(
      act = regex->first_match( sample )->group( 3 )
      exp = ``
      msg = 'A group index beyond the pattern did not yield an empty text' ).
  ENDMETHOD.

  METHOD given_unused_group_then_empty.
    DATA(match) = zcl_regex=>of( `(a)(b)?(c)` )->first_match( `ac` ).

    cl_abap_unit_assert=>assert_equals(
      act = match->groups( )
      exp = VALUE string_table( ( `a` ) ( `` ) ( `c` ) )
      msg = 'An optional group that did not take part is not reported as an empty line' ).
  ENDMETHOD.

  METHOD given_no_hit_then_not_found.
    cl_abap_unit_assert=>assert_equals(
      act = regex->first_match( `nothing here` )->is_found( )
      exp = abap_false
      msg = 'A text without an occurrence yields a found match' ).
  ENDMETHOD.

  METHOD given_no_hit_then_empty_match.
    DATA(match) = regex->first_match( `nothing here` ).

    cl_abap_unit_assert=>assert_equals(
      act = match->value( )
      exp = ``
      msg = 'A match that was not found carries a text' ).
    cl_abap_unit_assert=>assert_equals(
      act = match->offset( )
      exp = not_found_offset
      msg = 'A match that was not found does not report offset -1' ).
    cl_abap_unit_assert=>assert_equals(
      act = match->group_count( )
      exp = 0
      msg = 'A match that was not found reports capture groups' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_replacing DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS sample TYPE string VALUE `a1b22c333`.

    DATA digits TYPE REF TO zif_regex.

    METHODS setup RAISING zcx_regex.

    METHODS given_hits_then_all_replaced FOR TESTING RAISING cx_static_check.
    METHODS given_groups_then_referenced FOR TESTING RAISING cx_static_check.
    METHODS given_hits_then_first_replaced FOR TESTING RAISING cx_static_check.
    METHODS given_no_hit_then_unchanged FOR TESTING RAISING cx_static_check.
    METHODS given_literal_then_escaped FOR TESTING.
    METHODS given_literal_then_no_meaning FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_replacing IMPLEMENTATION.

  METHOD setup.
    digits = zcl_regex=>of( `[0-9]+` ).
  ENDMETHOD.

  METHOD given_hits_then_all_replaced.
    cl_abap_unit_assert=>assert_equals(
      act = digits->replace_all( text        = sample
                                 replacement = `#` )
      exp = `a#b#c#`
      msg = 'Not every occurrence was replaced' ).
  ENDMETHOD.

  METHOD given_groups_then_referenced.
    DATA(pairs) = zcl_regex=>of( `([a-z]+)-([0-9]+)` ).

    cl_abap_unit_assert=>assert_equals(
      act = pairs->replace_all( text        = `abc-12 def-34`
                                replacement = `$2-$1` )
      exp = `12-abc 34-def`
      msg = 'Group references in the replacement were not resolved' ).
  ENDMETHOD.

  METHOD given_hits_then_first_replaced.
    cl_abap_unit_assert=>assert_equals(
      act = digits->replace_first( text        = sample
                                   replacement = `#` )
      exp = `a#b22c333`
      msg = 'More or less than the first occurrence was replaced' ).
  ENDMETHOD.

  METHOD given_no_hit_then_unchanged.
    cl_abap_unit_assert=>assert_equals(
      act = digits->replace_all( text        = `abc`
                                 replacement = `#` )
      exp = `abc`
      msg = 'A text without an occurrence was changed' ).
  ENDMETHOD.

  METHOD given_literal_then_escaped.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_regex=>literal( `a.b (c)` )
      exp = `a\.b\ \(c\)`
      msg = 'Metacharacters were not escaped with a backslash' ).
  ENDMETHOD.

  METHOD given_literal_then_no_meaning.
    DATA(regex) = zcl_regex=>of( zcl_regex=>literal( `1.5*2` ) ).

    cl_abap_unit_assert=>assert_equals(
      act = regex->is_match( `1.5*2` )
      exp = abap_true
      msg = 'The escaped text does not match itself' ).
    cl_abap_unit_assert=>assert_equals(
      act = regex->is_match( `1x5555` )
      exp = abap_false
      msg = 'The escaped metacharacters kept their meaning' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_splitting DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA comma TYPE REF TO zif_regex.

    METHODS setup RAISING zcx_regex.

    METHODS given_separators_then_parts FOR TESTING RAISING cx_static_check.
    METHODS given_no_separator_then_whole FOR TESTING RAISING cx_static_check.
    METHODS given_trailing_sep_then_empty FOR TESTING RAISING cx_static_check.
    METHODS given_leading_sep_then_empty FOR TESTING RAISING cx_static_check.
    METHODS given_empty_text_then_one_part FOR TESTING RAISING cx_static_check.
    METHODS given_zero_length_then_ignored FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_splitting IMPLEMENTATION.

  METHOD setup.
    comma = zcl_regex=>of( `\s*,\s*` ).
  ENDMETHOD.

  METHOD given_separators_then_parts.
    cl_abap_unit_assert=>assert_equals(
      act = comma->split( `a , b,c` )
      exp = VALUE string_table( ( `a` ) ( `b` ) ( `c` ) )
      msg = 'The text was not cut at the separators' ).
  ENDMETHOD.

  METHOD given_no_separator_then_whole.
    cl_abap_unit_assert=>assert_equals(
      act = comma->split( `abc` )
      exp = VALUE string_table( ( `abc` ) )
      msg = 'A text without a separator is not returned as its only part' ).
  ENDMETHOD.

  METHOD given_trailing_sep_then_empty.
    cl_abap_unit_assert=>assert_equals(
      act = comma->split( `a,` )
      exp = VALUE string_table( ( `a` ) ( `` ) )
      msg = 'The empty part after a trailing separator was dropped' ).
  ENDMETHOD.

  METHOD given_leading_sep_then_empty.
    cl_abap_unit_assert=>assert_equals(
      act = comma->split( `,a` )
      exp = VALUE string_table( ( `` ) ( `a` ) )
      msg = 'The empty part before a leading separator was dropped' ).
  ENDMETHOD.

  METHOD given_empty_text_then_one_part.
    cl_abap_unit_assert=>assert_equals(
      act = comma->split( `` )
      exp = VALUE string_table( ( `` ) )
      msg = 'An empty text does not yield one empty part' ).
  ENDMETHOD.

  METHOD given_zero_length_then_ignored.
    cl_abap_unit_assert=>assert_equals(
      act = zcl_regex=>of( `x*` )->split( `ab` )
      exp = VALUE string_table( ( `ab` ) )
      msg = 'Occurrences of zero length cut the text' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_patterns DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_email_then_accepted FOR TESTING RAISING cx_static_check.
    METHODS given_bad_email_then_rejected FOR TESTING RAISING cx_static_check.
    METHODS given_url_then_accepted FOR TESTING RAISING cx_static_check.
    METHODS given_bad_url_then_rejected FOR TESTING RAISING cx_static_check.
    METHODS given_ipv4_then_accepted FOR TESTING RAISING cx_static_check.
    METHODS given_bad_ipv4_then_rejected FOR TESTING RAISING cx_static_check.
    METHODS given_uuid_then_accepted FOR TESTING RAISING cx_static_check.
    METHODS given_bad_uuid_then_rejected FOR TESTING RAISING cx_static_check.
    METHODS given_iso_date_then_accepted FOR TESTING RAISING cx_static_check.
    METHODS given_bad_iso_date_then_reject FOR TESTING RAISING cx_static_check.
    METHODS given_iso_time_then_accepted FOR TESTING RAISING cx_static_check.
    METHODS given_bad_iso_time_then_reject FOR TESTING RAISING cx_static_check.
    METHODS given_integer_then_accepted FOR TESTING RAISING cx_static_check.
    METHODS given_bad_integer_then_reject FOR TESTING RAISING cx_static_check.
    METHODS given_decimal_then_accepted FOR TESTING RAISING cx_static_check.
    METHODS given_bad_decimal_then_reject FOR TESTING RAISING cx_static_check.
    METHODS given_hex_then_accepted FOR TESTING RAISING cx_static_check.
    METHODS given_bad_hex_then_rejected FOR TESTING RAISING cx_static_check.
    METHODS given_alnum_then_accepted FOR TESTING RAISING cx_static_check.
    METHODS given_bad_alnum_then_rejected FOR TESTING RAISING cx_static_check.
    METHODS given_iban_then_accepted FOR TESTING RAISING cx_static_check.
    METHODS given_bad_iban_then_rejected FOR TESTING RAISING cx_static_check.
    METHODS given_semver_then_accepted FOR TESTING RAISING cx_static_check.
    METHODS given_bad_semver_then_rejected FOR TESTING RAISING cx_static_check.

    METHODS assert_accepts
      IMPORTING pattern TYPE string
                samples TYPE string_table
      RAISING   zcx_regex.

    METHODS assert_rejects
      IMPORTING pattern TYPE string
                samples TYPE string_table
      RAISING   zcx_regex.

ENDCLASS.


CLASS ltc_patterns IMPLEMENTATION.

  METHOD given_email_then_accepted.
    assert_accepts( pattern = zif_regex_patterns=>email
                    samples = VALUE #( ( `john.doe@example.com` )
                                       ( `first+tag@mail.example.co.uk` )
                                       ( `x_1%y@sub-domain.io` ) ) ).
  ENDMETHOD.

  METHOD given_bad_email_then_rejected.
    assert_rejects( pattern = zif_regex_patterns=>email
                    samples = VALUE #( ( `john.doe@example` )
                                       ( `john.doe.example.com` )
                                       ( `john@doe@example.com` )
                                       ( `john doe@example.com` )
                                       ( `@example.com` ) ) ).
  ENDMETHOD.

  METHOD given_url_then_accepted.
    assert_accepts( pattern = zif_regex_patterns=>url
                    samples = VALUE #( ( `https://example.com` )
                                       ( `http://localhost:8080/api/v1?x=1&y=2` )
                                       ( `https://sub.example.co.uk/path/to/page.html#top` ) ) ).
  ENDMETHOD.

  METHOD given_bad_url_then_rejected.
    assert_rejects( pattern = zif_regex_patterns=>url
                    samples = VALUE #( ( `example.com` )
                                       ( `ftp://example.com` )
                                       ( `https://` )
                                       ( `https://exa mple.com` ) ) ).
  ENDMETHOD.

  METHOD given_ipv4_then_accepted.
    assert_accepts( pattern = zif_regex_patterns=>ipv4
                    samples = VALUE #( ( `0.0.0.0` )
                                       ( `192.168.1.254` )
                                       ( `255.255.255.255` ) ) ).
  ENDMETHOD.

  METHOD given_bad_ipv4_then_rejected.
    assert_rejects( pattern = zif_regex_patterns=>ipv4
                    samples = VALUE #( ( `256.1.1.1` )
                                       ( `192.168.1` )
                                       ( `192.168.01.1` )
                                       ( `192.168.1.1.1` )
                                       ( `a.b.c.d` ) ) ).
  ENDMETHOD.

  METHOD given_uuid_then_accepted.
    assert_accepts( pattern = zif_regex_patterns=>uuid
                    samples = VALUE #( ( `baf0a1e7-5fb0-1edf-b5e8-89f53894ca3a` )
                                       ( `BAF0A1E7-5FB0-1EDF-B5E8-89F53894CA3A` )
                                       ( `00000000-0000-0000-0000-000000000000` ) ) ).
  ENDMETHOD.

  METHOD given_bad_uuid_then_rejected.
    assert_rejects( pattern = zif_regex_patterns=>uuid
                    samples = VALUE #( ( `baf0a1e75fb01edfb5e889f53894ca3a` )
                                       ( `baf0a1e7-5fb0-1edf-b5e8-89f53894ca3` )
                                       ( `baf0a1e7-5fb0-1edf-b5e8-89f53894ca3g` ) ) ).
  ENDMETHOD.

  METHOD given_iso_date_then_accepted.
    assert_accepts( pattern = zif_regex_patterns=>iso_date
                    samples = VALUE #( ( `2026-09-07` )
                                       ( `1999-01-01` )
                                       ( `2024-12-31` ) ) ).
  ENDMETHOD.

  METHOD given_bad_iso_date_then_reject.
    assert_rejects( pattern = zif_regex_patterns=>iso_date
                    samples = VALUE #( ( `2026-13-01` )
                                       ( `2026-00-10` )
                                       ( `2026-09-32` )
                                       ( `2026-9-7` )
                                       ( `20260907` )
                                       ( `07.09.2026` ) ) ).
  ENDMETHOD.

  METHOD given_iso_time_then_accepted.
    assert_accepts( pattern = zif_regex_patterns=>iso_time
                    samples = VALUE #( ( `00:00` )
                                       ( `23:59:59` )
                                       ( `09:05:00` ) ) ).
  ENDMETHOD.

  METHOD given_bad_iso_time_then_reject.
    assert_rejects( pattern = zif_regex_patterns=>iso_time
                    samples = VALUE #( ( `24:00` )
                                       ( `12:60` )
                                       ( `12:30:60` )
                                       ( `9:05` )
                                       ( `123000` ) ) ).
  ENDMETHOD.

  METHOD given_integer_then_accepted.
    assert_accepts( pattern = zif_regex_patterns=>integer
                    samples = VALUE #( ( `0` )
                                       ( `42` )
                                       ( `-17` )
                                       ( `+3` ) ) ).
  ENDMETHOD.

  METHOD given_bad_integer_then_reject.
    assert_rejects( pattern = zif_regex_patterns=>integer
                    samples = VALUE #( ( `4.2` )
                                       ( `1,000` )
                                       ( `42a` )
                                       ( `-` )
                                       ( `` ) ) ).
  ENDMETHOD.

  METHOD given_decimal_then_accepted.
    assert_accepts( pattern = zif_regex_patterns=>decimal
                    samples = VALUE #( ( `12` )
                                       ( `12.5` )
                                       ( `-0.25` )
                                       ( `+.5` ) ) ).
  ENDMETHOD.

  METHOD given_bad_decimal_then_reject.
    assert_rejects( pattern = zif_regex_patterns=>decimal
                    samples = VALUE #( ( `12.` )
                                       ( `1,5` )
                                       ( `1.2.3` )
                                       ( `1e5` )
                                       ( `.` ) ) ).
  ENDMETHOD.

  METHOD given_hex_then_accepted.
    assert_accepts( pattern = zif_regex_patterns=>hex
                    samples = VALUE #( ( `00` )
                                       ( `deadBEEF` )
                                       ( `0123456789abcdefABCDEF` ) ) ).
  ENDMETHOD.

  METHOD given_bad_hex_then_rejected.
    assert_rejects( pattern = zif_regex_patterns=>hex
                    samples = VALUE #( ( `0x1F` )
                                       ( `G1` )
                                       ( `1 F` )
                                       ( `` ) ) ).
  ENDMETHOD.

  METHOD given_alnum_then_accepted.
    assert_accepts( pattern = zif_regex_patterns=>alphanumeric
                    samples = VALUE #( ( `abc123` )
                                       ( `Z` )
                                       ( `007` ) ) ).
  ENDMETHOD.

  METHOD given_bad_alnum_then_rejected.
    assert_rejects( pattern = zif_regex_patterns=>alphanumeric
                    samples = VALUE #( ( `abc_123` )
                                       ( `abc 123` )
                                       ( `abc-123` )
                                       ( `` ) ) ).
  ENDMETHOD.

  METHOD given_iban_then_accepted.
    assert_accepts( pattern = zif_regex_patterns=>iban
                    samples = VALUE #( ( `GR1601101250000000012300695` )
                                       ( `DE89370400440532013000` )
                                       ( `GB29NWBK60161331926819` ) ) ).
  ENDMETHOD.

  METHOD given_bad_iban_then_rejected.
    assert_rejects( pattern = zif_regex_patterns=>iban
                    samples = VALUE #( ( `GR16 0110 1250 0000 0001 2300 695` )
                                       ( `gr1601101250000000012300695` )
                                       ( `1601101250000000012300695` )
                                       ( `GR16011012` ) ) ).
  ENDMETHOD.

  METHOD given_semver_then_accepted.
    assert_accepts( pattern = zif_regex_patterns=>semantic_version
                    samples = VALUE #( ( `1.0.0` )
                                       ( `2.1.0-beta.1` )
                                       ( `2.1.0+build.7` )
                                       ( `10.20.30-rc.1+exp.sha.5114f85` ) ) ).
  ENDMETHOD.

  METHOD given_bad_semver_then_rejected.
    assert_rejects( pattern = zif_regex_patterns=>semantic_version
                    samples = VALUE #( ( `1.0` )
                                       ( `01.0.0` )
                                       ( `v1.0.0` )
                                       ( `1.0.0-` )
                                       ( `1.0.0 beta` ) ) ).
  ENDMETHOD.

  METHOD assert_accepts.
    DATA(regex) = zcl_regex=>of( pattern ).

    LOOP AT samples INTO DATA(sample).
      cl_abap_unit_assert=>assert_equals(
        act = regex->is_match( sample )
        exp = abap_true
        msg = |{ sample } was rejected by the pattern { pattern }| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD assert_rejects.
    DATA(regex) = zcl_regex=>of( pattern ).

    LOOP AT samples INTO DATA(sample).
      cl_abap_unit_assert=>assert_equals(
        act = regex->is_match( sample )
        exp = abap_false
        msg = |{ sample } was accepted by the pattern { pattern }| ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
