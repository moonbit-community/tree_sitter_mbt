///|
test "cli renders cst output with ranges and fields" {
  let language = cli_parse_pair_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"ab")
  assert_eq(
    render_parse_cst_tree(b"ab", tree),
    (
      #|0:0 - 0:2   document
      #|0:0 - 0:1     left: item `a`
      #|0:1 - 0:2     "b"
      #|
    ),
  )
}

///|
test "cli renders cst output without ranges" {
  let language = cli_parse_pair_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"ab")
  assert_eq(
    render_parse_cst_tree(b"ab", tree, no_ranges=true),
    (
      #|document
      #|  left: item `a`
      #|  "b"
      #|
    ),
  )
}

///|
test "cli renders cst missing anonymous node" {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(cli_parse_diagnostics_language())
  let tree = parser.parse_bytes(b"")
  assert_eq(
    render_parse_cst_tree(b"", tree),
    (
      #|0:0 - 0:0   •document
      #|0:0 - 0:0     MISSING: "a"
      #|
    ),
  )
}
