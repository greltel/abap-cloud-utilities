"! <p class="shorttext synchronized" lang="EN">Factory calendar</p>
"! Working day arithmetic against one factory calendar, on top of the released
"! factory calendar runtime. A working day is a day the calendar marks as
"! such - weekends and the public holidays of the assigned holiday calendar
"! are skipped. Instances are created through {@link zcl_acu_date.METH:calendar}.
"! <p>Dates enter in the internal ABAP format and leave as
"! {@link zif_acu_date}, so a result can be calculated on further or stored
"! through {@link zif_acu_date.METH:as_date}.</p>
INTERFACE zif_acu_calendar
  PUBLIC.

  "! Tests whether the calendar marks the date as a working day.
  "! @parameter date     | Date in the internal ABAP format, YYYYMMDD
  "! @parameter result   | abap_true for a working day
  "! @raising   zcx_date | Not a calendar date, unknown calendar, or date outside its validity
  METHODS is_working_day
    IMPORTING date          TYPE d
    RETURNING VALUE(result) TYPE abap_bool
    RAISING   zcx_date.

  "! Moves the date by whole working days, the way a spreadsheet WORKDAY
  "! function does: the start date itself is never counted. Moving forward
  "! from a non-working day, one working day lands on the next working day;
  "! moving backwards, on the previous one. Zero returns the date unchanged,
  "! even when it is not a working day.
  "! @parameter date     | Date in the internal ABAP format, YYYYMMDD
  "! @parameter days     | Working days to move, negative to move backwards
  "! @parameter result   | New date, this many working days away
  "! @raising   zcx_date | Not a calendar date, unknown calendar, or result outside its validity
  METHODS add_working_days
    IMPORTING date          TYPE d
              days          TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_acu_date
    RAISING   zcx_date.

  "! First working day after the date. Same as adding one working day.
  "! @parameter date     | Date in the internal ABAP format, YYYYMMDD
  "! @parameter result   | New date on the next working day
  "! @raising   zcx_date | Not a calendar date, unknown calendar, or result outside its validity
  METHODS next_working_day
    IMPORTING date          TYPE d
    RETURNING VALUE(result) TYPE REF TO zif_acu_date
    RAISING   zcx_date.

  "! Last working day before the date. Same as subtracting one working day.
  "! @parameter date     | Date in the internal ABAP format, YYYYMMDD
  "! @parameter result   | New date on the previous working day
  "! @raising   zcx_date | Not a calendar date, unknown calendar, or result outside its validity
  METHODS previous_working_day
    IMPORTING date          TYPE d
    RETURNING VALUE(result) TYPE REF TO zif_acu_date
    RAISING   zcx_date.

ENDINTERFACE.
