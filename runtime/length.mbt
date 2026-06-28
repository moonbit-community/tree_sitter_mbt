///|
struct Length {
  bytes : UInt
  extent : @api.Point
} derive(Eq, Debug)

///|
pub fn Length::new(bytes~ : UInt, extent~ : @api.Point) -> Length {
  { bytes, extent }
}

///|
pub fn Length::zero() -> Length {
  { bytes: 0, extent: @api.Point::zero() }
}

///|
pub fn Length::undefined() -> Length {
  { bytes: 0, extent: @api.Point::new(row=0, column=1) }
}

///|
pub fn Length::max() -> Length {
  { bytes: @api.uint32_max(), extent: @api.Point::max() }
}

///|
pub fn Length::is_undefined(self : Length) -> Bool {
  self.bytes == 0 && self.extent.column != 0
}

///|
pub fn Length::min(self : Length, other : Length) -> Length {
  if self.bytes < other.bytes {
    self
  } else {
    other
  }
}

///|
pub fn Length::add(self : Length, other : Length) -> Length {
  {
    bytes: add_u32_saturating(self.bytes, other.bytes),
    extent: self.extent.add(other.extent),
  }
}

///|
pub fn Length::sub(self : Length, other : Length) -> Length {
  {
    bytes: sub_u32_saturating(self.bytes, other.bytes),
    extent: self.extent.sub(other.extent),
  }
}

///|
pub fn Length::saturating_sub(self : Length, other : Length) -> Length {
  if self.bytes > other.bytes {
    self.sub(other)
  } else {
    Length::zero()
  }
}

///|
fn add_u32_saturating(left : UInt, right : UInt) -> UInt {
  if right > @api.uint32_max() - left {
    @api.uint32_max()
  } else {
    left + right
  }
}

///|
fn sub_u32_saturating(left : UInt, right : UInt) -> UInt {
  if left >= right {
    left - right
  } else {
    0
  }
}
