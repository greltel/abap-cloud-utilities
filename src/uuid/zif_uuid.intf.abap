"! <p class="shorttext synchronized" lang="EN">UUID value</p>
"! Immutable universally unique identifier. Holds the 16 raw bytes and renders
"! them in every character format the SAP system uses.
INTERFACE zif_uuid
  PUBLIC.

  "! The identifier as 16 raw bytes, the form used for RAP keys.
  "! @parameter result | Binary UUID
  METHODS as_x16
    RETURNING VALUE(result) TYPE sysuuid_x16.

  "! The identifier in the compact 22 character SAP format. Case sensitive.
  "! @parameter result | 22 character UUID
  METHODS as_c22
    RETURNING VALUE(result) TYPE sysuuid_c22.

  "! The identifier as 32 upper case hexadecimal characters.
  "! @parameter result | 32 character UUID
  METHODS as_c32
    RETURNING VALUE(result) TYPE sysuuid_c32.

  "! The identifier in the 8-4-4-4-12 form with hyphens, upper case.
  "! @parameter result | 36 character UUID
  METHODS as_c36
    RETURNING VALUE(result) TYPE sysuuid_c36.

  "! Tests for the nil UUID, all 16 bytes zero, the value of an initial key.
  "! @parameter result | abap_true when every byte is zero
  METHODS is_nil
    RETURNING VALUE(result) TYPE abap_bool.

  "! Compares the raw bytes with another identifier.
  "! @parameter other  | Identifier to compare with, may be unbound
  "! @parameter result | abap_true when both carry the same 16 bytes
  METHODS equals
    IMPORTING other         TYPE REF TO zif_uuid
    RETURNING VALUE(result) TYPE abap_bool.

ENDINTERFACE.
