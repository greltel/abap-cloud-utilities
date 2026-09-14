"! <p class="shorttext synchronized" lang="EN">JSON write access</p>
"! Serializes an ABAP data object into a JSON string. Configure the member
"! names with the fluent methods, then terminate the chain with
"! {@link zif_json_writer.METH:to_string}.
"! <p>By default abap_bool components are serialized as their character values
"! (X / empty), the way the XCO JSON APIs render them; call
"! {@link zif_json_writer.METH:abap_bool_to_booleans} for the JSON values
"! true and false.</p> - the XCO JSON APIs offer no transformation to JSON
"! booleans in this direction.
INTERFACE zif_json_writer
  PUBLIC.

  "! Renders the member names in camelCase (ORDER_ID becomes orderId).
  "! When both camelCase and PascalCase are requested, the last call wins.
  "! @parameter self | Same instance, for chaining.
  METHODS as_camel_case
    RETURNING VALUE(self) TYPE REF TO zif_json_writer.

  "! Renders the member names in PascalCase (ORDER_ID becomes OrderId).
  "! When both camelCase and PascalCase are requested, the last call wins.
  "! @parameter self | Same instance, for chaining
  METHODS as_pascal_case
    RETURNING VALUE(self) TYPE REF TO zif_json_writer.

    "! Renders abap_bool components as the JSON values true and false instead
  "! of their character values X and empty. Components typed abap_bool,
  "! abap_boolean, xsdboolean, boole_d or xfeld are recognised anywhere in
  "! the data object, including inside internal tables; any other character
  "! component keeps its text.
  "! @parameter self | Same instance, for chaining
  METHODS abap_bool_to_booleans
    RETURNING VALUE(self) TYPE REF TO zif_json_writer.

  "! The document as a JSON string. Without a name transformation the member
  "! names keep the underscore style of the component names (ORDER_ID).
  "! @parameter result   | JSON string
  "! @raising   zcx_acu_json | The JSON string could not be generated
  METHODS to_string
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_acu_json.

ENDINTERFACE.
