"! <p class="shorttext synchronized" lang="EN">Entry point for the system context utility</p>
"! Creates the system context. Consumers depend on {@link zif_sy} and receive an
"! instance through {@link zcl_sy.METH:create}.
CLASS zcl_sy DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    INTERFACES zif_sy.
    INTERFACES zif_sy_user_info.

    "! Creates a system context bound to the current session.
    "! @parameter result | Context to be injected into the consuming class
    CLASS-METHODS create
      RETURNING VALUE(result) TYPE REF TO zif_sy.

    "! Creates the descriptive user information view of the current session.
    "! @parameter result | User information to be injected into the consuming class
    CLASS-METHODS create_user_info
      RETURNING VALUE(result) TYPE REF TO zif_sy_user_info.

ENDCLASS.


CLASS zcl_sy IMPLEMENTATION.

  METHOD create.
    result = NEW zcl_sy( ).
  ENDMETHOD.

  METHOD zif_sy~user_name.
    result = cl_abap_context_info=>get_user_technical_name( ).
  ENDMETHOD.

  METHOD zif_sy~language.
    result = xco_cp=>sy->language( )->value.
  ENDMETHOD.

  METHOD zif_sy~time_zone.
    result = xco_cp_time=>time_zone->user->value.
  ENDMETHOD.

  METHOD zif_sy~system_date.
    result = cl_abap_context_info=>get_system_date( ).
  ENDMETHOD.

  METHOD zif_sy~system_time.
    result = cl_abap_context_info=>get_system_time( ).
  ENDMETHOD.

  METHOD zif_sy~user_date.
    result = xco_cp=>sy->date( xco_cp_time=>time_zone->user )->as( xco_cp_time=>format->abap )->value.
  ENDMETHOD.

  METHOD zif_sy~user_time.
    result = xco_cp=>sy->time( xco_cp_time=>time_zone->user )->as( xco_cp_time=>format->abap )->value.
  ENDMETHOD.

  METHOD zif_sy~timestamp.
    result = utclong_current( ).
  ENDMETHOD.

  METHOD zif_sy~client.
    result = sy-mandt.
  ENDMETHOD.

  METHOD zif_sy~system_id.
    result = sy-sysid.
  ENDMETHOD.

  METHOD zif_sy~subrc.
    result = sy-subrc.
  ENDMETHOD.

  METHOD zif_sy~db_count.
    result = sy-dbcnt.
  ENDMETHOD.

  METHOD zif_sy~is_batch.
    result = xsdbool( sy-batch = abap_true ).
  ENDMETHOD.

  METHOD zif_sy~message.
    result = VALUE #( id         = sy-msgid
                      number     = sy-msgno
                      type       = sy-msgty
                      variable_1 = sy-msgv1
                      variable_2 = sy-msgv2
                      variable_3 = sy-msgv3
                      variable_4 = sy-msgv4 ).
  ENDMETHOD.

  METHOD create_user_info.
    result = NEW zcl_sy( ).
  ENDMETHOD.

  METHOD zif_sy_user_info~alias.
    result = cl_abap_context_info=>get_user_alias( ).
  ENDMETHOD.

  METHOD zif_sy_user_info~formatted_name.
    TRY.
        result = cl_abap_context_info=>get_user_formatted_name( ).
      CATCH cx_abap_context_info_error INTO DATA(lookup_error).
        RAISE EXCEPTION NEW zcx_sy( text     = `Formatted name of the current user could not be determined`
                                    previous = lookup_error ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_sy_user_info~language_iso.
    TRY.
        result = cl_abap_context_info=>get_user_language_iso_format( ).
      CATCH cx_abap_context_info_error INTO DATA(lookup_error).
        RAISE EXCEPTION NEW zcx_sy( text     = `ISO language of the current user could not be determined`
                                    previous = lookup_error ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
