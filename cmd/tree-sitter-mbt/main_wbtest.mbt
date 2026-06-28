///|
async test "main dispatch reports argument errors" {
  let result = run_tree_sitter_mbt_cli_args([])
  assert_eq(result.exit_code, 2)
  assert_eq(result.stdout, "error: missing command")
}

///|
async test "main dispatch routes parse command to native runner" {
  let result = run_tree_sitter_mbt_cli_args(["parse"])
  assert_eq(result.exit_code, 1)
  assert_true(result.stdout.contains("MissingLanguageConfig"))
}

///|
async test "main dispatch renders generate option errors" {
  let result = run_tree_sitter_mbt_cli_args(["generate", "--bad-option"])
  assert_eq(result.exit_code, 2)
  assert_eq(result.stdout, "error: unknown option `--bad-option`")
}

///|
async test "main trims one trailing newline before printing" {
  assert_eq(trim_single_trailing_newline("a\n"), "a")
  assert_eq(trim_single_trailing_newline("a\n\n"), "a\n")
  assert_eq(trim_single_trailing_newline("a"), "a")
}
