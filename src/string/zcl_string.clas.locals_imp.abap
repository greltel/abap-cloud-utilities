*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
"! Immutable view on a text.
CLASS lcl_string DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_string.

    METHODS constructor
      IMPORTING text TYPE string.

  PRIVATE SECTION.
    TYPES: BEGIN OF match,
             found     TYPE abap_bool,
             content   TYPE string,
             remainder TYPE string,
           END OF match.

    CONSTANTS not_found TYPE i VALUE -1.

    DATA text TYPE string.

    METHODS trimmed
      IMPORTING source        TYPE string
                characters    TYPE string
      RETURNING VALUE(result) TYPE string.

    METHODS all_parts
      IMPORTING source        TYPE string
                delimiter     TYPE string
      RETURNING VALUE(result) TYPE zif_string=>segments.

    METHODS rest_of
      IMPORTING source        TYPE string
                offset        TYPE i
      RETURNING VALUE(result) TYPE string.

    METHODS first_between
      IMPORTING source        TYPE string
                after         TYPE string
                before        TYPE string
      RETURNING VALUE(result) TYPE match.

ENDCLASS.


CLASS lcl_string IMPLEMENTATION.

  METHOD constructor.
    me->text = text.
  ENDMETHOD.

  METHOD zif_string~as_text.
    result = text.
  ENDMETHOD.

  METHOD zif_string~length.
    result = strlen( text ).
  ENDMETHOD.

  METHOD zif_string~trim.
    result = NEW lcl_string( trimmed( source     = text
                                      characters = characters ) ).
  ENDMETHOD.

  METHOD zif_string~split_by.
    IF delimiter IS INITIAL.
      RAISE EXCEPTION NEW zcx_string( `Splitting a text needs a delimiter` ).
    ENDIF.

    result = all_parts( source    = text
                        delimiter = delimiter ).
  ENDMETHOD.

  METHOD zif_string~split_tokens.
    DATA(parts) = zif_string~split_by( delimiter ).

    LOOP AT parts INTO DATA(part).
      DATA(token) = trimmed( source     = part
                             characters = ` ` ).
      IF token IS NOT INITIAL.
        INSERT token INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_string~split_lines.
    IF text IS INITIAL.
      RETURN.
    ENDIF.

    DATA(line_break) = |\n|.

    DATA(normalized) = replace( val  = text
                                sub  = |\r\n|
                                with = line_break
                                occ  = 0 ).
    normalized = replace( val  = normalized
                          sub  = |\r|
                          with = line_break
                          occ  = 0 ).

    DATA(text_length) = strlen( normalized ).
    DATA(last_character) = substring( val = normalized
                                      off = text_length - 1 ).
    IF last_character = line_break.
      normalized = substring( val = normalized
                              len = text_length - 1 ).
    ENDIF.

    result = all_parts( source    = normalized
                        delimiter = line_break ).
  ENDMETHOD.

  METHOD zif_string~split_fixed.
    IF size < 1.
      RAISE EXCEPTION NEW zcx_string( `A chunk needs at least one character` ).
    ENDIF.

    DATA(total) = strlen( text ).
    DATA(offset) = 0.

    WHILE offset < total.
      DATA(chunk_length) = nmin( val1 = size
                                 val2 = total - offset ).
      DATA(chunk) = substring( val = text
                               off = offset
                               len = chunk_length ).
      INSERT chunk INTO TABLE result.
      offset = offset + chunk_length.
    ENDWHILE.
  ENDMETHOD.

  METHOD zif_string~split_pairs.
    IF value_delimiter IS INITIAL.
      RAISE EXCEPTION NEW zcx_string( `Name and value need a delimiter` ).
    ENDIF.

    DATA(entries) = zif_string~split_tokens( pair_delimiter ).

    LOOP AT entries INTO DATA(entry).
      DATA(separator) = find( val = entry
                              sub = value_delimiter ).
      IF separator = not_found.
        INSERT VALUE #( name = entry ) INTO TABLE result.
        CONTINUE.
      ENDIF.

      DATA(raw_name) = substring( val = entry
                                  len = separator ).
      DATA(raw_value) = rest_of( source = entry
                                 offset = separator + strlen( value_delimiter ) ).
      DATA(pair_name) = trimmed( source     = raw_name
                                 characters = ` ` ).
      DATA(pair_value) = trimmed( source     = raw_value
                                  characters = ` ` ).

      INSERT VALUE #( name  = pair_name
                      value = pair_value ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_string~extract_between.
    DATA(hit) = first_between( source = text
                               after  = after
                               before = before ).
    result = NEW lcl_string( hit-content ).
  ENDMETHOD.

  METHOD zif_string~extract_all_between.
    DATA(rest) = text.

    WHILE rest IS NOT INITIAL.
      DATA(hit) = first_between( source = rest
                                 after  = after
                                 before = before ).
      IF hit-found = abap_false.
        RETURN.
      ENDIF.

      INSERT hit-content INTO TABLE result.
      rest = hit-remainder.
    ENDWHILE.
  ENDMETHOD.

  METHOD trimmed.
    result = source.
    IF source IS INITIAL OR characters IS INITIAL.
      RETURN.
    ENDIF.

    DATA(first) = find_any_not_of( val = source
                                   sub = characters ).
    IF first = not_found.
      CLEAR result.
      RETURN.
    ENDIF.

    DATA(last) = find_any_not_of( val = source
                                  sub = characters
                                  occ = -1 ).
    result = substring( val = source
                        off = first
                        len = last - first + 1 ).
  ENDMETHOD.

  METHOD all_parts.
    SPLIT source AT delimiter INTO TABLE result.

    DATA(expected) = count( val = source
                            sub = delimiter ) + 1.
    DATA(missing) = expected - lines( result ).

    DO missing TIMES.
      INSERT `` INTO TABLE result.
    ENDDO.
  ENDMETHOD.

  METHOD rest_of.
    DATA(available) = strlen( source ).
    IF offset < available.
      result = substring( val = source
                          off = offset ).
    ENDIF.
  ENDMETHOD.

  METHOD first_between.
    IF after IS INITIAL OR before IS INITIAL.
      RETURN.
    ENDIF.

    DATA(start) = find( val = source
                        sub = after ).
    IF start = not_found.
      RETURN.
    ENDIF.

    DATA(tail) = rest_of( source = source
                          offset = start + strlen( after ) ).
    DATA(stop) = find( val = tail
                       sub = before ).
    IF stop = not_found.
      RETURN.
    ENDIF.

    result-found = abap_true.
    result-content = substring( val = tail
                                len = stop ).
    result-remainder = rest_of( source = tail
                                offset = stop + strlen( before ) ).
  ENDMETHOD.

ENDCLASS.
