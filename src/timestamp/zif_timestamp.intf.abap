" ZIF_TIMESTAMP
"! <p class="shorttext synchronized" lang="EN">Point in time</p>
"! Immutable point in time on the UTC time line, held as utclong with a
"! precision of 100 nanoseconds. Every method either answers a question about
"! the point in time or returns a new one - the instance itself never changes.
"! The value is the only state, so nothing here reads the system context;
"! instances are created through {@link zcl_timestamp}.
"! <p>A point in time has no date and no time of day of its own - both depend
"! on a time zone and are read through {@link zif_timestamp.METH:in_zone}.</p>
INTERFACE zif_timestamp
  PUBLIC.

  "! The point in time as utclong, the type of the time stamp fields in ABAP
  "! Cloud tables and CDS view entities.
  "! @parameter result | Point in time on the UTC time line
  METHODS as_utclong
    RETURNING VALUE(result) TYPE utclong.

  "! The point in time as a long UTC time stamp of the classic packed type,
  "! YYYYMMDDhhmmss.fffffff, the way TIMESTAMPL fields store it.
  "! @parameter result | UTC time stamp with seven decimals
  METHODS as_timestamp
    RETURNING VALUE(result) TYPE timestampl.

  "! The point in time as a short UTC time stamp of the classic packed type,
  "! YYYYMMDDhhmmss. The fraction of the second is dropped, never rounded, so
  "! the result never lies after the point in time.
  "! @parameter result | UTC time stamp in whole seconds
  METHODS as_short_timestamp
    RETURNING VALUE(result) TYPE timestamp.

  "! Seconds since 1970-01-01T00:00:00Z - the Unix time of JSON payloads and
  "! token claims. A fraction of a second is dropped towards the past, so a
  "! point in time before the epoch falls back to the earlier second.
  "! @parameter result | Unix time in whole seconds, negative before 1970
  METHODS as_unix_seconds
    RETURNING VALUE(result) TYPE int8.

  "! The point in time as an RFC 3339 text in UTC, for example
  "! 2026-09-15T14:30:00Z. A fraction of a second is written only when there
  "! is one and without trailing zeros: 2026-09-15T14:30:00.25Z. The text is
  "! accepted again by {@link zcl_timestamp.METH:for_iso}.
  "! @parameter result | Text as YYYY-MM-DDThh:mm:ss[.fffffff]Z
  METHODS as_iso
    RETURNING VALUE(result) TYPE string.

  "! Reads the point in time on the wall clock of a time zone: date, time of
  "! day, daylight saving state, offset from UTC, and the borders of that day.
  "! @parameter zone   | Time zone as maintained in the system, for example CET or UTC;
  "!                     case and surrounding blanks do not matter
  "! @parameter result | The same point in time, seen from that time zone
  "! @raising zcx_timestamp | The time zone is not known to the system
  METHODS in_zone
    IMPORTING zone          TYPE csequence
    RETURNING VALUE(result) TYPE REF TO zif_timestamp_local
    RAISING   zcx_timestamp.

  "! Drops the fraction of the second.
  "! @parameter result | New point in time on the whole second, never later than this one
  METHODS truncate_to_seconds
    RETURNING VALUE(result) TYPE REF TO zif_timestamp.

  "! Moves the point in time by whole seconds; the fraction of the second is kept.
  "! @parameter seconds | Seconds to move, negative to move into the past
  "! @parameter result  | New point in time, this many seconds away
  "! @raising zcx_timestamp | The result leaves the time line, years 1 to 9999
  METHODS add_seconds
    IMPORTING seconds       TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_timestamp
    RAISING   zcx_timestamp.

  "! Moves the point in time by whole minutes.
  "! @parameter minutes | Minutes to move, negative to move into the past
  "! @parameter result  | New point in time, this many minutes away
  "! @raising zcx_timestamp | The result leaves the time line, years 1 to 9999
  METHODS add_minutes
    IMPORTING minutes       TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_timestamp
    RAISING   zcx_timestamp.

  "! Moves the point in time by whole hours.
  "! @parameter hours  | Hours to move, negative to move into the past
  "! @parameter result | New point in time, this many hours away
  "! @raising zcx_timestamp | The result leaves the time line, years 1 to 9999
  METHODS add_hours
    IMPORTING hours         TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_timestamp
    RAISING   zcx_timestamp.

  "! Moves the point in time by periods of exactly 24 hours. That is not a
  "! calendar day in a time zone: across a daylight saving switch the wall
  "! clock of the result differs by one hour. For calendar days read the date
  "! through {@link zif_timestamp.METH:in_zone} and go back through
  "! {@link zcl_timestamp.METH:for_date_time}.
  "! @parameter days   | Periods of 24 hours to move, negative to move into the past
  "! @parameter result | New point in time, this many periods away
  "! @raising zcx_timestamp | The result leaves the time line, years 1 to 9999
  METHODS add_days
    IMPORTING days          TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_timestamp
    RAISING   zcx_timestamp.

  "! Seconds from this point in time to another one, fraction included.
  "! @parameter other  | Point in time to measure against
  "! @parameter result | Seconds, negative when other lies in the past
  "! @raising zcx_timestamp | other is initial and therefore not a point in time
  METHODS seconds_until
    IMPORTING other         TYPE utclong
    RETURNING VALUE(result) TYPE decfloat34
    RAISING   zcx_timestamp.

  "! Tests whether both describe the same point in time, to the 100 nanoseconds.
  "! @parameter other  | Point in time to compare with
  "! @parameter result | abap_true when both are the same point in time
  METHODS equals
    IMPORTING other         TYPE utclong
    RETURNING VALUE(result) TYPE abap_bool.

  "! Tests whether the point in time lies strictly before another one.
  "! @parameter other  | Point in time to compare with
  "! @parameter result | abap_true when this one is earlier
  METHODS is_before
    IMPORTING other         TYPE utclong
    RETURNING VALUE(result) TYPE abap_bool.

  "! Tests whether the point in time lies strictly after another one.
  "! @parameter other  | Point in time to compare with
  "! @parameter result | abap_true when this one is later
  METHODS is_after
    IMPORTING other         TYPE utclong
    RETURNING VALUE(result) TYPE abap_bool.

  "! Tests whether the point in time lies inside the given period, borders
  "! included.
  "! @parameter time_from | Start of the period
  "! @parameter time_to   | End of the period
  "! @parameter result    | abap_true when the point in time lies inside the period
  METHODS is_between
    IMPORTING time_from     TYPE utclong
              time_to       TYPE utclong
    RETURNING VALUE(result) TYPE abap_bool.

ENDINTERFACE.
