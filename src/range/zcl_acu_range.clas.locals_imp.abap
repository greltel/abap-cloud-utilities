*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
"! The text a condition holds for a value. A string template writes a number
"! the way source code does - a leading minus sign, a decimal point, nothing
"! else - whereas a plain assignment to a string leaves a blank behind a
"! positive number and puts the sign of a negative one at its end.
CLASS lcl_text DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS of
      IMPORTING value         TYPE simple
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


"! The ten options a condition can carry, grouped by what they need: an
"! interval reads the high value as well, a pattern needs a character-like
"! field to be compared with.
CLASS lcl_option DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS is_known
      IMPORTING option        TYPE csequence
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS is_interval
      IMPORTING option        TYPE csequence
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS is_pattern
      IMPORTING option        TYPE csequence
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


"! One column of a ranges table - sign, option, low or high - seen through
"! its elementary type. Reads the column as text and writes a text into it,
"! refusing whatever a plain assignment would silently cut off, round or turn
"! into something else: a range that quietly differs from the conditions it
"! was built from selects the wrong data.
CLASS lcl_column DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES ty_nature TYPE c LENGTH 1.

    CLASS-METHODS of
      IMPORTING component     TYPE abap_compdescr
      RETURNING VALUE(result) TYPE REF TO lcl_column
      RAISING   zcx_range.

    METHODS constructor
      IMPORTING name     TYPE string
                nature   TYPE ty_nature
                capacity TYPE i.

    METHODS read
      IMPORTING row           TYPE any
      RETURNING VALUE(result) TYPE string.

    METHODS write
      IMPORTING text TYPE string
      CHANGING  row  TYPE any
      RAISING   zcx_range.

    METHODS holds_patterns
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF natures,
        text       TYPE ty_nature VALUE 'S',
        fixed_text TYPE ty_nature VALUE 'C',
        digits     TYPE ty_nature VALUE 'N',
        date_time  TYPE ty_nature VALUE 'D',
        number     TYPE ty_nature VALUE 'P',
        float      TYPE ty_nature VALUE 'F',
        bytes      TYPE ty_nature VALUE 'X',
        instant    TYPE ty_nature VALUE 'U',
      END OF natures.

    CONSTANTS unlimited TYPE i VALUE 0.
    CONSTANTS digits TYPE string VALUE `0123456789`.
    CONSTANTS hex_digits TYPE string VALUE `0123456789ABCDEF`.
    CONSTANTS digits_per_byte TYPE i VALUE 2.
    CONSTANTS blank TYPE string VALUE ` `.
    CONSTANTS zero TYPE string VALUE `0`.

    DATA name TYPE string.
    DATA nature TYPE ty_nature.
    DATA capacity TYPE i.

    CLASS-METHODS nature_of
      IMPORTING component     TYPE abap_compdescr
      RETURNING VALUE(result) TYPE ty_nature
      RAISING   zcx_range.

    CLASS-METHODS capacity_of
      IMPORTING component     TYPE abap_compdescr
      RETURNING VALUE(result) TYPE i.

    METHODS write_fixed_text
      IMPORTING text  TYPE string
      CHANGING  field TYPE any
      RAISING   zcx_range.

    METHODS write_digits
      IMPORTING text  TYPE string
      CHANGING  field TYPE any
      RAISING   zcx_range.

    METHODS write_date_time
      IMPORTING text  TYPE string
      CHANGING  field TYPE any
      RAISING   zcx_range.

    METHODS write_number
      IMPORTING text  TYPE string
      CHANGING  field TYPE any
      RAISING   zcx_range.

    METHODS write_bytes
      IMPORTING text  TYPE string
      CHANGING  field TYPE any
      RAISING   zcx_range.

    METHODS write_instant
      IMPORTING text  TYPE string
      CHANGING  field TYPE any
      RAISING   zcx_range.

    METHODS ensure_fits
      IMPORTING text  TYPE string
                units TYPE i
      RAISING   zcx_range.

ENDCLASS.


"! Everything that touches a table whose type is only known at run time: reads
"! the rows of any ranges table into conditions, and fills any ranges table
"! with conditions. A table counts as a ranges table when its rows have the
"! components sign, option, low and high with elementary types.
CLASS lcl_ranges_table DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS read
      IMPORTING range         TYPE ANY TABLE
      RETURNING VALUE(result) TYPE zif_range=>ty_conditions
      RAISING   zcx_range.

    "! Replaces the content of the table behind the reference. The rows are
    "! collected in a copy first, so the table changes only when every
    "! condition could be written.
    CLASS-METHODS fill
      IMPORTING conditions TYPE zif_range=>ty_conditions
                target     TYPE REF TO data
      RAISING   zcx_range.

  PRIVATE SECTION.
    CONSTANTS:
      BEGIN OF component,
        sign   TYPE string VALUE `SIGN`,
        option TYPE string VALUE `OPTION`,
        low    TYPE string VALUE `LOW`,
        high   TYPE string VALUE `HIGH`,
      END OF component.

    DATA sign_column TYPE REF TO lcl_column.
    DATA option_column TYPE REF TO lcl_column.
    DATA low_column TYPE REF TO lcl_column.
    DATA high_column TYPE REF TO lcl_column.

    CLASS-METHODS layout_of
      IMPORTING table_type    TYPE REF TO cl_abap_typedescr
      RETURNING VALUE(result) TYPE REF TO lcl_ranges_table
      RAISING   zcx_range.

    CLASS-METHODS column_of
      IMPORTING name          TYPE string
                components    TYPE abap_compdescr_tab
      RETURNING VALUE(result) TYPE REF TO lcl_column
      RAISING   zcx_range.

    METHODS condition_of
      IMPORTING row           TYPE any
                row_number    TYPE i
      RETURNING VALUE(result) TYPE zif_range=>ty_condition
      RAISING   zcx_range.

    METHODS write_row
      IMPORTING condition TYPE zif_range=>ty_condition
      CHANGING  row       TYPE any
      RAISING   zcx_range.

ENDCLASS.


"! Immutable range. The conditions are kept as text; the first time a value
"! of some kind is tested they are written once into a ranges table of the
"! type that kind is compared in, and from then on the kernel answers with
"! its own IN - the same rules a WHERE clause or a selection screen applies,
"! at the cost of one statement per call.
CLASS lcl_range DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_range.

    METHODS constructor
      IMPORTING conditions TYPE zif_range=>ty_conditions.

  PRIVATE SECTION.
    TYPES ty_family TYPE c LENGTH 1.

    CONSTANTS:
      BEGIN OF family,
        text    TYPE ty_family VALUE 'C',
        number  TYPE ty_family VALUE 'P',
        date    TYPE ty_family VALUE 'D',
        time    TYPE ty_family VALUE 'T',
        instant TYPE ty_family VALUE 'U',
        bytes   TYPE ty_family VALUE 'X',
      END OF family.

    DATA conditions TYPE zif_range=>ty_conditions.
    DATA texts TYPE RANGE OF string.
    DATA numbers TYPE RANGE OF decfloat34.
    DATA dates TYPE RANGE OF d.
    DATA times TYPE RANGE OF t.
    DATA instants TYPE RANGE OF utclong.
    DATA byte_strings TYPE RANGE OF xstring.

    METHODS family_of
      IMPORTING value         TYPE simple
      RETURNING VALUE(result) TYPE ty_family
      RAISING   zcx_range.

    METHODS covers_text
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_range.

    METHODS covers_number
      IMPORTING number        TYPE decfloat34
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_range.

    METHODS covers_date
      IMPORTING date          TYPE d
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_range.

    METHODS covers_time
      IMPORTING time          TYPE t
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_range.

    METHODS covers_instant
      IMPORTING instant       TYPE utclong
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_range.

    METHODS covers_bytes
      IMPORTING bytes         TYPE xstring
      RETURNING VALUE(result) TYPE abap_bool
      RAISING   zcx_range.

ENDCLASS.


"! Collects conditions in the order of the calls and keeps each one once.
"! The chain cannot raise, so the first call that could not be turned into
"! conditions is remembered here and raised when the range is built.
CLASS lcl_builder DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_range_builder.

  PRIVATE SECTION.
    DATA conditions TYPE zif_range=>ty_conditions.
    DATA known TYPE HASHED TABLE OF zif_range=>ty_condition WITH UNIQUE KEY sign option low high.
    DATA mistake TYPE REF TO zcx_range.

    METHODS add
      IMPORTING condition TYPE zif_range=>ty_condition.

    METHODS add_value
      IMPORTING sign   TYPE zif_range=>ty_sign
                option TYPE zif_range=>ty_option
                value  TYPE simple.

    METHODS add_interval
      IMPORTING sign TYPE zif_range=>ty_sign
                low  TYPE simple
                high TYPE simple.

    METHODS add_values
      IMPORTING sign   TYPE zif_range=>ty_sign
                values TYPE ANY TABLE.

    METHODS remember
      IMPORTING error TYPE REF TO zcx_range.

ENDCLASS.


CLASS lcl_text IMPLEMENTATION.

  METHOD of.
    result = |{ value }|.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_option IMPLEMENTATION.

  METHOD is_known.
    DATA(is_equality) = xsdbool( option = zif_range=>option-equal OR option = zif_range=>option-not_equal ).
    DATA(is_lower_border) = xsdbool( option = zif_range=>option-greater_than
                                     OR option = zif_range=>option-greater_or_equal ).
    DATA(is_upper_border) = xsdbool( option = zif_range=>option-less_than
                                     OR option = zif_range=>option-less_or_equal ).
    DATA(is_single_value) = xsdbool( is_equality = abap_true
                                     OR is_lower_border = abap_true
                                     OR is_upper_border = abap_true ).

    result = xsdbool( is_single_value = abap_true
                      OR is_interval( option ) = abap_true
                      OR is_pattern( option ) = abap_true ).
  ENDMETHOD.

  METHOD is_interval.
    result = xsdbool( option = zif_range=>option-between OR option = zif_range=>option-not_between ).
  ENDMETHOD.

  METHOD is_pattern.
    result = xsdbool( option = zif_range=>option-pattern OR option = zif_range=>option-not_pattern ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_column IMPLEMENTATION.

  METHOD of.
    result = NEW #( name     = CONV #( component-name )
                    nature   = nature_of( component )
                    capacity = capacity_of( component ) ).
  ENDMETHOD.

  METHOD constructor.
    me->name = name.
    me->nature = nature.
    me->capacity = capacity.
  ENDMETHOD.

  METHOD nature_of.
    CASE component-type_kind.
      WHEN cl_abap_typedescr=>typekind_string.
        result = natures-text.
      WHEN cl_abap_typedescr=>typekind_char.
        result = natures-fixed_text.
      WHEN cl_abap_typedescr=>typekind_num.
        result = natures-digits.
      WHEN cl_abap_typedescr=>typekind_date
          OR cl_abap_typedescr=>typekind_time.
        result = natures-date_time.
      WHEN cl_abap_typedescr=>typekind_int
          OR cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int2
          OR cl_abap_typedescr=>typekind_int8
          OR cl_abap_typedescr=>typekind_packed
          OR cl_abap_typedescr=>typekind_decfloat16
          OR cl_abap_typedescr=>typekind_decfloat34.
        result = natures-number.
      WHEN cl_abap_typedescr=>typekind_float.
        result = natures-float.
      WHEN cl_abap_typedescr=>typekind_hex
          OR cl_abap_typedescr=>typekind_xstring.
        result = natures-bytes.
      WHEN cl_abap_typedescr=>typekind_utclong.
        result = natures-instant.
      WHEN OTHERS.
        RAISE EXCEPTION NEW zcx_range(
          text = |The table is not a ranges table: the type of its component { component-name } cannot hold a value| ).
    ENDCASE.
  ENDMETHOD.

  METHOD capacity_of.
    CASE component-type_kind.
      WHEN cl_abap_typedescr=>typekind_char
          OR cl_abap_typedescr=>typekind_num
          OR cl_abap_typedescr=>typekind_date
          OR cl_abap_typedescr=>typekind_time.
        result = component-length DIV cl_abap_char_utilities=>charsize.
      WHEN cl_abap_typedescr=>typekind_hex.
        result = component-length.
      WHEN OTHERS.
        result = unlimited.
    ENDCASE.
  ENDMETHOD.

  METHOD read.
    FIELD-SYMBOLS <field> TYPE simple.

    ASSIGN COMPONENT name OF STRUCTURE row TO <field>.
    ASSERT sy-subrc = 0.

    result = lcl_text=>of( <field> ).
  ENDMETHOD.

  METHOD write.
    ASSIGN COMPONENT name OF STRUCTURE row TO FIELD-SYMBOL(<field>).
    ASSERT sy-subrc = 0.

    IF text IS INITIAL.
      CLEAR <field>.
      RETURN.
    ENDIF.

    CASE nature.
      WHEN natures-text.
        <field> = text.
      WHEN natures-fixed_text.
        write_fixed_text( EXPORTING text  = text
                          CHANGING  field = <field> ).
      WHEN natures-digits.
        write_digits( EXPORTING text  = text
                      CHANGING  field = <field> ).
      WHEN natures-date_time.
        write_date_time( EXPORTING text  = text
                         CHANGING  field = <field> ).
      WHEN natures-number OR natures-float.
        write_number( EXPORTING text  = text
                      CHANGING  field = <field> ).
      WHEN natures-bytes.
        write_bytes( EXPORTING text  = text
                     CHANGING  field = <field> ).
      WHEN natures-instant.
        write_instant( EXPORTING text  = text
                       CHANGING  field = <field> ).
    ENDCASE.
  ENDMETHOD.

  METHOD holds_patterns.
    result = xsdbool( nature = natures-text OR nature = natures-fixed_text ).
  ENDMETHOD.

  METHOD write_fixed_text.
    " Blanks at the end are all a character field drops without changing the value.
    ensure_fits( text  = text
                 units = strlen( shift_right( val = text
                                              sub = blank ) ) ).

    field = text.
  ENDMETHOD.

  METHOD write_digits.
    IF text CN digits.
      RAISE EXCEPTION NEW zcx_range(
        text = |The value "{ text }" of a condition is not numeric text: a NUMC field holds digits only| ).
    ENDIF.

    " Leading zeros take no place: the assignment pads to the length of the field anyway.
    ensure_fits( text  = text
                 units = strlen( shift_left( val = text
                                             sub = zero ) ) ).

    field = text.
  ENDMETHOD.

  METHOD write_date_time.
    " A date or a time is all digits and fills its field; anything shorter
    " or formatted would be stored as a value that no row ever has.
    IF text CN digits OR strlen( text ) <> capacity.
      RAISE EXCEPTION NEW zcx_range(
        text = |The value "{ text }" of a condition is not a date or a time: { capacity } digits were expected| ).
    ENDIF.

    field = text.
  ENDMETHOD.

  METHOD write_number.
    " Decimal floating point reads every notation a number comes in as text
    " and is wide enough to tell afterwards whether the field kept the value.
    TRY.
        DATA(exact) = CONV decfloat34( text ).

        field = exact.
      CATCH cx_sy_conversion_error INTO DATA(error).
        RAISE EXCEPTION NEW zcx_range(
          text     = |The value "{ text }" of a condition is not a number, or too large for the numeric type|
          previous = error ).
    ENDTRY.

    IF nature = natures-number AND field <> exact.
      RAISE EXCEPTION NEW zcx_range(
        text = |The value "{ text }" of a condition cannot be stored in the numeric type without rounding| ).
    ENDIF.
  ENDMETHOD.

  METHOD write_bytes.
    DATA(hex) = to_upper( text ).

    IF hex CN hex_digits OR strlen( hex ) MOD digits_per_byte <> 0.
      RAISE EXCEPTION NEW zcx_range(
        text = |The value "{ text }" of a condition is not a hexadecimal text of whole bytes| ).
    ENDIF.

    ensure_fits( text  = text
                 units = strlen( hex ) DIV digits_per_byte ).

    field = hex.
  ENDMETHOD.

  METHOD write_instant.
    TRY.
        field = text.
      CATCH cx_sy_conversion_error INTO DATA(error).
        RAISE EXCEPTION NEW zcx_range(
          text     = |The value "{ text }" of a condition is not a UTC time stamp|
          previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD ensure_fits.
    IF capacity <> unlimited AND units > capacity.
      RAISE EXCEPTION NEW zcx_range(
        text = |The value "{ text }" of a condition does not fit a field of length { capacity }| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_ranges_table IMPLEMENTATION.

  METHOD read.
    DATA(layout) = layout_of( cl_abap_typedescr=>describe_by_data( range ) ).
    DATA(row_number) = 0.

    LOOP AT range ASSIGNING FIELD-SYMBOL(<row>).
      row_number += 1.

      INSERT layout->condition_of( row        = <row>
                                   row_number = row_number ) INTO TABLE result.
    ENDLOOP.
  ENDMETHOD.

  METHOD fill.
    DATA staging TYPE REF TO data.
    DATA row TYPE REF TO data.
    FIELD-SYMBOLS <range> TYPE ANY TABLE.
    FIELD-SYMBOLS <staged> TYPE ANY TABLE.

    IF target IS NOT BOUND.
      RAISE EXCEPTION NEW zcx_range( text = `The range cannot be written: the reference points to no table` ).
    ENDIF.

    DATA(layout) = layout_of( cl_abap_typedescr=>describe_by_data_ref( target ) ).

    ASSIGN target->* TO <range>.
    CREATE DATA staging LIKE <range>.
    ASSIGN staging->* TO <staged>.
    CREATE DATA row LIKE LINE OF <range>.
    ASSIGN row->* TO FIELD-SYMBOL(<row>).

    LOOP AT conditions INTO DATA(condition).
      CLEAR <row>.
      layout->write_row( EXPORTING condition = condition
                         CHANGING  row       = <row> ).

      INSERT <row> INTO TABLE <staged>.
    ENDLOOP.

    <range> = <staged>.
  ENDMETHOD.

  METHOD layout_of.
    IF table_type->kind <> cl_abap_typedescr=>kind_table.
      RAISE EXCEPTION NEW zcx_range( text = `A ranges table was expected, but the data object is not a table` ).
    ENDIF.

    DATA(row_type) = CAST cl_abap_tabledescr( table_type )->get_table_line_type( ).

    IF row_type->kind <> cl_abap_typedescr=>kind_struct.
      RAISE EXCEPTION NEW zcx_range(
        text = `The table is not a ranges table: its rows are not structures with sign, option, low and high` ).
    ENDIF.

    DATA(components) = CAST cl_abap_structdescr( row_type )->components.

    result = NEW #( ).
    result->sign_column = column_of( name       = component-sign
                                     components = components ).
    result->option_column = column_of( name       = component-option
                                       components = components ).
    result->low_column = column_of( name       = component-low
                                    components = components ).
    result->high_column = column_of( name       = component-high
                                     components = components ).
  ENDMETHOD.

  METHOD column_of.
    TRY.
        result = lcl_column=>of( components[ name = name ] ).
      CATCH cx_sy_itab_line_not_found.
        RAISE EXCEPTION NEW zcx_range(
          text = |The table is not a ranges table: its rows have no component { name }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD condition_of.
    DATA(sign) = to_upper( sign_column->read( row ) ).
    DATA(option) = to_upper( option_column->read( row ) ).

    IF sign <> zif_range=>sign-including AND sign <> zif_range=>sign-excluding.
      RAISE EXCEPTION NEW zcx_range(
        text = |Row { row_number } of the ranges table has the sign "{ sign }": only I and E exist| ).
    ENDIF.

    IF lcl_option=>is_known( option ) = abap_false.
      RAISE EXCEPTION NEW zcx_range(
        text = |Row { row_number } of the ranges table has the unknown option "{ option }"| ).
    ENDIF.

    result = VALUE #( sign   = sign
                      option = option
                      low    = low_column->read( row ) ).

    " Only an interval has an upper border; elsewhere the column is ignored
    " by every comparison and would only make equal conditions look different.
    IF lcl_option=>is_interval( option ) = abap_true.
      result-high = high_column->read( row ).
    ENDIF.
  ENDMETHOD.

  METHOD write_row.
    IF lcl_option=>is_pattern( condition-option ) = abap_true AND low_column->holds_patterns( ) = abap_false.
      RAISE EXCEPTION NEW zcx_range(
        text = |The pattern "{ condition-low }" needs a character field or a string: this type cannot be matched| ).
    ENDIF.

    sign_column->write( EXPORTING text = CONV #( condition-sign )
                        CHANGING  row  = row ).
    option_column->write( EXPORTING text = CONV #( condition-option )
                          CHANGING  row  = row ).
    low_column->write( EXPORTING text = condition-low
                       CHANGING  row  = row ).
    high_column->write( EXPORTING text = condition-high
                        CHANGING  row  = row ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_range IMPLEMENTATION.

  METHOD constructor.
    me->conditions = conditions.
  ENDMETHOD.

  METHOD zif_range~covers.
    IF conditions IS INITIAL.
      result = abap_true.
      RETURN.
    ENDIF.

    TRY.
        CASE family_of( value ).
          WHEN family-text.
            result = covers_text( CONV string( value ) ).
          WHEN family-number.
            result = covers_number( CONV decfloat34( value ) ).
          WHEN family-date.
            result = covers_date( CONV d( value ) ).
          WHEN family-time.
            result = covers_time( CONV t( value ) ).
          WHEN family-instant.
            result = covers_instant( CONV utclong( value ) ).
          WHEN family-bytes.
            result = covers_bytes( CONV xstring( value ) ).
        ENDCASE.
      CATCH cx_sy_conversion_error INTO DATA(error).
        RAISE EXCEPTION NEW zcx_range( text     = `The value to test cannot be converted for the comparison`
                                       previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_range~is_empty.
    result = xsdbool( conditions IS INITIAL ).
  ENDMETHOD.

  METHOD zif_range~conditions.
    result = conditions.
  ENDMETHOD.

  METHOD zif_range~write_to.
    lcl_ranges_table=>fill( conditions = conditions
                            target     = range ).
  ENDMETHOD.

  METHOD family_of.
    CASE cl_abap_typedescr=>describe_by_data( value )->type_kind.
      WHEN cl_abap_typedescr=>typekind_char
          OR cl_abap_typedescr=>typekind_string.
        result = family-text.
      WHEN cl_abap_typedescr=>typekind_int
          OR cl_abap_typedescr=>typekind_int1
          OR cl_abap_typedescr=>typekind_int2
          OR cl_abap_typedescr=>typekind_int8
          OR cl_abap_typedescr=>typekind_packed
          OR cl_abap_typedescr=>typekind_decfloat16
          OR cl_abap_typedescr=>typekind_decfloat34
          OR cl_abap_typedescr=>typekind_float
          OR cl_abap_typedescr=>typekind_num.
        result = family-number.
      WHEN cl_abap_typedescr=>typekind_date.
        result = family-date.
      WHEN cl_abap_typedescr=>typekind_time.
        result = family-time.
      WHEN cl_abap_typedescr=>typekind_utclong.
        result = family-instant.
      WHEN cl_abap_typedescr=>typekind_hex
          OR cl_abap_typedescr=>typekind_xstring.
        result = family-bytes.
      WHEN OTHERS.
        RAISE EXCEPTION NEW zcx_range(
          text = `A range cannot be evaluated for this value: its type is not one a ranges table can be defined for` ).
    ENDCASE.
  ENDMETHOD.

  METHOD covers_text.
    IF texts IS INITIAL.
      lcl_ranges_table=>fill( conditions = conditions
                              target     = REF #( texts ) ).
    ENDIF.

    result = xsdbool( text IN texts ).
  ENDMETHOD.

  METHOD covers_number.
    IF numbers IS INITIAL.
      lcl_ranges_table=>fill( conditions = conditions
                              target     = REF #( numbers ) ).
    ENDIF.

    result = xsdbool( number IN numbers ).
  ENDMETHOD.

  METHOD covers_date.
    IF dates IS INITIAL.
      lcl_ranges_table=>fill( conditions = conditions
                              target     = REF #( dates ) ).
    ENDIF.

    result = xsdbool( date IN dates ).
  ENDMETHOD.

  METHOD covers_time.
    IF times IS INITIAL.
      lcl_ranges_table=>fill( conditions = conditions
                              target     = REF #( times ) ).
    ENDIF.

    result = xsdbool( time IN times ).
  ENDMETHOD.

  METHOD covers_instant.
    IF instants IS INITIAL.
      lcl_ranges_table=>fill( conditions = conditions
                              target     = REF #( instants ) ).
    ENDIF.

    result = xsdbool( instant IN instants ).
  ENDMETHOD.

  METHOD covers_bytes.
    IF byte_strings IS INITIAL.
      lcl_ranges_table=>fill( conditions = conditions
                              target     = REF #( byte_strings ) ).
    ENDIF.

    result = xsdbool( bytes IN byte_strings ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_builder IMPLEMENTATION.

  METHOD zif_range_builder~equal.
    add_value( sign   = zif_range=>sign-including
               option = zif_range=>option-equal
               value  = value ).

    self = me.
  ENDMETHOD.

  METHOD zif_range_builder~not_equal.
    add_value( sign   = zif_range=>sign-excluding
               option = zif_range=>option-equal
               value  = value ).

    self = me.
  ENDMETHOD.

  METHOD zif_range_builder~between.
    add_interval( sign = zif_range=>sign-including
                  low  = low
                  high = high ).

    self = me.
  ENDMETHOD.

  METHOD zif_range_builder~not_between.
    add_interval( sign = zif_range=>sign-excluding
                  low  = low
                  high = high ).

    self = me.
  ENDMETHOD.

  METHOD zif_range_builder~pattern.
    add_value( sign   = zif_range=>sign-including
               option = zif_range=>option-pattern
               value  = mask ).

    self = me.
  ENDMETHOD.

  METHOD zif_range_builder~not_pattern.
    add_value( sign   = zif_range=>sign-excluding
               option = zif_range=>option-pattern
               value  = mask ).

    self = me.
  ENDMETHOD.

  METHOD zif_range_builder~greater_than.
    add_value( sign   = zif_range=>sign-including
               option = zif_range=>option-greater_than
               value  = value ).

    self = me.
  ENDMETHOD.

  METHOD zif_range_builder~greater_or_equal.
    add_value( sign   = zif_range=>sign-including
               option = zif_range=>option-greater_or_equal
               value  = value ).

    self = me.
  ENDMETHOD.

  METHOD zif_range_builder~less_than.
    add_value( sign   = zif_range=>sign-including
               option = zif_range=>option-less_than
               value  = value ).

    self = me.
  ENDMETHOD.

  METHOD zif_range_builder~less_or_equal.
    add_value( sign   = zif_range=>sign-including
               option = zif_range=>option-less_or_equal
               value  = value ).

    self = me.
  ENDMETHOD.

  METHOD zif_range_builder~from_list.
    add_values( sign   = zif_range=>sign-including
                values = values ).

    self = me.
  ENDMETHOD.

  METHOD zif_range_builder~not_in.
    add_values( sign   = zif_range=>sign-excluding
                values = values ).

    self = me.
  ENDMETHOD.

  METHOD zif_range_builder~from_range.
    TRY.
        LOOP AT lcl_ranges_table=>read( range ) INTO DATA(condition).
          add( condition ).
        ENDLOOP.
      CATCH zcx_range INTO DATA(error).
        remember( error ).
    ENDTRY.

    self = me.
  ENDMETHOD.

  METHOD zif_range_builder~build.
    IF mistake IS BOUND.
      RAISE EXCEPTION mistake.
    ENDIF.

    result = NEW lcl_range( conditions ).
  ENDMETHOD.

  METHOD add.
    INSERT condition INTO TABLE known.

    IF sy-subrc = 0.
      INSERT condition INTO TABLE conditions.
    ENDIF.
  ENDMETHOD.

  METHOD add_value.
    add( VALUE #( sign   = sign
                  option = option
                  low    = lcl_text=>of( value ) ) ).
  ENDMETHOD.

  METHOD add_interval.
    add( VALUE #( sign   = sign
                  option = zif_range=>option-between
                  low    = lcl_text=>of( low )
                  high   = lcl_text=>of( high ) ) ).
  ENDMETHOD.

  METHOD add_values.
    FIELD-SYMBOLS <value> TYPE simple.

    DATA(table_type) = CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( values ) ).

    IF table_type->get_table_line_type( )->kind <> cl_abap_typedescr=>kind_elem.
      remember( NEW #( text = `A list of values was expected, but the rows of the table are not elementary values` ) ).
      RETURN.
    ENDIF.

    LOOP AT values ASSIGNING <value>.
      add_value( sign   = sign
                 option = zif_range=>option-equal
                 value  = <value> ).
    ENDLOOP.
  ENDMETHOD.

  METHOD remember.
    IF mistake IS NOT BOUND.
      mistake = error.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
