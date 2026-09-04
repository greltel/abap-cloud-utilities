"! <p class="shorttext synchronized" lang="EN">Email builder</p>
"! Assembles an email step by step. Every method validates its own argument
"! and returns the same instance, so the calls can be chained;
"! {@link zif_email_builder.METH:build} checks the message as a whole and
"! closes the chain. Setters replace an earlier value, adders accumulate.
INTERFACE zif_email_builder
  PUBLIC.

  "! Sets the sender address.
  "! @parameter address   | Sender address, leading and trailing blanks are removed
  "! @parameter self      | Same instance, for chaining
  "! @raising   zcx_email | The address is malformed
  METHODS from
    IMPORTING address     TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_email_builder
    RAISING   zcx_email.

  "! Adds a primary recipient.
  "! @parameter address   | Recipient address, leading and trailing blanks are removed
  "! @parameter self      | Same instance, for chaining
  "! @raising   zcx_email | The address is malformed
  METHODS to
    IMPORTING address     TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_email_builder
    RAISING   zcx_email.

  "! Adds a copy recipient.
  "! @parameter address   | Recipient address, leading and trailing blanks are removed
  "! @parameter self      | Same instance, for chaining
  "! @raising   zcx_email | The address is malformed
  METHODS cc
    IMPORTING address     TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_email_builder
    RAISING   zcx_email.

  "! Adds a blind copy recipient.
  "! @parameter address   | Recipient address, leading and trailing blanks are removed
  "! @parameter self      | Same instance, for chaining
  "! @raising   zcx_email | The address is malformed
  METHODS bcc
    IMPORTING address     TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_email_builder
    RAISING   zcx_email.

  "! Sets the subject line.
  "! @parameter text      | Subject, at most 1024 characters
  "! @parameter self      | Same instance, for chaining
  "! @raising   zcx_email | The subject is empty or too long
  METHODS subject
    IMPORTING text        TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_email_builder
    RAISING   zcx_email.

  "! Sets the plain text body. When an HTML body is set as well, the plain
  "! text travels as the alternative for clients that cannot render HTML.
  "! @parameter body      | Plain text
  "! @parameter self      | Same instance, for chaining
  "! @raising   zcx_email | The body is empty
  METHODS text
    IMPORTING body        TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_email_builder
    RAISING   zcx_email.

  "! Sets the HTML body.
  "! @parameter body      | HTML
  "! @parameter self      | Same instance, for chaining
  "! @raising   zcx_email | The body is empty
  METHODS html
    IMPORTING body        TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_email_builder
    RAISING   zcx_email.

  "! Adds a binary attachment.
  "! @parameter file_name    | Name the recipient sees, including the extension
  "! @parameter bytes        | Content
  "! @parameter content_type | MIME type, application/octet-stream when left empty
  "! @parameter self         | Same instance, for chaining
  "! @raising   zcx_email    | The file name or the content is empty, or the MIME type is too long
  METHODS attach
    IMPORTING file_name    TYPE string
              bytes        TYPE xstring
              content_type TYPE string OPTIONAL
    RETURNING VALUE(self)  TYPE REF TO zif_email_builder
    RAISING   zcx_email.

  "! Adds a text attachment. The mail system takes care of the character encoding.
  "! @parameter file_name    | Name the recipient sees, including the extension
  "! @parameter text         | Content
  "! @parameter content_type | MIME type, text/plain when left empty
  "! @parameter self         | Same instance, for chaining
  "! @raising   zcx_email    | The file name or the content is empty, or the MIME type is too long
  METHODS attach_text
    IMPORTING file_name    TYPE string
              text         TYPE string
              content_type TYPE string OPTIONAL
    RETURNING VALUE(self)  TYPE REF TO zif_email_builder
    RAISING   zcx_email.

  "! Checks the message as a whole and closes the chain. The builder stays
  "! usable afterwards; the message it handed out is not affected by later calls.
  "! @parameter result    | Immutable message, ready to be sent
  "! @raising   zcx_email | Sender, recipient, subject or body is missing
  METHODS build
    RETURNING VALUE(result) TYPE REF TO zif_email_message
    RAISING   zcx_email.

ENDINTERFACE.
