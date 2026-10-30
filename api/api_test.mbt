///|
test "point and range constructors keep byte-oriented values" {
  let start = @api.Point::zero()
  let end = @api.Point::new(row=1, column=4)
  let range = @api.Range::new(
    start_byte=0,
    end_byte=12,
    start_point=start,
    end_point=end,
  )
  assert_eq(range.start_byte, 0)
  assert_eq(range.end_point.column, 4)
}

///|
test "opaque id wrappers expose checked values through accessors" {
  let symbol = @api.SymbolId::new(7)
  let field = @api.FieldId::new(2)
  let state = @api.StateId::new(11)
  assert_eq(symbol.value(), 7)
  assert_eq(field.value(), 2)
  assert_eq(state.value(), 11)
}
