///|
fn parse_analysis_step(
  symbol : InternalSymbol,
  reserved? : Int = 0,
) -> ProductionStep {
  {
    symbol,
    alias_name: None,
    alias_named: false,
    field_name: None,
    precedence: None,
    associativity: Associativity::NoAssociativity,
    reserved_word_set_id: reserved,
  }
}

///|
fn parse_analysis_production(
  steps : Array[ProductionStep],
) -> FlattenedProduction {
  { steps, dynamic_precedence: 0 }
}

///|
fn parse_analysis_variable(
  index : Int,
  productions : Array[FlattenedProduction],
) -> FlattenedVariable {
  {
    symbol: InternalSymbol::NonTerminal(index),
    name: "v\{index}",
    kind: VariableKind::Named,
    productions,
  }
}

///|
fn parse_analysis_external_token(index : Int) -> ExtractedExternalToken {
  {
    symbol: InternalSymbol::External(index),
    name: "external\{index}",
    kind: VariableKind::Named,
    corresponding_internal_token: None,
    rule: InternedRule::IRSymbol(InternalSymbol::External(index)),
  }
}

///|
fn parse_analysis_lexical_variable(index : Int) -> ExpandedLexicalVariable {
  {
    symbol: InternalSymbol::Terminal(index),
    name: "terminal\{index}",
    kind: VariableKind::Anonymous,
    nfa: { states: [NfaState::NfaAccept(index, 0)], start: 0 },
    immediate: false,
    explicit_precedence: None,
    implicit_precedence: 0,
    main_token: true,
    literal: None,
  }
}

///|
fn parse_analysis_prepared(
  variables : Array[FlattenedVariable],
  external_count? : Int = 0,
  terminal_count? : Int = 0,
  extra_symbols? : Array[InternalSymbol] = [],
  inline_symbols? : Array[InternalSymbol] = [],
  word_symbol? : InternalSymbol,
  reserved_sets? : Array[ExtractedReservedSet] = [],
  inlines? : InlinedProductionMap = { productions: [], entries: [] },
) -> PreparedGrammar {
  let external_tokens : Array[ExtractedExternalToken] = []
  for i in 0..<external_count {
    external_tokens.push(parse_analysis_external_token(i))
  }
  let lexical_variables : Array[ExpandedLexicalVariable] = []
  for i in 0..<terminal_count {
    lexical_variables.push(parse_analysis_lexical_variable(i))
  }
  {
    syntax: {
      name: "parse_analysis",
      start_symbol: Some(InternalSymbol::NonTerminal(0)),
      variables,
      extra_symbols,
      external_tokens,
      inline_symbols,
      conflict_symbols: [],
      precedence_orderings: [],
      word_symbol,
      reserved_sets,
      supertype_symbols: [],
    },
    lexical: {
      variables: lexical_variables,
      separators: [],
      external_tokens: [],
    },
    default_aliases: [],
    inlines,
  }
}

///|
fn parse_analysis_token_set(
  terminals : Array[Int],
  externals : Array[Int],
) -> ParseTokenSet {
  let set = parse_token_set_empty()
  for terminal in terminals {
    parse_token_set_insert_symbol(set, InternalSymbol::Terminal(terminal))
  }
  for external_token in externals {
    parse_token_set_insert_symbol(set, InternalSymbol::External(external_token))
  }
  set
}

///|
test "parse symbol sets compute transitive first last and reserved first sets" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::NonTerminal(1), reserved=1),
          parse_analysis_step(InternalSymbol::Terminal(2)),
        ]),
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::External(0)),
        ]),
      ]),
      parse_analysis_variable(1, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0), reserved=2),
        ]),
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::NonTerminal(2)),
        ]),
      ]),
      parse_analysis_variable(2, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(1), reserved=3),
        ]),
      ]),
    ],
    external_count=1,
  )
  let sets = build_parse_symbol_sets(grammar)

  assert_true(
    parse_token_set_same(
      parse_symbol_first_set(sets, InternalSymbol::NonTerminal(0)),
      parse_analysis_token_set([0, 1], [0]),
    ),
  )
  assert_true(
    parse_token_set_same(
      parse_symbol_last_set(sets, InternalSymbol::NonTerminal(0)),
      parse_analysis_token_set([2], [0]),
    ),
  )
  assert_eq(
    parse_symbol_reserved_first_set(sets, InternalSymbol::NonTerminal(0)),
    3,
  )
}

///|
test "parse symbol sets expose singleton first and last sets for tokens" {
  let sets = build_parse_symbol_sets(parse_analysis_prepared([]))
  assert_true(
    parse_token_set_same(
      parse_symbol_first_set(sets, InternalSymbol::Terminal(4)),
      parse_analysis_token_set([4], []),
    ),
  )
  assert_true(
    parse_token_set_same(
      parse_symbol_last_set(sets, InternalSymbol::External(2)),
      parse_analysis_token_set([], [2]),
    ),
  )
  assert_eq(
    parse_symbol_reserved_first_set(sets, InternalSymbol::Terminal(4)),
    0,
  )
}

///|
test "parse symbol sets mirror upstream first step behavior for nullable rules" {
  let grammar = parse_analysis_prepared([
    parse_analysis_variable(0, [
      parse_analysis_production([
        parse_analysis_step(InternalSymbol::NonTerminal(1)),
        parse_analysis_step(InternalSymbol::Terminal(1)),
      ]),
    ]),
    parse_analysis_variable(1, [
      parse_analysis_production([]),
      parse_analysis_production([
        parse_analysis_step(InternalSymbol::Terminal(0)),
      ]),
    ]),
  ])
  let sets = build_parse_symbol_sets(grammar)

  assert_true(
    parse_token_set_same(
      parse_symbol_first_set(sets, InternalSymbol::NonTerminal(0)),
      parse_analysis_token_set([0], []),
    ),
  )
  assert_true(
    !parse_token_set_contains_symbol(
      parse_symbol_first_set(sets, InternalSymbol::NonTerminal(0)),
      InternalSymbol::Terminal(1),
    ),
  )
  assert_true(
    parse_token_set_same(
      parse_symbol_last_set(sets, InternalSymbol::NonTerminal(0)),
      parse_analysis_token_set([1], []),
    ),
  )
}

///|
test "following token sets use adjacent last and first terminal sets" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::NonTerminal(1)),
          parse_analysis_step(InternalSymbol::NonTerminal(2)),
          parse_analysis_step(InternalSymbol::External(0)),
          parse_analysis_step(InternalSymbol::Terminal(3)),
        ]),
      ]),
      parse_analysis_variable(1, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(1)),
        ]),
      ]),
      parse_analysis_variable(2, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(2)),
        ]),
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::External(0)),
        ]),
      ]),
    ],
    external_count=1,
    terminal_count=4,
  )
  let symbol_sets = build_parse_symbol_sets(grammar)
  let following = build_following_token_sets(grammar, symbol_sets)

  assert_true(
    parse_token_set_same(following[0], parse_analysis_token_set([2], [])),
  )
  assert_true(
    parse_token_set_same(following[1], parse_analysis_token_set([2], [])),
  )
  assert_true(
    parse_token_set_same(following[2], parse_analysis_token_set([], [])),
  )
}

///|
test "following token sets include inline productions" {
  let inline_production = parse_analysis_production([
    parse_analysis_step(InternalSymbol::Terminal(2)),
    parse_analysis_step(InternalSymbol::Terminal(3)),
  ])
  let grammar = parse_analysis_prepared([], terminal_count=4, inlines={
    productions: [inline_production],
    entries: [],
  })
  let symbol_sets = build_parse_symbol_sets(grammar)
  let following = build_following_token_sets(grammar, symbol_sets)

  assert_true(
    parse_token_set_same(following[2], parse_analysis_token_set([3], [])),
  )
}

///|
test "following token sets add terminal extras to every entry" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
          parse_analysis_step(InternalSymbol::Terminal(1)),
        ]),
      ]),
    ],
    terminal_count=5,
    extra_symbols=[InternalSymbol::Terminal(4)],
  )
  let symbol_sets = build_parse_symbol_sets(grammar)
  let following = build_following_token_sets(grammar, symbol_sets)

  assert_true(
    parse_token_set_same(following[0], parse_analysis_token_set([1, 4], [])),
  )
  assert_true(
    parse_token_set_same(
      following[4],
      parse_analysis_token_set([0, 1, 2, 3, 4], []),
    ),
  )
}

///|
test "following token sets add reserved first set terminals" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
          parse_analysis_step(InternalSymbol::NonTerminal(1)),
        ]),
      ]),
      parse_analysis_variable(1, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(1), reserved=1),
        ]),
      ]),
    ],
    terminal_count=5,
    reserved_sets=[
      { name: "", rules: [] },
      {
        name: "keyword",
        rules: [InternedRule::IRSymbol(InternalSymbol::Terminal(4))],
      },
    ],
  )
  let symbol_sets = build_parse_symbol_sets(grammar)
  let following = build_following_token_sets(grammar, symbol_sets)

  assert_true(
    parse_token_set_same(following[0], parse_analysis_token_set([1, 4], [])),
  )
}
