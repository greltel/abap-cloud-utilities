"! <p class="shorttext synchronized" lang="EN">Email utility</p>
"! Entry point for composing and sending emails on top of the released
"! CL_BCS_MAIL_MESSAGE API. Standalone - depends on nothing but SAP released APIs.
CLASS zcl_email DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    CONSTANTS:
      BEGIN OF content_type,
        plain_text TYPE string VALUE `text/plain`,
        html       TYPE string VALUE `text/html`,
        csv        TYPE string VALUE `text/csv`,
        xml        TYPE string VALUE `text/xml`,
        json       TYPE string VALUE `application/json`,
        pdf        TYPE string VALUE `application/pdf`,
        xlsx       TYPE string VALUE `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`,
        binary     TYPE string VALUE `application/octet-stream`,
      END OF content_type.

    "! Starts a new, empty message.
    "! @parameter result | Builder to be closed with build
    CLASS-METHODS compose
      RETURNING VALUE(result) TYPE REF TO zif_email_builder.

    "! Creates the sender that hands messages to the mail system. Inject it into
    "! the consuming class and replace it with a double of zif_email_sender in tests.
    "! @parameter result | Sender backed by CL_BCS_MAIL_MESSAGE
    CLASS-METHODS sender
      RETURNING VALUE(result) TYPE REF TO zif_email_sender.

    "! Runs the address check of the builder without raising.
    "! @parameter address | Candidate address, leading and trailing blanks are ignored
    "! @parameter result  | abap_true when the builder would accept the address
    CLASS-METHODS is_valid_address
      IMPORTING address       TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS zcl_email IMPLEMENTATION.

  METHOD compose.
    result = NEW lcl_builder( ).
  ENDMETHOD.

  METHOD sender.
    result = NEW lcl_sender( NEW lcl_bcs_mail( ) ).
  ENDMETHOD.

  METHOD is_valid_address.
    result = lcl_address=>is_valid( address ).
  ENDMETHOD.

ENDCLASS.

