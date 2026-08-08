"! <p class="shorttext synchronized" lang="EN">Runnable demo for the system context</p>
"! Prints every value offered by {@link zif_sy}. Start it with F9 in ADT.
CLASS zcl_sy_demo DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    DATA context TYPE REF TO zif_sy.

    DATA user_info TYPE REF TO zif_sy_user_info.

    "! Prints the descriptive user information.
    "! @parameter out | Console of the class runner
    METHODS write_user_info
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    "! Prints user and system identification.
    "! @parameter out | Console of the class runner
    METHODS write_identity
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    "! Prints date, time and time stamp values.
    "! @parameter out | Console of the class runner
    METHODS write_moment
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    "! Prints the technical runtime values.
    "! @parameter out | Console of the class runner
    METHODS write_runtime
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

ENDCLASS.


CLASS zcl_sy_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    context   = zcl_sy=>create( ).
    user_info = zcl_sy=>create_user_info( ).

    write_identity( out ).
    write_user_info( out ).
    write_moment( out ).
    write_runtime( out ).
  ENDMETHOD.

  METHOD write_user_info.
    out->write( |Alias: { user_info->alias( ) }| ).

    TRY.
        out->write( |Formatted name: { user_info->formatted_name( ) }| ).
        out->write( |Language ISO: { user_info->language_iso( ) }| ).
      CATCH zcx_sy INTO DATA(error).
        out->write( |User info not available: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD write_identity.
    out->write( |User name: { context->user_name( ) }| ).
    out->write( |Language: { context->language( ) }| ).
    out->write( |Time zone: { context->time_zone( ) }| ).
    out->write( |Client: { context->client( ) }| ).
    out->write( |System: { context->system_id( ) }| ).
  ENDMETHOD.

  METHOD write_moment.
    out->write( |System date: { context->system_date( ) DATE = ISO }| ).
    out->write( |System time: { context->system_time( ) TIME = ISO }| ).
    out->write( |User date: { context->user_date( ) DATE = ISO }| ).
    out->write( |User time: { context->user_time( ) TIME = ISO }| ).
    out->write( |Time stamp: { context->timestamp( ) TIMESTAMP = ISO }| ).
  ENDMETHOD.

  METHOD write_runtime.
    out->write( |Return code: { context->subrc( ) }| ).
    out->write( |Database count: { context->db_count( ) }| ).
    out->write( |Background: { context->is_batch( ) }| ).

    DATA(last_message) = context->message( ).
    out->write( |Message: { last_message-type }{ last_message-id } { last_message-number }| ).
  ENDMETHOD.

ENDCLASS.
