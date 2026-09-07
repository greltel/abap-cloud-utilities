*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
"! Cuts a text into words at separators and case boundaries.
CLASS lcl_words DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS of
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE zif_string_format=>word_list.

  PRIVATE SECTION.
    CONSTANTS: BEGIN OF kind,
                 separator TYPE i VALUE 0,
                 lower     TYPE i VALUE 1,
                 upper     TYPE i VALUE 2,
                 digit     TYPE i VALUE 3,
               END OF kind.

    " Unicode categories, so that letters and digits of every script count
    CONSTANTS letter_pattern TYPE string VALUE `\p{L}`.
    CONSTANTS digit_pattern TYPE string VALUE `\p{N}`.

    CLASS-METHODS character_at
      IMPORTING text          TYPE string
                offset        TYPE i
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS kind_of
      IMPORTING character     TYPE string
      RETURNING VALUE(result) TYPE i.

    CLASS-METHODS starts_new_word
      IMPORTING current       TYPE i
                previous      TYPE i
                next          TYPE i
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS lcl_words IMPLEMENTATION.

  METHOD of.
    DATA word TYPE string.

    DATA(total) = strlen( text ).

    DO total TIMES.
      DATA(offset) = sy-index - 1.
      DATA(character) = character_at( text   = text
                                      offset = offset ).
      DATA(current) = kind_of( character ).

      IF current = kind-separator.
        IF word IS NOT INITIAL.
          INSERT word INTO TABLE result.
          CLEAR word.
        ENDIF.
        CONTINUE.
      ENDIF.

      DATA(previous) = kind_of( character_at( text   = text
                                              offset = offset - 1 ) ).
      DATA(next) = kind_of( character_at( text   = text
                                          offset = offset + 1 ) ).
      IF word IS NOT INITIAL AND starts_new_word( current  = current
                                                  previous = previous
                                                  next     = next ) = abap_true.
        INSERT word INTO TABLE result.
        CLEAR word.
      ENDIF.

      word = word && character.
    ENDDO.

    IF word IS NOT INITIAL.
      INSERT word INTO TABLE result.
    ENDIF.
  ENDMETHOD.

  METHOD character_at.
    result = COND #( WHEN offset >= 0 AND offset < strlen( text )
                     THEN substring( val = text
                                     off = offset
                                     len = 1 )
                     ELSE `` ).
  ENDMETHOD.

  METHOD kind_of.
    IF character IS INITIAL.
      result = kind-separator.
      RETURN.
    ENDIF.

    IF matches( val  = character
                pcre = digit_pattern ).
      result = kind-digit.
      RETURN.
    ENDIF.

    DATA(upper) = to_upper( character ).
    DATA(lower) = to_lower( character ).

    IF upper <> lower.
      result = COND #( WHEN character = upper THEN kind-upper ELSE kind-lower ).
    ELSEIF matches( val  = character
                    pcre = letter_pattern ).
      " Letters of scripts without case behave like lower case letters
      result = kind-lower.
    ELSE.
      result = kind-separator.
    ENDIF.
  ENDMETHOD.

  METHOD starts_new_word.
    IF current <> kind-upper.
      result = abap_false.
      RETURN.
    ENDIF.

    DATA(after_lower_or_digit) = xsdbool( previous = kind-lower OR previous = kind-digit ).
    DATA(ends_acronym) = xsdbool( previous = kind-upper AND next = kind-lower ).

    result = xsdbool( after_lower_or_digit = abap_true OR ends_acronym = abap_true ).
  ENDMETHOD.

ENDCLASS.


"! Immutable formatting view on a text.
CLASS lcl_formatter DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_string_format.

    METHODS constructor
      IMPORTING text TYPE string.

  PRIVATE SECTION.
    CONSTANTS title_separator TYPE string VALUE ` `.
    CONSTANTS snake_separator TYPE string VALUE `_`.
    CONSTANTS kebab_separator TYPE string VALUE `-`.
    CONSTANTS fill_length TYPE i VALUE 1.

    DATA text TYPE string.

    METHODS ensure_width
      IMPORTING width TYPE i
      RAISING   zcx_string_format.

    METHODS ensure_fill
      IMPORTING fill TYPE string
      RAISING   zcx_string_format.

    METHODS missing
      IMPORTING width         TYPE i
      RETURNING VALUE(result) TYPE i.

    METHODS padded
      IMPORTING left          TYPE i
                right         TYPE i
                fill          TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_string_format.

    METHODS capitalized_words
      RETURNING VALUE(result) TYPE zif_string_format=>word_list.

    METHODS lower_words
      RETURNING VALUE(result) TYPE zif_string_format=>word_list.

    METHODS capitalized
      IMPORTING word          TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS lcl_formatter IMPLEMENTATION.

  METHOD constructor.
    me->text = text.
  ENDMETHOD.

  METHOD zif_string_format~as_text.
    result = text.
  ENDMETHOD.

  METHOD zif_string_format~align_left.
    ensure_width( width ).
    ensure_fill( fill ).

    result = padded( left  = 0
                     right = missing( width )
                     fill  = fill ).
  ENDMETHOD.

  METHOD zif_string_format~align_right.
    ensure_width( width ).
    ensure_fill( fill ).

    result = padded( left  = missing( width )
                     right = 0
                     fill  = fill ).
  ENDMETHOD.

  METHOD zif_string_format~center.
    ensure_width( width ).
    ensure_fill( fill ).

    DATA(total) = missing( width ).
    DATA(left) = total DIV 2.

    result = padded( left  = left
                     right = total - left
                     fill  = fill ).
  ENDMETHOD.

  METHOD zif_string_format~truncate.
    ensure_width( width ).

    IF strlen( text ) <= width.
      result = me.
      RETURN.
    ENDIF.

    result = NEW lcl_formatter( substring( val = text
                                           len = width ) ).
  ENDMETHOD.

  METHOD zif_string_format~shorten.
    DATA(marker_length) = strlen( marker ).

    IF width < marker_length.
      RAISE EXCEPTION NEW zcx_string_format( |A width of { width } leaves no room for the marker { marker }| ).
    ENDIF.

    IF strlen( text ) <= width.
      result = me.
      RETURN.
    ENDIF.

    DATA(kept) = substring( val = text
                            len = width - marker_length ).
    result = NEW lcl_formatter( kept && marker ).
  ENDMETHOD.

  METHOD zif_string_format~to_upper_case.
    result = NEW lcl_formatter( to_upper( text ) ).
  ENDMETHOD.

  METHOD zif_string_format~to_lower_case.
    result = NEW lcl_formatter( to_lower( text ) ).
  ENDMETHOD.

  METHOD zif_string_format~capitalize.
    IF text IS INITIAL.
      result = me.
      RETURN.
    ENDIF.

    DATA(first) = substring( val = text
                             len = 1 ).
    DATA(rest) = substring( val = text
                            off = 1 ).
    result = NEW lcl_formatter( to_upper( first ) && rest ).
  ENDMETHOD.

  METHOD zif_string_format~to_title_case.
    result = NEW lcl_formatter( concat_lines_of( table = capitalized_words( )
                                                 sep   = title_separator ) ).
  ENDMETHOD.

  METHOD zif_string_format~to_camel_case.
    DATA(words) = capitalized_words( ).

    IF words IS NOT INITIAL.
      words[ 1 ] = to_lower( words[ 1 ] ).
    ENDIF.

    result = NEW lcl_formatter( concat_lines_of( words ) ).
  ENDMETHOD.

  METHOD zif_string_format~to_pascal_case.
    result = NEW lcl_formatter( concat_lines_of( capitalized_words( ) ) ).
  ENDMETHOD.

  METHOD zif_string_format~to_snake_case.
    result = NEW lcl_formatter( concat_lines_of( table = lower_words( )
                                                 sep   = snake_separator ) ).
  ENDMETHOD.

  METHOD zif_string_format~to_kebab_case.
    result = NEW lcl_formatter( concat_lines_of( table = lower_words( )
                                                 sep   = kebab_separator ) ).
  ENDMETHOD.

  METHOD zif_string_format~words.
    result = lcl_words=>of( text ).
  ENDMETHOD.

  METHOD ensure_width.
    IF width < 0.
      RAISE EXCEPTION NEW zcx_string_format( |A width of { width } is negative| ).
    ENDIF.
  ENDMETHOD.

  METHOD ensure_fill.
    IF strlen( fill ) <> fill_length.
      RAISE EXCEPTION NEW zcx_string_format( |The fill { fill } must be exactly one character| ).
    ENDIF.
  ENDMETHOD.

  METHOD missing.
    result = nmax( val1 = width - strlen( text )
                   val2 = 0 ).
  ENDMETHOD.

  METHOD padded.
    IF left = 0 AND right = 0.
      result = me.
      RETURN.
    ENDIF.

    DATA(left_fill) = repeat( val = fill
                              occ = left ).
    DATA(right_fill) = repeat( val = fill
                               occ = right ).
    result = NEW lcl_formatter( left_fill && text && right_fill ).
  ENDMETHOD.

  METHOD capitalized_words.
    result = VALUE #( FOR word IN lcl_words=>of( text ) ( capitalized( word ) ) ).
  ENDMETHOD.

  METHOD lower_words.
    result = VALUE #( FOR word IN lcl_words=>of( text ) ( to_lower( word ) ) ).
  ENDMETHOD.

  METHOD capitalized.
    DATA(first) = substring( val = word
                             len = 1 ).
    DATA(rest) = substring( val = word
                            off = 1 ).
    result = to_upper( first ) && to_lower( rest ).
  ENDMETHOD.

ENDCLASS.


"! Parses a template text into literal and placeholder segments.
CLASS lcl_template_parser DEFINITION FINAL.

  PUBLIC SECTION.
    TYPES: BEGIN OF segment,
             is_placeholder TYPE abap_bool,
             text           TYPE string,
             key            TYPE string,
           END OF segment.
    TYPES segments TYPE STANDARD TABLE OF segment WITH EMPTY KEY.

    CONSTANTS opening_brace TYPE string VALUE `{`.
    CONSTANTS closing_brace TYPE string VALUE `}`.

    CLASS-METHODS parse
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE segments
      RAISING   zcx_string_format.

  PRIVATE SECTION.
    CONSTANTS placeholder_name_pattern TYPE string VALUE `[A-Za-z_][A-Za-z0-9_]*`.
    CONSTANTS not_found TYPE i VALUE -1.

    CLASS-METHODS character_at
      IMPORTING text          TYPE string
                offset        TYPE i
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS placeholder_name
      IMPORTING text          TYPE string
                offset        TYPE i
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_string_format.

ENDCLASS.


CLASS lcl_template_parser IMPLEMENTATION.

  METHOD parse.
    DATA literal TYPE string.

    DATA(total) = strlen( text ).
    DATA(offset) = 0.

    WHILE offset < total.
      DATA(character) = character_at( text   = text
                                      offset = offset ).
      DATA(following) = character_at( text   = text
                                      offset = offset + 1 ).

      IF character = following AND ( character = opening_brace OR character = closing_brace ).
        " A doubled brace stands for the brace itself
        literal = literal && character.
        offset = offset + 2.
        CONTINUE.
      ENDIF.

      IF character = closing_brace.
        RAISE EXCEPTION NEW zcx_string_format( |A closing brace at offset { offset } has no opening brace| ).
      ENDIF.

      IF character <> opening_brace.
        literal = literal && character.
        offset = offset + 1.
        CONTINUE.
      ENDIF.

      IF literal IS NOT INITIAL.
        INSERT VALUE #( text = literal ) INTO TABLE result.
        CLEAR literal.
      ENDIF.

      DATA(name) = placeholder_name( text   = text
                                     offset = offset ).
      INSERT VALUE #( is_placeholder = abap_true
                      text           = name
                      key            = to_upper( name ) ) INTO TABLE result.
      offset = offset + strlen( name ) + 2.
    ENDWHILE.

    IF literal IS NOT INITIAL.
      INSERT VALUE #( text = literal ) INTO TABLE result.
    ENDIF.
  ENDMETHOD.

  METHOD character_at.
    result = COND #( WHEN offset < strlen( text )
                     THEN substring( val = text
                                     off = offset
                                     len = 1 )
                     ELSE `` ).
  ENDMETHOD.

  METHOD placeholder_name.
    DATA(name_offset) = offset + 1.
    DATA(closing) = COND i( WHEN name_offset < strlen( text )
                            THEN find( val = text
                                       sub = closing_brace
                                       off = name_offset )
                            ELSE not_found ).

    IF closing = not_found.
      RAISE EXCEPTION NEW zcx_string_format( |The placeholder opened at offset { offset } is not closed| ).
    ENDIF.

    result = substring( val = text
                        off = name_offset
                        len = closing - name_offset ).

    DATA(is_valid_name) = xsdbool( matches( val  = result
                                            pcre = placeholder_name_pattern ) ).
    IF is_valid_name = abap_false.
      RAISE EXCEPTION NEW zcx_string_format( |\{{ result }\} is not a valid placeholder| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


"! Immutable template: parsed segments plus the values bound so far.
CLASS lcl_template DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_string_template.

    TYPES: BEGIN OF binding,
             name  TYPE string,
             value TYPE string,
           END OF binding.
    TYPES binding_table TYPE HASHED TABLE OF binding WITH UNIQUE KEY name.

    METHODS constructor
      IMPORTING segments TYPE lcl_template_parser=>segments
                bindings TYPE binding_table OPTIONAL.

  PRIVATE SECTION.
    TYPES type_kinds TYPE SORTED TABLE OF abap_typekind WITH UNIQUE KEY table_line.
    TYPES keys TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.

    CONSTANTS name_separator TYPE string VALUE `, `.

    DATA segments TYPE lcl_template_parser=>segments.
    DATA bindings TYPE binding_table.

    METHODS bound
      IMPORTING key           TYPE string
                value         TYPE string
      RETURNING VALUE(result) TYPE REF TO lcl_template.

    METHODS rendered
      RETURNING VALUE(result) TYPE string.

    METHODS unresolved
      RETURNING VALUE(result) TYPE zif_string_template=>names.

    METHODS is_deep
      IMPORTING component     TYPE abap_compdescr
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS lcl_template IMPLEMENTATION.

  METHOD constructor.
    me->segments = segments.
    me->bindings = bindings.
  ENDMETHOD.

  METHOD zif_string_template~placeholders.
    DATA seen TYPE keys.

    LOOP AT segments INTO DATA(segment) WHERE is_placeholder = abap_true.
      IF line_exists( seen[ table_line = segment-key ] ).
        CONTINUE.
      ENDIF.
      INSERT segment-key INTO TABLE seen.
      INSERT segment-text INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_string_template~with.
    result = bound( key   = to_upper( name )
                    value = |{ value }| ).
  ENDMETHOD.

  METHOD zif_string_template~with_pairs.
    DATA(template) = me.

    LOOP AT pairs INTO DATA(pair).
      template = template->bound( key   = to_upper( pair-name )
                                  value = pair-value ).
    ENDLOOP.

    result = template.
  ENDMETHOD.

  METHOD zif_string_template~with_structure.
    DATA(description) = cl_abap_typedescr=>describe_by_data( structure ).

    IF description->kind <> cl_abap_typedescr=>kind_struct.
      RAISE EXCEPTION NEW zcx_string_format( `Only a structure can fill a template by component names` ).
    ENDIF.

    DATA(structure_description) = CAST cl_abap_structdescr( description ).
    DATA(template) = me.

    LOOP AT structure_description->components INTO DATA(component).
      IF is_deep( component ) = abap_true.
        CONTINUE.
      ENDIF.

      ASSIGN COMPONENT component-name OF STRUCTURE structure TO FIELD-SYMBOL(<value>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      template = template->bound( key   = to_upper( CONV string( component-name ) )
                                  value = |{ <value> }| ).
    ENDLOOP.

    result = template.
  ENDMETHOD.

  METHOD zif_string_template~render.
    DATA(missing) = unresolved( ).

    IF missing IS NOT INITIAL.
      DATA(names) = concat_lines_of( table = missing
                                     sep   = name_separator ).
      RAISE EXCEPTION NEW zcx_string_format( |No value for the placeholders { names }| ).
    ENDIF.

    result = rendered( ).
  ENDMETHOD.

  METHOD zif_string_template~render_partial.
    result = rendered( ).
  ENDMETHOD.

  METHOD bound.
    DATA(new_bindings) = bindings.

    IF line_exists( new_bindings[ name = key ] ).
      new_bindings[ name = key ]-value = value.
    ELSE.
      INSERT VALUE #( name  = key
                      value = value ) INTO TABLE new_bindings.
    ENDIF.

    result = NEW lcl_template( segments = segments
                               bindings = new_bindings ).
  ENDMETHOD.

  METHOD rendered.
    LOOP AT segments INTO DATA(segment).
      IF segment-is_placeholder = abap_false.
        result = result && segment-text.
      ELSEIF line_exists( bindings[ name = segment-key ] ).
        result = result && bindings[ name = segment-key ]-value.
      ELSE.
        result = result && lcl_template_parser=>opening_brace && segment-text && lcl_template_parser=>closing_brace.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD unresolved.
    DATA(names) = zif_string_template~placeholders( ).

    LOOP AT names INTO DATA(placeholder).
      IF line_exists( bindings[ name = to_upper( placeholder ) ] ).
        CONTINUE.
      ENDIF.
      INSERT placeholder INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD is_deep.
    DATA(deep_kinds) = VALUE type_kinds( ( cl_abap_typedescr=>typekind_struct1 )
                                         ( cl_abap_typedescr=>typekind_struct2 )
                                         ( cl_abap_typedescr=>typekind_table )
                                         ( cl_abap_typedescr=>typekind_dref )
                                         ( cl_abap_typedescr=>typekind_oref )
                                         ( cl_abap_typedescr=>typekind_iref ) ).

    result = xsdbool( line_exists( deep_kinds[ table_line = component-type_kind ] ) ).
  ENDMETHOD.

ENDCLASS.
