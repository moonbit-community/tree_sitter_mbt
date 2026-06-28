///|
fn cli_parse_pair_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "cli_parse_pair_test",
      #|  "rules": {
      #|    "document": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        { "type": "FIELD", "name": "left", "content": { "type": "SYMBOL", "name": "item" } },
      #|        { "type": "STRING", "value": "b" }
      #|      ]
      #|    },
      #|    "item": { "type": "STRING", "value": "a" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
test "cli renders normal parse output with ranges and fields" {
  let language = cli_parse_pair_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"ab")
  assert_eq(
    render_parse_normal_tree(tree),
    (
      #|(document [0, 0] - [0, 2]
      #|  left: (item [0, 0] - [0, 1]))
      #|
    ),
  )
}

///|
test "cli renders normal parse output without ranges" {
  let language = cli_parse_pair_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"ab")
  assert_eq(
    render_parse_normal_tree(tree, no_ranges=true),
    (
      #|(document
      #|  left: (item))
      #|
    ),
  )
}
