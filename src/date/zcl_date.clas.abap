"! <p class="shorttext synchronized" lang="EN">Date utility</p>
"! Entry point for calendar arithmetic on top of the released XCO time APIs.
"! Standalone - depends on nothing but SAP released APIs.
"! <p>The utility never reads the system context. A date always enters through
"! one of the factory methods, so the caller decides where "today" comes from
"! and every calculation stays reproducible in a test.</p>
CLASS zcl_date DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Opens an ABAP date for calculation.
    "! @parameter date     | Date in the internal ABAP format, YYYYMMDD
    "! @parameter result   | The date, ready for calculation
    "! @raising   zcx_date | The value does not describe a calendar date
    CLASS-METHODS for_date
      IMPORTING date          TYPE d
      RETURNING VALUE(result) TYPE REF TO zif_date
      RAISING   zcx_date.

    "! Parses an ISO 8601 calendar date and opens it for calculation.
    "! @parameter iso      | Date as YYYY-MM-DD, without time and time zone
    "! @parameter result   | The date, ready for calculation
    "! @raising   zcx_date | The string is not an ISO 8601 calendar date
    CLASS-METHODS for_iso
      IMPORTING iso           TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_date
      RAISING   zcx_date.

    "! Assembles a date from its calendar components.
    "! @parameter year     | Year, 1 to 9999
    "! @parameter month    | Month, 1 to 12
    "! @parameter day      | Day, 1 to the length of the month
    "! @parameter result   | The date, ready for calculation
    "! @raising   zcx_date | The components do not describe a calendar date
    CLASS-METHODS for_parts
      IMPORTING year          TYPE i
                month         TYPE i
                day           TYPE i
      RETURNING VALUE(result) TYPE REF TO zif_date
      RAISING   zcx_date.

    "! Tests whether a value describes a date of the Gregorian calendar.
    "! Guard a call with this when a rejected date is a regular case rather
    "! than an error.
    "! @parameter date   | Date in the internal ABAP format, YYYYMMDD
    "! @parameter result | abap_true when the date exists
    CLASS-METHODS is_valid
      IMPORTING date          TYPE d
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.


CLASS zcl_date IMPLEMENTATION.

  METHOD for_date.
    result = lcl_date=>create( date ).
  ENDMETHOD.

  METHOD for_iso.
    result = lcl_date=>create_from_iso( iso ).
  ENDMETHOD.

  METHOD for_parts.
    result = lcl_date=>create_from_parts( year  = year
                                          month = month
                                          day   = day ).
  ENDMETHOD.

  METHOD is_valid.
    result = lcl_date=>is_valid( date ).
  ENDMETHOD.

ENDCLASS.

