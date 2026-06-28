///|
let unicode_scalar_max : UInt = 1114111U

///|
priv struct CharacterRange {
  start : UInt
  end : UInt
}

///|
priv struct CharacterSet {
  ranges : Array[CharacterRange]
}

///|
fn character_set_empty() -> CharacterSet {
  { ranges: [] }
}

///|
fn character_set_any() -> CharacterSet {
  character_set_range(0U, unicode_scalar_max)
}

///|
fn character_set_char(char : Char) -> CharacterSet {
  character_set_range(char.to_uint(), char.to_uint())
}

///|
fn character_set_range(start : UInt, end : UInt) -> CharacterSet {
  match normalized_character_range(start, end) {
    Some(range) => { ranges: [range] }
    None => character_set_empty()
  }
}

///|
fn character_set_from_ranges(ranges : Array[CharacterRange]) -> CharacterSet {
  let mut normalized : Array[CharacterRange] = []
  for range in ranges {
    match normalized_character_range(range.start, range.end) {
      Some(value) => normalized = insert_range(normalized, value)
      None => ()
    }
  }
  { ranges: normalized }
}

///|
fn character_set_union(
  left : CharacterSet,
  right : CharacterSet,
) -> CharacterSet {
  let mut ranges : Array[CharacterRange] = left.ranges
  for range in right.ranges {
    ranges = insert_range(ranges, range)
  }
  { ranges, }
}

///|
fn character_set_intersection(
  left : CharacterSet,
  right : CharacterSet,
) -> CharacterSet {
  let ranges : Array[CharacterRange] = []
  let mut left_index = 0
  let mut right_index = 0
  while left_index < left.ranges.length() && right_index < right.ranges.length() {
    let left_range = left.ranges[left_index]
    let right_range = right.ranges[right_index]
    let start = max_uint(left_range.start, right_range.start)
    let end = min_uint(left_range.end, right_range.end)
    if start <= end {
      ranges.push({ start, end })
    }
    if left_range.end < right_range.end {
      left_index += 1
    } else {
      right_index += 1
    }
  }
  { ranges, }
}

///|
fn character_set_difference(
  left : CharacterSet,
  right : CharacterSet,
) -> CharacterSet {
  character_set_intersection(left, character_set_negated(right))
}

///|
fn character_set_symmetric_difference(
  left : CharacterSet,
  right : CharacterSet,
) -> CharacterSet {
  character_set_union(
    character_set_difference(left, right),
    character_set_difference(right, left),
  )
}

///|
fn character_set_negated(set : CharacterSet) -> CharacterSet {
  let ranges : Array[CharacterRange] = []
  let mut next = 0U
  for range in set.ranges {
    if next < range.start {
      ranges.push({ start: next, end: range.start - 1U })
    }
    if range.end == unicode_scalar_max {
      return { ranges, }
    }
    next = range.end + 1U
  }
  if next <= unicode_scalar_max {
    ranges.push({ start: next, end: unicode_scalar_max })
  }
  { ranges, }
}

///|
fn character_set_contains(set : CharacterSet, code_point : UInt) -> Bool {
  for range in set.ranges {
    if range.start <= code_point && code_point <= range.end {
      return true
    }
  }
  false
}

///|
fn character_set_is_empty(set : CharacterSet) -> Bool {
  set.ranges.length() == 0
}

///|
fn character_set_range_count(set : CharacterSet) -> Int {
  set.ranges.length()
}

///|
fn character_set_same(left : CharacterSet, right : CharacterSet) -> Bool {
  character_set_compare(left, right) == 0
}

///|
fn character_set_compare(left : CharacterSet, right : CharacterSet) -> Int {
  let length = min_int(left.ranges.length(), right.ranges.length())
  for i in 0..<length {
    let start_compare = compare_uint(
      left.ranges[i].start,
      right.ranges[i].start,
    )
    if start_compare != 0 {
      return start_compare
    }
    let end_compare = compare_uint(left.ranges[i].end, right.ranges[i].end)
    if end_compare != 0 {
      return end_compare
    }
  }
  compare_int(left.ranges.length(), right.ranges.length())
}

///|
fn character_set_ascii_digit() -> CharacterSet {
  character_set_range(48U, 57U)
}

///|
fn character_set_ascii_word() -> CharacterSet {
  character_set_union(
    character_set_union(
      character_set_range(65U, 90U),
      character_set_range(97U, 122U),
    ),
    character_set_union(character_set_range(48U, 57U), character_set_char('_')),
  )
}

///|
fn character_set_ascii_whitespace() -> CharacterSet {
  character_set_union(character_set_range(9U, 13U), character_set_char(' '))
}

///|
fn character_set_smoke_weight() -> Int {
  let any = character_set_any()
  let normalized = character_set_from_ranges([
    { start: 65U, end: 67U },
    { start: 66U, end: 70U },
  ])
  let ascii = character_set_union(
    character_set_ascii_digit(),
    character_set_union(
      character_set_ascii_word(),
      character_set_ascii_whitespace(),
    ),
  )
  let symmetric = character_set_symmetric_difference(normalized, ascii)
  let contains_underscore = if character_set_contains(ascii, 95U) {
    1
  } else {
    0
  }
  character_set_weight(any) +
  character_set_weight(symmetric) +
  contains_underscore
}

///|
fn character_set_weight(set : CharacterSet) -> Int {
  let mut weight = 0
  for range in set.ranges {
    weight += range.start.reinterpret_as_int()
    weight += range.end.reinterpret_as_int()
  }
  weight
}

///|
fn normalized_character_range(start : UInt, end : UInt) -> CharacterRange? {
  if start > end || start > unicode_scalar_max {
    None
  } else {
    Some({ start, end: min_uint(end, unicode_scalar_max) })
  }
}

///|
fn insert_range(
  ranges : Array[CharacterRange],
  range : CharacterRange,
) -> Array[CharacterRange] {
  let result : Array[CharacterRange] = []
  let mut pending = range
  let mut inserted = false
  for existing in ranges {
    if inserted {
      result.push(existing)
    } else if range_is_strictly_before(existing, pending) {
      result.push(existing)
    } else if range_is_strictly_before(pending, existing) {
      result.push(pending)
      result.push(existing)
      inserted = true
    } else {
      pending = merge_ranges(pending, existing)
    }
  }
  if !inserted {
    result.push(pending)
  }
  result
}

///|
fn range_is_strictly_before(
  left : CharacterRange,
  right : CharacterRange,
) -> Bool {
  left.end < unicode_scalar_max && left.end + 1U < right.start
}

///|
fn merge_ranges(
  left : CharacterRange,
  right : CharacterRange,
) -> CharacterRange {
  {
    start: min_uint(left.start, right.start),
    end: max_uint(left.end, right.end),
  }
}

///|
fn min_uint(left : UInt, right : UInt) -> UInt {
  if left < right {
    left
  } else {
    right
  }
}

///|
fn max_uint(left : UInt, right : UInt) -> UInt {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn min_int(left : Int, right : Int) -> Int {
  if left < right {
    left
  } else {
    right
  }
}

///|
fn compare_int(left : Int, right : Int) -> Int {
  if left < right {
    -1
  } else if left > right {
    1
  } else {
    0
  }
}

///|
fn compare_uint(left : UInt, right : UInt) -> Int {
  if left < right {
    -1
  } else if left > right {
    1
  } else {
    0
  }
}
