# abap-cloud-utilities
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
Each one is independent. Take the class you need, leave the rest.

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

| Utility | Description |
|---|---|
| _(to be published)_ | See [To-Do](#to-do) for what is coming next |

Each utility ships with its own ABAP Doc documentation and unit tests.

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

* **JSON utility** — serialization / deserialization helpers on top of XCO
* **String parsing** — splitting, trimming, padding, formatting helpers
* **XString parsing** — binary / xstring conversion and inspection helpers
* **Regular expressions** — reusable, named and tested pattern building blocks
* **System variables** — Cloud-safe replacements for the classic `SY-*` fields
