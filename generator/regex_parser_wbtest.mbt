///|
test "regex parser parses literals alternation and concatenation" {
  let result = parse_regex("ab|c")
  guard result is Ok(RegexAst::RegexChoice(alternatives)) else {
    fail("regex should parse as alternation")
  }
  assert_eq(alternatives.length(), 2)
  guard alternatives[0] is RegexAst::RegexSeq(items) else {
    fail("first alternative should be concatenation")
  }
  assert_true(items[0] is RegexAst::RegexLiteral(97U))
  assert_true(items[1] is RegexAst::RegexLiteral(98U))
  assert_true(alternatives[1] is RegexAst::RegexLiteral(99U))
}

///|
test "regex parser parses repetition operators and bounded repetition" {
  guard parse_regex("a*") is Ok(RegexAst::RegexRepeat(min=0, max=None, ..)) else {
    fail("star should parse as unbounded repeat")
  }
  guard parse_regex("a+") is Ok(RegexAst::RegexRepeat(min=1, max=None, ..)) else {
    fail("plus should parse as unbounded repeat")
  }
  guard parse_regex("a?") is Ok(RegexAst::RegexRepeat(min=0, max=Some(1), ..)) else {
    fail("question should parse as optional repeat")
  }
  guard parse_regex("a{2,4}")
    is Ok(RegexAst::RegexRepeat(min=2, max=Some(4), ..)) else {
    fail("bounded repeat should parse")
  }
  assert_true(
    parse_regex("a{4,2}") is Err("Invalid repetition range at index 6"),
  )
}

///|
test "regex parser parses escapes and unicode escapes" {
  assert_true(parse_regex("\\n") is Ok(RegexAst::RegexLiteral(10U)))
  assert_true(parse_regex("\\0") is Ok(RegexAst::RegexLiteral(0U)))
  assert_true(parse_regex("\\u0041") is Ok(RegexAst::RegexLiteral(65U)))
  assert_true(parse_regex("\\U000000df") is Ok(RegexAst::RegexLiteral(223U)))
  assert_true(parse_regex("\\u{1F600}") is Ok(RegexAst::RegexLiteral(128512U)))
  assert_true(parse_regex("\\U{000000dd}") is Ok(RegexAst::RegexLiteral(221U)))

  guard parse_regex("\\d") is Ok(RegexAst::RegexClass(digit)) else {
    fail("digit escape should parse as class")
  }
  assert_true(character_set_contains(digit, 48U))
  assert_true(character_set_contains(digit, 57U))
  assert_true(!character_set_contains(digit, 65U))
}

///|
test "regex parser parses unicode property classes" {
  guard parse_regex("\\p{L}") is Ok(RegexAst::RegexClass(letter)) else {
    fail("letter property should parse")
  }
  assert_true(character_set_contains(letter, 65U))
  assert_true(character_set_contains(letter, 936U))
  assert_true(character_set_contains(letter, 4305U))
  assert_true(!character_set_contains(letter, 49U))

  guard parse_regex("\\p{Ll}") is Ok(RegexAst::RegexClass(lowercase)) else {
    fail("lowercase property should parse")
  }
  assert_true(character_set_contains(lowercase, 97U))
  assert_true(character_set_contains(lowercase, 347U))
  assert_true(!character_set_contains(lowercase, 65U))

  guard parse_regex("\\p{Lu}") is Ok(RegexAst::RegexClass(uppercase)) else {
    fail("uppercase property should parse")
  }
  assert_true(character_set_contains(uppercase, 65U))
  assert_true(character_set_contains(uppercase, 936U))
  assert_true(!character_set_contains(uppercase, 97U))

  guard parse_regex("\\P{White_Space}") is Ok(RegexAst::RegexClass(non_space)) else {
    fail("negated whitespace property should parse")
  }
  assert_true(!character_set_contains(non_space, 32U))
  assert_true(character_set_contains(non_space, 65U))

  guard parse_regex("[\\p{L}\\p{Nd}]") is Ok(RegexAst::RegexClass(word)) else {
    fail("properties inside bracketed classes should parse")
  }
  assert_true(character_set_contains(word, 97U))
  assert_true(character_set_contains(word, 1635U))
  assert_true(!character_set_contains(word, 95U))

  assert_true(
    parse_regex("\\p{Unknown_Property}")
    is Err("Unsupported Unicode property 'Unknown_Property' at index 2"),
  )
}

///|
test "regex parser parses character classes and set operations" {
  guard parse_regex("[a-cx]") is Ok(RegexAst::RegexClass(range_class)) else {
    fail("range class should parse")
  }
  assert_true(character_set_contains(range_class, 97U))
  assert_true(character_set_contains(range_class, 99U))
  assert_true(character_set_contains(range_class, 120U))
  assert_true(!character_set_contains(range_class, 100U))

  guard parse_regex("[a-f&&d-z]") is Ok(RegexAst::RegexClass(intersection)) else {
    fail("class intersection should parse")
  }
  assert_true(!character_set_contains(intersection, 99U))
  assert_true(character_set_contains(intersection, 100U))
  assert_true(character_set_contains(intersection, 102U))
  assert_true(!character_set_contains(intersection, 103U))

  guard parse_regex("[a-f--d]") is Ok(RegexAst::RegexClass(difference)) else {
    fail("class difference should parse")
  }
  assert_true(character_set_contains(difference, 99U))
  assert_true(!character_set_contains(difference, 100U))

  guard parse_regex("[a-c~~b-d]") is Ok(RegexAst::RegexClass(symmetric)) else {
    fail("class symmetric difference should parse")
  }
  assert_true(character_set_contains(symmetric, 97U))
  assert_true(!character_set_contains(symmetric, 98U))
  assert_true(!character_set_contains(symmetric, 99U))
  assert_true(character_set_contains(symmetric, 100U))

  guard parse_regex("[[0-7]&&[4-9]]") is Ok(RegexAst::RegexClass(nested)) else {
    fail("nested class intersection should parse")
  }
  assert_true(!character_set_contains(nested, 51U))
  assert_true(character_set_contains(nested, 52U))
  assert_true(character_set_contains(nested, 55U))
  assert_true(!character_set_contains(nested, 56U))

  guard parse_regex("[[[0-5]--[2-4]]~~[[3-9]--[6-7]]]")
    is Ok(RegexAst::RegexClass(deeply_nested)) else {
    fail("deeply nested set operations should parse")
  }
  assert_true(character_set_contains(deeply_nested, 48U))
  assert_true(character_set_contains(deeply_nested, 49U))
  assert_true(!character_set_contains(deeply_nested, 50U))
  assert_true(character_set_contains(deeply_nested, 51U))
  assert_true(character_set_contains(deeply_nested, 52U))
  assert_true(!character_set_contains(deeply_nested, 53U))
  assert_true(!character_set_contains(deeply_nested, 54U))
  assert_true(!character_set_contains(deeply_nested, 55U))
  assert_true(character_set_contains(deeply_nested, 56U))
  assert_true(character_set_contains(deeply_nested, 57U))
}

///|
test "regex parser rejects unsupported assertions with stable errors" {
  assert_true(
    parse_regex("(?=a)") is Err("Unsupported regex assertion at index 0"),
  )
  assert_true(parse_regex("(a") is Err("Expected ')' at index 2"))
}
