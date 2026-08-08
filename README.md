# ABAP Cloud Utilities
# Table of contents

1. [ABAP Cloud Utilities](#abap-cloud-utilities)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [License](#license)
5. [Contributors-Developers](#contributors-developers)
6. [Motivation for Creating the Repository](#motivation-for-creating-the-repository)
7. [Available Utilities](#available-utilities)
8. [Design Goals-Features](#design-goals-features)
9. [To-Do](#to-do)

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
| XLSX | `ZABAP_UTIL_XLSX` | `ZCL_XLSX` | Reads and writes XLSX workbooks on top of the released XCO XLSX APIs. Split into `ZIF_XLSX_READER` and `ZIF_XLSX_WRITER` so a consumer depends only on the direction it needs. Errors surface through `ZCX_XLSX`. |
| System variables | `ZABAP_UTIL_SY` | `ZCL_SY` | Cloud-safe replacement for the classic `SY` structure. `ZIF_SY` never raises and covers user, client, system, date, time and message fields; `ZIF_SY_USER_INFO` adds the descriptive user attributes that can fail and surface through `ZCX_SY`. |
| JSON | `ZABAP_UTIL_JSON` | `ZCL_JSON` | Serializes ABAP data to JSON and back on top of the released XCO JSON APIs. Split into `ZIF_JSON_READER` and `ZIF_JSON_WRITER` so a consumer depends only on the direction it needs. Errors surface through `ZCX_JSON`. |

Each utility ships with its own ABAP Doc documentation and unit tests.

## XLSX

Facade over the XCO XLSX APIs with a factory entry point.

| Interface | Purpose |
|---|---|
| `ZIF_XLSX_READER` | Opens a workbook from `xstring` and reads sheets and cell ranges |
| `ZIF_XLSX_WRITER` | Builds a workbook from internal tables and returns it as `xstring` |

Known limitation: worksheet renaming is constrained on ABAP 7.58, so a generated
workbook can still carry the default `Sheet1` name.

## System variables

`ZIF_SY` is the single place in a code base that touches `sy`. Consumers inject
the interface instead of reading system fields, which makes them mockable with
`CL_ABAP_TESTDOUBLE`.

| `SY` field | `ZIF_SY` | Source |
|---|---|---|
| `SY-UNAME` | `user_name( )` | `CL_ABAP_CONTEXT_INFO` |
| `SY-LANGU` | `language( )` | XCO |
| `SY-ZONLO` | `time_zone( )` | XCO |
| `SY-DATUM` | `system_date( )` | `CL_ABAP_CONTEXT_INFO` |
| `SY-UZEIT` | `system_time( )` | `CL_ABAP_CONTEXT_INFO` |
| `SY-DATLO` | `user_date( )` | XCO |
| `SY-TIMLO` | `user_time( )` | XCO |
| — | `timestamp( )` | `utclong_current( )` |
| `SY-MANDT` | `client( )` | `SY` |
| `SY-SYSID` | `system_id( )` | `SY` |
| `SY-SUBRC` | `subrc( )` | `SY` |
| `SY-DBCNT` | `db_count( )` | `SY` |
| `SY-BATCH` | `is_batch( )` | `SY` |
| `SY-MSGID` … `SY-MSGV4` | `message( )` | `SY` |

`ZIF_SY_USER_INFO` adds `alias( )`, `formatted_name( )` and `language_iso( )`.
The last two raise `ZCX_SY` because the underlying context API can fail.

Not covered on purpose: `SY-INDEX` and `SY-TABIX` are bound to the loop of the
calling processing block, so a wrapper method would return a different value than
the caller expects — read them directly. `SY-ABCDE`, `SY-SAPRL`, `SY-DBSYS` and
`SY-OPSYS` are not readable in ABAP for Cloud Development at all.

## JSON

Facade over the XCO JSON APIs with a factory entry point.

| Interface | Purpose |
|---|---|
| `ZIF_JSON_WRITER` | Serializes any ABAP data object into a JSON string, optionally transforming the member names to camelCase or PascalCase |
| `ZIF_JSON_READER` | Deserializes a JSON string into an ABAP data object; JSON booleans arrive as `abap_bool` |
| `ZIF_JSON_TYPES` | Naming convention shared by both directions: `unchanged`, `camel_case`, `pascal_case` |

Known limitations on this release: `abap_bool` fields serialize as the strings
`"X"` / `""` because XCO offers no ABAP-to-boolean transformation for the
outbound direction, and components typed `REF TO` cannot be filled from JSON —
the reader rejects such targets up front instead of letting XCO end in the
runtime error `XML_FORMAT_ERROR`.

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

* **String parsing** — splitting, trimming, padding, formatting helpers
* **XString parsing** — binary / xstring conversion and inspection helpers
* **Regular expressions** — reusable, named and tested pattern building blocks
* **Date functions** — quarter, week, first and last day helpers on top of `XCO_CP_TIME`
