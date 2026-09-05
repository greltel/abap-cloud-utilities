"! <p class="shorttext synchronized" lang="EN">UUID utility</p>
"! Entry point for creating, parsing and formatting UUIDs. Standalone -
"! depends on nothing but SAP released APIs.
CLASS zcl_uuid DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Creates a new, unique identifier.
    "! @parameter result | Fresh UUID
    CLASS-METHODS new
      RETURNING VALUE(result) TYPE REF TO zif_uuid.

    "! Wraps 16 raw bytes, for example a RAP key read from the database.
    "! @parameter uuid   | Binary UUID, may be initial
    "! @parameter result | Identifier carrying the bytes
    CLASS-METHODS for_x16
      IMPORTING uuid          TYPE sysuuid_x16
      RETURNING VALUE(result) TYPE REF TO zif_uuid.

    "! Parses a character representation. The format is recognised by length:
    "! 22 characters (case sensitive SAP format), 32 hexadecimal characters,
    "! or 36 characters with hyphens. Hexadecimal input may be lower case;
    "! surrounding blanks are ignored.
    "! @parameter text     | UUID in one of the three character formats
    "! @parameter result   | Identifier carrying the parsed bytes
    "! @raising   zcx_uuid | The text is not a valid representation
    CLASS-METHODS for_text
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_uuid
      RAISING   zcx_uuid.

    "! The generator behind new( ), for injection into classes that assign keys.
    "! @parameter result | Generator producing system UUIDs
    CLASS-METHODS generator
      RETURNING VALUE(result) TYPE REF TO zif_uuid_generator.

ENDCLASS.


CLASS zcl_uuid IMPLEMENTATION.

  METHOD new.
    result = generator( )->next( ).
  ENDMETHOD.

  METHOD for_x16.
    result = NEW lcl_uuid( uuid ).
  ENDMETHOD.

  METHOD for_text.
    result = NEW lcl_uuid( lcl_parser=>parse( text ) ).
  ENDMETHOD.

  METHOD generator.
    result = NEW lcl_generator( ).
  ENDMETHOD.

ENDCLASS.

