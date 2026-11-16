"! <p class="shorttext synchronized" lang="EN">Difference between two structures</p>
"! Immutable outcome of one comparison: the components whose value is not the
"! same in the two structures. Instances are created through
"! {@link zif_compare.METH:difference}.
"! <p>A component is named the way RTTI names it, in upper case. A component
"! of a nested structure carries the path that leads to it, the names joined
"! by a hyphen as in ABAP source: ADDRESS-CITY. Wherever a name is handed in,
"! upper and lower case make no difference, and the name of a nested
"! structure stands for every component below it.</p>
INTERFACE zif_compare_difference
  PUBLIC.

  TYPES:
    "! One changed component with its two values as text.
    "! <p>A value reads the way a string template writes it without formatting
    "! options: a number with a decimal point and a leading minus sign, a date
    "! as YYYYMMDD, a time as hhmmss, a character field without the blanks at
    "! its end, an enumerated value as the name of its constant. What has no
    "! text of its own is described in square brackets: an internal table by
    "! its number of rows, [3 rows], a reference as [bound] or [initial].</p>
    BEGIN OF ty_change,
      component TYPE string,
      before    TYPE string,
      after     TYPE string,
    END OF ty_change.
  "! The changed components of one comparison, in the order the structure
  "! declares them.
  TYPES ty_changes TYPE STANDARD TABLE OF ty_change WITH EMPTY KEY.

  "! Tests whether the two structures differ in at least one component that
  "! is not on the ignore list - the guard for an update, a change document
  "! or an event that must not be written when nothing relevant changed.
  "! @parameter result | abap_true when there is at least one changed component
  METHODS has_changes
    RETURNING VALUE(result) TYPE abap_bool.

  "! Tests whether one component changed. For a nested structure the answer
  "! is abap_true as soon as one component below it changed.
  "! @parameter component   | Name of a component, or the path to one: STATUS, Status, ADDRESS-CITY
  "! @parameter result      | abap_true when the value differs; always abap_false for a component
  "!                          on the ignore list, which was not compared
  "! @raising   zcx_compare | The compared structure has no component of this name - a
  "!                          misspelled name would otherwise read as not changed
  METHODS has_changed
    IMPORTING component     TYPE csequence
    RETURNING VALUE(result) TYPE abap_bool
    RAISING   zcx_compare.

  "! The changed components with the value each had before and has after,
  "! ready for a log, a change document or a message.
  "! @parameter result | One row per changed component; empty when the structures are equal apart
  "!                     from the ignored components
  METHODS changes
    RETURNING VALUE(result) TYPE ty_changes.

  "! Marks the changed components in a structure of flags: the %control
  "! structure of a RAP derived type, so that MODIFY ENTITIES updates exactly
  "! the fields that differ, its %element structure to highlight them in a
  "! message, or the X structure of a BAPI.
  "! <p>A flag is a component of one byte, set to the constants on and off
  "! of if_abap_behv, or of one character, set to abap_true and abap_false.
  "! Every flag is written: on when the component of the same name changed,
  "! off otherwise, whatever it held before. Flags are found by name, in
  "! nested structures by path; a flag named like a nested structure is on
  "! when anything below it changed. Components that are not flags, such as
  "! the key fields of a BAPI X structure, are left as they are, and a changed
  "! component without a flag of its name is left out - the complete list
  "! stays available through {@link zif_compare_difference.METH:changes}.</p>
  "! @parameter control     | Reference to the structure to fill, REF #( update-%control )
  "! @raising   zcx_compare | The reference does not point to a structure, or the structure
  "!                          holds no flag at all; it is then left as it was
  METHODS write_control
    IMPORTING control TYPE REF TO data
    RAISING   zcx_compare.

ENDINTERFACE.
