" ZIF_TIMESTAMP_LOCAL
"! <p class="shorttext synchronized" lang="EN">Point in time in a time zone</p>
"! A point in time read on the wall clock of one time zone: the date, the time
"! of day, the daylight saving state and the offset from UTC that the zone
"! showed at that moment. Immutable; created through
"! {@link zif_timestamp.METH:in_zone}.
INTERFACE zif_timestamp_local
  PUBLIC.

  "! Time zone the wall clock belongs to, as it is known to the system.
  "! @parameter result | Time zone key, for example CET
  METHODS zone
    RETURNING VALUE(result) TYPE string.

  "! Calendar date shown by the wall clock.
  "! @parameter result | Date as YYYYMMDD
  METHODS date
    RETURNING VALUE(result) TYPE d.

  "! Time of day shown by the wall clock, in whole seconds.
  "! @parameter result | Time as hhmmss
  METHODS time
    RETURNING VALUE(result) TYPE t.

  "! Tests whether daylight saving time was in force in the zone at that moment.
  "! @parameter result | abap_true during daylight saving time
  METHODS is_daylight_saving
    RETURNING VALUE(result) TYPE abap_bool.

  "! Offset of the wall clock from UTC at that moment, positive east of
  "! Greenwich.
  "! @parameter result | Offset in seconds, for example 7200 for CET in summer
  METHODS utc_offset_seconds
    RETURNING VALUE(result) TYPE i.

  "! The point in time as an RFC 3339 text with the offset of the zone, for
  "! example 2026-09-15T16:30:00+02:00. A fraction of a second is written only
  "! when there is one and without trailing zeros; an offset of zero is
  "! written as Z. The text is accepted again by
  "! {@link zcl_timestamp.METH:for_iso}.
  "! @parameter result | Text as YYYY-MM-DDThh:mm:ss[.fffffff](Z|+hh:mm|-hh:mm)
  METHODS as_iso
    RETURNING VALUE(result) TYPE string.

  "! First point in time of the calendar day, 00:00:00 on the wall clock.
  "! @parameter result | Point in time at which the day starts in the zone
  "! @raising zcx_timestamp | The day has no midnight in the zone because a
  "!                          daylight saving switch skips it, or the result
  "!                          leaves the time line
  METHODS start_of_day
    RETURNING VALUE(result) TYPE REF TO zif_timestamp
    RAISING   zcx_timestamp.

  "! Last point in time of the calendar day, 23:59:59.9999999 on the wall
  "! clock - the upper border for a BETWEEN selection on time stamp fields.
  "! @parameter result | Point in time at which the day ends in the zone
  "! @raising zcx_timestamp | The day has no 23:59:59 in the zone because a
  "!                          daylight saving switch skips it, or the result
  "!                          leaves the time line
  METHODS end_of_day
    RETURNING VALUE(result) TYPE REF TO zif_timestamp
    RAISING   zcx_timestamp.

ENDINTERFACE.
