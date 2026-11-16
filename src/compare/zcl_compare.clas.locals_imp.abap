*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
"! The name of a component the way RTTI spells it - upper case, no blanks
"! around it - and the path that leads to a component of a nested structure.
"! A consumer types a name in any case; the names of the ignore list, of the
"! changes and of a control structure meet here in one spelling.
CLASS lcl_path DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS of
      IMPORTING name          TYPE csequence
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS below
      IMPORTING parent        TYPE string
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS is_within
      IMPORTING path          TYPE string
                name          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    CLASS-METHODS segments
      IMPORTING path          TYPE string
      RETURNING VALUE(result) TYPE string_table.

  PRIVATE SECTION.
    CONSTANTS separator TYPE string VALUE `-`.
    CONSTANTS at_the_start TYPE i VALUE 0.

ENDCLASS.


"! The text a change shows for a value. A string template writes an
"! elementary value the way source code does - a leading minus sign, a
"! decimal point, no blanks at the end - whereas a plain assignment to a
"! string puts the sign of a negative number at its end. A table and a
"! reference have no such text and are described instead, so that a change
"! of them still reads as one line.
CLASS lcl_text DEFINITION FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS of
      IMPORTING value         TYPE any
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    CONSTANTS one_row TYPE string VALUE `[1 row]`.
    CONSTANTS bound_reference TYPE string VALUE `[bound]`.
    CONSTANTS initial_reference TYPE string VALUE `[initial]`.
    CONSTANTS exactly_one TYPE i VALUE 1.

    CLASS-METHODS of_table
      IMPORTING rows          TYPE ANY TABLE
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


"! The changed components of one comparison and the one question both a
"! consumer and a control structure ask of them: did this component, or
"! anything below it, change?
CLASS lcl_changes DEFINITION FINAL.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING changes TYPE zif_compare_difference=>ty_changes.

    METHODS entries
      RETURNING VALUE(result) TYPE zif_compare_difference=>ty_changes.

    METHODS is_empty
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS has_change_in
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    DATA changes TYPE zif_compare_difference=>ty_changes.

ENDCLASS.


"! A structure of flags, one per component, as RAP and BAPIs use it to say
"! which fields of a row are meant. Tells a flag from everything else by its
"! type - one byte for %control, one character for an X structure - and
"! switches every flag on or off, so that a structure which was used before
"! does not keep a flag of the previous row.
CLASS lcl_control DEFINITION FINAL.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING changes TYPE REF TO lcl_changes.

    METHODS write_to
      IMPORTING target TYPE REF TO data
      RAISING   zcx_compare.

  PRIVATE SECTION.
    CONSTANTS one_byte TYPE i VALUE 1.

    DATA changes TYPE REF TO lcl_changes.
    DATA flags_written TYPE i.

    METHODS mark
      IMPORTING prefix    TYPE string OPTIONAL
      CHANGING  structure TYPE any.

    METHODS is_structure
      IMPORTING component     TYPE abap_compdescr
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS is_byte_flag
      IMPORTING component     TYPE abap_compdescr
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS is_character_flag
      IMPORTING component     TYPE abap_compdescr
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


"! Immutable difference. Besides the changes it keeps the type of the
"! compared structure: a component that did not change and a component that
"! does not exist both have no change, and only the type tells a correct
"! question from a typing error.
CLASS lcl_difference DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_compare_difference.

    METHODS constructor
      IMPORTING layout  TYPE REF TO cl_abap_structdescr
                changes TYPE REF TO lcl_changes.

  PRIVATE SECTION.
    DATA layout TYPE REF TO cl_abap_structdescr.
    DATA changes TYPE REF TO lcl_changes.

    METHODS has_component
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


"! Immutable comparison with its ignore list. Walks the first structure by
"! the names RTTI gives its components and reads the second one in the type
"! of the first, so that two compatible structures with different component
"! names are compared field by field as well. Unchanged components cost one
"! comparison each; type information is read for the changed ones only.
CLASS lcl_comparison DEFINITION FINAL.

  PUBLIC SECTION.
    TYPES ty_names TYPE SORTED TABLE OF string WITH UNIQUE KEY table_line.

    INTERFACES zif_compare.

    METHODS constructor
      IMPORTING ignored TYPE ty_names.

  PRIVATE SECTION.
    DATA ignored TYPE ty_names.

    METHODS layout_of
      IMPORTING value         TYPE any
      RETURNING VALUE(result) TYPE REF TO cl_abap_structdescr
      RAISING   zcx_compare.

    METHODS category_of
      IMPORTING descriptor    TYPE REF TO cl_abap_typedescr
      RETURNING VALUE(result) TYPE string.

    METHODS changes_within
      IMPORTING prefix        TYPE string OPTIONAL
                before        TYPE any
                after         TYPE any
      RETURNING VALUE(result) TYPE zif_compare_difference=>ty_changes.

    METHODS changes_of
      IMPORTING path          TYPE string
                before        TYPE any
                after         TYPE any
      RETURNING VALUE(result) TYPE zif_compare_difference=>ty_changes.

ENDCLASS.


"! Collects the ignore list, each name once and in the spelling of RTTI.
"! The chain cannot raise, so the first call that could not be used is
"! remembered here and raised when the comparison is built.
CLASS lcl_builder DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_compare_builder.

  PRIVATE SECTION.
    DATA ignored TYPE lcl_comparison=>ty_names.
    DATA mistake TYPE REF TO zcx_compare.

ENDCLASS.


CLASS lcl_path IMPLEMENTATION.

  METHOD of.
    result = to_upper( condense( name ) ).
  ENDMETHOD.

  METHOD below.
    result = parent && separator.
  ENDMETHOD.

  METHOD is_within.
    DATA(position) = find( val = path
                           sub = below( name ) ).

    result = xsdbool( path = name OR position = at_the_start ).
  ENDMETHOD.

  METHOD segments.
    SPLIT path AT separator INTO TABLE result.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_text IMPLEMENTATION.

  METHOD of.
    FIELD-SYMBOLS <elementary> TYPE simple.
    FIELD-SYMBOLS <rows> TYPE ANY TABLE.

    CASE cl_abap_typedescr=>describe_by_data( value )->kind.
      WHEN cl_abap_typedescr=>kind_table.
        ASSIGN value TO <rows>.
        result = of_table( <rows> ).
      WHEN cl_abap_typedescr=>kind_ref.
        result = COND #( WHEN value IS INITIAL THEN initial_reference ELSE bound_reference ).
      WHEN OTHERS.
        ASSIGN value TO <elementary>.
        result = |{ <elementary> }|.
    ENDCASE.
  ENDMETHOD.

  METHOD of_table.
    DATA(number_of_rows) = lines( rows ).

    result = COND #( WHEN number_of_rows = exactly_one THEN one_row ELSE |[{ number_of_rows } rows]| ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_changes IMPLEMENTATION.

  METHOD constructor.
    me->changes = changes.
  ENDMETHOD.

  METHOD entries.
    result = changes.
  ENDMETHOD.

  METHOD is_empty.
    result = xsdbool( changes IS INITIAL ).
  ENDMETHOD.

  METHOD has_change_in.
    LOOP AT changes INTO DATA(change).
      IF lcl_path=>is_within( path = change-component
                              name = name ).
        result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_control IMPLEMENTATION.

  METHOD constructor.
    me->changes = changes.
  ENDMETHOD.

  METHOD write_to.
    IF target IS NOT BOUND.
      RAISE EXCEPTION NEW zcx_compare(
        text = `The changed components cannot be marked: the reference points to no control structure` ).
    ENDIF.

    IF cl_abap_typedescr=>describe_by_data_ref( target )->kind <> cl_abap_typedescr=>kind_struct.
      RAISE EXCEPTION NEW zcx_compare(
        text = `A control structure was expected, but the reference does not point to a structure` ).
    ENDIF.

    ASSIGN target->* TO FIELD-SYMBOL(<control>).

    mark( CHANGING structure = <control> ).

    IF flags_written IS INITIAL.
      RAISE EXCEPTION NEW zcx_compare(
        text = `The structure is not a control structure: it holds no flag of one byte or of one character` ).
    ENDIF.
  ENDMETHOD.

  METHOD mark.
    DATA(layout) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( structure ) ).

    LOOP AT layout->components INTO DATA(component).
      DATA(path) = prefix && component-name.

      ASSIGN COMPONENT component-name OF STRUCTURE structure TO FIELD-SYMBOL(<field>).
      ASSERT sy-subrc = 0.

      IF is_structure( component ).
        mark( EXPORTING prefix    = lcl_path=>below( path )
              CHANGING  structure = <field> ).
      ELSEIF is_byte_flag( component ).
        <field> = COND if_abap_behv=>t_xflag( WHEN changes->has_change_in( path )
                                              THEN if_abap_behv=>mk-on
                                              ELSE if_abap_behv=>mk-off ).
        flags_written += 1.
      ELSEIF is_character_flag( component ).
        <field> = changes->has_change_in( path ).
        flags_written += 1.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD is_structure.
    result = xsdbool( component-type_kind = cl_abap_typedescr=>typekind_struct1
                   OR component-type_kind = cl_abap_typedescr=>typekind_struct2 ).
  ENDMETHOD.

  METHOD is_byte_flag.
    result = xsdbool( component-type_kind = cl_abap_typedescr=>typekind_hex
                  AND component-length = one_byte ).
  ENDMETHOD.

  METHOD is_character_flag.
    result = xsdbool( component-type_kind = cl_abap_typedescr=>typekind_char
                  AND component-length = cl_abap_char_utilities=>charsize ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_difference IMPLEMENTATION.

  METHOD constructor.
    me->layout = layout.
    me->changes = changes.
  ENDMETHOD.

  METHOD zif_compare_difference~has_changes.
    result = xsdbool( changes->is_empty( ) = abap_false ).
  ENDMETHOD.

  METHOD zif_compare_difference~has_changed.
    DATA(name) = lcl_path=>of( component ).

    result = changes->has_change_in( name ).

    IF result = abap_false AND has_component( name ) = abap_false.
      RAISE EXCEPTION NEW zcx_compare( text = |The compared structure has no component { name }| ).
    ENDIF.
  ENDMETHOD.

  METHOD zif_compare_difference~changes.
    result = changes->entries( ).
  ENDMETHOD.

  METHOD zif_compare_difference~write_control.
    NEW lcl_control( changes )->write_to( control ).
  ENDMETHOD.

  METHOD has_component.
    DATA(segments) = lcl_path=>segments( name ).
    DATA(level) = CAST cl_abap_datadescr( layout ).

    LOOP AT segments INTO DATA(segment).
      IF level->kind <> cl_abap_typedescr=>kind_struct.
        RETURN.
      ENDIF.

      DATA(parent) = CAST cl_abap_structdescr( level ).

      IF NOT line_exists( parent->components[ name = segment ] ).
        RETURN.
      ENDIF.

      level = parent->get_component_type( segment ).
    ENDLOOP.

    result = xsdbool( segments IS NOT INITIAL ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_comparison IMPLEMENTATION.

  METHOD constructor.
    me->ignored = ignored.
  ENDMETHOD.

  METHOD zif_compare~difference.
    DATA counterpart TYPE REF TO data.

    DATA(layout) = layout_of( before ).

    IF layout->applies_to_data( after ) = abap_false.
      RAISE EXCEPTION NEW zcx_compare(
        text = `The two data objects cannot be compared: the second one is not of the type of the first` ).
    ENDIF.

    CREATE DATA counterpart LIKE before.
    ASSIGN counterpart->* TO FIELD-SYMBOL(<after>).
    <after> = after.

    DATA(changes) = COND zif_compare_difference=>ty_changes( WHEN before <> <after>
                                                             THEN changes_within( before = before
                                                                                  after  = <after> ) ).

    result = NEW lcl_difference( layout  = layout
                                 changes = NEW #( changes ) ).
  ENDMETHOD.

  METHOD layout_of.
    DATA(descriptor) = cl_abap_typedescr=>describe_by_data( value ).

    IF descriptor->kind <> cl_abap_typedescr=>kind_struct.
      DATA(category) = category_of( descriptor ).

      RAISE EXCEPTION NEW zcx_compare(
        text = |Only structures are compared by component, but the first data object is { category }| ).
    ENDIF.

    result = CAST #( descriptor ).
  ENDMETHOD.

  METHOD category_of.
    result = SWITCH #( descriptor->kind
                       WHEN cl_abap_typedescr=>kind_table THEN `an internal table`
                       WHEN cl_abap_typedescr=>kind_ref   THEN `a reference`
                       ELSE `an elementary value` ).
  ENDMETHOD.

  METHOD changes_within.
    DATA(layout) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( before ) ).

    LOOP AT layout->components INTO DATA(component).
      DATA(path) = prefix && component-name.

      IF line_exists( ignored[ table_line = path ] ).
        CONTINUE.
      ENDIF.

      ASSIGN COMPONENT component-name OF STRUCTURE before TO FIELD-SYMBOL(<before>).
      ASSERT sy-subrc = 0.
      ASSIGN COMPONENT component-name OF STRUCTURE after TO FIELD-SYMBOL(<after>).
      ASSERT sy-subrc = 0.

      IF <before> <> <after>.
        DATA(found) = changes_of( path   = path
                                  before = <before>
                                  after  = <after> ).
        INSERT LINES OF found INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD changes_of.
    IF cl_abap_typedescr=>describe_by_data( before )->kind = cl_abap_typedescr=>kind_struct.
      result = changes_within( prefix = lcl_path=>below( path )
                               before = before
                               after  = after ).
    ELSE.
      result = VALUE #( ( component = path
                          before    = lcl_text=>of( before )
                          after     = lcl_text=>of( after ) ) ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_builder IMPLEMENTATION.

  METHOD zif_compare_builder~ignoring.
    DATA(name) = lcl_path=>of( component ).

    IF name IS NOT INITIAL.
      INSERT name INTO TABLE ignored.
    ELSEIF mistake IS NOT BOUND.
      mistake = NEW #( text = `A component to ignore was handed in without a name` ).
    ENDIF.

    self = me.
  ENDMETHOD.

  METHOD zif_compare_builder~ignoring_list.
    LOOP AT components INTO DATA(component).
      zif_compare_builder~ignoring( component ).
    ENDLOOP.

    self = me.
  ENDMETHOD.

  METHOD zif_compare_builder~build.
    IF mistake IS BOUND.
      RAISE EXCEPTION mistake.
    ENDIF.

    result = NEW lcl_comparison( ignored ).
  ENDMETHOD.

ENDCLASS.
