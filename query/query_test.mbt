///|
fn query_test_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "query_test",
      #|  "rules": {
      #|    "document": { "type": "SYMBOL", "name": "item" },
      #|    "item": { "type": "STRING", "value": "a" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn query_test_literal_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "query_literal_test",
      #|  "rules": {
      #|    "document": { "type": "STRING", "value": "a" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn query_test_text_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "query_text_test",
      #|  "rules": {
      #|    "document": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        { "type": "STRING", "value": "1" },
      #|        { "type": "STRING", "value": " " },
      #|        { "type": "STRING", "value": "a" }
      #|      ]
      #|    }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn query_test_pair_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "query_pair_test",
      #|  "rules": {
      #|    "document": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        { "type": "SYMBOL", "name": "item" },
      #|        { "type": "STRING", "value": "b" }
      #|      ]
      #|    },
      #|    "item": { "type": "STRING", "value": "a" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn query_test_pair_tree() -> @tree_sitter_mbt.Tree raise {
  let language = query_test_pair_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  parser.parse_bytes(b"ab")
}

///|
fn query_test_field_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "query_field_test",
      #|  "rules": {
      #|    "document": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        {
      #|          "type": "FIELD",
      #|          "name": "left",
      #|          "content": { "type": "SYMBOL", "name": "item" }
      #|        },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "right",
      #|          "content": { "type": "SYMBOL", "name": "other" }
      #|        }
      #|      ]
      #|    },
      #|    "item": { "type": "STRING", "value": "a" },
      #|    "other": { "type": "STRING", "value": "b" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn query_test_hidden_field_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "query_hidden_field_test",
      #|  "rules": {
      #|    "document": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        {
      #|          "type": "FIELD",
      #|          "name": "left",
      #|          "content": { "type": "SYMBOL", "name": "_wrapped" }
      #|        },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "right",
      #|          "content": { "type": "SYMBOL", "name": "other" }
      #|        }
      #|      ]
      #|    },
      #|    "_wrapped": { "type": "SYMBOL", "name": "item" },
      #|    "item": { "type": "STRING", "value": "a" },
      #|    "other": { "type": "STRING", "value": "b" }
      #|  },
      #|  "inline": ["_wrapped"]
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn query_test_many_fields_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "query_many_fields_test",
      #|  "rules": {
      #|    "document": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        { "type": "SYMBOL", "name": "item" },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "f1",
      #|          "content": { "type": "SYMBOL", "name": "other" }
      #|        },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "f2",
      #|          "content": { "type": "SYMBOL", "name": "other" }
      #|        },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "f3",
      #|          "content": { "type": "SYMBOL", "name": "other" }
      #|        },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "f4",
      #|          "content": { "type": "SYMBOL", "name": "other" }
      #|        },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "f5",
      #|          "content": { "type": "SYMBOL", "name": "other" }
      #|        },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "f6",
      #|          "content": { "type": "SYMBOL", "name": "other" }
      #|        },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "f7",
      #|          "content": { "type": "SYMBOL", "name": "other" }
      #|        },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "f8",
      #|          "content": { "type": "SYMBOL", "name": "other" }
      #|        },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "f9",
      #|          "content": { "type": "SYMBOL", "name": "other" }
      #|        }
      #|      ]
      #|    },
      #|    "item": { "type": "STRING", "value": "a" },
      #|    "other": { "type": "STRING", "value": "b" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn query_test_repeat_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "query_repeat_test",
      #|  "rules": {
      #|    "document": {
      #|      "type": "REPEAT",
      #|      "content": { "type": "SYMBOL", "name": "item" }
      #|    },
      #|    "item": { "type": "STRING", "value": "a" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn query_test_mixed_repeat_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "query_mixed_repeat_test",
      #|  "rules": {
      #|    "document": {
      #|      "type": "REPEAT",
      #|      "content": {
      #|        "type": "CHOICE",
      #|        "members": [
      #|          { "type": "SYMBOL", "name": "item" },
      #|          { "type": "SYMBOL", "name": "other" }
      #|        ]
      #|      }
      #|    },
      #|    "item": { "type": "STRING", "value": "a" },
      #|    "other": { "type": "STRING", "value": "b" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn query_test_anchor_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "query_anchor_test",
      #|  "rules": {
      #|    "document": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        { "type": "STRING", "value": "b" },
      #|        { "type": "SYMBOL", "name": "item" },
      #|        { "type": "SYMBOL", "name": "other" },
      #|        { "type": "SYMBOL", "name": "item" }
      #|      ]
      #|    },
      #|    "item": { "type": "STRING", "value": "a" },
      #|    "other": { "type": "STRING", "value": "c" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn query_test_anchor_tree() -> @tree_sitter_mbt.Tree raise {
  let language = query_test_anchor_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  parser.parse_bytes(b"baca")
}

///|
fn query_test_supertype_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "query_supertype_test",
      #|  "rules": {
      #|    "document": { "type": "SYMBOL", "name": "expr" },
      #|    "expr": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        { "type": "SYMBOL", "name": "literal" },
      #|        { "type": "SYMBOL", "name": "identifier" },
      #|        { "type": "STRING", "value": "?" }
      #|      ]
      #|    },
      #|    "literal": { "type": "STRING", "value": "a" },
      #|    "identifier": { "type": "STRING", "value": "b" }
      #|  },
      #|  "supertypes": ["expr"]
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn query_test_supertype_tree(source : Bytes) -> @tree_sitter_mbt.Tree raise {
  let language = query_test_supertype_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  parser.parse_bytes(source)
}

///|
fn query_capture_names(cursor : QueryCursor) -> Array[String] {
  let names : Array[String] = []
  while true {
    match cursor.next_capture() {
      Some(capture) => names.push(capture.name)
      None => break
    }
  }
  names
}

///|
fn query_parser_public_snapshot(query : Query) -> String {
  let builder = StringBuilder::new()
  builder.write_string("patterns: \{query.pattern_count()}\n")
  builder.write_string("captures:\n")
  for capture_id in 0..<query.capture_count() {
    builder.write_string(
      "  \{capture_id}: \{query.capture_name_for_id(capture_id).unwrap_or("?")}\n",
    )
  }
  builder.write_string("strings:\n")
  for string_id in 0..<query.string_count() {
    builder.write_string(
      "  \{string_id}: \{query.string_value_for_id(string_id).unwrap_or("?")}\n",
    )
  }
  for pattern_index in 0..<query.pattern_count() {
    builder.write_string("pattern \{pattern_index}:\n")
    builder.write_string(
      "  range: \{query.start_byte_for_pattern(pattern_index).unwrap_or(-1)}..\{query.end_byte_for_pattern(pattern_index).unwrap_or(-1)}\n",
    )
    builder.write_string(
      "  rooted: \{query_bool_option_snapshot(query.is_pattern_rooted(pattern_index))}\n",
    )
    builder.write_string(
      "  non_local: \{query_bool_option_snapshot(query.is_pattern_non_local(pattern_index))}\n",
    )
    builder.write_string("  quantifiers:")
    for capture_id in 0..<query.capture_count() {
      builder.write_string(
        " \{query.capture_name_for_id(capture_id).unwrap_or("?")}=\{query_quantifier_snapshot(query.capture_quantifier_for_id(pattern_index, capture_id))}",
      )
    }
    builder.write_char('\n')
    builder.write_string("  predicate_steps:")
    let step_count = query
      .predicate_step_count_for_pattern(pattern_index)
      .unwrap_or(0)
    for step_index in 0..<step_count {
      builder.write_string(
        " \{query_predicate_step_snapshot(query, query.predicate_step_for_pattern(pattern_index, step_index))}",
      )
    }
    builder.write_char('\n')
  }
  builder.to_string()
}

///|
fn query_bool_option_snapshot(value : Bool?) -> String {
  match value {
    Some(true) => "true"
    Some(false) => "false"
    None => "none"
  }
}

///|
fn query_quantifier_snapshot(value : QueryCaptureQuantifier?) -> String {
  match value {
    Some(Zero) => "Zero"
    Some(ZeroOrOne) => "ZeroOrOne"
    Some(ZeroOrMore) => "ZeroOrMore"
    Some(One) => "One"
    Some(OneOrMore) => "OneOrMore"
    None => "none"
  }
}

///|
fn query_predicate_step_snapshot(
  query : Query,
  step : QueryPredicateStep?,
) -> String {
  match step {
    Some(Done) => "Done"
    Some(Capture(id)) =>
      "Capture(@\{query.capture_name_for_id(id).unwrap_or("?")})"
    Some(String(id)) =>
      "String(\{query.string_value_for_id(id).unwrap_or("?")})"
    None => "none"
  }
}

///|
test "query parses named patterns and capture accessors" {
  let language = query_test_language()
  let query = Query::new(
    language,
    (
      #|; leading comment
      #|(item) @node
      #|(document) @root
    ),
  )
  assert_eq(query.pattern_count(), 2)
  assert_eq(query.capture_count(), 2)
  assert_true(query.capture_name_for_id(0) == Some("node"))
  assert_true(query.capture_name_for_id(1) == Some("root"))
  assert_true(query.start_byte_for_pattern(0) is Some(_))
  assert_true(query.end_byte_for_pattern(1) is Some(_))
  assert_true(query.is_pattern_guaranteed_at_step(0, 0) == Some(true))
  assert_true(query.is_pattern_guaranteed_at_step(0, 1) == Some(false))
  assert_true(query.is_pattern_guaranteed_at_step(0, -1) == Some(false))
  assert_true(query.capture_quantifier_for_id(0, 0) == Some(One))
  assert_true(query.capture_quantifier_for_id(0, 1) == Some(Zero))
  assert_true(query.capture_quantifier_for_id(1, 0) == Some(Zero))
  assert_true(query.capture_quantifier_for_id(0, 2) is None)
  assert_true(query.capture_quantifier_for_id(2, 0) is None)
  assert_true(query.capture_quantifier_for_id(0, -1) is None)
}

///|
test "query parser public API snapshot" {
  let language = query_test_language()
  let query = Query::new(
    language,
    (
      #|; leading comment
      #|(item) @node
      #|  (#eq? @node "a")
      #|(document) @root
    ),
  )
  inspect(
    query_parser_public_snapshot(query),
    content=(
      #|patterns: 2
      #|captures:
      #|  0: node
      #|  1: root
      #|strings:
      #|  0: eq?
      #|  1: a
      #|pattern 0:
      #|  range: 18..50
      #|  rooted: true
      #|  non_local: false
      #|  quantifiers: node=One root=Zero
      #|  predicate_steps: String(eq?) Capture(@node) String(a) Done
      #|pattern 1:
      #|  range: 50..66
      #|  rooted: true
      #|  non_local: false
      #|  quantifiers: node=Zero root=One
      #|  predicate_steps:
      #|
    ),
  )
}

///|
test "query pattern source ranges use utf8 byte offsets" {
  let language = query_test_language()
  let source = "; 文\n(item) @node"
  let query = Query::new(language, source)
  assert_true(query.start_byte_for_pattern(0) == Some(6))
  assert_true(query.end_byte_for_pattern(0) == Some(18))
}

///|
test "query parser applies identifier and unicode whitespace boundaries" {
  let language = query_test_language()
  let query = Query::new(
    language, "(item)\u{3000}@\u{0663}.node @_node @-node @é.node",
  )
  assert_eq(query.capture_count(), 4)
  assert_true(query.capture_name_for_id(0) == Some("\u{0663}.node"))
  assert_true(query.capture_name_for_id(1) == Some("_node"))
  assert_true(query.capture_name_for_id(2) == Some("-node"))
  assert_true(query.capture_name_for_id(3) == Some("é.node"))

  let predicate = Query::new(
    language, "(item) @node\n(\u{3000}#é-op? @node arg.name)",
  )
  assert_true(predicate.predicate_step_count_for_pattern(0) == Some(4))
  assert_true(predicate.string_value_for_id(0) == Some("é-op?"))
  assert_true(predicate.string_value_for_id(1) == Some("arg.name"))

  let dot_start = @test.expect_error(() => Query::new(language, "(item) @.node"))
  assert_true(dot_start is Syntax(byte_offset=8, ..))

  let cjk_capture = Query::new(language, "(item) @节点")
  assert_true(cjk_capture.capture_name_for_id(0) == Some("节点"))
}

///|
test "query errors use utf8 byte offsets" {
  let language = query_test_language()
  let result = @test.expect_error(() => Query::new(language, "; 文\n(missing)"))
  assert_true(result is NodeType(byte_offset=7, name="missing"))
}

///|
test "query error variants use utf8 byte offsets" {
  let language = query_test_language()
  let bad_syntax = @test.expect_error(() => Query::new(language, "; 文\n(item"))
  assert_true(bad_syntax is Syntax(byte_offset=11, ..))

  let field_language = query_test_field_language()
  let bad_field = @test.expect_error(() => {
    Query::new(field_language, "; 文\n(document missing: (item))")
  })
  assert_true(bad_field is Field(byte_offset=16, name="missing"))

  let bad_capture = @test.expect_error(() => {
    Query::new(language, "; 文\n(item) @node (#eq? @missing \"a\")")
  })
  assert_true(bad_capture is Capture(byte_offset=26, name="missing"))

  let bad_missing_named = @test.expect_error(() => {
    Query::new(language, "; 文\n(MISSING itemx)")
  })
  assert_true(bad_missing_named is NodeType(byte_offset=15, name="itemx"))

  let bad_missing_anonymous = @test.expect_error(() => {
    Query::new(language, "; 文\n(MISSING \"ax\")")
  })
  assert_true(bad_missing_anonymous is NodeType(byte_offset=15, name="ax"))

  let bad_structure = @test.expect_error(() => {
    Query::new(language, "; 文\n(item (item))")
  })
  assert_true(bad_structure is Structure(byte_offset=7, ..))
}

///|
test "query exposes pattern metadata and raw predicate steps" {
  let language = query_test_language()
  let query = Query::new(
    language,
    (
      #|(item) @node
      #|  (#eq? @node "a")
      #|  (#set! injection.language "moonbit")
    ),
  )
  assert_true(query.is_pattern_rooted(0) == Some(true))
  assert_true(query.is_pattern_rooted(1) is None)
  assert_true(query.is_pattern_non_local(0) == Some(false))
  assert_true(query.is_pattern_guaranteed_at_step(0, 0) == Some(false))
  assert_true(query.is_pattern_guaranteed_at_step(0, 1) == Some(false))
  assert_true(query.capture_quantifier_for_id(0, 0) == Some(One))
  assert_eq(query.capture_count(), 1)
  assert_true(query.capture_name_for_id(0) == Some("node"))
  assert_eq(query.string_count(), 5)
  assert_true(query.string_value_for_id(0) == Some("eq?"))
  assert_true(query.string_value_for_id(1) == Some("a"))
  assert_true(query.string_value_for_id(2) == Some("set!"))
  assert_true(query.string_value_for_id(3) == Some("injection.language"))
  assert_true(query.string_value_for_id(4) == Some("moonbit"))
  assert_true(query.predicate_step_count_for_pattern(0) == Some(8))
  assert_true(query.predicate_step_for_pattern(0, 0) == Some(String(0)))
  assert_true(query.predicate_step_for_pattern(0, 1) == Some(Capture(0)))
  assert_true(query.predicate_step_for_pattern(0, 2) == Some(String(1)))
  assert_true(query.predicate_step_for_pattern(0, 3) == Some(Done))
  assert_true(query.predicate_step_for_pattern(0, 4) == Some(String(2)))
  assert_true(query.predicate_step_for_pattern(0, 5) == Some(String(3)))
  assert_true(query.predicate_step_for_pattern(0, 6) == Some(String(4)))
  assert_true(query.predicate_step_for_pattern(0, 7) == Some(Done))
  assert_true(query.predicate_step_for_pattern(0, 8) is None)
  assert_true(query.predicate_step_count_for_pattern(1) is None)
}

///|
test "query parses grouped single-root predicates" {
  let language = query_test_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(language, "((item) @node (#eq? @node \"a\"))")
  assert_eq(query.pattern_count(), 1)
  assert_eq(query.capture_count(), 1)
  assert_true(query.capture_name_for_id(0) == Some("node"))
  assert_eq(query.string_count(), 2)
  assert_true(query.string_value_for_id(0) == Some("eq?"))
  assert_true(query.string_value_for_id(1) == Some("a"))
  assert_true(query.predicate_step_count_for_pattern(0) == Some(4))
  assert_true(query.predicate_step_for_pattern(0, 0) == Some(String(0)))
  assert_true(query.predicate_step_for_pattern(0, 1) == Some(Capture(0)))
  assert_true(query.predicate_step_for_pattern(0, 2) == Some(String(1)))
  assert_true(query.predicate_step_for_pattern(0, 3) == Some(Done))

  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())
  let matched = cursor.next_match().unwrap()
  assert_eq(matched.captures.length(), 1)
  assert_true(query.text_predicates_match_bytes(matched, b"a"))

  let failing = Query::new(language, "((item) @node (#eq? @node \"b\"))")
  cursor.exec(failing, tree.root_node())
  let failed_match = cursor.next_match().unwrap()
  assert_true(!failing.text_predicates_match_bytes(failed_match, b"a"))
}

///|
test "query matches grouped sibling sequences" {
  let pair_language = query_test_pair_language()
  let pair_tree = query_test_pair_tree()
  let query = Query::new(
    pair_language, "((item) @node \"b\" @literal (#eq? @literal \"b\"))",
  )
  assert_eq(query.pattern_count(), 1)
  assert_eq(query.capture_count(), 2)
  assert_true(query.predicate_step_count_for_pattern(0) == Some(4))

  let cursor = QueryCursor::new()
  cursor.exec(query, pair_tree.root_node())
  let matched = cursor.next_match().unwrap()
  assert_eq(matched.captures.length(), 2)
  assert_eq(matched.captures[0].name, "node")
  assert_eq(matched.captures[1].name, "literal")
  assert_true(query.text_predicates_match_bytes(matched, b"ab"))
  assert_true(cursor.next_match() is None)

  let child_group = Query::new(
    pair_language, "(document ((item) @node \"b\" @literal (#eq? @literal \"b\"))) @root",
  )
  assert_eq(child_group.pattern_count(), 1)
  assert_eq(child_group.capture_count(), 3)
  assert_true(child_group.predicate_step_count_for_pattern(0) == Some(4))
  cursor.exec(child_group, pair_tree.root_node())
  let child_group_match = cursor.next_match().unwrap()
  assert_eq(child_group_match.captures.length(), 3)
  assert_eq(child_group_match.captures[0].name, "root")
  assert_eq(child_group_match.captures[1].name, "node")
  assert_eq(child_group_match.captures[2].name, "literal")
  assert_true(child_group.text_predicates_match_bytes(child_group_match, b"ab"))
  assert_true(cursor.next_match() is None)

  let node_predicate = Query::new(
    pair_language, "(document (item) @node (#eq? @node \"a\")) @root",
  )
  assert_true(node_predicate.predicate_step_count_for_pattern(0) == Some(4))
  cursor.exec(node_predicate, pair_tree.root_node())
  let node_predicate_match = cursor.next_match().unwrap()
  assert_eq(node_predicate_match.captures.length(), 2)
  assert_eq(node_predicate_match.captures[0].name, "root")
  assert_eq(node_predicate_match.captures[1].name, "node")
  assert_true(
    node_predicate.text_predicates_match_bytes(node_predicate_match, b"ab"),
  )
  assert_true(cursor.next_match() is None)

  let anchor_language = query_test_anchor_language()
  let anchor_tree = query_test_anchor_tree()
  let skipped = Query::new(anchor_language, "((item) @left (item) @right)")
  cursor.exec(skipped, anchor_tree.root_node())
  let skipped_match = cursor.next_match().unwrap()
  assert_eq(skipped_match.captures.length(), 2)
  assert_eq(skipped_match.captures[0].node.start_byte(), 1)
  assert_eq(skipped_match.captures[1].node.start_byte(), 3)
  assert_true(cursor.next_match() is None)

  let anonymous_first_group = Query::new(
    anchor_language, "(document (\"b\" @literal . _ @any)) @root",
  )
  cursor.exec(anonymous_first_group, anchor_tree.root_node())
  let anonymous_first_match = cursor.next_match().unwrap()
  assert_eq(anonymous_first_match.captures.length(), 3)
  assert_eq(anonymous_first_match.captures[0].name, "root")
  assert_eq(anonymous_first_match.captures[1].name, "literal")
  assert_eq(anonymous_first_match.captures[1].node.start_byte(), 0)
  assert_eq(anonymous_first_match.captures[2].name, "any")
  assert_eq(anonymous_first_match.captures[2].node.start_byte(), 1)
  assert_true(cursor.next_match() is None)

  let optional_leading = Query::new(
    anchor_language, "((other)? @maybe (item) @right)",
  )
  cursor.exec(optional_leading, anchor_tree.root_node())
  let mut first_item_match_count = 0
  let mut saw_optional_match = false
  while cursor.next_match() is Some(optional_match) {
    for capture in optional_match.captures {
      if capture.name == "right" && capture.node.start_byte() == 1 {
        first_item_match_count += 1
      }
      if capture.name == "maybe" && capture.node.start_byte() == 2 {
        saw_optional_match = true
      }
    }
  }
  assert_eq(first_item_match_count, 1)
  assert_true(saw_optional_match)

  let immediate = Query::new(anchor_language, "((item) @left . (item) @right)")
  cursor.exec(immediate, anchor_tree.root_node())
  assert_true(cursor.next_match() is None)
}

///|
test "query parses dot predicate directive marker" {
  let language = query_test_language()
  let query = Query::new(
    language,
    (
      #|(item) @node
      #|  (.eq? @node "a")
      #|  (.set! injection.language "moonbit")
    ),
  )
  assert_eq(query.string_count(), 5)
  assert_true(query.string_value_for_id(0) == Some("eq?"))
  assert_true(query.string_value_for_id(1) == Some("a"))
  assert_true(query.string_value_for_id(2) == Some("set!"))
  assert_true(query.string_value_for_id(3) == Some("injection.language"))
  assert_true(query.string_value_for_id(4) == Some("moonbit"))
  assert_true(query.predicate_step_count_for_pattern(0) == Some(8))
  assert_true(query.predicate_step_for_pattern(0, 0) == Some(String(0)))
  assert_true(query.predicate_step_for_pattern(0, 1) == Some(Capture(0)))
  assert_true(query.predicate_step_for_pattern(0, 2) == Some(String(1)))
  assert_true(query.predicate_step_for_pattern(0, 3) == Some(Done))
  assert_true(query.predicate_step_for_pattern(0, 4) == Some(String(2)))
  assert_true(query.predicate_step_for_pattern(0, 5) == Some(String(3)))
  assert_true(query.predicate_step_for_pattern(0, 6) == Some(String(4)))
  assert_true(query.predicate_step_for_pattern(0, 7) == Some(Done))

  let classes = query.classify_predicates()
  assert_eq(classes.text_predicates.length(), 1)
  assert_true(classes.text_predicates[0].kind == TextEq)
  assert_eq(classes.property_settings.length(), 1)
  assert_eq(classes.property_settings[0].key, "injection.language")
  assert_true(classes.property_settings[0].value == Some("moonbit"))
}

///|
test "query treats comments as whitespace before predicate markers" {
  let language = query_test_language()
  let query = Query::new(
    language,
    (
      #|(item) @node
      #|  (; marker comment
      #|   #eq? @node "a")
    ),
  )
  assert_true(query.predicate_step_count_for_pattern(0) == Some(4))
  assert_true(query.predicate_step_for_pattern(0, 0) == Some(String(0)))
  assert_true(query.predicate_step_for_pattern(0, 1) == Some(Capture(0)))
  assert_true(query.string_value_for_id(0) == Some("eq?"))
  assert_true(query.string_value_for_id(1) == Some("a"))
}

///|
test "query treats comments as whitespace after predicate atoms" {
  let language = query_test_language()
  let query = Query::new(
    language,
    (
      #|(item) @node
      #|  (#custom! arg; atom comment
      #|    @node)
    ),
  )
  assert_true(query.predicate_step_count_for_pattern(0) == Some(4))
  assert_true(query.predicate_step_for_pattern(0, 0) == Some(String(0)))
  assert_true(query.predicate_step_for_pattern(0, 1) == Some(String(1)))
  assert_true(query.predicate_step_for_pattern(0, 2) == Some(Capture(0)))
  assert_true(query.predicate_step_for_pattern(0, 3) == Some(Done))
  assert_true(query.string_value_for_id(0) == Some("custom!"))
  assert_true(query.string_value_for_id(1) == Some("arg"))
}

///|
test "query reports rooted and non-local pattern metadata" {
  let language = query_test_language()
  let root_alternation = Query::new(language, "[(item) @node (document) @root]")
  assert_true(root_alternation.is_pattern_rooted(0) == Some(true))
  assert_true(root_alternation.is_pattern_non_local(0) == Some(false))

  let repeated_root = Query::new(language, "(item)+ @node")
  assert_true(repeated_root.is_pattern_rooted(0) == Some(false))
  assert_true(repeated_root.is_pattern_non_local(0) == Some(true))

  let optional_root = Query::new(language, "(item)? @node")
  assert_true(optional_root.is_pattern_rooted(0) == Some(false))
  assert_true(optional_root.is_pattern_non_local(0) == Some(false))

  let mixed_alternation = Query::new(
    language, "[(item) @node (document)* @root]",
  )
  assert_true(mixed_alternation.is_pattern_rooted(0) == Some(false))
  assert_true(mixed_alternation.is_pattern_non_local(0) == Some(true))

  let repeat_language = query_test_repeat_language()
  let repeated_child = Query::new(
    repeat_language, "(document (item)+ @node) @root",
  )
  assert_true(repeated_child.is_pattern_rooted(0) == Some(true))
  assert_true(repeated_child.is_pattern_non_local(0) == Some(true))

  let optional_child = Query::new(
    repeat_language, "(document (item)? @node) @root",
  )
  assert_true(optional_child.is_pattern_rooted(0) == Some(true))
  assert_true(optional_child.is_pattern_non_local(0) == Some(false))
  assert_true(optional_child.is_pattern_guaranteed_at_step(0, 0) == Some(true))
  assert_true(optional_child.is_pattern_guaranteed_at_step(0, 1) == Some(false))

  let repeated_capture_in_sequence = Query::new(
    query_test_pair_language(),
    "(document (item) @node (\"b\") @node)",
  )
  assert_true(
    repeated_capture_in_sequence.capture_quantifier_for_id(0, 0) ==
    Some(OneOrMore),
  )

  let optional_and_required_capture = Query::new(
    query_test_pair_language(),
    "(document (item)? @node (\"b\") @node)",
  )
  assert_true(
    optional_and_required_capture.capture_quantifier_for_id(0, 0) ==
    Some(OneOrMore),
  )

  let local_and_child_capture = Query::new(
    repeat_language, "(document (item)+ @node) @node",
  )
  assert_true(
    local_and_child_capture.capture_quantifier_for_id(0, 0) == Some(OneOrMore),
  )

  let repeated_child_in_optional_parent = Query::new(
    repeat_language, "(document (item)+ @node)? @root",
  )
  assert_true(
    repeated_child_in_optional_parent.capture_quantifier_for_id(0, 0) ==
    Some(ZeroOrMore),
  )
  assert_true(
    repeated_child_in_optional_parent.capture_quantifier_for_id(0, 1) ==
    Some(ZeroOrOne),
  )

  let different_alternative_quantifiers = Query::new(
    repeat_language, "(document [(item)+ @node (item)? @node]) @root",
  )
  assert_true(
    different_alternative_quantifiers.capture_quantifier_for_id(0, 0) ==
    Some(ZeroOrMore),
  )
  assert_true(
    different_alternative_quantifiers.capture_quantifier_for_id(0, 1) ==
    Some(One),
  )

  let required_children = Query::new(
    query_test_pair_language(),
    "(document (item) @node (\"b\") @literal) @root",
  )
  assert_true(
    required_children.is_pattern_guaranteed_at_step(0, 0) == Some(true),
  )
  assert_true(
    required_children.is_pattern_guaranteed_at_step(0, 1) == Some(true),
  )
  assert_true(
    required_children.is_pattern_guaranteed_at_step(0, 2) == Some(true),
  )
  assert_true(
    required_children.is_pattern_guaranteed_at_step(0, 3) == Some(false),
  )
  assert_true(!required_children.is_pattern_guaranteed_at_byte_offset(-1))
  assert_true(required_children.is_pattern_guaranteed_at_byte_offset(0))
  assert_true(required_children.is_pattern_guaranteed_at_byte_offset(9))
  assert_true(required_children.is_pattern_guaranteed_at_byte_offset(10))
  assert_true(required_children.is_pattern_guaranteed_at_byte_offset(22))
  assert_true(required_children.is_pattern_guaranteed_at_byte_offset(23))
  assert_true(required_children.is_pattern_guaranteed_at_byte_offset(100))

  let predicate_child = Query::new(
    query_test_pair_language(),
    (
      #|(document (item) @node ("b") @literal) @root
      #|  (#eq? @node "a")
    ),
  )
  assert_true(predicate_child.is_pattern_guaranteed_at_step(0, 0) == Some(true))
  assert_true(
    predicate_child.is_pattern_guaranteed_at_step(0, 1) == Some(false),
  )
  assert_true(predicate_child.is_pattern_guaranteed_at_step(0, 2) == Some(true))
  assert_true(predicate_child.is_pattern_guaranteed_at_byte_offset(0))
  assert_true(!predicate_child.is_pattern_guaranteed_at_byte_offset(10))
  assert_true(!predicate_child.is_pattern_guaranteed_at_byte_offset(22))
  assert_true(!predicate_child.is_pattern_guaranteed_at_byte_offset(23))
  assert_true(predicate_child.is_pattern_guaranteed_at_byte_offset(24))

  let wildcard_named_siblings = Query::new(
    query_test_anchor_language(),
    "(_ (item) @left (other) @right) @root",
  )
  assert_true(wildcard_named_siblings.is_pattern_rooted(0) == Some(false))
  assert_true(wildcard_named_siblings.is_pattern_non_local(0) == Some(true))

  let wildcard_single_child = Query::new(
    query_test_pair_language(),
    "(_ (item) @node) @root",
  )
  assert_true(wildcard_single_child.is_pattern_rooted(0) == Some(true))
  assert_true(wildcard_single_child.is_pattern_non_local(0) == Some(false))

  let wildcard_anonymous_siblings = Query::new(
    query_test_pair_language(),
    "(_ (\"b\") @left (\"b\") @right) @root",
  )
  assert_true(wildcard_anonymous_siblings.is_pattern_rooted(0) == Some(false))
  assert_true(
    wildcard_anonymous_siblings.is_pattern_non_local(0) == Some(false),
  )

  let alternation_child = Query::new(
    query_test_anchor_language(),
    "(document [(item) @left (other) @right]) @root",
  )
  assert_true(
    alternation_child.is_pattern_guaranteed_at_step(0, 0) == Some(true),
  )
  assert_true(
    alternation_child.is_pattern_guaranteed_at_step(0, 1) == Some(false),
  )

  let grouped_sequence = Query::new(
    query_test_anchor_language(),
    "((item) @left (item) @right)",
  )
  assert_true(grouped_sequence.is_pattern_rooted(0) == Some(false))
  assert_true(grouped_sequence.is_pattern_non_local(0) == Some(true))
  assert_true(
    grouped_sequence.is_pattern_guaranteed_at_step(0, 0) == Some(true),
  )
  assert_true(
    grouped_sequence.is_pattern_guaranteed_at_step(0, 1) == Some(true),
  )
  assert_true(
    grouped_sequence.is_pattern_guaranteed_at_step(0, 2) == Some(false),
  )
  assert_true(grouped_sequence.capture_quantifier_for_id(0, 0) == Some(One))
  assert_true(grouped_sequence.capture_quantifier_for_id(0, 1) == Some(One))

  let anonymous_grouped_sequence = Query::new(
    query_test_pair_language(),
    "((\"b\") @left (\"b\") @right)",
  )
  assert_true(anonymous_grouped_sequence.is_pattern_rooted(0) == Some(false))
  assert_true(anonymous_grouped_sequence.is_pattern_non_local(0) == Some(false))
}

///|
test "query parses string literal escapes and reports string errors" {
  let language = query_test_language()
  let escaped = Query::new(
    language, "(item) @node (#eq? @node \"\\n\\r\\t\\0\\q\")",
  )
  assert_true(escaped.string_value_for_id(0) == Some("eq?"))
  assert_true(escaped.string_value_for_id(1) == Some("\n\r\t\u0000q"))

  let newline = @test.expect_error(() => {
    Query::new(
      language,
      (
        #|(item) @node
        #|  (#eq? @node "a
        #|")
      ),
    )
  })
  assert_true(newline is Syntax(reason="newline in string literal", ..))

  let eof = @test.expect_error(() => {
    Query::new(language, "(item) @node (#eq? @node \"a")
  })
  assert_true(eof is Syntax(reason="unterminated string literal", ..))
}

///|
test "query classifies helper predicates" {
  let language = query_test_language()
  let query = Query::new(
    language,
    (
      #|(item) @node
      #|  (#eq? @node "a")
      #|  (#any-of? @node "a" "b")
      #|  (#match? @node "[a-z]+")
      #|  (#any-not-match? @node "[0-9]+")
      #|  (#set! injection.language "moonbit")
      #|  (#is-not? @node local true)
      #|  (#custom! @node "x")
    ),
  )
  let classes = query.classify_predicates()

  assert_eq(classes.text_predicates.length(), 4)
  let eq_predicate = classes.text_predicates[0]
  assert_true(eq_predicate.kind == TextEq)
  assert_eq(eq_predicate.capture_id, 0)
  assert_true(eq_predicate.args == [ArgString("a")])
  let any_of_predicate = classes.text_predicates[1]
  assert_true(any_of_predicate.kind == TextAnyOf)
  assert_true(any_of_predicate.args == [ArgString("a"), ArgString("b")])
  let match_predicate = classes.text_predicates[2]
  assert_true(match_predicate.kind == TextMatch)
  assert_true(match_predicate.args == [ArgString("[a-z]+")])
  let any_not_match_predicate = classes.text_predicates[3]
  assert_true(any_not_match_predicate.kind == TextAnyNotMatch)
  assert_true(any_not_match_predicate.args == [ArgString("[0-9]+")])

  assert_eq(classes.property_settings.length(), 1)
  let setting = classes.property_settings[0]
  assert_eq(setting.key, "injection.language")
  assert_true(setting.value == Some("moonbit"))
  assert_true(setting.capture_id is None)

  assert_eq(classes.property_assertions.length(), 1)
  let assertion = classes.property_assertions[0]
  assert_true(!assertion.is_positive)
  assert_eq(assertion.key, "local")
  assert_true(assertion.value == Some("true"))
  assert_true(assertion.capture_id == Some(0))

  assert_eq(classes.general_predicates.length(), 1)
  let general = classes.general_predicates[0]
  assert_eq(general.operator, "custom!")
  assert_true(general.args == [ArgCapture(0), ArgString("x")])
}

///|
test "query classifies property predicate argument forms" {
  let language = query_test_language()
  let query = Query::new(
    language,
    (
      #|(item) @node
      #|  (#set! @node role)
      #|  (#set! role value @node)
      #|  (#is? local)
      #|  (#is? @node local)
      #|  (#is? local true)
      #|  (#is-not? @node local false)
    ),
  )
  let classes = query.classify_predicates()

  assert_eq(classes.property_settings.length(), 2)
  let capture_setting = classes.property_settings[0]
  assert_eq(capture_setting.key, "role")
  assert_true(capture_setting.value is None)
  assert_true(capture_setting.capture_id == Some(0))
  let valued_capture_setting = classes.property_settings[1]
  assert_eq(valued_capture_setting.key, "role")
  assert_true(valued_capture_setting.value == Some("value"))
  assert_true(valued_capture_setting.capture_id == Some(0))

  assert_eq(classes.property_assertions.length(), 4)
  let key_only = classes.property_assertions[0]
  assert_true(key_only.is_positive)
  assert_eq(key_only.key, "local")
  assert_true(key_only.value is None)
  assert_true(key_only.capture_id is None)
  let captured_key = classes.property_assertions[1]
  assert_true(captured_key.is_positive)
  assert_eq(captured_key.key, "local")
  assert_true(captured_key.value is None)
  assert_true(captured_key.capture_id == Some(0))
  let key_value = classes.property_assertions[2]
  assert_true(key_value.is_positive)
  assert_eq(key_value.key, "local")
  assert_true(key_value.value == Some("true"))
  assert_true(key_value.capture_id is None)
  let negative_key_value = classes.property_assertions[3]
  assert_true(!negative_key_value.is_positive)
  assert_eq(negative_key_value.key, "local")
  assert_true(negative_key_value.value == Some("false"))
  assert_true(negative_key_value.capture_id == Some(0))
}

///|
test "query helper predicate classification validates known operators" {
  let language = query_test_language()
  let bad_text = Query::new(language, "(item) @node (#eq? \"a\" \"b\")")
  let text_result = @test.expect_error(() => bad_text.classify_predicates())
  assert_true(text_result is Predicate(byte_offset=15, operator="eq?", ..))

  let bad_text_arg_count = Query::new(language, "(item) @node (#eq? @node)")
  let text_arg_count_result = @test.expect_error(() => {
    bad_text_arg_count.classify_predicates()
  })
  assert_true(
    text_arg_count_result
    is Predicate(
      byte_offset=15,
      operator="eq?",
      reason="expected 2 arguments",
      ..
    ),
  )

  let bad_any_of_arg_count = Query::new(
    language, "(item) @node (#any-of? @node)",
  )
  let any_of_arg_count_result = @test.expect_error(() => {
    bad_any_of_arg_count.classify_predicates()
  })
  assert_true(
    any_of_arg_count_result
    is Predicate(
      byte_offset=15,
      operator="any-of?",
      reason="text predicate expects a capture and at least one string",
      ..
    ),
  )

  let bad_any_of_arg_type = Query::new(
    language, "(item) @left @right (#any-of? @left @right)",
  )
  let any_of_arg_type_result = @test.expect_error(() => {
    bad_any_of_arg_type.classify_predicates()
  })
  assert_true(
    any_of_arg_type_result
    is Predicate(
      byte_offset=22,
      operator="any-of?",
      reason="expected string argument",
      ..
    ),
  )

  let bad_regex_arg_type = Query::new(
    language, "(item) @node (#match? @node @node)",
  )
  let regex_arg_type_result = @test.expect_error(() => {
    bad_regex_arg_type.classify_predicates()
  })
  assert_true(
    regex_arg_type_result
    is Predicate(
      byte_offset=15,
      operator="match?",
      reason="expected string argument",
      ..
    ),
  )

  let empty_regex = Query::new(language, "(item) @node (#match? @node \"\")")
  let empty_regex_result = @test.expect_error(() => {
    empty_regex.classify_predicates()
  })
  assert_true(
    empty_regex_result
    is Predicate(
      byte_offset=15,
      operator="match?",
      reason="regex must not be empty",
      ..
    ),
  )

  let bad_property = Query::new(language, "(item) @node (#set! @node)")
  let property_result = @test.expect_error(() => {
    bad_property.classify_predicates()
  })
  assert_true(
    property_result
    is Predicate(
      byte_offset=15,
      operator="set!",
      reason="property predicate key is required",
      ..
    ),
  )

  let bad_property_arg_count = Query::new(
    language, "(item) @node (#set! \"key\" \"value\" @node \"extra\")",
  )
  let arg_count_result = @test.expect_error(() => {
    bad_property_arg_count.classify_predicates()
  })
  assert_true(
    arg_count_result
    is Predicate(
      byte_offset=15,
      operator="set!",
      reason="property predicate expects one to three arguments",
      ..
    ),
  )

  let bad_property_captures = Query::new(
    language, "(item) @left @right (#is? @left @right local)",
  )
  let capture_result = @test.expect_error(() => {
    bad_property_captures.classify_predicates()
  })
  assert_true(
    capture_result
    is Predicate(
      byte_offset=22,
      operator="is?",
      reason="property predicate accepts at most one capture",
      ..
    ),
  )

  let bad_property_values = Query::new(
    language, "(item) @node (#is? local true false)",
  )
  let value_result = @test.expect_error(() => {
    bad_property_values.classify_predicates()
  })
  assert_true(
    value_result
    is Predicate(
      byte_offset=15,
      operator="is?",
      reason="property predicate accepts at most one value",
      ..
    ),
  )

  let bad_regex = Query::new(language, "(item) @node (#match? @node \"[abc\")")
  let regex_result = @test.expect_error(() => bad_regex.classify_predicates())
  assert_true(regex_result is Predicate(byte_offset=15, operator="match?", ..))
}

///|
test "query predicate errors use utf8 byte offsets" {
  let language = query_test_language()
  let bad_text = Query::new(language, "; 文\n(item) @node (#eq? \"a\" \"b\")")
  let text_result = @test.expect_error(() => bad_text.classify_predicates())
  assert_true(text_result is Predicate(byte_offset=21, operator="eq?", ..))

  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let bad_source = Query::new(
    language, "; 文\n(item) @node (#eq? @node \"a\")",
  )
  let cursor = QueryCursor::new()
  cursor.exec(bad_source, tree.root_node())
  let matched = cursor.next_match().unwrap()
  let source_result = @test.expect_error(() => {
    bad_source.text_predicates_match_bytes(matched, b"")
  })
  assert_true(source_result is Predicate(byte_offset=21, operator="eq?", ..))
}

///|
test "query predicate classes expose utf8 byte offsets" {
  let language = query_test_language()
  let query = Query::new(
    language, "; 文\n(item) @node (#eq? @node \"a\") (#set! role value) (#is? local) (#custom! @node)",
  )
  let classes = query.classify_predicates()

  assert_eq(classes.text_predicates.length(), 1)
  assert_eq(classes.text_predicates[0].byte_offset, 21)
  assert_eq(classes.property_settings.length(), 1)
  assert_eq(classes.property_settings[0].byte_offset, 38)
  assert_eq(classes.property_assertions.length(), 1)
  assert_eq(classes.property_assertions[0].byte_offset, 57)
  assert_eq(classes.general_predicates.length(), 1)
  assert_eq(classes.general_predicates[0].byte_offset, 70)
}

///|
test "query text predicate helper filters exact predicates" {
  let language = query_test_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let passing = Query::new(
    language,
    (
      #|(item) @node
      #|  (#eq? @node "a")
      #|  (#not-eq? @node "b")
      #|  (#any-of? @node "a" "b")
      #|  (#not-any-of? @node "c")
    ),
  )
  let cursor = QueryCursor::new()
  cursor.exec(passing, tree.root_node())
  let matched = cursor.next_match().unwrap()
  assert_true(passing.text_predicates_match_bytes(matched, b"a"))
  assert_true(passing.text_predicates_match_string(matched, "a"))

  let failing = Query::new(language, "(item) @node (#eq? @node \"b\")")
  cursor.exec(failing, tree.root_node())
  let failed_match = cursor.next_match().unwrap()
  assert_true(!failing.text_predicates_match_bytes(failed_match, b"a"))
}

///|
test "query text predicate helper supports capture and regex predicates" {
  let language = query_test_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let passing = Query::new(
    language,
    (
      #|(item) @left @right
      #|  (#eq? @left @right)
      #|  (#match? @left "[a-z]+")
      #|  (#not-match? @left "[0-9]+")
    ),
  )
  let cursor = QueryCursor::new()
  cursor.exec(passing, tree.root_node())
  let matched = cursor.next_match().unwrap()
  assert_true(passing.text_predicates_match_bytes(matched, b"a"))

  let failing = Query::new(language, "(item) @node (#match? @node \"[0-9]+\")")
  cursor.exec(failing, tree.root_node())
  let failed_match = cursor.next_match().unwrap()
  assert_true(!failing.text_predicates_match_bytes(failed_match, b"a"))

  let general_regex = Query::new(
    language, "(item) @node (#match? @node \"a.*|z\")",
  )
  cursor.exec(general_regex, tree.root_node())
  let general_match = cursor.next_match().unwrap()
  assert_true(general_regex.text_predicates_match_bytes(general_match, b"a"))

  let shorthand_regex = Query::new(
    language, "(item) @node (#match? @node \"^\\\\w{1}$\")",
  )
  cursor.exec(shorthand_regex, tree.root_node())
  let shorthand_match = cursor.next_match().unwrap()
  assert_true(
    shorthand_regex.text_predicates_match_bytes(shorthand_match, b"a"),
  )

  let absolute_anchor_regex = Query::new(
    language, "(item) @node (#match? @node \"\\\\Aa\\\\z\")",
  )
  cursor.exec(absolute_anchor_regex, tree.root_node())
  let absolute_anchor_match = cursor.next_match().unwrap()
  assert_true(
    absolute_anchor_regex.text_predicates_match_bytes(
      absolute_anchor_match, b"a",
    ),
  )
}

///|
test "query text predicate helper supports regex shorthand classes" {
  let language = query_test_text_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let cursor = QueryCursor::new()

  let digit_tree = parser.parse_bytes(b"1")
  let digit = Query::new(
    language, "(document) @node (#match? @node \"^\\\\d$\")",
  )
  cursor.exec(digit, digit_tree.root_node())
  let digit_match = cursor.next_match().unwrap()
  assert_true(digit.text_predicates_match_bytes(digit_match, b"1"))

  let digit_class = Query::new(
    language, "(document) @node (#match? @node \"^[\\\\d_]$\")",
  )
  cursor.exec(digit_class, digit_tree.root_node())
  let digit_class_match = cursor.next_match().unwrap()
  assert_true(digit_class.text_predicates_match_bytes(digit_class_match, b"1"))

  let letter_tree = parser.parse_bytes(b"a")
  let non_digit_class = Query::new(
    language, "(document) @node (#match? @node \"^[\\\\D_]$\")",
  )
  cursor.exec(non_digit_class, letter_tree.root_node())
  let non_digit_class_match = cursor.next_match().unwrap()
  assert_true(
    non_digit_class.text_predicates_match_bytes(non_digit_class_match, b"a"),
  )

  let non_digit = Query::new(
    language, "(document) @node (#match? @node \"^\\\\D$\")",
  )
  cursor.exec(non_digit, letter_tree.root_node())
  let non_digit_match = cursor.next_match().unwrap()
  assert_true(non_digit.text_predicates_match_bytes(non_digit_match, b"a"))

  let non_space_class = Query::new(
    language, "(document) @node (#match? @node \"^[\\\\S_]$\")",
  )
  cursor.exec(non_space_class, letter_tree.root_node())
  let non_space_class_match = cursor.next_match().unwrap()
  assert_true(
    non_space_class.text_predicates_match_bytes(non_space_class_match, b"a"),
  )

  let non_space = Query::new(
    language, "(document) @node (#match? @node \"^\\\\S$\")",
  )
  cursor.exec(non_space, letter_tree.root_node())
  let non_space_match = cursor.next_match().unwrap()
  assert_true(non_space.text_predicates_match_bytes(non_space_match, b"a"))

  let space_tree = parser.parse_bytes(b" ")
  let space = Query::new(
    language, "(document) @node (#match? @node \"^\\\\s$\")",
  )
  cursor.exec(space, space_tree.root_node())
  let space_match = cursor.next_match().unwrap()
  assert_true(space.text_predicates_match_bytes(space_match, b" "))

  let non_word = Query::new(
    language, "(document) @node (#match? @node \"^\\\\W$\")",
  )
  cursor.exec(non_word, space_tree.root_node())
  let non_word_match = cursor.next_match().unwrap()
  assert_true(non_word.text_predicates_match_bytes(non_word_match, b" "))

  let non_word_class = Query::new(
    language, "(document) @node (#match? @node \"^[\\\\W_]$\")",
  )
  cursor.exec(non_word_class, space_tree.root_node())
  let non_word_class_match = cursor.next_match().unwrap()
  assert_true(
    non_word_class.text_predicates_match_bytes(non_word_class_match, b" "),
  )
}

///|
test "query text predicate helper applies all and any to quantified captures" {
  let language = query_test_mixed_repeat_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"aab")
  let cursor = QueryCursor::new()

  let all_a = Query::new(
    language,
    (
      #|(document [(item) @token (other) @token]+)
      #|  (#match? @token "^a$")
    ),
  )
  cursor.exec(all_a, tree.root_node())
  let all_match = cursor.next_match().unwrap()
  assert_true(!all_a.text_predicates_match_bytes(all_match, b"aab"))

  let any_a = Query::new(
    language,
    (
      #|(document [(item) @token (other) @token]+)
      #|  (#any-match? @token "^a$")
    ),
  )
  cursor.exec(any_a, tree.root_node())
  let any_match = cursor.next_match().unwrap()
  assert_true(any_a.text_predicates_match_bytes(any_match, b"aab"))

  let any_z = Query::new(
    language,
    (
      #|(document [(item) @token (other) @token]+)
      #|  (#any-match? @token "^z$")
    ),
  )
  cursor.exec(any_z, tree.root_node())
  let missing_any_match = cursor.next_match().unwrap()
  assert_true(!any_z.text_predicates_match_bytes(missing_any_match, b"aab"))

  let any_not_b = Query::new(
    language,
    (
      #|(document [(item) @token (other) @token]+)
      #|  (#any-not-match? @token "^b$")
    ),
  )
  cursor.exec(any_not_b, tree.root_node())
  let any_not_b_match = cursor.next_match().unwrap()
  assert_true(any_not_b.text_predicates_match_bytes(any_not_b_match, b"aab"))

  let any_not_ab = Query::new(
    language,
    (
      #|(document [(item) @token (other) @token]+)
      #|  (#any-not-match? @token "^[ab]$")
    ),
  )
  cursor.exec(any_not_ab, tree.root_node())
  let any_not_ab_match = cursor.next_match().unwrap()
  assert_true(!any_not_ab.text_predicates_match_bytes(any_not_ab_match, b"aab"))

  let exact_all_a = Query::new(
    language,
    (
      #|(document [(item) @token (other) @token]+)
      #|  (#eq? @token "a")
    ),
  )
  cursor.exec(exact_all_a, tree.root_node())
  let exact_all_match = cursor.next_match().unwrap()
  assert_true(!exact_all_a.text_predicates_match_bytes(exact_all_match, b"aab"))

  let exact_any_a = Query::new(
    language,
    (
      #|(document [(item) @token (other) @token]+)
      #|  (#any-eq? @token "a")
    ),
  )
  cursor.exec(exact_any_a, tree.root_node())
  let exact_any_match = cursor.next_match().unwrap()
  assert_true(exact_any_a.text_predicates_match_bytes(exact_any_match, b"aab"))

  let exact_any_not_a = Query::new(
    language,
    (
      #|(document [(item) @token (other) @token]+)
      #|  (#any-not-eq? @token "a")
    ),
  )
  cursor.exec(exact_any_not_a, tree.root_node())
  let exact_any_not_match = cursor.next_match().unwrap()
  assert_true(
    exact_any_not_a.text_predicates_match_bytes(exact_any_not_match, b"aab"),
  )

  let exact_none_z = Query::new(
    language,
    (
      #|(document [(item) @token (other) @token]+)
      #|  (#not-eq? @token "z")
    ),
  )
  cursor.exec(exact_none_z, tree.root_node())
  let exact_none_match = cursor.next_match().unwrap()
  assert_true(
    exact_none_z.text_predicates_match_bytes(exact_none_match, b"aab"),
  )

  let all_in_set = Query::new(
    language,
    (
      #|(document [(item) @token (other) @token]+)
      #|  (#any-of? @token "a" "b")
    ),
  )
  cursor.exec(all_in_set, tree.root_node())
  let all_in_set_match = cursor.next_match().unwrap()
  assert_true(all_in_set.text_predicates_match_bytes(all_in_set_match, b"aab"))

  let missing_from_set = Query::new(
    language,
    (
      #|(document [(item) @token (other) @token]+)
      #|  (#any-of? @token "a")
    ),
  )
  cursor.exec(missing_from_set, tree.root_node())
  let missing_from_set_match = cursor.next_match().unwrap()
  assert_true(
    !missing_from_set.text_predicates_match_bytes(
      missing_from_set_match, b"aab",
    ),
  )

  let none_in_set = Query::new(
    language,
    (
      #|(document [(item) @token (other) @token]+)
      #|  (#not-any-of? @token "z")
    ),
  )
  cursor.exec(none_in_set, tree.root_node())
  let none_in_set_match = cursor.next_match().unwrap()
  assert_true(
    none_in_set.text_predicates_match_bytes(none_in_set_match, b"aab"),
  )

  let one_in_set = Query::new(
    language,
    (
      #|(document [(item) @token (other) @token]+)
      #|  (#not-any-of? @token "b")
    ),
  )
  cursor.exec(one_in_set, tree.root_node())
  let one_in_set_match = cursor.next_match().unwrap()
  assert_true(!one_in_set.text_predicates_match_bytes(one_in_set_match, b"aab"))

  let empty_tree = parser.parse_bytes(b"")
  let all_absent = Query::new(
    language,
    (
      #|(document (item)? @token)
      #|  (#match? @token "^a$")
    ),
  )
  cursor.exec(all_absent, empty_tree.root_node())
  let all_absent_match = cursor.next_match().unwrap()
  assert_true(all_absent.text_predicates_match_bytes(all_absent_match, b""))

  let any_absent = Query::new(
    language,
    (
      #|(document (item)? @token)
      #|  (#any-match? @token "^a$")
    ),
  )
  cursor.exec(any_absent, empty_tree.root_node())
  let any_absent_match = cursor.next_match().unwrap()
  assert_true(!any_absent.text_predicates_match_bytes(any_absent_match, b""))
}

///|
test "query text predicate helper compares quantified captures pairwise" {
  let repeat_language = query_test_repeat_language()
  let repeat_parser = @tree_sitter_mbt.Parser::new()
  repeat_parser.set_language(repeat_language)
  let repeat_tree = repeat_parser.parse_bytes(b"aa")
  let cursor = QueryCursor::new()

  let count_mismatch = Query::new(
    repeat_language,
    (
      #|(document (item) @left @right (item) @left)
      #|  (#eq? @left @right)
    ),
  )
  cursor.exec(count_mismatch, repeat_tree.root_node())
  let count_mismatch_match = cursor.next_match().unwrap()
  assert_true(
    !count_mismatch.text_predicates_match_bytes(count_mismatch_match, b"aa"),
  )

  let any_equal_pair = Query::new(
    repeat_language,
    (
      #|(document (item) @left @right (item) @left)
      #|  (#any-eq? @left @right)
    ),
  )
  cursor.exec(any_equal_pair, repeat_tree.root_node())
  let any_equal_match = cursor.next_match().unwrap()
  assert_true(
    any_equal_pair.text_predicates_match_bytes(any_equal_match, b"aa"),
  )

  let any_not_equal_pair = Query::new(
    repeat_language,
    (
      #|(document (item) @left @right (item) @left)
      #|  (#any-not-eq? @left @right)
    ),
  )
  cursor.exec(any_not_equal_pair, repeat_tree.root_node())
  let any_not_equal_match = cursor.next_match().unwrap()
  assert_true(
    !any_not_equal_pair.text_predicates_match_bytes(any_not_equal_match, b"aa"),
  )

  let mixed_language = query_test_mixed_repeat_language()
  let mixed_parser = @tree_sitter_mbt.Parser::new()
  mixed_parser.set_language(mixed_language)
  let mixed_tree = mixed_parser.parse_bytes(b"ab")
  let not_equal_pair = Query::new(
    mixed_language,
    (
      #|(document (item) @left (other) @right)
      #|  (#not-eq? @left @right)
    ),
  )
  cursor.exec(not_equal_pair, mixed_tree.root_node())
  let not_equal_match = cursor.next_match().unwrap()
  assert_true(
    not_equal_pair.text_predicates_match_bytes(not_equal_match, b"ab"),
  )
}

///|
test "query text predicate helper reports invalid source ranges" {
  let language = query_test_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(language, "(item) @node (#eq? @node \"a\")")
  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())
  let matched = cursor.next_match().unwrap()
  let result = @test.expect_error(() => {
    query.text_predicates_match_bytes(matched, b"")
  })
  assert_true(result is Predicate(operator="eq?", ..))
}

///|
test "query cursor returns matches and document-ordered captures" {
  let language = query_test_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(language, "(item) @node\n(document) @root")
  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())

  let first_match = cursor.next_match().unwrap()
  assert_eq(first_match.id, 0)
  assert_eq(first_match.pattern_index, 1)
  assert_eq(first_match.captures.length(), 1)
  assert_eq(first_match.captures[0].match_id, first_match.id)
  assert_eq(first_match.captures[0].name, "root")
  assert_eq(first_match.captures[0].node.type_(), "document")

  let second_match = cursor.next_match().unwrap()
  assert_eq(second_match.id, 1)
  assert_eq(second_match.pattern_index, 0)
  assert_eq(second_match.captures[0].match_id, second_match.id)
  assert_eq(second_match.captures[0].name, "node")
  assert_eq(second_match.captures[0].node.type_(), "item")
  assert_true(cursor.next_match() is None)

  let first_capture = cursor.next_capture().unwrap()
  assert_eq(first_capture.match_id, second_match.id)
  assert_eq(first_capture.name, "node")
  assert_eq(first_capture.node.type_(), "item")
  let second_capture = cursor.next_capture().unwrap()
  assert_eq(second_capture.match_id, first_match.id)
  assert_eq(second_capture.name, "root")
  assert_eq(second_capture.node.type_(), "document")
  assert_true(cursor.next_capture() is None)
}

///|
test "query cursor ignores trees from incompatible languages" {
  let query_language = query_test_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(query_language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(query_language, "(item) @node")
  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())
  assert_true(query_capture_names(cursor) == ["node"])

  let other_language = query_test_pair_language()
  let other_parser = @tree_sitter_mbt.Parser::new()
  other_parser.set_language(other_language)
  let other_tree = other_parser.parse_bytes(b"ab")
  cursor.exec(query, other_tree.root_node())
  assert_true(cursor.next_match() is None)
  assert_true(cursor.next_capture() is None)
}

///|
test "query cursor matches simple child patterns" {
  let language = query_test_pair_language()
  let tree = query_test_pair_tree()
  let query = Query::new(language, "(document (item) @node) @root")
  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())

  let matched = cursor.next_match().unwrap()
  assert_eq(matched.pattern_index, 0)
  assert_eq(matched.captures.length(), 2)
  assert_eq(matched.captures[0].name, "root")
  assert_eq(matched.captures[0].node.type_(), "document")
  assert_eq(matched.captures[1].name, "node")
  assert_eq(matched.captures[1].node.type_(), "item")
  assert_true(cursor.next_match() is None)

  let child_capture = cursor.next_capture().unwrap()
  assert_eq(child_capture.name, "node")
  let root_capture = cursor.next_capture().unwrap()
  assert_eq(root_capture.name, "root")
  assert_true(cursor.next_capture() is None)

  let wildcard_root = Query::new(language, "(_ (item) @node) @root")
  cursor.exec(wildcard_root, tree.root_node())
  let wildcard_root_match = cursor.next_match().unwrap()
  assert_eq(wildcard_root_match.captures.length(), 2)
  assert_eq(wildcard_root_match.captures[0].name, "root")
  assert_eq(wildcard_root_match.captures[0].node.type_(), "document")
  assert_eq(wildcard_root_match.captures[1].name, "node")
  assert_eq(wildcard_root_match.captures[1].node.type_(), "item")
  assert_true(cursor.next_match() is None)

  let anonymous_child = Query::new(
    language, "(document (item) @node \"b\" @literal) @root",
  )
  cursor.exec(anonymous_child, tree.root_node())
  let anonymous_child_match = cursor.next_match().unwrap()
  assert_eq(anonymous_child_match.captures.length(), 3)
  assert_eq(anonymous_child_match.captures[0].name, "root")
  assert_eq(anonymous_child_match.captures[1].name, "node")
  assert_eq(anonymous_child_match.captures[2].name, "literal")
  assert_eq(anonymous_child_match.captures[2].node.type_(), "b")
  assert_true(!anonymous_child_match.captures[2].node.is_named())
  assert_true(cursor.next_match() is None)

  let terminal_with_child = @test.expect_error(() => {
    Query::new(language, "(item (\"b\") @literal) @node")
  })
  assert_true(terminal_with_child is Structure(..))

  let repeat_language = query_test_repeat_language()
  let repeat_parser = @tree_sitter_mbt.Parser::new()
  repeat_parser.set_language(repeat_language)
  let repeat_tree = repeat_parser.parse_bytes(b"aaa")
  let repeat_query = Query::new(
    repeat_language, "(document (item) @node) @root",
  )
  cursor.exec(repeat_query, repeat_tree.root_node())
  let first_repeat_match = cursor.next_match().unwrap()
  assert_eq(first_repeat_match.captures[1].node.start_byte(), 0)
  let second_repeat_match = cursor.next_match().unwrap()
  assert_eq(second_repeat_match.captures[1].node.start_byte(), 1)
  let third_repeat_match = cursor.next_match().unwrap()
  assert_eq(third_repeat_match.captures[1].node.start_byte(), 2)
  assert_true(cursor.next_match() is None)
}

///|
test "query cursor matches field-constrained child patterns" {
  let language = query_test_field_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(language, "(document left: (item) @node) @root")
  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())

  let matched = cursor.next_match().unwrap()
  assert_eq(matched.captures.length(), 2)
  assert_eq(matched.captures[0].name, "root")
  assert_eq(matched.captures[1].name, "node")

  let no_match = Query::new(language, "(document right: (item) @node) @root")
  cursor.exec(no_match, tree.root_node())
  assert_true(cursor.next_match() is None)

  let root_field_query = Query::new(language, "left: (item) @node")
  cursor.exec(root_field_query, tree.root_node())
  let root_field_match = cursor.next_match().unwrap()
  assert_eq(root_field_match.captures.length(), 1)
  assert_eq(root_field_match.captures[0].name, "node")
  assert_eq(root_field_match.captures[0].node.type_(), "item")
  assert_true(cursor.next_match() is None)

  let root_field_no_match = Query::new(language, "right: (item) @node")
  cursor.exec(root_field_no_match, tree.root_node())
  assert_true(cursor.next_match() is None)

  let hidden_language = query_test_hidden_field_language()
  let hidden_parser = @tree_sitter_mbt.Parser::new()
  hidden_parser.set_language(hidden_language)
  let hidden_tree = hidden_parser.parse_bytes(b"a")
  assert_eq(hidden_tree.root_node().child(0).type_(), "item")
  assert_true(hidden_tree.root_node().field_name_for_child(0) == Some("left"))
  let inherited_field_query = Query::new(
    hidden_language, "(document left: (item) @node) @root",
  )
  cursor.exec(inherited_field_query, hidden_tree.root_node())
  let inherited_match = cursor.next_match().unwrap()
  assert_eq(inherited_match.captures.length(), 2)
  assert_eq(inherited_match.captures[1].name, "node")

  let inherited_root_field_query = Query::new(
    hidden_language, "left: (item) @node",
  )
  cursor.exec(inherited_root_field_query, hidden_tree.root_node())
  let inherited_root_field_match = cursor.next_match().unwrap()
  assert_eq(inherited_root_field_match.captures.length(), 1)
  assert_eq(inherited_root_field_match.captures[0].name, "node")
  assert_true(cursor.next_match() is None)

  let hidden_no_match = Query::new(
    hidden_language, "(document right: (item) @node) @root",
  )
  cursor.exec(hidden_no_match, hidden_tree.root_node())
  assert_true(cursor.next_match() is None)

  let hidden_root_field_no_match = Query::new(
    hidden_language, "right: (item) @node",
  )
  cursor.exec(hidden_root_field_no_match, hidden_tree.root_node())
  assert_true(cursor.next_match() is None)
}

///|
test "query treats comments as whitespace in field constraints" {
  let language = query_test_field_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(
    language,
    (
      #|(document
      #|  !right
      #|  ; comment before field label
      #|  left ; comment before colon
      #|  : (item) @node) @root
    ),
  )
  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())
  assert_true(query_capture_names(cursor) == ["node", "root"])
}

///|
test "query cursor matches negated field constraints" {
  let language = query_test_field_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(language, "(document !right (item) @node) @root")
  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())
  let matched = cursor.next_match().unwrap()
  assert_eq(matched.captures.length(), 2)

  let spaced_query = Query::new(
    language, "(document ! right (item) @node) @root",
  )
  cursor.exec(spaced_query, tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 2)

  let commented_query = Query::new(
    language,
    (
      #|(document !
      #|  ; comment after negated field operator
      #|  right (item) @node) @root
    ),
  )
  cursor.exec(commented_query, tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 2)

  let no_match = Query::new(language, "(document !left (item) @node) @root")
  cursor.exec(no_match, tree.root_node())
  assert_true(cursor.next_match() is None)

  let hidden_language = query_test_hidden_field_language()
  let hidden_parser = @tree_sitter_mbt.Parser::new()
  hidden_parser.set_language(hidden_language)
  let hidden_tree = hidden_parser.parse_bytes(b"a")
  let hidden_present = Query::new(
    hidden_language, "(document !right (item) @node) @root",
  )
  cursor.exec(hidden_present, hidden_tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 2)

  let hidden_absent = Query::new(
    hidden_language, "(document !left (item) @node) @root",
  )
  cursor.exec(hidden_absent, hidden_tree.root_node())
  assert_true(cursor.next_match() is None)
}

///|
test "query cursor matches quantified child patterns" {
  let language = query_test_repeat_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"aaa")
  let many = Query::new(language, "(document (item)+ @node) @root")
  assert_true(many.capture_name_for_id(0) == Some("node"))
  assert_true(many.capture_name_for_id(1) == Some("root"))
  assert_true(many.capture_quantifier_for_id(0, 0) == Some(OneOrMore))
  assert_true(many.capture_quantifier_for_id(0, 1) == Some(One))
  let cursor = QueryCursor::new()
  cursor.exec(many, tree.root_node())
  let matched = cursor.next_match().unwrap()
  assert_eq(matched.captures.length(), 4)
  assert_eq(matched.captures[0].name, "root")
  assert_eq(matched.captures[1].name, "node")
  assert_eq(matched.captures[2].name, "node")
  assert_eq(matched.captures[3].name, "node")

  let optional = Query::new(language, "(document (item)? @node) @root")
  assert_true(optional.capture_quantifier_for_id(0, 0) == Some(ZeroOrOne))
  cursor.exec(optional, tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 2)

  let optional_with_tail = Query::new(
    language, "(document (item)? @maybe . (item) @right) @root",
  )
  let two_item_tree = parser.parse_bytes(b"aa")
  cursor.exec(optional_with_tail, two_item_tree.root_node())
  let mut optional_tail_match_count = 0
  let mut saw_skipped_optional = false
  let mut saw_present_optional = false
  while cursor.next_match() is Some(optional_tail_match) {
    optional_tail_match_count += 1
    let mut maybe_start = @api.uint32_max()
    let mut right_start = @api.uint32_max()
    for capture in optional_tail_match.captures {
      if capture.name == "maybe" {
        maybe_start = capture.node.start_byte()
      } else if capture.name == "right" {
        right_start = capture.node.start_byte()
      }
    }
    if maybe_start == @api.uint32_max() && right_start == 0 {
      saw_skipped_optional = true
    }
    if maybe_start == 0 && right_start == 1 {
      saw_present_optional = true
    }
  }
  assert_eq(optional_tail_match_count, 2)
  assert_true(saw_skipped_optional)
  assert_true(saw_present_optional)

  let empty_tree = parser.parse_bytes(b"")
  let zero_or_more = Query::new(language, "(document (item)* @node) @root")
  assert_true(zero_or_more.capture_quantifier_for_id(0, 0) == Some(ZeroOrMore))
  cursor.exec(zero_or_more, empty_tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 1)

  let one_or_more = Query::new(language, "(document (item)+ @node) @root")
  cursor.exec(one_or_more, empty_tree.root_node())
  assert_true(cursor.next_match() is None)

  let branch_tree = parser.parse_bytes(b"aa")
  let repeated_alternation = Query::new(
    language, "(document [(item) @one (item) @two]+) @root",
  )
  cursor.exec(repeated_alternation, branch_tree.root_node())
  let one_one = cursor.next_match().unwrap()
  assert_eq(one_one.captures[1].name, "one")
  assert_eq(one_one.captures[2].name, "one")
  let one_two = cursor.next_match().unwrap()
  assert_eq(one_two.captures[1].name, "one")
  assert_eq(one_two.captures[2].name, "two")
  let two_one = cursor.next_match().unwrap()
  assert_eq(two_one.captures[1].name, "two")
  assert_eq(two_one.captures[2].name, "one")
  let two_two = cursor.next_match().unwrap()
  assert_eq(two_two.captures[1].name, "two")
  assert_eq(two_two.captures[2].name, "two")
  assert_true(cursor.next_match() is None)

  let equivalent_repeated_alternation = Query::new(
    language, "(document [(item) @same (item) @same]+) @root",
  )
  cursor.exec(equivalent_repeated_alternation, branch_tree.root_node())
  let equivalent = cursor.next_match().unwrap()
  assert_eq(equivalent.captures.length(), 3)
  assert_eq(equivalent.captures[1].name, "same")
  assert_eq(equivalent.captures[2].name, "same")
  assert_true(cursor.next_match() is None)
}

///|
test "query cursor matches quantified root patterns" {
  let language = query_test_repeat_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"aaa")
  let cursor = QueryCursor::new()

  let one_or_more = Query::new(language, "(item)+ @node")
  cursor.exec(one_or_more, tree.root_node())
  let repeated_match = cursor.next_match().unwrap()
  assert_eq(repeated_match.captures.length(), 3)
  assert_true(cursor.next_match() is None)
  assert_true(query_capture_names(cursor) == ["node", "node", "node"])

  let branch_tree = parser.parse_bytes(b"aa")
  let repeated_alternation = Query::new(language, "[(item) @one (item) @two]+")
  cursor.exec(repeated_alternation, branch_tree.root_node())
  let one_one = cursor.next_match().unwrap()
  assert_eq(one_one.captures[0].name, "one")
  assert_eq(one_one.captures[1].name, "one")
  let one_two = cursor.next_match().unwrap()
  assert_eq(one_two.captures[0].name, "one")
  assert_eq(one_two.captures[1].name, "two")
  let two_one = cursor.next_match().unwrap()
  assert_eq(two_one.captures[0].name, "two")
  assert_eq(two_one.captures[1].name, "one")
  let two_two = cursor.next_match().unwrap()
  assert_eq(two_two.captures[0].name, "two")
  assert_eq(two_two.captures[1].name, "two")
  assert_true(cursor.next_match() is None)

  let equivalent_repeated_alternation = Query::new(
    language, "[(item) @same (item) @same]+",
  )
  cursor.exec(equivalent_repeated_alternation, branch_tree.root_node())
  let equivalent = cursor.next_match().unwrap()
  assert_eq(equivalent.captures.length(), 2)
  assert_eq(equivalent.captures[0].name, "same")
  assert_eq(equivalent.captures[1].name, "same")
  assert_true(cursor.next_match() is None)

  let zero_or_more = Query::new(language, "(item)* @node")
  cursor.exec(zero_or_more, tree.root_node())
  let zero_or_more_match = cursor.next_match().unwrap()
  assert_eq(zero_or_more_match.captures.length(), 3)
  assert_true(cursor.next_match() is None)

  let optional = Query::new(language, "(item)? @node")
  cursor.exec(optional, tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 1)
  assert_eq(cursor.next_match().unwrap().captures.length(), 1)
  assert_eq(cursor.next_match().unwrap().captures.length(), 1)
  assert_true(cursor.next_match() is None)

  let empty_tree = parser.parse_bytes(b"")
  cursor.exec(zero_or_more, empty_tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 0)
  assert_true(cursor.next_match() is None)

  cursor.exec(optional, empty_tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 0)
  assert_true(cursor.next_match() is None)

  let ranged = QueryCursor::new()
  ranged.set_byte_range(1, 2) |> ignore
  ranged.exec(one_or_more, tree.root_node())
  let ranged_match = ranged.next_match().unwrap()
  assert_eq(ranged_match.captures.length(), 3)
  assert_true(query_capture_names(ranged) == ["node"])

  let inconsistent_range = QueryCursor::new()
  inconsistent_range.set_byte_range(0, 1) |> ignore
  inconsistent_range.set_point_range(
    @api.Point::new(row=0, column=1),
    @api.Point::new(row=0, column=2),
  )
  |> ignore
  inconsistent_range.exec(one_or_more, tree.root_node())
  assert_true(inconsistent_range.next_match() is None)
  assert_true(query_capture_names(inconsistent_range) == [])
}

///|
test "query parser composes repeated suffix modifiers" {
  let language = query_test_repeat_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"aaa")
  let empty_tree = parser.parse_bytes(b"")
  let cursor = QueryCursor::new()

  let stars = Query::new(language, "(item)*** @node")
  assert_true(stars.capture_quantifier_for_id(0, 0) == Some(ZeroOrMore))
  cursor.exec(stars, empty_tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 0)
  cursor.exec(stars, tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 3)

  let questions = Query::new(language, "(item)??? @node")
  assert_true(questions.capture_quantifier_for_id(0, 0) == Some(ZeroOrOne))
  cursor.exec(questions, empty_tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 0)
  cursor.exec(questions, tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 1)

  let mixed_left = Query::new(language, "(item)*?* @node")
  assert_true(mixed_left.capture_quantifier_for_id(0, 0) == Some(ZeroOrMore))
  cursor.exec(mixed_left, tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 3)

  let mixed_right = Query::new(language, "(item)?*? @node")
  assert_true(mixed_right.capture_quantifier_for_id(0, 0) == Some(ZeroOrMore))
  cursor.exec(mixed_right, tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 3)

  let capture_before_quantifier = Query::new(language, "(item) @node+")
  assert_true(
    capture_before_quantifier.capture_quantifier_for_id(0, 0) == Some(OneOrMore),
  )
  cursor.exec(capture_before_quantifier, tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 3)

  let commented_suffixes = Query::new(
    language,
    (
      #|(item) ; after pattern
      #|+ ; after quantifier
      #|@node
    ),
  )
  assert_true(
    commented_suffixes.capture_quantifier_for_id(0, 0) == Some(OneOrMore),
  )
  cursor.exec(commented_suffixes, tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 3)

  let commented_capture_suffix = Query::new(
    language,
    (
      #|(item) @node ; after capture
      #|+
    ),
  )
  assert_true(
    commented_capture_suffix.capture_quantifier_for_id(0, 0) == Some(OneOrMore),
  )
  cursor.exec(commented_capture_suffix, tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 3)
}

///|
test "query cursor matches anchored child patterns" {
  let language = query_test_anchor_language()
  let tree = query_test_anchor_tree()
  let cursor = QueryCursor::new()

  let first_named = Query::new(language, "(document . (item) @node) @root")
  cursor.exec(first_named, tree.root_node())
  let first_match = cursor.next_match().unwrap()
  assert_eq(first_match.captures.length(), 2)
  assert_eq(first_match.captures[1].name, "node")
  assert_eq(first_match.captures[1].node.start_byte(), 1)
  assert_true(cursor.next_match() is None)

  let first_any = Query::new(language, "(document . _ @node) @root")
  cursor.exec(first_any, tree.root_node())
  let any_match = cursor.next_match().unwrap()
  assert_eq(any_match.captures[1].node.type_(), "b")
  assert_true(!any_match.captures[1].node.is_named())

  let pair_language = query_test_pair_language()
  let pair_tree = query_test_pair_tree()
  let bare_wildcard_after_named = Query::new(
    pair_language, "(document (item) @left . _ @literal) @root",
  )
  cursor.exec(bare_wildcard_after_named, pair_tree.root_node())
  let bare_wildcard_match = cursor.next_match().unwrap()
  assert_eq(bare_wildcard_match.captures.length(), 3)
  assert_eq(bare_wildcard_match.captures[2].name, "literal")
  assert_eq(bare_wildcard_match.captures[2].node.type_(), "b")
  assert_true(!bare_wildcard_match.captures[2].node.is_named())

  let named_wildcard_after_named = Query::new(
    pair_language, "(document (item) @left . (_) @named) @root",
  )
  cursor.exec(named_wildcard_after_named, pair_tree.root_node())
  assert_true(cursor.next_match() is None)

  let mixed_language = query_test_mixed_repeat_language()
  let mixed_parser = @tree_sitter_mbt.Parser::new()
  mixed_parser.set_language(mixed_language)
  let mixed_tree = mixed_parser.parse_bytes(b"aab")
  let anchored_backtrack = Query::new(
    mixed_language, "(document (item) @left . (other) @right) @root",
  )
  cursor.exec(anchored_backtrack, mixed_tree.root_node())
  let backtracked = cursor.next_match().unwrap()
  assert_eq(backtracked.captures[1].node.start_byte(), 1)
  assert_eq(backtracked.captures[2].node.start_byte(), 2)
  assert_true(cursor.next_match() is None)

  let skipped = Query::new(
    language, "(document (item) @left (item) @right) @root",
  )
  cursor.exec(skipped, tree.root_node())
  let skipped_match = cursor.next_match().unwrap()
  assert_eq(skipped_match.captures.length(), 3)
  assert_eq(skipped_match.captures[1].node.start_byte(), 1)
  assert_eq(skipped_match.captures[2].node.start_byte(), 3)

  let immediate = Query::new(
    language, "(document (item) @left . (item) @right) @root",
  )
  cursor.exec(immediate, tree.root_node())
  assert_true(cursor.next_match() is None)

  let last_named = Query::new(language, "(document (item) @node .) @root")
  cursor.exec(last_named, tree.root_node())
  let last_match = cursor.next_match().unwrap()
  assert_eq(last_match.captures[1].node.start_byte(), 3)
  assert_true(cursor.next_match() is None)
}

///|
test "query cursor matches alternation patterns" {
  let simple_language = query_test_language()
  let simple_parser = @tree_sitter_mbt.Parser::new()
  simple_parser.set_language(simple_language)
  let simple_tree = simple_parser.parse_bytes(b"a")
  let root_alternation = Query::new(
    simple_language, "[(item) @node (document) @root]",
  )
  let cursor = QueryCursor::new()
  cursor.exec(root_alternation, simple_tree.root_node())
  let document_match = cursor.next_match().unwrap()
  assert_eq(document_match.captures[0].name, "root")
  assert_eq(document_match.captures[0].node.type_(), "document")
  let item_match = cursor.next_match().unwrap()
  assert_eq(item_match.captures[0].name, "node")
  assert_eq(item_match.captures[0].node.type_(), "item")
  assert_true(cursor.next_match() is None)

  let same_root_alternation = Query::new(
    simple_language, "[(item) @left (item) @right]",
  )
  cursor.exec(same_root_alternation, simple_tree.root_node())
  let left_root_match = cursor.next_match().unwrap()
  assert_eq(left_root_match.captures[0].name, "left")
  let right_root_match = cursor.next_match().unwrap()
  assert_eq(right_root_match.captures[0].name, "right")
  assert_true(cursor.next_match() is None)

  let language = query_test_anchor_language()
  let tree = query_test_anchor_tree()
  let first_branch = Query::new(
    language, "(document (item) @left [(other) @middle (item) @right]) @root",
  )
  cursor.exec(first_branch, tree.root_node())
  let first_branch_match = cursor.next_match().unwrap()
  assert_eq(first_branch_match.captures.length(), 3)
  assert_eq(first_branch_match.captures[1].name, "left")
  assert_eq(first_branch_match.captures[2].name, "middle")

  let same_child_alternation = Query::new(
    language, "(document (item) @left [(other) @one (other) @two]) @root",
  )
  cursor.exec(same_child_alternation, tree.root_node())
  let first_child_branch = cursor.next_match().unwrap()
  assert_eq(first_child_branch.captures.length(), 3)
  assert_eq(first_child_branch.captures[2].name, "one")
  let second_child_branch = cursor.next_match().unwrap()
  assert_eq(second_child_branch.captures.length(), 3)
  assert_eq(second_child_branch.captures[2].name, "two")
  assert_true(cursor.next_match() is None)

  let second_branch = Query::new(
    language, "(document (other) @middle [(other) @again (item) @right]) @root",
  )
  cursor.exec(second_branch, tree.root_node())
  let second_branch_match = cursor.next_match().unwrap()
  assert_eq(second_branch_match.captures.length(), 3)
  assert_eq(second_branch_match.captures[1].name, "middle")
  assert_eq(second_branch_match.captures[2].name, "right")

  let optional_capture = Query::new(
    language, "(document [(other) @maybe (item)]) @root",
  )
  assert_true(optional_capture.capture_name_for_id(0) == Some("maybe"))
  assert_true(
    optional_capture.capture_quantifier_for_id(0, 0) == Some(ZeroOrOne),
  )
  cursor.exec(optional_capture, tree.root_node())
  assert_eq(cursor.next_match().unwrap().captures.length(), 1)
}

///|
test "query cursor matches supertype patterns" {
  let language = query_test_supertype_language()
  let literal_tree = query_test_supertype_tree(b"a")
  let cursor = QueryCursor::new()

  let any_expr = Query::new(language, "(expr) @expr")
  cursor.exec(any_expr, literal_tree.root_node())
  let expr_capture = cursor.next_capture().unwrap()
  assert_eq(expr_capture.name, "expr")
  assert_eq(expr_capture.node.type_(), "literal")
  assert_true(cursor.next_capture() is None)

  let literal_only = Query::new(language, "(expr/literal) @literal")
  cursor.exec(literal_only, literal_tree.root_node())
  let literal_capture = cursor.next_capture().unwrap()
  assert_eq(literal_capture.name, "literal")
  assert_eq(literal_capture.node.type_(), "literal")

  let identifier_only = Query::new(language, "(expr/identifier) @identifier")
  cursor.exec(identifier_only, literal_tree.root_node())
  assert_true(cursor.next_capture() is None)

  let question_tree = query_test_supertype_tree(b"?")
  let question_only = Query::new(language, "(expr/\"?\") @question")
  cursor.exec(question_only, question_tree.root_node())
  let question_capture = cursor.next_capture().unwrap()
  assert_eq(question_capture.node.type_(), "?")
  assert_true(!question_capture.node.is_named())

  let bad_left = @test.expect_error(() => {
    Query::new(language, "(literal/identifier)")
  })
  assert_true(bad_left is NodeType(name="literal", ..))

  let bad_subtype = @test.expect_error(() => {
    Query::new(language, "(expr/document)")
  })
  assert_true(bad_subtype is NodeType(name="document", ..))

  let anonymous_subtype_with_child = @test.expect_error(() => {
    Query::new(language, "(expr/\"?\" (literal))")
  })
  assert_true(anonymous_subtype_with_child is Structure(..))
}

///|
test "query cursor remove_match filters future results" {
  let language = query_test_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(language, "(item) @node\n(document) @root")
  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())

  let first_match = cursor.next_match().unwrap()
  assert_eq(first_match.id, 0)
  assert_eq(first_match.pattern_index, 1)
  cursor.remove_match(first_match.id)
  cursor.remove_match(first_match.id)
  let second_match = cursor.next_match().unwrap()
  assert_eq(second_match.id, 1)
  assert_eq(second_match.pattern_index, 0)
  let first_capture = cursor.next_capture().unwrap()
  assert_eq(first_capture.match_id, second_match.id)
  assert_eq(first_capture.name, "node")
  assert_true(cursor.next_capture() is None)

  cursor.exec(query, tree.root_node())
  let root_match = cursor.next_match().unwrap()
  cursor.remove_match(root_match.id + 1)
  assert_true(cursor.next_match() is None)

  cursor.exec(query, tree.root_node())
  cursor.remove_match(0)
  let node_capture = cursor.next_capture().unwrap()
  assert_eq(node_capture.name, "node")
  cursor.remove_match(node_capture.match_id)
  assert_true(cursor.next_capture() is None)

  cursor.exec(query, tree.root_node())
  let reset_root_match = cursor.next_match().unwrap()
  assert_eq(reset_root_match.id, 0)
  assert_eq(reset_root_match.pattern_index, 1)
  let reset_node_match = cursor.next_match().unwrap()
  assert_eq(reset_node_match.id, 1)
  assert_eq(reset_node_match.pattern_index, 0)
}

///|
test "query cursor text predicate helpers remove failing matches" {
  let language = query_test_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(
    language,
    (
      #|(item) @bad (#eq? @bad "z")
      #|(item) @ok (#eq? @ok "a")
    ),
  )

  let match_cursor = QueryCursor::new()
  match_cursor.exec(query, tree.root_node())
  let matched = match_cursor
    .next_match_with_text_predicates_bytes(query, b"a")
    .unwrap()
  assert_eq(matched.pattern_index, 1)
  assert_eq(matched.captures[0].name, "ok")
  assert_true(
    match_cursor.next_match_with_text_predicates_bytes(query, b"a") is None,
  )

  let string_cursor = QueryCursor::new()
  string_cursor.exec(query, tree.root_node())
  let string_matched = string_cursor
    .next_match_with_text_predicates_string(query, "a")
    .unwrap()
  assert_eq(string_matched.pattern_index, 1)

  let capture_cursor = QueryCursor::new()
  capture_cursor.exec(query, tree.root_node())
  let capture = capture_cursor
    .next_capture_with_text_predicates_bytes(query, b"a")
    .unwrap()
  assert_eq(capture.name, "ok")
  assert_true(
    capture_cursor.next_capture_with_text_predicates_bytes(query, b"a") is None,
  )

  let string_capture_cursor = QueryCursor::new()
  string_capture_cursor.exec(query, tree.root_node())
  let string_capture = string_capture_cursor
    .next_capture_with_text_predicates_string(query, "a")
    .unwrap()
  assert_eq(string_capture.name, "ok")

  let pair_language = query_test_pair_language()
  let pair_tree = query_test_pair_tree()
  let multi_capture_query = Query::new(
    pair_language,
    (
      #|(document (item) @bad ("b") @bad)
      #|  (#eq? @bad "z")
      #|("b") @ok
      #|  (#eq? @ok "b")
    ),
  )
  let multi_capture_cursor = QueryCursor::new()
  multi_capture_cursor.exec(multi_capture_query, pair_tree.root_node())
  let later_capture = multi_capture_cursor
    .next_capture_with_text_predicates_bytes(multi_capture_query, b"ab")
    .unwrap()
  assert_eq(later_capture.name, "ok")
  assert_true(
    multi_capture_cursor.next_capture_with_text_predicates_bytes(
      multi_capture_query, b"ab",
    )
    is None,
  )
}

///|
test "query disable_capture removes capture output only" {
  let language = query_test_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(language, "(item) @node\n(document) @root")
  assert_true(query.disable_capture("node"))
  assert_true(!query.disable_capture("missing"))

  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())
  let first_match = cursor.next_match().unwrap()
  assert_eq(first_match.pattern_index, 1)
  assert_eq(first_match.captures.length(), 1)
  let second_match = cursor.next_match().unwrap()
  assert_eq(second_match.pattern_index, 0)
  assert_eq(second_match.captures.length(), 0)
  assert_true(query_capture_names(cursor) == ["root"])

  let pair_language = query_test_pair_language()
  let pair_tree = query_test_pair_tree()
  let repeated_capture = Query::new(
    pair_language, "(document (item) @node (\"b\") @node) @root",
  )
  assert_true(repeated_capture.disable_capture("node"))
  cursor.exec(repeated_capture, pair_tree.root_node())
  let repeated_match = cursor.next_match().unwrap()
  assert_eq(repeated_match.captures.length(), 1)
  assert_eq(repeated_match.captures[0].name, "root")
  assert_true(cursor.next_match() is None)
  assert_true(query_capture_names(cursor) == ["root"])
}

///|
test "query disable_pattern removes matches" {
  let language = query_test_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(language, "(item) @node\n(document) @root")
  assert_true(query.disable_pattern(0))
  assert_true(!query.disable_pattern(2))

  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())
  let matched = cursor.next_match().unwrap()
  assert_eq(matched.pattern_index, 1)
  assert_true(query_capture_names(cursor) == ["root"])
}

///|
test "query cursor byte range filters captures" {
  let language = query_test_pair_language()
  let tree = query_test_pair_tree()
  let query = Query::new(language, "(item) @node\n(\"b\") @literal")
  let cursor = QueryCursor::new()
  assert_true(cursor.set_byte_range(1, 2))
  assert_true(!cursor.set_byte_range(3, 2))
  cursor.exec(query, tree.root_node())
  assert_true(query_capture_names(cursor) == ["literal"])

  let unbounded = QueryCursor::new()
  assert_true(unbounded.set_byte_range(1, 0))
  unbounded.exec(query, tree.root_node())
  assert_true(query_capture_names(unbounded) == ["literal"])

  cursor.set_byte_range(0, 0) |> ignore
  cursor.exec(query, tree.root_node())
  assert_true(query_capture_names(cursor) == ["node", "literal"])

  let empty = QueryCursor::new()
  assert_true(empty.set_byte_range(1, 1))
  empty.exec(query, tree.root_node())
  assert_true(query_capture_names(empty) == ["node", "literal"])

  let nested = Query::new(
    language, "(document (item) @node (\"b\") @literal) @root",
  )
  cursor.set_byte_range(1, 2) |> ignore
  cursor.exec(nested, tree.root_node())
  let nested_match = cursor.next_match().unwrap()
  assert_eq(nested_match.captures.length(), 3)
  assert_true(query_capture_names(cursor) == ["root", "literal"])
}

///|
test "query cursor point range filters captures" {
  let language = query_test_pair_language()
  let tree = query_test_pair_tree()
  let query = Query::new(language, "(item) @node\n(\"b\") @literal")
  let cursor = QueryCursor::new()
  assert_true(
    cursor.set_point_range(
      @api.Point::new(row=0, column=1),
      @api.Point::new(row=0, column=2),
    ),
  )
  assert_true(
    !cursor.set_point_range(
      @api.Point::new(row=0, column=3),
      @api.Point::new(row=0, column=2),
    ),
  )
  cursor.exec(query, tree.root_node())
  assert_true(query_capture_names(cursor) == ["literal"])

  let unbounded = QueryCursor::new()
  assert_true(
    unbounded.set_point_range(
      @api.Point::new(row=0, column=1),
      @api.Point::zero(),
    ),
  )
  unbounded.exec(query, tree.root_node())
  assert_true(query_capture_names(unbounded) == ["literal"])

  cursor.set_point_range(@api.Point::zero(), @api.Point::zero()) |> ignore
  cursor.exec(query, tree.root_node())
  assert_true(query_capture_names(cursor) == ["node", "literal"])

  let empty = QueryCursor::new()
  assert_true(
    empty.set_point_range(
      @api.Point::new(row=0, column=1),
      @api.Point::new(row=0, column=1),
    ),
  )
  empty.exec(query, tree.root_node())
  assert_true(query_capture_names(empty) == ["node", "literal"])

  let nested = Query::new(
    language, "(document (item) @node (\"b\") @literal) @root",
  )
  cursor.set_point_range(
    @api.Point::new(row=0, column=1),
    @api.Point::new(row=0, column=2),
  )
  |> ignore
  cursor.exec(nested, tree.root_node())
  let nested_match = cursor.next_match().unwrap()
  assert_eq(nested_match.captures.length(), 3)
  assert_true(query_capture_names(cursor) == ["root", "literal"])
}

///|
test "query cursor containing byte range requires contained captures" {
  let language = query_test_pair_language()
  let tree = query_test_pair_tree()
  let query = Query::new(
    language, "(document) @root\n(item) @node\n(\"b\") @literal",
  )
  let cursor = QueryCursor::new()
  assert_true(cursor.set_containing_byte_range(1, 2))
  assert_true(!cursor.set_containing_byte_range(3, 2))
  cursor.exec(query, tree.root_node())
  assert_true(query_capture_names(cursor) == ["literal"])

  let unbounded = QueryCursor::new()
  assert_true(unbounded.set_containing_byte_range(1, 0))
  unbounded.exec(query, tree.root_node())
  assert_true(query_capture_names(unbounded) == ["literal"])

  cursor.set_containing_byte_range(0, 0) |> ignore
  cursor.exec(query, tree.root_node())
  assert_true(query_capture_names(cursor) == ["root", "node", "literal"])
}

///|
test "query cursor containing byte range requires contained matched nodes" {
  let language = query_test_pair_language()
  let tree = query_test_pair_tree()
  let query = Query::new(language, "(document (item) @node (\"b\"))")
  let only_capture_contained = QueryCursor::new()
  assert_true(only_capture_contained.set_containing_byte_range(0, 1))
  only_capture_contained.exec(query, tree.root_node())
  assert_true(only_capture_contained.next_match() is None)
  assert_true(query_capture_names(only_capture_contained) == [])

  let whole_match_contained = QueryCursor::new()
  assert_true(whole_match_contained.set_containing_byte_range(0, 2))
  whole_match_contained.exec(query, tree.root_node())
  assert_true(query_capture_names(whole_match_contained) == ["node"])
}

///|
test "query cursor containing point range requires contained captures" {
  let language = query_test_pair_language()
  let tree = query_test_pair_tree()
  let query = Query::new(
    language, "(document) @root\n(item) @node\n(\"b\") @literal",
  )
  let cursor = QueryCursor::new()
  assert_true(
    cursor.set_containing_point_range(
      @api.Point::new(row=0, column=1),
      @api.Point::new(row=0, column=2),
    ),
  )
  assert_true(
    !cursor.set_containing_point_range(
      @api.Point::new(row=0, column=3),
      @api.Point::new(row=0, column=2),
    ),
  )
  cursor.exec(query, tree.root_node())
  assert_true(query_capture_names(cursor) == ["literal"])

  let unbounded = QueryCursor::new()
  assert_true(
    unbounded.set_containing_point_range(
      @api.Point::new(row=0, column=1),
      @api.Point::zero(),
    ),
  )
  unbounded.exec(query, tree.root_node())
  assert_true(query_capture_names(unbounded) == ["literal"])

  cursor.set_containing_point_range(@api.Point::zero(), @api.Point::zero())
  |> ignore
  cursor.exec(query, tree.root_node())
  assert_true(query_capture_names(cursor) == ["root", "node", "literal"])
}

///|
test "query cursor containing point range requires contained matched nodes" {
  let language = query_test_pair_language()
  let tree = query_test_pair_tree()
  let query = Query::new(language, "(document (item) @node (\"b\"))")
  let only_capture_contained = QueryCursor::new()
  assert_true(
    only_capture_contained.set_containing_point_range(
      @api.Point::new(row=0, column=0),
      @api.Point::new(row=0, column=1),
    ),
  )
  only_capture_contained.exec(query, tree.root_node())
  assert_true(only_capture_contained.next_match() is None)
  assert_true(query_capture_names(only_capture_contained) == [])

  let whole_match_contained = QueryCursor::new()
  assert_true(
    whole_match_contained.set_containing_point_range(
      @api.Point::new(row=0, column=0),
      @api.Point::new(row=0, column=2),
    ),
  )
  whole_match_contained.exec(query, tree.root_node())
  assert_true(query_capture_names(whole_match_contained) == ["node"])
}

///|
test "query cursor max start depth limits pattern roots" {
  let language = query_test_pair_language()
  let tree = query_test_pair_tree()
  let query = Query::new(
    language, "(document) @root\n(item) @node\n(\"b\") @literal",
  )
  let root_only = QueryCursor::new()
  assert_true(root_only.set_max_start_depth(0))
  assert_true(!root_only.set_max_start_depth(-2))
  root_only.exec(query, tree.root_node())
  assert_true(query_capture_names(root_only) == ["root"])
  assert_true(
    root_only.set_max_start_depth(@api.uint32_max().reinterpret_as_int()),
  )
  root_only.exec(query, tree.root_node())
  assert_true(query_capture_names(root_only) == ["root", "node", "literal"])

  let root_internal = Query::new(
    language, "(document (item) @node (\"b\") @literal) @root",
  )
  let root_internal_cursor = QueryCursor::new()
  root_internal_cursor.set_max_start_depth(0) |> ignore
  root_internal_cursor.exec(root_internal, tree.root_node())
  let root_internal_match = root_internal_cursor.next_match().unwrap()
  assert_eq(root_internal_match.captures.length(), 3)
  assert_true(
    query_capture_names(root_internal_cursor) == ["node", "root", "literal"],
  )

  let children = QueryCursor::new()
  assert_true(children.set_max_start_depth(1))
  children.exec(query, tree.root_node())
  assert_true(query_capture_names(children) == ["root", "node", "literal"])
}

///|
test "query cursor match limit reports branching pressure" {
  let language = query_test_pair_language()
  let tree = query_test_pair_tree()
  let query = Query::new(language, "(item) @node\n(\"b\") @literal")
  let cursor = QueryCursor::new()
  assert_eq(cursor.match_limit(), @api.uint32_max())
  assert_true(!cursor.did_exceed_match_limit())

  cursor.set_match_limit(1)
  assert_eq(cursor.match_limit(), 1)
  cursor.exec(query, tree.root_node())
  assert_true(!cursor.did_exceed_match_limit())
  assert_true(query_capture_names(cursor) == ["node", "literal"])

  cursor.set_match_limit(10)
  cursor.exec(query, tree.root_node())
  assert_true(!cursor.did_exceed_match_limit())

  let repeat_language = query_test_repeat_language()
  let repeat_parser = @tree_sitter_mbt.Parser::new()
  repeat_parser.set_language(repeat_language)
  let branch_tree = repeat_parser.parse_bytes(b"aa")
  let branching = Query::new(
    repeat_language, "(document [(item) @one (item) @two]+) @root",
  )
  let branching_cursor = QueryCursor::new()
  branching_cursor.set_match_limit(1)
  branching_cursor.exec(branching, branch_tree.root_node())
  assert_true(branching_cursor.did_exceed_match_limit())
  assert_eq(branching_cursor.next_match().unwrap().captures.length(), 2)
  assert_true(branching_cursor.next_match() is None)

  let no_capture_query = Query::new(language, "(item)\n(\"b\")")
  let no_capture_cursor = QueryCursor::new()
  no_capture_cursor.set_match_limit(0)
  no_capture_cursor.exec(no_capture_query, tree.root_node())
  assert_true(!no_capture_cursor.did_exceed_match_limit())
  assert_eq(no_capture_cursor.next_match().unwrap().captures.length(), 0)
  assert_eq(no_capture_cursor.next_match().unwrap().captures.length(), 0)
  assert_true(no_capture_cursor.next_match() is None)

  let sibling_branching = Query::new(
    repeat_language, "([(item) @one (item) @two] (item) @tail)",
  )
  let sibling_branching_cursor = QueryCursor::new()
  sibling_branching_cursor.set_match_limit(1)
  sibling_branching_cursor.exec(sibling_branching, branch_tree.root_node())
  assert_true(sibling_branching_cursor.did_exceed_match_limit())
  assert_eq(sibling_branching_cursor.next_match().unwrap().captures.length(), 2)
  assert_true(sibling_branching_cursor.next_match() is None)

  branching_cursor.set_match_limit(10)
  branching_cursor.exec(query, tree.root_node())
  assert_true(!branching_cursor.did_exceed_match_limit())
  assert_true(query_capture_names(branching_cursor) == ["node", "literal"])
}

///|
test "query cursor progress callback can cancel scanning" {
  let language = query_test_repeat_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(Bytes::make(150, b'a'))
  let query = Query::new(language, "(item) @node")
  let cursor = QueryCursor::new()
  let offsets : Array[UInt] = []
  cursor.set_progress_callback(
    Some(state => {
      offsets.push(state.current_byte_offset)
      true
    }),
  )
  cursor.exec(query, tree.root_node())
  assert_eq(offsets.length(), 1)
  assert_true(offsets[0] >= 90)
  let mut capture_count = 0
  while cursor.next_capture() is Some(_) {
    capture_count += 1
  }
  assert_true(capture_count > 0)
  assert_true(capture_count < 150)

  cursor.set_progress_callback(None)
  cursor.exec(query, tree.root_node())
  capture_count = 0
  while cursor.next_capture() is Some(_) {
    capture_count += 1
  }
  assert_eq(capture_count, 150)
}

///|
test "query supports anonymous string root pattern" {
  let language = query_test_literal_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(language, "(\"a\") @literal")
  assert_eq(query.string_count(), 1)
  assert_true(query.string_value_for_id(0) == Some("a"))

  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())
  let capture = cursor.next_capture().unwrap()
  assert_eq(capture.name, "literal")
  assert_eq(capture.node.type_(), "a")
  assert_true(!capture.node.is_named())
  assert_true(cursor.next_capture() is None)

  let bare_query = Query::new(language, "\"a\" @literal")
  assert_eq(bare_query.string_count(), 1)
  assert_true(bare_query.string_value_for_id(0) == Some("a"))
  cursor.exec(bare_query, tree.root_node())
  let bare_capture = cursor.next_capture().unwrap()
  assert_eq(bare_capture.name, "literal")
  assert_eq(bare_capture.node.type_(), "a")
  assert_true(!bare_capture.node.is_named())
  assert_true(cursor.next_capture() is None)
}

///|
test "query supports named wildcard root pattern" {
  let language = query_test_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(language, "(_) @any")
  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())

  let root_capture = cursor.next_capture().unwrap()
  assert_eq(root_capture.node.type_(), "document")
  let item_capture = cursor.next_capture().unwrap()
  assert_eq(item_capture.node.type_(), "item")
  assert_true(cursor.next_capture() is None)
}

///|
test "query supports bare wildcard root pattern" {
  let language = query_test_literal_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let query = Query::new(language, "_ @any")
  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())

  let root_capture = cursor.next_capture().unwrap()
  assert_eq(root_capture.node.type_(), "document")
  assert_true(root_capture.node.is_named())
  let literal_capture = cursor.next_capture().unwrap()
  assert_eq(literal_capture.node.type_(), "a")
  assert_true(!literal_capture.node.is_named())
  assert_true(cursor.next_capture() is None)
}

///|
test "query supports ERROR root pattern" {
  let language = query_test_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"b")
  let query = Query::new(language, "(ERROR) @error")
  let cursor = QueryCursor::new()
  cursor.exec(query, tree.root_node())

  let capture = cursor.next_capture().unwrap()
  assert_eq(capture.name, "error")
  assert_true(capture.node.is_error())
  assert_true(cursor.next_capture() is None)

  let error_child_pattern = Query::new(language, "(ERROR (item) @child) @error")
  cursor.exec(error_child_pattern, tree.root_node())
  assert_true(cursor.next_match() is None)

  let wildcard = Query::new(language, "_ @any\n(_) @named")
  cursor.exec(wildcard, tree.root_node())
  let mut any_capture_count = 0
  let mut named_capture_count = 0
  while cursor.next_capture() is Some(capture) {
    assert_true(!capture.node.is_error())
    if capture.name == "any" {
      any_capture_count += 1
    } else if capture.name == "named" {
      named_capture_count += 1
    }
  }
  assert_true(any_capture_count > 0)
  assert_true(named_capture_count > 0)
}

///|
test "query supports MISSING root patterns" {
  let named_language = query_test_language()
  let named_parser = @tree_sitter_mbt.Parser::new()
  named_parser.set_language(named_language)
  let named_tree = named_parser.parse_bytes(b"")
  let missing_named = Query::new(named_language, "(MISSING item) @missing")
  let named_cursor = QueryCursor::new()
  named_cursor.exec(missing_named, named_tree.root_node())
  let named_capture = named_cursor.next_capture().unwrap()
  assert_true(named_capture.node.is_missing())
  assert_eq(named_capture.node.type_(), "item")
  assert_true(named_capture.node.is_named())

  let named_regular = Query::new(
    named_language, "(document (item) @node)\n(document (_) @named)",
  )
  named_cursor.exec(named_regular, named_tree.root_node())
  let regular_named_capture = named_cursor.next_capture().unwrap()
  assert_eq(regular_named_capture.name, "node")
  assert_true(regular_named_capture.node.is_missing())
  assert_eq(regular_named_capture.node.type_(), "item")
  let wildcard_named_capture = named_cursor.next_capture().unwrap()
  assert_eq(wildcard_named_capture.name, "named")
  assert_true(wildcard_named_capture.node.is_missing())
  assert_eq(wildcard_named_capture.node.type_(), "item")
  assert_true(named_cursor.next_capture() is None)

  let literal_language = query_test_literal_language()
  let literal_parser = @tree_sitter_mbt.Parser::new()
  literal_parser.set_language(literal_language)
  let literal_tree = literal_parser.parse_bytes(b"")
  let missing_any = Query::new(literal_language, "(MISSING) @missing")
  let any_cursor = QueryCursor::new()
  any_cursor.exec(missing_any, literal_tree.root_node())
  let any_capture = any_cursor.next_capture().unwrap()
  assert_true(any_capture.node.is_missing())

  let missing_literal = Query::new(literal_language, "(MISSING \"a\") @missing")
  let literal_cursor = QueryCursor::new()
  literal_cursor.exec(missing_literal, literal_tree.root_node())
  let literal_capture = literal_cursor.next_capture().unwrap()
  assert_true(literal_capture.node.is_missing())
  assert_eq(literal_capture.node.type_(), "a")
  assert_true(!literal_capture.node.is_named())

  let literal_regular = Query::new(
    literal_language, "(document (\"a\") @literal)\n(document _ @any)",
  )
  literal_cursor.exec(literal_regular, literal_tree.root_node())
  let regular_literal_capture = literal_cursor.next_capture().unwrap()
  assert_eq(regular_literal_capture.name, "literal")
  assert_true(regular_literal_capture.node.is_missing())
  assert_eq(regular_literal_capture.node.type_(), "a")
  let wildcard_literal_capture = literal_cursor.next_capture().unwrap()
  assert_eq(wildcard_literal_capture.name, "any")
  assert_true(wildcard_literal_capture.node.is_missing())
  assert_eq(wildcard_literal_capture.node.type_(), "a")
  assert_true(literal_cursor.next_capture() is None)
}

///|
test "query treats ERROR and MISSING special names exactly" {
  let language = query_test_language()
  let error_short_prefix = @test.expect_error(() => {
    Query::new(language, "(ERR)")
  })
  assert_true(error_short_prefix is NodeType(name="ERR", ..))

  let error_prefix = @test.expect_error(() => Query::new(language, "(ERRORx)"))
  assert_true(error_prefix is NodeType(name="ERRORx", ..))

  let missing_short_prefix = @test.expect_error(() => {
    Query::new(language, "(MISS)")
  })
  assert_true(missing_short_prefix is NodeType(name="MISS", ..))

  let missing_named_prefix = @test.expect_error(() => {
    Query::new(language, "(MISSING itemx)")
  })
  assert_true(missing_named_prefix is NodeType(name="itemx", ..))

  let missing_literal_prefix = @test.expect_error(() => {
    Query::new(language, "(MISSING \"ax\")")
  })
  assert_true(missing_literal_prefix is NodeType(name="ax", ..))
}

///|
test "query reports syntax and node type errors" {
  let language = query_test_language()
  let bad_syntax = @test.expect_error(() => Query::new(language, "(item"))
  assert_true(bad_syntax is Syntax(..))

  let bad_node = @test.expect_error(() => Query::new(language, "(missing)"))
  assert_true(bad_node is NodeType(name="missing", ..))

  let bad_literal = @test.expect_error(() => {
    Query::new(language, "(\"missing\")")
  })
  assert_true(bad_literal is NodeType(name="missing", ..))

  let bad_bare_literal = @test.expect_error(() => {
    Query::new(language, "\"missing\"")
  })
  assert_true(bad_bare_literal is NodeType(name="missing", ..))

  let bare_child_identifier = @test.expect_error(() => {
    Query::new(language, "(document item)")
  })
  assert_true(bare_child_identifier is Syntax(..))

  let field_language = query_test_field_language()
  let bad_field = @test.expect_error(() => {
    Query::new(field_language, "(document missing: (item))")
  })
  assert_true(bad_field is Field(name="missing", ..))

  let bad_root_field = @test.expect_error(() => {
    Query::new(field_language, "missing: (item)")
  })
  assert_true(bad_root_field is Field(name="missing", ..))

  let bad_negated_field = @test.expect_error(() => {
    Query::new(field_language, "(document !missing)")
  })
  assert_true(bad_negated_field is Field(name="missing", ..))

  let bad_predicate_capture = @test.expect_error(() => {
    Query::new(language, "(item) @node (#eq? @missing \"a\")")
  })
  assert_true(bad_predicate_capture is Capture(name="missing", ..))

  let bad_predicate_symbol = @test.expect_error(() => {
    Query::new(language, "(item) @node (#custom! a/b)")
  })
  assert_true(bad_predicate_symbol is Syntax(..))

  let bad_predicate_capture_suffix = @test.expect_error(() => {
    Query::new(language, "(item) @node (#eq? @node/extra \"a\")")
  })
  assert_true(bad_predicate_capture_suffix is Syntax(..))

  let bad_predicate_operator = @test.expect_error(() => {
    Query::new(language, "(item) @node (#custom @node)")
  })
  assert_true(bad_predicate_operator is Syntax(..))

  let dot_start_predicate_operator = @test.expect_error(() => {
    Query::new(language, "(item) @node (#.custom? @node)")
  })
  assert_true(dot_start_predicate_operator is Syntax(..))

  let suffix_only_predicate_operator = @test.expect_error(() => {
    Query::new(language, "(item) @node (#? @node)")
  })
  assert_true(suffix_only_predicate_operator is Syntax(..))

  let embedded_suffix_predicate_operator = @test.expect_error(() => {
    Query::new(language, "(item) @node (#custom?! @node)")
  })
  assert_true(embedded_suffix_predicate_operator is Syntax(..))

  let empty_root_alternation = @test.expect_error(() => {
    Query::new(language, "[]")
  })
  assert_true(empty_root_alternation is Syntax(..))

  let empty_child_alternation = @test.expect_error(() => {
    Query::new(language, "(document [])")
  })
  assert_true(empty_child_alternation is Syntax(..))

  let dangling_child_anchor = @test.expect_error(() => {
    Query::new(language, "(document .)")
  })
  assert_true(dangling_child_anchor is Syntax(..))

  let valid_predicate_capture = Query::new(
    language, "(item) @node (#eq? @node \"a\")",
  )
  assert_eq(valid_predicate_capture.capture_count(), 1)
  assert_true(valid_predicate_capture.capture_name_for_id(0) == Some("node"))

  let pair_language = query_test_pair_language()
  let string_first_group = Query::new(pair_language, "(\"b\" (item))")
  assert_eq(string_first_group.pattern_count(), 1)

  let named_terminal_with_child = @test.expect_error(() => {
    Query::new(language, "(item (item))")
  })
  assert_true(named_terminal_with_child is Structure(..))

  let missing_with_child = @test.expect_error(() => {
    Query::new(language, "(MISSING item (item))")
  })
  assert_true(missing_with_child is Syntax(..))

  let missing_with_extra_symbol = @test.expect_error(() => {
    Query::new(language, "(MISSING item item)")
  })
  assert_true(missing_with_extra_symbol is Syntax(..))
}

///|
test "query intentionally allows more than upstream step storage limits" {
  let language = query_test_language()
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  let many_captures = Query::new(language, "(item) @one @two @three @four")
  assert_eq(many_captures.capture_count(), 4)
  let capture_cursor = QueryCursor::new()
  capture_cursor.exec(many_captures, tree.root_node())
  assert_true(
    query_capture_names(capture_cursor) == ["one", "two", "three", "four"],
  )

  let field_language = query_test_many_fields_language()
  let field_parser = @tree_sitter_mbt.Parser::new()
  field_parser.set_language(field_language)
  let field_tree = field_parser.parse_bytes(b"a")
  let many_negated_fields = Query::new(
    field_language, "(document !f1 !f2 !f3 !f4 !f5 !f6 !f7 !f8 !f9) @root",
  )
  let field_cursor = QueryCursor::new()
  field_cursor.exec(many_negated_fields, field_tree.root_node())
  assert_true(query_capture_names(field_cursor) == ["root"])
}
