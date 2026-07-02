///|
fn minimal_grammar_json() -> String {
  (
    #|{
    #|  "name": "minimal",
    #|  "rules": {
    #|    "document": { "type": "STRING", "value": "a" }
    #|  }
    #|}
  )
}

///|
fn generator_test_contains_string(
  values : Array[String],
  value : String,
) -> Bool {
  for item in values {
    if item == value {
      return true
    }
  }
  false
}

///|
fn generator_test_source_for_path(
  sources : Array[GeneratedSource],
  path : String,
) -> String? {
  for source in sources {
    if source.path == path {
      return Some(source.content)
    }
  }
  None
}

///|
fn generator_test_string_contains(source : String, needle : String) -> Bool {
  if needle.length() == 0 {
    return true
  }
  if source.length() < needle.length() {
    return false
  }
  for i in 0..<=(source.length() - needle.length()) {
    if source.unsafe_substring(start=i, end=i + needle.length()) == needle {
      return true
    }
  }
  false
}

///|
fn generator_test_assert_valid_json(source : String) -> Unit raise {
  let _ = @json.parse(source[:]) catch { err => fail(err.to_string()) }
}

///|
test "generate language validates grammar json and uses grammar name by default" {
  let generated = generate_language(minimal_grammar_json())
  assert_eq(generated.language_name, "minimal")
  assert_eq(generated.abi_version, @tables.target_abi_version())
  generator_test_assert_valid_json(generated.node_types_json)
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"type\": \"document\", \"named\": true, \"root\": true",
    ),
  )
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"children\": {\"multiple\": false, \"required\": true, \"types\": [{\"type\": \"a\", \"named\": false}]}",
    ),
  )
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "{\"type\": \"a\", \"named\": false}",
    ),
  )
  assert_eq(generated.moonbit_sources.length(), 2)
  guard generator_test_source_for_path(generated.moonbit_sources, "moon.pkg")
    is Some(moon_pkg) else {
    fail("moon.pkg source should be generated")
  }
  assert_true(
    generator_test_string_contains(
      moon_pkg, "\"moonbit-community/tree_sitter_mbt/runtime/tables\"",
    ),
  )
  guard generator_test_source_for_path(
      generated.moonbit_sources,
      "language.mbt",
    )
    is Some(language_source) else {
    fail("language.mbt source should be generated")
  }
  assert_true(
    generator_test_string_contains(
      language_source, "pub fn language() -> @tree_sitter_mbt.Language raise @tables.TableValidationError",
    ),
  )
  assert_true(
    generator_test_string_contains(
      language_source, "@tables.GeneratedLanguageTables::new",
    ),
  )
  assert_true(
    generator_test_string_contains(
      language_source, "symbol_names=[\"end\", \"a\", \"document\"]",
    ),
  )
  let validated = @tables.validate(generated.tables)
  assert_eq(validated.name(), "minimal")
  assert_eq(validated.symbol_count(), 3)
  assert_eq(validated.token_count(), 2)
  assert_eq(validated.external_token_count(), 0)
  assert_eq(validated.state_count(), 4)
  assert_eq(validated.production_id_count(), 1)
  assert_eq(validated.max_alias_sequence_length(), 1)
  assert_eq(validated.external_lex_state_count(), 1)
  assert_eq(validated.reserved_word_set_count(), 1)
  assert_eq(validated.max_reserved_word_set_size(), 0)
  assert_true(validated.main_lex_state_count() > 0)
  assert_true(
    validated.reserved_word_set(0) == Some(@tables.GeneratedTokenSet::new()),
  )
  assert_true(
    validated.external_lex_state(0) ==
    Some(@tables.GeneratedExternalLexState::new()),
  )
  assert_true(
    validated.lex_mode(@api.StateId::new(1)) ==
    Some(@tables.GeneratedLexMode::new(lex_state=0)),
  )
  guard validated.main_lex_table(0) is Some(lex_table) else {
    fail("start state main lex table should be generated")
  }
  assert_eq(lex_table.start_state, 0)
  assert_true(lex_table.states.length() > 1)
  assert_true(
    lex_table.states[0].transitions[0].ranges ==
    [@tables.GeneratedCharacterRange::new(start=97, end=97)],
  )
  assert_true(
    validated.primary_state_id(@api.StateId::new(1)) ==
    Some(@api.StateId::new(1)),
  )
  assert_eq(validated.large_state_count(), 2)
  assert_true(
    validated.large_parse_table_cell(
      @api.StateId::new(1),
      @api.SymbolId::new(1),
    ) ==
    Some(@tables.GeneratedParseTableCell::ActionCell(1)),
  )
  assert_true(
    validated.large_parse_table_cell(
      @api.StateId::new(1),
      @api.SymbolId::new(2),
    ) ==
    Some(@tables.GeneratedParseTableCell::StateCell(3)),
  )
  assert_true(validated.small_parse_table_offset(0) == Some(0))
  guard validated.small_parse_table_row(0) is Some(first_small_row) else {
    fail("first small parse table row should be generated")
  }
  assert_eq(first_small_row.state_id, 2)
  assert_eq(validated.parse_action_list_count(), 4)
  guard validated.parse_action_list(1) is Some(shift_list) else {
    fail("shift action list should be generated")
  }
  assert_true(shift_list.reusable)
  assert_true(
    shift_list.actions[0] ==
    @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
  )
  guard validated.parse_action_list(2) is Some(reduce_list) else {
    fail("reduce action list should be generated")
  }
  assert_true(
    reduce_list.actions[0] ==
    @tables.GeneratedParseAction::Reduce(
      symbol_id=2,
      child_count=1,
      dynamic_precedence=0,
      production_id=0,
    ),
  )
  guard validated.parse_action_list(3) is Some(accept_list) else {
    fail("accept action list should be generated")
  }
  assert_true(accept_list.actions[0] == @tables.GeneratedParseAction::Accept)
  assert_true(validated.symbol_name(@api.SymbolId::new(0)) == Some("end"))
  assert_true(validated.symbol_name(@api.SymbolId::new(1)) == Some("a"))
  assert_true(
    validated.symbol_type(@api.SymbolId::new(1)) ==
    Some(@api.SymbolType::Anonymous),
  )
  assert_true(validated.symbol_name(@api.SymbolId::new(2)) == Some("document"))
}

///|
test "generate language options can override language name" {
  let generated = generate_language(minimal_grammar_json(), options={
    ..GenerateOptions::default(),
    language_name: "override",
  })
  assert_eq(generated.language_name, "override")
  assert_eq(@tables.validate(generated.tables).name(), "override")
}

///|
test "generate language sources honor custom import aliases" {
  let generated = generate_language(minimal_grammar_json(), options={
    ..GenerateOptions::default(),
    root_alias: "runtime_facade",
    tables_alias: "runtime_tables",
    api_alias: "runtime_api",
  })
  guard generator_test_source_for_path(generated.moonbit_sources, "moon.pkg")
    is Some(moon_pkg) else {
    fail("moon.pkg source should be generated")
  }
  assert_true(
    generator_test_string_contains(
      moon_pkg, "\"moonbit-community/tree_sitter_mbt\" @runtime_facade",
    ),
  )
  assert_true(
    generator_test_string_contains(
      moon_pkg, "\"moonbit-community/tree_sitter_mbt/runtime/tables\" @runtime_tables",
    ),
  )
  assert_true(
    generator_test_string_contains(
      moon_pkg, "\"moonbit-community/tree_sitter_mbt/api\" @runtime_api",
    ),
  )
  guard generator_test_source_for_path(
      generated.moonbit_sources,
      "language.mbt",
    )
    is Some(language_source) else {
    fail("language.mbt source should be generated")
  }
  assert_true(
    generator_test_string_contains(
      language_source, "pub fn language() -> @runtime_facade.Language raise @runtime_tables.TableValidationError",
    ),
  )
  assert_true(
    generator_test_string_contains(
      language_source, "@runtime_api.SymbolType::Anonymous",
    ),
  )
}

///|
test "generate language rejects invalid import aliases" {
  let invalid_character = @test.expect_error(() => {
    generate_language(minimal_grammar_json(), options={
      ..GenerateOptions::default(),
      root_alias: "bad-alias",
    })
  })
  assert_true(
    invalid_character is GenerateError::InvalidImportAlias("bad-alias"),
  )
  let invalid_start = @test.expect_error(() => {
    generate_language(minimal_grammar_json(), options={
      ..GenerateOptions::default(),
      tables_alias: "1tables",
    })
  })
  assert_true(invalid_start is GenerateError::InvalidImportAlias("1tables"))
  let keyword = @test.expect_error(() => {
    generate_language(minimal_grammar_json(), options={
      ..GenerateOptions::default(),
      api_alias: "fn",
    })
  })
  assert_true(keyword is GenerateError::InvalidImportAlias("fn"))
  let duplicate = @test.expect_error(() => {
    generate_language(minimal_grammar_json(), options={
      ..GenerateOptions::default(),
      root_alias: "shared_alias",
      tables_alias: "shared_alias",
    })
  })
  assert_true(duplicate is GenerateError::InvalidImportAlias("shared_alias"))
}

///|
test "generate language emits keyword lex table for word-like string token" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "keyword_literal",
      #|  "word": "identifier",
      #|  "rules": {
      #|    "document": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        { "type": "SYMBOL", "name": "keyword" },
      #|        { "type": "SYMBOL", "name": "identifier" }
      #|      ]
      #|    },
      #|    "identifier": { "type": "PATTERN", "value": "[a-z]+" },
      #|    "keyword": { "type": "STRING", "value": "if" }
      #|  }
      #|}
    ),
  )
  let validated = @tables.validate(generated.tables)
  assert_true(validated.keyword_capture_token() is Some(_))
  guard validated.keyword_lex_table() is Some(keyword_table) else {
    fail("word-like string token should produce a keyword lex table")
  }
  assert_true(keyword_table.states.length() > 0)
}

///|
test "generate language exposes generated table fields and metadata" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "fielded",
      #|  "rules": {
      #|    "document": {
      #|      "type": "FIELD",
      #|      "name": "body",
      #|      "content": { "type": "STRING", "value": "a" }
      #|    }
      #|  }
      #|}
    ),
    options={
      ..GenerateOptions::default(),
      semantic_version: Some(
        @tables.LanguageMetadata::new(major=1, minor=2, patch=3),
      ),
    },
  )
  let validated = @tables.validate(generated.tables)
  assert_true(
    validated.metadata() ==
    @tables.LanguageMetadata::new(major=1, minor=2, patch=3),
  )
  assert_eq(validated.field_count(), 1)
  assert_eq(validated.production_id_count(), 2)
  assert_true(validated.field_name_for_id(@api.FieldId::new(1)) == Some("body"))
  assert_true(validated.field_id_for_name("body") == Some(@api.FieldId::new(1)))
  guard validated.production_info(1) is Some(info) else {
    fail("fielded production info should be generated")
  }
  assert_eq(info.field_map.length(), 1)
  assert_eq(info.field_map[0].field_id, 1)
  assert_true(
    info.field_map[0].locations ==
    [@tables.GeneratedFieldLocation::new(index=0, inherited=false)],
  )
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"fields\": {\"body\": {\"multiple\": false, \"required\": true, \"types\": [{\"type\": \"a\", \"named\": false}]}}",
    ),
  )
}

///|
test "generate node-types inherits fields from hidden variables" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "hidden_fields",
      #|  "rules": {
      #|    "document": { "type": "SYMBOL", "name": "_wrapper" },
      #|    "_wrapper": {
      #|      "type": "FIELD",
      #|      "name": "body",
      #|      "content": { "type": "SYMBOL", "name": "leaf" }
      #|    },
      #|    "leaf": { "type": "STRING", "value": "a" }
      #|  }
      #|}
    ),
  )
  generator_test_assert_valid_json(generated.node_types_json)
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"type\": \"document\", \"named\": true, \"root\": true",
    ),
  )
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"fields\": {\"body\": {\"multiple\": false, \"required\": true, \"types\": [{\"type\": \"leaf\", \"named\": true}]}}",
    ),
  )
  assert_true(
    !generator_test_string_contains(
      generated.node_types_json,
      "\"type\": \"_wrapper\"",
    ),
  )
}

///|
test "generate node-types marks extra symbols" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "extra_nodes",
      #|  "rules": {
      #|    "document": { "type": "STRING", "value": "a" },
      #|    "comment": { "type": "PATTERN", "value": "#.*" }
      #|  },
      #|  "extras": [{ "type": "SYMBOL", "name": "comment" }]
      #|}
    ),
  )
  generator_test_assert_valid_json(generated.node_types_json)
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "{\"type\": \"comment\", \"named\": true, \"extra\": true}",
    ),
  )
}

///|
test "generate language exposes production alias sequences" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "aliased",
      #|  "rules": {
      #|    "document": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        {
      #|          "type": "SEQ",
      #|          "members": [
      #|            {
      #|              "type": "ALIAS",
      #|              "value": "leaf",
      #|              "named": true,
      #|              "content": { "type": "STRING", "value": "a" }
      #|            },
      #|            { "type": "STRING", "value": "b" }
      #|          ]
      #|        },
      #|        {
      #|          "type": "SEQ",
      #|          "members": [
      #|            { "type": "STRING", "value": "a" },
      #|            { "type": "STRING", "value": "c" }
      #|          ]
      #|        }
      #|      ]
      #|    }
      #|  }
      #|}
    ),
  )
  let validated = @tables.validate(generated.tables)
  assert_eq(validated.alias_count(), 1)
  let alias_symbol_id = @api.SymbolId::new(
    validated.symbol_count().reinterpret_as_uint(),
  )
  assert_true(validated.symbol_name(alias_symbol_id) == Some("leaf"))
  assert_true(
    validated.symbol_type(alias_symbol_id) == Some(@api.SymbolType::Regular),
  )
  let mut found_alias = false
  for i in 0..<validated.production_id_count() {
    match validated.production_info(i) {
      Some(info) =>
        if info.alias_sequence ==
          [Some(@tables.GeneratedAlias::new(value="leaf", named=true))] {
          found_alias = true
        }
      None => ()
    }
  }
  assert_true(found_alias)
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "{\"type\": \"leaf\", \"named\": true}",
    ),
  )
  guard generator_test_source_for_path(
      generated.moonbit_sources,
      "language.mbt",
    )
    is Some(language_source) else {
    fail("language.mbt source should be generated")
  }
  assert_true(generator_test_string_contains(language_source, "alias_count=1"))
  assert_true(
    generator_test_string_contains(
      language_source, "alias_symbols=[@tables.GeneratedAlias::new(value=\"leaf\", named=true)]",
    ),
  )
}

///|
test "generate node-types exposes named rule aliased as anonymous" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "anonymous_alias",
      #|  "rules": {
      #|    "document": {
      #|      "type": "ALIAS",
      #|      "value": "anonymous_leaf",
      #|      "named": false,
      #|      "content": { "type": "SYMBOL", "name": "leaf" }
      #|    },
      #|    "leaf": { "type": "STRING", "value": "a" }
      #|  }
      #|}
    ),
  )
  generator_test_assert_valid_json(generated.node_types_json)
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"type\": \"anonymous_leaf\", \"named\": false",
    ),
  )
}

///|
test "generate node-types keeps anonymous ERROR distinct from builtin error" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "anonymous_error",
      #|  "rules": {
      #|    "document": { "type": "STRING", "value": "ERROR" }
      #|  }
      #|}
    ),
  )
  generator_test_assert_valid_json(generated.node_types_json)
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "{\"type\": \"ERROR\", \"named\": false}",
    ),
  )
  let validated = @tables.validate(generated.tables)
  let mut found_anonymous_error = false
  for i in 0..<validated.symbol_count() {
    let symbol_id = @api.SymbolId::new(i.reinterpret_as_uint())
    if validated.symbol_name(symbol_id) == Some("ERROR") {
      assert_true(
        validated.symbol_type(symbol_id) == Some(@api.SymbolType::Anonymous),
      )
      found_anonymous_error = true
    }
  }
  assert_true(found_anonymous_error)
}

///|
test "generate node-types makes fields and children optional across merged aliases" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "alias_merge_optional",
      #|  "rules": {
      #|    "document": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        {
      #|          "type": "ALIAS",
      #|          "value": "item",
      #|          "named": true,
      #|          "content": { "type": "SYMBOL", "name": "_complex" }
      #|        },
      #|        {
      #|          "type": "ALIAS",
      #|          "value": "item",
      #|          "named": true,
      #|          "content": { "type": "STRING", "value": "b" }
      #|        }
      #|      ]
      #|    },
      #|    "_complex": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        {
      #|          "type": "FIELD",
      #|          "name": "body",
      #|          "content": { "type": "SYMBOL", "name": "leaf" }
      #|        },
      #|        { "type": "SYMBOL", "name": "tail" }
      #|      ]
      #|    },
      #|    "leaf": { "type": "STRING", "value": "a" },
      #|    "tail": { "type": "STRING", "value": "c" }
      #|  }
      #|}
    ),
  )
  generator_test_assert_valid_json(generated.node_types_json)
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"type\": \"item\", \"named\": true",
    ),
  )
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"fields\": {\"body\": {\"multiple\": false, \"required\": false, \"types\": [{\"type\": \"leaf\", \"named\": true}]}}",
    ),
  )
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"children\": {\"multiple\": false, \"required\": false, \"types\": [{\"type\": \"tail\", \"named\": true}]}",
    ),
  )
}

///|
test "generate language exposes default alias metadata" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "default_alias",
      #|  "rules": {
      #|    "document": {
      #|      "type": "ALIAS",
      #|      "value": "leaf",
      #|      "named": true,
      #|      "content": { "type": "STRING", "value": "a" }
      #|    }
      #|  }
      #|}
    ),
  )
  let validated = @tables.validate(generated.tables)
  let mut found_default_alias = false
  for i in 0..<validated.symbol_count() {
    let symbol_id = @api.SymbolId::new(i.reinterpret_as_uint())
    if validated.symbol_name(symbol_id) == Some("a") {
      assert_true(
        validated.default_alias_for_symbol(symbol_id) ==
        Some(@tables.GeneratedAlias::new(value="leaf", named=true)),
      )
      found_default_alias = true
    }
  }
  assert_true(found_default_alias)
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "{\"type\": \"leaf\", \"named\": true}",
    ),
  )
}

///|
test "generate language exposes external lex modes" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "external_mode",
      #|  "rules": {
      #|    "document": { "type": "SYMBOL", "name": "external_token" }
      #|  },
      #|  "externals": [{ "type": "SYMBOL", "name": "external_token" }]
      #|}
    ),
  )
  let validated = @tables.validate(generated.tables)
  assert_eq(validated.external_token_count(), 1)
  assert_eq(validated.external_lex_state_count(), 2)
  assert_true(
    validated.lex_mode(@api.StateId::new(1)) ==
    Some(@tables.GeneratedLexMode::new(external_lex_state=1)),
  )
  assert_true(
    validated.external_lex_state(1) ==
    Some(@tables.GeneratedExternalLexState::new(external_token_ids=[0])),
  )
  let scanner = validated.external_scanner()
  assert_true(scanner.state_enabled(0, 0) == Some(false))
  assert_true(scanner.state_enabled(1, 0) == Some(true))
  assert_true(scanner.symbol_for_external_token(0) == Some(1))
  guard generator_test_source_for_path(
      generated.moonbit_sources,
      "language.mbt",
    )
    is Some(language_source) else {
    fail("language source should be generated")
  }
  assert_true(
    generator_test_string_contains(
      language_source, "pub fn language(scanner : @tables.ExternalScannerDescriptor)",
    ),
  )
  assert_true(
    generator_test_string_contains(
      language_source, "generated_language_tables(external_scanner=scanner)",
    ),
  )
  assert_true(
    validated.primary_state_id(@api.StateId::new(1)) ==
    Some(@api.StateId::new(1)),
  )
}

///|
test "generate language maps paired external scanner symbols to internal token" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "paired_external",
      #|  "rules": {
      #|    "document": { "type": "STRING", "value": "a" }
      #|  },
      #|  "externals": [{ "type": "STRING", "value": "a" }]
      #|}
    ),
  )
  let validated = @tables.validate(generated.tables)
  assert_eq(validated.external_token_count(), 1)
  assert_eq(validated.token_count(), 2)
  assert_true(
    validated.external_lex_state(1) ==
    Some(@tables.GeneratedExternalLexState::new(external_token_ids=[0])),
  )
  let scanner = validated.external_scanner()
  assert_true(scanner.state_enabled(1, 0) == Some(true))
  assert_true(scanner.symbol_for_external_token(0) == Some(1))
}

///|
test "generate language exposes supertype count and symbol type" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "supertypes",
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
  let validated = @tables.validate(generated.tables)
  assert_eq(validated.supertype_count(), 1)
  assert_eq(validated.supertypes().length(), 1)
  let supertype = validated.supertypes()[0]
  assert_true(validated.symbol_name(supertype) == Some("expr"))
  assert_true(
    validated.symbol_type(supertype) == Some(@api.SymbolType::Supertype),
  )
  let subtype_names : Array[String] = []
  for subtype in validated.subtypes(supertype) {
    match validated.symbol_name(subtype) {
      Some(name) => subtype_names.push(name)
      None => fail("subtype should name a public symbol")
    }
  }
  assert_eq(subtype_names.length(), 3)
  assert_true(generator_test_contains_string(subtype_names, "?"))
  assert_true(generator_test_contains_string(subtype_names, "identifier"))
  assert_true(generator_test_contains_string(subtype_names, "literal"))
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"type\": \"expr\", \"named\": true, \"subtypes\"",
    ),
  )
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "{\"type\": \"?\", \"named\": false}",
    ),
  )
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "{\"type\": \"identifier\", \"named\": true}",
    ),
  )
}

///|
test "generate node-types folds subtypes when supertype is also present" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "supertype_fold",
      #|  "rules": {
      #|    "document": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        { "type": "SYMBOL", "name": "expr" },
      #|        { "type": "SYMBOL", "name": "literal" },
      #|        { "type": "SYMBOL", "name": "wrapper" }
      #|      ]
      #|    },
      #|    "wrapper": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        {
      #|          "type": "FIELD",
      #|          "name": "body",
      #|          "content": { "type": "SYMBOL", "name": "expr" }
      #|        },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "body",
      #|          "content": { "type": "SYMBOL", "name": "literal" }
      #|        }
      #|      ]
      #|    },
      #|    "expr": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        { "type": "SYMBOL", "name": "literal" },
      #|        { "type": "SYMBOL", "name": "identifier" }
      #|      ]
      #|    },
      #|    "literal": { "type": "STRING", "value": "a" },
      #|    "identifier": { "type": "STRING", "value": "b" }
      #|  },
      #|  "supertypes": ["expr"]
      #|}
    ),
  )
  generator_test_assert_valid_json(generated.node_types_json)
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"type\": \"document\", \"named\": true, \"root\": true, \"children\": {\"multiple\": true, \"required\": true, \"types\": [{\"type\": \"expr\", \"named\": true}, {\"type\": \"wrapper\", \"named\": true}]}",
    ),
  )
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"fields\": {\"body\": {\"multiple\": true, \"required\": true, \"types\": [{\"type\": \"expr\", \"named\": true}]}}",
    ),
  )
}

///|
test "generate node-types folds nested supertypes in topological order" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "nested_supertype_fold",
      #|  "rules": {
      #|    "document": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        { "type": "SYMBOL", "name": "node" },
      #|        { "type": "SYMBOL", "name": "expr" },
      #|        { "type": "SYMBOL", "name": "literal" },
      #|        { "type": "SYMBOL", "name": "wrapper" }
      #|      ]
      #|    },
      #|    "wrapper": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        {
      #|          "type": "FIELD",
      #|          "name": "body",
      #|          "content": { "type": "SYMBOL", "name": "node" }
      #|        },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "body",
      #|          "content": { "type": "SYMBOL", "name": "expr" }
      #|        },
      #|        {
      #|          "type": "FIELD",
      #|          "name": "body",
      #|          "content": { "type": "SYMBOL", "name": "literal" }
      #|        }
      #|      ]
      #|    },
      #|    "node": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        { "type": "SYMBOL", "name": "expr" },
      #|        { "type": "SYMBOL", "name": "comment" }
      #|      ]
      #|    },
      #|    "expr": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        { "type": "SYMBOL", "name": "literal" },
      #|        { "type": "SYMBOL", "name": "identifier" }
      #|      ]
      #|    },
      #|    "literal": { "type": "STRING", "value": "a" },
      #|    "identifier": { "type": "STRING", "value": "b" },
      #|    "comment": { "type": "STRING", "value": "c" }
      #|  },
      #|  "supertypes": ["expr", "node"]
      #|}
    ),
  )
  generator_test_assert_valid_json(generated.node_types_json)
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"type\": \"document\", \"named\": true, \"root\": true, \"children\": {\"multiple\": true, \"required\": true, \"types\": [{\"type\": \"node\", \"named\": true}, {\"type\": \"wrapper\", \"named\": true}]}",
    ),
  )
  assert_true(
    generator_test_string_contains(
      generated.node_types_json,
      "\"fields\": {\"body\": {\"multiple\": true, \"required\": true, \"types\": [{\"type\": \"node\", \"named\": true}]}}",
    ),
  )
}

///|
test "generate language warns about unsupported regex flags" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "regex_flags",
      #|  "rules": {
      #|    "document": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        { "type": "PATTERN", "value": "[a-z]+", "flags": "iuvx" },
      #|        { "type": "PATTERN", "value": "[0-9]+", "flags": "xy" }
      #|      ]
      #|    }
      #|  },
      #|  "extras": [{ "type": "PATTERN", "value": "\\s+", "flags": "z" }]
      #|}
    ),
  )
  assert_eq(generated.warnings.length(), 3)
  assert_true(
    generated.warnings[0] is GenerateWarning::UnsupportedRegexFlag("x"),
  )
  assert_true(
    generated.warnings[1] is GenerateWarning::UnsupportedRegexFlag("y"),
  )
  assert_true(
    generated.warnings[2] is GenerateWarning::UnsupportedRegexFlag("z"),
  )
}

///|
test "generate language rejects invalid grammar json" {
  let result = @test.expect_error(() => {
    generate_language(
      (
        #|{
        #|  "name": "broken",
        #|  "rules": {
        #|    "document": { "type": "TOKEN", "content": { "type": "SYMBOL", "name": "id" } }
        #|  }
        #|}
      ),
    )
  })
  assert_true(result is GenerateError::InvalidGrammar(_))
}

///|
test "generate language rejects undefined symbols during preparation" {
  let result = @test.expect_error(() => {
    generate_language(
      (
        #|{
        #|  "name": "undefined_symbol",
        #|  "rules": {
        #|    "document": { "type": "SYMBOL", "name": "missing" }
        #|  }
        #|}
      ),
    )
  })
  assert_true(result is GenerateError::UndefinedSymbol("missing"))
}

///|
test "generate language rejects terminal supertypes after token extraction" {
  let result = @test.expect_error(() => {
    generate_language(
      (
        #|{
        #|  "name": "terminal_supertype",
        #|  "rules": {
        #|    "document": { "type": "SYMBOL", "name": "node" },
        #|    "node": { "type": "PATTERN", "value": "[a-z]+" }
        #|  },
        #|  "supertypes": ["node"]
        #|}
      ),
    )
  })
  assert_true(result is GenerateError::TerminalSupertype("node"))
}

///|
test "generate language rejects external tokens that do not resolve to a token" {
  let result = @test.expect_error(() => {
    generate_language(
      (
        #|{
        #|  "name": "invalid_external",
        #|  "rules": {
        #|    "document": { "type": "SYMBOL", "name": "node" },
        #|    "node": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "STRING", "value": "a" },
        #|        { "type": "STRING", "value": "b" }
        #|      ]
        #|    }
        #|  },
        #|  "externals": [{ "type": "SYMBOL", "name": "node" }]
        #|}
      ),
    )
  })
  assert_true(result is GenerateError::InvalidExternalToken("node"))
}

///|
test "generate language validates named precedence declarations" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "precedence_ok",
      #|  "rules": {
      #|    "document": {
      #|      "type": "PREC_LEFT",
      #|      "value": "call",
      #|      "content": { "type": "STRING", "value": "a" }
      #|    }
      #|  },
      #|  "precedences": [["call"]]
      #|}
    ),
  )
  assert_eq(generated.language_name, "precedence_ok")

  let undeclared = @test.expect_error(() => {
    generate_language(
      (
        #|{
        #|  "name": "precedence_bad",
        #|  "rules": {
        #|    "document": {
        #|      "type": "PREC",
        #|      "value": "missing",
        #|      "content": { "type": "STRING", "value": "a" }
        #|    }
        #|  }
        #|}
      ),
    )
  })
  assert_true(undeclared is GenerateError::UndeclaredPrecedence("missing"))
}

///|
test "generate language precedence validation does not descend into reserved rules" {
  let generated = generate_language(
    (
      #|{
      #|  "name": "reserved_precedence",
      #|  "rules": {
      #|    "document": {
      #|      "type": "RESERVED",
      #|      "context_name": "global",
      #|      "content": {
      #|        "type": "PREC",
      #|        "value": "missing",
      #|        "content": { "type": "STRING", "value": "a" }
      #|      }
      #|    }
      #|  },
      #|  "reserved": {
      #|    "global": []
      #|  }
      #|}
    ),
  )
  assert_eq(generated.language_name, "reserved_precedence")
}

///|
test "generate language rejects conflicting precedence ordering" {
  let result = @test.expect_error(() => {
    generate_language(
      (
        #|{
        #|  "name": "precedence_conflict",
        #|  "rules": {
        #|    "document": { "type": "STRING", "value": "a" }
        #|  },
        #|  "precedences": [["a", "b"], ["b", "a"]]
        #|}
      ),
    )
  })
  assert_true(
    result is GenerateError::ConflictingPrecedenceOrdering(left="b", right="a"),
  )
}

///|
test "generate language rejects unresolved conflicting precedence fixture" {
  let result = @test.expect_error(() => {
    generate_language(
      (
        #|{
        #|  "name": "conflicting_precedence",
        #|  "rules": {
        #|    "expression": {
        #|      "type": "CHOICE",
        #|      "members": [
        #|        { "type": "SYMBOL", "name": "sum" },
        #|        { "type": "SYMBOL", "name": "product" },
        #|        { "type": "SYMBOL", "name": "other_thing" }
        #|      ]
        #|    },
        #|    "sum": {
        #|      "type": "PREC_LEFT",
        #|      "value": 0,
        #|      "content": {
        #|        "type": "SEQ",
        #|        "members": [
        #|          { "type": "SYMBOL", "name": "expression" },
        #|          { "type": "STRING", "value": "+" },
        #|          { "type": "SYMBOL", "name": "expression" }
        #|        ]
        #|      }
        #|    },
        #|    "product": {
        #|      "type": "PREC_LEFT",
        #|      "value": 1,
        #|      "content": {
        #|        "type": "SEQ",
        #|        "members": [
        #|          { "type": "SYMBOL", "name": "expression" },
        #|          { "type": "STRING", "value": "*" },
        #|          { "type": "SYMBOL", "name": "expression" }
        #|        ]
        #|      }
        #|    },
        #|    "other_thing": {
        #|      "type": "PREC_LEFT",
        #|      "value": -1,
        #|      "content": {
        #|        "type": "SEQ",
        #|        "members": [
        #|          { "type": "SYMBOL", "name": "expression" },
        #|          { "type": "STRING", "value": "*" },
        #|          { "type": "STRING", "value": "*" }
        #|        ]
        #|      }
        #|    },
        #|    "identifier": { "type": "PATTERN", "value": "[a-zA-Z]+" }
        #|  },
        #|  "extras": [{ "type": "PATTERN", "value": "\\s" }]
        #|}
      ),
    )
  })
  guard result is GenerateError::InvalidGrammar(message) else {
    fail("expected InvalidGrammar")
  }
  assert_true(generator_test_string_contains(message, "unresolved conflict"))
}

///|
test "generate language rejects indirect recursion through single symbols" {
  let result = @test.expect_error(() => {
    generate_language(
      (
        #|{
        #|  "name": "indirect_recursion",
        #|  "rules": {
        #|    "document": { "type": "SYMBOL", "name": "a" },
        #|    "a": { "type": "SYMBOL", "name": "b" },
        #|    "b": { "type": "SYMBOL", "name": "a" }
        #|  }
        #|}
      ),
    )
  })
  assert_true(result is GenerateError::IndirectRecursion("a -> b -> a"))
}

///|
test "generate language treats choice and metadata wrappers as single symbol edges" {
  let result = @test.expect_error(() => {
    generate_language(
      (
        #|{
        #|  "name": "metadata_recursion",
        #|  "rules": {
        #|    "document": {
        #|      "type": "CHOICE",
        #|      "members": [
        #|        {
        #|          "type": "ALIAS",
        #|          "value": "wrapped",
        #|          "named": true,
        #|          "content": { "type": "SYMBOL", "name": "a" }
        #|        },
        #|        { "type": "STRING", "value": "x" }
        #|      ]
        #|    },
        #|    "a": {
        #|      "type": "FIELD",
        #|      "name": "child",
        #|      "content": {
        #|        "type": "PREC_DYNAMIC",
        #|        "value": 1,
        #|        "content": { "type": "SYMBOL", "name": "document" }
        #|      }
        #|    }
        #|  }
        #|}
      ),
    )
  })
  assert_true(
    result is GenerateError::IndirectRecursion("document -> a -> document"),
  )
}

///|
test "generate language rejects unresolved direct self recursion" {
  let result = @test.expect_error(() => {
    generate_language(
      (
        #|{
        #|  "name": "direct_recursion",
        #|  "rules": {
        #|    "document": { "type": "SYMBOL", "name": "document" }
        #|  }
        #|}
      ),
    )
  })
  assert_true(result is GenerateError::InvalidGrammar(_))
}

///|
test "generate language rejects unresolved non single recursion shapes" {
  let result = @test.expect_error(() => {
    generate_language(
      (
        #|{
        #|  "name": "non_single_recursion",
        #|  "rules": {
        #|    "document": {
        #|      "type": "CHOICE",
        #|      "members": [
        #|        { "type": "SYMBOL", "name": "seq_rule" },
        #|        { "type": "SYMBOL", "name": "repeat_rule" },
        #|        { "type": "SYMBOL", "name": "reserved_rule" },
        #|        { "type": "SYMBOL", "name": "token_rule" },
        #|        { "type": "STRING", "value": "x" }
        #|      ]
        #|    },
        #|    "seq_rule": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "SYMBOL", "name": "document" },
        #|        { "type": "STRING", "value": "s" }
        #|      ]
        #|    },
        #|    "repeat_rule": {
        #|      "type": "REPEAT",
        #|      "content": { "type": "SYMBOL", "name": "document" }
        #|    },
        #|    "reserved_rule": {
        #|      "type": "RESERVED",
        #|      "context_name": "global",
        #|      "content": { "type": "SYMBOL", "name": "document" }
        #|    },
        #|    "token_rule": {
        #|      "type": "TOKEN",
        #|      "content": { "type": "STRING", "value": "tok" }
        #|    }
        #|  },
        #|  "reserved": {
        #|    "global": []
        #|  }
        #|}
      ),
    )
  })
  assert_true(result is GenerateError::InvalidGrammar(_))
}
