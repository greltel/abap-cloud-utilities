"! <p class="shorttext synchronized" lang="EN">JSON node</p>
"! Read access to one value of a JSON document: its member name, its kind, its
"! text and, for objects and arrays, the values below it. Nodes are obtained
"! from {@link zcl_acu_json.METH:parse} and navigated from there by member
"! name and position; they are never created directly.
"! <p>Member names are matched exactly as written in the document - no case
"! folding and no camelCase translation. Positions count from 1, like ABAP
"! table indexes.</p>
INTERFACE zif_json_node
  PUBLIC.

  "! Values in document order.
  TYPES nodes TYPE STANDARD TABLE OF REF TO zif_json_node WITH EMPTY KEY.

  "! Member name the value is stored under in its parent object.
  "! @parameter result | Member name, empty for the root value and for array elements
  METHODS name
    RETURNING VALUE(result) TYPE string.

  "! Whether the value is an object.
  "! @parameter result | abap_true for an object
  METHODS is_object
    RETURNING VALUE(result) TYPE abap_bool.

  "! Whether the value is an array.
  "! @parameter result | abap_true for an array
  METHODS is_array
    RETURNING VALUE(result) TYPE abap_bool.

  "! Whether the value is a string.
  "! @parameter result | abap_true for a string
  METHODS is_string
    RETURNING VALUE(result) TYPE abap_bool.

  "! Whether the value is a number.
  "! @parameter result | abap_true for a number
  METHODS is_number
    RETURNING VALUE(result) TYPE abap_bool.

  "! Whether the value is true or false.
  "! @parameter result | abap_true for a boolean
  METHODS is_boolean
    RETURNING VALUE(result) TYPE abap_bool.

  "! Whether the value is null.
  "! @parameter result | abap_true for null
  METHODS is_null
    RETURNING VALUE(result) TYPE abap_bool.

  "! Text of the value. A string is returned with its escapes decoded, a
  "! number exactly as written in the document, a boolean as true or false.
  "! @parameter result | Text, empty for null, objects and arrays
  METHODS text
    RETURNING VALUE(result) TYPE string.

  "! The value as a number.
  "! @parameter result       | Number
  "! @raising   zcx_acu_json | The value is not a number
  METHODS as_number
    RETURNING VALUE(result) TYPE decfloat34
    RAISING   zcx_acu_json.

  "! The value as an ABAP boolean. Only the JSON value true counts - a string
  "! holding the text true does not.
  "! @parameter result | abap_true for the JSON value true
  METHODS as_boolean
    RETURNING VALUE(result) TYPE abap_bool.

  "! Number of members of an object or elements of an array.
  "! @parameter result | Count, 0 for a scalar value and for an empty container
  METHODS size
    RETURNING VALUE(result) TYPE i.

  "! Members of an object or elements of an array, in document order.
  "! @parameter result | Values, empty for a scalar value
  METHODS children
    RETURNING VALUE(result) TYPE nodes.

  "! Whether the object has a member with the given name.
  "! @parameter name   | Member name as written in the document
  "! @parameter result | abap_true when such a member exists
  METHODS has_child
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE abap_bool.

  "! First member with the given name.
  "! @parameter name         | Member name as written in the document
  "! @parameter result       | The member
  "! @raising   zcx_acu_json | No such member, or the value is not an object
  METHODS child
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE REF TO zif_json_node
    RAISING   zcx_acu_json.

  "! Text of the first member with the given name - the shorthand for
  "! child( )->text( ) when the member is optional.
  "! @parameter name   | Member name as written in the document
  "! @parameter result | Text of the member, empty when there is no such member
  METHODS child_text
    IMPORTING name          TYPE string
    RETURNING VALUE(result) TYPE string.

  "! Element of an array, or member of an object, by position.
  "! @parameter position     | Position, counting from 1
  "! @parameter result       | The value at that position
  "! @raising   zcx_acu_json | The position is outside the container, or the value is a scalar
  METHODS at
    IMPORTING position      TYPE i
    RETURNING VALUE(result) TYPE REF TO zif_json_node
    RAISING   zcx_acu_json.

  "! Value reached by walking a path of slash-separated steps, for example
  "! order/items/2/sku. A step made of digits selects a position when the
  "! current value is an array, otherwise it is taken as a member name. Empty
  "! steps are ignored.
  "! @parameter path         | Slash-separated member names and positions, relative to this value
  "! @parameter result       | The value at the end of the path
  "! @raising   zcx_acu_json | A step does not resolve
  METHODS descendant
    IMPORTING path          TYPE string
    RETURNING VALUE(result) TYPE REF TO zif_json_node
    RAISING   zcx_acu_json.

ENDINTERFACE.
