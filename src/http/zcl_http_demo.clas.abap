"! <p class="shorttext synchronized" lang="EN">HTTP client utility demo</p>
"! Runnable walk through ZCL_HTTP. Press F9 in ADT to see the output. Nothing
"! here touches the network: every request goes to a local transport double,
"! the way a consumer test would send it. To go online, hand
"! zcl_http=&gt;for_destination an if_http_destination of your platform.
CLASS zcl_http_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS round_trip_limit TYPE i VALUE 10.

    METHODS show_offline_request
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_http.

    METHODS show_offline_failure
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_http.

    METHODS show_response
      IMPORTING out      TYPE REF TO if_oo_adt_classrun_out
                response TYPE REF TO zif_http_response.

ENDCLASS.


CLASS zcl_http_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_offline_request( out ).
        show_offline_failure( out ).
      CATCH zcx_http INTO DATA(error).
        out->write( |Unexpected failure: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_offline_request.
    out->write( `=== Offline - the request as the transport sees it ===` ).

    DATA(client) = zcl_http=>for_transport( NEW lcl_echo_transport( ) ).

    DATA(response) = client->post( `/orders`
                           )->query( name  = `dry-run`
                                     value = `yes`
                           )->header( name  = `Accept`
                                      value = `application/json`
                           )->bearer( `demo-token`
                           )->json( `{"item":"BOX","quantity":12}`
                           )->timeout( round_trip_limit
                           )->send( ).

    show_response( out      = out
                   response = response ).
  ENDMETHOD.

  METHOD show_offline_failure.
    out->write( `=== Offline - insisting on success ===` ).

    DATA(client) = zcl_http=>for_transport( NEW lcl_echo_transport( status = 404
                                                                    reason = `Not Found` ) ).

    DATA(response) = client->get( `/orders/4711` )->send( ).

    DATA(verdict) = COND string( WHEN response->is_success( ) = abap_true THEN `true`
                                 ELSE `false` ).
    out->write( |is_success( ) answers { verdict } for status { response->status( ) }| ).

    TRY.
        response->ensure_success( ).
      CATCH zcx_http INTO DATA(error).
        out->write( |ensure_success( ) raised: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_response.
    out->write( |Status: { response->status( ) } { response->reason( ) }| ).
    out->write( |Content-Type: { response->content_type( ) }| ).
    out->write( response->text( ) ).
  ENDMETHOD.

ENDCLASS.

