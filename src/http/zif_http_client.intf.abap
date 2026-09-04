"! <p class="shorttext synchronized" lang="EN">HTTP client</p>
"! Opens requests against one destination. Every method hands out a fresh
"! {@link zif_http_request_builder} for the given HTTP method and path; the
"! path is appended to the path prefix the destination carries.
INTERFACE zif_http_client
  PUBLIC.

  "! Starts a GET request.
  "! @parameter path   | URI path of the resource, empty when the destination already names it
  "! @parameter result | Builder for the request
  METHODS get
    IMPORTING path          TYPE string DEFAULT ``
    RETURNING VALUE(result) TYPE REF TO zif_http_request_builder.

  "! Starts a POST request.
  "! @parameter path   | URI path of the resource, empty when the destination already names it
  "! @parameter result | Builder for the request
  METHODS post
    IMPORTING path          TYPE string DEFAULT ``
    RETURNING VALUE(result) TYPE REF TO zif_http_request_builder.

  "! Starts a PUT request.
  "! @parameter path   | URI path of the resource, empty when the destination already names it
  "! @parameter result | Builder for the request
  METHODS put
    IMPORTING path          TYPE string DEFAULT ``
    RETURNING VALUE(result) TYPE REF TO zif_http_request_builder.

  "! Starts a PATCH request.
  "! @parameter path   | URI path of the resource, empty when the destination already names it
  "! @parameter result | Builder for the request
  METHODS patch
    IMPORTING path          TYPE string DEFAULT ``
    RETURNING VALUE(result) TYPE REF TO zif_http_request_builder.

  "! Starts a DELETE request.
  "! @parameter path   | URI path of the resource, empty when the destination already names it
  "! @parameter result | Builder for the request
  METHODS delete
    IMPORTING path          TYPE string DEFAULT ``
    RETURNING VALUE(result) TYPE REF TO zif_http_request_builder.

  "! Starts a request with any HTTP method, for example HEAD or OPTIONS.
  "! @parameter http_method | One of the if_web_http_client method constants
  "! @parameter path        | URI path of the resource, empty when the destination already names it
  "! @parameter result      | Builder for the request
  METHODS request
    IMPORTING http_method   TYPE if_web_http_client=>method
              path          TYPE string DEFAULT ``
    RETURNING VALUE(result) TYPE REF TO zif_http_request_builder.

ENDINTERFACE.
