"! <p class="shorttext synchronized" lang="EN">HTTP request builder</p>
"! Collects the parts of one request and sends it. Every configuring method
"! returns the builder, so a request reads as one chain that ends in
"! {@link zif_http_request_builder.METH:send}. A builder is obtained from
"! {@link zif_http_client}, which fixes the HTTP method and the path.
"! <p>Text, JSON and binary bodies replace each other; the last one set wins.
"! A header field set twice keeps only the last value.</p>
INTERFACE zif_http_request_builder
  PUBLIC.

  CONSTANTS:
    "! Media types the builder sets on behalf of the caller.
    BEGIN OF media_type,
      json   TYPE string VALUE `application/json`,
      text   TYPE string VALUE `text/plain; charset=utf-8`,
      binary TYPE string VALUE `application/octet-stream`,
      form   TYPE string VALUE `application/x-www-form-urlencoded`,
    END OF media_type.

  "! Adds a query parameter. The same name may be added more than once; the
  "! value is encoded when the request is sent.
  "! @parameter name  | Parameter name
  "! @parameter value | Parameter value, not yet encoded
  "! @parameter self  | Same instance, for chaining
  METHODS query
    IMPORTING name        TYPE string
              value       TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_http_request_builder.

  "! Sets a header field. A field of the same name, whatever its case, is replaced.
  "! @parameter name  | Header field name, for example Accept
  "! @parameter value | Header field value
  "! @parameter self  | Same instance, for chaining
  METHODS header
    IMPORTING name        TYPE string
              value       TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_http_request_builder.

  "! Sends a bearer token in the Authorization header field.
  "! @parameter token | Token as issued, without the Bearer prefix
  "! @parameter self  | Same instance, for chaining
  METHODS bearer
    IMPORTING token       TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_http_request_builder.

  "! Sends user name and password as HTTP basic authentication.
  "! @parameter user     | User name
  "! @parameter password | Password
  "! @parameter self     | Same instance, for chaining
  METHODS basic_auth
    IMPORTING user        TYPE string
              password    TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_http_request_builder.

  "! Sends the text as JSON body and sets the Content-Type to application/json.
  "! @parameter json | JSON document
  "! @parameter self | Same instance, for chaining
  METHODS json
    IMPORTING json        TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_http_request_builder.

  "! Sends text as the body.
  "! @parameter text         | Body text
  "! @parameter content_type | Media type of the text, plain UTF-8 text when left out
  "! @parameter self         | Same instance, for chaining
  METHODS text
    IMPORTING text         TYPE string
              content_type TYPE string DEFAULT media_type-text
    RETURNING VALUE(self)  TYPE REF TO zif_http_request_builder.

  "! Sends raw bytes as the body.
  "! @parameter bytes        | Body bytes
  "! @parameter content_type | Media type of the bytes, octet stream when left out
  "! @parameter self         | Same instance, for chaining
  METHODS binary
    IMPORTING bytes        TYPE xstring
              content_type TYPE string DEFAULT media_type-binary
    RETURNING VALUE(self)  TYPE REF TO zif_http_request_builder.

  "! Adds a form field. All form fields together become an
  "! application/x-www-form-urlencoded body, encoded by the runtime.
  "! @parameter name  | Field name
  "! @parameter value | Field value, not yet encoded
  "! @parameter self  | Same instance, for chaining
  METHODS form_field
    IMPORTING name        TYPE string
              value       TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_http_request_builder.

  "! Limits the time the round trip may take.
  "! @parameter seconds | Time limit, zero restores the default of the runtime
  "! @parameter self    | Same instance, for chaining
  METHODS timeout
    IMPORTING seconds     TYPE i
    RETURNING VALUE(self) TYPE REF TO zif_http_request_builder.

  "! Fetches a CSRF token from the destination first and sends it along with
  "! the request, as SAP OData services demand for modifying calls.
  "! @parameter self | Same instance, for chaining
  METHODS with_csrf_token
    RETURNING VALUE(self) TYPE REF TO zif_http_request_builder.

  "! Sends the request and hands back the answer. Any status code is a regular
  "! answer; only a request that could not be sent or answered raises.
  "! @parameter result   | Answer of the server
  "! @raising   zcx_http | The request could not be sent or no answer arrived
  METHODS send
    RETURNING VALUE(result) TYPE REF TO zif_http_response
    RAISING   zcx_http.

ENDINTERFACE.
