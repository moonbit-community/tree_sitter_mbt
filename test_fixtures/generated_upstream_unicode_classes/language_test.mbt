///|
test "generated upstream unicode_classes language metadata" {
  let language = language()
  assert_eq(language.name(), "unicode_classes")
  assert_true(language.metadata() == @tables.LanguageMetadata::zero())
  assert_true(language.symbol_for_name("program", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("lower", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("upper", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("math_sym", is_named=true) is Some(_))
  assert_true(
    language.symbol_for_name("letter_number", is_named=true) is Some(_),
  )
}

///|
test "generated upstream unicode_classes parses uppercase corpus" {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language())
  let tree = parser.parse_string("Δბㄱ  Ψ  Ɓƀ  Ƒ  Ɣ  Śřř")
  assert_eq(
    tree.root_node().to_sexp(),
    "(program (upper) (upper) (upper) (upper) (upper) (upper))",
  )
}
