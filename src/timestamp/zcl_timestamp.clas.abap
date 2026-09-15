" ZCL_TIMESTAMP
"! <p class="shorttext synchronized" lang="EN">Time stamp utility</p>
"! Entry point for points in time on top of utclong and the kernel time zone
"! conversions. Standalone - depends on nothing but SAP released APIs.
"! <p>The utility never reads the system context. A point in time always
"! enters through one of the factory methods, so the caller decides where
"! "now" comes from - utclong_current( ) at the composition root - and every
"! calculation stays reproducible in a test.</p>
CLASS zcl_timestamp DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Opens a utclong value for calculation.
    "! @parameter instant | Point in time as utclong, for example a table field or utclong_current( )
    "! @parameter result  | The point in time, ready for calculation
    "! @raising   zcx_timestamp | The value is initial and therefore not a point in time
    CLASS-METHODS for_utclong
      IMPORTING instant       TYPE utclong
      RETURNING VALUE(result) TYPE REF TO zif_timestamp
      RAISING   zcx_timestamp.

    "! Opens a long classic UTC time stamp, TIMESTAMPL, for calculation. The
    "! seven decimals are kept. For the short form see
    "! {@link zcl_timestamp.METH:for_short_timestamp}.
    "! @parameter stamp  | UTC time stamp as YYYYMMDDhhmmss.fffffff
    "! @parameter result | The point in time, ready for calculation
    "! @raising   zcx_timestamp | The value is not a UTC time stamp
    CLASS-METHODS for_timestamp
      IMPORTING stamp         TYPE timestampl
      RETURNING VALUE(result) TYPE REF TO zif_timestamp
      RAISING   zcx_timestamp.

    "! Opens a short classic UTC time stamp, TIMESTAMP, for calculation.
    "! @parameter stamp  | UTC time stamp as YYYYMMDDhhmmss
    "! @parameter result | The point in time, ready for calculation
    "! @raising   zcx_timestamp | The value is not a UTC time stamp
    CLASS-METHODS for_short_timestamp
      IMPORTING stamp         TYPE timestamp
      RETURNING VALUE(result) TYPE REF TO zif_timestamp
      RAISING   zcx_timestamp.

    "! Opens a Unix time for calculation. The parameter is int8 because Unix
    "! time outlives the year 2038 there; pass an i value through CONV int8( ).
    "! @parameter seconds | Seconds since 1970-01-01T00:00:00Z, negative before 1970
    "! @parameter result  | The point in time, ready for calculation
    "! @raising   zcx_timestamp | The value leaves the time line, years 1 to 9999
    CLASS-METHODS for_unix
      IMPORTING seconds       TYPE int8
      RETURNING VALUE(result) TYPE REF TO zif_timestamp
      RAISING   zcx_timestamp.
    "! Parses an ISO 8601 / RFC 3339 time stamp. The text needs a calendar
    "! date, a time of day in whole seconds with an optional fraction, and a
    "! zone designator: Z or an offset like +02:00, +0200 or -05. T and Z
    "! may be lower case; a single blank may replace the T.
    "! <p>A text without a zone designator is a local time, not a point in
    "! time, and is rejected - parse it with
    "! {@link zcl_timestamp.METH:for_date_time} and the zone it was written
    "! in.</p>
    "! @parameter text   | Text as YYYY-MM-DDThh:mm:ss[.fffffff](Z|+hh:mm|-hh:mm)
    "! @parameter result | The point in time, ready for calculation
    "! @raising   zcx_timestamp | The text is not a time stamp with a zone designator,
    "!                            or the point in time leaves the time line
    CLASS-METHODS for_iso
      IMPORTING text          TYPE csequence
      RETURNING VALUE(result) TYPE REF TO zif_timestamp
      RAISING   zcx_timestamp.

    "! Opens the point in time at which the wall clock of a time zone shows
    "! the given date and time. In the hour repeated by the switch back from
    "! daylight saving time the kernel decides which of the two moments is
    "! meant.
    "! @parameter date   | Date on the wall clock, YYYYMMDD
    "! @parameter time   | Time on the wall clock, hhmmss
    "! @parameter zone   | Time zone as maintained in the system, for example CET or UTC;
    "!                     case and surrounding blanks do not matter
    "! @parameter result | The point in time, ready for calculation
    "! @raising   zcx_timestamp | The date or the time is not valid, the zone is not
    "!                            known, or the wall clock never showed that time because
    "!                            a daylight saving switch skipped it
    CLASS-METHODS for_date_time
      IMPORTING date          TYPE d
                time          TYPE t
                zone          TYPE csequence
      RETURNING VALUE(result) TYPE REF TO zif_timestamp
      RAISING   zcx_timestamp.

    "! Tests whether a time zone is known to the system. Guard a call with this
    "! when an unknown zone is a regular case rather than an error, for example
    "! when the zone comes from user input.
    "! @parameter zone   | Time zone to test; case and surrounding blanks do not matter
    "! @parameter result | abap_true when the zone exists
    CLASS-METHODS is_known_zone
      IMPORTING zone          TYPE csequence
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS zcl_timestamp IMPLEMENTATION.

  METHOD for_utclong.
    result = lcl_factory=>create( )->for_utclong( instant ).
  ENDMETHOD.

  METHOD for_timestamp.
    result = lcl_factory=>create( )->for_timestamp( stamp ).
  ENDMETHOD.

  METHOD for_short_timestamp.
    result = lcl_factory=>create( )->for_timestamp( CONV #( stamp ) ).
  ENDMETHOD.

  METHOD for_unix.
    result = lcl_factory=>create( )->for_unix( seconds ).
  ENDMETHOD.

  METHOD for_iso.
    result = lcl_factory=>create( )->for_iso( text ).
  ENDMETHOD.

  METHOD for_date_time.
    result = lcl_factory=>create( )->for_date_time( date = date
                                                    time = time
                                                    zone = zone ).
  ENDMETHOD.

  METHOD is_known_zone.
    result = lcl_factory=>create( )->is_known_zone( zone ).
  ENDMETHOD.

ENDCLASS.
