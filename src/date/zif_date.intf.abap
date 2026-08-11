"! <p class="shorttext synchronized" lang="EN">Calendar date</p>
"! Immutable calendar date. Every method either answers a question about the
"! date or returns a new date - the instance itself never changes. The date is
"! the only state, so nothing here reads the system context; instances are
"! created through {@link zcl_date}.
INTERFACE zif_date
  PUBLIC.

  "! The date in the internal ABAP format.
  "! @parameter result | Date as YYYYMMDD
  METHODS as_date
    RETURNING VALUE(result) TYPE d.

  "! The date as an ISO 8601 calendar date, independent of any user setting.
  "! @parameter result | Date as YYYY-MM-DD
  METHODS as_iso
    RETURNING VALUE(result) TYPE string.

  "! Calendar year.
  "! @parameter result | Year, 1 to 9999
  METHODS year
    RETURNING VALUE(result) TYPE i.

  "! Calendar month.
  "! @parameter result | Month, 1 to 12
  METHODS month
    RETURNING VALUE(result) TYPE i.

  "! Day within the month.
  "! @parameter result | Day, 1 to 31
  METHODS day
    RETURNING VALUE(result) TYPE i.

  "! Calendar quarter the date falls into.
  "! @parameter result | Quarter, 1 to 4
  METHODS quarter
    RETURNING VALUE(result) TYPE i.

  "! Day of the week following ISO 8601, where a week starts on Monday.
  "! @parameter result | Weekday, 1 for Monday up to 7 for Sunday
  METHODS weekday
    RETURNING VALUE(result) TYPE i.

  "! Position of the date within its year.
  "! @parameter result | Day of year, 1 to 366
  METHODS day_of_year
    RETURNING VALUE(result) TYPE i.

  "! Length of the month the date falls into.
  "! @parameter result | Number of days, 28 to 31
  METHODS days_in_month
    RETURNING VALUE(result) TYPE i.

  "! Week number following ISO 8601. Week 1 is the week that holds the first
  "! Thursday of the year, so the first days of January can still belong to
  "! the last week of the previous year.
  "! <p>Always read together with {@link zif_date.METH:iso_year} - the week
  "! number alone is ambiguous around the turn of the year.</p>
  "! @parameter result | Week number, 1 to 53
  METHODS iso_week
    RETURNING VALUE(result) TYPE i.

  "! Year that the ISO 8601 week belongs to. Differs from
  "! {@link zif_date.METH:year} for the first and last days of a year.
  "! @parameter result | ISO week year, 1 to 9999
  METHODS iso_year
    RETURNING VALUE(result) TYPE i.

  "! Tests whether the date falls into a leap year.
  "! @parameter result | abap_true for a year with 366 days
  METHODS is_leap_year
    RETURNING VALUE(result) TYPE abap_bool.

  "! Tests whether the date falls on a Saturday or a Sunday. This is a plain
  "! calendar statement - public holidays need a factory calendar and are
  "! deliberately out of scope here.
  "! @parameter result | abap_true for Saturday and Sunday
  METHODS is_weekend
    RETURNING VALUE(result) TYPE abap_bool.

  "! Tests whether the date lies inside the given period, borders included.
  "! @parameter date_from | First date of the period
  "! @parameter date_to   | Last date of the period
  "! @parameter result    | abap_true when the date lies inside the period
  METHODS is_between
    IMPORTING date_from     TYPE d
              date_to       TYPE d
    RETURNING VALUE(result) TYPE abap_bool.

  "! Number of days between this date and the given one.
  "! @parameter other  | Date to measure against
  "! @parameter result | Days, negative when other lies before this date
  METHODS days_until
    IMPORTING other         TYPE d
    RETURNING VALUE(result) TYPE i.

  "! First day of the month the date falls into.
  "! @parameter result | New date on the first of the month
  "! @raising  zcx_date | The result leaves the value range of the calendar
  METHODS first_day_of_month
    RETURNING VALUE(result) TYPE REF TO zif_date
    RAISING   zcx_date.

  "! Last day of the month the date falls into, leap years included.
  "! @parameter result | New date on the last of the month
  "! @raising  zcx_date | The result leaves the value range of the calendar
  METHODS last_day_of_month
    RETURNING VALUE(result) TYPE REF TO zif_date
    RAISING   zcx_date.

  "! First day of the quarter the date falls into.
  "! @parameter result | New date on 1 January, 1 April, 1 July or 1 October
  "! @raising  zcx_date | The result leaves the value range of the calendar
  METHODS first_day_of_quarter
    RETURNING VALUE(result) TYPE REF TO zif_date
    RAISING   zcx_date.

  "! Last day of the quarter the date falls into.
  "! @parameter result | New date on 31 March, 30 June, 30 September or 31 December
  "! @raising  zcx_date | The result leaves the value range of the calendar
  METHODS last_day_of_quarter
    RETURNING VALUE(result) TYPE REF TO zif_date
    RAISING   zcx_date.

  "! First day of the year the date falls into.
  "! @parameter result | New date on 1 January
  "! @raising  zcx_date | The result leaves the value range of the calendar
  METHODS first_day_of_year
    RETURNING VALUE(result) TYPE REF TO zif_date
    RAISING   zcx_date.

  "! Last day of the year the date falls into.
  "! @parameter result | New date on 31 December
  "! @raising  zcx_date | The result leaves the value range of the calendar
  METHODS last_day_of_year
    RETURNING VALUE(result) TYPE REF TO zif_date
    RAISING   zcx_date.

  "! Monday of the ISO 8601 week the date falls into.
  "! @parameter result | New date on the Monday of that week
  "! @raising  zcx_date | The result leaves the value range of the calendar
  METHODS first_day_of_week
    RETURNING VALUE(result) TYPE REF TO zif_date
    RAISING   zcx_date.

  "! Sunday of the ISO 8601 week the date falls into.
  "! @parameter result | New date on the Sunday of that week
  "! @raising  zcx_date | The result leaves the value range of the calendar
  METHODS last_day_of_week
    RETURNING VALUE(result) TYPE REF TO zif_date
    RAISING   zcx_date.

  "! Moves the date by whole days.
  "! @parameter days   | Days to move, negative to move backwards
  "! @parameter result | New date, this many days away
  "! @raising  zcx_date | The result leaves the value range of the calendar
  METHODS add_days
    IMPORTING days          TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_date
    RAISING   zcx_date.

  "! Moves the date by whole months, keeping the day of the month. A day that
  "! does not exist in the target month falls back to the last day of that
  "! month, so 31 January plus one month is 28 February.
  "! @parameter months | Months to move, negative to move backwards
  "! @parameter result | New date, this many months away
  "! @raising  zcx_date | The result leaves the value range of the calendar
  METHODS add_months
    IMPORTING months        TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_date
    RAISING   zcx_date.

  "! Moves the date by whole months, keeping the position at the end of the
  "! month. A date that is the last day of its month stays the last day of the
  "! target month, so 28 February plus one month is 31 March. Any other date
  "! behaves exactly like {@link zif_date.METH:add_months}.
  "! <p>Use this for period ends and instalment plans anchored on a month end;
  "! use {@link zif_date.METH:add_months} for anniversaries.</p>
  "! @parameter months | Months to move, negative to move backwards
  "! @parameter result | New date, this many months away
  "! @raising  zcx_date | The result leaves the value range of the calendar
  METHODS add_months_ultimo
    IMPORTING months        TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_date
    RAISING   zcx_date.

  "! Moves the date by whole years. 29 February falls back to 28 February in a
  "! non leap year.
  "! @parameter years  | Years to move, negative to move backwards
  "! @parameter result | New date, this many years away
  "! @raising  zcx_date | The result leaves the value range of the calendar
  METHODS add_years
    IMPORTING years         TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_date
    RAISING   zcx_date.

ENDINTERFACE.
