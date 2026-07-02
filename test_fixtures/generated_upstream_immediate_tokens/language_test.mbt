///|
test "generated upstream immediate_tokens language metadata" {
  let language = language()
  assert_eq(language.name(), "immediate_tokens")
  assert_true(language.metadata() == @tables.LanguageMetadata::zero())
  assert_true(language.symbol_for_name("program", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("call", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("infix", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("prefix", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("identifier", is_named=true) is Some(_))
}

///|
test "generated upstream immediate_tokens parses infix corpus" {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language())
  let tree = parser.parse_string("a::b::c")
  assert_eq(
    tree.root_node().to_sexp(),
    "(program (infix (infix (identifier) (identifier)) (identifier)))",
  )
}
