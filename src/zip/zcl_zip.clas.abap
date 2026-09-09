"! <p class="shorttext synchronized" lang="EN">ZIP utility</p>
"! Entry point for ZIP archives and GZIP streams on top of the released
"! CL_ABAP_ZIP and CL_ABAP_GZIP. Standalone - depends on nothing but SAP
"! released APIs.
CLASS zcl_zip DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Compression levels accepted by the builder and the GZIP codec. stored
    "! writes the bytes as they are, normal is the kernel default, best trades
    "! time for size.
    CONSTANTS:
      BEGIN OF level,
        stored  TYPE i VALUE 0,
        fastest TYPE i VALUE 1,
        normal  TYPE i VALUE 6,
        best    TYPE i VALUE 9,
      END OF level.

    "! Starts a new, empty archive.
    "! @parameter result | Builder that collects the entries and is closed with build( )
    CLASS-METHODS builder
      RETURNING VALUE(result) TYPE REF TO zif_zip_builder.

    "! Opens an existing archive for listing and extraction.
    "! @parameter archive | The archive as bytes
    "! @parameter result  | Read-only view on the archive
    "! @raising   zcx_zip | The bytes are not a ZIP archive
    CLASS-METHODS open
      IMPORTING archive       TYPE xstring
      RETURNING VALUE(result) TYPE REF TO zif_zip_archive
      RAISING   zcx_zip.

    "! GZIP codec with the normal compression level.
    "! @parameter result | Codec for GZIP streams
    CLASS-METHODS gzip
      RETURNING VALUE(result) TYPE REF TO zif_gzip.

ENDCLASS.


CLASS zcl_zip IMPLEMENTATION.

  METHOD builder.
    result = NEW lcl_builder( ).
  ENDMETHOD.

  METHOD open.
    result = NEW lcl_archive( lcl_engine=>load( archive ) ).
  ENDMETHOD.

  METHOD gzip.
    result = NEW lcl_gzip( level-normal ).
  ENDMETHOD.

ENDCLASS.
