"! <p class="shorttext synchronized" lang="EN">Email utility demo</p>
"! Runnable showcase for {@link zcl_email}. Start it with F9 in ADT.
"! <p>Composing and validation run without any configuration. The send at the
"! end only happens when the two address constants are filled in, because it
"! needs a configured mail system and a real mailbox.</p>
CLASS zcl_email_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS sender_address TYPE string VALUE ``.
    CONSTANTS recipient_address TYPE string VALUE ``.
    CONSTANTS pdf_signature TYPE xstring VALUE '255044462D312E37'.

    METHODS show_composing
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_email.

    METHODS show_addresses
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS show_sending
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_email.

    METHODS as_yes_no
      IMPORTING flag          TYPE abap_bool
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_email_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_composing( out ).
        show_addresses( out ).
        show_rejected_input( out ).
        show_sending( out ).
      CATCH zcx_email INTO DATA(error).
        out->write( |Email demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_composing.
    DATA(message) = zcl_email=>compose(
      )->from( `noreply@example.com`
      )->to( `jane.doe@example.com`
      )->cc( `boss@example.com`
      )->subject( `Weekly report`
      )->text( `Please find the report attached.`
      )->html( `<p>Please find the report <strong>attached</strong>.</p>`
      )->attach( file_name    = `report.pdf`
                 bytes        = pdf_signature
                 content_type = zcl_email=>content_type-pdf
      )->attach_text( file_name    = `figures.csv`
                      text         = `region,revenue`
                      content_type = zcl_email=>content_type-csv
      )->build( ).

    DATA(primary_recipients) = message->to( ).
    DATA(copy_recipients) = message->cc( ).

    out->write( `--- Composing ---` ).
    out->write( |From       : { message->from( ) }| ).
    out->write( |To         : { concat_lines_of( table = primary_recipients
                                                 sep   = `, ` ) }| ).
    out->write( |Cc         : { concat_lines_of( table = copy_recipients
                                                 sep   = `, ` ) }| ).
    out->write( |Subject    : { message->subject( ) }| ).
    out->write( |Text       : { message->text( ) }| ).
    out->write( |HTML       : { message->html( ) }| ).

    LOOP AT message->attachments( ) INTO DATA(attachment).
      out->write( |Attachment : { attachment-file_name } ({ attachment-content_type })| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD show_addresses.
    out->write( `--- Addresses ---` ).
    out->write( |john.doe@example.com : { as_yes_no( zcl_email=>is_valid_address( `john.doe@example.com` ) ) }| ).
    out->write( |john.doe@example     : { as_yes_no( zcl_email=>is_valid_address( `john.doe@example` ) ) }| ).
    out->write( |john doe@example.com : { as_yes_no( zcl_email=>is_valid_address( `john doe@example.com` ) ) }| ).
  ENDMETHOD.

  METHOD show_rejected_input.
    out->write( `--- Rejected input ---` ).

    TRY.
        zcl_email=>compose( )->to( `john@doe@example.com` ).
      CATCH zcx_email INTO DATA(bad_address).
        out->write( |Recipient : { bad_address->get_text( ) }| ).
    ENDTRY.

    TRY.
        zcl_email=>compose( )->from( `noreply@example.com` )->build( ).
      CATCH zcx_email INTO DATA(incomplete).
        out->write( |Build     : { incomplete->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_sending.
    DATA(recipient) = recipient_address.

    out->write( `--- Sending ---` ).

    IF recipient IS INITIAL.
      out->write( `Fill in sender_address and recipient_address to send the demo message` ).
      RETURN.
    ENDIF.

    DATA(message) = zcl_email=>compose(
      )->from( sender_address
      )->to( recipient
      )->subject( `abap-cloud-utilities demo`
      )->text( `Sent through ZCL_EMAIL on top of CL_BCS_MAIL_MESSAGE.`
      )->attach_text( file_name = `demo.txt`
                      text      = `Hello from ABAP Cloud`
      )->build( ).

    DATA(delivery) = zcl_email=>sender( )->send( message ).

    out->write( |Mail id : { delivery-mail_id }| ).
    out->write( |Status  : { delivery-status }| ).

    LOOP AT delivery-recipients INTO DATA(recipient_status).
      out->write( |{ recipient_status-address } : { recipient_status-status }| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD as_yes_no.
    result = COND string( WHEN flag = abap_true THEN `valid`
                          ELSE `invalid` ).
  ENDMETHOD.

ENDCLASS.

