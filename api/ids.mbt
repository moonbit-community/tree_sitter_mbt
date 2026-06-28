///|
struct SymbolId {
  value : UInt
} derive(Eq, Debug)

///|
pub fn SymbolId::new(value : UInt) -> SymbolId {
  { value, }
}

///|
pub fn SymbolId::value(self : SymbolId) -> UInt {
  self.value
}

///|
struct FieldId {
  value : UInt
} derive(Eq, Debug)

///|
pub fn FieldId::new(value : UInt) -> FieldId {
  { value, }
}

///|
pub fn FieldId::value(self : FieldId) -> UInt {
  self.value
}

///|
struct StateId {
  value : UInt
} derive(Eq, Debug)

///|
pub fn StateId::new(value : UInt) -> StateId {
  { value, }
}

///|
pub fn StateId::value(self : StateId) -> UInt {
  self.value
}
