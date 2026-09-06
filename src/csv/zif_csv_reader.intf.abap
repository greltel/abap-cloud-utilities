"! <p class="shorttext synchronized" lang="EN">CSV read access</p>
"! Parses a CSV document (RFC 4180) into internal tables. A field enclosed in
"! quotes may contain the delimiter, line breaks and quotes (written twice).
"! Records end with CRLF, LF or CR; blank lines are skipped. Configure the
"! dialect with the fluent methods, then terminate the chain with
"! {@link zif_csv_reader.METH:read_into} or
"! {@link zif_csv_reader.METH:read_records}.
INTERFACE zif_csv_reader
  PUBLIC.

  "! Fields of one record, in document order.
  TYPES record  TYPE STANDARD TABLE OF string WITH EMPTY KEY.
  "! Records of a document, in document order.
  TYPES records TYPE STANDARD TABLE OF record WITH EMPTY KEY.

  "! Uses the given field delimiter instead of the comma.
  "! @parameter delimiter | Exactly one character, for example ; or cl_abap_char_utilities=>horizontal_tab
  "! @parameter self      | Same instance, for chaining
  METHODS with_delimiter
    IMPORTING delimiter   TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_csv_reader.

  "! Uses the given quote character instead of the double quote.
  "! @parameter quote | Exactly one character
  "! @parameter self  | Same instance, for chaining
  METHODS with_quote
    IMPORTING quote       TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_csv_reader.

  "! Treats the first record as data. By default the first record is a header
  "! whose column names select the target components in
  "! {@link zif_csv_reader.METH:read_into}.
  "! @parameter self | Same instance, for chaining
  METHODS without_header
    RETURNING VALUE(self) TYPE REF TO zif_csv_reader.

  "! Every record of the document as the table of its field texts, exactly as
  "! parsed - a header record is returned like any other record.
  "! @parameter result  | Records in document order
  "! @raising   zcx_csv | The document is malformed or the dialect is invalid
  METHODS read_records
    RETURNING VALUE(result) TYPE records
    RAISING   zcx_csv.

  "! Fills the given table, one row per data record. With a header, columns
  "! are matched to components by name (case insensitive); columns without a
  "! component are ignored, components without a column stay initial. Without
  "! a header, columns are mapped to components by position. Every record must
  "! have as many fields as the first one. Values are converted with the ABAP
  "! assignment rules of the component type (dates as YYYYMMDD, numbers with
  "! a decimal point).
  "! @parameter rows    | Receiving table; its line type must be a structure of elementary components
  "! @raising   zcx_csv | Malformed document, unsupported line type, no matching column,
  "!                      wrong field count or a value that cannot be converted
  METHODS read_into
    EXPORTING rows TYPE STANDARD TABLE
    RAISING   zcx_csv.

ENDINTERFACE.
