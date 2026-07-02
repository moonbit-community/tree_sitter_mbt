///|
test "generated upstream reserved_words language metadata" {
  let language = language()
  assert_eq(language.name(), "reserved_words")
  assert_true(language.metadata() == @tables.LanguageMetadata::zero())
  assert_true(language.symbol_for_name("program", is_named=true) is Some(_))
  assert_true(
    language.symbol_for_name("if_statement", is_named=true) is Some(_),
  )
  assert_true(
    language.symbol_for_name("var_declaration", is_named=true) is Some(_),
  )
  assert_true(
    language.symbol_for_name("while_statement", is_named=true) is Some(_),
  )
  assert_true(language.symbol_for_name("identifier", is_named=true) is Some(_))
}

///|
test "generated upstream reserved_words parses valid code corpus" {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language())
  let input =
    #|if (a) {
    #|  var b = {
    #|    c: d,
    #|    e: f,
    #|  };
    #|  while (g) {
    #|    h();
    #|  }
    #|}
    #|
  let tree = parser.parse_string(input)
  assert_eq(
    tree.root_node().to_sexp(),
    "(program (if_statement (parenthesized_expression (identifier)) (block (var_declaration (identifier) (object (pair (identifier) (identifier)) (pair (identifier) (identifier)))) (while_statement (parenthesized_expression (identifier)) (block (expression_statement (call_expression (identifier))))))))",
  )
}
