"! <p class="shorttext synchronized" lang="EN">ZIP archive builder</p>
"! Builds a ZIP archive entry by entry. Entry names are paths inside the
"! archive with / as separator; a backslash is turned into a slash and a
"! leading slash is dropped. Names with non ASCII characters are stored
"! UTF-8 encoded, the way current archivers expect them. A mistake in the
"! chain - an empty or duplicate name, a name ending in a slash or containing
"! a .. segment, an unsupported compression level, a date before 1980 - is
"! remembered and reported by {@link zif_zip_builder.METH:build}, which keeps
"! the chain itself free of exceptions.
INTERFACE zif_zip_builder
  PUBLIC.

  "! Adds a binary entry.
  "! @parameter name    | Path of the entry inside the archive, unique, case sensitive
  "! @parameter content | Bytes of the entry, may be empty
  "! @parameter self    | Same instance, for chaining
  METHODS add
    IMPORTING name        TYPE string
              content     TYPE xstring
    RETURNING VALUE(self) TYPE REF TO zif_zip_builder.

  "! Adds a text entry. The text is stored as UTF-8 without a byte order
  "! mark, so {@link zif_zip_archive.METH:extract_text} gives the same text back.
  "! @parameter name | Path of the entry inside the archive, unique, case sensitive
  "! @parameter text | Text of the entry, may be empty
  "! @parameter self | Same instance, for chaining
  METHODS add_text
    IMPORTING name        TYPE string
              text        TYPE string
    RETURNING VALUE(self) TYPE REF TO zif_zip_builder.

  "! Sets the compression level for the entries added after this call. Entries
  "! added before keep theirs. Without a call the level is
  "! {@link zcl_zip.DATA:level}-normal; use level-stored for payloads that are
  "! compressed already, such as images or XLSX workbooks.
  "! @parameter level | 0 (stored) to 9 (best), see the level constants of {@link zcl_zip}
  "! @parameter self  | Same instance, for chaining
  METHODS with_level
    IMPORTING level       TYPE i
    RETURNING VALUE(self) TYPE REF TO zif_zip_builder.

  "! Sets the modification date and time written for the entries added after
  "! this call, which makes an archive reproducible. Without a call the
  "! entries carry the moment they were added.
  "! @parameter date | Modification date, 1980-01-01 or later - the ZIP format cannot store earlier dates
  "! @parameter time | Modification time; the format keeps it in steps of two seconds
  "! @parameter self | Same instance, for chaining
  METHODS with_timestamp
    IMPORTING date        TYPE d
              time        TYPE t
    RETURNING VALUE(self) TYPE REF TO zif_zip_builder.

  "! Finishes the archive.
  "! @parameter result  | The archive as bytes, ready to be stored or sent
  "! @raising   zcx_zip | No entry was added, or a call in the chain was invalid
  METHODS build
    RETURNING VALUE(result) TYPE xstring
    RAISING   zcx_zip.

ENDINTERFACE.
