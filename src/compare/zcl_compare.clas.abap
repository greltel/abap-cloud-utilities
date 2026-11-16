"! <p class="shorttext synchronized" lang="EN">Compare utility</p>
"! Entry point for the difference between two structures of the same type:
"! which components changed, with the value each had before and has after,
"! optionally leaving aside an ignore list, and with the changed components
"! marked in a %control structure for RAP.
"! Standalone - depends on nothing but SAP released APIs.
CLASS zcl_compare DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Starts a comparison with an empty ignore list.
    "! @parameter result | Builder that collects the components to ignore and is closed with build( )
    CLASS-METHODS builder
      RETURNING VALUE(result) TYPE REF TO zif_compare_builder.

    "! Compares two structures in every component. Short for
    "! builder( )->build( )->difference( ... ).
    "! @parameter before      | The structure in its earlier state; its component names name the changes
    "! @parameter after       | The structure in its later state, of the same type
    "! @parameter result      | The difference, immutable
    "! @raising   zcx_compare | before is not a structure, or after is not of its type
    CLASS-METHODS difference
      IMPORTING before        TYPE any
                after         TYPE any
      RETURNING VALUE(result) TYPE REF TO zif_compare_difference
      RAISING   zcx_compare.

ENDCLASS.


CLASS zcl_compare IMPLEMENTATION.

  METHOD builder.
    result = NEW lcl_builder( ).
  ENDMETHOD.

  METHOD difference.
    result = builder( )->build( )->difference( before = before
                                               after  = after ).
  ENDMETHOD.

ENDCLASS.
