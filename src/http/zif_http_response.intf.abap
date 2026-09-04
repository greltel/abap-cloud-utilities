"! <p class="shorttext synchronized" lang="EN">HTTP response</p>
"! Immutable answer to an HTTP request: status line, header fields and body.
"! Header names are matched without regard to case, as HTTP demands. A status
"! outside the 2xx range is a regular answer, not an error - a chain that must
"! not go on with such an answer calls {@link zif_http_response.METH:ensure_success}.
INTERFACE zif_http_response
  PUBLIC.

  TYPES:
    "! Every part of a response. Lets a test double of {@link zif_http_transport}
    "! answer with a response built through {@link zcl_http.METH:response},
    "! without a network round trip.
    BEGIN OF parts,
      status  TYPE i,
      reason  TYPE string,
      headers TYPE if_web_http_request=>name_value_pairs,
      text    TYPE string,
      binary  TYPE xstring,
    END OF parts.

  "! HTTP status code, for example 200 or 404.
  "! @parameter result | Status code
  METHODS status
    RETURNING VALUE(result) TYPE i.

  "! Reason phrase of the status line, for example OK or Not Found.
  "! @parameter result | Reason phrase, may be empty
  METHODS reason
    RETURNING VALUE(result) TYPE string.

  "! Whether the status code is in the 2xx range.
  "! @parameter result | abap_true for 200 to 299
  METHODS is_success
    RETURNING VALUE(result) TYPE abap_bool.

  "! Raises unless the status code is in the 2xx range, so a chain can insist
  "! on success before it reads the body.
  "! @parameter self     | Same instance, for chaining
  "! @raising   zcx_http | The status code is not in the 2xx range
  METHODS ensure_success
    RETURNING VALUE(self) TYPE REF TO zif_http_response
    RAISING   zcx_http.

  "! Value of one header field. The name is matched without regard to case.
  "! @parameter name   | Header field name, for example Content-Type
  "! @parameter result | Field value, empty when the field is absent
  METHODS header
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE string.

  "! All header fields as delivered by the server.
  "! @parameter result | Name and value pairs
  METHODS headers
    RETURNING VALUE(result) TYPE if_web_http_request=>name_value_pairs.

  "! Value of the Content-Type header field.
  "! @parameter result | Media type with its parameters, empty when absent
  METHODS content_type
    RETURNING VALUE(result) TYPE string.

  "! Body as text, decoded with the character set the server declared.
  "! @parameter result | Body text, empty when there is no body or it cannot be decoded
  METHODS text
    RETURNING VALUE(result) TYPE string.

  "! Body as raw bytes, exactly as received.
  "! @parameter result | Body bytes, empty when there is no body
  METHODS binary
    RETURNING VALUE(result) TYPE xstring.

ENDINTERFACE.
