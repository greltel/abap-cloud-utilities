"! <p class="shorttext synchronized" lang="EN">HTTP client utility</p>
"! Entry point of the HTTP utility. Opens a {@link zif_http_client} for a
"! destination; requests are then built fluently and answered with an immutable
"! {@link zif_http_response}. Standalone - depends on nothing but SAP released APIs.
CLASS zcl_http DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.

    "! Opens a client for an HTTP destination. How the destination is obtained
    "! depends on the platform: on SAP BTP ABAP Environment and SAP S/4HANA
    "! Cloud Public Edition through cl_http_destination_provider; on SAP S/4HANA
    "! on-premise and Private Edition through a released wrapper the customer
    "! maintains in Standard ABAP, since no destination provider is released
    "! there. The client itself is the same everywhere.
    "! @parameter destination | Destination to send to
    "! @parameter result      | Client for the destination
    CLASS-METHODS for_destination
      IMPORTING destination   TYPE REF TO if_http_destination
      RETURNING VALUE(result) TYPE REF TO zif_http_client.

    "! Opens a client on a transport the caller supplies. Meant for tests,
    "! where a double replaces the network.
    "! @parameter transport | Transport that answers the requests
    "! @parameter result    | Client on the transport
    CLASS-METHODS for_transport
      IMPORTING transport     TYPE REF TO zif_http_transport
      RETURNING VALUE(result) TYPE REF TO zif_http_client.

    "! Builds a response without a network round trip, for transport doubles.
    "! @parameter parts  | Status, header fields and body of the response
    "! @parameter result | Immutable response
    CLASS-METHODS response
      IMPORTING parts         TYPE zif_http_response=>parts
      RETURNING VALUE(result) TYPE REF TO zif_http_response.

ENDCLASS.


CLASS zcl_http IMPLEMENTATION.

  METHOD for_destination.
    result = NEW lcl_client( NEW lcl_web_transport( destination ) ).
  ENDMETHOD.

  METHOD for_transport.
    result = NEW lcl_client( transport ).
  ENDMETHOD.

  METHOD response.
    result = NEW lcl_response( parts ).
  ENDMETHOD.

ENDCLASS.

