"! <p class="shorttext synchronized" lang="EN">Regular expression utility demo</p>
"! Runnable showcase for {@link zcl_regex}. Start it with F9 in ADT.
CLASS zcl_regex_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS order_line TYPE string VALUE `Shipped: DE-4711 (12 pcs), GR-0815 (3 pcs); pending: FR-9000`.
    CONSTANTS order_reference TYPE string VALUE `([A-Z]{2})-([0-9]{4})`.

    METHODS show_validation
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_regex.

    METHODS show_extraction
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_regex.

    METHODS show_replacing
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_regex.

    METHODS show_splitting
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_regex.

    METHODS show_literal
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_regex.

    METHODS show_rejected_pattern
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS as_yes_no
      IMPORTING flag          TYPE abap_bool
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_regex_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_validation( out ).
        show_extraction( out ).
        show_replacing( out ).
        show_splitting( out ).
        show_literal( out ).
        show_rejected_pattern( out ).
      CATCH zcx_regex INTO DATA(error).
        out->write( |Regex demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_validation.
    DATA(email) = zcl_regex=>of( zif_regex_patterns=>email ).
    DATA(date) = zcl_regex=>of( zif_regex_patterns=>iso_date ).

    out->write( `--- Validation with named patterns ---` ).
    out->write( |john.doe@example.com : { as_yes_no( email->is_match( `john.doe@example.com` ) ) }| ).
    out->write( |john.doe@example     : { as_yes_no( email->is_match( `john.doe@example` ) ) }| ).
    out->write( |2026-09-07           : { as_yes_no( date->is_match( `2026-09-07` ) ) }| ).
    out->write( |07.09.2026           : { as_yes_no( date->is_match( `07.09.2026` ) ) }| ).
  ENDMETHOD.

  METHOD show_extraction.
    DATA(reference) = zcl_regex=>of( order_reference ).

    out->write( `--- Extraction ---` ).
    out->write( |Text       : { order_line }| ).
    out->write( |Occurs     : { as_yes_no( reference->occurs_in( order_line ) ) }| ).
    out->write( |Count      : { reference->match_count( order_line ) }| ).
    out->write( |Extract all: { concat_lines_of( table = reference->extract_all( order_line )
                                                 sep   = `, ` ) }| ).

    LOOP AT reference->all_matches( order_line ) INTO DATA(match).
      out->write( |  { match->value( ) } at offset { match->offset( ) }: | &&
                  |country { match->group( 1 ) }, number { match->group( 2 ) }| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD show_replacing.
    DATA(digits) = zcl_regex=>of( `[0-9]` ).
    DATA(reference) = zcl_regex=>of( order_reference ).

    DATA(masked) = digits->replace_all( text        = `Card 4111 1111 1111 1111`
                                        replacement = `*` ).
    DATA(reordered) = reference->replace_all( text        = order_line
                                              replacement = `$2/$1` ).
    DATA(first_only) = reference->replace_first( text        = order_line
                                                 replacement = `[redacted]` ).

    out->write( `--- Replacing ---` ).
    out->write( |Masked     : { masked }| ).
    out->write( |Reordered  : { reordered }| ).
    out->write( |First only : { first_only }| ).
  ENDMETHOD.

  METHOD show_splitting.
    DATA(separator) = zcl_regex=>of( `\s*[;,]\s*` ).

    out->write( `--- Splitting ---` ).
    LOOP AT separator->split( `alpha , beta;gamma,  delta` ) INTO DATA(part).
      out->write( |  [{ part }]| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD show_literal.
    DATA(file_name) = `report(2026).pdf`.
    DATA(exact) = zcl_regex=>of( |^{ zcl_regex=>literal( file_name ) }$| ).

    out->write( `--- Literal text inside a pattern ---` ).
    out->write( |Pattern    : { exact->pattern( ) }| ).
    out->write( |Same name  : { as_yes_no( exact->is_match( file_name ) ) }| ).
    out->write( |Other name : { as_yes_no( exact->is_match( `reportX2026Y.pdf` ) ) }| ).
  ENDMETHOD.

  METHOD show_rejected_pattern.
    out->write( `--- Rejected pattern ---` ).

    TRY.
        zcl_regex=>of( `(unclosed` ).

        out->write( `A broken pattern was unexpectedly accepted` ).
      CATCH zcx_regex INTO DATA(rejection).
        out->write( |Rejected as expected: { rejection->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD as_yes_no.
    result = COND string( WHEN flag = abap_true THEN `yes`
                          ELSE `no` ).
  ENDMETHOD.

ENDCLASS.
