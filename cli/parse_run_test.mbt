///|
test "cli parse runner returns normal output and success status" {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(cli_parse_pair_language())
  let result = run_cli_parse_source(parser, b"ab", no_ranges=true)
  assert_true(result.successful)
  assert_true(result.problem is None)
  assert_true(result.encoding == Utf8)
  assert_eq(
    result.output,
    (
      #|(document
      #|  left: (item))
      #|
    ),
  )
  assert_true(!cli_parse_results_have_error([result]))
  assert_eq(cli_parse_exit_code([result]), 0)
}

///|
test "cli parse runner selects cst output" {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(cli_parse_pair_language())
  let result = run_cli_parse_source(
    parser,
    b"ab",
    output=CliParseCst,
    no_ranges=true,
  )
  assert_true(result.successful)
  assert_eq(
    result.output,
    (
      #|document
      #|  left: item `a`
      #|  "b"
      #|
    ),
  )
}

///|
test "cli parse runner reports parse errors for exit status" {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(cli_parse_diagnostics_language())
  let result = run_cli_parse_source(parser, b"x", output=CliParseQuiet)
  assert_true(!result.successful)
  assert_eq(result.output, "")
  guard result.problem is Some(problem) else { fail("expected parse problem") }
  assert_true(problem.kind is ErrorNode)
  assert_true(cli_parse_results_have_error([result]))
  assert_eq(cli_parse_exit_code([result]), 1)
}

///|
test "cli parse runner applies utf16 bom encoding" {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(cli_parse_diagnostics_language())
  let result = run_cli_parse_source(
    parser,
    Bytes::from_array([b'\xFF', b'\xFE', b'a', b'\x00']),
    no_ranges=true,
  )
  assert_true(result.successful)
  assert_true(result.encoding == Utf16LE)
  assert_eq(
    result.output,
    (
      #|(document)
      #|
    ),
  )
}

///|
test "cli parse runner explicit encoding overrides bom" {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(cli_parse_diagnostics_language())
  let result = run_cli_parse_source(
    parser,
    Bytes::from_array([b'\xFF', b'\xFE', b'a', b'\x00']),
    output=CliParseQuiet,
    encoding=Utf8,
  )
  assert_true(!result.successful)
  assert_true(result.encoding == Utf8)
}
