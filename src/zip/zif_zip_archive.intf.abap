"! <p class="shorttext synchronized" lang="EN">ZIP archive</p>
"! Read-only view on a loaded ZIP archive: lists its entries and extracts
"! them by name. Names are matched exactly, including letter case, with / as
"! path separator. Folder entries - names ending in a slash - are listed but
"! carry no content.
INTERFACE zif_zip_archive
  PUBLIC.

  TYPES:
    "! One entry of the archive. size is the uncompressed size in bytes;
    "! is_folder marks a folder entry, which has no content to extract.
    BEGIN OF zip_entry,
      name      TYPE string,
      size      TYPE i,
      date      TYPE d,
      time      TYPE t,
      is_folder TYPE abap_bool,
    END OF zip_entry.

  "! Entries in archive order, folder entries included.
  TYPES entry_table TYPE STANDARD TABLE OF zip_entry WITH EMPTY KEY.

  "! Entry names in archive order, folder entries included.
  TYPES name_table TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  TYPES:
    "! One extracted file: its name inside the archive and its bytes.
    BEGIN OF zip_file,
      name    TYPE string,
      content TYPE xstring,
    END OF zip_file.

  "! Extracted files in archive order.
  TYPES file_table TYPE STANDARD TABLE OF zip_file WITH EMPTY KEY.

  "! Number of entries, folder entries included.
  "! @parameter result | Entry count
  METHODS entry_count
    RETURNING VALUE(result) TYPE i.

  "! Every entry with its size and modification stamp.
  "! @parameter result | Entries in archive order
  METHODS entries
    RETURNING VALUE(result) TYPE entry_table.

  "! Names of every entry.
  "! @parameter result | Names in archive order
  METHODS names
    RETURNING VALUE(result) TYPE name_table.

  "! Tells whether an entry with the given name exists.
  "! @parameter name   | Path inside the archive, case sensitive
  "! @parameter result | abap_true when the entry exists
  METHODS has
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE abap_bool.

  "! Size and modification stamp of one entry.
  "! @parameter name    | Path inside the archive, case sensitive
  "! @parameter result  | The entry
  "! @raising   zcx_zip | No entry has this name
  METHODS entry
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE zip_entry
    RAISING   zcx_zip.

  "! Extracts the bytes of one entry.
  "! @parameter name    | Path inside the archive, case sensitive
  "! @parameter result  | Uncompressed bytes, empty for an empty entry
  "! @raising   zcx_zip | No entry has this name, or its data is corrupt
  METHODS extract
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE xstring
    RAISING   zcx_zip.

  "! Extracts one entry and decodes it as UTF-8 text.
  "! @parameter name    | Path inside the archive, case sensitive
  "! @parameter result  | The text
  "! @raising   zcx_zip | No entry has this name, its data is corrupt, or it is not valid UTF-8
  METHODS extract_text
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_zip.

  "! Extracts every file. Folder entries are skipped, they have no content.
  "! @parameter result  | Files in archive order
  "! @raising   zcx_zip | The data of an entry is corrupt
  METHODS extract_all
    RETURNING VALUE(result) TYPE file_table
    RAISING   zcx_zip.

ENDINTERFACE.
