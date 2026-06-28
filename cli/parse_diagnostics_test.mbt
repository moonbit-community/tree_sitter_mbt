///|
fn cli_parse_diagnostics_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "cli_parse_diagnostics_test",
      #|  "rules": {
      #|    "document": { "type": "STRING", "value": "a" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn cli_parse_diagnostics_tree(input : Bytes) -> @tree_sitter_mbt.Tree raise {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(cli_parse_diagnostics_language())
  parser.parse_bytes(input)
}

///|
test "cli parse diagnostics reports no problem for valid tree" {
  let tree = cli_parse_diagnostics_tree(b"a")
  assert_true(!tree_has_parse_problem(tree))
  assert_true(first_parse_problem(tree) is None)
}

///|
test "cli parse diagnostics finds first error node" {
  let tree = cli_parse_diagnostics_tree(b"x")
  guard first_parse_problem(tree) is Some(problem) else {
    fail("expected parse problem")
  }
  assert_true(tree_has_parse_problem(tree))
  assert_true(problem.kind is ErrorNode)
  assert_eq(problem.node_type, "ERROR")
  assert_true(problem.is_named)
  assert_eq(problem.start_byte, 0)
  assert_eq(problem.end_byte, 1)
  assert_true(problem.start_point == @api.Point::zero())
  assert_true(problem.end_point == @api.Point::new(row=0, column=1))
  assert_eq(render_parse_problem(problem), "(ERROR [0, 0] - [0, 1])")
}

///|
test "cli parse diagnostics finds missing node" {
  let tree = cli_parse_diagnostics_tree(b"")
  guard first_parse_problem(tree) is Some(problem) else {
    fail("expected parse problem")
  }
  assert_true(tree_has_parse_problem(tree))
  assert_true(problem.kind is MissingNode)
  assert_eq(problem.node_type, "a")
  assert_true(!problem.is_named)
  assert_eq(problem.start_byte, 0)
  assert_eq(problem.end_byte, 0)
  assert_true(problem.start_point == @api.Point::zero())
  assert_true(problem.end_point == @api.Point::zero())
  assert_eq(render_parse_problem(problem), "(MISSING \"a\" [0, 0] - [0, 0])")
}

///|
test "cli parse diagnostics escapes problem text" {
  let problem = CliParseProblem::{
    kind: MissingNode,
    node_type: "a\\b\nc",
    is_named: true,
    start_byte: 1,
    end_byte: 4,
    start_point: @api.Point::new(row=1, column=2),
    end_point: @api.Point::new(row=3, column=4),
  }
  assert_eq(
    render_parse_problem(problem),
    "(MISSING a\\\\b\\nc [1, 2] - [3, 4])",
  )
}
