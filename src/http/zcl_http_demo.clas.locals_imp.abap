*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations

" Transport double that never touches the network: it answers every request
" with a text body that lists what it received, under a status of choice.
" A consumer test replaces the network the same way.
CLASS lcl_echo_transport DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_http_transport.

    METHODS constructor
      IMPORTING status TYPE i DEFAULT 200
                reason TYPE string DEFAULT `OK`.

  PRIVATE SECTION.
    DATA status TYPE i.
    DATA reason TYPE string.

ENDCLASS.


CLASS lcl_echo_transport IMPLEMENTATION.

  METHOD constructor.
    me->status = status.
    me->reason = reason.
  ENDMETHOD.

  METHOD zif_http_transport~send.
    DATA(target) = COND string( WHEN request->query_string( ) IS INITIAL THEN request->path( )
                                ELSE |{ request->path( ) }?{ request->query_string( ) }| ).
    DATA(headers) = request->headers( ).
    DATA(header_lines) = VALUE string_table( FOR header IN headers
                                             ( |{ header-name }: { header-value }| ) ).

    DATA(body_lines) = VALUE string_table( ( |{ request->http_method( ) } { target }| )
                                           ( LINES OF header_lines )
                                           ( `` )
                                           ( request->text( ) ) ).

    DATA(text) = concat_lines_of( table = body_lines
                                  sep   = cl_abap_char_utilities=>newline ).

    DATA(parts) = VALUE zif_http_response=>parts( status  = status
                                                  reason  = reason
                                                  headers = VALUE #( ( name  = `Content-Type`
                                                                       value = `text/plain` ) )
                                                  text    = text ).

    result = zcl_http=>response( parts ).
  ENDMETHOD.

ENDCLASS.
