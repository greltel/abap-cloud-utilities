*"* use this source file for your ABAP unit test classes
CLASS ltc_sy DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zif_sy.

    METHODS setup.
    METHODS teardown.
    METHODS given_no_match_then_subrc_4  FOR TESTING.
    METHODS given_session_then_user_set  FOR TESTING.
    METHODS given_session_then_dates_set FOR TESTING.
ENDCLASS.


CLASS ltc_sy IMPLEMENTATION.

  METHOD setup.
    cut = zcl_sy=>create( ).
  ENDMETHOD.

  METHOD teardown.
    CLEAR cut.
  ENDMETHOD.

  METHOD given_no_match_then_subrc_4.
    FIND `x` IN `abc`.

    DATA(return_code) = cut->subrc( ).

    cl_abap_unit_assert=>assert_equals(
      act = return_code
      exp = 4
      msg = `Return code of the previous statement was not passed through` ).
  ENDMETHOD.

  METHOD given_session_then_user_set.
    DATA(user_name) = cut->user_name( ).

    cl_abap_unit_assert=>assert_not_initial(
      act = user_name
      msg = `Technical user name could not be determined` ).
  ENDMETHOD.

  METHOD given_session_then_dates_set.
    DATA(system_date) = cut->system_date( ).
    DATA(user_date) = cut->user_date( ).

    cl_abap_unit_assert=>assert_not_initial(
      act = system_date
      msg = `System date could not be determined` ).
    cl_abap_unit_assert=>assert_not_initial(
      act = user_date
      msg = `User date could not be determined` ).
  ENDMETHOD.

ENDCLASS.
