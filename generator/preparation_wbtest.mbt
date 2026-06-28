///|
fn production(steps : Array[ProductionStep]) -> FlattenedProduction {
  { steps, dynamic_precedence: 0 }
}

///|
fn step(symbol : InternalSymbol) -> ProductionStep {
  {
    symbol,
    alias_name: None,
    alias_named: false,
    field_name: None,
    precedence: None,
    associativity: Associativity::NoAssociativity,
    reserved_word_set_id: 0,
  }
}

///|
fn alias_step(
  symbol : InternalSymbol,
  alias_name : String,
  alias_named : Bool,
) -> ProductionStep {
  { ..step(symbol), alias_name: Some(alias_name), alias_named }
}

///|
fn prepared_syntax_fixture(
  variables : Array[FlattenedVariable],
  inline_symbols : Array[InternalSymbol],
) -> FlattenedSyntaxGrammar {
  {
    name: "prepared",
    start_symbol: Some(InternalSymbol::NonTerminal(0)),
    variables,
    extra_symbols: [],
    external_tokens: [],
    inline_symbols,
    conflict_symbols: [],
    precedence_orderings: [],
    word_symbol: None,
    reserved_sets: [],
    supertype_symbols: [],
  }
}

///|
fn expanded_lexical_fixture(count : Int) -> ExpandedLexicalGrammar {
  let variables : Array[ExpandedLexicalVariable] = []
  for i in 0..<count {
    variables.push({
      symbol: InternalSymbol::Terminal(i),
      name: "t\{i}",
      kind: VariableKind::Anonymous,
      nfa: regex_ast_to_nfa(RegexAst::RegexEmpty),
      immediate: false,
      explicit_precedence: None,
      implicit_precedence: 0,
      main_token: false,
      literal: None,
    })
  }
  { variables, separators: [], external_tokens: [] }
}

///|
fn alias_extracted_fixture(
  syntax : FlattenedSyntaxGrammar,
  lexical : ExpandedLexicalGrammar,
) -> AliasExtractedGrammar {
  { syntax, lexical, default_aliases: [] }
}

///|
fn find_default_alias(
  aliases : Array[DefaultAlias],
  symbol : InternalSymbol,
) -> DefaultAlias? {
  for default_alias in aliases {
    if default_alias.symbol == symbol {
      return Some(default_alias)
    }
  }
  None
}

///|
fn inlined_entry_for(
  map : InlinedProductionMap,
  source : InlinedProductionSource,
  step_index : Int,
) -> Array[FlattenedProduction]? {
  for entry in map.entries {
    if entry.source == source && entry.step_index == step_index {
      let productions : Array[FlattenedProduction] = []
      for index in entry.production_indices {
        productions.push(map.productions[index])
      }
      return Some(productions)
    }
  }
  None
}

///|
test "extract default aliases promotes most common alias and clears redundant steps" {
  let syntax = prepared_syntax_fixture(
    [
      {
        symbol: InternalSymbol::NonTerminal(0),
        name: "v1",
        kind: VariableKind::Named,
        productions: [
          production([
            alias_step(InternalSymbol::Terminal(0), "a1", true),
            alias_step(InternalSymbol::Terminal(1), "a2", true),
            alias_step(InternalSymbol::Terminal(2), "a3", true),
            alias_step(InternalSymbol::Terminal(3), "a4", true),
          ]),
        ],
      },
      {
        symbol: InternalSymbol::NonTerminal(1),
        name: "v2",
        kind: VariableKind::Named,
        productions: [
          production([
            alias_step(InternalSymbol::Terminal(0), "a1", true),
            step(InternalSymbol::Terminal(1)),
            alias_step(InternalSymbol::Terminal(2), "a5", true),
            alias_step(InternalSymbol::Terminal(3), "a6", true),
            alias_step(InternalSymbol::Terminal(3), "a6", true),
          ]),
        ],
      },
    ],
    [],
  )
  let grammar : TokenExpandedGrammar = {
    syntax,
    lexical: expanded_lexical_fixture(4),
  }
  let aliased = extract_default_aliases(grammar)

  assert_eq(aliased.default_aliases.length(), 3)
  guard find_default_alias(aliased.default_aliases, InternalSymbol::Terminal(0))
    is Some(alias0) else {
    fail("terminal 0 should have a default alias")
  }
  assert_eq(alias0.value, "a1")
  guard find_default_alias(aliased.default_aliases, InternalSymbol::Terminal(2))
    is Some(alias2) else {
    fail("terminal 2 should have a default alias")
  }
  assert_eq(alias2.value, "a3")
  guard find_default_alias(aliased.default_aliases, InternalSymbol::Terminal(3))
    is Some(alias3) else {
    fail("terminal 3 should have a default alias")
  }
  assert_eq(alias3.value, "a6")
  assert_true(
    find_default_alias(aliased.default_aliases, InternalSymbol::Terminal(1))
    is None,
  )

  let v1 = aliased.syntax.variables[0].productions[0].steps
  assert_true(v1[0].alias_name is None)
  assert_true(v1[1].alias_name == Some("a2"))
  assert_true(v1[2].alias_name is None)
  assert_true(v1[3].alias_name == Some("a4"))
  let v2 = aliased.syntax.variables[1].productions[0].steps
  assert_true(v2[0].alias_name is None)
  assert_true(v2[1].alias_name is None)
  assert_true(v2[2].alias_name == Some("a5"))
  assert_true(v2[3].alias_name is None)
  assert_true(v2[4].alias_name is None)
}

///|
test "process inlines expands basic inline productions" {
  let syntax = prepared_syntax_fixture(
    [
      {
        symbol: InternalSymbol::NonTerminal(0),
        name: "document",
        kind: VariableKind::Named,
        productions: [
          production([
            step(InternalSymbol::Terminal(10)),
            step(InternalSymbol::NonTerminal(1)),
            step(InternalSymbol::Terminal(11)),
          ]),
        ],
      },
      {
        symbol: InternalSymbol::NonTerminal(1),
        name: "_item",
        kind: VariableKind::Hidden,
        productions: [
          production([
            step(InternalSymbol::Terminal(12)),
            step(InternalSymbol::Terminal(13)),
          ]),
          {
            steps: [step(InternalSymbol::Terminal(14))],
            dynamic_precedence: -2,
          },
        ],
      },
    ],
    [InternalSymbol::NonTerminal(1)],
  )
  let prepared = process_inlines(
    alias_extracted_fixture(syntax, expanded_lexical_fixture(0)),
  )

  guard inlined_entry_for(
      prepared.inlines,
      InlinedProductionSource::GrammarProduction(
        variable_index=0,
        production_index=0,
      ),
      1,
    )
    is Some(productions) else {
    fail("inline entry should exist")
  }
  assert_eq(productions.length(), 2)
  assert_true(
    same_production(
      productions[0],
      production([
        step(InternalSymbol::Terminal(10)),
        step(InternalSymbol::Terminal(12)),
        step(InternalSymbol::Terminal(13)),
        step(InternalSymbol::Terminal(11)),
      ]),
    ),
  )
  assert_true(
    same_production(productions[1], {
      steps: [
        step(InternalSymbol::Terminal(10)),
        step(InternalSymbol::Terminal(14)),
        step(InternalSymbol::Terminal(11)),
      ],
      dynamic_precedence: -2,
    }),
  )
}

///|
test "process inlines propagates alias field and tail precedence" {
  let outer_step = {
    ..alias_step(InternalSymbol::NonTerminal(1), "outer_alias", true),
    field_name: Some("outer_field"),
    precedence: Some(@grammar.PrecedenceValue::Number(1)),
    associativity: Associativity::Left,
  }
  let syntax = prepared_syntax_fixture(
    [
      {
        symbol: InternalSymbol::NonTerminal(0),
        name: "document",
        kind: VariableKind::Named,
        productions: [production([outer_step])],
      },
      {
        symbol: InternalSymbol::NonTerminal(1),
        name: "_item",
        kind: VariableKind::Hidden,
        productions: [
          production([
            alias_step(InternalSymbol::Terminal(1), "inner_alias", true),
            step(InternalSymbol::Terminal(2)),
          ]),
        ],
      },
    ],
    [InternalSymbol::NonTerminal(1)],
  )
  let prepared = process_inlines(
    alias_extracted_fixture(syntax, expanded_lexical_fixture(0)),
  )

  guard inlined_entry_for(
      prepared.inlines,
      InlinedProductionSource::GrammarProduction(
        variable_index=0,
        production_index=0,
      ),
      0,
    )
    is Some(productions) else {
    fail("inline entry should exist")
  }
  let steps = productions[0].steps
  assert_true(steps[0].alias_name == Some("outer_alias"))
  assert_true(steps[0].field_name == Some("outer_field"))
  assert_true(steps[0].precedence is None)
  assert_true(steps[1].alias_name == Some("outer_alias"))
  assert_true(steps[1].field_name == Some("outer_field"))
  assert_true(steps[1].precedence == Some(@grammar.PrecedenceValue::Number(1)))
  assert_true(steps[1].associativity is Associativity::Left)
}

///|
test "process inlines rejects terminals and the start rule" {
  let terminal_inline = prepared_syntax_fixture([], [
    InternalSymbol::Terminal(0),
  ])
  let terminal_result = @test.expect_error(() => {
    process_inlines(
      alias_extracted_fixture(terminal_inline, expanded_lexical_fixture(1)),
    )
  })
  guard terminal_result is GenerateError::InvalidInline(message) else {
    fail("terminal inline should fail")
  }
  assert_eq(message, "Token `t0` cannot be inlined")

  let start_inline = prepared_syntax_fixture(
    [
      {
        symbol: InternalSymbol::NonTerminal(0),
        name: "document",
        kind: VariableKind::Named,
        productions: [],
      },
    ],
    [InternalSymbol::NonTerminal(0)],
  )
  let start_result = @test.expect_error(() => {
    process_inlines(
      alias_extracted_fixture(start_inline, expanded_lexical_fixture(0)),
    )
  })
  guard start_result is GenerateError::InvalidInline(start_message) else {
    fail("start inline should fail")
  }
  assert_eq(
    start_message, "Rule `document` cannot be inlined because it is the first rule",
  )
}
