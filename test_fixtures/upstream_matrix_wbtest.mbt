///|
test "upstream fixture manifest covers v1 matrix" {
  let fixtures = upstream_fixture_manifest()
  assert_eq(fixtures.length(), 56)
  assert_eq(count_upstream_status(fixtures, RunnableCorpus), 30)
  assert_eq(count_upstream_status(fixtures, ExpectedGenerateError), 10)
  assert_eq(count_upstream_status(fixtures, UnsupportedExternalScanner), 16)
  match duplicate_upstream_fixture_name(fixtures) {
    Some(name) => fail("duplicate upstream fixture " + name)
    None => ()
  }
  for name in expected_runnable_fixture_names() {
    assert_upstream_manifest_has(fixtures, name, RunnableCorpus)
  }
  for name in expected_generate_error_fixture_names() {
    assert_upstream_manifest_has(fixtures, name, ExpectedGenerateError)
  }
  for name in expected_scanner_fixture_names() {
    assert_upstream_manifest_has(fixtures, name, UnsupportedExternalScanner)
  }
}

///|
test "upstream expected-error fixtures fail local generation as classified" {
  for fixture in upstream_fixture_manifest() {
    if fixture.status != ExpectedGenerateError {
      continue
    }
    guard fixture.grammar_json is Some(grammar_json) else {
      fail("expected grammar json for " + fixture.name)
    }
    guard fixture.expected_error is Some(expected_error) else {
      fail("expected local error classification for " + fixture.name)
    }
    try @generator.generate_language(grammar_json) catch {
      err =>
        assert_generate_error_matches(
          fixture.name,
          @debug.to_string(err),
          expected_error,
        )
    } noraise {
      _ => fail("expected generation to fail for " + fixture.name)
    }
  }
}

///|
test "upstream runnable corpus fixtures pass through generator and runtime" {
  for fixture in upstream_fixture_manifest() {
    if fixture.status != RunnableCorpus {
      continue
    }
    let parser = upstream_fixture_parser(fixture)
    let corpus = upstream_fixture_corpus(fixture)
    let results = @cli.run_cli_corpus_file(parser, corpus) catch {
      err =>
        fail(
          "fixture " +
          fixture.name +
          " raised while running corpus: " +
          @debug.to_string(err),
        )
    }
    assert_corpus_results_pass(fixture.name, results)
  }
}

///|
test "upstream runnable corpus fixtures reparse edited input like fresh parse" {
  for fixture in upstream_fixture_manifest() {
    if fixture.status != RunnableCorpus {
      continue
    }
    let parser = upstream_fixture_parser(fixture)
    let corpus = upstream_fixture_corpus(fixture)
    for example in corpus.examples {
      assert_incremental_parse_matches_fresh(
        fixture.name,
        example.name,
        parser,
        example.input,
      ) catch {
        err =>
          fail(
            "fixture " +
            fixture.name +
            " example " +
            example.name +
            " raised while reparsing: " +
            @debug.to_string(err),
          )
      }
    }
  }
}

///|
fn upstream_fixture_parser(
  fixture : UpstreamFixture,
) -> @tree_sitter_mbt.Parser raise {
  guard fixture.grammar_json is Some(grammar_json) else {
    fail("expected grammar json for " + fixture.name)
  }
  let generated = @generator.generate_language(grammar_json) catch {
    err =>
      fail(
        "fixture " +
        fixture.name +
        " failed generation: " +
        @debug.to_string(err),
      )
  }
  let language = @tree_sitter_mbt.language_from_generated_tables(
    generated.tables,
  )
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  parser
}

///|
fn upstream_fixture_corpus(
  fixture : UpstreamFixture,
) -> @cli.CliCorpusFile raise {
  guard fixture.corpus is Some(corpus) else {
    fail("expected corpus for " + fixture.name)
  }
  let file = @cli.parse_corpus_file_contents(
    fixture.name,
    corpus,
    file_name=fixture.upstream_path + "/corpus.txt",
    current_platform="linux",
  )
  if file.examples.is_empty() &&
    !upstream_fixture_allows_empty_corpus(fixture.name) {
    fail("expected corpus examples for " + fixture.name)
  }
  file
}

///|
fn upstream_fixture_allows_empty_corpus(name : String) -> Bool {
  name == "named_precedences"
}

///|
fn assert_generate_error_matches(
  fixture_name : String,
  rendered : String,
  expected : UpstreamExpectedGenerateError,
) -> Unit raise {
  if !rendered.contains(expected.category) {
    fail(
      "fixture " +
      fixture_name +
      " expected error category " +
      expected.category +
      ", got " +
      rendered,
    )
  }
  for fragment in expected.message_fragments {
    if !rendered.contains(fragment) {
      fail(
        "fixture " +
        fixture_name +
        " expected error fragment " +
        fragment +
        ", got " +
        rendered,
      )
    }
  }
}

///|
fn assert_corpus_results_pass(
  fixture_name : String,
  results : Array[@cli.CliCorpusRunResult],
) -> Unit raise {
  if results.is_empty() {
    if upstream_fixture_allows_empty_corpus(fixture_name) {
      return
    }
    fail("expected corpus results for " + fixture_name)
  }
  for result in results {
    if !(result.status is @cli.CorpusRunPassed) {
      fail(
        "fixture " +
        fixture_name +
        " example " +
        result.name +
        " failed: expected " +
        result.expected +
        ", actual " +
        result.actual,
      )
    }
  }
}

///|
fn assert_incremental_parse_matches_fresh(
  fixture_name : String,
  example_name : String,
  parser : @tree_sitter_mbt.Parser,
  input : Bytes,
) -> Unit raise {
  let old_tree = parser.parse_bytes(input)
  let edited_old_tree = old_tree.copy()
  let end_byte = input.length().reinterpret_as_uint()
  let end_point = input_end_point(input)
  edited_old_tree.edit(
    @api.InputEdit::new(
      start_byte=end_byte,
      old_end_byte=end_byte,
      new_end_byte=end_byte + 1U,
      start_point=end_point,
      old_end_point=end_point,
      new_end_point=@api.Point::new(
        row=end_point.row,
        column=end_point.column + 1U,
      ),
    ),
  )
  let edited_input = append_ascii_space(input)
  let reparsed = parser.parse_bytes(
    edited_input,
    old_tree=Some(edited_old_tree),
  )
  let fresh = parser.parse_bytes(edited_input)
  if reparsed.to_sexp() != fresh.to_sexp() {
    fail(
      "fixture " +
      fixture_name +
      " example " +
      example_name +
      " incremental parse differed: reparsed " +
      reparsed.to_sexp() +
      ", fresh " +
      fresh.to_sexp(),
    )
  }
}

///|
fn input_end_point(input : Bytes) -> @api.Point {
  let mut row = 0U
  let mut column = 0U
  for i in 0..<input.length() {
    if input[i] == b'\n' {
      row += 1U
      column = 0U
    } else {
      column += 1U
    }
  }
  @api.Point::new(row~, column~)
}

///|
fn append_ascii_space(input : Bytes) -> Bytes {
  let bytes : Array[Byte] = []
  for i in 0..<input.length() {
    bytes.push(input[i])
  }
  bytes.push(b' ')
  Bytes::from_array(bytes)
}

///|
fn count_upstream_status(
  fixtures : Array[UpstreamFixture],
  status : UpstreamFixtureStatus,
) -> Int {
  let mut count = 0
  for fixture in fixtures {
    if fixture.status == status {
      count += 1
    }
  }
  count
}

///|
fn duplicate_upstream_fixture_name(
  fixtures : Array[UpstreamFixture],
) -> String? {
  for index, fixture in fixtures {
    for other_index in 0..<index {
      if fixtures[other_index].name == fixture.name {
        return Some(fixture.name)
      }
    }
  }
  None
}

///|
fn assert_upstream_manifest_has(
  fixtures : Array[UpstreamFixture],
  name : String,
  status : UpstreamFixtureStatus,
) -> Unit raise {
  for fixture in fixtures {
    if fixture.name == name && fixture.status == status {
      return
    }
  }
  fail("missing upstream fixture " + name)
}

///|
fn expected_runnable_fixture_names() -> Array[String] {
  [
    "aliased_inlined_rules", "aliased_rules", "aliased_token_rules", "aliased_unit_reductions",
    "aliases_in_root", "anonymous_error", "anonymous_tokens_with_escaped_chars",
    "associativity_left", "associativity_right", "dynamic_precedence", "extra_non_terminals",
    "extra_non_terminals_with_shared_rules", "immediate_tokens", "inline_rules",
    "inlined_aliased_rules", "lexical_conflicts_due_to_state_merging", "named_precedences",
    "named_rule_aliased_as_anonymous", "nested_inlined_rules", "next_sibling_from_zwt",
    "precedence_on_single_child_negative", "precedence_on_single_child_positive",
    "precedence_on_subsequence", "precedence_on_token", "readme_grammar", "reserved_words",
    "start_rule_is_blank", "start_rule_is_token", "unicode_classes", "unused_rules",
  ]
}

///|
fn expected_generate_error_fixture_names() -> Array[String] {
  [
    "associativity_missing", "conflict_in_repeat_rule", "conflict_in_repeat_rule_after_external_token",
    "conflicting_precedence", "epsilon_rules", "indirect_recursion_in_transitions",
    "invisible_start_rule", "partially_resolved_conflict", "precedence_on_single_child_missing",
    "terminal_supertype",
  ]
}

///|
fn expected_scanner_fixture_names() -> Array[String] {
  [
    "depends_on_column", "epsilon_external_extra_tokens", "epsilon_external_tokens",
    "external_and_internal_anonymous_tokens", "external_and_internal_tokens", "external_extra_tokens",
    "external_lookahead_eof_boundary", "external_tokens", "external_unicode_column_alignment",
    "get_col_eof", "get_col_should_hang_not_crash", "inverted_external_token", "uses_current_column",
    "utf16_surrogate_oob", "wasm_realloc_clobber_region", "wasm_realloc_overflow_heap",
  ]
}
