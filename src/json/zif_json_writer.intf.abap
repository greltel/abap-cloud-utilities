"! <p class="shorttext synchronized" lang="EN">JSON write access</p>
"! Serializes an ABAP data object into a JSON string. Configure the member
"! names with the fluent methods, then terminate the chain with
"! {@link zif_json_writer.METH:to_string}.
"! <p><strong>abap_bool components are serialized as their character values
"! (X / empty)</strong> - the XCO JSON APIs offer no transformation to JSON
"! booleans in this direction.</p>
INTERFACE zif_json_writer
  PUBLIC.

  "! Renders the member names in camelCase (ORDER_ID becomes orderId).
  "! When both camelCase and PascalCase are requested, the last call wins.
  "! @parameter self | Same instance, for chaining
  METHODS as_camel_case
    RETURNING VALUE(self) TYPE REF TO zif_json_writer.

  "! Renders the member names in PascalCase (ORDER_ID becomes OrderId).
  "! When both camelCase and PascalCase are requested, the last call wins.
  "! @parameter self | Same instance, for chaining
  METHODS as_pascal_case
    RETURNING VALUE(self) TYPE REF TO zif_json_writer.

  "! The document as a JSON string. Without a name transformation the member
  "! names keep the underscore style of the component names (ORDER_ID).
  "! @parameter result   | JSON string
  "! @raising   zcx_json | The JSON string could not be generated
  METHODS to_string
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_json.

ENDINTERFACE.
