///|
test "generated minimal language validates" {
  let language = language()
  assert_eq(language.name(), "minimal")
  assert_eq(language.symbol_count(), 3)
  assert_true(language.symbol_name(@api.SymbolId::new(1)) == Some("a"))
  assert_true(language.symbol_name(@api.SymbolId::new(2)) == Some("document"))
}

///|
test "generated minimal language parses valid input" {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language())
  let tree = parser.parse_bytes(b"a")
  assert_eq(tree.root_node().to_sexp(), "(document)")
}
