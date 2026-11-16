"! <p class="shorttext synchronized" lang="EN">Comparison of two structures</p>
"! Compares two structures of the same type component by component and
"! leaves aside the components on its ignore list. Obtained from
"! {@link zif_compare_builder.METH:build}.
"! <p>A comparison is immutable and bound to no type: one instance serves
"! any number of comparisons, of rows of any structure. Inject it, and
"! replace it with a double in tests.</p>
INTERFACE zif_compare
  PUBLIC.

  "! Works out in which components two states of a structure differ: a row
  "! before and after a change, the active and the draft instance of an
  "! entity, the record on the database and the one a caller sent.
  "! <p>Two values differ when a comparison of two fields of their type says
  "! so. Nested structures are compared component by component, down to any
  "! depth. An internal table and a reference are each compared as a whole:
  "! a table differs when its rows do, a reference when it points to
  "! something else.</p>
  "! @parameter before      | The structure in its earlier state; its component names name the changes
  "! @parameter after       | The structure in its later state - of the same type, or of a type
  "!                          compatible with it, in which case it is read by position
  "! @parameter result      | The difference, immutable; without changes when the two are equal in
  "!                          every component that is not ignored
  "! @raising   zcx_compare | before is not a structure, or after is not of its type
  METHODS difference
    IMPORTING before        TYPE any
              after         TYPE any
    RETURNING VALUE(result) TYPE REF TO zif_compare_difference
    RAISING   zcx_compare.

ENDINTERFACE.
