///|
test "cli input encoding parses option names" {
  assert_true(@cli.parse_cli_input_encoding("utf8") == Utf8)
  assert_true(@cli.parse_cli_input_encoding("utf16-le") == Utf16LE)
  assert_true(@cli.parse_cli_input_encoding("utf16-be") == Utf16BE)
}

///|
test "cli input encoding rejects unknown option name" {
  let result = @test.expect_error(() => @cli.parse_cli_input_encoding("utf16"))
  let @cli.CliEncodingError::UnknownEncoding(name) = result
  assert_eq(name, "utf16")
}

///|
test "cli input encoding detects utf16 bom when unspecified" {
  assert_true(
    @cli.select_cli_input_encoding(
      Bytes::from_array([b'\xFF', b'\xFE', b'a', b'\x00']),
    ) ==
    Utf16LE,
  )
  assert_true(
    @cli.select_cli_input_encoding(
      Bytes::from_array([b'\xFE', b'\xFF', b'\x00', b'a']),
    ) ==
    Utf16BE,
  )
  assert_true(@cli.select_cli_input_encoding(b"a") == Utf8)
}

///|
test "cli input encoding explicit option overrides bom" {
  assert_true(
    @cli.select_cli_input_encoding(
      Bytes::from_array([b'\xFF', b'\xFE']),
      requested=Utf8,
    ) ==
    Utf8,
  )
}

///|
fn cli_encoding_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "cli_encoding_test",
      #|  "rules": {
      #|    "document": { "type": "STRING", "value": "a" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
test "cli input from bytes applies detected utf16 encoding" {
  let input = @cli.cli_input_from_bytes(
    Bytes::from_array([b'\xFF', b'\xFE', b'a', b'\x00']),
  )
  assert_true(input.encoding() == Utf16LE)

  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(cli_encoding_language())
  let tree = parser.parse(input)
  assert_true(!@cli.tree_has_parse_problem(tree))
  assert_eq(tree.root_node().child(0).start_byte(), 2)
}
