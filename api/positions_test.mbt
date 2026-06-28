///|
test "point ordering follows row then byte column" {
  let before = Point::new(row=1, column=3)
  let same = Point::new(row=1, column=3)
  let after_column = Point::new(row=1, column=4)
  let after_row = Point::new(row=2, column=0)
  assert_true(before.lte(same))
  assert_true(before.lt(after_column))
  assert_true(after_row.gt(before))
  assert_true(after_row.gte(after_column))
}

///|
test "point add and sub match tree-sitter newline extent rules" {
  let base = Point::new(row=3, column=10)
  assert_true(
    base.add(Point::new(row=0, column=4)) == Point::new(row=3, column=14),
  )
  assert_true(
    base.add(Point::new(row=2, column=4)) == Point::new(row=5, column=4),
  )
  assert_true(
    Point::new(row=5, column=7).sub(Point::new(row=3, column=99)) ==
    Point::new(row=2, column=7),
  )
  assert_true(
    Point::new(row=1, column=3).sub(Point::new(row=1, column=9)) ==
    Point::zero(),
  )
}

///|
test "tree-sitter point columns are byte columns not string or scanner columns" {
  let moonbit_scalar_count = "é".to_array().length()
  let point_after_e_acute = Point::new(row=0, column=2)
  let external_scanner_code_point_column : UInt = 1
  assert_eq(moonbit_scalar_count, 1)
  assert_eq(point_after_e_acute.column, 2)
  assert_true(point_after_e_acute.column != external_scanner_code_point_column)
}

///|
test "input edit updates positions using both old byte and old point" {
  let edit = InputEdit::new(
    start_byte=2,
    old_end_byte=4,
    new_end_byte=8,
    start_point=Point::new(row=0, column=2),
    old_end_point=Point::new(row=0, column=4),
    new_end_point=Point::new(row=1, column=3),
  )
  assert_true(
    Point::new(row=0, column=2).edit(byte=2, edit~) ==
    (2, Point::new(row=0, column=2)),
  )
  assert_true(
    Point::new(row=0, column=3).edit(byte=3, edit~) ==
    (8, Point::new(row=1, column=3)),
  )
  assert_true(
    Point::new(row=0, column=10).edit(byte=10, edit~) ==
    (14, Point::new(row=1, column=9)),
  )
}

///|
test "range edit shifts endpoints and truncates overlaps" {
  let edit = InputEdit::new(
    start_byte=2,
    old_end_byte=4,
    new_end_byte=8,
    start_point=Point::new(row=0, column=2),
    old_end_point=Point::new(row=0, column=4),
    new_end_point=Point::new(row=1, column=3),
  )
  let shifted = Range::new(
    start_byte=1,
    end_byte=10,
    start_point=Point::new(row=0, column=1),
    end_point=Point::new(row=0, column=10),
  ).edit(edit)
  assert_eq(shifted.start_byte, 1)
  assert_eq(shifted.end_byte, 14)
  assert_true(shifted.end_point == Point::new(row=1, column=9))

  let overlapped = Range::new(
    start_byte=3,
    end_byte=3,
    start_point=Point::new(row=0, column=3),
    end_point=Point::new(row=0, column=3),
  ).edit(edit)
  assert_eq(overlapped.start_byte, 2)
  assert_eq(overlapped.end_byte, 2)
  assert_true(overlapped.start_point == Point::new(row=0, column=2))
  assert_true(overlapped.end_point == Point::new(row=0, column=2))
}

///|
test "range helpers preserve unbounded and overflow sentinels" {
  let edit = InputEdit::new(
    start_byte=0,
    old_end_byte=1,
    new_end_byte=4294967290U,
    start_point=Point::zero(),
    old_end_point=Point::new(row=0, column=1),
    new_end_point=Point::new(row=0, column=4294967290U),
  )
  let unbounded = Range::unbounded(start_byte=0, start_point=Point::zero()).edit(
    edit,
  )
  assert_eq(unbounded.end_byte, uint32_max())
  assert_true(unbounded.end_point == Point::max())

  let overflowed = Range::new(
    start_byte=20,
    end_byte=20,
    start_point=Point::new(row=0, column=20),
    end_point=Point::new(row=0, column=20),
  ).edit(edit)
  assert_eq(overflowed.start_byte, uint32_max())
  assert_true(overflowed.start_point == Point::max())
  assert_eq(overflowed.end_byte, uint32_max())
  assert_true(overflowed.end_point == Point::max())
}

///|
test "range contains byte and point use half-open bounds" {
  let range = Range::new(
    start_byte=2,
    end_byte=5,
    start_point=Point::new(row=0, column=2),
    end_point=Point::new(row=0, column=5),
  )
  assert_true(range.contains_byte(2))
  assert_true(!range.contains_byte(5))
  assert_true(range.contains_point(Point::new(row=0, column=2)))
  assert_true(!range.contains_point(Point::new(row=0, column=5)))
  assert_eq(range.byte_length(), 3)
}
