///|
fn native_test_dir(label : String) -> String {
  "/tmp/tree_sitter_mbt_cli_native_\{@env.now()}_\{label}"
}

///|
async fn[T] native_expect_error_string(f : async () -> T) -> String {
  try f() catch {
    err => @debug.to_string(err)
  } noraise {
    _ => abort("expected error, but no error was raised")
  }
}

///|
async fn native_remove_file_if_exists(path : String) -> Unit {
  if @fs.exists(path) {
    @fs.remove(path)
  }
}

///|
async fn native_remove_dir_if_exists(path : String) -> Unit {
  if @fs.exists(path) {
    @fs.rmdir(path)
  }
}

///|
async fn native_create_clean_dir(path : String) -> Unit {
  native_remove_dir_if_exists(path)
  @fs.mkdir(path)
}

///|
async fn native_write_text(path : String, content : String) -> Unit {
  @fs.write_file(path, content, create_mode=CreateOrTruncate)
}

///|
fn native_restore_env(name : String, value : String?) -> Unit {
  match value {
    Some(value) => @env.set_env_var(name, value)
    None => @env.unset_env_var(name)
  }
}

///|
fn native_test_parser() -> @tree_sitter_mbt.Parser raise {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(@minimal.language())
  parser
}

///|
fn native_minimal_grammar_json() -> String {
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
fn native_minimal_grammar_js_esm() -> String {
  (
    #|export default grammar({
    #|  name: 'minimal',
    #|  rules: {
    #|    document: $ => 'a',
    #|  },
    #|});
  )
}

///|
fn native_minimal_grammar_js_cjs() -> String {
  (
    #|module.exports = grammar({
    #|  name: 'minimal',
    #|  rules: {
    #|    document: $ => 'a',
    #|  },
    #|});
  )
}

///|
fn native_minimal_grammar_js_with_require() -> String {
  (
    #|const common = require('./common');
    #|
    #|module.exports = grammar({
    #|  name: 'minimal',
    #|  rules: {
    #|    document: $ => common.literal,
    #|  },
    #|});
  )
}

///|
fn native_generate_command(
  grammar_path : String?,
  output_dir : String?,
  no_parser : Bool,
  js_runtime? : String? = None,
) -> @cli.CliGenerateCommand {
  @cli.CliGenerateCommand::{
    grammar_path,
    output_dir,
    abi_version: None,
    js_runtime,
    log: false,
    no_parser,
    report_states_for_rule: None,
    json_summary: true,
    disable_optimizations: false,
  }
}

///|
fn native_file_paths(files : Array[@cli.CliOutputFile]) -> Array[String] {
  files.map(file => file.path)
}

///|
async test "native parse command loads paths file and parses source" {
  let dir = native_test_dir("parse")
  native_create_clean_dir(dir)
  let source_path = dir + "/source.txt"
  let paths_path = dir + "/paths.txt"
  native_write_text(source_path, "a")
  native_write_text(paths_path, source_path + "\n")
  let command = @cli.CliParseCommand::{
    paths_file: Some(paths_path),
    paths: [],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    output: @cli.CliParseNormal,
    no_ranges: true,
    time: false,
    encoding: None,
    test_number: None,
    rebuild: false,
  }
  let result = run_cli_parse_command_files(command, native_test_parser())
  assert_eq(result.exit_code, 0)
  assert_eq(result.results.length(), 1)
  assert_true(result.results[0].name == Some(source_path))
  assert_eq(result.stdout, "(document)\n")
  native_remove_file_if_exists(source_path)
  native_remove_file_if_exists(paths_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native parse and query commands use stdin when no source paths are given" {
  let parse_command = @cli.CliParseCommand::{
    paths_file: None,
    paths: [],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    output: @cli.CliParseNormal,
    no_ranges: true,
    time: false,
    encoding: None,
    test_number: None,
    rebuild: false,
  }
  let parse_sources = read_cli_parse_command_sources(parse_command)
  assert_eq(parse_sources.length(), 1)
  assert_true(parse_sources[0].name is None)
  assert_true(parse_sources[0].language_names.is_empty())
  let query_command = @cli.CliQueryCommand::{
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
    output: @cli.CliQueryCaptures,
    byte_range: None,
    containing_byte_range: None,
    test_mode: false,
  }
  let query_sources = read_cli_query_command_sources(query_command)
  assert_eq(query_sources.length(), 1)
  assert_true(query_sources[0].name is None)
  assert_true(query_sources[0].language_names.is_empty())
}

///|
async test "native parse command reports empty paths file as missing input" {
  let dir = native_test_dir("empty_paths")
  native_create_clean_dir(dir)
  let paths_path = dir + "/paths.txt"
  native_write_text(paths_path, "\n")
  let command = @cli.CliParseCommand::{
    paths_file: Some(paths_path),
    paths: [],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    output: @cli.CliParseNormal,
    no_ranges: true,
    time: false,
    encoding: None,
    test_number: None,
    rebuild: false,
  }
  let result = native_expect_error_string(() => {
    read_cli_parse_command_sources(command)
  })
  assert_true(result.contains("MissingInputPaths"))
  assert_true(result.contains("parse"))
  native_remove_file_if_exists(paths_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native parse command expands globs and exclusions" {
  let dir = native_test_dir("parse_glob")
  native_create_clean_dir(dir)
  let kept_path = dir + "/kept.txt"
  let skipped_path = dir + "/skipped.txt"
  native_write_text(kept_path, "a")
  native_write_text(skipped_path, "x")
  let command = @cli.CliParseCommand::{
    paths_file: None,
    paths: [dir + "/*.txt", "!" + skipped_path],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    output: @cli.CliParseNormal,
    no_ranges: true,
    time: false,
    encoding: None,
    test_number: None,
    rebuild: false,
  }
  let result = run_cli_parse_command_files(command, native_test_parser())
  assert_eq(result.exit_code, 0)
  assert_eq(result.results.length(), 1)
  assert_true(result.results[0].name == Some(kept_path))
  assert_eq(result.stdout, "(document)\n")
  native_remove_file_if_exists(kept_path)
  native_remove_file_if_exists(skipped_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native parse command can load language from grammar path" {
  let dir = native_test_dir("parse_loaded")
  native_create_clean_dir(dir)
  let grammar_path = dir + "/grammar.json"
  let source_path = dir + "/source.txt"
  native_write_text(grammar_path, native_minimal_grammar_json())
  native_write_text(source_path, "a")
  let command = @cli.CliParseCommand::{
    paths_file: None,
    paths: [source_path],
    config_path: None,
    grammar_path: Some(grammar_path),
    lib_path: None,
    lang_name: None,
    scope: None,
    output: @cli.CliParseNormal,
    no_ranges: true,
    time: false,
    encoding: None,
    test_number: None,
    rebuild: false,
  }
  let result = run_cli_parse_command_loaded_files(command)
  assert_eq(result.exit_code, 0)
  assert_eq(result.stdout, "(document)\n")
  native_remove_file_if_exists(source_path)
  native_remove_file_if_exists(grammar_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native parse command can load language from esm grammar js path" {
  let dir = native_test_dir("parse_loaded_js_esm")
  native_create_clean_dir(dir)
  let grammar_path = dir + "/grammar.js"
  let package_path = dir + "/package.json"
  let source_path = dir + "/source.txt"
  native_write_text(package_path, "{\"type\":\"module\"}")
  native_write_text(grammar_path, native_minimal_grammar_js_esm())
  native_write_text(source_path, "a")
  let command = @cli.CliParseCommand::{
    paths_file: None,
    paths: [source_path],
    config_path: None,
    grammar_path: Some(grammar_path),
    lib_path: None,
    lang_name: None,
    scope: None,
    output: @cli.CliParseNormal,
    no_ranges: true,
    time: false,
    encoding: None,
    test_number: None,
    rebuild: false,
  }
  let result = run_cli_parse_command_loaded_files(command)
  assert_eq(result.exit_code, 0)
  assert_eq(result.stdout, "(document)\n")
  native_remove_file_if_exists(source_path)
  native_remove_file_if_exists(package_path)
  native_remove_file_if_exists(grammar_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native read language from commonjs grammar js with require" {
  let dir = native_test_dir("loaded_js_require")
  native_create_clean_dir(dir)
  let grammar_path = dir + "/grammar.js"
  let common_path = dir + "/common.js"
  native_write_text(grammar_path, native_minimal_grammar_js_with_require())
  native_write_text(common_path, "exports.literal = 'a';\n")
  let language = read_cli_language_from_grammar_path(grammar_path)
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  assert_eq(parser.parse_string("a").to_sexp(), "(document)")
  native_remove_file_if_exists(common_path)
  native_remove_file_if_exists(grammar_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native query command loads query and source files" {
  let dir = native_test_dir("query")
  native_create_clean_dir(dir)
  let source_path = dir + "/source.txt"
  let query_path = dir + "/query.scm"
  native_write_text(source_path, "a")
  native_write_text(query_path, "(document) @root")
  let command = @cli.CliQueryCommand::{
    query_path: Some(query_path),
    source_paths: [source_path],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    encoding: None,
    test_number: None,
    rebuild: false,
    output: @cli.CliQueryCaptures,
    byte_range: None,
    containing_byte_range: None,
    test_mode: false,
  }
  let result = run_cli_query_command_files(command, @minimal.language())
  assert_eq(result.exit_code, 0)
  assert_eq(result.results.length(), 1)
  assert_eq(result.stdout, "root document 0:1\n")
  native_remove_file_if_exists(source_path)
  native_remove_file_if_exists(query_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native query command can load language from grammar path" {
  let dir = native_test_dir("query_loaded")
  native_create_clean_dir(dir)
  let grammar_path = dir + "/grammar.json"
  let source_path = dir + "/source.txt"
  let query_path = dir + "/query.scm"
  native_write_text(grammar_path, native_minimal_grammar_json())
  native_write_text(source_path, "a")
  native_write_text(query_path, "(document) @root")
  let command = @cli.CliQueryCommand::{
    query_path: Some(query_path),
    source_paths: [source_path],
    config_path: None,
    grammar_path: Some(grammar_path),
    lib_path: None,
    lang_name: None,
    scope: None,
    encoding: None,
    test_number: None,
    rebuild: false,
    output: @cli.CliQueryCaptures,
    byte_range: None,
    containing_byte_range: None,
    test_mode: false,
  }
  let result = run_cli_query_command_loaded_files(command)
  assert_eq(result.exit_code, 0)
  assert_eq(result.stdout, "root document 0:1\n")
  native_remove_file_if_exists(query_path)
  native_remove_file_if_exists(source_path)
  native_remove_file_if_exists(grammar_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native test-number input reads corpus case and language marker" {
  native_remove_file_if_exists("test/query.scm")
  native_remove_file_if_exists("test/corpus/corpus.txt")
  native_remove_dir_if_exists("test/corpus")
  native_remove_dir_if_exists("test")
  @fs.mkdir("test")
  @fs.mkdir("test/corpus")
  native_write_text(
    "test/corpus/corpus.txt",
    (
      #|===
      #|First case
      #|:language(source.first)
      #|===
      #|x
      #|---
      #|(ERROR)
      #|===
      #|Second case
      #|:language(source.second)
      #|===
      #|a
      #|---
      #|(document)
      #|
    ),
  )
  native_write_text("test/query.scm", "(document) @root")
  let zero_command = @cli.CliParseCommand::{
    paths_file: None,
    paths: [],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    output: @cli.CliParseNormal,
    no_ranges: true,
    time: false,
    encoding: None,
    test_number: Some(0U),
    rebuild: false,
  }
  let zero_sources = read_cli_parse_command_sources(zero_command)
  assert_eq(zero_sources.length(), 1)
  assert_true(zero_sources[0].name == Some("First case"))
  assert_true(zero_sources[0].contents == b"x")
  assert_true(zero_sources[0].language_names == ["source.first"])
  let parse_command = { ..zero_command, test_number: Some(2U) }
  let parse_sources = read_cli_parse_command_sources(parse_command)
  assert_eq(parse_sources.length(), 1)
  assert_true(parse_sources[0].name == Some("Second case"))
  assert_true(parse_sources[0].contents == b"a")
  assert_true(parse_sources[0].language_names == ["source.second"])
  let parse_result = run_cli_parse_command_files(
    parse_command,
    native_test_parser(),
  )
  assert_eq(parse_result.exit_code, 0)
  assert_eq(parse_result.stdout, "(document)\n")
  let query_command = @cli.CliQueryCommand::{
    query_path: Some("test/query.scm"),
    source_paths: [],
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    encoding: None,
    test_number: Some(2U),
    rebuild: false,
    output: @cli.CliQueryCaptures,
    byte_range: None,
    containing_byte_range: None,
    test_mode: false,
  }
  let query_sources = read_cli_query_command_sources(query_command)
  assert_true(query_sources[0].language_names == ["source.second"])
  let query_result = run_cli_query_command_files(
    query_command,
    @minimal.language(),
  )
  assert_eq(query_result.exit_code, 0)
  assert_eq(query_result.stdout, "root document 0:1\n")
  native_remove_file_if_exists("test/query.scm")
  native_remove_file_if_exists("test/corpus/corpus.txt")
  native_remove_dir_if_exists("test/corpus")
  native_remove_dir_if_exists("test")
}

///|
async test "native config readers load global and tree-sitter json" {
  let dir = native_test_dir("config")
  native_create_clean_dir(dir)
  let global_path = dir + "/config.json"
  let grammar_config_path = dir + "/tree-sitter.json"
  native_write_text(global_path, "{\"parser-directories\":[\"grammars\"]}")
  native_write_text(
    grammar_config_path, "{\"grammars\":[{\"scope\":\"source.mbt\",\"file-types\":[\"mbt\"]}]}",
  )
  let global = read_cli_global_config_file(global_path)
  assert_true(global.parser_directories == ["grammars"])
  let optional_global = read_cli_optional_global_config_file(Some(global_path))
  assert_true(optional_global is Some({ parser_directories: ["grammars"], .. }))
  assert_true(read_cli_optional_global_config_file(None) is None)
  let grammar_config = read_cli_tree_sitter_config_file(grammar_config_path)
  assert_eq(grammar_config.grammars.length(), 1)
  assert_eq(grammar_config.grammars[0].scope, "source.mbt")
  native_remove_file_if_exists(global_path)
  native_remove_file_if_exists(grammar_config_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native parse command selects configured grammar by file type" {
  let dir = native_test_dir("parse_config_loaded")
  native_create_clean_dir(dir)
  let parser_root = dir + "/parser"
  let grammar_root = parser_root + "/grammar"
  @fs.mkdir(parser_root)
  @fs.mkdir(grammar_root)
  let global_path = dir + "/config.json"
  let tree_sitter_path = parser_root + "/tree-sitter.json"
  let grammar_path = grammar_root + "/grammar.json"
  let source_path = dir + "/sample.native"
  native_write_text(
    global_path,
    "{\"parser-directories\":[\"\{parser_root}\"]}",
  )
  native_write_text(
    tree_sitter_path,
    (
      #|{
      #|  "grammars": [{
      #|    "scope": "source.native",
      #|    "path": "grammar",
      #|    "file-types": ["native"]
      #|  }]
      #|}
    ),
  )
  native_write_text(grammar_path, native_minimal_grammar_json())
  native_write_text(source_path, "a")
  let command = @cli.CliParseCommand::{
    paths_file: None,
    paths: [source_path],
    config_path: Some(global_path),
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    output: @cli.CliParseNormal,
    no_ranges: true,
    time: false,
    encoding: None,
    test_number: None,
    rebuild: false,
  }
  let result = run_cli_parse_command_loaded_files(command)
  assert_eq(result.exit_code, 0)
  assert_eq(result.stdout, "(document)\n")
  native_remove_file_if_exists(source_path)
  native_remove_file_if_exists(grammar_path)
  native_remove_file_if_exists(tree_sitter_path)
  native_remove_file_if_exists(global_path)
  native_remove_dir_if_exists(grammar_root)
  native_remove_dir_if_exists(parser_root)
  native_remove_dir_if_exists(dir)
}

///|
async test "native parse command falls back to configured grammar js" {
  let dir = native_test_dir("parse_config_js_loaded")
  native_create_clean_dir(dir)
  let parser_root = dir + "/parser"
  let grammar_root = parser_root + "/grammar"
  @fs.mkdir(parser_root)
  @fs.mkdir(grammar_root)
  let global_path = dir + "/config.json"
  let tree_sitter_path = parser_root + "/tree-sitter.json"
  let grammar_path = grammar_root + "/grammar.js"
  let source_path = dir + "/sample.nativejs"
  native_write_text(
    global_path,
    "{\"parser-directories\":[\"\{parser_root}\"]}",
  )
  native_write_text(
    tree_sitter_path,
    (
      #|{
      #|  "grammars": [{
      #|    "scope": "source.nativejs",
      #|    "path": "grammar",
      #|    "file-types": ["nativejs"]
      #|  }]
      #|}
    ),
  )
  native_write_text(grammar_path, native_minimal_grammar_js_cjs())
  native_write_text(source_path, "a")
  let command = @cli.CliParseCommand::{
    paths_file: None,
    paths: [source_path],
    config_path: Some(global_path),
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    scope: None,
    output: @cli.CliParseNormal,
    no_ranges: true,
    time: false,
    encoding: None,
    test_number: None,
    rebuild: false,
  }
  let result = run_cli_parse_command_loaded_files(command)
  assert_eq(result.exit_code, 0)
  assert_eq(result.stdout, "(document)\n")
  native_remove_file_if_exists(source_path)
  native_remove_file_if_exists(grammar_path)
  native_remove_file_if_exists(tree_sitter_path)
  native_remove_file_if_exists(global_path)
  native_remove_dir_if_exists(grammar_root)
  native_remove_dir_if_exists(parser_root)
  native_remove_dir_if_exists(dir)
}

///|
async test "native tags command loads configured queries and grammar" {
  let dir = native_test_dir("tags_config_loaded")
  native_create_clean_dir(dir)
  let parser_root = dir + "/parser"
  let grammar_root = parser_root + "/grammar"
  let queries_root = grammar_root + "/queries"
  @fs.mkdir(parser_root)
  @fs.mkdir(grammar_root)
  @fs.mkdir(queries_root)
  let global_path = dir + "/config.json"
  let tree_sitter_path = parser_root + "/tree-sitter.json"
  let grammar_path = grammar_root + "/grammar.json"
  let tags_path = queries_root + "/tags.scm"
  let locals_path = queries_root + "/locals.scm"
  let source_path = dir + "/sample.tagsnative"
  native_write_text(
    global_path,
    "{\"parser-directories\":[\"\{parser_root}\"]}",
  )
  native_write_text(
    tree_sitter_path,
    (
      #|{
      #|  "grammars": [{
      #|    "scope": "source.tagsnative",
      #|    "path": "grammar",
      #|    "file-types": ["tagsnative"],
      #|    "tags": ["queries/tags.scm"],
      #|    "locals": ["queries/locals.scm"]
      #|  }]
      #|}
    ),
  )
  native_write_text(grammar_path, native_minimal_grammar_json())
  native_write_text(tags_path, "(document) @definition.function @name")
  native_write_text(locals_path, "")
  native_write_text(source_path, "a")
  let command = @cli.CliTagsCommand::{
    paths_file: None,
    paths: [source_path],
    config_path: Some(global_path),
    grammar_path: None,
    scope: None,
    time: false,
    quiet: false,
    test_number: None,
    rebuild: false,
  }
  let result = run_cli_tags_command_loaded_files(command)
  assert_eq(result.exit_code, 0)
  assert_eq(result.results.length(), 1)
  assert_eq(result.stdout, "a         \t | function\tdef [0, 0] - [0, 1] `a`\n")
  native_remove_file_if_exists(source_path)
  native_remove_file_if_exists(locals_path)
  native_remove_file_if_exists(tags_path)
  native_remove_file_if_exists(grammar_path)
  native_remove_file_if_exists(tree_sitter_path)
  native_remove_file_if_exists(global_path)
  native_remove_dir_if_exists(queries_root)
  native_remove_dir_if_exists(grammar_root)
  native_remove_dir_if_exists(parser_root)
  native_remove_dir_if_exists(dir)
}

///|
async test "native global config discovery checks explicit env xdg and legacy paths" {
  let old_tree_sitter_dir = @env.get_env_var("TREE_SITTER_DIR")
  let old_xdg_config_home = @env.get_env_var("XDG_CONFIG_HOME")
  let old_home = @env.get_env_var("HOME")
  let dir = native_test_dir("global_config_discovery")
  native_create_clean_dir(dir)
  let explicit_path = dir + "/explicit.json"
  let tree_sitter_dir = dir + "/tree_sitter_dir"
  let xdg_dir = dir + "/xdg"
  let xdg_tree_sitter_dir = xdg_dir + "/tree-sitter"
  let home_dir = dir + "/home"
  let home_config_dir = home_dir + "/.config"
  let home_config_tree_sitter_dir = home_config_dir + "/tree-sitter"
  let legacy_dir = home_dir + "/.tree-sitter"
  @fs.mkdir(tree_sitter_dir)
  @fs.mkdir(xdg_dir)
  @fs.mkdir(xdg_tree_sitter_dir)
  @fs.mkdir(home_dir)
  @fs.mkdir(home_config_dir)
  @fs.mkdir(home_config_tree_sitter_dir)
  @fs.mkdir(legacy_dir)
  let tree_sitter_config_path = tree_sitter_dir + "/config.json"
  let xdg_config_path = xdg_tree_sitter_dir + "/config.json"
  let home_config_path = home_config_tree_sitter_dir + "/config.json"
  let legacy_config_path = legacy_dir + "/config.json"
  native_write_text(explicit_path, "{\"parser-directories\":[\"explicit\"]}")
  native_write_text(
    tree_sitter_config_path, "{\"parser-directories\":[\"tree\"]}",
  )
  native_write_text(xdg_config_path, "{\"parser-directories\":[\"xdg\"]}")
  native_write_text(
    home_config_path, "{\"parser-directories\":[\"home-config\"]}",
  )
  native_write_text(legacy_config_path, "{\"parser-directories\":[\"legacy\"]}")
  @env.set_env_var("TREE_SITTER_DIR", tree_sitter_dir)
  @env.set_env_var("XDG_CONFIG_HOME", xdg_dir)
  @env.set_env_var("HOME", home_dir)
  assert_true(
    resolve_cli_global_config_path(Some(explicit_path)) == Some(explicit_path),
  )
  assert_true(
    resolve_cli_global_config_path(None) == Some(tree_sitter_config_path),
  )
  native_remove_file_if_exists(tree_sitter_config_path)
  assert_true(resolve_cli_global_config_path(None) == Some(xdg_config_path))
  @env.unset_env_var("XDG_CONFIG_HOME")
  assert_true(resolve_cli_global_config_path(None) == Some(home_config_path))
  native_remove_file_if_exists(home_config_path)
  assert_true(resolve_cli_global_config_path(None) == Some(legacy_config_path))
  let loaded = read_cli_discovered_global_config_file(None)
  assert_true(loaded is Some({ parser_directories: ["legacy"], .. }))
  native_remove_file_if_exists(explicit_path)
  native_remove_file_if_exists(xdg_config_path)
  native_remove_file_if_exists(legacy_config_path)
  native_remove_dir_if_exists(legacy_dir)
  native_remove_dir_if_exists(home_config_tree_sitter_dir)
  native_remove_dir_if_exists(home_config_dir)
  native_remove_dir_if_exists(home_dir)
  native_remove_dir_if_exists(xdg_tree_sitter_dir)
  native_remove_dir_if_exists(xdg_dir)
  native_remove_dir_if_exists(tree_sitter_dir)
  native_remove_dir_if_exists(dir)
  native_restore_env("TREE_SITTER_DIR", old_tree_sitter_dir)
  native_restore_env("XDG_CONFIG_HOME", old_xdg_config_home)
  native_restore_env("HOME", old_home)
}

///|
async test "native config readers locate tree-sitter languages" {
  let dir = native_test_dir("config_locations")
  native_create_clean_dir(dir)
  let grammar_config_path = dir + "/tree-sitter.json"
  native_write_text(
    grammar_config_path,
    (
      #|{
      #|  "grammars": [{
      #|    "scope": "source.native",
      #|    "path": "grammar",
      #|    "file-types": ["native"],
      #|    "highlights": ["queries/highlights.scm"]
      #|  }]
      #|}
    ),
  )
  let locations = read_cli_tree_sitter_config_locations([dir])
  assert_eq(locations.length(), 1)
  assert_eq(locations[0].parser_root, dir)
  assert_eq(locations[0].grammar_root, dir + "/grammar")
  assert_eq(locations[0].config.scope, "source.native")
  let query_paths = @cli.resolve_cli_language_location_query_paths(locations[0])
  assert_true(
    query_paths.highlights == [dir + "/grammar/queries/highlights.scm"],
  )
  native_remove_file_if_exists(grammar_config_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native query file readers preserve combined source ranges" {
  let dir = native_test_dir("query_files")
  native_create_clean_dir(dir)
  let first_path = dir + "/highlights.scm"
  let second_path = dir + "/locals.scm"
  native_write_text(first_path, "a")
  native_write_text(second_path, "b\n")
  let files = read_cli_query_files([first_path, second_path])
  assert_eq(files.length(), 2)
  assert_eq(files[0].content, "a")
  let combined = read_cli_combined_query([first_path, second_path])
  assert_eq(combined.source, "ab\n")
  assert_true(
    combined.ranges ==
    [
      @cli.CliQuerySourceRange::{ path: first_path, start_byte: 0, end_byte: 1 },
      @cli.CliQuerySourceRange::{
        path: second_path,
        start_byte: 1,
        end_byte: 3,
      },
    ],
  )
  native_remove_file_if_exists(first_path)
  native_remove_file_if_exists(second_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native generate command reads grammar and writes outputs" {
  let dir = native_test_dir("generate")
  native_create_clean_dir(dir)
  let grammar_path = dir + "/grammar.json"
  let config_path = dir + "/tree-sitter.json"
  native_write_text(grammar_path, native_minimal_grammar_json())
  native_write_text(config_path, "{\"metadata\":{\"version\":\"1.2.3\"}}")
  let command = @cli.CliGenerateCommand::{
    grammar_path: Some(grammar_path),
    output_dir: Some(dir),
    abi_version: None,
    js_runtime: None,
    log: false,
    no_parser: false,
    report_states_for_rule: None,
    json_summary: true,
    disable_optimizations: false,
  }
  let result = run_cli_generate_command_files(command)
  assert_eq(result.files.length(), 3)
  let language_path = dir + "/language.mbt"
  let node_types_path = dir + "/node-types.json"
  assert_true(
    read_cli_file_string(language_path).contains(
      "@tables.LanguageMetadata::new(major=1, minor=2, patch=3)",
    ),
  )
  assert_true(
    read_cli_file_string(node_types_path).contains("\"type\": \"document\""),
  )
  assert_true(result.json_summary is Some(_))
  native_remove_file_if_exists(language_path)
  native_remove_file_if_exists(dir + "/moon.pkg")
  native_remove_file_if_exists(node_types_path)
  native_remove_file_if_exists(config_path)
  native_remove_file_if_exists(grammar_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native generate command converts grammar js and writes parser outputs" {
  let dir = native_test_dir("generate_js")
  native_create_clean_dir(dir)
  let grammar_path = dir + "/grammar.js"
  native_write_text(grammar_path, native_minimal_grammar_js_cjs())
  let result = run_cli_generate_command_files(
    native_generate_command(Some(grammar_path), Some(dir), false),
  )
  assert_eq(result.files.length(), 4)
  assert_true(
    native_file_paths(result.files) ==
    [
      dir + "/grammar.json",
      dir + "/moon.pkg",
      dir + "/language.mbt",
      dir + "/node-types.json",
    ],
  )
  assert_true(
    read_cli_file_string(dir + "/grammar.json").contains("\"name\":\"minimal\""),
  )
  assert_true(
    result.json_summary ==
    Some(
      "{\"language\":\"minimal\",\"abi_version\":15,\"file_count\":4,\"warning_count\":0}",
    ),
  )
  native_remove_file_if_exists(dir + "/node-types.json")
  native_remove_file_if_exists(dir + "/language.mbt")
  native_remove_file_if_exists(dir + "/moon.pkg")
  native_remove_file_if_exists(dir + "/grammar.json")
  native_remove_file_if_exists(grammar_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native generate command with grammar js and no parser writes grammar and node types" {
  let dir = native_test_dir("generate_js_no_parser")
  native_create_clean_dir(dir)
  let grammar_path = dir + "/grammar.js"
  native_write_text(grammar_path, native_minimal_grammar_js_cjs())
  let result = run_cli_generate_command_files(
    native_generate_command(Some(grammar_path), Some(dir), true),
  )
  assert_eq(result.files.length(), 2)
  assert_true(
    native_file_paths(result.files) ==
    [dir + "/grammar.json", dir + "/node-types.json"],
  )
  assert_true(@fs.exists(dir + "/grammar.json"))
  assert_true(@fs.exists(dir + "/node-types.json"))
  assert_true(!@fs.exists(dir + "/language.mbt"))
  assert_true(!@fs.exists(dir + "/moon.pkg"))
  native_remove_file_if_exists(dir + "/node-types.json")
  native_remove_file_if_exists(dir + "/grammar.json")
  native_remove_file_if_exists(grammar_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native grammar js errors include runtime status and stderr" {
  let dir = native_test_dir("grammar_js_errors")
  native_create_clean_dir(dir)
  let grammar_path = dir + "/grammar.js"
  native_write_text(
    grammar_path, "module.exports = grammar({ name: 'bad', rules: {} });",
  )
  let missing_runtime = dir + "/missing-node"
  let missing_result = native_expect_error_string(() => {
    run_cli_generate_command_files(
      native_generate_command(
        Some(grammar_path),
        Some(dir),
        true,
        js_runtime=Some(missing_runtime),
      ),
    )
  })
  assert_true(missing_result.contains("GrammarJsLoadFailed"))
  assert_true(missing_result.contains(grammar_path))
  assert_true(missing_result.contains(missing_runtime))
  assert_true(missing_result.contains("-1"))
  native_write_text(grammar_path, "throw new Error('boom from grammar js');\n")
  let invalid_result = native_expect_error_string(() => {
    run_cli_generate_command_files(
      native_generate_command(Some(grammar_path), Some(dir), true),
    )
  })
  assert_true(invalid_result.contains("GrammarJsLoadFailed"))
  assert_true(invalid_result.contains(grammar_path))
  assert_true(invalid_result.contains("boom from grammar js"))
  native_remove_file_if_exists(grammar_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native grammar loader rejects unsupported extensions" {
  let dir = native_test_dir("grammar_extension")
  native_create_clean_dir(dir)
  let grammar_path = dir + "/grammar.txt"
  native_write_text(grammar_path, native_minimal_grammar_json())
  let result = native_expect_error_string(() => {
    read_cli_language_from_grammar_path(grammar_path)
  })
  assert_true(result.contains("UnsupportedGrammarFileExtension"))
  assert_true(result.contains(grammar_path))
  native_remove_file_if_exists(grammar_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native test command loads corpus and writes update files" {
  let dir = native_test_dir("test")
  native_create_clean_dir(dir)
  let corpus_path = dir + "/corpus.txt"
  native_write_text(
    corpus_path,
    (
      #|===
      #|Needs update
      #|===
      #|a
      #|---
      #|(wrong)
      #|
    ),
  )
  let command = @cli.CliTestCommand::{
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
  let result = run_cli_test_command_files(command, native_test_parser(), [
    corpus_path,
  ])
  assert_eq(result.exit_code, 1)
  assert_eq(result.files.length(), 1)
  assert_true(read_cli_file_string(corpus_path).contains("(document)"))
  native_remove_file_if_exists(corpus_path)
  native_remove_dir_if_exists(dir)
}

///|
async test "native test command reads corpus directories recursively" {
  let dir = native_test_dir("test_dir")
  native_create_clean_dir(dir)
  let corpus_dir = dir + "/corpus"
  let nested_dir = corpus_dir + "/nested"
  let hidden_dir = corpus_dir + "/.hidden"
  @fs.mkdir(corpus_dir)
  @fs.mkdir(nested_dir)
  @fs.mkdir(hidden_dir)
  let first_path = corpus_dir + "/a.txt"
  let second_path = nested_dir + "/b.txt"
  let hidden_path = hidden_dir + "/skip.txt"
  let passing =
    #|===
    #|Passing
    #|===
    #|a
    #|---
    #|(document)
    #|
  native_write_text(first_path, passing)
  native_write_text(second_path, passing)
  native_write_text(hidden_path, passing)
  let command = @cli.CliTestCommand::{
    include_pattern: None,
    exclude_pattern: None,
    file_name: None,
    config_path: None,
    grammar_path: None,
    lib_path: None,
    lang_name: None,
    update: false,
    show_fields: false,
    rebuild: false,
    overview_only: false,
    json_summary: false,
    stats: None,
  }
  let result = run_cli_test_command_files(command, native_test_parser(), [
    corpus_dir,
  ])
  assert_eq(result.exit_code, 0)
  assert_eq(result.files.length(), 2)
  assert_eq(result.summary.total, 2)
  assert_eq(result.summary.passed, 2)
  native_remove_file_if_exists(first_path)
  native_remove_file_if_exists(second_path)
  native_remove_file_if_exists(hidden_path)
  native_remove_dir_if_exists(hidden_dir)
  native_remove_dir_if_exists(nested_dir)
  native_remove_dir_if_exists(corpus_dir)
  native_remove_dir_if_exists(dir)
}
