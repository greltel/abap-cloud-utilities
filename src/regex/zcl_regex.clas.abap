"! <p class="shorttext synchronized" lang="EN">Regular expression utility</p>
"! Entry point for compiling PCRE patterns into reusable expressions. Standalone -
"! depends on nothing but the released CL_ABAP_REGEX and CL_ABAP_MATCHER APIs.
"! Ready-made patterns live in {@link zif_regex_patterns}.
CLASS zcl_regex DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    "! Switches that change how a pattern is compiled. All are off by default.
    TYPES:
      BEGIN OF ty_options,
        "! Letters match regardless of case
        ignore_case TYPE abap_bool,
        "! ^ and $ also match at line breaks inside the text, not only at its ends
        multiline   TYPE abap_bool,
        "! The dot also matches line break characters
        dot_all     TYPE abap_bool,
        "! Free-spacing mode: whitespace in the pattern is ignored and # starts a comment
        extended    TYPE abap_bool,
      END OF ty_options.

    "! Compiles a PCRE pattern. Whitespace in the pattern is significant, as in
    "! most other languages; switch on the extended option for the free-spacing
    "! mode that the ABAP statements FIND PCRE and REPLACE PCRE use by default.
    "! Compile a pattern once and keep the expression, the compiled form is
    "! what makes repeated use cheap.
    "! @parameter pattern   | PCRE pattern, not empty
    "! @parameter options   | Compilation switches, all off when omitted
    "! @parameter result    | Compiled expression
    "! @raising   zcx_regex | The pattern is empty or not a valid regular expression
    CLASS-METHODS of
      IMPORTING pattern       TYPE string
                options       TYPE ty_options OPTIONAL
      RETURNING VALUE(result) TYPE REF TO zif_regex
      RAISING   zcx_regex.

    "! Escapes a text so that a pattern matches it character by character.
    "! Use it to embed user input or file names in a pattern without giving
    "! dots, brackets or other metacharacters a meaning.
    "! @parameter text   | Text to match literally
    "! @parameter result | Pattern fragment matching exactly that text
    CLASS-METHODS literal
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_regex IMPLEMENTATION.

  METHOD of.
    result = lcl_compiler=>compile( pattern = pattern
                                    options = options ).
  ENDMETHOD.

  METHOD literal.
    result = lcl_compiler=>escape_literal( text ).
  ENDMETHOD.

ENDCLASS.
