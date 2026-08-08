"! <p class="shorttext synchronized" lang="EN">JSON read access</p>
"! Deserializes a JSON document into ABAP data. Configure the mapping with the
"! fluent methods, then terminate the chain with
"! {@link zif_json_reader.METH:read_into}.
INTERFACE zif_json_reader
  PUBLIC.

  "! Treats the member names of the document as camelCase (orderId) and maps
  "! them to underscore component names (ORDER_ID). When both camelCase and
  "! PascalCase are requested, the last call wins.
  "! @parameter self | Same instance, for chaining
  METHODS from_camel_case
    RETURNING VALUE(self) TYPE REF TO zif_json_reader.

  "! Treats the member names of the document as PascalCase (OrderId) and maps
  "! them to underscore component names (ORDER_ID). When both camelCase and
  "! PascalCase are requested, the last call wins.
  "! @parameter self | Same instance, for chaining
  METHODS from_pascal_case
    RETURNING VALUE(self) TYPE REF TO zif_json_reader.

  "! Converts the JSON boolean values true and false to abap_true and
  "! abap_false, so that they can be received in abap_bool components.
  "! @parameter self | Same instance, for chaining
  METHODS booleans_to_abap_bool
    RETURNING VALUE(self) TYPE REF TO zif_json_reader.

  "! Writes the document into the given ABAP data object. Members without a
  "! matching component are ignored; components without a matching member
  "! stay initial.
  "! @parameter data     | Target data object; structures, internal tables and
  "!                       elementary types are supported, reference components are not
  "! @raising   zcx_json | The document could not be mapped to the target
  METHODS read_into
    EXPORTING data TYPE data
    RAISING   zcx_json.

ENDINTERFACE.
