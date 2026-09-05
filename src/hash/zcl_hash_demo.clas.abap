"! <p class="shorttext synchronized" lang="EN">Hash utility demo</p>
"! Runnable showcase for {@link zcl_hash}. Start it with F9 in ADT.
CLASS zcl_hash_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    CONSTANTS payload TYPE string VALUE `Clean Core`.
    CONSTANTS shared_secret TYPE string VALUE `s3cr3t`.

    METHODS show_digests
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_hash.

    METHODS show_keyed_digest
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_hash.

    METHODS show_verification
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out
      RAISING   zcx_hash.

    METHODS show_rejected_input
      IMPORTING out TYPE REF TO if_oo_adt_classrun_out.

    METHODS as_yes_no
      IMPORTING flag          TYPE abap_bool
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_hash_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        show_digests( out ).
        show_keyed_digest( out ).
        show_verification( out ).
        show_rejected_input( out ).
      CATCH zcx_hash INTO DATA(error).
        out->write( |Hash demo failed: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD show_digests.
    DATA(digest) = zcl_hash=>sha_256( )->of_text( payload ).

    out->write( `--- Digests ---` ).
    out->write( |Algorithm  : { digest->algorithm( ) }| ).
    out->write( |Bytes      : { digest->length( ) }| ).
    out->write( |Hex        : { digest->as_hex( ) }| ).
    out->write( |Base64     : { digest->as_base64( ) }| ).
    out->write( |MD5        : { zcl_hash=>md5( )->of_text( payload )->as_hex( ) }| ).
    out->write( |By name    : { zcl_hash=>for_algorithm( `sha1` )->of_text( payload )->as_hex( ) }| ).
  ENDMETHOD.

  METHOD show_keyed_digest.
    DATA(signer) = zcl_hash=>sha_256( )->keyed_with_text( shared_secret ).

    out->write( `--- Keyed digest ---` ).
    out->write( |Algorithm  : { signer->name( ) }| ).
    out->write( |Signature  : { signer->of_text( payload )->as_base64( ) }| ).
  ENDMETHOD.

  METHOD show_verification.
    DATA(signer) = zcl_hash=>sha_256( )->keyed_with_text( shared_secret ).
    DATA(received) = signer->of_text( payload )->as_hex( ).
    DATA(recalculated) = signer->of_text( payload ).

    out->write( `--- Verification ---` ).
    out->write( |Genuine    : { as_yes_no( recalculated->matches_hex( received ) ) }| ).
    out->write( |Tampered   : { as_yes_no( signer->of_text( |{ payload }!| )->matches_hex( received ) ) }| ).
  ENDMETHOD.

  METHOD show_rejected_input.
    out->write( `--- Rejected input ---` ).

    TRY.
        zcl_hash=>for_algorithm( `ROT13` ).

        out->write( `An unknown algorithm was unexpectedly accepted` ).
      CATCH zcx_hash INTO DATA(rejection).
        out->write( |Rejected as expected: { rejection->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD as_yes_no.
    result = COND string( WHEN flag = abap_true THEN `yes`
                          ELSE `no` ).
  ENDMETHOD.

ENDCLASS.

