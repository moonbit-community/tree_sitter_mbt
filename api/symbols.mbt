///|
pub(all) enum SymbolType {
  Regular
  Anonymous
  Supertype
  Auxiliary
} derive(Eq, Debug)

///|
pub extend SymbolType with Debug::{to_repr}

///|
pub extend SymbolType with Eq::{not_equal, equal}
