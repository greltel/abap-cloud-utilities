*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

" Everything a request consists of. Collected by lcl_request_builder and
" frozen into an lcl_request the moment the request is sent.
TYPES:
  BEGIN OF request_parts,
    http_method TYPE if_web_http_client=>method,
    path        TYPE string,
    query       TYPE if_web_http_request=>name_value_pairs,
    headers     TYPE if_web_http_request=>name_value_pairs,
    form_fields TYPE if_web_http_request=>name_value_pairs,
    text        TYPE string,
    binary      TYPE xstring,
    timeout     TYPE i,
    csrf_token  TYPE abap_bool,
  END OF request_parts.


CLASS lcl_request DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_http_request.

    METHODS constructor
      IMPORTING parts TYPE request_parts.

  PRIVATE SECTION.
    DATA parts TYPE request_parts.

    METHODS encoded
      IMPORTING value         TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS lcl_request IMPLEMENTATION.

  METHOD constructor.
    me->parts = parts.
  ENDMETHOD.

  METHOD zif_http_request~http_method.
    result = parts-http_method.
  ENDMETHOD.

  METHOD zif_http_request~path.
    result = parts-path.
  ENDMETHOD.

  METHOD zif_http_request~query.
    result = parts-query.
  ENDMETHOD.

  METHOD zif_http_request~query_string.
    DATA(parameters) = VALUE string_table( FOR entry IN parts-query
                                           ( |{ encoded( entry-name ) }={ encoded( entry-value ) }| ) ).

    result = concat_lines_of( table = parameters
                              sep   = `&` ).
  ENDMETHOD.

  METHOD zif_http_request~headers.
    result = parts-headers.
  ENDMETHOD.

  METHOD zif_http_request~form_fields.
    result = parts-form_fields.
  ENDMETHOD.

  METHOD zif_http_request~text.
    result = parts-text.
  ENDMETHOD.

  METHOD zif_http_request~binary.
    result = parts-binary.
  ENDMETHOD.

  METHOD zif_http_request~timeout.
    result = parts-timeout.
  ENDMETHOD.

  METHOD zif_http_request~needs_csrf_token.
    result = parts-csrf_token.
  ENDMETHOD.

  METHOD encoded.
    result = escape( val    = value
                     format = cl_abap_format=>e_url_full ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_response DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_http_response.

    METHODS constructor
      IMPORTING parts TYPE zif_http_response=>parts.

  PRIVATE SECTION.
    CONSTANTS lowest_success_status  TYPE i VALUE 200.
    CONSTANTS lowest_redirect_status TYPE i VALUE 300.
    CONSTANTS content_type_field     TYPE string VALUE `Content-Type`.

    DATA parts TYPE zif_http_response=>parts.

ENDCLASS.


CLASS lcl_response IMPLEMENTATION.

  METHOD constructor.
    me->parts = parts.
  ENDMETHOD.

  METHOD zif_http_response~status.
    result = parts-status.
  ENDMETHOD.

  METHOD zif_http_response~reason.
    result = parts-reason.
  ENDMETHOD.

  METHOD zif_http_response~is_success.
    result = xsdbool( parts-status >= lowest_success_status AND parts-status < lowest_redirect_status ).
  ENDMETHOD.

  METHOD zif_http_response~ensure_success.
    IF zif_http_response~is_success( ) = abap_false.
      RAISE EXCEPTION NEW zcx_http( text = |Request answered with HTTP status { parts-status } { parts-reason }| ).
    ENDIF.

    self = me.
  ENDMETHOD.

  METHOD zif_http_response~header.
    DATA(wanted) = to_lower( name ).

    LOOP AT parts-headers INTO DATA(header).
      IF to_lower( header-name ) = wanted.
        result = header-value.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_http_response~headers.
    result = parts-headers.
  ENDMETHOD.

  METHOD zif_http_response~content_type.
    result = zif_http_response~header( content_type_field ).
  ENDMETHOD.

  METHOD zif_http_response~text.
    result = parts-text.
  ENDMETHOD.

  METHOD zif_http_response~binary.
    result = parts-binary.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_request_builder DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_http_request_builder.

    METHODS constructor
      IMPORTING transport   TYPE REF TO zif_http_transport
                http_method TYPE if_web_http_client=>method
                path        TYPE string.

  PRIVATE SECTION.
    CONSTANTS authorization_field TYPE string VALUE `Authorization`.
    CONSTANTS content_type_field  TYPE string VALUE `Content-Type`.

    DATA transport TYPE REF TO zif_http_transport.
    DATA parts     TYPE request_parts.

    METHODS set_header
      IMPORTING name  TYPE string
                value TYPE string.

    METHODS set_text_body
      IMPORTING text         TYPE string
                content_type TYPE string.

ENDCLASS.


CLASS lcl_request_builder IMPLEMENTATION.

  METHOD constructor.
    me->transport = transport.
    parts-http_method = http_method.
    parts-path = path.
  ENDMETHOD.

  METHOD zif_http_request_builder~query.
    INSERT VALUE #( name  = name
                    value = value ) INTO TABLE parts-query.
    self = me.
  ENDMETHOD.

  METHOD zif_http_request_builder~header.
    set_header( name  = name
                value = value ).
    self = me.
  ENDMETHOD.

  METHOD zif_http_request_builder~bearer.
    set_header( name  = authorization_field
                value = |Bearer { token }| ).
    self = me.
  ENDMETHOD.

  METHOD zif_http_request_builder~basic_auth.
    DATA(credentials) = |{ user }:{ password }|.

    set_header( name  = authorization_field
                value = |Basic { cl_web_http_utility=>encode_base64( credentials ) }| ).
    self = me.
  ENDMETHOD.

  METHOD zif_http_request_builder~json.
    set_text_body( text         = json
                   content_type = zif_http_request_builder=>media_type-json ).
    self = me.
  ENDMETHOD.

  METHOD zif_http_request_builder~text.
    set_text_body( text         = text
                   content_type = content_type ).
    self = me.
  ENDMETHOD.

  METHOD zif_http_request_builder~binary.
    CLEAR parts-text.
    parts-binary = bytes.
    set_header( name  = content_type_field
                value = content_type ).
    self = me.
  ENDMETHOD.

  METHOD zif_http_request_builder~form_field.
    INSERT VALUE #( name  = name
                    value = value ) INTO TABLE parts-form_fields.
    self = me.
  ENDMETHOD.

  METHOD zif_http_request_builder~timeout.
    parts-timeout = seconds.
    self = me.
  ENDMETHOD.

  METHOD zif_http_request_builder~with_csrf_token.
    parts-csrf_token = abap_true.
    self = me.
  ENDMETHOD.

  METHOD zif_http_request_builder~send.
    result = transport->send( NEW lcl_request( parts ) ).
  ENDMETHOD.

  METHOD set_header.
    DATA(key) = to_lower( name ).

    LOOP AT parts-headers INTO DATA(header).
      IF to_lower( header-name ) = key.
        DELETE parts-headers INDEX sy-tabix.
      ENDIF.
    ENDLOOP.

    INSERT VALUE #( name  = name
                    value = value ) INTO TABLE parts-headers.
  ENDMETHOD.

  METHOD set_text_body.
    CLEAR parts-binary.
    parts-text = text.
    set_header( name  = content_type_field
                value = content_type ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_client DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_http_client.

    METHODS constructor
      IMPORTING transport TYPE REF TO zif_http_transport.

  PRIVATE SECTION.
    DATA transport TYPE REF TO zif_http_transport.

ENDCLASS.


CLASS lcl_client IMPLEMENTATION.

  METHOD constructor.
    me->transport = transport.
  ENDMETHOD.

  METHOD zif_http_client~get.
    result = zif_http_client~request( http_method = if_web_http_client=>get
                                      path        = path ).
  ENDMETHOD.

  METHOD zif_http_client~post.
    result = zif_http_client~request( http_method = if_web_http_client=>post
                                      path        = path ).
  ENDMETHOD.

  METHOD zif_http_client~put.
    result = zif_http_client~request( http_method = if_web_http_client=>put
                                      path        = path ).
  ENDMETHOD.

  METHOD zif_http_client~patch.
    result = zif_http_client~request( http_method = if_web_http_client=>patch
                                      path        = path ).
  ENDMETHOD.

  METHOD zif_http_client~delete.
    result = zif_http_client~request( http_method = if_web_http_client=>delete
                                      path        = path ).
  ENDMETHOD.

  METHOD zif_http_client~request.
    result = NEW lcl_request_builder( transport   = transport
                                      http_method = http_method
                                      path        = path ).
  ENDMETHOD.

ENDCLASS.


" The only place that touches the network. Opens a fresh web client for every
" request, so no header or body of one request leaks into the next one.
CLASS lcl_web_transport DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_http_transport.

    METHODS constructor
      IMPORTING destination TYPE REF TO if_http_destination.

  PRIVATE SECTION.
    DATA destination TYPE REF TO if_http_destination.

    METHODS open
      RETURNING VALUE(result) TYPE REF TO if_web_http_client
      RAISING   zcx_http.

    METHODS fill
      IMPORTING request     TYPE REF TO zif_http_request
                web_request TYPE REF TO if_web_http_request
      RAISING   cx_web_message_error.

    METHODS fill_body
      IMPORTING request     TYPE REF TO zif_http_request
                web_request TYPE REF TO if_web_http_request
      RAISING   cx_web_message_error.

    METHODS answer
      IMPORTING web_response  TYPE REF TO if_web_http_response
      RETURNING VALUE(result) TYPE REF TO zif_http_response
      RAISING   cx_web_message_error.

    METHODS close_quietly
      IMPORTING client TYPE REF TO if_web_http_client.

    METHODS describe
      IMPORTING request       TYPE REF TO zif_http_request
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS lcl_web_transport IMPLEMENTATION.

  METHOD constructor.
    me->destination = destination.
  ENDMETHOD.

  METHOD zif_http_transport~send.
    DATA(client) = open( ).

    TRY.
        fill( request     = request
              web_request = client->get_http_request( ) ).

        IF request->needs_csrf_token( ) = abap_true.
          client->set_csrf_token( ).
        ENDIF.

        result = answer( client->execute( i_method  = request->http_method( )
                                          i_timeout = request->timeout( ) ) ).
      CATCH cx_web_http_client_error cx_web_message_error INTO DATA(error).
        close_quietly( client ).
        RAISE EXCEPTION NEW zcx_http( text     = |{ describe( request ) } failed: { error->get_text( ) }|
                                      previous = error ).
    ENDTRY.

    close_quietly( client ).
  ENDMETHOD.

  METHOD open.
    TRY.
        result = cl_web_http_client_manager=>create_by_http_destination( destination ).
      CATCH cx_web_http_client_error INTO DATA(error).
        RAISE EXCEPTION NEW zcx_http( text     = |HTTP client cannot be opened: { error->get_text( ) }|
                                      previous = error ).
    ENDTRY.
  ENDMETHOD.

  METHOD fill.
    IF request->path( ) IS NOT INITIAL.
      web_request->set_uri_path( request->path( ) ).
    ENDIF.

    IF request->query_string( ) IS NOT INITIAL.
      web_request->set_query( request->query_string( ) ).
    ENDIF.

    " Header fields go first: the content type they may carry decides how the
    " runtime encodes the body that follows.
    DATA(headers) = request->headers( ).
    LOOP AT headers INTO DATA(header).
      web_request->set_header_field( i_name  = header-name
                                     i_value = header-value ).
    ENDLOOP.

    fill_body( request     = request
               web_request = web_request ).
  ENDMETHOD.

  METHOD fill_body.
    DATA(form_fields) = request->form_fields( ).
    LOOP AT form_fields INTO DATA(field).
      web_request->set_form_field( i_name  = field-name
                                   i_value = field-value ).
    ENDLOOP.

    IF request->binary( ) IS NOT INITIAL.
      web_request->set_binary( request->binary( ) ).
    ELSEIF request->text( ) IS NOT INITIAL.
      web_request->set_text( request->text( ) ).
    ENDIF.
  ENDMETHOD.

  METHOD answer.
    DATA(status) = web_response->get_status( ).

    DATA(parts) = VALUE zif_http_response=>parts( status  = status-code
                                                  reason  = status-reason
                                                  headers = web_response->get_header_fields( )
                                                  binary  = web_response->get_binary( ) ).

    TRY.
        parts-text = web_response->get_text( ).
      CATCH cx_web_message_error.
        " A body that cannot be decoded as text stays reachable through binary( )
    ENDTRY.

    result = NEW lcl_response( parts ).
  ENDMETHOD.

  METHOD close_quietly.
    TRY.
        client->close( ).
      CATCH cx_web_http_client_error.
        " The runtime releases the connection anyway and the answer is already read
    ENDTRY.
  ENDMETHOD.

  METHOD describe.
    result = |{ request->http_method( ) } { request->path( ) }|.
  ENDMETHOD.

ENDCLASS.
