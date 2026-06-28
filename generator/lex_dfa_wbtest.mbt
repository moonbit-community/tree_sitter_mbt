///|
fn lex_dfa_step(dfa : LexDfa, state_id : Int, char : Char) -> Int? {
  if state_id < 0 || state_id >= dfa.states.length() {
    return None
  }
  for transition in dfa.states[state_id].transitions {
    if character_set_contains(transition.characters, char.to_uint()) {
      return Some(transition.target_state)
    }
  }
  None
}

///|
fn lex_dfa_accept_variable(dfa : LexDfa, state_id : Int) -> Int? {
  if state_id < 0 || state_id >= dfa.states.length() {
    return None
  }
  match dfa.states[state_id].accept {
    Some(accept) => Some(accept.variable_index)
    None => None
  }
}

///|
fn expanded_lexical_from_rules(
  variables : Array[LexicalVariable],
  separators : Array[InternedRule],
) -> Result[ExpandedLexicalGrammar, GenerateError] {
  try expand_tokens(token_expansion_fixture(variables, separators)) catch {
    error => Err(error)
  } noraise {
    expanded => Ok(expanded.lexical)
  }
}

///|
test "lex dfa keeps continuation after a shorter completed token" {
  let result = expanded_lexical_from_rules(
    [
      lexical_variable(
        0,
        "a",
        VariableKind::Anonymous,
        InternedRule::IRString("a"),
      ),
      lexical_variable(
        1,
        "ab",
        VariableKind::Anonymous,
        InternedRule::IRString("ab"),
      ),
    ],
    [],
  )
  guard result is Ok(lexical) else { fail("token expansion should succeed") }
  let dfa = build_lex_dfa(lexical, lex_token_set([0, 1]))

  guard lex_dfa_step(dfa, dfa.start_state, 'a') is Some(after_a) else {
    fail("start should advance on a")
  }
  assert_true(lex_dfa_accept_variable(dfa, after_a) == Some(0))
  guard lex_dfa_step(dfa, after_a, 'b') is Some(after_ab) else {
    fail("shorter completion should keep longer continuation")
  }
  assert_true(lex_dfa_accept_variable(dfa, after_ab) == Some(1))
}

///|
test "lex dfa chooses explicit precedence among completed tokens" {
  let result = expanded_lexical_from_rules(
    [
      lexical_variable(
        0,
        "plain",
        VariableKind::Named,
        InternedRule::IRString("a"),
      ),
      lexical_variable(
        1,
        "precise",
        VariableKind::Named,
        InternedRule::IRPrec(
          value=@grammar.PrecedenceValue::Number(5),
          content=InternedRule::IRString("a"),
        ),
      ),
    ],
    [],
  )
  guard result is Ok(lexical) else { fail("token expansion should succeed") }
  let dfa = build_lex_dfa(lexical, lex_token_set([0, 1]))

  guard lex_dfa_step(dfa, dfa.start_state, 'a') is Some(after_a) else {
    fail("start should advance on a")
  }
  assert_true(lex_dfa_accept_variable(dfa, after_a) == Some(1))
}

///|
test "lex dfa keeps nul transition separate from eof action" {
  let result = expanded_lexical_from_rules(
    [
      lexical_variable(
        0,
        "nul",
        VariableKind::Named,
        InternedRule::IRPattern(value="\\0", flags=""),
      ),
    ],
    [],
  )
  guard result is Ok(lexical) else { fail("token expansion should succeed") }
  let dfa = build_lex_dfa(lexical, lex_token_set([0], eof=true))

  assert_true(dfa.states[dfa.start_state].eof_action is Some(_))
  guard lex_dfa_step(dfa, dfa.start_state, '\u{0}') is Some(after_nul) else {
    fail("nul code point should be consumed as a character")
  }
  assert_true(lex_dfa_accept_variable(dfa, after_nul) == Some(0))
}

///|
test "lex dfa propagates eof validity only through separators" {
  let result = expanded_lexical_from_rules(
    [
      lexical_variable(
        0,
        "a",
        VariableKind::Anonymous,
        InternedRule::IRString("a"),
      ),
    ],
    [InternedRule::IRString(" ")],
  )
  guard result is Ok(lexical) else { fail("token expansion should succeed") }
  let dfa = build_lex_dfa(lexical, lex_token_set([0], eof=true))

  assert_true(dfa.states[dfa.start_state].eof_action is Some(_))
  guard lex_dfa_step(dfa, dfa.start_state, ' ') is Some(after_space) else {
    fail("start should skip separator")
  }
  assert_true(dfa.states[after_space].eof_valid)
  assert_true(dfa.states[after_space].eof_action is Some(_))
  guard lex_dfa_step(dfa, after_space, 'a') is Some(after_a) else {
    fail("separator state should still allow token")
  }
  assert_true(!dfa.states[after_a].eof_valid)
  assert_true(dfa.states[after_a].eof_action is None)
  assert_true(lex_dfa_accept_variable(dfa, after_a) == Some(0))
}

///|
test "lex dfa does not add initial separators for immediate-only token set" {
  let result = expanded_lexical_from_rules(
    [
      lexical_variable(
        0,
        "immediate",
        VariableKind::Named,
        InternedRule::IRImmediateToken(InternedRule::IRString("a")),
      ),
    ],
    [InternedRule::IRString(" ")],
  )
  guard result is Ok(lexical) else { fail("token expansion should succeed") }
  let dfa = build_lex_dfa(lexical, lex_token_set([0]))

  assert_true(lex_dfa_step(dfa, dfa.start_state, ' ') is None)
  assert_true(lex_dfa_step(dfa, dfa.start_state, 'a') is Some(_))
}

///|
test "lex dfa carries external token slots for explicit and paired tokens" {
  let result = expanded_lexical_from_rules(
    [
      lexical_variable(
        0,
        "paired_internal",
        VariableKind::Named,
        InternedRule::IRString("p"),
      ),
    ],
    [],
  )
  guard result is Ok(base_lexical) else {
    fail("token expansion should succeed")
  }
  let lexical : ExpandedLexicalGrammar = {
    ..base_lexical,
    external_tokens: [
      {
        symbol: InternalSymbol::External(0),
        name: "scanner_only",
        kind: VariableKind::Named,
        corresponding_internal_token: None,
      },
      {
        symbol: InternalSymbol::External(1),
        name: "paired_internal",
        kind: VariableKind::Named,
        corresponding_internal_token: Some(InternalSymbol::Terminal(0)),
      },
    ],
  }

  let dfa = build_lex_dfa(lexical, lex_token_set([0], externals=[0]))
  assert_eq(dfa.external_tokens.length(), 2)
  assert_eq(dfa.external_tokens[0].external_index, 0)
  assert_true(dfa.external_tokens[0].symbol == InternalSymbol::External(0))
  assert_true(dfa.external_tokens[0].corresponding_internal_token is None)
  assert_eq(dfa.external_tokens[1].external_index, 1)
  assert_true(dfa.external_tokens[1].symbol == InternalSymbol::External(1))
  assert_true(
    dfa.external_tokens[1].corresponding_internal_token ==
    Some(InternalSymbol::Terminal(0)),
  )
}
