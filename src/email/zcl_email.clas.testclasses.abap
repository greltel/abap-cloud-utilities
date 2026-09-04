*"* use this source file for your ABAP unit test classes
CLASS ltc_addresses DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS domain TYPE string VALUE `@example.com`.

    METHODS given_plain_then_valid FOR TESTING.
    METHODS given_padded_then_trimmed FOR TESTING RAISING cx_static_check.
    METHODS given_empty_then_invalid FOR TESTING.
    METHODS given_blanks_only_then_invalid FOR TESTING.
    METHODS given_no_at_then_invalid FOR TESTING.
    METHODS given_two_at_then_invalid FOR TESTING.
    METHODS given_inner_blank_then_invalid FOR TESTING.
    METHODS given_no_local_then_invalid FOR TESTING.
    METHODS given_no_dot_then_invalid FOR TESTING.
    METHODS given_leading_dot_then_invalid FOR TESTING.
    METHODS given_trailing_dot_invalid FOR TESTING.
    METHODS given_max_length_then_valid FOR TESTING.
    METHODS given_too_long_then_invalid FOR TESTING.
    METHODS given_bad_to_then_raises FOR TESTING.
    METHODS given_bad_from_then_raises FOR TESTING.

    METHODS address_of_length
      IMPORTING length        TYPE i
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS ltc_addresses IMPLEMENTATION.

  METHOD given_plain_then_valid.
    cl_abap_unit_assert=>assert_true(
      act = zcl_email=>is_valid_address( `john.doe@example.com` )
      msg = 'A plain address is not accepted' ).
  ENDMETHOD.

  METHOD given_padded_then_trimmed.
    DATA(message) = zcl_email=>compose(
      )->from( `  noreply@example.com  `
      )->to( ` jane@example.com`
      )->subject( `Padding`
      )->text( `Body`
      )->build( ).

    cl_abap_unit_assert=>assert_equals(
      act = message->from( )
      exp = `noreply@example.com`
      msg = 'Blanks around the sender address are not removed' ).
    cl_abap_unit_assert=>assert_equals(
      act = message->to( )
      exp = VALUE zif_email_message=>address_table( ( `jane@example.com` ) )
      msg = 'Blanks around the recipient address are not removed' ).
  ENDMETHOD.

  METHOD given_empty_then_invalid.
    cl_abap_unit_assert=>assert_false(
      act = zcl_email=>is_valid_address( `` )
      msg = 'An empty address is accepted' ).
  ENDMETHOD.

  METHOD given_blanks_only_then_invalid.
    cl_abap_unit_assert=>assert_false(
      act = zcl_email=>is_valid_address( `   ` )
      msg = 'An address made of blanks is accepted' ).
  ENDMETHOD.

  METHOD given_no_at_then_invalid.
    cl_abap_unit_assert=>assert_false(
      act = zcl_email=>is_valid_address( `john.example.com` )
      msg = 'An address without @ is accepted' ).
  ENDMETHOD.

  METHOD given_two_at_then_invalid.
    cl_abap_unit_assert=>assert_false(
      act = zcl_email=>is_valid_address( `john@doe@example.com` )
      msg = 'An address with two @ is accepted' ).
  ENDMETHOD.

  METHOD given_inner_blank_then_invalid.
    cl_abap_unit_assert=>assert_false(
      act = zcl_email=>is_valid_address( `john doe@example.com` )
      msg = 'An address with an inner blank is accepted' ).
  ENDMETHOD.

  METHOD given_no_local_then_invalid.
    cl_abap_unit_assert=>assert_false(
      act = zcl_email=>is_valid_address( domain )
      msg = 'An address without a local part is accepted' ).
  ENDMETHOD.

  METHOD given_no_dot_then_invalid.
    cl_abap_unit_assert=>assert_false(
      act = zcl_email=>is_valid_address( `john@example` )
      msg = 'A domain without a dot is accepted' ).
  ENDMETHOD.

  METHOD given_leading_dot_then_invalid.
    cl_abap_unit_assert=>assert_false(
      act = zcl_email=>is_valid_address( `john@.example.com` )
      msg = 'A domain starting with a dot is accepted' ).
  ENDMETHOD.

  METHOD given_trailing_dot_invalid.
    cl_abap_unit_assert=>assert_false(
      act = zcl_email=>is_valid_address( `john@example.com.` )
      msg = 'A domain ending with a dot is accepted' ).
  ENDMETHOD.

  METHOD given_max_length_then_valid.
    cl_abap_unit_assert=>assert_true(
      act = zcl_email=>is_valid_address( address_of_length( 512 ) )
      msg = 'An address of exactly 512 characters is rejected' ).
  ENDMETHOD.

  METHOD given_too_long_then_invalid.
    cl_abap_unit_assert=>assert_false(
      act = zcl_email=>is_valid_address( address_of_length( 513 ) )
      msg = 'An address of 513 characters is accepted' ).
  ENDMETHOD.

  METHOD given_bad_to_then_raises.
    TRY.
        zcl_email=>compose( )->to( `not-an-address` ).

        cl_abap_unit_assert=>fail( 'A malformed recipient was unexpectedly accepted' ).
      CATCH zcx_email INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_bad_from_then_raises.
    TRY.
        zcl_email=>compose( )->from( `@example.com` ).

        cl_abap_unit_assert=>fail( 'A malformed sender was unexpectedly accepted' ).
      CATCH zcx_email INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD address_of_length.
    DATA(local_part) = repeat( val = `a`
                               occ = length - strlen( domain ) ).

    result = local_part && domain.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_building DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS sender TYPE string VALUE `noreply@example.com`.
    CONSTANTS recipient TYPE string VALUE `jane.doe@example.com`.
    CONSTANTS report_bytes TYPE xstring VALUE '255044462D'.

    DATA cut TYPE REF TO zif_email_builder.

    METHODS setup.
    METHODS teardown.

    METHODS given_all_parts_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_two_to_then_both_kept FOR TESTING RAISING cx_static_check.
    METHODS given_cc_only_then_builds FOR TESTING RAISING cx_static_check.
    METHODS given_bcc_only_then_builds FOR TESTING RAISING cx_static_check.
    METHODS given_2nd_subject_then_last FOR TESTING RAISING cx_static_check.
    METHODS given_max_subject_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_bin_attach_then_typed FOR TESTING RAISING cx_static_check.
    METHODS given_text_attach_then_typed FOR TESTING RAISING cx_static_check.
    METHODS given_own_type_then_kept FOR TESTING RAISING cx_static_check.
    METHODS given_built_then_detached FOR TESTING RAISING cx_static_check.
    METHODS given_no_sender_then_rejected FOR TESTING RAISING cx_static_check.
    METHODS given_no_recipient_rejected FOR TESTING RAISING cx_static_check.
    METHODS given_no_subject_then_rejected FOR TESTING RAISING cx_static_check.
    METHODS given_no_body_then_rejected FOR TESTING RAISING cx_static_check.
    METHODS given_empty_subject_then_raise FOR TESTING.
    METHODS given_long_subject_then_raise FOR TESTING.
    METHODS given_empty_text_then_raises FOR TESTING.
    METHODS given_empty_html_then_raises FOR TESTING.
    METHODS given_attach_no_name_raises FOR TESTING.
    METHODS given_attach_no_bytes_raises FOR TESTING.
    METHODS given_attach_no_text_raises FOR TESTING.
    METHODS given_long_mime_then_raises FOR TESTING.

    METHODS complete_draft
      RETURNING VALUE(result) TYPE REF TO zif_email_builder
      RAISING   zcx_email.

    METHODS assert_build_rejected
      IMPORTING reason TYPE string.

ENDCLASS.


CLASS ltc_building IMPLEMENTATION.

  METHOD setup.
    cut = zcl_email=>compose( ).
  ENDMETHOD.

  METHOD teardown.
    CLEAR cut.
  ENDMETHOD.

  METHOD complete_draft.
    result = cut->from( sender
      )->to( recipient
      )->subject( `Weekly report`
      )->text( `Please find the report attached.` ).
  ENDMETHOD.

  METHOD assert_build_rejected.
    TRY.
        cut->build( ).

        cl_abap_unit_assert=>fail( |{ reason } was unexpectedly accepted| ).
      CATCH zcx_email INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_all_parts_then_kept.
    DATA(message) = complete_draft(
      )->cc( `boss@example.com`
      )->bcc( `audit@example.com`
      )->html( `<p>Please find the report attached.</p>`
      )->attach( file_name = `report.pdf`
                 bytes     = report_bytes
      )->build( ).

    cl_abap_unit_assert=>assert_equals(
      act = message->from( )
      exp = sender
      msg = 'Sender is not kept' ).
    cl_abap_unit_assert=>assert_equals(
      act = message->to( )
      exp = VALUE zif_email_message=>address_table( ( recipient ) )
      msg = 'Primary recipient is not kept' ).
    cl_abap_unit_assert=>assert_equals(
      act = message->cc( )
      exp = VALUE zif_email_message=>address_table( ( `boss@example.com` ) )
      msg = 'Copy recipient is not kept' ).
    cl_abap_unit_assert=>assert_equals(
      act = message->bcc( )
      exp = VALUE zif_email_message=>address_table( ( `audit@example.com` ) )
      msg = 'Blind copy recipient is not kept' ).
    cl_abap_unit_assert=>assert_equals(
      act = message->subject( )
      exp = `Weekly report`
      msg = 'Subject is not kept' ).
    cl_abap_unit_assert=>assert_equals(
      act = message->text( )
      exp = `Please find the report attached.`
      msg = 'Text body is not kept' ).
    cl_abap_unit_assert=>assert_equals(
      act = message->html( )
      exp = `<p>Please find the report attached.</p>`
      msg = 'HTML body is not kept' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( message->attachments( ) )
      exp = 1
      msg = 'Attachment is not kept' ).
  ENDMETHOD.

  METHOD given_two_to_then_both_kept.
    DATA(message) = complete_draft( )->to( `john.doe@example.com` )->build( ).

    cl_abap_unit_assert=>assert_equals(
      act = message->to( )
      exp = VALUE zif_email_message=>address_table( ( recipient ) ( `john.doe@example.com` ) )
      msg = 'A second primary recipient replaces the first one instead of joining it' ).
  ENDMETHOD.

  METHOD given_cc_only_then_builds.
    DATA(message) = cut->from( sender
      )->cc( recipient
      )->subject( `Copy only`
      )->text( `Body`
      )->build( ).

    cl_abap_unit_assert=>assert_initial(
      act = message->to( )
      msg = 'A message with copy recipients only reports primary recipients' ).
  ENDMETHOD.

  METHOD given_bcc_only_then_builds.
    DATA(message) = cut->from( sender
      )->bcc( recipient
      )->subject( `Blind copy only`
      )->text( `Body`
      )->build( ).

    cl_abap_unit_assert=>assert_equals(
      act = message->bcc( )
      exp = VALUE zif_email_message=>address_table( ( recipient ) )
      msg = 'A message with blind copy recipients only cannot be built' ).
  ENDMETHOD.

  METHOD given_2nd_subject_then_last.
    DATA(message) = complete_draft( )->subject( `Corrected subject` )->build( ).

    cl_abap_unit_assert=>assert_equals(
      act = message->subject( )
      exp = `Corrected subject`
      msg = 'A second subject does not replace the first one' ).
  ENDMETHOD.

  METHOD given_max_subject_then_kept.
    DATA(long_subject) = repeat( val = `s`
                                 occ = 1024 ).

    DATA(message) = complete_draft( )->subject( long_subject )->build( ).

    cl_abap_unit_assert=>assert_equals(
      act = strlen( message->subject( ) )
      exp = 1024
      msg = 'A subject of exactly 1024 characters is not kept' ).
  ENDMETHOD.

  METHOD given_bin_attach_then_typed.
    DATA(message) = complete_draft(
      )->attach( file_name = `report.pdf`
                 bytes     = report_bytes
      )->build( ).

    DATA(attachments) = message->attachments( ).
    DATA(attachment) = attachments[ 1 ].

    cl_abap_unit_assert=>assert_equals(
      act = attachment-content_type
      exp = zcl_email=>content_type-binary
      msg = 'A binary attachment without MIME type does not default to octet-stream' ).
    cl_abap_unit_assert=>assert_false(
      act = attachment-is_text
      msg = 'A binary attachment is flagged as text' ).
    cl_abap_unit_assert=>assert_equals(
      act = attachment-bytes
      exp = report_bytes
      msg = 'Binary content is not kept' ).
  ENDMETHOD.

  METHOD given_text_attach_then_typed.
    DATA(message) = complete_draft(
      )->attach_text( file_name = `notes.txt`
                      text      = `Some notes`
      )->build( ).

    DATA(attachments) = message->attachments( ).
    DATA(attachment) = attachments[ 1 ].

    cl_abap_unit_assert=>assert_equals(
      act = attachment-content_type
      exp = zcl_email=>content_type-plain_text
      msg = 'A text attachment without MIME type does not default to text/plain' ).
    cl_abap_unit_assert=>assert_true(
      act = attachment-is_text
      msg = 'A text attachment is not flagged as text' ).
    cl_abap_unit_assert=>assert_equals(
      act = attachment-text
      exp = `Some notes`
      msg = 'Text content is not kept' ).
  ENDMETHOD.

  METHOD given_own_type_then_kept.
    DATA(message) = complete_draft(
      )->attach_text( file_name    = `data.csv`
                      text         = `id,name`
                      content_type = zcl_email=>content_type-csv
      )->build( ).

    DATA(attachments) = message->attachments( ).

    cl_abap_unit_assert=>assert_equals(
      act = attachments[ 1 ]-content_type
      exp = zcl_email=>content_type-csv
      msg = 'An explicit MIME type is overwritten by the default' ).
  ENDMETHOD.

  METHOD given_built_then_detached.
    DATA(message) = complete_draft( )->build( ).

    cut->to( `late@example.com` ).

    cl_abap_unit_assert=>assert_equals(
      act = lines( message->to( ) )
      exp = 1
      msg = 'A recipient added after build leaks into the built message' ).
  ENDMETHOD.

  METHOD given_no_sender_then_rejected.
    cut->to( recipient )->subject( `No sender` )->text( `Body` ).

    assert_build_rejected( `A message without sender` ).
  ENDMETHOD.

  METHOD given_no_recipient_rejected.
    cut->from( sender )->subject( `No recipient` )->text( `Body` ).

    assert_build_rejected( `A message without recipient` ).
  ENDMETHOD.

  METHOD given_no_subject_then_rejected.
    cut->from( sender )->to( recipient )->text( `Body` ).

    assert_build_rejected( `A message without subject` ).
  ENDMETHOD.

  METHOD given_no_body_then_rejected.
    cut->from( sender )->to( recipient )->subject( `No body` ).

    assert_build_rejected( `A message without body` ).
  ENDMETHOD.

  METHOD given_empty_subject_then_raise.
    TRY.
        cut->subject( `` ).

        cl_abap_unit_assert=>fail( 'An empty subject was unexpectedly accepted' ).
      CATCH zcx_email INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_long_subject_then_raise.
    DATA(long_subject) = repeat( val = `s`
                                 occ = 1025 ).

    TRY.
        cut->subject( long_subject ).

        cl_abap_unit_assert=>fail( 'A subject of 1025 characters was unexpectedly accepted' ).
      CATCH zcx_email INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_empty_text_then_raises.
    TRY.
        cut->text( `` ).

        cl_abap_unit_assert=>fail( 'An empty text body was unexpectedly accepted' ).
      CATCH zcx_email INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_empty_html_then_raises.
    TRY.
        cut->html( `` ).

        cl_abap_unit_assert=>fail( 'An empty HTML body was unexpectedly accepted' ).
      CATCH zcx_email INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_attach_no_name_raises.
    TRY.
        cut->attach( file_name = ` `
                     bytes     = report_bytes ).

        cl_abap_unit_assert=>fail( 'An attachment without file name was unexpectedly accepted' ).
      CATCH zcx_email INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_attach_no_bytes_raises.
    TRY.
        cut->attach( file_name = `empty.pdf`
                     bytes     = VALUE #( ) ).

        cl_abap_unit_assert=>fail( 'An empty binary attachment was unexpectedly accepted' ).
      CATCH zcx_email INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_attach_no_text_raises.
    TRY.
        cut->attach_text( file_name = `empty.txt`
                          text      = `` ).

        cl_abap_unit_assert=>fail( 'An empty text attachment was unexpectedly accepted' ).
      CATCH zcx_email INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_long_mime_then_raises.
    DATA(long_mime_type) = repeat( val = `m`
                                   occ = 129 ).

    TRY.
        cut->attach_text( file_name    = `notes.txt`
                          text         = `Some notes`
                          content_type = long_mime_type ).

        cl_abap_unit_assert=>fail( 'A MIME type of 129 characters was unexpectedly accepted' ).
      CATCH zcx_email INTO DATA(rejection).
        cl_abap_unit_assert=>assert_not_initial( act = rejection->get_text( )
                                                 msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


"! Records every call the sender makes on the mail system seam instead of
"! sending anything.
CLASS ltd_bcs_mail DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PUBLIC SECTION.
    INTERFACES lif_bcs_mail.

    TYPES:
      BEGIN OF recording,
        opened      TYPE i,
        sender      TYPE string,
        to          TYPE zif_email_message=>address_table,
        cc          TYPE zif_email_message=>address_table,
        bcc         TYPE zif_email_message=>address_table,
        subject     TYPE string,
        main_text   TYPE string,
        main_html   TYPE string,
        alternative TYPE string,
        attachments TYPE zif_email_message=>attachment_table,
        sent        TYPE abap_bool,
      END OF recording.

    METHODS constructor
      IMPORTING delivery TYPE zif_email_sender=>delivery OPTIONAL
                failure  TYPE REF TO cx_bcs_mail OPTIONAL.

    METHODS recorded
      RETURNING VALUE(result) TYPE recording.

  PRIVATE SECTION.
    DATA log TYPE recording.
    DATA delivery TYPE zif_email_sender=>delivery.
    DATA failure TYPE REF TO cx_bcs_mail.

ENDCLASS.


CLASS ltd_bcs_mail IMPLEMENTATION.

  METHOD constructor.
    me->delivery = delivery.
    me->failure = failure.
  ENDMETHOD.

  METHOD recorded.
    result = log.
  ENDMETHOD.

  METHOD lif_bcs_mail~open.
    DATA(opened) = log-opened + 1.

    CLEAR log.
    log-opened = opened.
  ENDMETHOD.

  METHOD lif_bcs_mail~set_sender.
    log-sender = address.
  ENDMETHOD.

  METHOD lif_bcs_mail~add_to.
    INSERT address INTO TABLE log-to.
  ENDMETHOD.

  METHOD lif_bcs_mail~add_cc.
    INSERT address INTO TABLE log-cc.
  ENDMETHOD.

  METHOD lif_bcs_mail~add_bcc.
    INSERT address INTO TABLE log-bcc.
  ENDMETHOD.

  METHOD lif_bcs_mail~set_subject.
    log-subject = subject.
  ENDMETHOD.

  METHOD lif_bcs_mail~set_main_text.
    log-main_text = text.
  ENDMETHOD.

  METHOD lif_bcs_mail~set_main_html.
    log-main_html = html.
  ENDMETHOD.

  METHOD lif_bcs_mail~add_alternative_text.
    log-alternative = text.
  ENDMETHOD.

  METHOD lif_bcs_mail~attach.
    INSERT attachment INTO TABLE log-attachments.
  ENDMETHOD.

  METHOD lif_bcs_mail~send.
    IF failure IS BOUND.
      RAISE EXCEPTION failure.
    ENDIF.

    log-sent = abap_true.
    result = delivery.
  ENDMETHOD.

ENDCLASS.


CLASS ltc_sending DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CONSTANTS sender TYPE string VALUE `noreply@example.com`.
    CONSTANTS recipient TYPE string VALUE `jane.doe@example.com`.
    CONSTANTS report_bytes TYPE xstring VALUE '255044462D'.
    CONSTANTS mail_id TYPE zif_email_sender=>delivery-mail_id VALUE 'A1B2C3D4E5F60718293A4B5C6D7E8F90'.

    DATA bcs TYPE REF TO ltd_bcs_mail.
    DATA cut TYPE REF TO zif_email_sender.

    METHODS setup.
    METHODS teardown.

    METHODS given_message_then_sender_set FOR TESTING RAISING cx_static_check.
    METHODS given_recipients_then_mapped FOR TESTING RAISING cx_static_check.
    METHODS given_subject_then_passed FOR TESTING RAISING cx_static_check.
    METHODS given_text_only_then_main_text FOR TESTING RAISING cx_static_check.
    METHODS given_html_only_then_main_html FOR TESTING RAISING cx_static_check.
    METHODS given_both_then_html_plus_alt FOR TESTING RAISING cx_static_check.
    METHODS given_attachments_then_passed FOR TESTING RAISING cx_static_check.
    METHODS given_sent_then_delivery_back FOR TESTING RAISING cx_static_check.
    METHODS given_two_sends_then_two_mails FOR TESTING RAISING cx_static_check.
    METHODS given_bcs_failure_then_wrapped FOR TESTING RAISING cx_static_check.
    METHODS given_facade_then_sender_bound FOR TESTING.

    METHODS text_message
      RETURNING VALUE(result) TYPE REF TO zif_email_builder
      RAISING   zcx_email.

ENDCLASS.


CLASS ltc_sending IMPLEMENTATION.

  METHOD setup.
    bcs = NEW ltd_bcs_mail( delivery = VALUE #( mail_id    = mail_id
                                                status     = 'S'
                                                recipients = VALUE #( ( address = recipient
                                                                        status  = 'S' ) ) ) ).
    cut = NEW lcl_sender( bcs ).
  ENDMETHOD.

  METHOD teardown.
    CLEAR cut.
    CLEAR bcs.
  ENDMETHOD.

  METHOD text_message.
    result = zcl_email=>compose(
      )->from( sender
      )->to( recipient
      )->subject( `Weekly report`
      )->text( `Please find the report attached.` ).
  ENDMETHOD.

  METHOD given_message_then_sender_set.
    cut->send( text_message( )->build( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = bcs->recorded( )-sender
      exp = sender
      msg = 'Sender address is not handed to the mail system' ).
  ENDMETHOD.

  METHOD given_recipients_then_mapped.
    DATA(message) = text_message(
      )->to( `john.doe@example.com`
      )->cc( `boss@example.com`
      )->bcc( `audit@example.com`
      )->build( ).

    cut->send( message ).

    DATA(recorded) = bcs->recorded( ).

    cl_abap_unit_assert=>assert_equals(
      act = recorded-to
      exp = VALUE zif_email_message=>address_table( ( recipient ) ( `john.doe@example.com` ) )
      msg = 'Primary recipients are not mapped to the To line' ).
    cl_abap_unit_assert=>assert_equals(
      act = recorded-cc
      exp = VALUE zif_email_message=>address_table( ( `boss@example.com` ) )
      msg = 'Copy recipients are not mapped to the Cc line' ).
    cl_abap_unit_assert=>assert_equals(
      act = recorded-bcc
      exp = VALUE zif_email_message=>address_table( ( `audit@example.com` ) )
      msg = 'Blind copy recipients are not mapped to the Bcc line' ).
  ENDMETHOD.

  METHOD given_subject_then_passed.
    cut->send( text_message( )->build( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = bcs->recorded( )-subject
      exp = `Weekly report`
      msg = 'Subject is not handed to the mail system' ).
  ENDMETHOD.

  METHOD given_text_only_then_main_text.
    cut->send( text_message( )->build( ) ).

    DATA(recorded) = bcs->recorded( ).

    cl_abap_unit_assert=>assert_equals(
      act = recorded-main_text
      exp = `Please find the report attached.`
      msg = 'Plain text is not the main body of a text only message' ).
    cl_abap_unit_assert=>assert_initial(
      act = recorded-main_html
      msg = 'A text only message carries an HTML body' ).
    cl_abap_unit_assert=>assert_initial(
      act = recorded-alternative
      msg = 'A text only message carries an alternative body' ).
  ENDMETHOD.

  METHOD given_html_only_then_main_html.
    DATA(message) = zcl_email=>compose(
      )->from( sender
      )->to( recipient
      )->subject( `HTML only`
      )->html( `<p>Hello</p>`
      )->build( ).

    cut->send( message ).

    DATA(recorded) = bcs->recorded( ).

    cl_abap_unit_assert=>assert_equals(
      act = recorded-main_html
      exp = `<p>Hello</p>`
      msg = 'HTML is not the main body of an HTML only message' ).
    cl_abap_unit_assert=>assert_initial(
      act = recorded-main_text
      msg = 'An HTML only message carries a plain text main body' ).
    cl_abap_unit_assert=>assert_initial(
      act = recorded-alternative
      msg = 'An HTML only message carries an alternative body' ).
  ENDMETHOD.

  METHOD given_both_then_html_plus_alt.
    DATA(message) = text_message( )->html( `<p>Please find the report attached.</p>` )->build( ).

    cut->send( message ).

    DATA(recorded) = bcs->recorded( ).

    cl_abap_unit_assert=>assert_equals(
      act = recorded-main_html
      exp = `<p>Please find the report attached.</p>`
      msg = 'HTML is not the main body when both bodies are set' ).
    cl_abap_unit_assert=>assert_equals(
      act = recorded-alternative
      exp = `Please find the report attached.`
      msg = 'Plain text is not the alternative when both bodies are set' ).
    cl_abap_unit_assert=>assert_initial(
      act = recorded-main_text
      msg = 'Plain text is set as main body although HTML is present' ).
  ENDMETHOD.

  METHOD given_attachments_then_passed.
    DATA(message) = text_message(
      )->attach( file_name = `report.pdf`
                 bytes     = report_bytes
      )->attach_text( file_name = `notes.txt`
                      text      = `Some notes`
      )->build( ).

    cut->send( message ).

    DATA(attachments) = bcs->recorded( )-attachments.

    cl_abap_unit_assert=>assert_equals(
      act = lines( attachments )
      exp = 2
      msg = 'Not every attachment reaches the mail system' ).
    cl_abap_unit_assert=>assert_equals(
      act = attachments[ 1 ]-file_name
      exp = `report.pdf`
      msg = 'Attachments do not keep their order' ).
    cl_abap_unit_assert=>assert_true(
      act = attachments[ 2 ]-is_text
      msg = 'The text attachment loses its text flag on the way' ).
  ENDMETHOD.

  METHOD given_sent_then_delivery_back.
    DATA(delivery) = cut->send( text_message( )->build( ) ).

    cl_abap_unit_assert=>assert_true(
      act = bcs->recorded( )-sent
      msg = 'The mail system was never asked to send' ).
    cl_abap_unit_assert=>assert_equals(
      act = delivery-mail_id
      exp = mail_id
      msg = 'The mail id of the mail system is not passed back' ).
    cl_abap_unit_assert=>assert_equals(
      act = delivery-recipients[ 1 ]-address
      exp = recipient
      msg = 'The recipient status of the mail system is not passed back' ).
  ENDMETHOD.

  METHOD given_two_sends_then_two_mails.
    DATA(message) = text_message( )->build( ).

    cut->send( message ).
    cut->send( message ).

    DATA(recorded) = bcs->recorded( ).

    cl_abap_unit_assert=>assert_equals(
      act = recorded-opened
      exp = 2
      msg = 'A second send does not open a fresh mail' ).
    cl_abap_unit_assert=>assert_equals(
      act = lines( recorded-to )
      exp = 1
      msg = 'Recipients of the first send leak into the second mail' ).
  ENDMETHOD.

  METHOD given_bcs_failure_then_wrapped.
    DATA(failure) = NEW cx_bcs_mail( textid = cx_bcs_mail=>send_error ).
    DATA(failing_cut) = CAST zif_email_sender( NEW lcl_sender( NEW ltd_bcs_mail( failure = failure ) ) ).

    TRY.
        failing_cut->send( text_message( )->build( ) ).

        cl_abap_unit_assert=>fail( 'A failure of the mail system was swallowed' ).
      CATCH zcx_email INTO DATA(rejection).
        cl_abap_unit_assert=>assert_equals(
          act = rejection->previous
          exp = failure
          msg = 'The original mail system exception is not kept as previous' ).
        cl_abap_unit_assert=>assert_not_initial(
          act = rejection->get_text( )
          msg = 'The rejection does not explain itself' ).
    ENDTRY.
  ENDMETHOD.

  METHOD given_facade_then_sender_bound.
    cl_abap_unit_assert=>assert_bound(
      act = zcl_email=>sender( )
      msg = 'The facade does not hand out a sender' ).
  ENDMETHOD.

ENDCLASS.
