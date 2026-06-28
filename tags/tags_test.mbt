///|
fn tags_test_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "tags_test",
      #|  "extras": [{ "type": "PATTERN", "value": "\\s" }],
      #|  "rules": {
      #|    "document": {
      #|      "type": "REPEAT",
      #|      "content": { "type": "SYMBOL", "name": "item" }
      #|    },
      #|    "item": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        { "type": "STRING", "value": "a" },
      #|        { "type": "STRING", "value": "b" },
      #|        { "type": "STRING", "value": "é" }
      #|      ]
      #|    }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn tags_doc_test_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "tags_doc_test",
      #|  "extras": [{ "type": "PATTERN", "value": "\\s" }],
      #|  "rules": {
      #|    "document": {
      #|      "type": "REPEAT",
      #|      "content": {
      #|        "type": "CHOICE",
      #|        "members": [
      #|          { "type": "SYMBOL", "name": "doc" },
      #|          { "type": "SYMBOL", "name": "item" }
      #|        ]
      #|      }
      #|    },
      #|    "doc": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        { "type": "STRING", "value": "/// skip" },
      #|        { "type": "STRING", "value": "/// keep" }
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
fn tags_scope_test_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "tags_scope_test",
      #|  "rules": {
      #|    "document": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        { "type": "SYMBOL", "name": "item" },
      #|        { "type": "SYMBOL", "name": "scope" },
      #|        { "type": "SYMBOL", "name": "item" }
      #|      ]
      #|    },
      #|    "scope": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        { "type": "STRING", "value": "[" },
      #|        { "type": "SYMBOL", "name": "item" },
      #|        { "type": "SYMBOL", "name": "item" },
      #|        { "type": "STRING", "value": "]" }
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
test "tags generate definition and reference records" {
  let config = TagsConfiguration::new(
    tags_test_language(),
    (
      #|(document . (item) @definition.function @name)
      #|(document (item) . (item) @reference.call @name)
    ),
  )
  assert_eq(config.tags_pattern_start(), 0)
  let result = generate_tags(config, b"ab")
  assert_true(!result.has_error)
  assert_eq(result.tags.length(), 2)
  assert_eq(result.tags[0].name, "a")
  assert_true(result.tags[0].kind == Definition)
  assert_eq(result.tags[0].syntax_type, "function")
  let first_range = @api.Range::new(
    start_byte=0U,
    end_byte=1U,
    start_point=@api.Point::new(row=0U, column=0U),
    end_point=@api.Point::new(row=0U, column=1U),
  )
  assert_true(result.tags[0].range == first_range)
  assert_true(result.tags[0].name_range == first_range)
  assert_true(result.tags[0].span == first_range)
  assert_eq(result.tags[1].name, "b")
  assert_true(result.tags[1].kind == Reference)
  assert_eq(result.tags[1].syntax_type, "call")
}

///|
test "tags filter local references and ignored names" {
  let config = TagsConfiguration::new(
    tags_test_language(),
    (
      #|(document
      #|  (item) @ignore @definition.function @name)
      #|(document
      #|  (item)
      #|  (item) @reference.call @name
      #|  (#is-not? local))
    ),
    locals_query=(
      #|(document (item) @local.definition)
    ),
  )
  let result = generate_tags(config, b"aa")
  assert_eq(result.tags.length(), 0)
}

///|
test "tags apply text predicates" {
  let config = TagsConfiguration::new(
    tags_test_language(),
    "(item) @definition.function @name (#eq? @name \"a\")",
  )
  let result = generate_tags(config, b"ab")
  assert_eq(result.tags.length(), 1)
  assert_eq(result.tags[0].name, "a")
}

///|
test "tags validate capture names and allow local references" {
  let language = tags_test_language()
  try TagsConfiguration::new(language, "(item) @custom") catch {
    InvalidCaptureName(name) => assert_eq(name, "custom")
    _ => fail("expected invalid capture name")
  } noraise {
    _ => fail("expected invalid capture name")
  }
  let valid = TagsConfiguration::new(
    language,
    "(item) @definition.function @name",
    locals_query="(item) @local.reference",
  )
  assert_true(valid.names().contains("local.reference"))
}

///|
test "tags local scope can stop outer definition inheritance" {
  let language = tags_scope_test_language()
  let tags_query =
    #|(scope . (item) @reference.call @name (#is-not? local))
    #|(scope (item) . (item) @reference.call @name (#is-not? local))
  let inherited_config = TagsConfiguration::new(
    language,
    tags_query,
    locals_query=(
      #|(document . (item) @local.definition)
      #|(scope) @local.scope
    ),
  )
  let inherited_result = generate_tags(inherited_config, b"a[aa]a")
  assert_eq(inherited_result.tags.length(), 0)
  let isolated_config = TagsConfiguration::new(
    language,
    tags_query,
    locals_query=(
      #|(document . (item) @local.definition)
      #|(scope) @local.scope (#set! local.scope-inherits false)
    ),
  )
  let isolated_result = generate_tags(isolated_config, b"a[aa]a")
  assert_eq(isolated_result.tags.length(), 2)
  assert_eq(isolated_result.tags[0].name_range.start_byte, 2U)
  assert_eq(isolated_result.tags[1].name_range.start_byte, 3U)
}

///|
test "tags deduplicate name ranges and suppress trailing ignored names" {
  let language = tags_test_language()
  let duplicate_config = TagsConfiguration::new(
    language,
    (
      #|(item) @definition.function @name
      #|(item) @definition.class @name
    ),
  )
  let duplicate_result = generate_tags(duplicate_config, b"a")
  assert_eq(duplicate_result.tags.length(), 1)
  assert_eq(duplicate_result.tags[0].syntax_type, "function")
  let ignore_config = TagsConfiguration::new(
    language, "(item) @ignore @definition.function @name",
  )
  let ignored_result = generate_tags(ignore_config, b"a")
  assert_eq(ignored_result.tags.length(), 0)
}

///|
test "tags compute trimmed line and utf16 columns" {
  let config = TagsConfiguration::new(
    tags_test_language(),
    "(item) @definition.function @name",
  )
  let result = generate_tags(config, @utf8.encode("  é  "))
  assert_eq(result.tags.length(), 1)
  let tag = result.tags[0]
  assert_eq(tag.name, "é")
  assert_true(tag.line_range.start_byte == 2U)
  assert_true(tag.line_range.end_byte == 4U)
  assert_true(tag.utf16_column_range == { start: 2U, end: 3U })
}

///|
test "tags select adjacent docs and strip prefixes" {
  let config = TagsConfiguration::new(
    tags_doc_test_language(),
    (
      #|(document
      #|  (doc) @doc
      #|  (doc) @doc
      #|  (doc) @doc
      #|  (item) @definition.function @name
      #|  (#select-adjacent! @doc @name)
      #|  (#strip! @doc "^/// "))
    ),
  )
  let result = generate_tags(config, b"/// skip\n\n/// keep\n/// keep\na")
  assert_eq(result.tags.length(), 1)
  assert_eq(result.tags[0].docs, "keep\nkeep")
}

///|
test "tags ignore select adjacent when first argument is not doc" {
  let config = TagsConfiguration::new(
    tags_doc_test_language(),
    (
      #|(document
      #|  (doc) @doc
      #|  (doc) @doc
      #|  (item) @definition.function @name
      #|  (#select-adjacent! @name @doc)
      #|  (#strip! @doc "^/// "))
    ),
  )
  let result = generate_tags(config, b"/// skip\n\n/// keep\na")
  assert_eq(result.tags.length(), 1)
  assert_eq(result.tags[0].docs, "skip\nkeep")
}

///|
test "tags ignore strip when first argument is not doc" {
  let config = TagsConfiguration::new(
    tags_doc_test_language(),
    (
      #|(document
      #|  (doc) @doc
      #|  (item) @definition.function @name
      #|  (#strip! @name "^/// "))
    ),
  )
  let result = generate_tags(config, b"/// keep\na")
  assert_eq(result.tags.length(), 1)
  assert_eq(result.tags[0].docs, "/// keep")
}

///|
test "tags can be cancelled before parsing" {
  let config = TagsConfiguration::new(
    tags_test_language(),
    "(item) @definition.function @name",
  )
  let state = TagsProgressState::new(phase=Query, current_byte_offset=9U)
  try generate_tags(config, b"a", options=TagsOptions::cancelled(state)) catch {
    Cancelled(cancelled) => assert_true(cancelled == state)
    _ => fail("expected tags cancellation")
  } noraise {
    _ => fail("expected tags cancellation")
  }
}
