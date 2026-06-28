///|
fn query_files_test_language_config() -> CliLanguageConfig {
  CliLanguageConfig::{
    scope: "source.test",
    path: None,
    file_types: [],
    content_regex: None,
    first_line_regex: None,
    injection_regex: None,
    highlights: ["queries/highlights.scm"],
    injections: ["queries/injections.scm"],
    locals: ["queries/locals.scm"],
    tags: ["queries/tags.scm"],
    external_files: [],
  }
}

///|
test "cli resolves configured query paths relative to grammar root" {
  let paths = resolve_cli_language_query_paths(
    "/repo/tree-sitter-test",
    query_files_test_language_config(),
  )
  assert_true(
    paths.highlights == ["/repo/tree-sitter-test/queries/highlights.scm"],
  )
  assert_true(
    paths.injections == ["/repo/tree-sitter-test/queries/injections.scm"],
  )
  assert_true(paths.locals == ["/repo/tree-sitter-test/queries/locals.scm"])
  assert_true(paths.tags == ["/repo/tree-sitter-test/queries/tags.scm"])
  assert_true(paths.others == [])
}

///|
test "cli resolves located language query paths from grammar root" {
  let location = CliLanguageConfigLocation::{
    parser_root: "/repo/parser",
    grammar_root: "/repo/parser/grammar",
    config: query_files_test_language_config(),
  }
  let paths = resolve_cli_language_location_query_paths(location)
  assert_true(
    paths.highlights == ["/repo/parser/grammar/queries/highlights.scm"],
  )
  assert_true(
    paths.injections == ["/repo/parser/grammar/queries/injections.scm"],
  )
  assert_true(paths.locals == ["/repo/parser/grammar/queries/locals.scm"])
  assert_true(paths.tags == ["/repo/parser/grammar/queries/tags.scm"])
}

///|
test "cli classifies explicit query paths without defaults" {
  let paths = resolve_cli_explicit_query_paths([
    "custom/highlights.scm", "custom/injections.scm", "custom/locals.scm", "custom/tags.scm",
    "custom/rules.scm",
  ])
  assert_true(paths.highlights == ["custom/highlights.scm"])
  assert_true(paths.injections == ["custom/injections.scm"])
  assert_true(paths.locals == ["custom/locals.scm"])
  assert_true(paths.tags == ["custom/tags.scm"])
  assert_true(paths.others == ["custom/rules.scm"])
}

///|
test "cli combines query files without inserted separators" {
  let combined = combine_cli_query_files([
    { path: "a.scm", content: "a" },
    { path: "b.scm", content: "b\n" },
    { path: "unicode.scm", content: "é" },
  ])
  assert_eq(combined.source, "ab\né")
  assert_true(
    combined.ranges ==
    [
      { path: "a.scm", start_byte: 0, end_byte: 1 },
      { path: "b.scm", start_byte: 1, end_byte: 3 },
      { path: "unicode.scm", start_byte: 3, end_byte: 5 },
    ],
  )
}

///|
test "cli maps combined query byte offsets to source files" {
  let combined = combine_cli_query_files([
    { path: "a.scm", content: "a" },
    { path: "b.scm", content: "b\n" },
    { path: "unicode.scm", content: "é" },
  ])
  assert_true(
    cli_query_file_offset(combined, 0) ==
    Some({ path: "a.scm", byte_offset: 0 }),
  )
  assert_true(
    cli_query_file_offset(combined, 1) ==
    Some({ path: "b.scm", byte_offset: 0 }),
  )
  assert_true(
    cli_query_file_offset(combined, 3) ==
    Some({ path: "unicode.scm", byte_offset: 0 }),
  )
  assert_true(
    cli_query_file_offset(combined, 5) ==
    Some({ path: "unicode.scm", byte_offset: 2 }),
  )
  assert_true(cli_query_file_offset(combined, -1) is None)
  assert_true(cli_query_file_offset(combined, 6) is None)
}

///|
test "cli maps query errors to source files" {
  let combined = combine_cli_query_files([
    { path: "first.scm", content: "(document) @root" },
    { path: "second.scm", content: "(missing) @bad" },
  ])
  let error = @query.QueryError::NodeType(byte_offset=18, name="missing")
  assert_eq(cli_query_error_byte_offset(error), 18)
  assert_true(
    cli_query_error_file_offset(combined, error) ==
    Some({ path: "second.scm", byte_offset: 2 }),
  )
}
