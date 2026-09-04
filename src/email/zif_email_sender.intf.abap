"! <p class="shorttext synchronized" lang="EN">Email sender</p>
"! Hands a message to the mail system. Consumers inject this interface and
"! replace it with a test double in their unit tests, so no test ever sends
"! a real email.
INTERFACE zif_email_sender
  PUBLIC.

  TYPES:
    "! Status of one recipient as reported by the mail system.
    BEGIN OF recipient_status,
      address TYPE string,
      status  TYPE c LENGTH 1,
    END OF recipient_status.

  "! Status of every recipient, in the order reported by the mail system.
  TYPES recipient_status_table TYPE STANDARD TABLE OF recipient_status WITH EMPTY KEY.

  TYPES:
    "! Outcome of a send. The status codes are passed through from the mail
    "! system unchanged.
    BEGIN OF delivery,
      mail_id    TYPE x LENGTH 16,
      status     TYPE c LENGTH 1,
      recipients TYPE recipient_status_table,
    END OF delivery.

  "! Sends the message. The method does not commit, the calling unit of work does.
  "! @parameter message   | Message to send
  "! @parameter result    | Identifier and status of the send request
  "! @raising   zcx_email | The mail system rejected the message
  METHODS send
    IMPORTING message       TYPE REF TO zif_email_message
    RETURNING VALUE(result) TYPE delivery
    RAISING   zcx_email.

ENDINTERFACE.
