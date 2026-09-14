*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
TYPES currency_key TYPE cl_exchange_rates=>ty_convert_curr-fcurr.
TYPES rate_type TYPE cl_exchange_rates=>ty_convert_curr-kurst.

"! Amount as the exchange rate service takes and returns it: the database
"! representation with two decimals, in a packed field wide enough for the
"! 23-digit amount fields of S/4HANA.
TYPES api_amount TYPE p LENGTH 12 DECIMALS 2.

TYPES:
  "! The state of one amount: the value in currency units, the currency and
  "! its decimals, resolved once when the amount is created.
  BEGIN OF money,
    value    TYPE decfloat34,
    currency TYPE currency_key,
    decimals TYPE i,
  END OF money.

TYPES:
  "! One conversion request for the exchange rate service. The amount is in
  "! the database representation, as the service expects it.
  BEGIN OF conversion,
    amount    TYPE api_amount,
    currency  TYPE currency_key,
    target    TYPE currency_key,
    date      TYPE d,
    rate_type TYPE rate_type,
  END OF conversion.


"! Normalises and checks a currency key before it reaches the released APIs.
"! Their key type has a fixed length, so a key that is too long would be cut
"! silently and address the wrong currency.
CLASS lcl_currency_key DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS of
      IMPORTING value         TYPE csequence
      RETURNING VALUE(result) TYPE currency_key
      RAISING   zcx_amount.

  PRIVATE SECTION.
    CONSTANTS key_length TYPE i VALUE 5.

ENDCLASS.


"! Turns what a caller passes as a value into the decimal floating point
"! number the amount works with, and reports what is not a number.
CLASS lcl_number DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS of
      IMPORTING value         TYPE simple
      RETURNING VALUE(result) TYPE decfloat34
      RAISING   zcx_amount.

ENDCLASS.


"! Moves a value between currency units and the database representation of a
"! currency field, which keeps every currency with two decimals: JPY 1000 is
"! stored as 10.00, KWD 1.234 as 12.34. Powers of ten are exact in decimal
"! floating point, so the shift loses nothing.
CLASS lcl_scale DEFINITION FINAL.

  PUBLIC SECTION.
    CLASS-METHODS to_internal
      IMPORTING value         TYPE decfloat34
                decimals      TYPE i
      RETURNING VALUE(result) TYPE decfloat34.

    CLASS-METHODS to_external
      IMPORTING value         TYPE decfloat34
                decimals      TYPE i
      RETURNING VALUE(result) TYPE decfloat34.

  PRIVATE SECTION.
    CONSTANTS field_decimals TYPE i VALUE 2.
    CONSTANTS ten TYPE decfloat34 VALUE 10.

    CLASS-METHODS shifted
      IMPORTING value         TYPE decfloat34
                places        TYPE i
      RETURNING VALUE(result) TYPE decfloat34.

ENDCLASS.


"! Seam to the currency master data. Kept as thin as possible so that
"! everything above it can be tested with a double.
INTERFACE lif_currencies.

  METHODS decimals_of
    IMPORTING currency      TYPE currency_key
    RETURNING VALUE(result) TYPE i
    RAISING   zcx_amount.

ENDINTERFACE.


"! The only class that reads I_Currency. Decimals are cached for the session:
"! amounts are created in loops, and the answer for a currency never changes
"! while a program runs.
CLASS lcl_currencies DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES lif_currencies.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF cached_currency,
        currency TYPE currency_key,
        decimals TYPE i,
      END OF cached_currency.
    TYPES cached_currencies TYPE HASHED TABLE OF cached_currency WITH UNIQUE KEY currency.

    " Currencies with two decimals have no entry in the decimals table, which
    " the view exposes as a null value
    CONSTANTS default_decimals TYPE i VALUE 2.

    CLASS-DATA cache TYPE cached_currencies.

    CLASS-METHODS read
      IMPORTING currency      TYPE currency_key
      RETURNING VALUE(result) TYPE i
      RAISING   zcx_amount.

ENDCLASS.


"! Seam to the exchange rate service, one method per API call. Kept as thin
"! as possible so that everything above it can be tested with a double.
INTERFACE lif_rates.

  METHODS convert
    IMPORTING conversion    TYPE conversion
    RETURNING VALUE(result) TYPE api_amount
    RAISING   cx_exchange_rates.

ENDINTERFACE.


"! The only class that calls CL_EXCHANGE_RATES.
CLASS lcl_rates DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES lif_rates.

ENDCLASS.


"! One amount. Immutable: every operation hands a new state to a new instance
"! that shares the collaborators.
CLASS lcl_amount DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_amount.

    METHODS constructor
      IMPORTING money      TYPE money
                currencies TYPE REF TO lif_currencies
                rates      TYPE REF TO lif_rates.

  PRIVATE SECTION.
    DATA money TYPE money.
    DATA currencies TYPE REF TO lif_currencies.
    DATA rates TYPE REF TO lif_rates.
    " Largest value a packed amount with 23 digits and two decimals can hold;
    " the exchange rate service works with such fields
    CONSTANTS api_amount_limit TYPE decfloat34 VALUE '1E21'.

    METHODS with_value
      IMPORTING value         TYPE decfloat34
      RETURNING VALUE(result) TYPE REF TO zif_amount.

    METHODS rounded_value
      IMPORTING mode          TYPE i
      RETURNING VALUE(result) TYPE decfloat34.

    METHODS ensure_same_currency
      IMPORTING other TYPE REF TO zif_amount
      RAISING   zcx_amount.

    METHODS request_for
      IMPORTING target        TYPE currency_key
                date          TYPE d
                rate_type     TYPE rate_type
      RETURNING VALUE(result) TYPE conversion
      RAISING   zcx_amount.

    METHODS converted
      IMPORTING conversion    TYPE conversion
      RETURNING VALUE(result) TYPE api_amount
      RAISING   zcx_amount.

ENDCLASS.


CLASS lcl_currency_key IMPLEMENTATION.

  METHOD of.
    DATA(key) = to_upper( condense( value ) ).

    IF key IS INITIAL.
      RAISE EXCEPTION NEW zcx_amount( `Currency key is empty` ).
    ENDIF.

    IF strlen( key ) > key_length.
      RAISE EXCEPTION NEW zcx_amount( |Currency key { key } exceeds { key_length } characters| ).
    ENDIF.

    result = key.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_number IMPLEMENTATION.

  METHOD of.
    TRY.
        result = CONV decfloat34( value ).
      CATCH cx_sy_conversion_error INTO DATA(error).
        RAISE EXCEPTION NEW zcx_amount( text     = |Value '{ value }' is not a number|
                                        previous = error ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_scale IMPLEMENTATION.

  METHOD to_internal.
    result = shifted( value  = value
                      places = decimals - field_decimals ).
  ENDMETHOD.

  METHOD to_external.
    result = shifted( value  = value
                      places = field_decimals - decimals ).
  ENDMETHOD.

  METHOD shifted.
    DATA(factor) = ipow( base = ten
                         exp  = abs( places ) ).

    result = COND #( WHEN places < 0
                     THEN value / factor
                     ELSE value * factor ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_currencies IMPLEMENTATION.

  METHOD lif_currencies~decimals_of.
    DATA(known) = VALUE #( cache[ currency = currency ] OPTIONAL ).

    IF known IS NOT INITIAL.
      result = known-decimals.
      RETURN.
    ENDIF.

    result = read( currency ).

    INSERT VALUE #( currency = currency
                    decimals = result ) INTO TABLE cache.
  ENDMETHOD.

  METHOD read.
    SELECT SINGLE FROM i_currency
          FIELDS decimals
          WHERE currency = @currency
            AND decimals IS NOT NULL
          INTO @result.

    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    " No entry in the decimals table: the currency has two decimals - if it
    " exists at all
    SELECT SINGLE FROM i_currency
      FIELDS currency
      WHERE currency = @currency
      INTO @DATA(known) ##NEEDED.

    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW zcx_amount( |Currency { currency } is unknown| ).
    ENDIF.

    result = default_decimals.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_rates IMPLEMENTATION.

  METHOD lif_rates~convert.
    cl_exchange_rates=>convert_to_local_currency( EXPORTING date             = conversion-date
                                                            foreign_amount   = conversion-amount
                                                            foreign_currency = conversion-currency
                                                            local_currency   = conversion-target
                                                            rate_type        = conversion-rate_type
                                                  IMPORTING local_amount     = result ).
  ENDMETHOD.

ENDCLASS.


CLASS lcl_amount IMPLEMENTATION.

  METHOD constructor.
    me->money = money.
    me->currencies = currencies.
    me->rates = rates.
  ENDMETHOD.

  METHOD zif_amount~as_decimal.
    result = money-value.
  ENDMETHOD.

  METHOD zif_amount~as_internal.
    result = lcl_scale=>to_internal( value    = money-value
                                     decimals = money-decimals ).
  ENDMETHOD.

  METHOD zif_amount~currency.
    result = money-currency.
  ENDMETHOD.

  METHOD zif_amount~decimals.
    result = money-decimals.
  ENDMETHOD.

  METHOD zif_amount~round.
    result = with_value( rounded_value( mode ) ).
  ENDMETHOD.

  METHOD zif_amount~is_rounded.
    result = xsdbool( money-value = rounded_value( cl_abap_math=>round_half_up ) ).
  ENDMETHOD.

  METHOD zif_amount~add.
    ensure_same_currency( other ).

    result = with_value( money-value + other->as_decimal( ) ).
  ENDMETHOD.

  METHOD zif_amount~subtract.
    ensure_same_currency( other ).

    result = with_value( money-value - other->as_decimal( ) ).
  ENDMETHOD.

  METHOD zif_amount~multiply_by.
    result = with_value( money-value * factor ).
  ENDMETHOD.

  METHOD zif_amount~negate.
    result = with_value( - money-value ).
  ENDMETHOD.

  METHOD zif_amount~is_zero.
    result = xsdbool( money-value = 0 ).
  ENDMETHOD.

  METHOD zif_amount~is_negative.
    result = xsdbool( money-value < 0 ).
  ENDMETHOD.

  METHOD zif_amount~equals.
    result = xsdbool( other->currency( ) = zif_amount~currency( ) AND other->as_decimal( ) = money-value ).
  ENDMETHOD.

  METHOD zif_amount~convert_to.
    DATA(target) = lcl_currency_key=>of( currency ).

    IF target = money-currency.
      result = me.
      RETURN.
    ENDIF.

    DATA(target_decimals) = currencies->decimals_of( target ).
    DATA(target_amount) = converted( request_for( target    = target
                                                  date      = date
                                                  rate_type = rate_type ) ).

    DATA(target_value) = lcl_scale=>to_external( value    = CONV decfloat34( target_amount )
                                                 decimals = target_decimals ).

    result = NEW lcl_amount( money      = VALUE #( value    = target_value
                                                   currency = target
                                                   decimals = target_decimals )
                             currencies = currencies
                             rates      = rates ).
  ENDMETHOD.

  METHOD zif_amount~as_text.
    result = |{ rounded_value( cl_abap_math=>round_half_up ) SIGN = LEFT NUMBER = USER DECIMALS = money-decimals }|.
  ENDMETHOD.

  METHOD zif_amount~as_text_with_currency.
    result = |{ zif_amount~as_text( ) } { zif_amount~currency( ) }|.
  ENDMETHOD.

  METHOD zif_amount~as_raw_text.
    result = |{ rounded_value( cl_abap_math=>round_half_up ) SIGN = LEFT NUMBER = RAW DECIMALS = money-decimals }|.
  ENDMETHOD.

  METHOD with_value.
    result = NEW lcl_amount( money      = VALUE #( BASE money value = value )
                             currencies = currencies
                             rates      = rates ).
  ENDMETHOD.

  METHOD rounded_value.
    result = round( val  = money-value
                    dec  = money-decimals
                    mode = mode ).
  ENDMETHOD.

  METHOD ensure_same_currency.
    IF other->currency( ) <> zif_amount~currency( ).
      DATA(text) = |Amounts in { zif_amount~currency( ) } and { other->currency( ) } cannot be combined|.
      RAISE EXCEPTION NEW zcx_amount( |{ text }| ).
    ENDIF.
  ENDMETHOD.

  METHOD request_for.
    IF date IS INITIAL.
      RAISE EXCEPTION NEW zcx_amount( `Exchange rate date is empty` ).
    ENDIF.

    IF rate_type IS INITIAL.
      RAISE EXCEPTION NEW zcx_amount( `Exchange rate type is empty` ).
    ENDIF.

    DATA(internal) = zif_amount~round( )->as_internal( ).

    IF abs( internal ) >= api_amount_limit.
      DATA(text) = CONV string( 'does not fit the amounts of the exchange rate service' ).
      RAISE EXCEPTION NEW zcx_amount( |{ zif_amount~as_text_with_currency( ) } { text }| ).
    ENDIF.

    result = VALUE #( amount    = internal
                      currency  = money-currency
                      target    = target
                      date      = date
                      rate_type = rate_type ).
  ENDMETHOD.

  METHOD converted.
    TRY.
        result = rates->convert( conversion ).
      CATCH cx_exchange_rates INTO DATA(refusal).
        DATA(description) = |{ zif_amount~as_text_with_currency( ) } to { conversion-target }|.

        RAISE EXCEPTION NEW zcx_amount( text     = |{ description } could not be converted: { refusal->get_text( ) }|
                                        previous = refusal ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
