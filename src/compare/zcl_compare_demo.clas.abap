"! <p class="shorttext synchronized" lang="EN">Compare utility demo</p>
"! Runnable showcase for {@link zcl_compare}. Start it with F9 in ADT.
CLASS zcl_compare_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    TYPES ty_order_id TYPE n LENGTH 10.
    TYPES ty_status TYPE c LENGTH 1.
    TYPES ty_price TYPE p LENGTH 7 DECIMALS 2.
    TYPES ty_country TYPE c LENGTH 2.
    TYPES ty_notes TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_address,
        city    TYPE string,
        country TYPE ty_country,
      END OF ty_address.
    TYPES:
      BEGIN OF ty_order,
        order_id        TYPE ty_order_id,
        status          TYPE ty_status,
        net_price       TYPE ty_price,
        delivery_date   TYPE d,
        ship_to         TYPE ty_address,
        notes           TYPE ty_notes,
        last_changed_by TYPE string,
        last_changed_on TYPE d,
      END OF ty_order.
    TYPES ty_orders TYPE STANDARD TABLE OF ty_order WITH EMPTY KEY.
    TYPES:
      "! The shape of %control in a RAP derived type: one flag per field of the entity.
      BEGIN OF ty_order_control,
        status        TYPE abp_behv_flag,
        net_price     TYPE abp_behv_flag,
        delivery_date TYPE abp_behv_flag,
        ship_to       TYPE abp_behv_flag,
        notes         TYPE abp_behv_flag,
      END OF ty_order_control.

    CONSTANTS order_id TYPE ty_order_id VALUE '0000004711'.
    CONSTANTS status_open TYPE ty_status VALUE 'O'.
    CONSTANTS status_confirmed TYPE ty_status VALUE 'C'.
    CONSTANTS old_price TYPE ty_price VALUE '100.00'.
    CONSTANTS new_price TYPE ty_price VALUE '120.50'.
    CONSTANTS delivery_date TYPE d VALUE '20260301'.
    CONSTANTS old_city TYPE string VALUE `Athens`.
    CONSTANTS new_city TYPE string VALUE `Lamia`.
    CONSTANTS country TYPE ty_country VALUE 'GR'.
    CONSTANTS first_note TYPE string VALUE `Deliver to the back entrance`.
    CONSTANTS second_note TYPE string VALUE `Call before delivery`.
    CONSTANTS clerk TYPE string VALUE `ANNA`.
    CONSTANTS interface_user TYPE string VALUE `ORDER_API`.
    CONSTANTS created_on TYPE d VALUE '20260115'.
    CONSTANTS changed_on TYPE d VALUE '20260116'.
    CONSTANTS field_status TYPE string VALUE `STATUS`.
    CONSTANTS field_delivery_date TYPE string VALUE `DELIVERY_DATE`.
    CONSTANTS field_ship_to TYPE string VALUE `SHIP_TO`.
    CONSTANTS field_changed_by TYPE string VALUE `LAST_CHANGED_BY`.
    CONSTANTS field_changed_on TYPE string VALUE `LAST_CHANGED_ON`.
    CONSTANTS field_unknown TYPE string VALUE `GROSS_PRICE`.
    CONSTANTS text_yes TYPE string VALUE `yes`.
    CONSTANTS text_no TYPE string VALUE `no`.

    METHODS show_changes
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_compare.

    METHODS show_ignore_list
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_compare.

    METHODS show_single_components
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_compare.

    METHODS show_control_structure
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_compare.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS order_on_database
      RETURNING VALUE(result) TYPE ty_order.

    METHODS order_from_caller
      RETURNING VALUE(result) TYPE ty_order.

    METHODS business_fields
      RETURNING VALUE(result) TYPE REF TO zif_compare
      RAISING   zcx_compare.

    METHODS answer
      IMPORTING flag          TYPE abap_bool
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_compare_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_changes( out ).
        show_ignore_list( out ).
        show_single_components( out ).
        show_control_structure( out ).
        show_rejected_input( out ).
      CATCH zcx_compare INTO DATA(error).
        out->write( |Compare demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_changes.
    DATA(difference) = zcl_compare=>difference( before = order_on_database( )
                                                after  = order_from_caller( ) ).

    out->write( `--- An order on the database and the one a caller sent: every component that differs ---` ).
    out->write( difference->changes( ) ).
  ENDMETHOD.

  METHOD show_ignore_list.
    DATA(saved_again) = order_on_database( ).
    saved_again-last_changed_by = interface_user.
    saved_again-last_changed_on = changed_on.

    DATA(comparison) = business_fields( ).
    DATA(difference) = comparison->difference( before = order_on_database( )
                                               after  = order_from_caller( ) ).
    DATA(nothing_new) = comparison->difference( before = order_on_database( )
                                                after  = saved_again ).

    out->write( `--- The same comparison with the administrative fields on the ignore list ---` ).
    out->write( difference->changes( ) ).
    out->write( |Saved again without a change - anything to update: { answer( nothing_new->has_changes( ) ) }| ).
  ENDMETHOD.

  METHOD show_single_components.
    DATA(difference) = business_fields( )->difference( before = order_on_database( )
                                                       after  = order_from_caller( ) ).

    out->write( `--- Questions about single components, a nested structure counted as one ---` ).
    out->write( |{ field_status } changed: { answer( difference->has_changed( field_status ) ) }| ).
    out->write( |{ field_ship_to } changed: { answer( difference->has_changed( field_ship_to ) ) }| ).
    out->write( |{ field_delivery_date } changed: { answer( difference->has_changed( field_delivery_date ) ) }| ).
  ENDMETHOD.

  METHOD show_control_structure.
    DATA control TYPE ty_order_control.

    DATA(difference) = business_fields( )->difference( before = order_on_database( )
                                                       after  = order_from_caller( ) ).

    " With a behavior definition at hand the target is REF #( update-%control ).
    difference->write_control( REF #( control ) ).

    out->write( `--- The changed fields marked in a structure shaped like %control: 01 is on, 00 is off ---` ).
    out->write( control ).
  ENDMETHOD.

  METHOD show_rejected_input.
    DATA(orders) = VALUE ty_orders( ( order_on_database( ) ) ).

    out->write( `--- Rejected input ---` ).

    TRY.
        zcl_compare=>difference( before = orders
                                 after  = orders ).

        out->write( `Two internal tables were unexpectedly compared component by component` ).
      CATCH zcx_compare INTO DATA(rejection).
        out->write( rejection->get_text( ) ).
    ENDTRY.

    TRY.
        DATA(changed) = zcl_compare=>difference( before = order_on_database( )
                                                 after  = order_from_caller( ) )->has_changed( field_unknown ).

        out->write( |A component the order does not have was unexpectedly answered: { answer( changed ) }| ).
      CATCH zcx_compare INTO rejection.
        out->write( rejection->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD order_on_database.
    result = VALUE #( order_id        = order_id
                      status          = status_open
                      net_price       = old_price
                      delivery_date   = delivery_date
                      ship_to         = VALUE #( city    = old_city
                                                 country = country )
                      notes           = VALUE #( ( first_note ) )
                      last_changed_by = clerk
                      last_changed_on = created_on ).
  ENDMETHOD.

  METHOD order_from_caller.
    result = VALUE #( order_id        = order_id
                      status          = status_confirmed
                      net_price       = new_price
                      delivery_date   = delivery_date
                      ship_to         = VALUE #( city    = new_city
                                                 country = country )
                      notes           = VALUE #( ( first_note ) ( second_note ) )
                      last_changed_by = interface_user
                      last_changed_on = changed_on ).
  ENDMETHOD.

  METHOD business_fields.
    result = zcl_compare=>builder( )->ignoring( field_changed_by
                                   )->ignoring( field_changed_on
                                   )->build( ).
  ENDMETHOD.

  METHOD answer.
    result = COND #( WHEN flag = abap_true THEN text_yes ELSE text_no ).
  ENDMETHOD.

ENDCLASS.
