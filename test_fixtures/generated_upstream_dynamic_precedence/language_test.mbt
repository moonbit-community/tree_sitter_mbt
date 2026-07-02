///|
test "generated upstream dynamic_precedence language metadata" {
  let language = language()
  assert_eq(language.name(), "dynamic_precedence")
  assert_true(language.metadata() == @tables.LanguageMetadata::zero())
  assert_true(language.symbol_for_name("program", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("declaration", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("declarator", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("expression", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("identifier", is_named=true) is Some(_))
}

///|
test "generated upstream dynamic_precedence parses declaration corpus" {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language())
  let tree = parser.parse_string("T * x")
  assert_eq(
    tree.root_node().to_sexp(),
    "(program (declaration (type (identifier)) (declarator (identifier))))",
  )
}
