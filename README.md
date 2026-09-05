# ABAP Cloud Utilities
# Table of contents

1. [ABAP Cloud Utilities](#abap-cloud-utilities)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [License](#license)
5. [Contributors-Developers](#contributors-developers)
6. [Available Utilities](#available-utilities)
7. [Design Goals-Features](#design-goals-features)
8. [To-Do](#to-do)

# ABAP Cloud Utilities

A collection of small, self-contained ABAP classes and utilities for everyday
development on SAP S/4HANA and SAP BTP ABAP Environment.

Every utility is written against the **ABAP for Cloud Development** language
version, follows **Clean Core** principles, and consumes **released APIs only**.
Each one is independent — take the class you need, leave the rest.

# Prerequisites

* SAP S/4HANA 2023 (or higher) OR SAP BTP ABAP Environment
* ABAP language version: ABAP for Cloud Development
* XCO library availability
* Statement compatibility from v758 and Cloud

# Installation

Install via [abapGit](https://abapgit.org) into a package flagged as
**ABAP Cloud** in the customer namespace.

# License

This project is licensed under the [MIT License](https://github.com/greltel/abap-cloud-utilities/blob/main/LICENSE).

# Contributors-Developers

The repository was created by [George Drakos](https://www.linkedin.com/in/george-drakos/).

# Available Utilities

| Utility | Package | Entry point | Description |
|---|---|---|---|
| [XLSX](#xlsx) | `ZABAP_UTIL_XLSX` | `ZCL_XLSX` | Reads and writes XLSX workbooks on top of the released XCO XLSX APIs |
| [System variables](#system-variables) | `ZABAP_UTIL_SY` | `ZCL_SY` | Cloud-safe replacement for the classic `SY` structure |
| [JSON](#json) | `ZABAP_UTIL_JSON` | `ZCL_JSON` | Serializes ABAP data to JSON and back on top of the released XCO JSON APIs |
| [XString](#xstring) | `ZABAP_UTIL_XSTRING` | `ZCL_XSTRING` | Converts byte strings to and from text, Base64 and hexadecimal, and assembles them from parts |
| [String](#string) | `ZABAP_UTIL_STRING` | `ZCL_STRING` | Cuts a text into the parts a caller needs: fields, tokens, lines, chunks, pairs and enclosed text |
| [Date](#date) | `ZABAP_UTIL_DATE` | `ZCL_DATE` | Calendar arithmetic on ABAP dates: quarters, ISO weeks, boundaries and shifting |
| [HTTP](#http) | `ZABAP_UTIL_HTTP` | `ZCL_HTTP` | Fluent HTTP client on top of `IF_WEB_HTTP_CLIENT` with a mockable transport |
| [Email](#email) | `ZABAP_UTIL_EMAIL` | `ZCL_EMAIL` | Composes and sends emails on top of the released `CL_BCS_MAIL_MESSAGE` API |
| [Hash](#hash) | `ZABAP_UTIL_HASH` | `ZCL_HASH` | Message digests and HMAC on top of `CL_ABAP_MESSAGE_DIGEST` and `CL_ABAP_HMAC` |
| [UUID](#uuid) | `ZABAP_UTIL_UUID` | `ZCL_UUID` | Creates, parses and formats UUIDs on top of the released XCO UUID and `CL_SYSTEM_UUID` APIs |

Every utility follows the same shape: a facade class with factory methods as the
only entry point, the whole public surface on `ZIF_` interfaces so consumers can
mock it, immutable results, and errors surfacing through one `ZCX_` exception
class per utility. Each utility ships with its own ABAP Doc documentation and
unit tests.

## XLSX

Facade over the XCO XLSX APIs. `for_file_content` opens an existing workbook,
`empty` starts a new one. Errors surface through `ZCX_XLSX`.

| Interface | Purpose |
|---|---|
| `ZIF_XLSX_READER` | Reads sheets by name or position into an internal table |
| `ZIF_XLSX_WRITER` | Fluent builder that adds sheets from internal tables and returns the workbook as `xstring` |

```abap
DATA(workbook) = zcl_xlsx=>empty(
  )->add_sheet( sheet_name = `Orders` rows = orders
  )->get_file_content( ).

zcl_xlsx=>for_file_content( workbook )->read_sheet(
  EXPORTING sheet_name = `Orders`
  IMPORTING rows       = imported_orders ).
```

## System variables

Facade over `CL_ABAP_CONTEXT_INFO`, XCO and the `SY` fields that are readable in
ABAP for Cloud Development. `create` returns the fields that never fail,
`create_user_info` the descriptive user attributes that can. Errors surface
through `ZCX_SY`.

| Interface | Purpose |
|---|---|
| `ZIF_SY` | User, client, system, date, time, timestamp and message fields; never raises |
| `ZIF_SY_USER_INFO` | `alias( )`, `formatted_name( )`, `language_iso( )`; raises where the context API can fail |

```abap
DATA(sy) = zcl_sy=>create( ).

DATA(today) = sy->system_date( ).
DATA(user)  = sy->user_name( ).
DATA(stamp) = sy->timestamp( ).
```

## JSON

Facade over the XCO JSON APIs. `for_data` starts serialization, `for_string`
starts deserialization. Errors surface through `ZCX_JSON`.

| Interface | Purpose |
|---|---|
| `ZIF_JSON_WRITER` | Fluent: `as_camel_case( )`, `as_pascal_case( )`, closed with `to_string( )` |
| `ZIF_JSON_READER` | Fluent: `from_camel_case( )`, `from_pascal_case( )`, `booleans_to_abap_bool( )`, closed with `read_into( )` |

```abap
DATA(json) = zcl_json=>for_data( order )->as_camel_case( )->to_string( ).

zcl_json=>for_string( json
  )->from_camel_case(
  )->booleans_to_abap_bool(
  )->read_into( IMPORTING data = order ).
```

## XString

Facade over `CL_ABAP_CONV_CODEPAGE` and the XCO Base64 encoding, with one entry
point per input representation: `for_xstring`, `for_text`, `for_base64`,
`for_hex` and `builder`. Errors surface through `ZCX_XSTRING`.

| Interface | Purpose |
|---|---|
| `ZIF_XSTRING_READER` | Immutable view on a byte string: rendering as text, Base64 or hexadecimal, and positional access |
| `ZIF_XSTRING_WRITER` | Fluent builder that appends bytes, text, Base64 or hexadecimal and is closed with `build( )` |

```abap
DATA(base64) = zcl_xstring=>for_text( `Hello` )->as_base64( ).

DATA(payload) = zcl_xstring=>builder(
  )->append_hex( `EFBBBF`
  )->append_text( text = csv code_page = zcl_xstring=>code_page-utf_8
  )->build( )->as_xstring( ).
```

## String

Facade over the built-in string functions with a single entry point, `for_text`.
Operations that yield one text return a new `ZIF_STRING` and chain; operations
that yield several texts return a table. Errors surface through `ZCX_STRING`.

| Interface | Purpose |
|---|---|
| `ZIF_STRING` | Immutable view on a text: `split_by`, `split_tokens`, `split_lines`, `split_fixed`, `split_pairs`, `extract_between`, `extract_all_between`, `trim` |

```abap
DATA(tokens) = zcl_string=>for_text( raw )->trim( )->split_tokens( `,` ).

DATA(pairs) = zcl_string=>for_text( `COLOR=RED;SIZE=L` )->split_pairs( ).
```

## Date

Facade over native date arithmetic and the released XCO date API, with one entry
point per input representation: `for_date`, `for_iso` and `for_parts`. `is_valid`
checks an input without raising. Errors surface through `ZCX_DATE`.

| Interface | Purpose |
|---|---|
| `ZIF_DATE` | Immutable date: calendar parts, month, quarter, year and week boundaries, shifting by days, months and years, and questions such as `is_weekend( )` |

```abap
DATA(quarter_end) = zcl_date=>for_date( posting_date
                             )->last_day_of_quarter( )->as_date( ).

DATA(due_date) = zcl_date=>for_iso( `2026-01-31` )->add_months_ultimo( 1 )->as_iso( ).
```

## HTTP

Facade over `IF_WEB_HTTP_CLIENT`. `for_destination` takes any `IF_HTTP_DESTINATION`
and talks to the network; `for_transport` takes a `ZIF_HTTP_TRANSPORT` of your
own, which is how tests replace the network. Errors surface through `ZCX_HTTP`.

| Interface | Purpose |
|---|---|
| `ZIF_HTTP_CLIENT` | Opens a request per verb: `get`, `post`, `put`, `patch`, `delete` |
| `ZIF_HTTP_REQUEST_BUILDER` | Fluent: `query`, `header`, `bearer`, `basic_auth`, `json`, `text`, `binary`, `timeout`, closed by `send( )` |
| `ZIF_HTTP_RESPONSE` | Immutable answer: `status`, `is_success`, `ensure_success`, `header`, `text`, `binary` |
| `ZIF_HTTP_TRANSPORT` | One method, `send( request )`; the only place that touches the network |

```abap
DATA(response) = zcl_http=>for_destination( destination
                           )->post( `/rest/api/2/issue`
                           )->bearer( token
                           )->json( payload
                           )->send( )->ensure_success( ).
```

## Email

Facade over the released `CL_BCS_MAIL_MESSAGE` API. `compose` starts a message,
`sender` creates the object that hands it to the mail system. Errors surface
through `ZCX_EMAIL`.

| Interface | Purpose |
|---|---|
| `ZIF_EMAIL_BUILDER` | Fluent: `from`, `to`, `cc`, `bcc`, `subject`, `text`, `html`, `attach`, closed with `build( )` |
| `ZIF_EMAIL_MESSAGE` | Immutable message with an accessor for every part |
| `ZIF_EMAIL_SENDER` | `send( )` hands the message over; the seam consumers mock |

```abap
DATA(message) = zcl_email=>compose(
  )->from( `noreply@example.com`
  )->to( `jane.doe@example.com`
  )->subject( `Weekly report`
  )->text( `Please find the report attached.`
  )->attach( file_name    = `report.xlsx`
             bytes        = workbook
             content_type = zcl_email=>content_type-xlsx
  )->build( ).

zcl_email=>sender( )->send( message ).
```

## Hash

Facade over `CL_ABAP_MESSAGE_DIGEST` and `CL_ABAP_HMAC` with one entry point per
algorithm: `md5`, `sha_1`, `sha_256`, `sha_384`, `sha_512`, or `for_algorithm` for
any name the system knows. Errors surface through `ZCX_HASH`.

| Interface | Purpose |
|---|---|
| `ZIF_HASHER` | Immutable algorithm: `of_text( )`, `of_bytes( )`; `keyed_with( )` returns the HMAC variant |
| `ZIF_HASH` | Immutable digest: `as_xstring( )`, `as_hex( )`, `as_base64( )`, and constant-time comparison through `equals( )` and `matches_hex( )` |

```abap
DATA(checksum) = zcl_hash=>sha_256( )->of_bytes( payload )->as_hex( ).

DATA(signature) = zcl_hash=>sha_256( )->keyed_with_text( shared_secret
                                     )->of_text( body )->as_base64( ).
```

## UUID

Facade with three entry points: `new` creates an identifier, `for_x16` wraps the
16 raw bytes of an existing key, and `for_text` parses any character format.
`generator` returns the object behind `new` for injection. Errors surface through
`ZCX_UUID`.

| Interface | Purpose |
|---|---|
| `ZIF_UUID` | Immutable identifier: `as_x16( )`, `as_c22( )`, `as_c32( )`, `as_c36( )`, `is_nil( )`, `equals( )` |
| `ZIF_UUID_GENERATOR` | One method, `next( )`; inject it into the class that assigns keys and replace it with a double in tests |

```abap
DATA(order_id) = zcl_uuid=>new( )->as_x16( ).

DATA(external) = zcl_uuid=>for_x16( order_id )->as_c36( ).
DATA(incoming) = zcl_uuid=>for_text( `baf0a1e7-5fb0-1edf-b5e8-89f53894ca3a` ).
```

# Design Goals-Features

* ABAP Cloud / Clean Core compatibility — passes the ATC variant `ABAP_CLOUD_DEVELOPMENT_DEFAULT`
* Released APIs only (release contract C1) — no access to SAP standard tables, no non-released function modules
* Clean Code following the [Clean ABAP Style Guides](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md)
* Modern ABAP syntax (7.58 / 9.14) — expressions, inline declarations, string templates
* Interface-based public surface, so every utility can be mocked in consumer tests
* Unit tested with ABAP Unit and `CL_ABAP_TESTDOUBLE`
* Documented with ABAP Doc on every public declaration
* No cross-dependencies between utilities — install only what you need

# To-Do

Utilities planned for the next iterations:

- **Number range** — hands out numbers from a customer number range object on top of the released `CL_NUMBERRANGE_RUNTIME`
- **CSV** — reads and writes CSV text to and from internal tables, with quoting, embedded delimiters and line breaks, and an optional header row
- **XML** — reads and writes XML on top of the released `CL_SXML_STRING_READER` and `CL_SXML_STRING_WRITER`
- **Regular expressions** — reusable, named and tested pattern building blocks on top of `CL_ABAP_REGEX` and `CL_ABAP_MATCHER`
- **String formatting** — padding, alignment, case conversion and template helpers
