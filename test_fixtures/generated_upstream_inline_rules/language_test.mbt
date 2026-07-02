///|
test "generated upstream inline_rules language metadata" {
  let language = language()
  assert_eq(language.name(), "inline_rules")
  assert_true(language.metadata() == @tables.LanguageMetadata::zero())
  assert_true(language.symbol_for_name("program", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("statement", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("sum", is_named=true) is Some(_))
  assert_true(language.symbol_for_name("product", is_named=true) is Some(_))
  assert_true(
    language.symbol_for_name("parenthesized_expression", is_named=true)
    is Some(_),
  )
}

///|
test "generated upstream inline_rules parses expression corpus" {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language())
  let input =
    #|1 + 2 * 3;
    #|4 * 5 + 6;
    #|7 * (8 + 9);
    #|
  let tree = parser.parse_string(input)
  assert_eq(
    tree.root_node().to_sexp(),
    "(program (statement (sum (number) (product (number) (number)))) (statement (sum (product (number) (number)) (number))) (statement (product (number) (parenthesized_expression (sum (number) (number))))))",
  )
}
