"! <p class="shorttext synchronized" lang="EN">String template</p>
"! Immutable text template with named placeholders such as
"! Dear {name}, your order {order_id} has shipped. A placeholder name starts
"! with a letter or underscore and continues with letters, digits and
"! underscores; names are matched without regard to case. Literal braces are
"! written twice: {{ and }}. Every with method hands back a new template that
"! knows one more value, so one parsed template can be rendered many times.
INTERFACE zif_string_template
  PUBLIC.

  TYPES:
    "! One placeholder name and the value that replaces it.
    BEGIN OF pair,
      name  TYPE string,
      value TYPE string,
    END OF pair.

  "! List of name and value pairs.
  TYPES pairs TYPE STANDARD TABLE OF pair WITH EMPTY KEY.

  "! Distinct placeholder names.
  TYPES names TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  "! The placeholder names found in the template, each once, in the order of
  "! their first appearance and spelled as written there.
  "! @parameter result | Placeholder names, empty for a template without placeholders
  METHODS placeholders
    RETURNING VALUE(result) TYPE names.

  "! Binds a value to a placeholder. The value is converted to text the way a
  "! string template does it, so a date arrives as YYYYMMDD; pass a text when
  "! another format is wanted. A later value for the same name wins.
  "! @parameter name   | Placeholder name, case does not matter
  "! @parameter value  | Any elementary value
  "! @parameter result | Template that knows this value
  METHODS with
    IMPORTING name          TYPE string
              value         TYPE simple
    RETURNING VALUE(result) TYPE REF TO zif_string_template.

  "! Binds a list of values at once.
  "! @parameter pairs  | Names and their values
  "! @parameter result | Template that knows these values
  METHODS with_pairs
    IMPORTING pairs         TYPE pairs
    RETURNING VALUE(result) TYPE REF TO zif_string_template.

  "! Binds every elementary component of a structure to the placeholder with
  "! the component name. Nested structures, tables and references are skipped.
  "! @parameter structure         | Flat or nested structure
  "! @parameter result            | Template that knows the component values
  "! @raising   zcx_string_format | The argument is not a structure
  METHODS with_structure
    IMPORTING structure     TYPE any
    RETURNING VALUE(result) TYPE REF TO zif_string_template
    RAISING   zcx_string_format.

  "! Replaces every placeholder by its value.
  "! @parameter result            | The rendered text
  "! @raising   zcx_string_format | A placeholder has no value
  METHODS render
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_string_format.

  "! Replaces every placeholder that has a value and leaves the others in
  "! place, braces included, so the text can be completed in a later step.
  "! @parameter result | The partially rendered text
  METHODS render_partial
    RETURNING VALUE(result) TYPE string.

ENDINTERFACE.
