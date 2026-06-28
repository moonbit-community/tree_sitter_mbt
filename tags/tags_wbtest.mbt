///|
test "tags line range truncates at invalid utf8" {
  let line_range = tag_line_range(
    Bytes::from_array([b'a', b'\xff', b' ', b'\n']),
    @api.Range::new(
      start_byte=0U,
      end_byte=1U,
      start_point=@api.Point::new(row=0U, column=0U),
      end_point=@api.Point::new(row=0U, column=1U),
    ),
  )
  assert_eq(line_range.start_byte, 0U)
  assert_eq(line_range.end_byte, 1U)
  assert_true(line_range.end_point == @api.Point::new(row=0U, column=1U))
}
