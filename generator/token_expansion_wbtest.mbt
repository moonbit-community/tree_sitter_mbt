///|
fn token_expansion_fixture(
  variables : Array[LexicalVariable],
  separators : Array[InternedRule],
) -> FlattenedGrammar {
  {
    syntax: {
      name: "token_expansion",
      start_symbol: None,
      variables: [],
      extra_symbols: [],
      external_tokens: [],
      inline_symbols: [],
      conflict_symbols: [],
      precedence_orderings: [],
      word_symbol: None,
      reserved_sets: [],
      supertype_symbols: [],
    },
    lexical: { variables, separators },
  }
}

///|
fn lexical_variable(
  index : Int,
  name : String,
  kind : VariableKind,
  rule : InternedRule,
) -> LexicalVariable {
  { symbol: InternalSymbol::Terminal(index), name, kind, rule }
}

///|
test "expand tokens lowers string and pattern variables to nfas" {
  let grammar = token_expansion_fixture(
    [
      lexical_variable(
        0,
        "if",
        VariableKind::Anonymous,
        InternedRule::IRString("if"),
      ),
      lexical_variable(
        1,
        "identifier",
        VariableKind::Named,
        InternedRule::IRPattern(value="[a-z]+", flags=""),
      ),
    ],
    [],
  )
  let expanded = expand_tokens(grammar)

  assert_eq(expanded.lexical.variables.length(), 2)
  let keyword = expanded.lexical.variables[0]
  assert_true(nfa_matches(keyword.nfa, "if"))
  assert_true(!nfa_matches(keyword.nfa, "i"))
  assert_eq(keyword.implicit_precedence, 2)
  assert_true(keyword.explicit_precedence is None)

  let identifier = expanded.lexical.variables[1]
  assert_true(nfa_matches(identifier.nfa, "abc"))
  assert_true(!nfa_matches(identifier.nfa, "ABC"))
  assert_eq(identifier.implicit_precedence, 0)
}

///|
test "expand tokens carries external token metadata into lexical scaffold" {
  let base = token_expansion_fixture(
    [
      lexical_variable(
        0,
        "paired",
        VariableKind::Named,
        InternedRule::IRString("p"),
      ),
    ],
    [],
  )
  let grammar : FlattenedGrammar = {
    ..base,
    syntax: {
      ..base.syntax,
      external_tokens: [
        {
          symbol: InternalSymbol::External(0),
          name: "scanner_only",
          kind: VariableKind::Named,
          corresponding_internal_token: None,
          rule: InternedRule::IRSymbol(InternalSymbol::External(0)),
        },
        {
          symbol: InternalSymbol::External(1),
          name: "paired",
          kind: VariableKind::Named,
          corresponding_internal_token: Some(InternalSymbol::Terminal(0)),
          rule: InternedRule::IRString("p"),
        },
      ],
    },
  }

  let expanded = expand_tokens(grammar)
  assert_eq(expanded.lexical.external_tokens.length(), 2)
  assert_true(
    expanded.lexical.external_tokens[0].symbol == InternalSymbol::External(0),
  )
  assert_true(
    expanded.lexical.external_tokens[0].corresponding_internal_token is None,
  )
  assert_true(
    expanded.lexical.external_tokens[1].symbol == InternalSymbol::External(1),
  )
  assert_true(
    expanded.lexical.external_tokens[1].corresponding_internal_token ==
    Some(InternalSymbol::Terminal(0)),
  )
}

///|
test "expand tokens applies ascii case insensitive regex flag" {
  let grammar = token_expansion_fixture(
    [
      lexical_variable(
        0,
        "word",
        VariableKind::Named,
        InternedRule::IRPattern(value="abc", flags="i"),
      ),
    ],
    [],
  )
  let expanded = expand_tokens(grammar)

  let word = expanded.lexical.variables[0]
  assert_true(nfa_matches(word.nfa, "abc"))
  assert_true(nfa_matches(word.nfa, "ABC"))
  assert_true(nfa_matches(word.nfa, "aBc"))
}

///|
test "expand tokens handles long s case insensitive regex special case" {
  let grammar = token_expansion_fixture(
    [
      lexical_variable(
        0,
        "plain_s",
        VariableKind::Named,
        InternedRule::IRPattern(value="s", flags="i"),
      ),
      lexical_variable(
        1,
        "explicit_long_s",
        VariableKind::Named,
        InternedRule::IRPattern(value="[s\\u{017F}]", flags="i"),
      ),
    ],
    [],
  )
  let expanded = expand_tokens(grammar)

  let plain_s = expanded.lexical.variables[0]
  assert_true(nfa_matches(plain_s.nfa, "s"))
  assert_true(nfa_matches(plain_s.nfa, "S"))
  assert_true(!nfa_matches(plain_s.nfa, "\u{017F}"))

  let explicit_long_s = expanded.lexical.variables[1]
  assert_true(nfa_matches(explicit_long_s.nfa, "s"))
  assert_true(nfa_matches(explicit_long_s.nfa, "S"))
  assert_true(nfa_matches(explicit_long_s.nfa, "\u{017F}"))
}

///|
test "expand tokens preserves token metadata" {
  let grammar = token_expansion_fixture(
    [
      lexical_variable(
        0,
        "main",
        VariableKind::Named,
        InternedRule::IRToken(InternedRule::IRString("x")),
      ),
      lexical_variable(
        1,
        "immediate",
        VariableKind::Named,
        InternedRule::IRImmediateToken(InternedRule::IRString("y")),
      ),
      lexical_variable(
        2,
        "precise",
        VariableKind::Named,
        InternedRule::IRPrec(
          value=@grammar.PrecedenceValue::Number(5),
          content=InternedRule::IRString("z"),
        ),
      ),
    ],
    [],
  )
  let expanded = expand_tokens(grammar)

  let main = expanded.lexical.variables[0]
  assert_true(main.main_token)
  assert_true(!main.immediate)
  assert_eq(main.implicit_precedence, 3)

  let immediate = expanded.lexical.variables[1]
  assert_true(immediate.main_token)
  assert_true(immediate.immediate)
  assert_eq(immediate.implicit_precedence, 3)

  let precise = expanded.lexical.variables[2]
  assert_true(precise.explicit_precedence == Some(5))
  assert_eq(precise.implicit_precedence, 2)
}

///|
test "expand tokens lowers separator rules" {
  let grammar = token_expansion_fixture([], [
    InternedRule::IRString(" "),
    InternedRule::IRPattern(value="\\s+", flags=""),
  ])
  let expanded = expand_tokens(grammar)

  assert_eq(expanded.lexical.separators.length(), 2)
  assert_true(nfa_matches(expanded.lexical.separators[0], " "))
  assert_true(nfa_matches(expanded.lexical.separators[1], "\n\t"))
}

///|
test "expand tokens reports regex parse failures" {
  let grammar = token_expansion_fixture(
    [
      lexical_variable(
        0,
        "lookahead",
        VariableKind::Named,
        InternedRule::IRPattern(value="(?=a)", flags=""),
      ),
    ],
    [],
  )
  let result = @test.expect_error(() => expand_tokens(grammar))
  guard result is GenerateError::InvalidRegex(message) else {
    fail("regex failure should be reported")
  }
  assert_eq(message, "Unsupported regex assertion at index 0")
}

///|
test "expand tokens rejects structurally empty lexical rules" {
  let grammar = token_expansion_fixture(
    [lexical_variable(0, "blank", VariableKind::Named, InternedRule::IRBlank)],
    [],
  )
  let result = @test.expect_error(() => expand_tokens(grammar))
  guard result is GenerateError::InvalidLexicalToken(message) else {
    fail("empty lexical token should be rejected")
  }
  assert_eq(message, "Lexical token blank can match empty input")
}

///|
test "expand tokens allows nullable regex patterns" {
  let grammar = token_expansion_fixture(
    [
      lexical_variable(
        0,
        "nullable",
        VariableKind::Named,
        InternedRule::IRPattern(value="a*", flags=""),
      ),
    ],
    [],
  )
  let expanded = expand_tokens(grammar)

  assert_true(nfa_matches(expanded.lexical.variables[0].nfa, ""))
  assert_true(nfa_matches(expanded.lexical.variables[0].nfa, "aaa"))
}

///|
test "expand tokens rejects symbol references inside lexical tokens" {
  let grammar = token_expansion_fixture(
    [
      lexical_variable(
        0,
        "bad_token",
        VariableKind::Named,
        InternedRule::IRToken(
          InternedRule::IRSymbol(InternalSymbol::NonTerminal(0)),
        ),
      ),
    ],
    [],
  )
  let result = @test.expect_error(() => expand_tokens(grammar))
  guard result is GenerateError::InvalidLexicalToken(message) else {
    fail("symbol reference should be rejected")
  }
  assert_eq(message, "Lexical token bad_token contains a symbol reference")
}
