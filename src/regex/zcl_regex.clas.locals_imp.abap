*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
"! One occurrence of a pattern in a text. Immutable value object built from the
"! kernel match result; the text is kept so groups can be cut out on demand.
CLASS lcl_match DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_regex_match.

    CLASS-METHODS of
      IMPORTING text          TYPE string
                found         TYPE match_result
      RETURNING VALUE(result) TYPE REF TO zif_regex_match.

    CLASS-METHODS none
      RETURNING VALUE(result) TYPE REF TO zif_regex_match.

    METHODS constructor
      IMPORTING text   TYPE string
                found  TYPE match_result
                exists TYPE abap_bool.

  PRIVATE SECTION.
    CONSTANTS not_found_offset TYPE i VALUE -1.

    DATA text TYPE string.
    DATA found TYPE match_result.
    DATA exists TYPE abap_bool.

    "! Cuts a segment out of the text. An offset of -1 marks a capture group
    "! that did not take part in the match; it yields an empty string.
    METHODS cut
      IMPORTING offset        TYPE i
                length        TYPE i
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


"! A compiled PCRE pattern. Every operation creates a fresh matcher for the
"! text at hand, so one expression can be shared freely between callers.
"! Failures of the kernel engine are wrapped into ZCX_REGEX.
CLASS lcl_regex DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_regex.

    METHODS constructor
      IMPORTING regex TYPE REF TO cl_abap_regex.

  PRIVATE SECTION.
    DATA regex TYPE REF TO cl_abap_regex.

    METHODS all_results
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE match_result_tab
      RAISING   zcx_regex.

    METHODS failure_text
      IMPORTING cause         TYPE REF TO cx_root
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


"! Turns a pattern into a compiled expression and escapes literals. The only
"! place that talks to CL_ABAP_REGEX directly.
CLASS lcl_compiler DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS compile
      IMPORTING pattern       TYPE string
                options       TYPE zcl_regex=>ty_options
      RETURNING VALUE(result) TYPE REF TO zif_regex
      RAISING   zcx_regex.

    CLASS-METHODS escape_literal
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    "! Every PCRE metacharacter, plus # and blank so the result also survives
    "! extended mode. Written for the extended mode of the replace( ) function,
    "! where the blank must sit inside the class to count.
    CONSTANTS metacharacters TYPE string VALUE `([\\^$.|?*+()\[\]{}# ])`.
    CONSTANTS escaped_metacharacter TYPE string VALUE `\\$1`.

ENDCLASS.


CLASS lcl_match IMPLEMENTATION.

  METHOD of.
    result = NEW lcl_match( text   = text
                            found  = found
                            exists = abap_true ).
  ENDMETHOD.

  METHOD none.
    result = NEW lcl_match( text   = ``
                            found  = VALUE #( offset = not_found_offset )
                            exists = abap_false ).
  ENDMETHOD.

  METHOD constructor.
    me->text = text.
    me->found = found.
    me->exists = exists.
  ENDMETHOD.

  METHOD zif_regex_match~is_found.
    result = exists.
  ENDMETHOD.

  METHOD zif_regex_match~value.
    result = cut( offset = found-offset
                  length = found-length ).
  ENDMETHOD.

  METHOD zif_regex_match~offset.
    result = found-offset.
  ENDMETHOD.

  METHOD zif_regex_match~length.
    result = found-length.
  ENDMETHOD.

  METHOD zif_regex_match~group.
    IF index = 0.
      result = zif_regex_match~value( ).
    ELSEIF line_exists( found-submatches[ index ] ).
      result = cut( offset = found-submatches[ index ]-offset
                    length = found-submatches[ index ]-length ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_regex_match~groups.
    result = VALUE #( FOR submatch IN found-submatches
                      ( cut( offset = submatch-offset
                             length = submatch-length ) ) ).
  ENDMETHOD.

  METHOD zif_regex_match~group_count.
    result = lines( found-submatches ).
  ENDMETHOD.

  METHOD cut.
    IF offset >= 0.
      result = substring( val = text
                          off = offset
                          len = length ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_regex IMPLEMENTATION.

  METHOD constructor.
    me->regex = regex.
  ENDMETHOD.

  METHOD zif_regex~pattern.
    result = regex->pattern.
  ENDMETHOD.

  METHOD zif_regex~is_match.
    TRY.
        result = regex->create_matcher( text = text )->match( ).
      CATCH cx_sy_matcher INTO DATA(cause).
        RAISE EXCEPTION NEW zcx_regex( text     = failure_text( cause )
                                       previous = cause ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_regex~occurs_in.
    TRY.
        result = regex->create_matcher( text = text )->find_next( ).
      CATCH cx_sy_matcher INTO DATA(cause).
        RAISE EXCEPTION NEW zcx_regex( text     = failure_text( cause )
                                       previous = cause ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_regex~first_match.
    TRY.
        DATA(matcher) = regex->create_matcher( text = text ).

        result = COND #( WHEN matcher->find_next( ) = abap_true
                         THEN lcl_match=>of( text  = text
                                             found = matcher->get_match( ) )
                         ELSE lcl_match=>none( ) ).
      CATCH cx_sy_matcher INTO DATA(cause).
        RAISE EXCEPTION NEW zcx_regex( text     = failure_text( cause )
                                       previous = cause ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_regex~all_matches.
    result = VALUE #( FOR found IN all_results( text )
                      ( lcl_match=>of( text  = text
                                       found = found ) ) ).
  ENDMETHOD.

  METHOD zif_regex~match_count.
    result = lines( all_results( text ) ).
  ENDMETHOD.

  METHOD zif_regex~extract_all.
    result = VALUE #( FOR found IN all_results( text )
                      ( substring( val = text
                                   off = found-offset
                                   len = found-length ) ) ).
  ENDMETHOD.

  METHOD zif_regex~replace_all.
    TRY.
        DATA(matcher) = regex->create_matcher( text = text ).

        matcher->replace_all( replacement ).
        result = matcher->text.
      CATCH cx_sy_matcher INTO DATA(cause).
        RAISE EXCEPTION NEW zcx_regex( text     = failure_text( cause )
                                       previous = cause ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_regex~replace_first.
    TRY.
        DATA(matcher) = regex->create_matcher( text = text ).

        matcher->replace_next( replacement ).
        result = matcher->text.
      CATCH cx_sy_matcher INTO DATA(cause).
        RAISE EXCEPTION NEW zcx_regex( text     = failure_text( cause )
                                       previous = cause ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_regex~split.
    DATA(start) = 0.

    " A zero-length occurrence would cut nothing and is skipped
    LOOP AT all_results( text ) INTO DATA(found) WHERE length > 0.
      INSERT substring( val = text
                        off = start
                        len = found-offset - start ) INTO TABLE result.
      start = found-offset + found-length.
    ENDLOOP.

    INSERT substring( val = text
                      off = start ) INTO TABLE result.
  ENDMETHOD.

  METHOD all_results.
    TRY.
        result = regex->create_matcher( text = text )->find_all( ).
      CATCH cx_sy_matcher INTO DATA(cause).
        RAISE EXCEPTION NEW zcx_regex( text     = failure_text( cause )
                                       previous = cause ).
    ENDTRY.
  ENDMETHOD.

  METHOD failure_text.
    result = |Pattern { regex->pattern } could not be applied: { cause->get_text( ) }|.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_compiler IMPLEMENTATION.

  METHOD compile.
    IF pattern IS INITIAL.
      RAISE EXCEPTION NEW zcx_regex( `An empty pattern is not a regular expression` ).
    ENDIF.

    TRY.
        result = NEW lcl_regex( cl_abap_regex=>create_pcre( pattern          = pattern
                                                            ignore_case      = options-ignore_case
                                                            enable_multiline = options-multiline
                                                            dot_all          = options-dot_all
                                                            extended         = options-extended ) ).
      CATCH cx_sy_regex cx_sy_matcher INTO DATA(cause).
        RAISE EXCEPTION NEW zcx_regex( text     = |Pattern { pattern } is not a valid regular expression: | &&
                                                  cause->get_text( )
                                       previous = cause ).
    ENDTRY.
  ENDMETHOD.

  METHOD escape_literal.
    result = replace( val  = text
                      pcre = metacharacters
                      with = escaped_metacharacter
                      occ  = 0 ).
  ENDMETHOD.

ENDCLASS.
