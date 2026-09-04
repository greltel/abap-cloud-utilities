"! <p class="shorttext synchronized" lang="EN">Email message</p>
"! Immutable email as assembled by {@link zif_email_builder} and consumed by
"! {@link zif_email_sender}. Every accessor hands out a copy, so a message
"! cannot change once it has been built.
INTERFACE zif_email_message
  PUBLIC.

  "! Email addresses in the order they were added.
  TYPES address_table TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  TYPES:
    "! One attachment. A text attachment carries its content in text, a binary
    "! one in bytes; is_text tells which of the two applies.
    BEGIN OF attachment,
      file_name    TYPE string,
      content_type TYPE string,
      is_text      TYPE abap_bool,
      text         TYPE string,
      bytes        TYPE xstring,
    END OF attachment.

  "! Attachments in the order they were added.
  TYPES attachment_table TYPE STANDARD TABLE OF attachment WITH EMPTY KEY.

  "! Address the message is sent from.
  "! @parameter result | Sender address
  METHODS from
    RETURNING VALUE(result) TYPE string.

  "! Primary recipients.
  "! @parameter result | Addresses on the To line
  METHODS to
    RETURNING VALUE(result) TYPE address_table.

  "! Copy recipients.
  "! @parameter result | Addresses on the Cc line
  METHODS cc
    RETURNING VALUE(result) TYPE address_table.

  "! Blind copy recipients.
  "! @parameter result | Addresses on the Bcc line, invisible to the other recipients
  METHODS bcc
    RETURNING VALUE(result) TYPE address_table.

  "! Subject line.
  "! @parameter result | Subject
  METHODS subject
    RETURNING VALUE(result) TYPE string.

  "! Plain text body.
  "! @parameter result | Plain text, empty when the message carries only HTML
  METHODS text
    RETURNING VALUE(result) TYPE string.

  "! HTML body.
  "! @parameter result | HTML, empty when the message carries only plain text
  METHODS html
    RETURNING VALUE(result) TYPE string.

  "! Attachments.
  "! @parameter result | Attachments in the order they were added, may be empty
  METHODS attachments
    RETURNING VALUE(result) TYPE attachment_table.

ENDINTERFACE.
