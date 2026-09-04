*"* use this source file for your ABAP unit test classes
CLASS ltd_transport DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES zif_http_transport.

    METHODS answer_with
      IMPORTING response TYPE REF TO zif_http_response.

    METHODS last_request
      RETURNING VALUE(result) TYPE REF TO zif_http_request.

    METHODS sent_requests
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    DATA response TYPE REF TO zif_http_response.
    DATA request  TYPE REF TO zif_http_request.
    DATA sent     TYPE i.

ENDCLASS.


CLASS ltd_transport IMPLEMENTATION.

  METHOD zif_http_transport~send.
    me->request = request.
    sent += 1.
    result = response.
  ENDMETHOD.

  METHOD answer_with.
    me->response = response.
  ENDMETHOD.

  METHOD last_request.
    result = request.
  ENDMETHOD.

  METHOD sent_requests.
    result = sent.
  ENDMETHOD.

ENDCLASS.


CLASS ltd_failing_transport DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES zif_http_transport.

ENDCLASS.


CLASS ltd_failing_transport IMPLEMENTATION.

  METHOD zif_http_transport~send.
    RAISE EXCEPTION NEW zcx_http( text = |No route to { request->path( ) }| ).
  ENDMETHOD.

ENDCLASS.


CLASS ltd_destination DEFINITION FINAL FOR TESTING.

  PUBLIC SECTION.
    INTERFACES if_http_destination.

ENDCLASS.


CLASS ltd_destination IMPLEMENTATION.
ENDCLASS.


CLASS ltc_client DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA transport TYPE REF TO ltd_transport.
    DATA cut       TYPE REF TO zif_http_client.

    METHODS setup.

    METHODS when_get_then_method_and_path FOR TESTING RAISING cx_static_check.
    METHODS when_post_then_method_post FOR TESTING RAISING cx_static_check.
    METHODS when_put_then_method_put FOR TESTING RAISING cx_static_check.
    METHODS when_patch_then_method_patch FOR TESTING RAISING cx_static_check.
    METHODS when_delete_then_method_delete FOR TESTING RAISING cx_static_check.
    METHODS when_request_then_any_method FOR TESTING RAISING cx_static_check.
    METHODS when_no_path_then_path_empty FOR TESTING RAISING cx_static_check.
    METHODS when_sent_twice_then_two_calls FOR TESTING RAISING cx_static_check.
    METHODS when_destination_then_client FOR TESTING.

ENDCLASS.


CLASS ltc_client IMPLEMENTATION.

  METHOD setup.
    transport = NEW ltd_transport( ).
    transport->answer_with( zcl_http=>response( VALUE #( status = 200
                                                         reason = `OK` ) ) ).
    cut = zcl_http=>for_transport( transport ).
  ENDMETHOD.

  METHOD when_get_then_method_and_path.
    cut->get( `/todos/1` )->send( ).

    DATA(request) = transport->last_request( ).

    cl_abap_unit_assert=>assert_equals( act = request->http_method( )
                                        exp = if_web_http_client=>get
                                        msg = 'get( ) must send a GET request' ).
    cl_abap_unit_assert=>assert_equals( act = request->path( )
                                        exp = `/todos/1`
                                        msg = 'The path handed to get( ) must reach the transport' ).
  ENDMETHOD.

  METHOD when_post_then_method_post.
    cut->post( `/todos` )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->http_method( )
                                        exp = if_web_http_client=>post
                                        msg = 'post( ) must send a POST request' ).
  ENDMETHOD.

  METHOD when_put_then_method_put.
    cut->put( `/todos/1` )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->http_method( )
                                        exp = if_web_http_client=>put
                                        msg = 'put( ) must send a PUT request' ).
  ENDMETHOD.

  METHOD when_patch_then_method_patch.
    cut->patch( `/todos/1` )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->http_method( )
                                        exp = if_web_http_client=>patch
                                        msg = 'patch( ) must send a PATCH request' ).
  ENDMETHOD.

  METHOD when_delete_then_method_delete.
    cut->delete( `/todos/1` )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->http_method( )
                                        exp = if_web_http_client=>delete
                                        msg = 'delete( ) must send a DELETE request' ).
  ENDMETHOD.

  METHOD when_request_then_any_method.
    cut->request( http_method = if_web_http_client=>head
                  path        = `/todos` )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->http_method( )
                                        exp = if_web_http_client=>head
                                        msg = 'request( ) must send the method it was given' ).
  ENDMETHOD.

  METHOD when_no_path_then_path_empty.
    cut->get( )->send( ).

    cl_abap_unit_assert=>assert_initial( act = transport->last_request( )->path( )
                                         msg = 'Without a path the request must leave the path empty' ).
  ENDMETHOD.

  METHOD when_sent_twice_then_two_calls.
    DATA(builder) = cut->get( `/todos` ).

    builder->send( ).
    builder->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->sent_requests( )
                                        exp = 2
                                        msg = 'A builder must be reusable, every send( ) is one round trip' ).
  ENDMETHOD.

  METHOD when_destination_then_client.
    DATA(client) = zcl_http=>for_destination( NEW ltd_destination( ) ).

    cl_abap_unit_assert=>assert_bound( act = client
                                       msg = 'A destination must yield a client without touching the network' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_request_builder DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA transport TYPE REF TO ltd_transport.
    DATA cut       TYPE REF TO zif_http_request_builder.

    METHODS setup.

    METHODS when_query_then_pair_kept FOR TESTING RAISING cx_static_check.
    METHODS when_query_then_encoded FOR TESTING RAISING cx_static_check.
    METHODS when_same_name_then_repeated FOR TESTING RAISING cx_static_check.
    METHODS when_no_query_then_empty FOR TESTING RAISING cx_static_check.
    METHODS when_header_then_field_set FOR TESTING RAISING cx_static_check.
    METHODS when_header_twice_then_last FOR TESTING RAISING cx_static_check.
    METHODS when_other_header_then_kept FOR TESTING RAISING cx_static_check.
    METHODS when_bearer_then_authorization FOR TESTING RAISING cx_static_check.
    METHODS when_basic_auth_then_encoded FOR TESTING RAISING cx_static_check.
    METHODS when_json_then_body_and_type FOR TESTING RAISING cx_static_check.
    METHODS when_text_then_plain_utf8 FOR TESTING RAISING cx_static_check.
    METHODS when_text_typed_then_type_kept FOR TESTING RAISING cx_static_check.
    METHODS when_bin_then_bytes_and_type FOR TESTING RAISING cx_static_check.
    METHODS when_bin_after_text_then_bin FOR TESTING RAISING cx_static_check.
    METHODS when_text_after_bin_then_txt FOR TESTING RAISING cx_static_check.
    METHODS when_form_field_then_kept FOR TESTING RAISING cx_static_check.
    METHODS when_timeout_then_seconds FOR TESTING RAISING cx_static_check.
    METHODS when_defaults_then_no_extras FOR TESTING RAISING cx_static_check.
    METHODS when_csrf_then_token_wanted FOR TESTING RAISING cx_static_check.
    METHODS when_chained_then_same_builder FOR TESTING.
    METHODS when_send_then_answer_returned FOR TESTING RAISING cx_static_check.
    METHODS when_transp_fails_then_raise FOR TESTING.
    METHODS when_changed_after_send_old FOR TESTING RAISING cx_static_check.

    METHODS pair
      IMPORTING name          TYPE string
                value         TYPE string
      RETURNING VALUE(result) TYPE if_web_http_request=>name_value_pairs.

ENDCLASS.


CLASS ltc_request_builder IMPLEMENTATION.

  METHOD pair.
    result = VALUE #( ( name  = name
                        value = value ) ).
  ENDMETHOD.

  METHOD setup.
    transport = NEW ltd_transport( ).
    transport->answer_with( zcl_http=>response( VALUE #( status = 200
                                                         reason = `OK` ) ) ).
    cut = zcl_http=>for_transport( transport )->get( `/items` ).
  ENDMETHOD.

  METHOD when_query_then_pair_kept.
    cut->query( name  = `limit`
                value = `10` )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->query( )
                                        exp = pair( name  = `limit`
                                                    value = `10` )
                                        msg = 'A query parameter must be kept as name and value' ).
  ENDMETHOD.

  METHOD when_query_then_encoded.
    cut->query( name  = `q`
                value = `a b&c=d` )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->query_string( )
                                        exp = `q=a%20b%26c%3Dd`
                                        msg = 'Reserved characters in a value must be percent encoded' ).
  ENDMETHOD.

  METHOD when_same_name_then_repeated.
    cut->query( name  = `tag`
                value = `a` ).
    cut->query( name  = `tag`
                value = `b` ).
    cut->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->query_string( )
                                        exp = `tag=a&tag=b`
                                        msg = 'The same name may occur more than once, in call order' ).
  ENDMETHOD.

  METHOD when_no_query_then_empty.
    cut->send( ).

    cl_abap_unit_assert=>assert_initial( act = transport->last_request( )->query_string( )
                                         msg = 'Without parameters the query string must be empty' ).
  ENDMETHOD.

  METHOD when_header_then_field_set.
    cut->header( name  = `Accept`
                 value = `application/json` )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->headers( )
                                        exp = pair( name  = `Accept`
                                                    value = `application/json` )
                                        msg = 'A header field must reach the transport as set' ).
  ENDMETHOD.

  METHOD when_header_twice_then_last.
    cut->header( name  = `Accept`
                 value = `text/plain` ).
    cut->header( name  = `accept`
                 value = `application/json` ).
    cut->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->headers( )
                                        exp = pair( name  = `accept`
                                                    value = `application/json` )
                                        msg = 'A field set twice, whatever its case, must keep only the last value' ).
  ENDMETHOD.

  METHOD when_other_header_then_kept.
    cut->header( name  = `Accept`
                 value = `application/json` ).
    cut->header( name  = `X-Trace`
                 value = `42` ).
    cut->send( ).

    cl_abap_unit_assert=>assert_equals( act = lines( transport->last_request( )->headers( ) )
                                        exp = 2
                                        msg = 'Fields with different names must all be kept' ).
  ENDMETHOD.

  METHOD when_bearer_then_authorization.
    cut->bearer( `abc123` )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->headers( )
                                        exp = pair( name  = `Authorization`
                                                    value = `Bearer abc123` )
                                        msg = 'A bearer token must become an Authorization header field' ).
  ENDMETHOD.

  METHOD when_basic_auth_then_encoded.
    cut->basic_auth( user     = `user`
                     password = `pass` )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->headers( )
                                        exp = pair( name  = `Authorization`
                                                    value = `Basic dXNlcjpwYXNz` )
                                        msg = 'Basic authentication must send user:password in Base64' ).
  ENDMETHOD.

  METHOD when_json_then_body_and_type.
    cut->json( `{"id":1}` )->send( ).

    DATA(request) = transport->last_request( ).

    cl_abap_unit_assert=>assert_equals( act = request->text( )
                                        exp = `{"id":1}`
                                        msg = 'The JSON document must become the text body' ).
    cl_abap_unit_assert=>assert_equals( act = request->headers( )
                                        exp = pair( name  = `Content-Type`
                                                    value = `application/json` )
                                        msg = 'json( ) must declare the body as application/json' ).
  ENDMETHOD.

  METHOD when_text_then_plain_utf8.
    cut->text( `hello` )->send( ).

    DATA(request) = transport->last_request( ).

    cl_abap_unit_assert=>assert_equals( act = request->text( )
                                        exp = `hello`
                                        msg = 'The text must become the body' ).
    cl_abap_unit_assert=>assert_equals( act = request->headers( )
                                        exp = pair( name  = `Content-Type`
                                                    value = `text/plain; charset=utf-8` )
                                        msg = 'Without a content type the body is plain UTF-8 text' ).
  ENDMETHOD.

  METHOD when_text_typed_then_type_kept.
    cut->text( text         = `<a/>`
               content_type = `application/xml` )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->headers( )
                                        exp = pair( name  = `Content-Type`
                                                    value = `application/xml` )
                                        msg = 'A content type handed to text( ) must be used as given' ).
  ENDMETHOD.

  METHOD when_bin_then_bytes_and_type.
    cut->binary( CONV xstring( `DEADBEEF` ) )->send( ).

    DATA(request) = transport->last_request( ).

    cl_abap_unit_assert=>assert_equals( act = request->binary( )
                                        exp = CONV xstring( `DEADBEEF` )
                                        msg = 'The bytes must become the body' ).
    cl_abap_unit_assert=>assert_equals( act = request->headers( )
                                        exp = pair( name  = `Content-Type`
                                                    value = `application/octet-stream` )
                                        msg = 'Without a content type bytes are an octet stream' ).
  ENDMETHOD.

  METHOD when_bin_after_text_then_bin.
    cut->text( `hello` )->binary( CONV xstring( `00FF` ) )->send( ).

    DATA(request) = transport->last_request( ).

    cl_abap_unit_assert=>assert_initial( act = request->text( )
                                         msg = 'A binary body must replace a text body set before' ).
    cl_abap_unit_assert=>assert_equals( act = request->binary( )
                                        exp = CONV xstring( `00FF` )
                                        msg = 'The last body set must win' ).
  ENDMETHOD.

  METHOD when_text_after_bin_then_txt.
    cut->binary( CONV xstring( `00FF` ) )->json( `{}` )->send( ).

    DATA(request) = transport->last_request( ).

    cl_abap_unit_assert=>assert_initial( act = request->binary( )
                                         msg = 'A text body must replace a binary body set before' ).
    cl_abap_unit_assert=>assert_equals( act = request->text( )
                                        exp = `{}`
                                        msg = 'The last body set must win' ).
  ENDMETHOD.

  METHOD when_form_field_then_kept.
    cut->form_field( name  = `grant_type`
                     value = `client_credentials` )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->form_fields( )
                                        exp = pair( name  = `grant_type`
                                                    value = `client_credentials` )
                                        msg = 'A form field must reach the transport as name and value' ).
  ENDMETHOD.

  METHOD when_timeout_then_seconds.
    cut->timeout( 30 )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->timeout( )
                                        exp = 30
                                        msg = 'The timeout must reach the transport in seconds' ).
  ENDMETHOD.

  METHOD when_defaults_then_no_extras.
    cut->send( ).

    DATA(request) = transport->last_request( ).

    cl_abap_unit_assert=>assert_initial( act = request->headers( )
                                         msg = 'A bare request must carry no header fields' ).
    cl_abap_unit_assert=>assert_initial( act = request->timeout( )
                                         msg = 'A bare request must leave the timeout to the runtime' ).
    cl_abap_unit_assert=>assert_equals( act = request->needs_csrf_token( )
                                        exp = abap_false
                                        msg = 'A bare request must not ask for a CSRF token' ).
  ENDMETHOD.

  METHOD when_csrf_then_token_wanted.
    cut->with_csrf_token( )->send( ).

    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->needs_csrf_token( )
                                        exp = abap_true
                                        msg = 'with_csrf_token( ) must ask the transport for the handshake' ).
  ENDMETHOD.

  METHOD when_chained_then_same_builder.
    DATA(after_query) = cut->query( name  = `a`
                                    value = `1` ).
    DATA(after_rest) = cut->header( name  = `Accept`
                                    value = `*/*` )->bearer( `t` )->json( `{}` )->timeout( 5 )->with_csrf_token( ).

    cl_abap_unit_assert=>assert_equals( act = after_query
                                        exp = cut
                                        msg = 'query( ) must return the same builder' ).
    cl_abap_unit_assert=>assert_equals( act = after_rest
                                        exp = cut
                                        msg = 'Every other configuring method must return the same builder' ).
  ENDMETHOD.

  METHOD when_send_then_answer_returned.
    DATA(answer) = zcl_http=>response( VALUE #( status = 201
                                                reason = `Created` ) ).
    transport->answer_with( answer ).

    DATA(response) = cut->send( ).

    cl_abap_unit_assert=>assert_equals( act = response
                                        exp = answer
                                        msg = 'send( ) must hand back what the transport answered' ).
  ENDMETHOD.

  METHOD when_transp_fails_then_raise.
    DATA(builder) = zcl_http=>for_transport( NEW ltd_failing_transport( ) )->get( `/down` ).

    TRY.
        builder->send( ).
        cl_abap_unit_assert=>fail( 'A failing transport must surface as ZCX_HTTP' ).
      CATCH zcx_http INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->get_text( )
                                            exp = `No route to /down`
                                            msg = 'The transport message must be passed on unchanged' ).
    ENDTRY.
  ENDMETHOD.

  METHOD when_changed_after_send_old.
    cut->query( name  = `page`
                value = `1` )->send( ).
    DATA(first) = transport->last_request( ).

    cut->query( name  = `page`
                value = `2` )->send( ).

    cl_abap_unit_assert=>assert_equals( act = first->query_string( )
                                        exp = `page=1`
                                        msg = 'A sent request must not change when the builder goes on' ).
    cl_abap_unit_assert=>assert_equals( act = transport->last_request( )->query_string( )
                                        exp = `page=1&page=2`
                                        msg = 'The builder must keep collecting after a send' ).
  ENDMETHOD.

ENDCLASS.


CLASS ltc_response DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS when_built_then_status_kept FOR TESTING.
    METHODS when_200_then_success FOR TESTING.
    METHODS when_299_then_success FOR TESTING.
    METHODS when_199_then_no_success FOR TESTING.
    METHODS when_300_then_no_success FOR TESTING.
    METHODS when_404_then_no_success FOR TESTING.
    METHODS when_ok_then_ensure_ret_self FOR TESTING RAISING cx_static_check.
    METHODS when_failed_then_ensure_raises FOR TESTING.
    METHODS when_header_then_value FOR TESTING.
    METHODS when_head_other_case_then_val FOR TESTING.
    METHODS when_header_absent_then_empty FOR TESTING.
    METHODS when_headers_then_all_kept FOR TESTING.
    METHODS when_content_type_then_header FOR TESTING.
    METHODS when_body_then_text_and_bytes FOR TESTING.
    METHODS when_parts_change_then_unmoved FOR TESTING.

    METHODS response_with_status
      IMPORTING status        TYPE i
      RETURNING VALUE(result) TYPE REF TO zif_http_response.

    METHODS response_with_header
      IMPORTING name          TYPE string
                value         TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_http_response.

ENDCLASS.


CLASS ltc_response IMPLEMENTATION.

  METHOD response_with_status.
    result = zcl_http=>response( VALUE #( status = status ) ).
  ENDMETHOD.

  METHOD response_with_header.
    DATA(parts) = VALUE zif_http_response=>parts( headers = VALUE #( ( name  = name
                                                                       value = value ) ) ).

    result = zcl_http=>response( parts ).
  ENDMETHOD.

  METHOD when_built_then_status_kept.
    DATA(parts) = VALUE zif_http_response=>parts( status = 404
                                                  reason = `Not Found` ).

    DATA(cut) = zcl_http=>response( parts ).

    cl_abap_unit_assert=>assert_equals( act = cut->status( )
                                        exp = 404
                                        msg = 'The status code must be the one the response was built with' ).
    cl_abap_unit_assert=>assert_equals( act = cut->reason( )
                                        exp = `Not Found`
                                        msg = 'The reason phrase must be the one the response was built with' ).
  ENDMETHOD.

  METHOD when_200_then_success.
    cl_abap_unit_assert=>assert_equals( act = response_with_status( 200 )->is_success( )
                                        exp = abap_true
                                        msg = '200 is the first successful status' ).
  ENDMETHOD.

  METHOD when_299_then_success.
    cl_abap_unit_assert=>assert_equals( act = response_with_status( 299 )->is_success( )
                                        exp = abap_true
                                        msg = '299 is the last successful status' ).
  ENDMETHOD.

  METHOD when_199_then_no_success.
    cl_abap_unit_assert=>assert_equals( act = response_with_status( 199 )->is_success( )
                                        exp = abap_false
                                        msg = 'An informational status is not a success' ).
  ENDMETHOD.

  METHOD when_300_then_no_success.
    cl_abap_unit_assert=>assert_equals( act = response_with_status( 300 )->is_success( )
                                        exp = abap_false
                                        msg = 'A redirection status is not a success' ).
  ENDMETHOD.

  METHOD when_404_then_no_success.
    cl_abap_unit_assert=>assert_equals( act = response_with_status( 404 )->is_success( )
                                        exp = abap_false
                                        msg = 'A client error status is not a success' ).
  ENDMETHOD.

  METHOD when_ok_then_ensure_ret_self.
    DATA(cut) = response_with_status( 204 ).

    cl_abap_unit_assert=>assert_equals( act = cut->ensure_success( )
                                        exp = cut
                                        msg = 'ensure_success( ) must hand back the same response on success' ).
  ENDMETHOD.

  METHOD when_failed_then_ensure_raises.
    DATA(parts) = VALUE zif_http_response=>parts( status = 500
                                                  reason = `Internal Server Error` ).

    DATA(cut) = zcl_http=>response( parts ).

    TRY.
        cut->ensure_success( ).
        cl_abap_unit_assert=>fail( 'A status outside 2xx must raise on ensure_success( )' ).
      CATCH zcx_http INTO DATA(error).
        cl_abap_unit_assert=>assert_equals( act = error->get_text( )
                                            exp = `Request answered with HTTP status 500 Internal Server Error`
                                            msg = 'The message must name the status the server answered with' ).
    ENDTRY.
  ENDMETHOD.

  METHOD when_header_then_value.
    DATA(cut) = response_with_header( name  = `ETag`
                                      value = `v7` ).

    cl_abap_unit_assert=>assert_equals( act = cut->header( `ETag` )
                                        exp = `v7`
                                        msg = 'A header field must be found by its name' ).
  ENDMETHOD.

  METHOD when_head_other_case_then_val.
    DATA(cut) = response_with_header( name  = `content-type`
                                      value = `text/plain` ).

    cl_abap_unit_assert=>assert_equals( act = cut->header( `Content-Type` )
                                        exp = `text/plain`
                                        msg = 'Header names must match without regard to case' ).
  ENDMETHOD.

  METHOD when_header_absent_then_empty.
    DATA(cut) = response_with_header( name  = `ETag`
                                      value = `v7` ).

    cl_abap_unit_assert=>assert_initial( act = cut->header( `Location` )
                                         msg = 'A header field the server did not send must answer empty' ).
  ENDMETHOD.

  METHOD when_headers_then_all_kept.
    DATA(headers) = VALUE if_web_http_request=>name_value_pairs( ( name  = `ETag`
                                                                   value = `v7` )
                                                                 ( name  = `Location`
                                                                   value = `/items/9` ) ).

    DATA(cut) = zcl_http=>response( VALUE #( headers = headers ) ).

    cl_abap_unit_assert=>assert_equals( act = cut->headers( )
                                        exp = headers
                                        msg = 'headers( ) must hand back every field as delivered' ).
  ENDMETHOD.

  METHOD when_content_type_then_header.
    DATA(cut) = response_with_header( name  = `Content-Type`
                                      value = `application/json; charset=utf-8` ).

    cl_abap_unit_assert=>assert_equals( act = cut->content_type( )
                                        exp = `application/json; charset=utf-8`
                                        msg = 'content_type( ) must read the Content-Type header field' ).
  ENDMETHOD.

  METHOD when_body_then_text_and_bytes.
    DATA(cut) = zcl_http=>response( VALUE #( text   = `hi`
                                             binary = CONV xstring( `6869` ) ) ).

    cl_abap_unit_assert=>assert_equals( act = cut->text( )
                                        exp = `hi`
                                        msg = 'text( ) must hand back the body text' ).
    cl_abap_unit_assert=>assert_equals( act = cut->binary( )
                                        exp = CONV xstring( `6869` )
                                        msg = 'binary( ) must hand back the body bytes' ).
  ENDMETHOD.

  METHOD when_parts_change_then_unmoved.
    DATA(parts) = VALUE zif_http_response=>parts( status = 200
                                                  text   = `before` ).
    DATA(cut) = zcl_http=>response( parts ).

    parts-status = 500.
    parts-text = `after`.

    cl_abap_unit_assert=>assert_equals( act = cut->status( )
                                        exp = 200
                                        msg = 'A response must not follow later changes of its parts' ).
    cl_abap_unit_assert=>assert_equals( act = cut->text( )
                                        exp = `before`
                                        msg = 'A response must keep its own copy of the body' ).
  ENDMETHOD.

ENDCLASS.
