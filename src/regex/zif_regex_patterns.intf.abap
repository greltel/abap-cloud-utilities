"! <p class="shorttext synchronized" lang="EN">Named regular expression patterns</p>
"! Ready-made, unit tested PCRE patterns for everyday validation. Every pattern
"! is anchored with ^ and $, so it validates a whole value, and every one is
"! free of whitespace, so it behaves the same with and without extended mode.
"! Use them through {@link zcl_regex}, or directly in the ABAP string functions
"! and FIND / REPLACE statements. They check the shape of a value, not its
"! meaning: an ISO date pattern accepts the 31st of February.
INTERFACE zif_regex_patterns
  PUBLIC.

  "! Email address in the everyday form name at domain: exactly one at sign, a dotted
  "! domain and a top level domain of at least two letters. Deliberately
  "! simpler than RFC 5322.
  CONSTANTS email TYPE string
    VALUE `^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,}$`.

  "! Absolute http or https URL: scheme, host, optional port and optional path
  "! or query without whitespace.
  CONSTANTS url TYPE string
    VALUE `^https?://[A-Za-z0-9.-]+(:[0-9]{1,5})?(/[^\s]*)?$`.

  "! IPv4 address in dotted decimal notation, each octet 0 to 255 without
  "! leading zeros.
  CONSTANTS ipv4 TYPE string
    VALUE `^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])` &
          `(\.(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])){3}$`.

  "! UUID in the 8-4-4-4-12 hexadecimal form with hyphens, either case.
  CONSTANTS uuid TYPE string
    VALUE `^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$`.

  "! Calendar date in ISO 8601 form YYYY-MM-DD with month 01 to 12 and day 01
  "! to 31. Shape only, the day is not checked against the month.
  CONSTANTS iso_date TYPE string
    VALUE `^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$`.

  "! Time of day in ISO 8601 form HH:MM or HH:MM:SS on a 24 hour clock.
  CONSTANTS iso_time TYPE string
    VALUE `^([01][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$`.

  "! Whole number with an optional sign: digits only, no separators.
  CONSTANTS integer TYPE string
    VALUE `^[+-]?[0-9]+$`.

  "! Decimal number with an optional sign and a dot as decimal separator: 12,
  "! 12.5, -0.25 and .5 pass, 12. and 1,5 do not.
  CONSTANTS decimal TYPE string
    VALUE `^[+-]?([0-9]+(\.[0-9]+)?|\.[0-9]+)$`.

  "! Hexadecimal digits in either case, at least one.
  CONSTANTS hex TYPE string
    VALUE `^[0-9A-Fa-f]+$`.

  "! Latin letters and digits only, at least one character.
  CONSTANTS alphanumeric TYPE string
    VALUE `^[A-Za-z0-9]+$`.

  "! IBAN in electronic form without blanks: two letter country code, two check
  "! digits and 11 to 30 alphanumeric characters. Shape only, the check digits
  "! are not verified.
  CONSTANTS iban TYPE string
    VALUE `^[A-Z]{2}[0-9]{2}[A-Z0-9]{11,30}$`.

  "! Semantic version MAJOR.MINOR.PATCH with optional pre-release and build
  "! parts, for example 2.1.0, 2.1.0-beta.1 or 2.1.0+build.7.
  CONSTANTS semantic_version TYPE string
    VALUE `^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$`.

ENDINTERFACE.
