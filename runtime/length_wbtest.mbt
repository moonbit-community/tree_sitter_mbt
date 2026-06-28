///|
test "length models bytes plus tree-sitter point extent" {
  let base = Length::new(bytes=10, extent=@api.Point::new(row=0, column=10))
  let same_line = Length::new(bytes=2, extent=@api.Point::new(row=0, column=2))
  let next_line = Length::new(bytes=5, extent=@api.Point::new(row=1, column=3))
  assert_true(
    base.add(same_line) ==
    Length::new(bytes=12, extent=@api.Point::new(row=0, column=12)),
  )
  assert_true(
    base.add(next_line) ==
    Length::new(bytes=15, extent=@api.Point::new(row=1, column=3)),
  )
}

///|
test "length subtraction saturates bytes and point extent" {
  let left = Length::new(bytes=3, extent=@api.Point::new(row=0, column=3))
  let right = Length::new(bytes=10, extent=@api.Point::new(row=0, column=9))
  assert_true(left.sub(right) == Length::zero())
  assert_true(left.saturating_sub(right) == Length::zero())
}

///|
test "length undefined and max sentinels match upstream constants" {
  assert_true(Length::undefined().is_undefined())
  assert_eq(Length::max().bytes, @api.uint32_max())
  assert_true(Length::max().extent == @api.Point::max())
}

///|
test "length min uses byte length ordering" {
  let short = Length::new(bytes=2, extent=@api.Point::new(row=4, column=0))
  let long = Length::new(bytes=3, extent=@api.Point::new(row=0, column=3))
  assert_true(long.min(short) == short)
}
