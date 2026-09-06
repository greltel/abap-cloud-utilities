"! <p class="shorttext synchronized" lang="EN">Number range interval</p>
"! One interval of a number range object, addressed by object and interval
"! number and, where the object is defined that way, by subobject and year.
"! Immutable: the configuration methods return a new instance. Every request
"! goes to the number range runtime, so the numbers handed out are unique
"! across all callers of the interval.
INTERFACE zif_number_range
  PUBLIC.

  "! A number as the runtime hands it out: 20 digits, padded with leading
  "! zeros. Assign it to the target field with CONV; a shorter NUMC field
  "! keeps the significant digits.
  TYPES number TYPE cl_numberrange_runtime=>nr_number.

  "! Consecutive numbers in ascending order.
  TYPES number_table TYPE STANDARD TABLE OF number WITH EMPTY KEY.

  TYPES:
    "! Outcome of one request for several numbers. quantity is the count
    "! actually assigned; it falls short of the request only when the interval
    "! did not have enough numbers left. is_critical reports that the numbers
    "! lie in the warning area of the interval, is_exhausted that the interval
    "! handed out its last number.
    BEGIN OF block,
      first        TYPE number,
      last         TYPE number,
      quantity     TYPE i,
      is_critical  TYPE abap_bool,
      is_exhausted TYPE abap_bool,
    END OF block.

  "! Hands out the next number.
  "! @parameter result           | Next free number of the interval
  "! @raising   zcx_number_range | The interval is unknown, external or exhausted
  METHODS next
    RETURNING VALUE(result) TYPE number
    RAISING   zcx_number_range.

  "! Hands out up to quantity consecutive numbers in one request. When fewer
  "! numbers are left than requested the block is shorter, so compare its
  "! quantity with the request.
  "! @parameter quantity         | How many numbers to reserve, at least 1
  "! @parameter result           | First and last number, count and status
  "! @raising   zcx_number_range | The quantity is below 1, or the interval is unknown or external
  METHODS next_block
    IMPORTING quantity      TYPE i
    RETURNING VALUE(result) TYPE block
    RAISING   zcx_number_range.

  "! Hands out exactly quantity consecutive numbers as a table, ready to be
  "! assigned to a list of new records by index. Raises when the interval has
  "! fewer numbers left than requested; the numbers assigned by then stay used.
  "! @parameter quantity         | How many numbers to reserve, at least 1
  "! @parameter result           | The numbers in ascending order, exactly quantity lines
  "! @raising   zcx_number_range | The quantity is below 1, the interval ran short, or it is unknown
  METHODS next_numbers
    IMPORTING quantity      TYPE i
    RETURNING VALUE(result) TYPE number_table
    RAISING   zcx_number_range.

  "! Reads the number level of the interval without assigning anything: the
  "! last number handed out, zero for a fresh interval. For buffered objects
  "! this is the level in the database, which runs ahead of the numbers the
  "! buffer has actually handed out.
  "! @parameter result           | Last number assigned in the database
  "! @raising   zcx_number_range | The interval is unknown
  METHODS last_assigned
    RETURNING VALUE(result) TYPE number
    RAISING   zcx_number_range.

  "! Addresses the interval of a subobject, for objects defined with one, for
  "! example a company code. Case insensitive, surrounding blanks are ignored.
  "! @parameter subobject        | Subobject value of up to 6 characters
  "! @parameter result           | New interval for the subobject
  "! @raising   zcx_number_range | The subobject is empty or longer than 6 characters
  METHODS in_subobject
    IMPORTING subobject     TYPE string
    RETURNING VALUE(result) TYPE REF TO zif_number_range
    RAISING   zcx_number_range.

  "! Addresses the interval of a year, for year dependent objects.
  "! @parameter year             | Fiscal year between 1 and 9999
  "! @parameter result           | New interval for the year
  "! @raising   zcx_number_range | The year is outside 1 to 9999
  METHODS for_year
    IMPORTING year          TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_number_range
    RAISING   zcx_number_range.

  "! Takes the numbers from the database instead of the buffer of the object,
  "! so no buffered numbers are skipped. Has no effect on objects that are
  "! not buffered.
  "! @parameter result | New interval that bypasses the buffer
  METHODS bypassing_buffer
    RETURNING VALUE(result) TYPE REF TO zif_number_range.

ENDINTERFACE.
