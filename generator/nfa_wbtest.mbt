///|
test "nfa lowering matches literal concatenation" {
  guard parse_regex_to_nfa("ab") is Ok(nfa) else {
    fail("regex should lower to nfa")
  }
  assert_true(nfa_matches(nfa, "ab"))
  assert_true(!nfa_matches(nfa, "a"))
  assert_true(!nfa_matches(nfa, "abc"))
}

///|
test "nfa lowering matches alternation and empty alternatives" {
  guard parse_regex_to_nfa("a|bc|") is Ok(nfa) else {
    fail("regex should lower to nfa")
  }
  assert_true(nfa_matches(nfa, ""))
  assert_true(nfa_matches(nfa, "a"))
  assert_true(nfa_matches(nfa, "bc"))
  assert_true(!nfa_matches(nfa, "b"))
}

///|
test "nfa lowering matches star plus and optional repetition" {
  guard parse_regex_to_nfa("a*b+c?") is Ok(nfa) else {
    fail("regex should lower to nfa")
  }
  assert_true(nfa_matches(nfa, "b"))
  assert_true(nfa_matches(nfa, "aaabbc"))
  assert_true(nfa_matches(nfa, "aaabb"))
  assert_true(!nfa_matches(nfa, "aaa"))
}

///|
test "nfa lowering matches bounded repetition" {
  guard parse_regex_to_nfa("a{2,3}") is Ok(nfa) else {
    fail("regex should lower to nfa")
  }
  assert_true(!nfa_matches(nfa, "a"))
  assert_true(nfa_matches(nfa, "aa"))
  assert_true(nfa_matches(nfa, "aaa"))
  assert_true(!nfa_matches(nfa, "aaaa"))
}

///|
test "nfa lowering matches character classes and escaped shorthands" {
  guard parse_regex_to_nfa("[a-c&&b-d]+\\d") is Ok(nfa) else {
    fail("regex should lower to nfa")
  }
  assert_true(nfa_matches(nfa, "b2"))
  assert_true(nfa_matches(nfa, "bc9"))
  assert_true(!nfa_matches(nfa, "a2"))
  assert_true(!nfa_matches(nfa, "bdx"))
}

///|
test "nfa lowering matches nested character set operations" {
  guard parse_regex_to_nfa("[[0-7]&&[4-9]]+") is Ok(intersection) else {
    fail("nested intersection should lower to nfa")
  }
  assert_true(nfa_matches(intersection, "456"))
  assert_true(nfa_matches(intersection, "64"))
  assert_true(!nfa_matches(intersection, "452"))
  assert_true(!nfa_matches(intersection, "8"))

  guard parse_regex_to_nfa("[[0-9]--[4-7]]+") is Ok(difference) else {
    fail("nested difference should lower to nfa")
  }
  assert_true(nfa_matches(difference, "123"))
  assert_true(nfa_matches(difference, "83"))
  assert_true(!nfa_matches(difference, "124"))
  assert_true(!nfa_matches(difference, "67"))

  guard parse_regex_to_nfa("[[[0-5]--[2-4]]~~[[3-9]--[6-7]]]+") is Ok(nested) else {
    fail("deeply nested set operations should lower to nfa")
  }
  assert_true(nfa_matches(nested, "01"))
  assert_true(nfa_matches(nested, "43"))
  assert_true(nfa_matches(nested, "8"))
  assert_true(!nfa_matches(nested, "2"))
  assert_true(!nfa_matches(nested, "567"))
}

///|
test "nfa lowering matches unicode property classes and negation" {
  guard parse_regex_to_nfa("\\p{L}+\\P{L}+") is Ok(letter_nfa) else {
    fail("letter property regex should lower to nfa")
  }
  assert_true(nfa_matches(letter_nfa, "\u{10D1}\u{03A8}___"))
  assert_true(!nfa_matches(letter_nfa, "\u{10D1}\u{03A8}"))

  guard parse_regex_to_nfa("[\\p{L}\\p{Nd}]+") is Ok(word_nfa) else {
    fail("property class union should lower to nfa")
  }
  assert_true(nfa_matches(word_nfa, "ab\u{03A8}12\u{0663}\u{0663}"))
  assert_true(!nfa_matches(word_nfa, "ab\u{03A8},"))
}

///|
test "nfa lowering matches unicode symbol number and emoji properties" {
  guard parse_regex_to_nfa("\\p{Sm}+") is Ok(symbol_nfa) else {
    fail("math symbol property should lower to nfa")
  }
  assert_true(nfa_matches(symbol_nfa, "\u{227A}\u{227C}\u{2211}"))
  assert_true(!nfa_matches(symbol_nfa, "abc"))

  guard parse_regex_to_nfa("\\p{Letter_Number}") is Ok(number_nfa) else {
    fail("letter number property should lower to nfa")
  }
  assert_true(nfa_matches(number_nfa, "\u{2165}"))
  assert_true(nfa_matches(number_nfa, "\u{3029}"))
  assert_true(!nfa_matches(number_nfa, "5"))

  guard parse_regex_to_nfa("\\p{Emoji}+") is Ok(emoji_nfa) else {
    fail("emoji property should lower to nfa")
  }
  assert_true(nfa_matches(emoji_nfa, "\u{1F40E}"))
  assert_true(nfa_matches(emoji_nfa, "#0"))
  assert_true(!nfa_matches(emoji_nfa, "\u{265E}"))
}

///|
test "nfa lowering preserves nul code point as character not eof" {
  guard parse_regex_to_nfa("\\0") is Ok(nfa) else {
    fail("regex should lower to nfa")
  }
  assert_true(nfa_matches(nfa, "\u{0}"))
  assert_true(!nfa_matches(nfa, ""))
}

///|
fn same_nfa_transition(left : NfaTransition, right : NfaTransition) -> Bool {
  character_set_compare(left.characters, right.characters) == 0 &&
  left.is_separator == right.is_separator &&
  left.precedence == right.precedence &&
  left.states == right.states
}

///|
fn same_nfa_transitions(
  left : Array[NfaTransition],
  right : Array[NfaTransition],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if !same_nfa_transition(left[i], right[i]) {
      return false
    }
  }
  true
}

///|
test "nfa cursor groups overlapping transitions into disjoint partitions" {
  let transitions = nfa_group_raw_transitions([
    {
      characters: character_set_range('a'.to_uint(), 'f'.to_uint()),
      is_separator: false,
      precedence: 0,
      state: 1,
    },
    {
      characters: character_set_range('d'.to_uint(), 'i'.to_uint()),
      is_separator: false,
      precedence: 1,
      state: 2,
    },
  ])

  assert_true(
    same_nfa_transitions(transitions, [
      {
        characters: character_set_range('a'.to_uint(), 'c'.to_uint()),
        is_separator: false,
        precedence: 0,
        states: [1],
      },
      {
        characters: character_set_range('d'.to_uint(), 'f'.to_uint()),
        is_separator: false,
        precedence: 1,
        states: [1, 2],
      },
      {
        characters: character_set_range('g'.to_uint(), 'i'.to_uint()),
        is_separator: false,
        precedence: 1,
        states: [2],
      },
    ]),
  )
}

///|
test "nfa cursor uses separator and precedence combination rules" {
  let transitions = nfa_group_raw_transitions([
    {
      characters: character_set_range('a'.to_uint(), 'c'.to_uint()),
      is_separator: true,
      precedence: 0,
      state: 1,
    },
    {
      characters: character_set_range('b'.to_uint(), 'd'.to_uint()),
      is_separator: false,
      precedence: 5,
      state: 2,
    },
  ])

  assert_true(
    same_nfa_transitions(transitions, [
      {
        characters: character_set_char('a'),
        is_separator: true,
        precedence: 0,
        states: [1],
      },
      {
        characters: character_set_range('b'.to_uint(), 'c'.to_uint()),
        is_separator: false,
        precedence: 5,
        states: [1, 2],
      },
      {
        characters: character_set_char('d'),
        is_separator: false,
        precedence: 5,
        states: [2],
      },
    ]),
  )
}

///|
test "nfa cursor merges disjoint ranges with identical transition signatures" {
  let transitions = nfa_group_raw_transitions([
    {
      characters: character_set_char('a'),
      is_separator: false,
      precedence: 0,
      state: 1,
    },
    {
      characters: character_set_range('c'.to_uint(), 'd'.to_uint()),
      is_separator: false,
      precedence: 0,
      state: 1,
    },
    {
      characters: character_set_char('b'),
      is_separator: false,
      precedence: 0,
      state: 2,
    },
  ])

  assert_true(
    same_nfa_transitions(transitions, [
      {
        characters: character_set_union(
          character_set_char('a'),
          character_set_range('c'.to_uint(), 'd'.to_uint()),
        ),
        is_separator: false,
        precedence: 0,
        states: [1],
      },
      {
        characters: character_set_char('b'),
        is_separator: false,
        precedence: 0,
        states: [2],
      },
    ]),
  )
}

///|
test "nfa cursor collects transitions from epsilon closure" {
  guard parse_regex_to_nfa("a|b") is Ok(nfa) else {
    fail("regex should lower to nfa")
  }
  let cursor = nfa_cursor_new(nfa, [nfa.start])
  assert_true(cursor.state_ids == [1, 3])
  let transitions = nfa_cursor_transitions(cursor)

  assert_true(
    same_nfa_transitions(transitions, [
      {
        characters: character_set_char('a'),
        is_separator: false,
        precedence: 0,
        states: [2],
      },
      {
        characters: character_set_char('b'),
        is_separator: false,
        precedence: 0,
        states: [4],
      },
    ]),
  )
}
