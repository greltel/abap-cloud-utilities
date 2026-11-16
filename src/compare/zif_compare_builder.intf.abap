"! <p class="shorttext synchronized" lang="EN">Comparison builder</p>
"! Collects the ignore list of a comparison and is closed with
"! {@link zif_compare_builder.METH:build}. Obtained from
"! {@link zcl_compare.METH:builder}.
"! <p>An ignored component is not compared and never counts as changed -
"! the place for administrative fields such as the time and the user of the
"! last change, which differ on every save without saying anything. Names
"! are taken in any case. A name the compared structure does not have is
"! simply never met, so one list of administrative fields serves structures
"! that carry only some of them. The chain itself never raises - a call
"! that cannot be used is remembered and reported by build( ).</p>
INTERFACE zif_compare_builder
  PUBLIC.

  "! Puts one component on the ignore list.
  "! @parameter component | Name of a component; of a nested structure, to ignore everything below
  "!                        it; or the path to one component of it, ADDRESS-CITY
  "! @parameter self      | Same instance, for chaining
  METHODS ignoring
    IMPORTING component   TYPE csequence
    RETURNING VALUE(self) TYPE REF TO zif_compare_builder.

  "! Puts a list of components on the ignore list - one call for a list that
  "! is kept in one place and shared by several comparisons.
  "! @parameter components | Names and paths as for {@link zif_compare_builder.METH:ignoring};
  "!                         an empty list ignores nothing
  "! @parameter self       | Same instance, for chaining
  METHODS ignoring_list
    IMPORTING components  TYPE string_table
    RETURNING VALUE(self) TYPE REF TO zif_compare_builder.

  "! Creates the comparison. The builder can be used further afterwards; the
  "! comparison keeps the ignore list it was built with.
  "! @parameter result      | The comparison, immutable
  "! @raising   zcx_compare | A component to ignore was handed in without a name
  METHODS build
    RETURNING VALUE(result) TYPE REF TO zif_compare
    RAISING   zcx_compare.

ENDINTERFACE.
