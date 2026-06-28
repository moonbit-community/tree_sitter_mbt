///|
pub(all) struct Point {
  row : UInt
  column : UInt
} derive(Eq, Debug)

///|
pub fn uint32_max() -> UInt {
  4294967295U
}

///|
pub fn Point::new(row~ : UInt, column~ : UInt) -> Point {
  { row, column }
}

///|
pub fn Point::zero() -> Point {
  { row: 0, column: 0 }
}

///|
pub fn Point::max() -> Point {
  { row: uint32_max(), column: uint32_max() }
}

///|
pub fn Point::lt(self : Point, other : Point) -> Bool {
  self.row < other.row || (self.row == other.row && self.column < other.column)
}

///|
pub fn Point::lte(self : Point, other : Point) -> Bool {
  self.row < other.row || (self.row == other.row && self.column <= other.column)
}

///|
pub fn Point::gt(self : Point, other : Point) -> Bool {
  self.row > other.row || (self.row == other.row && self.column > other.column)
}

///|
pub fn Point::gte(self : Point, other : Point) -> Bool {
  self.row > other.row || (self.row == other.row && self.column >= other.column)
}

///|
pub fn Point::add(self : Point, other : Point) -> Point {
  if other.row > 0 {
    { row: add_u32_saturating(self.row, other.row), column: other.column }
  } else {
    { row: self.row, column: add_u32_saturating(self.column, other.column) }
  }
}

///|
pub fn Point::sub(self : Point, other : Point) -> Point {
  if self.row > other.row {
    { row: self.row - other.row, column: self.column }
  } else {
    { row: 0, column: sub_u32_saturating(self.column, other.column) }
  }
}

///|
pub fn Point::edit(
  self : Point,
  byte~ : UInt,
  edit~ : InputEdit,
) -> (UInt, Point) {
  edit.edit_position(byte~, point=self)
}

///|
pub(all) struct Range {
  start_byte : UInt
  end_byte : UInt
  start_point : Point
  end_point : Point
} derive(Eq, Debug)

///|
pub fn Range::new(
  start_byte~ : UInt,
  end_byte~ : UInt,
  start_point~ : Point,
  end_point~ : Point,
) -> Range {
  { start_byte, end_byte, start_point, end_point }
}

///|
pub fn Range::unbounded(start_byte~ : UInt, start_point~ : Point) -> Range {
  { start_byte, end_byte: uint32_max(), start_point, end_point: Point::max() }
}

///|
pub fn Range::is_empty(self : Range) -> Bool {
  self.start_byte == self.end_byte && self.start_point == self.end_point
}

///|
pub fn Range::contains_byte(self : Range, byte : UInt) -> Bool {
  self.start_byte <= byte && byte < self.end_byte
}

///|
pub fn Range::contains_point(self : Range, point : Point) -> Bool {
  self.start_point.lte(point) && point.lt(self.end_point)
}

///|
pub fn Range::byte_length(self : Range) -> UInt {
  sub_u32_saturating(self.end_byte, self.start_byte)
}

///|
pub fn Range::edit(self : Range, edit : InputEdit) -> Range {
  let (end_byte, end_point) = edit_range_end(
    byte=self.end_byte,
    point=self.end_point,
    edit~,
  )
  let (start_byte, start_point) = edit_range_start(
    byte=self.start_byte,
    point=self.start_point,
    edit~,
  )
  { start_byte, end_byte, start_point, end_point }
}

///|
pub(all) struct InputEdit {
  start_byte : UInt
  old_end_byte : UInt
  new_end_byte : UInt
  start_point : Point
  old_end_point : Point
  new_end_point : Point
} derive(Eq, Debug)

///|
pub fn InputEdit::new(
  start_byte~ : UInt,
  old_end_byte~ : UInt,
  new_end_byte~ : UInt,
  start_point~ : Point,
  old_end_point~ : Point,
  new_end_point~ : Point,
) -> InputEdit {
  {
    start_byte,
    old_end_byte,
    new_end_byte,
    start_point,
    old_end_point,
    new_end_point,
  }
}

///|
pub fn InputEdit::edit_position(
  self : InputEdit,
  byte~ : UInt,
  point~ : Point,
) -> (UInt, Point) {
  if byte >= self.old_end_byte {
    let delta = byte - self.old_end_byte
    let (new_byte, overflowed) = add_u32_checked(self.new_end_byte, delta)
    if overflowed {
      (uint32_max(), Point::max())
    } else {
      let new_point = self.new_end_point.add(point.sub(self.old_end_point))
      (new_byte, new_point)
    }
  } else if byte > self.start_byte {
    (self.new_end_byte, self.new_end_point)
  } else {
    (byte, point)
  }
}

///|
pub(all) enum InputEncoding {
  Utf8
  Utf16LE
  Utf16BE
  Custom
} derive(Eq, Debug)

///|
fn edit_range_end(
  byte~ : UInt,
  point~ : Point,
  edit~ : InputEdit,
) -> (UInt, Point) {
  if byte >= edit.old_end_byte {
    if byte != uint32_max() {
      let delta = byte - edit.old_end_byte
      let (new_byte, overflowed) = add_u32_checked(edit.new_end_byte, delta)
      if overflowed {
        (uint32_max(), Point::max())
      } else {
        let new_point = edit.new_end_point.add(point.sub(edit.old_end_point))
        (new_byte, new_point)
      }
    } else {
      (byte, point)
    }
  } else if byte > edit.start_byte {
    (edit.start_byte, edit.start_point)
  } else {
    (byte, point)
  }
}

///|
fn edit_range_start(
  byte~ : UInt,
  point~ : Point,
  edit~ : InputEdit,
) -> (UInt, Point) {
  if byte >= edit.old_end_byte {
    let delta = byte - edit.old_end_byte
    let (new_byte, overflowed) = add_u32_checked(edit.new_end_byte, delta)
    if overflowed {
      (uint32_max(), Point::max())
    } else {
      let new_point = edit.new_end_point.add(point.sub(edit.old_end_point))
      (new_byte, new_point)
    }
  } else if byte > edit.start_byte {
    (edit.start_byte, edit.start_point)
  } else {
    (byte, point)
  }
}

///|
fn add_u32_checked(left : UInt, right : UInt) -> (UInt, Bool) {
  if right > uint32_max() - left {
    (uint32_max(), true)
  } else {
    (left + right, false)
  }
}

///|
fn add_u32_saturating(left : UInt, right : UInt) -> UInt {
  let (value, _) = add_u32_checked(left, right)
  value
}

///|
fn sub_u32_saturating(left : UInt, right : UInt) -> UInt {
  if left >= right {
    left - right
  } else {
    0
  }
}
