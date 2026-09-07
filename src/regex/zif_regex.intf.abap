"! <p class="shorttext synchronized" lang="EN">Compiled regular expression</p>
"! A PCRE pattern compiled once and applied to as many texts as needed. All
"! operations run against the whole text; the pattern is not anchored unless it
"! says so with ^ and $. Errors surface through {@link zcx_regex}.
INTERFACE zif_regex
  PUBLIC.

  TYPES ty_matches TYPE STANDARD TABLE OF REF TO zif_regex_match WITH EMPTY KEY.

  "! The pattern this expression was compiled from.
  "! @parameter result | Source pattern
  METHODS pattern
    RETURNING VALUE(result) TYPE string.

  "! Tests whether the whole text matches the pattern, as if it were enclosed
  "! in ^ and $.
  "! @parameter text      | Text to test
  "! @parameter result    | abap_true when the pattern covers the text from start to end
  "! @raising   zcx_regex | The engine could not apply the pattern
  METHODS is_match
    IMPORTING text          TYPE string
    RETURNING VALUE(result) TYPE abap_bool
    RAISING   zcx_regex.

  "! Tests whether the pattern occurs anywhere in the text.
  "! @parameter text      | Text to search
  "! @parameter result    | abap_true when at least one occurrence exists
  "! @raising   zcx_regex | The engine could not apply the pattern
  METHODS occurs_in
    IMPORTING text          TYPE string
    RETURNING VALUE(result) TYPE abap_bool
    RAISING   zcx_regex.

  "! Finds the first occurrence of the pattern.
  "! @parameter text      | Text to search
  "! @parameter result    | The first match; always bound, ask is_found( ) whether it exists
  "! @raising   zcx_regex | The engine could not apply the pattern
  METHODS first_match
    IMPORTING text          TYPE string
    RETURNING VALUE(result) TYPE REF TO zif_regex_match
    RAISING   zcx_regex.

  "! Finds every occurrence of the pattern, left to right and without overlaps.
  "! @parameter text      | Text to search
  "! @parameter result    | All matches in text order, empty when there is none
  "! @raising   zcx_regex | The engine could not apply the pattern
  METHODS all_matches
    IMPORTING text          TYPE string
    RETURNING VALUE(result) TYPE ty_matches
    RAISING   zcx_regex.

  "! Counts the occurrences of the pattern.
  "! @parameter text      | Text to search
  "! @parameter result    | Number of non-overlapping matches
  "! @raising   zcx_regex | The engine could not apply the pattern
  METHODS match_count
    IMPORTING text          TYPE string
    RETURNING VALUE(result) TYPE i
    RAISING   zcx_regex.

  "! Collects the text of every occurrence, like grep -o.
  "! @parameter text      | Text to search
  "! @parameter result    | Matched texts in text order, empty when there is none
  "! @raising   zcx_regex | The engine could not apply the pattern
  METHODS extract_all
    IMPORTING text          TYPE string
    RETURNING VALUE(result) TYPE string_table
    RAISING   zcx_regex.

  "! Replaces every occurrence of the pattern. The replacement may refer to the
  "! match with $0 and to capture groups with $1 to $9; a literal dollar sign or
  "! backslash is written as \$ and \\.
  "! @parameter text        | Text to change
  "! @parameter replacement | Text put in place of each occurrence
  "! @parameter result      | Changed text, unchanged when nothing matched
  "! @raising   zcx_regex   | The engine could not apply the pattern
  METHODS replace_all
    IMPORTING text          TYPE string
              replacement   TYPE string
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_regex.

  "! Replaces the first occurrence of the pattern only. The replacement follows
  "! the same rules as in replace_all.
  "! @parameter text        | Text to change
  "! @parameter replacement | Text put in place of the first occurrence
  "! @parameter result      | Changed text, unchanged when nothing matched
  "! @raising   zcx_regex   | The engine could not apply the pattern
  METHODS replace_first
    IMPORTING text          TYPE string
              replacement   TYPE string
    RETURNING VALUE(result) TYPE string
    RAISING   zcx_regex.

  "! Cuts the text at every occurrence of the pattern. The occurrences are
  "! dropped, the parts between them are kept, including empty parts at the
  "! start, in the middle and at the end - n occurrences give n + 1 parts.
  "! Occurrences of zero length are ignored.
  "! @parameter text      | Text to cut
  "! @parameter result    | Parts between the occurrences; the whole text when there is none
  "! @raising   zcx_regex | The engine could not apply the pattern
  METHODS split
    IMPORTING text          TYPE string
    RETURNING VALUE(result) TYPE string_table
    RAISING   zcx_regex.

ENDINTERFACE.
