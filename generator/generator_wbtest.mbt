///|
fn intern_fixture_json() -> String {
  (
    #|{
    #|  "name": "intern_fixture",
    #|  "rules": {
    #|    "document": {
    #|      "type": "SEQ",
    #|      "members": [
    #|        { "type": "SYMBOL", "name": "_helper" },
    #|        { "type": "SYMBOL", "name": "external_token" }
    #|      ]
    #|    },
    #|    "_helper": { "type": "STRING", "value": "h" }
    #|  },
    #|  "extras": [{ "type": "SYMBOL", "name": "external_token" }],
    #|  "externals": [{ "type": "SYMBOL", "name": "external_token" }],
    #|  "inline": ["_helper"],
    #|  "conflicts": [["document", "_helper"]],
    #|  "word": "_helper",
    #|  "reserved": {
    #|    "global": [{ "type": "SYMBOL", "name": "_helper" }]
    #|  },
    #|  "supertypes": ["document"]
    #|}
  )
}

///|
fn extract_fixture_json() -> String {
  (
    #|{
    #|  "name": "extract_fixture",
    #|  "rules": {
    #|    "document": {
    #|      "type": "SEQ",
    #|      "members": [
    #|        { "type": "STRING", "value": "a" },
    #|        { "type": "SYMBOL", "name": "identifier" },
    #|        { "type": "SYMBOL", "name": "external_token" }
    #|      ]
    #|    },
    #|    "identifier": { "type": "PATTERN", "value": "[a-z]+" },
    #|    "external_token": { "type": "STRING", "value": "x" }
    #|  },
    #|  "externals": [
    #|    { "type": "SYMBOL", "name": "external_token" },
    #|    { "type": "STRING", "value": "a" }
    #|  ]
    #|}
  )
}

///|
fn extract_extras_fixture_json() -> String {
  (
    #|{
    #|  "name": "extract_extras_fixture",
    #|  "rules": {
    #|    "document": { "type": "STRING", "value": "a" }
    #|  },
    #|  "extras": [
    #|    { "type": "STRING", "value": " " },
    #|    { "type": "STRING", "value": "a" }
    #|  ]
    #|}
  )
}

///|
fn repeat_fixture_json() -> String {
  (
    #|{
    #|  "name": "repeat_fixture",
    #|  "rules": {
    #|    "document": {
    #|      "type": "SEQ",
    #|      "members": [
    #|        { "type": "REPEAT", "content": { "type": "SYMBOL", "name": "item" } },
    #|        { "type": "REPEAT", "content": { "type": "SYMBOL", "name": "item" } }
    #|      ]
    #|    },
    #|    "item": { "type": "STRING", "value": "x" }
    #|  }
    #|}
  )
}

///|
test "intern symbols preserves order and rewrites symbol references" {
  let grammar = @grammar.parse_grammar(intern_fixture_json())

  let interned = intern_symbols(grammar)

  assert_true(interned.start_symbol == Some(InternalSymbol::NonTerminal(0)))
  assert_eq(interned.variables.length(), 2)
  assert_eq(interned.variables[0].name, "document")
  assert_true(interned.variables[0].symbol == InternalSymbol::NonTerminal(0))
  assert_true(interned.variables[0].kind is VariableKind::Hidden)
  assert_eq(interned.variables[1].name, "_helper")
  assert_true(interned.variables[1].symbol == InternalSymbol::NonTerminal(1))
  assert_true(interned.variables[1].kind is VariableKind::Hidden)

  guard interned.variables[0].rule is InternedRule::IRSeq(members) else {
    fail("document should intern as a sequence")
  }
  assert_true(
    members[0] == InternedRule::IRSymbol(InternalSymbol::NonTerminal(1)),
  )
  assert_true(members[1] == InternedRule::IRSymbol(InternalSymbol::External(0)))

  assert_true(
    interned.extras[0] == InternedRule::IRSymbol(InternalSymbol::External(0)),
  )
  assert_eq(interned.external_tokens.length(), 1)
  assert_eq(interned.external_tokens[0].name, "external_token")
  assert_true(interned.external_tokens[0].symbol == InternalSymbol::External(0))
  assert_true(
    interned.external_tokens[0].rule ==
    InternedRule::IRSymbol(InternalSymbol::External(0)),
  )
}

///|
test "extract tokens preserves lexical order, dedupes rules, and rewrites syntax" {
  let grammar = @grammar.parse_grammar(extract_fixture_json())

  let extracted = extract_tokens(intern_symbols(grammar))

  assert_eq(extracted.lexical.variables.length(), 3)
  assert_eq(extracted.lexical.variables[0].name, "a")
  assert_true(extracted.lexical.variables[0].kind is VariableKind::Anonymous)
  assert_true(
    extracted.lexical.variables[0].rule == InternedRule::IRString("a"),
  )
  assert_eq(extracted.lexical.variables[1].name, "identifier")
  assert_true(extracted.lexical.variables[1].kind is VariableKind::Named)
  assert_true(
    extracted.lexical.variables[1].rule ==
    InternedRule::IRPattern(value="[a-z]+", flags=""),
  )
  assert_eq(extracted.lexical.variables[2].name, "external_token")
  assert_true(
    extracted.lexical.variables[2].rule == InternedRule::IRString("x"),
  )

  assert_eq(extracted.syntax.variables.length(), 1)
  guard extracted.syntax.variables[0].rule is InternedRule::IRSeq(members) else {
    fail("document should remain a syntax sequence")
  }
  assert_true(members[0] == InternedRule::IRSymbol(InternalSymbol::Terminal(0)))
  assert_true(members[1] == InternedRule::IRSymbol(InternalSymbol::Terminal(1)))
  assert_true(members[2] == InternedRule::IRSymbol(InternalSymbol::Terminal(2)))

  assert_eq(extracted.syntax.external_tokens.length(), 2)
  assert_eq(extracted.syntax.external_tokens[0].name, "external_token")
  assert_true(
    extracted.syntax.external_tokens[0].corresponding_internal_token ==
    Some(InternalSymbol::Terminal(2)),
  )
  assert_eq(extracted.syntax.external_tokens[1].name, "_external_token1")
  assert_true(
    extracted.syntax.external_tokens[1].corresponding_internal_token ==
    Some(InternalSymbol::Terminal(0)),
  )
}

///|
test "extract tokens routes extras to symbols or separators" {
  let grammar = @grammar.parse_grammar(extract_extras_fixture_json())

  let extracted = extract_tokens(intern_symbols(grammar))

  assert_true(extracted.syntax.extra_symbols == [InternalSymbol::Terminal(0)])
  assert_true(extracted.lexical.separators == [InternedRule::IRString(" ")])
}

///|
test "expand repeats creates and reuses auxiliary repeat variables" {
  let grammar = @grammar.parse_grammar(repeat_fixture_json())

  let expanded = expand_repeats(extract_tokens(intern_symbols(grammar)))

  assert_eq(expanded.syntax.variables.length(), 2)
  guard expanded.syntax.variables[0].rule is InternedRule::IRSeq(members) else {
    fail("document should remain a sequence")
  }
  assert_true(
    members[0] ==
    InternedRule::IRChoice([
      InternedRule::IRSymbol(InternalSymbol::NonTerminal(1)),
      InternedRule::IRBlank,
    ]),
  )
  assert_true(members[1] == members[0])
  assert_eq(expanded.syntax.variables[1].name, "document_repeat1")
  assert_true(expanded.syntax.variables[1].kind is VariableKind::Auxiliary)
  assert_true(
    expanded.syntax.variables[1].symbol == InternalSymbol::NonTerminal(1),
  )
  assert_true(
    expanded.syntax.variables[1].rule ==
    InternedRule::IRChoice([
      InternedRule::IRSeq([
        InternedRule::IRSymbol(InternalSymbol::NonTerminal(1)),
        InternedRule::IRSymbol(InternalSymbol::NonTerminal(1)),
      ]),
      InternedRule::IRSymbol(InternalSymbol::Terminal(0)),
    ]),
  )
}

///|
test "expand repeats rewrites hidden top level repeat in place" {
  let extracted : ExtractedGrammar = {
    syntax: {
      name: "hidden_repeat",
      start_symbol: Some(InternalSymbol::NonTerminal(0)),
      variables: [
        {
          symbol: InternalSymbol::NonTerminal(0),
          name: "document",
          kind: VariableKind::Named,
          rule: InternedRule::IRSymbol(InternalSymbol::NonTerminal(1)),
        },
        {
          symbol: InternalSymbol::NonTerminal(1),
          name: "_items",
          kind: VariableKind::Hidden,
          rule: InternedRule::IRRepeat(
            InternedRule::IRSymbol(InternalSymbol::Terminal(0)),
          ),
        },
      ],
      extra_symbols: [],
      external_tokens: [],
      inline_symbols: [InternalSymbol::NonTerminal(1)],
      conflict_symbols: [],
      precedence_orderings: [],
      word_symbol: None,
      reserved_sets: [],
      supertype_symbols: [],
    },
    lexical: {
      variables: [
        {
          symbol: InternalSymbol::Terminal(0),
          name: "item",
          kind: VariableKind::Named,
          rule: InternedRule::IRString("x"),
        },
      ],
      separators: [],
    },
  }
  let expanded = expand_repeats(extracted)

  assert_eq(expanded.syntax.variables.length(), 2)
  assert_true(expanded.syntax.inline_symbols.length() == 0)
  assert_true(expanded.syntax.variables[1].kind is VariableKind::Auxiliary)
  assert_true(
    expanded.syntax.variables[1].rule ==
    InternedRule::IRChoice([
      InternedRule::IRSeq([
        InternedRule::IRSymbol(InternalSymbol::NonTerminal(1)),
        InternedRule::IRSymbol(InternalSymbol::NonTerminal(1)),
      ]),
      InternedRule::IRSymbol(InternalSymbol::Terminal(0)),
    ]),
  )
}

///|
test "flatten grammar cross-products choices and dedupes productions" {
  let extracted : ExtractedGrammar = {
    syntax: {
      name: "flatten_cross_product",
      start_symbol: Some(InternalSymbol::NonTerminal(0)),
      variables: [
        {
          symbol: InternalSymbol::NonTerminal(0),
          name: "document",
          kind: VariableKind::Named,
          rule: InternedRule::IRSeq([
            InternedRule::IRChoice([
              InternedRule::IRSymbol(InternalSymbol::Terminal(0)),
              InternedRule::IRSymbol(InternalSymbol::Terminal(1)),
            ]),
            InternedRule::IRChoice([
              InternedRule::IRSymbol(InternalSymbol::Terminal(2)),
              InternedRule::IRSymbol(InternalSymbol::Terminal(2)),
            ]),
          ]),
        },
      ],
      extra_symbols: [],
      external_tokens: [],
      inline_symbols: [],
      conflict_symbols: [],
      precedence_orderings: [],
      word_symbol: None,
      reserved_sets: [],
      supertype_symbols: [],
    },
    lexical: { variables: [], separators: [] },
  }
  let flattened = flatten_grammar(extracted)

  assert_eq(flattened.syntax.variables.length(), 1)
  let productions = flattened.syntax.variables[0].productions
  assert_eq(productions.length(), 2)
  assert_eq(productions[0].steps.length(), 2)
  assert_true(productions[0].steps[0].symbol == InternalSymbol::Terminal(0))
  assert_true(productions[0].steps[1].symbol == InternalSymbol::Terminal(2))
  assert_eq(productions[1].steps.length(), 2)
  assert_true(productions[1].steps[0].symbol == InternalSymbol::Terminal(1))
  assert_true(productions[1].steps[1].symbol == InternalSymbol::Terminal(2))
}

///|
test "flatten grammar propagates metadata and rolls back non-final precedence" {
  let extracted : ExtractedGrammar = {
    syntax: {
      name: "flatten_metadata",
      start_symbol: Some(InternalSymbol::NonTerminal(0)),
      variables: [
        {
          symbol: InternalSymbol::NonTerminal(0),
          name: "document",
          kind: VariableKind::Named,
          rule: InternedRule::IRPrecDynamic(
            value=5,
            content=InternedRule::IRSeq([
              InternedRule::IRField(
                name="left",
                content=InternedRule::IRReserved(
                  context_name="global",
                  content=InternedRule::IRPrecLeft(
                    value=@grammar.PrecedenceValue::Name("p"),
                    content=InternedRule::IRSymbol(InternalSymbol::Terminal(0)),
                  ),
                ),
              ),
              InternedRule::IRPrecRight(
                value=@grammar.PrecedenceValue::Number(2),
                content=InternedRule::IRSymbol(InternalSymbol::Terminal(1)),
              ),
            ]),
          ),
        },
      ],
      extra_symbols: [],
      external_tokens: [],
      inline_symbols: [],
      conflict_symbols: [],
      precedence_orderings: [],
      word_symbol: None,
      reserved_sets: [{ name: "", rules: [] }, { name: "global", rules: [] }],
      supertype_symbols: [],
    },
    lexical: { variables: [], separators: [] },
  }
  let flattened = flatten_grammar(extracted)

  let production = flattened.syntax.variables[0].productions[0]
  assert_eq(production.dynamic_precedence, 5)
  assert_eq(production.steps.length(), 2)
  assert_true(production.steps[0].field_name == Some("left"))
  assert_eq(production.steps[0].reserved_word_set_id, 1)
  assert_true(production.steps[0].precedence is None)
  assert_true(
    production.steps[0].associativity is Associativity::NoAssociativity,
  )
  assert_true(
    production.steps[1].precedence == Some(@grammar.PrecedenceValue::Number(2)),
  )
  assert_true(production.steps[1].associativity is Associativity::Right)
}

///|
test "intern symbols rewrites metadata symbol lists" {
  let grammar = @grammar.parse_grammar(intern_fixture_json())

  let interned = intern_symbols(grammar)

  assert_true(interned.inline_symbols == [InternalSymbol::NonTerminal(1)])
  assert_true(
    interned.conflict_symbols ==
    [[InternalSymbol::NonTerminal(0), InternalSymbol::NonTerminal(1)]],
  )
  assert_true(interned.word_symbol == Some(InternalSymbol::NonTerminal(1)))
  assert_true(interned.supertype_symbols == [InternalSymbol::NonTerminal(0)])
  assert_eq(interned.reserved_sets.length(), 1)
  assert_eq(interned.reserved_sets[0].name, "global")
  assert_true(
    interned.reserved_sets[0].rules[0] ==
    InternedRule::IRSymbol(InternalSymbol::NonTerminal(1)),
  )
}

///|
test "generated tables include reserved word set rows from parse draft" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(2), reserved=1),
        ]),
      ]),
    ],
    terminal_count=3,
    word_symbol=InternalSymbol::Terminal(2),
    reserved_sets=[
      { name: "", rules: [] },
      {
        name: "keyword",
        rules: [InternedRule::IRSymbol(InternalSymbol::Terminal(1))],
      },
    ],
  )
  let draft = parse_table_draft_for(grammar)
  let tables = generated_language_tables_from_draft(
    "reserved_rows",
    @tables.target_abi_version(),
    @tables.LanguageMetadata::zero(),
    grammar,
    draft,
  )
  let validated = @tables.validate(tables)

  assert_eq(validated.reserved_word_set_count(), 2)
  assert_eq(validated.max_reserved_word_set_size(), 1)
  assert_true(
    validated.lex_mode(@api.StateId::new(1)) ==
    Some(@tables.GeneratedLexMode::new(lex_state=0, reserved_word_set_id=1)),
  )
  assert_true(
    validated.reserved_word_set(1) ==
    Some(@tables.GeneratedTokenSet::new(symbol_ids=[2])),
  )
  assert_true(validated.keyword_capture_token() == Some(@api.SymbolId::new(1)))
  guard validated.keyword_lex_table() is Some(keyword_table) else {
    fail("reserved word candidates should produce a keyword lex table")
  }
  assert_true(keyword_table.states.length() > 0)
}
