"! <p class="shorttext synchronized" lang="EN">HTTP transport</p>
"! Puts a request on the wire and hands back the answer. The utility ships an
"! implementation on top of IF_WEB_HTTP_CLIENT; a consumer test replaces it
"! through {@link zcl_http.METH:for_transport} with a double that records the
"! request and answers with a response built by {@link zcl_http.METH:response}.
INTERFACE zif_http_transport
  PUBLIC.

  "! Sends one request.
  "! @parameter request  | Request to send
  "! @parameter result   | Answer of the server
  "! @raising   zcx_http | The request could not be sent or no answer arrived
  METHODS send
    IMPORTING request       TYPE REF TO zif_http_request
    RETURNING VALUE(result) TYPE REF TO zif_http_response
    RAISING   zcx_http.

ENDINTERFACE.
