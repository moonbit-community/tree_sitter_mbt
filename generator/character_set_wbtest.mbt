///|
test "character set normalizes scalar ranges" {
  let set = character_set_from_ranges([
    { start: 70U, end: 72U },
    { start: 65U, end: 67U },
    { start: 68U, end: 69U },
    { start: 80U, end: 79U },
    { start: 1114112U, end: 1114113U },
  ])

  assert_eq(set.ranges.length(), 1)
  assert_eq(set.ranges[0].start, 65U)
  assert_eq(set.ranges[0].end, 72U)
  assert_true(character_set_contains(set, 65U))
  assert_true(character_set_contains(set, 72U))
  assert_true(!character_set_contains(set, 73U))
}

///|
test "character set negation uses Unicode scalar bounds" {
  let set = character_set_from_ranges([
    { start: 0U, end: 0U },
    { start: 10U, end: 12U },
    { start: unicode_scalar_max, end: unicode_scalar_max },
  ])
  let negated = character_set_negated(set)

  assert_eq(negated.ranges.length(), 2)
  assert_eq(negated.ranges[0].start, 1U)
  assert_eq(negated.ranges[0].end, 9U)
  assert_eq(negated.ranges[1].start, 13U)
  assert_eq(negated.ranges[1].end, unicode_scalar_max - 1U)
  assert_true(!character_set_contains(negated, 0U))
  assert_true(!character_set_contains(negated, unicode_scalar_max))
}

///|
test "character set intersection difference and symmetric difference are stable" {
  let left = character_set_from_ranges([
    { start: 1U, end: 5U },
    { start: 10U, end: 12U },
  ])
  let right = character_set_from_ranges([{ start: 3U, end: 10U }])

  let intersection = character_set_intersection(left, right)
  assert_eq(intersection.ranges.length(), 2)
  assert_eq(intersection.ranges[0].start, 3U)
  assert_eq(intersection.ranges[0].end, 5U)
  assert_eq(intersection.ranges[1].start, 10U)
  assert_eq(intersection.ranges[1].end, 10U)

  let difference = character_set_difference(left, right)
  assert_eq(difference.ranges.length(), 2)
  assert_eq(difference.ranges[0].start, 1U)
  assert_eq(difference.ranges[0].end, 2U)
  assert_eq(difference.ranges[1].start, 11U)
  assert_eq(difference.ranges[1].end, 12U)

  let symmetric = character_set_symmetric_difference(left, right)
  assert_eq(symmetric.ranges.length(), 3)
  assert_eq(symmetric.ranges[0].start, 1U)
  assert_eq(symmetric.ranges[0].end, 2U)
  assert_eq(symmetric.ranges[1].start, 6U)
  assert_eq(symmetric.ranges[1].end, 9U)
  assert_eq(symmetric.ranges[2].start, 11U)
  assert_eq(symmetric.ranges[2].end, 12U)
}

///|
test "character set ascii shorthand sets match tree-sitter replacements" {
  let digit = character_set_ascii_digit()
  assert_true(character_set_contains(digit, 48U))
  assert_true(character_set_contains(digit, 57U))
  assert_true(!character_set_contains(digit, 58U))

  let word = character_set_ascii_word()
  assert_true(character_set_contains(word, 65U))
  assert_true(character_set_contains(word, 95U))
  assert_true(character_set_contains(word, 122U))
  assert_true(!character_set_contains(word, 45U))

  let whitespace = character_set_ascii_whitespace()
  assert_true(character_set_contains(whitespace, 9U))
  assert_true(character_set_contains(whitespace, 13U))
  assert_true(character_set_contains(whitespace, 32U))
  assert_true(!character_set_contains(whitespace, 33U))
}
