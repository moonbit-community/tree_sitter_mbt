///|
test "cli args parse command maps parse options" {
  let command = parse_cli_command_args([
    "parse", "--paths", "paths.txt", "--encoding=utf16-le", "--no-ranges", "--cst",
    "--config-path", "config.json", "--grammar-path", "grammar", "--lib-path", "parser.so",
    "--lang-name", "moonbit", "--scope", "source.mbt", "--time", "--rebuild",
  ])
  guard command is CliParse(parse) else { fail("expected parse command") }
  assert_true(parse.paths_file == Some("paths.txt"))
  assert_true(parse.paths.is_empty())
  assert_true(parse.encoding == Some(Utf16LE))
  assert_true(parse.output is CliParseCst)
  assert_true(parse.no_ranges)
  assert_true(parse.config_path == Some("config.json"))
  assert_true(parse.grammar_path == Some("grammar"))
  assert_true(parse.lib_path == Some("parser.so"))
  assert_true(parse.lang_name == Some("moonbit"))
  assert_true(parse.scope == Some("source.mbt"))
  assert_true(parse.time)
  assert_true(parse.rebuild)
}

///|
test "cli args parse command handles short flags" {
  let command = parse_cli_command_args(["p", "-q", "-t", "-n", "0"])
  guard command is CliParse(parse) else { fail("expected parse command") }
  assert_true(parse.output is CliParseQuiet)
  assert_true(parse.time)
  assert_true(parse.test_number == Some(0U))
  assert_true(parse.paths.is_empty())
}

///|
test "cli args parse command handles positional terminator" {
  let command = parse_cli_command_args(["p", "-c", "--", "-"])
  guard command is CliParse(parse) else { fail("expected parse command") }
  assert_true(parse.output is CliParseCst)
  assert_true(parse.test_number is None)
  assert_true(parse.paths == ["-"])
}

///|
test "cli args test command maps filters and report options" {
  let command = parse_cli_command_args([
    "test", "--include", "parse", "--exclude=slow", "--file-name", "corpus.txt",
    "--config-path", "config.json", "-p", "grammar", "-l", "parser.so", "--lang-name",
    "moonbit", "--update", "--show-fields", "--overview-only", "--json-summary",
    "--stat", "total-only",
  ])
  guard command is CliTest(test_command) else { fail("expected test command") }
  assert_true(test_command.include_pattern == Some("parse"))
  assert_true(test_command.exclude_pattern == Some("slow"))
  assert_true(test_command.file_name == Some("corpus.txt"))
  assert_true(test_command.config_path == Some("config.json"))
  assert_true(test_command.grammar_path == Some("grammar"))
  assert_true(test_command.lib_path == Some("parser.so"))
  assert_true(test_command.lang_name == Some("moonbit"))
  assert_true(test_command.update)
  assert_true(test_command.show_fields)
  assert_true(test_command.overview_only)
  assert_true(test_command.json_summary)
  assert_true(test_command.stats == Some(CliTestStatsTotalOnly))
}

///|
test "cli args test command accepts optional stat default" {
  let command = parse_cli_command_args(["t", "--stat", "-u"])
  guard command is CliTest(test_command) else { fail("expected test command") }
  assert_true(test_command.stats == Some(CliTestStatsOutliersAndTotal))
  assert_true(test_command.update)
}

///|
test "cli args generate command maps generation options" {
  let command = parse_cli_command_args([
    "gen", "grammar.json", "--output", "src", "--abi=latest", "--log", "--no-parser",
    "--report-states-for-rule", "-", "--json-summary", "--disable-optimizations",
    "--js-runtime", "node",
  ])
  guard command is CliGenerate(generate) else {
    fail("expected generate command")
  }
  assert_true(generate.grammar_path == Some("grammar.json"))
  assert_true(generate.output_dir == Some("src"))
  assert_true(generate.abi_version == Some("latest"))
  assert_true(generate.log)
  assert_true(generate.no_parser)
  assert_true(generate.report_states_for_rule == Some("-"))
  assert_true(generate.json_summary)
  assert_true(generate.disable_optimizations)
  assert_true(generate.js_runtime == Some("node"))
}

///|
test "cli args query command maps query options" {
  let command = parse_cli_command_args([
    "query", "queries/highlights.scm", "a.mbt", "b.mbt", "--matches", "--byte-range",
    "1:4", "--containing-byte-range=2:3", "--encoding", "utf16-be", "--scope", "source.mbt",
    "--config-path", "config.json", "--test", "--rebuild",
  ])
  guard command is CliQuery(query) else { fail("expected query command") }
  assert_true(query.query_path == Some("queries/highlights.scm"))
  assert_true(query.source_paths == ["a.mbt", "b.mbt"])
  assert_true(query.output is CliQueryMatches)
  assert_true(query.byte_range == Some({ start: 1U, end: 4U }))
  assert_true(query.containing_byte_range == Some({ start: 2U, end: 3U }))
  assert_true(query.encoding == Some(Utf16BE))
  assert_true(query.config_path == Some("config.json"))
  assert_true(query.scope == Some("source.mbt"))
  assert_true(query.test_mode)
  assert_true(query.rebuild)
}

///|
test "cli args tags command maps tagging options" {
  let command = parse_cli_command_args([
    "tags", "--paths", "paths.txt", "--scope", "source.mbt", "--config-path", "config.json",
    "-p", "grammar.json", "-t", "-q", "-r",
  ])
  guard command is CliTags(tags) else { fail("expected tags command") }
  assert_true(tags.paths_file == Some("paths.txt"))
  assert_true(tags.paths.is_empty())
  assert_true(tags.scope == Some("source.mbt"))
  assert_true(tags.config_path == Some("config.json"))
  assert_true(tags.grammar_path == Some("grammar.json"))
  assert_true(tags.time)
  assert_true(tags.quiet)
  assert_true(tags.rebuild)
}

///|
test "cli args reports command and option errors" {
  let missing = @test.expect_error(() => parse_cli_command_args([]))
  assert_true(missing is MissingCommand)
  let unknown = @test.expect_error(() => parse_cli_command_args(["unknown"]))
  assert_true(unknown is UnknownCommand("unknown"))
  let option = @test.expect_error(() => {
    parse_cli_command_args(["parse", "--bad"])
  })
  assert_true(option is UnknownOption("--bad"))
}

///|
test "cli args reports invalid values and conflicts" {
  let encoding = @test.expect_error(() => {
    parse_cli_command_args(["parse", "--encoding", "latin1"])
  })
  assert_true(
    encoding is InvalidOptionValue(option="--encoding", value="latin1"),
  )
  let number = @test.expect_error(() => {
    parse_cli_command_args(["parse", "-n", "abc"])
  })
  assert_true(number is InvalidOptionValue(option="-n", value="abc"))
  let conflict = @test.expect_error(() => {
    parse_cli_command_args(["parse", "--paths", "paths.txt", "source.mbt"])
  })
  assert_true(conflict is ConflictingOptions("--paths", "paths"))
  let range = @test.expect_error(() => {
    parse_cli_command_args(["query", "query.scm", "--byte-range", "5:3"])
  })
  assert_true(range is InvalidOptionValue(option="--byte-range", value="5:3"))
  let query_conflict = @test.expect_error(() => {
    parse_cli_command_args(["query", "query.scm", "-n", "1", "source.mbt"])
  })
  assert_true(query_conflict is ConflictingOptions("--test-number", "paths"))
}

///|
test "cli args reports missing values and unexpected arguments" {
  let missing = @test.expect_error(() => {
    parse_cli_command_args(["test", "--include"])
  })
  assert_true(missing is MissingOptionValue("--include"))
  let positional = @test.expect_error(() => {
    parse_cli_command_args(["test", "corpus"])
  })
  assert_true(positional is UnexpectedArgument("corpus"))
}
