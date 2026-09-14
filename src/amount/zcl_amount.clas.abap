"! ZCL_AMOUNT
"! <p class="shorttext synchronized" lang="EN">Currency amount utility</p>
"! Entry point for currency amounts: rounding to the decimals of a currency,
"! arithmetic, conversion through the released CL_EXCHANGE_RATES and rendering
"! for output. Currency decimals are read from the released view I_Currency.
"! Standalone - depends on nothing but SAP released APIs.
CLASS zcl_amount DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Creates an amount from a value in currency units, the way a user
    "! writes it: 1000 for JPY 1000, '1.234' for KWD 1.234. Use of_internal( )
    "! for a value read from a currency field of the database.
    "! @parameter value      | A number, or its text in technical format such as '1234.57'
    "! @parameter currency   | Currency key, case insensitive
    "! @parameter result     | The amount, unrounded
    "! @raising   zcx_amount | The value is not a number or the currency is unknown
    CLASS-METHODS of
      IMPORTING value         TYPE simple
                currency      TYPE csequence
      RETURNING VALUE(result) TYPE REF TO zif_amount
      RAISING   zcx_amount.

    "! Creates an amount from a value as stored in a currency field (CURR) of
    "! the database, where every currency is kept with two decimals: 10.00
    "! for JPY 1000, 12.34 for KWD 1.234. For currencies with two decimals
    "! this is the same as of( ).
    "! @parameter value      | The content of the currency field
    "! @parameter currency   | Currency key of the field, case insensitive
    "! @parameter result     | The amount in currency units
    "! @raising   zcx_amount | The value is not a number or the currency is unknown
    CLASS-METHODS of_internal
      IMPORTING value         TYPE simple
                currency      TYPE csequence
      RETURNING VALUE(result) TYPE REF TO zif_amount
      RAISING   zcx_amount.

    "! Creates a zero amount, for example as the start of a total.
    "! @parameter currency   | Currency key, case insensitive
    "! @parameter result     | The zero amount
    "! @raising   zcx_amount | The currency is unknown
    CLASS-METHODS zero
      IMPORTING currency      TYPE csequence
      RETURNING VALUE(result) TYPE REF TO zif_amount
      RAISING   zcx_amount.

    "! Adds up amounts of one currency. An empty table yields zero.
    "! @parameter amounts    | Amounts to add up
    "! @parameter currency   | Currency every amount must have, case insensitive
    "! @parameter result     | The total, unrounded
    "! @raising   zcx_amount | The currency is unknown or an amount is in another currency
    CLASS-METHODS sum
      IMPORTING amounts       TYPE zif_amount=>amounts
                currency      TYPE csequence
      RETURNING VALUE(result) TYPE REF TO zif_amount
      RAISING   zcx_amount.

    "! Number of decimals of a currency: 2 for EUR, 0 for JPY, 3 for KWD.
    "! @parameter currency   | Currency key, case insensitive
    "! @parameter result     | Decimals as maintained for the currency
    "! @raising   zcx_amount | The currency is unknown
    CLASS-METHODS decimals_of
      IMPORTING currency      TYPE csequence
      RETURNING VALUE(result) TYPE i
      RAISING   zcx_amount.

  PRIVATE SECTION.
    CLASS-METHODS assemble
      IMPORTING value         TYPE decfloat34
                currency      TYPE csequence
                decimals      TYPE i
      RETURNING VALUE(result) TYPE REF TO zif_amount.

ENDCLASS.


CLASS zcl_amount IMPLEMENTATION.

  METHOD of.
    DATA(key) = lcl_currency_key=>of( currency ).
    DATA(number) = lcl_number=>of( value ).

    result = assemble( value    = number
                       currency = key
                       decimals = decimals_of( key ) ).
  ENDMETHOD.

  METHOD of_internal.
    DATA(key) = lcl_currency_key=>of( currency ).
    DATA(number) = lcl_number=>of( value ).
    DATA(decimals) = decimals_of( key ).

    result = assemble( value    = lcl_scale=>to_external( value    = number
                                                          decimals = decimals )
                       currency = key
                       decimals = decimals ).
  ENDMETHOD.

  METHOD zero.
    DATA(key) = lcl_currency_key=>of( currency ).

    result = assemble( value    = 0
                       currency = key
                       decimals = decimals_of( key ) ).
  ENDMETHOD.

  METHOD sum.
    result = REDUCE #( INIT total = zero( currency )
                       FOR amount IN amounts
                       NEXT total = total->add( amount ) ).
  ENDMETHOD.

  METHOD decimals_of.
    result = NEW lcl_currencies( )->lif_currencies~decimals_of( lcl_currency_key=>of( currency ) ).
  ENDMETHOD.

  METHOD assemble.
    result = NEW lcl_amount( money      = VALUE #( value    = value
                                                   currency = currency
                                                   decimals = decimals )
                             currencies = NEW lcl_currencies( )
                             rates      = NEW lcl_rates( ) ).
  ENDMETHOD.

ENDCLASS.
