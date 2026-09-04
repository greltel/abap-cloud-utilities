"! <p class="shorttext synchronized" lang="EN">HTTP request</p>
"! Immutable request as handed to a {@link zif_http_transport}: everything the
"! {@link zif_http_request_builder} collected, frozen at the moment of sending.
"! Authorization and content type are already ordinary header fields here.
INTERFACE zif_http_request
  PUBLIC.

  "! HTTP method.
  "! @parameter result | One of the if_web_http_client method constants
  METHODS http_method
    RETURNING VALUE(result) TYPE if_web_http_client=>method.

  "! Path of the resource, appended to the path prefix of the destination.
  "! @parameter result | URI path, empty when the destination already names the resource
  METHODS path
    RETURNING VALUE(result) TYPE string.

  "! Query parameters in the order they were added, not yet encoded.
  "! @parameter result | Name and value pairs
  METHODS query
    RETURNING VALUE(result) TYPE if_web_http_request=>name_value_pairs.

  "! Query parameters as an encoded query string, without the leading question mark.
  "! @parameter result | Encoded query string, empty when there are no parameters
  METHODS query_string
    RETURNING VALUE(result) TYPE string.

  "! Header fields, one entry per name.
  "! @parameter result | Name and value pairs
  METHODS headers
    RETURNING VALUE(result) TYPE if_web_http_request=>name_value_pairs.

  "! Form fields, sent as an application/x-www-form-urlencoded body.
  "! @parameter result | Name and value pairs
  METHODS form_fields
    RETURNING VALUE(result) TYPE if_web_http_request=>name_value_pairs.

  "! Text body.
  "! @parameter result | Body text, empty when the body is binary or absent
  METHODS text
    RETURNING VALUE(result) TYPE string.

  "! Binary body.
  "! @parameter result | Body bytes, empty when the body is text or absent
  METHODS binary
    RETURNING VALUE(result) TYPE xstring.

  "! Time limit for the round trip.
  "! @parameter result | Seconds, zero for the default of the runtime
  METHODS timeout
    RETURNING VALUE(result) TYPE i.

  "! Whether a CSRF token has to be fetched from the destination and sent along.
  "! @parameter result | abap_true when the token handshake was requested
  METHODS needs_csrf_token
    RETURNING VALUE(result) TYPE abap_bool.

ENDINTERFACE.
