"! <p class="shorttext synchronized" lang="EN">Descriptive user information beyond SY</p>
"! User attributes that classic ABAP never exposed through <em>sy</em>. Kept apart from
"! {@link zif_sy} because these values are looked up and can fail, while the
"! <em>sy</em> replacements always answer.
INTERFACE zif_sy_user_info
  PUBLIC.

  "! Language of the current user as ISO 639 code
  TYPES ty_language_iso TYPE c LENGTH 2.

  "! Alias maintained for the user of the current session.
  "! @parameter result | Empty when no alias is maintained
  METHODS alias
    RETURNING VALUE(result) TYPE string.

  "! Name of the current user as it should be shown on a user interface.
  "! @parameter result | Formatted name, for example first name and last name
  "! @raising   zcx_sy | Formatted name could not be determined
  METHODS formatted_name
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_sy.

  "! Language of the current user as two character ISO 639 code.
  "! @parameter result | ISO code, for example EN or DE
  "! @raising   zcx_sy | Language could not be determined
  METHODS language_iso
    RETURNING VALUE(result) TYPE ty_language_iso
    RAISING   zcx_sy.

ENDINTERFACE.
