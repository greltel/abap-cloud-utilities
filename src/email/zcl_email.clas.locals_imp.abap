*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
TYPES:
  "! Everything a message consists of. The builder fills it, the message keeps it.
  BEGIN OF message_content,
    from        TYPE string,
    to          TYPE zif_email_message=>address_table,
    cc          TYPE zif_email_message=>address_table,
    bcc         TYPE zif_email_message=>address_table,
    subject     TYPE string,
    text        TYPE string,
    html        TYPE string,
    attachments TYPE zif_email_message=>attachment_table,
  END OF message_content.


"! Validates and normalises email addresses. Deliberately light: it catches
"! the mistakes that would otherwise surface as an obscure error deep inside
"! the mail system, it does not try to implement RFC 5322.
CLASS lcl_address DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS normalise
      IMPORTING address       TYPE string
      RETURNING VALUE(result) TYPE string
      RAISING   zcx_email.

    CLASS-METHODS is_valid
      IMPORTING address       TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    CONSTANTS max_length TYPE i VALUE 512.
    CONSTANTS at_sign TYPE string VALUE `@`.
    CONSTANTS dot TYPE string VALUE `.`.
    CONSTANTS blank TYPE string VALUE ` `.

    CLASS-METHODS reject_bad_shape
      IMPORTING address TYPE string
      RAISING   zcx_email.

    CLASS-METHODS reject_bad_parts
      IMPORTING address TYPE string
      RAISING   zcx_email.

ENDCLASS.


"! Immutable message. Holds a private copy of the content and hands out copies.
CLASS lcl_message DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_email_message.

    METHODS constructor
      IMPORTING content TYPE message_content.

  PRIVATE SECTION.
    DATA content TYPE message_content.

ENDCLASS.


"! Collects the parts of a message and checks them as they arrive.
CLASS lcl_builder DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_email_builder.

  PRIVATE SECTION.
    CONSTANTS max_subject_length TYPE i VALUE 1024.
    CONSTANTS max_content_type_length TYPE i VALUE 128.

    DATA draft TYPE message_content.

    METHODS require_text
      IMPORTING value TYPE string
                what  TYPE string
      RAISING   zcx_email.

    METHODS add_attachment
      IMPORTING attachment TYPE zif_email_message=>attachment
      RAISING   zcx_email.

    METHODS reject_incomplete
      RAISING zcx_email.

ENDCLASS.


"! Seam to the mail system: one outbound mail at a time. Kept as thin as
"! possible so that everything above it can be tested with a recording double.
INTERFACE lif_bcs_mail.

  METHODS open
    RAISING cx_bcs_mail.

  METHODS set_sender
    IMPORTING address TYPE string
    RAISING   cx_bcs_mail.

  METHODS add_to
    IMPORTING address TYPE string
    RAISING   cx_bcs_mail.

  METHODS add_cc
    IMPORTING address TYPE string
    RAISING   cx_bcs_mail.

  METHODS add_bcc
    IMPORTING address TYPE string
    RAISING   cx_bcs_mail.

  METHODS set_subject
    IMPORTING subject TYPE string.

  METHODS set_main_text
    IMPORTING text TYPE string
    RAISING   cx_bcs_mail.

  METHODS set_main_html
    IMPORTING html TYPE string
    RAISING   cx_bcs_mail.

  METHODS add_alternative_text
    IMPORTING text TYPE string
    RAISING   cx_bcs_mail.

  METHODS attach
    IMPORTING attachment TYPE zif_email_message=>attachment
    RAISING   cx_bcs_mail.

  METHODS send
    RETURNING VALUE(result) TYPE zif_email_sender=>delivery
    RAISING   cx_bcs_mail.

ENDINTERFACE.


"! The only class that touches CL_BCS_MAIL_MESSAGE.
CLASS lcl_bcs_mail DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES lif_bcs_mail.

  PRIVATE SECTION.
    DATA mail TYPE REF TO cl_bcs_mail_message.

ENDCLASS.


"! Translates a message into calls on the mail system seam.
CLASS lcl_sender DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_email_sender.

    METHODS constructor
      IMPORTING bcs TYPE REF TO lif_bcs_mail.

  PRIVATE SECTION.
    DATA bcs TYPE REF TO lif_bcs_mail.

    METHODS transfer
      IMPORTING message       TYPE REF TO zif_email_message
      RETURNING VALUE(result) TYPE zif_email_sender=>delivery
      RAISING   cx_bcs_mail.

    METHODS add_recipients
      IMPORTING message TYPE REF TO zif_email_message
      RAISING   cx_bcs_mail.

    METHODS set_bodies
      IMPORTING message TYPE REF TO zif_email_message
      RAISING   cx_bcs_mail.

ENDCLASS.


CLASS lcl_address IMPLEMENTATION.

  METHOD normalise.
    result = condense( address ).

    reject_bad_shape( result ).
    reject_bad_parts( result ).
  ENDMETHOD.

  METHOD is_valid.
    TRY.
        normalise( address ).

        result = abap_true.
      CATCH zcx_email.
        result = abap_false.
    ENDTRY.
  ENDMETHOD.

  METHOD reject_bad_shape.
    IF address IS INITIAL.
      RAISE EXCEPTION NEW zcx_email( |Email address is empty| ).
    ENDIF.

    IF strlen( address ) > max_length.
      RAISE EXCEPTION NEW zcx_email( |Email address exceeds { max_length } characters| ).
    ENDIF.

    IF contains( val = address
                 sub = blank ).
      RAISE EXCEPTION NEW zcx_email( |Email address { address } contains blanks| ).
    ENDIF.

    IF count( val = address
              sub = at_sign ) <> 1.
      RAISE EXCEPTION NEW zcx_email( |Email address { address } must contain exactly one @| ).
    ENDIF.
  ENDMETHOD.

  METHOD reject_bad_parts.
    DATA(local_part) = substring_before( val = address
                                         sub = at_sign ).
    DATA(domain) = substring_after( val = address
                                    sub = at_sign ).

    IF local_part IS INITIAL.
      RAISE EXCEPTION NEW zcx_email( |Email address { address } has nothing before the @| ).
    ENDIF.

    IF domain IS INITIAL OR NOT contains( val = domain
                                          sub = dot ).
      RAISE EXCEPTION NEW zcx_email( |Email address { address } has no domain with a dot after the @| ).
    ENDIF.

    DATA(first_dot) = find( val = domain
                            sub = dot ).
    DATA(last_dot) = find( val = domain
                           sub = dot
                           occ = -1 ).

    IF first_dot = 0 OR last_dot = strlen( domain ) - 1.
      RAISE EXCEPTION NEW zcx_email( |Domain of email address { address } starts or ends with a dot| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_message IMPLEMENTATION.

  METHOD constructor.
    me->content = content.
  ENDMETHOD.

  METHOD zif_email_message~from.
    result = content-from.
  ENDMETHOD.

  METHOD zif_email_message~to.
    result = content-to.
  ENDMETHOD.

  METHOD zif_email_message~cc.
    result = content-cc.
  ENDMETHOD.

  METHOD zif_email_message~bcc.
    result = content-bcc.
  ENDMETHOD.

  METHOD zif_email_message~subject.
    result = content-subject.
  ENDMETHOD.

  METHOD zif_email_message~text.
    result = content-text.
  ENDMETHOD.

  METHOD zif_email_message~html.
    result = content-html.
  ENDMETHOD.

  METHOD zif_email_message~attachments.
    result = content-attachments.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_builder IMPLEMENTATION.

  METHOD zif_email_builder~from.
    draft-from = lcl_address=>normalise( address ).

    self = me.
  ENDMETHOD.

  METHOD zif_email_builder~to.
    DATA(normalised) = lcl_address=>normalise( address ).

    INSERT normalised INTO TABLE draft-to.

    self = me.
  ENDMETHOD.

  METHOD zif_email_builder~cc.
    DATA(normalised) = lcl_address=>normalise( address ).

    INSERT normalised INTO TABLE draft-cc.

    self = me.
  ENDMETHOD.

  METHOD zif_email_builder~bcc.
    DATA(normalised) = lcl_address=>normalise( address ).

    INSERT normalised INTO TABLE draft-bcc.

    self = me.
  ENDMETHOD.

  METHOD zif_email_builder~subject.
    require_text( value = text
                  what  = `Subject` ).

    IF strlen( text ) > max_subject_length.
      RAISE EXCEPTION NEW zcx_email( |Subject exceeds { max_subject_length } characters| ).
    ENDIF.

    draft-subject = text.

    self = me.
  ENDMETHOD.

  METHOD zif_email_builder~text.
    require_text( value = body
                  what  = `Text body` ).

    draft-text = body.

    self = me.
  ENDMETHOD.

  METHOD zif_email_builder~html.
    require_text( value = body
                  what  = `HTML body` ).

    draft-html = body.

    self = me.
  ENDMETHOD.

  METHOD zif_email_builder~attach.
    add_attachment( VALUE #( file_name    = file_name
                             content_type = content_type
                             is_text      = abap_false
                             bytes        = bytes ) ).

    self = me.
  ENDMETHOD.

  METHOD zif_email_builder~attach_text.
    add_attachment( VALUE #( file_name    = file_name
                             content_type = content_type
                             is_text      = abap_true
                             text         = text ) ).

    self = me.
  ENDMETHOD.

  METHOD zif_email_builder~build.
    reject_incomplete( ).

    result = NEW lcl_message( draft ).
  ENDMETHOD.

  METHOD require_text.
    IF value IS INITIAL.
      RAISE EXCEPTION NEW zcx_email( |{ what } is empty| ).
    ENDIF.
  ENDMETHOD.

  METHOD add_attachment.
    DATA(file_name) = condense( attachment-file_name ).

    IF file_name IS INITIAL.
      RAISE EXCEPTION NEW zcx_email( |Attachment file name is missing| ).
    ENDIF.

    IF attachment-text IS INITIAL AND attachment-bytes IS INITIAL.
      RAISE EXCEPTION NEW zcx_email( |Attachment { attachment-file_name } has no content| ).
    ENDIF.

    IF strlen( attachment-content_type ) > max_content_type_length.
      RAISE EXCEPTION NEW zcx_email( |MIME type of attachment { attachment-file_name } exceeds | &&
                                     |{ max_content_type_length } characters| ).
    ENDIF.

    DATA(complete) = attachment.

    complete-content_type = COND #( WHEN attachment-content_type IS NOT INITIAL THEN attachment-content_type
                                    WHEN attachment-is_text = abap_true THEN zcl_email=>content_type-plain_text
                                    ELSE zcl_email=>content_type-binary ).

    INSERT complete INTO TABLE draft-attachments.
  ENDMETHOD.

  METHOD reject_incomplete.
    IF draft-from IS INITIAL.
      RAISE EXCEPTION NEW zcx_email( |Sender address is missing| ).
    ENDIF.

    IF draft-to IS INITIAL AND draft-cc IS INITIAL AND draft-bcc IS INITIAL.
      RAISE EXCEPTION NEW zcx_email( |At least one recipient is required| ).
    ENDIF.

    IF draft-subject IS INITIAL.
      RAISE EXCEPTION NEW zcx_email( |Subject is missing| ).
    ENDIF.

    IF draft-text IS INITIAL AND draft-html IS INITIAL.
      RAISE EXCEPTION NEW zcx_email( |Message body is missing| ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_bcs_mail IMPLEMENTATION.

  METHOD lif_bcs_mail~open.
    mail = cl_bcs_mail_message=>create_instance( ).
  ENDMETHOD.

  METHOD lif_bcs_mail~set_sender.
    DATA(bcs_address) = CONV cl_bcs_mail_message=>ty_address( address ).

    mail->set_sender( bcs_address ).
  ENDMETHOD.

  METHOD lif_bcs_mail~add_to.
    DATA(bcs_address) = CONV cl_bcs_mail_message=>ty_address( address ).

    mail->add_recipient( iv_address = bcs_address
                         iv_copy    = cl_bcs_mail_message=>to ).
  ENDMETHOD.

  METHOD lif_bcs_mail~add_cc.
    DATA(bcs_address) = CONV cl_bcs_mail_message=>ty_address( address ).

    mail->add_recipient( iv_address = bcs_address
                         iv_copy    = cl_bcs_mail_message=>cc ).
  ENDMETHOD.

  METHOD lif_bcs_mail~add_bcc.
    DATA(bcs_address) = CONV cl_bcs_mail_message=>ty_address( address ).

    mail->add_recipient( iv_address = bcs_address
                         iv_copy    = cl_bcs_mail_message=>bcc ).
  ENDMETHOD.

  METHOD lif_bcs_mail~set_subject.
    DATA(bcs_subject) = CONV cl_bcs_mail_message=>ty_subject( subject ).

    mail->set_subject( bcs_subject ).
  ENDMETHOD.

  METHOD lif_bcs_mail~set_main_text.
    mail->set_main( cl_bcs_mail_textpart=>create_text_plain( text ) ).
  ENDMETHOD.

  METHOD lif_bcs_mail~set_main_html.
    mail->set_main( cl_bcs_mail_textpart=>create_text_html( html ) ).
  ENDMETHOD.

  METHOD lif_bcs_mail~add_alternative_text.
    mail->add_main_alternative( cl_bcs_mail_textpart=>create_text_plain( text ) ).
  ENDMETHOD.

  METHOD lif_bcs_mail~attach.
    DATA(bcs_content_type) = CONV cl_bcs_mail_bodypart=>ty_content_type( attachment-content_type ).

    IF attachment-is_text = abap_true.
      DATA(text_part) = cl_bcs_mail_textpart=>create_instance( iv_content      = attachment-text
                                                               iv_content_type = bcs_content_type
                                                               iv_filename     = attachment-file_name ).

      mail->add_attachment( text_part ).
    ELSE.
      DATA(binary_part) = cl_bcs_mail_binarypart=>create_instance( iv_content      = attachment-bytes
                                                                   iv_content_type = bcs_content_type
                                                                   iv_filename     = attachment-file_name ).

      mail->add_attachment( binary_part ).
    ENDIF.
  ENDMETHOD.

  METHOD lif_bcs_mail~send.
    mail->send( IMPORTING et_status      = DATA(statuses)
                          ev_mail_status = result-status ).

    result-mail_id = mail->get_mail_id( ).
    result-recipients = VALUE #( FOR entry IN statuses
                                 ( address = condense( entry-recipient )
                                   status  = entry-status ) ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_sender IMPLEMENTATION.

  METHOD constructor.
    me->bcs = bcs.
  ENDMETHOD.

  METHOD zif_email_sender~send.
    TRY.
        result = transfer( message ).
      CATCH cx_bcs_mail INTO DATA(mail_error).
        RAISE EXCEPTION NEW zcx_email( text     = |Mail system rejected the message: { mail_error->get_text( ) }|
                                       previous = mail_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD transfer.
    bcs->open( ).
    bcs->set_sender( message->from( ) ).

    add_recipients( message ).

    bcs->set_subject( message->subject( ) ).

    set_bodies( message ).

    LOOP AT message->attachments( ) INTO DATA(attachment).
      bcs->attach( attachment ).
    ENDLOOP.

    result = bcs->send( ).
  ENDMETHOD.

  METHOD add_recipients.
    LOOP AT message->to( ) INTO DATA(primary).
      bcs->add_to( primary ).
    ENDLOOP.

    LOOP AT message->cc( ) INTO DATA(copy).
      bcs->add_cc( copy ).
    ENDLOOP.

    LOOP AT message->bcc( ) INTO DATA(blind_copy).
      bcs->add_bcc( blind_copy ).
    ENDLOOP.
  ENDMETHOD.

  METHOD set_bodies.
    DATA(html) = message->html( ).
    DATA(text) = message->text( ).

    IF html IS INITIAL.
      bcs->set_main_text( text ).
      RETURN.
    ENDIF.

    bcs->set_main_html( html ).

    IF text IS NOT INITIAL.
      bcs->add_alternative_text( text ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
