///|
fn cli_generate_minimal_grammar_json() -> String {
  (
    #|{
    #|  "name": "minimal",
    #|  "rules": {
    #|    "document": { "type": "STRING", "value": "a" }
    #|  }
    #|}
  )
}

///|
fn cli_generated_file_for_path(
  files : Array[CliOutputFile],
  path : String,
) -> CliOutputFile? {
  for file in files {
    if file.path == path {
      return Some(file)
    }
  }
  None
}

///|
test "cli generate command returns parser files and node types" {
  let command = CliGenerateCommand::{
    grammar_path: Some("grammar.json"),
    output_dir: Some("src"),
    abi_version: Some("latest"),
    js_runtime: None,
    log: false,
    no_parser: false,
    report_states_for_rule: None,
    json_summary: true,
    disable_optimizations: false,
  }
  let result = run_cli_generate_command(
    command,
    cli_generate_minimal_grammar_json(),
  )
  assert_eq(result.language_name, "minimal")
  assert_eq(
    result.abi_version,
    @generator.GenerateOptions::default().abi_version,
  )
  assert_eq(result.files.length(), 3)
  guard cli_generated_file_for_path(result.files, "src/moon.pkg")
    is Some(moon_pkg) else {
    fail("expected moon.pkg output")
  }
  assert_true(moon_pkg.content.contains("moonbit-community/tree_sitter_mbt"))
  guard cli_generated_file_for_path(result.files, "src/language.mbt")
    is Some(language_source) else {
    fail("expected language.mbt output")
  }
  assert_true(language_source.content.contains("pub fn language()"))
  guard cli_generated_file_for_path(result.files, "src/node-types.json")
    is Some(node_types) else {
    fail("expected node-types output")
  }
  assert_true(node_types.content.contains("\"type\": \"document\""))
  assert_true(
    result.json_summary ==
    Some(
      "{\"language\":\"minimal\",\"abi_version\":15,\"file_count\":3,\"warning_count\":0}",
    ),
  )
}

///|
test "cli generate command can omit parser sources" {
  let command = CliGenerateCommand::{
    grammar_path: None,
    output_dir: None,
    abi_version: None,
    js_runtime: None,
    log: false,
    no_parser: true,
    report_states_for_rule: None,
    json_summary: false,
    disable_optimizations: false,
  }
  let result = run_cli_generate_command(
    command,
    cli_generate_minimal_grammar_json(),
  )
  assert_eq(result.files.length(), 1)
  assert_true(result.files[0].path == "node-types.json")
  assert_true(result.json_summary is None)
}

///|
test "cli generate command can include converted grammar json output" {
  let command = CliGenerateCommand::{
    grammar_path: Some("grammar.js"),
    output_dir: Some("out"),
    abi_version: None,
    js_runtime: None,
    log: false,
    no_parser: true,
    report_states_for_rule: None,
    json_summary: true,
    disable_optimizations: false,
  }
  let grammar_json = cli_generate_minimal_grammar_json()
  let result = run_cli_generate_command(
    command,
    grammar_json,
    emit_grammar_json=true,
  )
  assert_eq(result.files.length(), 2)
  guard cli_generated_file_for_path(result.files, "out/grammar.json")
    is Some(grammar_file) else {
    fail("expected converted grammar.json output")
  }
  assert_true(grammar_file.content == grammar_json)
  assert_true(
    cli_generated_file_for_path(result.files, "out/node-types.json") is Some(_),
  )
  assert_true(
    result.json_summary ==
    Some(
      "{\"language\":\"minimal\",\"abi_version\":15,\"file_count\":2,\"warning_count\":0}",
    ),
  )
}

///|
test "cli generate command reports invalid and unsupported options" {
  let bad_abi = CliGenerateCommand::{
    grammar_path: None,
    output_dir: None,
    abi_version: Some("abc"),
    js_runtime: None,
    log: false,
    no_parser: false,
    report_states_for_rule: None,
    json_summary: false,
    disable_optimizations: false,
  }
  let bad_abi_result = @test.expect_error(() => {
    run_cli_generate_command(bad_abi, cli_generate_minimal_grammar_json())
  })
  assert_true(bad_abi_result is InvalidAbiVersion("abc"))
  let unsupported = CliGenerateCommand::{
    ..bad_abi,
    abi_version: None,
    report_states_for_rule: Some("document"),
  }
  let unsupported_result = @test.expect_error(() => {
    run_cli_generate_command(unsupported, cli_generate_minimal_grammar_json())
  })
  assert_true(
    unsupported_result is UnsupportedGenerateOption("--report-states-for-rule"),
  )
}
