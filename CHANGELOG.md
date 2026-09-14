# Changelog

All notable changes to this repository are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and versions follow
[Semantic Versioning](https://semver.org/spec/v2.0.0.html); one version covers
the whole repository, so a tag pins every utility at once. The rules for what
bumps which part of the version are in
[CONTRIBUTING.md](CONTRIBUTING.md#releasing).

Entries are grouped per module and name the public objects that changed.

## [Unreleased]

## [1.0.0] - 2026-09-14

First tagged release. Everything below was on `main` before tags were
introduced; later releases list only what changed.

### Added

- **Amount** (`ZABAP_UTIL_AMOUNT`, `ZCL_AMOUNT`, `ZIF_AMOUNT`, `ZCX_AMOUNT`) —
  immutable currency amounts that round to the decimals of their currency,
  convert through `CL_EXCHANGE_RATES`, move between currency units and the
  database representation, and render for output.
- **CSV** (`ZABAP_UTIL_CSV`, `ZCL_CSV`, `ZIF_CSV_READER`, `ZIF_CSV_WRITER`,
  `ZCX_CSV`) — RFC 4180 reading and writing to and from internal tables, with
  quoting, embedded delimiters and line breaks, and an optional header row.
- **Date** (`ZABAP_UTIL_DATE`, `ZCL_ACU_DATE`, `ZIF_ACU_DATE`,
  `ZIF_ACU_CALENDAR`, `ZCX_DATE`) — calendar arithmetic on ABAP dates:
  quarters, ISO weeks, boundaries, shifting by days, months and years, and
  working days on a factory calendar through `CL_FHC_CALENDAR_RUNTIME`
  (`is_working_day`, `add_working_days`, `next_working_day`,
  `previous_working_day`).
- **Email** (`ZABAP_UTIL_EMAIL`, `ZCL_EMAIL`, `ZIF_EMAIL_BUILDER`,
  `ZIF_EMAIL_MESSAGE`, `ZIF_EMAIL_SENDER`, `ZCX_EMAIL`) — composes and sends
  emails on top of `CL_BCS_MAIL_MESSAGE`.
- **Hash** (`ZABAP_UTIL_HASH`, `ZCL_HASH`, `ZIF_HASH`, `ZIF_HASHER`,
  `ZCX_HASH`) — message digests and HMAC on top of `CL_ABAP_MESSAGE_DIGEST`
  and `CL_ABAP_HMAC`.
- **HTTP** (`ZABAP_UTIL_HTTP`, `ZCL_HTTP`, `ZIF_HTTP_CLIENT`,
  `ZIF_HTTP_REQUEST`, `ZIF_HTTP_REQUEST_BUILDER`, `ZIF_HTTP_RESPONSE`,
  `ZIF_HTTP_TRANSPORT`, `ZCX_HTTP`) — fluent HTTP client on top of
  `IF_WEB_HTTP_CLIENT` with a mockable transport.
- **JSON** (`ZABAP_UTIL_JSON`, `ZCL_ACU_JSON`, `ZIF_JSON_READER`,
  `ZIF_JSON_WRITER`, `ZIF_JSON_NODE`, `ZCX_ACU_JSON`) — serialization of ABAP
  data to JSON and back on top of the XCO JSON APIs, with camelCase and
  PascalCase member names and JSON booleans for `abap_bool` components
  (`abap_bool_to_booleans`); `parse` reads a document of unknown shape into a
  tree navigated by member name and position.
- **Lock** (`ZABAP_UTIL_LOCK`, `ZCL_LOCK`, `ZIF_LOCK`, `ZIF_LOCK_REQUEST`,
  `ZCX_LOCK`) — sets and releases locks of a customer lock object on top of
  `CL_ABAP_LOCK_OBJECT_FACTORY`, with a mockable seam to the lock server.
- **Number range** (`ZABAP_UTIL_NUMBER_RANGE`, `ZCL_ACU_NUMBER_RANGE`,
  `ZIF_NUMBER_RANGE`, `ZCX_NUMBER_RANGE`) — hands out numbers from a customer
  number range object on top of `CL_NUMBERRANGE_RUNTIME`.
- **Regular expressions** (`ZABAP_UTIL_REGEX`, `ZCL_REGEX`, `ZIF_REGEX`,
  `ZIF_REGEX_MATCH`, `ZIF_REGEX_PATTERNS`, `ZCX_REGEX`) — compiles PCRE
  patterns into reusable expressions on top of `CL_ABAP_REGEX` and
  `CL_ABAP_MATCHER`, with a set of named, tested patterns.
- **String** (`ZABAP_UTIL_STRING`, `ZCL_STRING`, `ZIF_STRING`, `ZCX_STRING`)
  — cuts a text into fields, tokens, lines, chunks, pairs and enclosed text.
- **String formatting** (`ZABAP_UTIL_STRING_FORMAT`, `ZCL_STRING_FORMAT`,
  `ZIF_STRING_FORMAT`, `ZIF_STRING_TEMPLATE`, `ZCX_STRING_FORMAT`) — pads,
  aligns, cuts and case-converts a text, and renders templates with named
  placeholders.
- **System variables** (`ZABAP_UTIL_SY`, `ZCL_SY`, `ZIF_SY`,
  `ZIF_SY_USER_INFO`, `ZCX_SY`) — cloud-safe replacement for the classic `SY`
  structure.
- **UUID** (`ZABAP_UTIL_UUID`, `ZCL_UUID`, `ZIF_UUID`, `ZIF_UUID_GENERATOR`,
  `ZCX_UUID`) — creates, parses and formats UUIDs on top of the XCO UUID and
  `CL_SYSTEM_UUID` APIs.
- **XLSX** (`ZABAP_UTIL_XLSX`, `ZCL_XLSX`, `ZIF_XLSX_READER`,
  `ZIF_XLSX_WRITER`, `ZCX_XLSX`) — reads and writes XLSX workbooks on top of
  the XCO XLSX APIs.
- **XML** (`ZABAP_UTIL_XML`, `ZCL_XML`, `ZIF_XML_DOCUMENT`, `ZIF_XML_NODE`,
  `ZIF_XML_BUILDER`, `ZCX_XML`) — reads and writes XML documents on top of
  `CL_SXML_STRING_READER` and `CL_SXML_STRING_WRITER`, navigated by element
  name and built with a fluent builder.
- **XString** (`ZABAP_UTIL_XSTRING`, `ZCL_XSTRING`, `ZIF_XSTRING_READER`,
  `ZIF_XSTRING_WRITER`, `ZCX_XSTRING`) — converts byte strings to and from
  text, Base64 and hexadecimal, and assembles them from parts.
- **ZIP** (`ZABAP_UTIL_ZIP`, `ZCL_ZIP`, `ZIF_ZIP_ARCHIVE`, `ZIF_ZIP_BUILDER`,
  `ZIF_GZIP`, `ZCX_ZIP`) — builds, lists and extracts ZIP archives and
  compresses GZIP streams on top of `CL_ABAP_ZIP` and `CL_ABAP_GZIP`.
- Repository: abaplint configuration with the steampunk-2302 API stubs,
  dotabap.org name-collision check, off-stack ABAP Unit runner (informational),
  `CONTRIBUTING.md`.

[Unreleased]: https://github.com/greltel/abap-cloud-utilities/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/greltel/abap-cloud-utilities/releases/tag/v1.0.0
