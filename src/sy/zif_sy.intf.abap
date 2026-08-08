"! <p class="shorttext synchronized" lang="EN">ABAP Cloud safe replacement for SY</p>
"! Read-only access to the runtime context that classic ABAP exposes through the
"! structure <em>sy</em>. Every value comes from a released API or from a system field
"! that stays readable in ABAP for Cloud Development, so consuming code never reads
"! <em>sy</em> itself and can be unit tested with a test double of this interface.
INTERFACE zif_sy
  PUBLIC.

  "! Technical user name, mirrors <em>sy-uname</em>
  TYPES ty_user_name TYPE c LENGTH 12.
  "! Logon language in the one character SAP format, mirrors <em>sy-langu</em>
  TYPES ty_language  TYPE c LENGTH 1.
  "! Time zone of the current user, mirrors <em>sy-zonlo</em>
  TYPES ty_time_zone TYPE c LENGTH 6.
  "! Client of the current session, mirrors <em>sy-mandt</em>
  TYPES ty_client    TYPE c LENGTH 3.
  "! Identifier of the system, mirrors <em>sy-sysid</em>
  TYPES ty_system_id TYPE c LENGTH 8.

  TYPES: BEGIN OF ty_message,
           id         TYPE c LENGTH 20,
           number     TYPE n LENGTH 3,
           type       TYPE c LENGTH 1,
           variable_1 TYPE c LENGTH 50,
           variable_2 TYPE c LENGTH 50,
           variable_3 TYPE c LENGTH 50,
           variable_4 TYPE c LENGTH 50,
         END OF ty_message.

  "! Technical name of the user the current session runs under.
  "! @parameter result | Equivalent of <em>sy-uname</em>
  METHODS user_name
    RETURNING VALUE(result) TYPE ty_user_name.

  "! Logon language of the current user.
  "! @parameter result | Equivalent of <em>sy-langu</em>
  METHODS language
    RETURNING VALUE(result) TYPE ty_language.

  "! Time zone maintained for the current user.
  "! @parameter result | Equivalent of <em>sy-zonlo</em>
  METHODS time_zone
    RETURNING VALUE(result) TYPE ty_time_zone.

  "! Current system date, related to UTC.
  "! @parameter result | Equivalent of <em>sy-datum</em>
  METHODS system_date
    RETURNING VALUE(result) TYPE d.

  "! Current system time, related to UTC.
  "! @parameter result | Equivalent of <em>sy-uzeit</em>
  METHODS system_time
    RETURNING VALUE(result) TYPE t.

  "! Current date in the time zone of the user.
  "! @parameter result | Equivalent of <em>sy-datlo</em>
  METHODS user_date
    RETURNING VALUE(result) TYPE d.

  "! Current time in the time zone of the user.
  "! @parameter result | Equivalent of <em>sy-timlo</em>
  METHODS user_time
    RETURNING VALUE(result) TYPE t.

  "! Current UTC time stamp. Preferred over the date and time pair for persistence.
  "! @parameter result | Moment the method was called
  METHODS timestamp
    RETURNING VALUE(result) TYPE utclong.

  "! Client the current session is logged on to.
  "! @parameter result | Equivalent of <em>sy-mandt</em>
  METHODS client
    RETURNING VALUE(result) TYPE ty_client.

  "! Identifier of the system the code runs on.
  "! @parameter result | Equivalent of <em>sy-sysid</em>
  METHODS system_id
    RETURNING VALUE(result) TYPE ty_system_id.

  "! Return code of the statement executed directly before this call.
  "! @parameter result | Equivalent of <em>sy-subrc</em>
  METHODS subrc
    RETURNING VALUE(result) TYPE i.

  "! Number of rows touched by the database statement executed before this call.
  "! @parameter result | Equivalent of <em>sy-dbcnt</em>
  METHODS db_count
    RETURNING VALUE(result) TYPE i.

  "! Tells whether the current session runs in background processing.
  "! @parameter result | abap_true when <em>sy-batch</em> is set
  METHODS is_batch
    RETURNING VALUE(result) TYPE abap_bool.

  "! Message fields filled by the statement executed before this call.
  "! @parameter result | Equivalent of the <em>sy-msg</em> fields
  METHODS message
    RETURNING VALUE(result) TYPE ty_message.

ENDINTERFACE.
