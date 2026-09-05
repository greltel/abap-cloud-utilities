"! <p class="shorttext synchronized" lang="EN">UUID generator</p>
"! Source of new identifiers. Inject it into classes that assign keys, so a
"! test replaces it with a double that hands out known values.
INTERFACE zif_uuid_generator
  PUBLIC.

  "! Creates a new, unique identifier.
  "! @parameter result | Fresh UUID
  METHODS next
    RETURNING VALUE(result) TYPE REF TO zif_uuid.

ENDINTERFACE.
