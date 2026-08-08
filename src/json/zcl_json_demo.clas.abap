"! <p class="shorttext synchronized" lang="EN">JSON utility demo</p>
"! Round-trip smoke test for {@link zcl_json}: serializes sample data in every
"! name style and reads a camelCase document back. Run with F9 in ADT.
CLASS zcl_json_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    TYPES: BEGIN OF contact,
             first_name TYPE string,
             last_name  TYPE string,
             is_active  TYPE abap_bool,
           END OF contact.
    TYPES contacts TYPE STANDARD TABLE OF contact WITH EMPTY KEY.

    TYPES: BEGIN OF team,
             team_name TYPE string,
             members   TYPE contacts,
           END OF team.

    METHODS sample_team
      RETURNING VALUE(result) TYPE team.

    METHODS show_serialization
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_json.

    METHODS show_deserialization
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_json.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

ENDCLASS.


CLASS zcl_json_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_serialization( out ).
        show_deserialization( out ).
        show_rejected_input( out ).
      CATCH zcx_json INTO DATA(error).
        out->write( |JSON demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD sample_team.
    result = VALUE #( team_name = `Clean Core`
                      members   = VALUE #( ( first_name = `Ada` last_name = `Lovelace` is_active = abap_true )
                                           ( first_name = `Grace` last_name = `Hopper` is_active = abap_false ) ) ).
  ENDMETHOD.

  METHOD show_serialization.
    DATA(team) = sample_team( ).

    out->write( `Default member names:` ).
    out->write( zcl_json=>for_data( team )->to_string( ) ).

    out->write( `camelCase member names:` ).
    out->write( zcl_json=>for_data( team )->as_camel_case( )->to_string( ) ).

    out->write( `PascalCase member names:` ).
    out->write( zcl_json=>for_data( team )->as_pascal_case( )->to_string( ) ).
  ENDMETHOD.

  METHOD show_deserialization.
    DATA inbound_team TYPE team.

    DATA(json) = `{ "teamName": "Inbound",` &&
                 ` "members": [ { "firstName": "Alan", "lastName": "Turing", "isActive": true } ] }`.

    zcl_json=>for_string( json
      )->from_camel_case(
      )->booleans_to_abap_bool(
      )->read_into( IMPORTING data = inbound_team ).

    out->write( |Team { inbound_team-team_name } with { lines( inbound_team-members ) } member(s):| ).
    out->write( inbound_team-members ).
  ENDMETHOD.

  METHOD show_rejected_input.
    TYPES: BEGIN OF dynamic_payload,
             id      TYPE string,
             content TYPE REF TO data,
           END OF dynamic_payload.

    DATA payload TYPE dynamic_payload.

    TRY.
        zcl_json=>for_data( payload ).

        out->write( `A reference component was unexpectedly accepted` ).
      CATCH zcx_json INTO DATA(error).
        out->write( |Rejected as expected: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
