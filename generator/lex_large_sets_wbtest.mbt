///|
fn set_from_singletons(values : Array[Char]) -> CharacterSet {
  let mut result = character_set_empty()
  for value in values {
    result = character_set_union(result, character_set_char(value))
  }
  result
}

///|
test "large character set collection records per token main character unions" {
  let main_set = set_from_singletons([
    'a', 'c', 'e', 'g', 'i', 'k', 'm', 'o', 'q',
  ])
  let lexical : ExpandedLexicalGrammar = {
    variables: [
      {
        symbol: InternalSymbol::Terminal(0),
        name: "wide",
        kind: VariableKind::Named,
        nfa: nfa_with_metadata(
          regex_ast_to_nfa(RegexAst::RegexClass(main_set)),
          0,
          0,
          false,
          0,
        ),
        immediate: false,
        explicit_precedence: None,
        implicit_precedence: 0,
        main_token: false,
        literal: None,
      },
    ],
    separators: [],
    external_tokens: [],
  }

  let sets = collect_large_character_sets(lexical)
  assert_eq(sets.length(), 1)
  assert_true(sets[0].symbol == Some(InternalSymbol::Terminal(0)))
  assert_true(character_set_same(sets[0].characters, main_set))
}

///|
test "large character set collection records shared separator transitions" {
  let separator_set = set_from_singletons([
    '0', '2', '4', '6', '8', 'A', 'C', 'E', 'G',
  ])
  let lexical : ExpandedLexicalGrammar = {
    variables: [
      {
        symbol: InternalSymbol::Terminal(0),
        name: "token",
        kind: VariableKind::Named,
        nfa: nfa_with_metadata(
          regex_ast_to_nfa(RegexAst::RegexLiteral('a'.to_uint())),
          0,
          0,
          false,
          0,
        ),
        immediate: false,
        explicit_precedence: None,
        implicit_precedence: 0,
        main_token: false,
        literal: None,
      },
    ],
    separators: [
      nfa_with_metadata(
        regex_ast_to_nfa(RegexAst::RegexClass(separator_set)),
        -1,
        0,
        true,
        0,
      ),
    ],
    external_tokens: [],
  }

  let sets = collect_large_character_sets(lexical)
  assert_eq(sets.length(), 1)
  assert_true(sets[0].symbol is None)
  assert_true(character_set_same(sets[0].characters, separator_set))
}

///|
test "large character set collection dedupes by character set only" {
  let shared_set = set_from_singletons([
    'a', 'c', 'e', 'g', 'i', 'k', 'm', 'o', 'q',
  ])
  let lexical : ExpandedLexicalGrammar = {
    variables: [
      {
        symbol: InternalSymbol::Terminal(0),
        name: "left",
        kind: VariableKind::Named,
        nfa: nfa_with_metadata(
          regex_ast_to_nfa(RegexAst::RegexClass(shared_set)),
          0,
          0,
          false,
          0,
        ),
        immediate: false,
        explicit_precedence: None,
        implicit_precedence: 0,
        main_token: false,
        literal: None,
      },
      {
        symbol: InternalSymbol::Terminal(1),
        name: "right",
        kind: VariableKind::Named,
        nfa: nfa_with_metadata(
          regex_ast_to_nfa(RegexAst::RegexClass(shared_set)),
          1,
          0,
          false,
          0,
        ),
        immediate: false,
        explicit_precedence: None,
        implicit_precedence: 0,
        main_token: false,
        literal: None,
      },
    ],
    separators: [],
    external_tokens: [],
  }

  let sets = collect_large_character_sets(lexical)
  assert_eq(sets.length(), 1)
  assert_true(sets[0].symbol == Some(InternalSymbol::Terminal(0)))
}

///|
test "large character set choice prefers fewer additions and removals" {
  let base = set_from_singletons(['a', 'c', 'e', 'g', 'i', 'k', 'm', 'o'])
  let larger = character_set_union(base, character_set_char('q'))
  let exactish = character_set_union(larger, character_set_char('s'))
  let sets = [
    { symbol: None, characters: base },
    { symbol: Some(InternalSymbol::Terminal(1)), characters: exactish },
  ]
  let transition = character_set_union(exactish, character_set_char('u'))

  guard choose_large_character_set(sets, transition, character_set_empty())
    is Some(choice) else {
    fail("large set should be selected")
  }
  assert_eq(choice.set_index, 1)
  assert_true(character_set_same(choice.additions, character_set_char('u')))
  assert_true(character_set_is_empty(choice.removals))
}

///|
test "large character set choice respects render threshold and improvement" {
  let small = set_from_singletons(['a', 'c', 'e', 'g', 'i', 'k', 'm'])
  let sets = [{ symbol: None, characters: small }]
  assert_true(
    choose_large_character_set(sets, small, character_set_empty()) is None,
  )

  let large = character_set_union(small, character_set_char('o'))
  assert_true(
    choose_large_character_set(
      [{ symbol: None, characters: character_set_char('z') }],
      large,
      character_set_empty(),
    )
    is None,
  )
}
