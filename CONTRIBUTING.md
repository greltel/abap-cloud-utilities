# Contributing

Thanks for considering a contribution. This document describes the shape every
utility in this repository follows and the bar a change must clear before it is
merged. It is written as a set of checkable statements; the
[Definition of Done](#definition-of-done) at the end is the summary a reviewer
works from.

The reference implementation is the **UUID** module (`src/uuid`): small, and it
shows every part of the pattern. **ZIP** (`src/zip`) shows the same pattern with
several interfaces and a fluent builder.

## Table of contents

1. [Scope](#scope)
2. [Before you start](#before-you-start)
3. [Anatomy of a utility](#anatomy-of-a-utility)
4. [Naming](#naming)
5. [Code rules](#code-rules)
6. [Tests](#tests)
7. [ABAP Doc and release contracts](#abap-doc-and-release-contracts)
8. [README convention](#readme-convention)
9. [Workflow](#workflow)
10. [Skeleton](#skeleton)
11. [Definition of Done](#definition-of-done)

## Scope

A utility belongs here when all of the following hold:

- It solves one everyday development problem (dates, strings, archives, ...),
  not a business process.
- It is written in the **ABAP for Cloud Development** language version and
  consumes **released SAP APIs only** (release contract C1).
- It is **self-contained**: one package, no dependency on any other utility in
  this repository, no dependency on customer tables or configuration.
- It activates on SAP S/4HANA 2023 (on-premise and private cloud) and on
  SAP BTP ABAP Environment.

Out of scope: anything that needs an unreleased API, a database table, RAP
artefacts, or a UI.

## Before you start

- **New utility or new public method** — open an issue first and describe the
  problem it solves and the released API it will sit on. This avoids work on
  something that will not be accepted.
- **Bug fix, documentation, test** — open a pull request directly.
- Verify the released state of every SAP API you intend to use *before* writing
  code: the **API State** tab in ADT, or the
  [steampunk-2302 stubs](https://github.com/abapedia/steampunk-2302-api) that
  abaplint uses as its dependency. If an API is not released, do not use it;
  there is no exception to this rule.

## Anatomy of a utility

Every utility lives in `src/<module>/` and consists of the objects below.
`<module>` is a short lower-case noun (`uuid`, `zip`, `string_format`).

| Object | Name | Role |
|---|---|---|
| Package | `ZABAP_UTIL_<MODULE>` | One package per utility; description `ABAP Cloud Utility for <Name>` |
| Facade | `ZCL_<MODULE>` | `FINAL`, `CREATE PRIVATE`; only `CLASS-METHODS` factories in the public section, each returning an interface reference. It holds no logic. |
| Interfaces | `ZIF_<MODULE>`, `ZIF_<MODULE>_<ROLE>` | The whole public surface. Split by consumer role (interface segregation), never one interface with everything |
| Exception | `ZCX_<MODULE>` | One class, `INHERITING FROM cx_static_check`, `FINAL`; constructor takes `text` and an optional `previous`; `get_text` is redefined to return `text` |
| Implementation | `lcl_*` in the facade's **Local Types** (CCIMP) | All logic. Global classes are interfaces plus one facade; consumers never see an `lcl_*` |
| Seam | `lif_*` in CCIMP | Every call to the external SAP API goes through one local interface with one real adapter (`lcl_*`) — see [Tests](#tests) |
| Tests | `ltc_*` in the facade's **Test Classes** (CCAU) | ABAP Unit; exercises the utility through the public interfaces only |
| Demo | `ZCL_<MODULE>_DEMO` | Implements `IF_OO_ADT_CLASSRUN`; runnable with F9; shows the happy path and one rejected input |
| Release contracts | `*.apis.xml` per public object | C1 contract on facade, interfaces and exception — **not** on the demo |

Results returned to consumers are immutable value objects behind an interface.
Fluent builders return `self` and are closed with a terminal method (`build( )`,
`send( )`); the chain never raises — the first mistake is reported by the
terminal method.

## Naming

- Global objects use the module prefix consistently: `ZCL_ZIP`, `ZIF_ZIP_ARCHIVE`,
  `ZCX_ZIP`, `ZCL_ZIP_DEMO`.
- Interfaces name the **role** the consumer sees (`ZIF_ZIP_BUILDER`,
  `ZIF_UUID_GENERATOR`), not the implementation.
- Local classes: `lcl_*`, local interfaces `lif_*`, test classes `ltc_*`,
  test doubles `ltd_*`, test helpers `lth_*`.
- Method names are behaviour, not implementation (`for_text`, `with_level`,
  `extract_all`); returning parameters are named `result`, or `self` in a fluent
  chain. No Hungarian prefixes anywhere.
- **Filename collisions.** This repository is listed on dotabap.org, which
  refuses two projects shipping a file with the same name. A GitHub Action
  checks every push. If your object name collides with another listed project,
  insert `ACU_` after the prefix (`ZCL_ACU_JSON`) and keep the module name
  otherwise unchanged. Run `python scripts/check_name_collisions.py` locally
  before the first push of a new module.

## Code rules

**abaplint is the authority.** `abaplint.json` in the repository root encodes
Clean ABAP for this project; a pull request must produce **zero issues** with it
and with the stricter syntax pass (see [Workflow](#workflow)). Do not add
pragmas or pseudo-comments to silence a rule — fix the code, or open an issue if
you believe the rule is wrong.

Beyond the linter, the following conventions apply:

- Modern syntax only: inline declarations, `NEW`, `VALUE`, `CORRESPONDING`,
  string templates, `xsdbool( )`, `line_exists( )`, table expressions.
  `RAISE EXCEPTION NEW zcx_<module>( ... )`, never `MESSAGE ... RAISING`.
- No magic literals in production code. Named constants carry the *meaning*
  (`c22_length`), not the value.
- Methods do one thing, stay under ~20 lines, take at most three importing
  parameters, and have names of at most 30 characters.
- `SY` components other than `SY-SUBRC`, `SY-TABIX` and `SY-INDEX` are not read
  in utilities; system context comes from `cl_abap_context_info`.
- `TEST-SEAM` / `TEST-INJECTION` are not used, even though they compile.
  Testability comes from the local seam interface.

**What abaplint does not catch.** These pass the linter and fail at activation
or at runtime. Activate in ADT and run the demo before you push.

- Offset/length access on a `STRING` or `XSTRING` (`text+2(3)`) cannot be used
  inline as a method argument or in a functional expression. Assign it to a
  local variable first.
- A functional call is not a valid operand of a predicate:
  `IF condense( text ) IS INITIAL` does not compile. Assign to a variable, then
  test the variable.
- Multi-line `IF` conditions formatted by ABAP Cleaner violate the
  `in_statement_indentation` rule. Decompose into named `xsdbool( )` variables
  and test those.
- `SY-INDEX` and `SY-TABIX` must never be wrapped in a method; their value is
  bound to the calling processing block.
- `SPLIT ... INTO TABLE` drops trailing empty segments. Pad explicitly when all
  parts are needed.
- Some XCO operations throw exceptions that cannot be caught (for example date
  calculation with the `PRESERVING` strategy, and the JSON engine on malformed
  input). Validate the input *before* the call and raise `ZCX_<MODULE>` yourself.
- `DECFLOAT16` / `DECFLOAT34` are written as zero by XCO XLSX. Reject them with a
  clear error rather than producing a silently wrong file.
- Every `*.xml` metadata file must start with a UTF-8 BOM (abapGit writes it;
  do not strip it in your editor). abaplint enforces this with the `xml_bom` rule.

## Tests

Tests are mandatory for every public method and every error path. They live in
the facade's Test Classes include and follow these rules:

- `FOR TESTING RISK LEVEL HARMLESS DURATION SHORT`, class `FINAL`.
- One behaviour per method, named `given_..._when_..._then_...` (drop the part
  that is trivial), at most 30 characters.
- Arrange / Act / Assert visible in the body. Every assertion carries a `msg`
  that says what is wrong when it fails, in plain language.
- Tests call the utility through `ZCL_<MODULE>` and its `ZIF_` interfaces —
  never an `lcl_*` directly.
- Every reason that raises `ZCX_<MODULE>` has a test that expects the exception
  and checks the message text is meaningful.
- No real database, RFC, HTTP, mail, clock or authority check inside a test.

**The seam pattern.** All calls to the external SAP API a utility wraps go
through one local interface, typically named after that API (`lif_bcs_mail`,
`lif_runtime`). Production code gets the real adapter from the facade; tests
inject a recording fake (`ltd_*`) through a constructor parameter or a package-
visible factory in CCIMP. This keeps the tests deterministic and lets them run
without the SAP API being reachable. The **Email** and **Number range** modules
are the reference for this pattern.

The GitHub Action *ABAP Unit Testing* transpiles each module with
[abaplint/transpiler](https://github.com/abaplint/transpiler) and runs its
tests off-stack. It is **informational**: open-abap does not implement the XCO
APIs, so modules built on XCO are reported as *blocked*. The gate for tests is
a green run in ADT (`Ctrl+Shift+F10`) on a 2023 system, with a screenshot of the
result attached to the pull request.

## ABAP Doc and release contracts

- Every global class, interface, method, parameter and exception has ABAP Doc
  (`"!`). The first line of a class or interface is the synchronized short text:
  `"! <p class="shorttext synchronized" lang="EN">UUID utility</p>`.
- Method documentation says what the method does for the consumer and documents
  every `@parameter` and `@raising`. Do not repeat the signature in words.
- Use `{@link zcl_uuid}` to reference other objects; the demo class links to the
  facade it showcases.
- Local classes get a one-paragraph ABAP Doc that explains *why* they exist,
  not what each method does.
- After activation, release the facade, every `ZIF_` interface and the `ZCX_`
  exception with **release contract C1**, use in Cloud Platform ticked, in ADT
  (*Properties → API State*). abapGit serializes this as
  `<object>.<type>.apis.xml`; commit those files. The demo class is **not**
  released.

## README convention

Adding a utility means exactly three edits to `README.md`; do not touch anything
else in the file.

1. Add one row to the table in **Available Utilities** (utility, package, entry
   point, one-sentence description).
2. Add a `## <Utility name>` section immediately before `# Design Goals-Features`:
   a prose paragraph on what it does and how errors surface, a table of its
   interfaces and their purpose, and one usage snippet.
3. Remove the corresponding bullet from **To-Do**, if there was one.

Improving an existing utility means editing its section and, when the surface
changed, its interface table.

## Workflow

1. Fork, then branch from `main`: `feature/<module>` or `fix/<module>-<topic>`.
2. Develop in ADT, in a package flagged **ABAP Cloud**, on a 2023 system.
   Activate everything; run the demo class with F9.
3. Run the unit tests in ADT; all green.
4. Lint locally from the repository root:

   ```bash
   npm install
   npm run lint                       # abaplint.json, must report 0 issues
   sed 's/"check_syntax": false/"check_syntax": true/' abaplint.json > abaplint_strict.json
   npx abaplint abaplint_strict.json  # stricter pass, must also report 0 issues
   ```

   Do not commit `abaplint_strict.json`.
5. For a new module: `python scripts/check_name_collisions.py`.
6. Update `README.md` (see above) and add an entry under **Unreleased** in
   `CHANGELOG.md`.
7. Push through abapGit. Commit messages start with the module name:
   `zip: add gzip codec`, `date: fix quarter boundary on leap years`,
   `docs: describe the seam pattern`.
8. Open the pull request with the Definition of Done checklist filled in and
   the ADT unit test result attached.

Small, focused pull requests are reviewed quickly. One module, one improvement,
or one fix per pull request.

## Skeleton

A minimal utility with the complete shape. Replace `example` with your module
name and grow from here. The `lif_*` seam and its fake are shown in comments
where they go; look at `src/email` for a full one.

**Interface — `zif_example.intf.abap`**

```abap
"! <p class="shorttext synchronized" lang="EN">Example value</p>
"! Immutable view on a text produced by {@link zcl_example}.
INTERFACE zif_example
  PUBLIC.

  "! The text in upper case.
  "! @parameter result | Upper-case text
  METHODS as_upper
    RETURNING VALUE(result) TYPE string.

ENDINTERFACE.
```

**Exception — `zcx_example.clas.abap`**

```abap
"! <p class="shorttext synchronized" lang="EN">Example processing error</p>
"! Raised when the input text cannot be processed.
CLASS zcx_example DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Creates the exception with a technical description of the failure.
    "! @parameter text     | What could not be done
    "! @parameter previous | Original exception, when a foreign one is wrapped
    METHODS constructor
      IMPORTING text     TYPE string
                previous TYPE REF TO cx_root OPTIONAL.

    METHODS get_text REDEFINITION.

  PRIVATE SECTION.
    DATA description TYPE string.

ENDCLASS.


CLASS zcx_example IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    description = text.
  ENDMETHOD.

  METHOD get_text.
    result = description.
  ENDMETHOD.

ENDCLASS.
```

**Facade — `zcl_example.clas.abap`**

```abap
"! <p class="shorttext synchronized" lang="EN">Example utility</p>
"! Entry point for the example utility. Standalone - depends on nothing but
"! SAP released APIs.
CLASS zcl_example DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Wraps a text. Blank text is rejected.
    "! @parameter text        | Text to wrap
    "! @parameter result      | Immutable view on the text
    "! @raising   zcx_example | The text is blank
    CLASS-METHODS for_text
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE REF TO zif_example
      RAISING   zcx_example.

ENDCLASS.


CLASS zcl_example IMPLEMENTATION.

  METHOD for_text.
    result = NEW lcl_example( text ).
  ENDMETHOD.

ENDCLASS.
```

**Local Types (CCIMP) — `zcl_example.clas.locals_imp.abap`**

```abap
"! Holds the validated text. Validation happens once, in the constructor, so
"! every method can trust the value it works on.
CLASS lcl_example DEFINITION FINAL.

  PUBLIC SECTION.
    INTERFACES zif_example.

    METHODS constructor
      IMPORTING text TYPE string
      RAISING   zcx_example.

  PRIVATE SECTION.
    DATA text TYPE string.

ENDCLASS.


CLASS lcl_example IMPLEMENTATION.

  METHOD constructor.
    DATA(trimmed) = condense( text ).
    IF trimmed IS INITIAL.
      RAISE EXCEPTION NEW zcx_example( `The text is blank` ).
    ENDIF.
    me->text = trimmed.
  ENDMETHOD.

  METHOD zif_example~as_upper.
    result = to_upper( text ).
  ENDMETHOD.

ENDCLASS.
```

When the utility wraps a SAP API, add `INTERFACE lif_<api>` here with the
methods you actually call, one `lcl_<api>_adapter` implementing it with the
real API, and let `lcl_example` receive the `lif_<api>` reference in its
constructor.

**Test Classes (CCAU) — `zcl_example.clas.testclasses.abap`**

```abap
CLASS ltc_example DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS given_text_when_upper_then_caps FOR TESTING RAISING zcx_example.
    METHODS given_blank_then_raises FOR TESTING.

ENDCLASS.


CLASS ltc_example IMPLEMENTATION.

  METHOD given_text_when_upper_then_caps.
    DATA(cut) = zcl_example=>for_text( `abc` ).

    DATA(upper) = cut->as_upper( ).

    cl_abap_unit_assert=>assert_equals(
      act = upper
      exp = `ABC`
      msg = 'The text is not returned in upper case' ).
  ENDMETHOD.

  METHOD given_blank_then_raises.
    TRY.
        zcl_example=>for_text( `   ` ).
        cl_abap_unit_assert=>fail( 'Blank text was accepted' ).
      CATCH zcx_example INTO DATA(error).
        cl_abap_unit_assert=>assert_not_initial(
          act = error->get_text( )
          msg = 'The exception carries no message' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
```

**Demo — `zcl_example_demo.clas.abap`**

```abap
"! <p class="shorttext synchronized" lang="EN">Example utility demo</p>
"! Runnable showcase for {@link zcl_example}. Start it with F9 in ADT.
CLASS zcl_example_demo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

ENDCLASS.


CLASS zcl_example_demo IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    TRY.
        out->write( zcl_example=>for_text( `hello` )->as_upper( ) ).
        zcl_example=>for_text( ` ` ).
      CATCH zcx_example INTO DATA(error).
        out->write( |Rejected as expected: { error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
```

## Definition of Done

Copy this list into the pull request description and tick every box.

- [ ] Released SAP APIs only; API State verified in ADT for each one
- [ ] Package `ZABAP_UTIL_<MODULE>`, no dependency on other utilities
- [ ] Facade `ZCL_<MODULE>` is `CREATE PRIVATE` with factory methods only; all logic in CCIMP
- [ ] Public surface entirely on `ZIF_` interfaces; errors surface only through `ZCX_<MODULE>`
- [ ] External SAP API isolated behind a `lif_*` seam with a fake used in tests
- [ ] ABAP Unit tests for every public method and every error path; green in ADT (screenshot attached)
- [ ] Demo class `ZCL_<MODULE>_DEMO` runs with F9 and shows happy path and a rejected input
- [ ] ABAP Doc on every public declaration
- [ ] Release contract C1 on facade, interfaces and exception; `*.apis.xml` committed; demo not released
- [ ] `npm run lint` and the `check_syntax: true` pass both report 0 issues
- [ ] `scripts/check_name_collisions.py` passes (new modules)
- [ ] `README.md` updated per the README convention
- [ ] `CHANGELOG.md` entry added under **Unreleased**
- [ ] Commit messages prefixed with the module name
