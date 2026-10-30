///|
struct SymbolId {
  value : UInt32
} derive(Eq, Debug)

///|
pub fn SymbolId::new(value : UInt32) -> SymbolId {
  { value, }
}

///|
pub fn SymbolId::value(self : SymbolId) -> UInt32 {
  self.value
}

///|
struct FieldId {
  value : UInt32
} derive(Eq, Debug)

///|
pub fn FieldId::new(value : UInt32) -> FieldId {
  { value, }
}

///|
pub fn FieldId::value(self : FieldId) -> UInt32 {
  self.value
}

///|
struct StateId {
  value : UInt32
} derive(Eq, Debug)

///|
pub fn StateId::new(value : UInt32) -> StateId {
  { value, }
}

///|
pub fn StateId::value(self : StateId) -> UInt32 {
  self.value
}

///|
pub extend FieldId with Debug::{to_repr}

///|
pub extend FieldId with Eq::{not_equal, equal}

///|
pub extend StateId with Debug::{to_repr}

///|
pub extend StateId with Eq::{not_equal, equal}

///|
pub extend SymbolId with Debug::{to_repr}

///|
pub extend SymbolId with Eq::{not_equal, equal}
