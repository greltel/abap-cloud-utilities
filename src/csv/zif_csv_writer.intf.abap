"! <p class="shorttext synchronized" lang="EN">CSV write access</p>
"! Renders internal tables as a CSV document (RFC 4180). A field that contains
"! the delimiter, the quote character or a line break is enclosed in quotes,
"! quotes inside it are written twice. Every record ends with a line break.
"! Configure the dialect with the fluent methods, then terminate the chain
"! with {@link zif_csv_writer.METH:to_string}.
INTERFACE zif_csv_writer
  PUBLIC.

  "! Texts of a header row.
  TYPES labels TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  "! Uses the given field delimiter instead of the comma.
  "! @parameter delimiter | Exactly one character, for example ; or cl_abap_char_utilities=>horizontal_tab
  "! @parameter self      | Same instance, for chaining
  METHODS with_delimiter
    IMPORTING delimiter   TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_csv_writer.

  "! Uses the given quote character instead of the double quote.
  "! @parameter quote | Exactly one character
  "! @parameter self  | Same instance, for chaining
  METHODS with_quote
    IMPORTING quote       TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_csv_writer.

  "! Ends every record with the given line break instead of CRLF.
  "! @parameter line_break | cl_abap_char_utilities=>cr_lf or cl_abap_char_utilities=>newline
  "! @parameter self       | Same instance, for chaining
  METHODS with_line_break
    IMPORTING line_break  TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_csv_writer.

  "! Writes the given texts as the header row. For a table they replace the
  "! component names and their count must match the component count; for
  "! ready-made records they are written in front of the records.
  "! @parameter labels | Header texts in column order
  "! @parameter self   | Same instance, for chaining
  METHODS with_labels
    IMPORTING labels      TYPE labels
    RETURNING VALUE(self) TYPE REF TO zif_csv_writer.

  "! Writes no header row. By default a table gets a header row with its
  "! component names, ready-made records get none.
  "! @parameter self | Same instance, for chaining
  METHODS without_header
    RETURNING VALUE(self) TYPE REF TO zif_csv_writer.

  "! The complete document. Empty when there is neither a header nor a record.
  "! @parameter result  | CSV document
  "! @raising   zcx_csv | The dialect is invalid or the label count does not match
  METHODS to_string
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_csv.

ENDINTERFACE.
