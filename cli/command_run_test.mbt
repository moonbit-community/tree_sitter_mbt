///|
fn cli_command_test_parser() -> @tree_sitter_mbt.Parser raise {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(cli_parse_pair_language())
  parser
}

///|
fn cli_query_assertion_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "cli_query_assertion_test",
      #|  "extras": [
      #|    { "type": "PATTERN", "value": "\\s" },
      #|    { "type": "SYMBOL", "name": "comment" }
      #|  ],
      #|  "rules": {
      #|    "document": {
      #|      "type": "REPEAT",
      #|      "content": { "type": "SYMBOL", "name": "item" }
      #|    },
      #|    "item": { "type": "STRING", "value": "a" },
      #|    "comment": { "type": "PATTERN", "value": "//.*" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn cli_query_utf8_column_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "cli_query_utf8_column_test",
      #|  "extras": [
      #|    { "type": "PATTERN", "value": "\\s" },
      #|    { "type": "SYMBOL", "name": "comment" }
      #|  ],
      #|  "rules": {
      #|    "document": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        { "type": "STRING", "value": "\u00e9" },
      #|        { "type": "SYMBOL", "name": "item" }
      #|      ]
      #|    },
      #|    "item": { "type": "STRING", "value": "a" },
      #|    "comment": { "type": "PATTERN", "value": "//.*" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn cli_tags_test_command() -> CliTagsCommand {
  {
    paths_file: None,
    paths: [],
    config_path: None,
    grammar_path: None,
    scope: None,
    time: false,
    quiet: false,
    test_number: None,
    rebuild: false,
  }
}

///|
test "cli parse command runner maps command options to parse runner" {
  let parser = cli_command_test_parser()
  let command = CliParseCommand::{
    paths_file: None,
    paths: [],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    output: CliParseCst,
    no_ranges: true,
    time: false,
    encoding: None,
    test_number: None,
    rebuild: false,
  }
  let result = run_cli_parse_command(command, parser, [
    { name: Some("sample.mbt"), contents: b"ab", language_names: [] },
  ])
  assert_eq(result.results.length(), 1)
  assert_eq(result.exit_code, 0)
  assert_eq(
    result.stdout,
    (
      #|document
      #|  left: item `a`
      #|  "b"
      #|
    ),
  )
  assert_true(result.results[0].name == Some("sample.mbt"))
}

///|
test "cli parse command runner appends first parse problem summary" {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(cli_parse_diagnostics_language())
  let command = CliParseCommand::{
    paths_file: None,
    paths: [],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    output: CliParseQuiet,
    no_ranges: false,
    time: false,
    encoding: None,
    test_number: None,
    rebuild: false,
  }
  let result = run_cli_parse_command(command, parser, [
    { name: Some("bad.mbt"), contents: b"x", language_names: [] },
  ])
  assert_eq(result.results.length(), 1)
  assert_eq(result.exit_code, 1)
  assert_eq(result.stdout, "bad.mbt\t(ERROR [0, 0] - [0, 1])\n")
  guard result.results[0].result.problem is Some(problem) else {
    fail("expected parse problem")
  }
  assert_true(problem.kind is ErrorNode)
}

///|
test "cli parse command runner appends timing summary when requested" {
  let parser = cli_command_test_parser()
  let command = CliParseCommand::{
    paths_file: None,
    paths: [],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    output: CliParseQuiet,
    no_ranges: false,
    time: true,
    encoding: None,
    test_number: None,
    rebuild: false,
  }
  let result = run_cli_parse_command(command, parser, [
    { name: Some("timed.mbt"), contents: b"ab", language_names: [] },
  ])
  assert_eq(result.exit_code, 0)
  assert_true(result.stdout.has_prefix("timed.mbt\tParse: "))
  assert_true(result.stdout.has_suffix(" ms\n"))
}

///|
test "cli test command runner filters corpus and renders summaries" {
  let parser = cli_command_test_parser()
  let command = CliTestCommand::{
    include_pattern: Some("Passing"),
    exclude_pattern: None,
    file_name: None,
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    update: false,
    show_fields: false,
    rebuild: false,
    overview_only: true,
    json_summary: true,
    stats: Some(CliTestStatsTotalOnly),
  }
  let result = run_cli_test_command(command, parser, [
    {
      name: "corpus.txt",
      contents: (
        #|===
        #|Passing case
        #|===
        #|ab
        #|---
        #|(document (item))
        #|===
        #|Filtered failure
        #|===
        #|ab
        #|---
        #|(wrong)
        #|
      ),
      file_name: Some("corpus.txt"),
      current_platform: Some("linux"),
    },
  ])
  assert_eq(result.summary.total, 1)
  assert_eq(result.summary.passed, 1)
  assert_eq(result.summary.failed, 0)
  assert_eq(result.exit_code, 0)
  assert_true(
    result.json_summary ==
    Some(
      "{\"total\":1,\"passed\":1,\"failed\":0,\"skipped\":0,\"platform_skipped\":0}",
    ),
  )
  assert_eq(result.stdout, result.json_summary.unwrap())
}

///|
test "cli test command runner prepares update writes" {
  let parser = cli_command_test_parser()
  let command = CliTestCommand::{
    include_pattern: None,
    exclude_pattern: None,
    file_name: None,
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    update: true,
    show_fields: false,
    rebuild: false,
    overview_only: false,
    json_summary: false,
    stats: None,
  }
  let result = run_cli_test_command(command, parser, [
    {
      name: "corpus.txt",
      contents: (
        #|===
        #|Needs update
        #|===
        #|ab
        #|---
        #|(wrong)
        #|
      ),
      file_name: None,
      current_platform: None,
    },
  ])
  assert_eq(result.files.length(), 1)
  guard result.files[0].update is Some(update) else {
    fail("expected update output")
  }
  assert_eq(update.path, "corpus.txt")
  assert_true(update.content.contains("(document\n  (item))"))
  assert_eq(result.exit_code, 1)
}

///|
test "cli query command runner renders captures with text predicates" {
  let command = CliQueryCommand::{
    query_path: Some("query.scm"),
    source_paths: [],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    encoding: None,
    test_number: None,
    rebuild: false,
    output: CliQueryCaptures,
    byte_range: None,
    containing_byte_range: None,
    test_mode: false,
  }
  let result = run_cli_query_command(
    command,
    cli_parse_pair_language(),
    "(item) @node (#eq? @node \"a\")",
    [{ name: Some("source.mbt"), contents: b"ab", language_names: [] }],
  )
  assert_eq(result.exit_code, 0)
  assert_eq(result.results.length(), 1)
  assert_eq(result.results[0].match_count, 1)
  assert_eq(result.results[0].capture_count, 1)
  assert_eq(result.stdout, "node item 0:1\n")
}

///|
test "cli query command runner renders matches and applies byte ranges" {
  let command = CliQueryCommand::{
    query_path: None,
    source_paths: [],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    encoding: None,
    test_number: None,
    rebuild: false,
    output: CliQueryMatches,
    byte_range: None,
    containing_byte_range: Some({ start: 0U, end: 1U }),
    test_mode: false,
  }
  let result = run_cli_query_command(
    command,
    cli_parse_pair_language(),
    "(document) @root (item) @node",
    [{ name: None, contents: b"ab", language_names: [] }],
  )
  assert_eq(result.exit_code, 0)
  assert_eq(result.results[0].match_count, 1)
  assert_eq(result.results[0].capture_count, 1)
  assert_eq(
    result.stdout,
    (
      #|pattern 1
      #|  node item 0:1
      #|
    ),
  )
}

///|
test "cli query command runner test mode passes assertion comments" {
  let command = CliQueryCommand::{
    query_path: None,
    source_paths: [],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    encoding: None,
    test_number: None,
    rebuild: false,
    output: CliQueryCaptures,
    byte_range: None,
    containing_byte_range: None,
    test_mode: true,
  }
  let result = run_cli_query_command(
    command,
    cli_query_assertion_language(),
    "(item) @node",
    [
      {
        name: Some("source.mbt"),
        contents: b"a\n// <- node\n",
        language_names: [],
      },
    ],
  )
  assert_eq(result.exit_code, 0)
  assert_true(result.results[0].successful)
  assert_eq(result.results[0].match_count, 1)
  assert_eq(result.results[0].capture_count, 1)
  assert_eq(result.stdout, "source.mbt\t1 assertion passed\n")
}

///|
test "cli query command runner test mode uses utf8 grapheme columns" {
  let command = CliQueryCommand::{
    query_path: None,
    source_paths: [],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    encoding: None,
    test_number: None,
    rebuild: false,
    output: CliQueryCaptures,
    byte_range: None,
    containing_byte_range: None,
    test_mode: true,
  }
  let source = Bytes::from_array([
    0x20, 0x20, 0xC3, 0xA9, 0x61, 0x0A, 0x2F, 0x2F, 0x20, 0x5E, 0x20, 0x6E, 0x6F,
    0x64, 0x65, 0x0A,
  ])
  let result = run_cli_query_command(
    command,
    cli_query_utf8_column_language(),
    "(item) @node",
    [{ name: Some("utf8.mbt"), contents: source, language_names: [] }],
  )
  assert_eq(result.exit_code, 0)
  assert_true(result.results[0].successful)
  assert_eq(result.stdout, "utf8.mbt\t1 assertion passed\n")
}

///|
test "cli query command runner test mode reports assertion failures" {
  let command = CliQueryCommand::{
    query_path: None,
    source_paths: [],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    encoding: None,
    test_number: None,
    rebuild: false,
    output: CliQueryCaptures,
    byte_range: None,
    containing_byte_range: None,
    test_mode: true,
  }
  let result = run_cli_query_command(
    command,
    cli_query_assertion_language(),
    "(item) @node",
    [
      {
        name: Some("source.mbt"),
        contents: b"a\n// <- other\n",
        language_names: [],
      },
    ],
  )
  assert_eq(result.exit_code, 1)
  assert_true(!result.results[0].successful)
  assert_eq(
    result.stdout,
    "source.mbt\tAssertion failed: at (0, 0), found node, expected other\n",
  )
}

///|
test "cli tags command runner renders upstream style rows" {
  let config = @tags.TagsConfiguration::new(
    cli_parse_pair_language(),
    "(item) @definition.function @name",
  )
  let result = run_cli_tags_command(cli_tags_test_command(), config, [
    { name: Some("source.mbt"), contents: b"ab", language_names: [] },
  ])
  assert_eq(result.exit_code, 0)
  assert_eq(result.results.length(), 1)
  assert_eq(result.results[0].tag_count, 1)
  assert_true(!result.results[0].has_parse_error)
  assert_eq(
    result.stdout,
    "a         \t | function\tdef [0, 0] - [0, 1] `ab`\n",
  )
}
