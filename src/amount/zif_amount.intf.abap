"! ZIF_AMOUNT
"! <p class="shorttext synchronized" lang="EN">Currency amount</p>
"! An amount of money in one currency. Immutable: arithmetic, rounding and
"! conversion return a new amount while the original keeps its value. The
"! value is held in currency units, the way a user writes it - JPY 1000 is
"! 1000 here, not the 10.00 of a database field - so that rounding to the
"! decimals of the currency means what it says. as_internal( ) returns the
"! database representation for CURR fields.
INTERFACE zif_amount
  PUBLIC.

  CONSTANTS:
    "! Exchange rate types for convert_to( ). average (M) is the type every
    "! system maintains and the default; bank_buying (G) and bank_selling (B)
    "! are the classic bank rates. Any other type the system knows can be
    "! passed as well.
    BEGIN OF rate_type,
      average      TYPE cl_exchange_rates=>ty_convert_curr-kurst VALUE 'M',
      bank_buying  TYPE cl_exchange_rates=>ty_convert_curr-kurst VALUE 'G',
      bank_selling TYPE cl_exchange_rates=>ty_convert_curr-kurst VALUE 'B',
    END OF rate_type.

  "! Amounts to add up with sum( ) of {@link zcl_amount}.
  TYPES amounts TYPE STANDARD TABLE OF REF TO zif_amount WITH EMPTY KEY.

  "! Value in currency units, unrounded: JPY 1000 is 1000, KWD 1.234 is 1.234.
  "! @parameter result | The value as a decimal floating point number
  METHODS as_decimal
    RETURNING VALUE(result) TYPE decfloat34.

  "! Value as stored in a currency field (CURR) of the database, where every
  "! currency is kept with two decimals: JPY 1000 is 10.00, KWD 1.234 is 12.34.
  "! Assign it to the CURR field; round( ) first when the value may carry more
  "! decimals than the currency has.
  "! @parameter result | The value shifted to the database representation
  METHODS as_internal
    RETURNING VALUE(result) TYPE decfloat34.

  "! Currency of the amount.
  "! @parameter result | Currency key in upper case, for example EUR
  METHODS currency
    RETURNING VALUE(result) TYPE string.

  "! Number of decimals the currency has: 2 for EUR, 0 for JPY, 3 for KWD.
  "! @parameter result | Decimals as maintained for the currency
  METHODS decimals
    RETURNING VALUE(result) TYPE i.

  "! Rounds the value to the decimals of the currency. The default is
  "! commercial rounding: halves are rounded away from zero.
  "! @parameter mode   | One of the rounding constants of CL_ABAP_MATH, for example
  "!                     round_half_even for banker's rounding
  "! @parameter result | New amount with the rounded value
  METHODS round
    IMPORTING mode          TYPE i DEFAULT cl_abap_math=>round_half_up
    RETURNING VALUE(result) TYPE REF TO zif_amount.

  "! Tells whether the value has no more decimals than the currency.
  "! @parameter result | abap_true when round( ) would not change the value
  METHODS is_rounded
    RETURNING VALUE(result) TYPE abap_bool.

  "! Adds an amount of the same currency.
  "! @parameter other      | Amount to add
  "! @parameter result     | New amount with the sum, unrounded
  "! @raising   zcx_amount | The other amount is in a different currency
  METHODS add
    IMPORTING other         TYPE REF TO zif_amount
    RETURNING VALUE(result) TYPE REF TO zif_amount
    RAISING   zcx_amount.

  "! Subtracts an amount of the same currency.
  "! @parameter other      | Amount to subtract
  "! @parameter result     | New amount with the difference, unrounded
  "! @raising   zcx_amount | The other amount is in a different currency
  METHODS subtract
    IMPORTING other         TYPE REF TO zif_amount
    RETURNING VALUE(result) TYPE REF TO zif_amount
    RAISING   zcx_amount.

  "! Multiplies the value, for example by a quantity or a tax rate. The result
  "! keeps every decimal; call round( ) when the currency decimals are needed.
  "! @parameter factor | A number, or its text in technical format such as '0.19'
  "! @parameter result | New amount with the product, unrounded
  METHODS multiply_by
    IMPORTING factor        TYPE simple
    RETURNING VALUE(result) TYPE REF TO zif_amount.

  "! Reverses the sign.
  "! @parameter result | New amount with the negated value
  METHODS negate
    RETURNING VALUE(result) TYPE REF TO zif_amount.

  "! Tells whether the value is exactly zero.
  "! @parameter result | abap_true for a zero amount
  METHODS is_zero
    RETURNING VALUE(result) TYPE abap_bool.

  "! Tells whether the value is below zero.
  "! @parameter result | abap_true for a negative amount
  METHODS is_negative
    RETURNING VALUE(result) TYPE abap_bool.

  "! Compares value and currency. Amounts of different currencies are never
  "! equal; 1.5 and 1.50 of the same currency are.
  "! @parameter other  | Amount to compare with
  "! @parameter result | abap_true when currency and value are the same
  METHODS equals
    IMPORTING other         TYPE REF TO zif_amount
    RETURNING VALUE(result) TYPE abap_bool.

  "! Converts the amount into another currency through the released exchange
  "! rate service, with the rate of the given type valid on the given date.
  "! The value is rounded to the decimals of its currency before the
  "! conversion and the result is rounded to the decimals of the target
  "! currency. Converting into the own currency returns the amount unchanged.
  "! @parameter currency   | Target currency key, case insensitive
  "! @parameter date       | Date the exchange rate must be valid on
  "! @parameter rate_type  | Exchange rate type, one of the rate_type constants or any type the system knows
  "! @parameter result     | New amount in the target currency
  "! @raising   zcx_amount | The target currency is unknown, the date or the rate type is empty,
  "!                         no exchange rate is maintained, or the amount does not fit the
  "!                         amount fields of the service
  METHODS convert_to
    IMPORTING currency      TYPE csequence
              date          TYPE d
              rate_type     TYPE cl_exchange_rates=>ty_convert_curr-kurst DEFAULT rate_type-average
    RETURNING VALUE(result) TYPE REF TO zif_amount
    RAISING   zcx_amount.

  "! Renders the value rounded to the decimals of the currency, in the number
  "! format of the current user (decimal and thousands separators), with the
  "! sign in front: -1.234,57 for a German user.
  "! @parameter result | The value as text, without the currency
  METHODS as_text
    RETURNING VALUE(result) TYPE string.

  "! Renders the value like as_text( ) followed by a blank and the currency:
  "! -1.234,57 EUR for a German user.
  "! @parameter result | Value and currency as text
  METHODS as_text_with_currency
    RETURNING VALUE(result) TYPE string.

  "! Renders the value rounded to the decimals of the currency in technical
  "! format, for files and interfaces: decimal point, no thousands separator,
  "! sign in front: -1234.57.
  "! @parameter result | The value as technical text, without the currency
  METHODS as_raw_text
    RETURNING VALUE(result) TYPE string.

ENDINTERFACE.
