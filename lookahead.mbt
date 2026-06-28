///|
struct LookaheadIterator {
  mut language : Language
  mut state_id : @api.StateId
  mut symbols : Array[@api.SymbolId]
  mut index : Int
}

///|
pub fn Language::lookahead_iterator(
  self : Language,
  state_id : @api.StateId,
) -> LookaheadIterator? {
  match self.tables.lookahead_symbols(state_id) {
    Some(symbols) => Some({ language: self, state_id, symbols, index: -1 })
    None => None
  }
}

///|
pub fn LookaheadIterator::language(self : LookaheadIterator) -> Language {
  self.language
}

///|
pub fn LookaheadIterator::state(self : LookaheadIterator) -> @api.StateId {
  self.state_id
}

///|
pub fn LookaheadIterator::reset_state(
  self : LookaheadIterator,
  state_id : @api.StateId,
) -> Bool {
  match self.language.tables.lookahead_symbols(state_id) {
    Some(symbols) => {
      self.state_id = state_id
      self.symbols = symbols
      self.index = -1
      true
    }
    None => false
  }
}

///|
pub fn LookaheadIterator::reset(
  self : LookaheadIterator,
  language : Language,
  state_id : @api.StateId,
) -> Bool {
  match language.tables.lookahead_symbols(state_id) {
    Some(symbols) => {
      self.language = language
      self.state_id = state_id
      self.symbols = symbols
      self.index = -1
      true
    }
    None => false
  }
}

///|
pub fn LookaheadIterator::next(self : LookaheadIterator) -> Bool {
  let next_index = self.index + 1
  if next_index < self.symbols.length() {
    self.index = next_index
    true
  } else {
    false
  }
}

///|
pub fn LookaheadIterator::current_symbol(
  self : LookaheadIterator,
) -> @api.SymbolId {
  if self.index >= 0 && self.index < self.symbols.length() {
    self.symbols[self.index]
  } else {
    @api.SymbolId::new(0)
  }
}

///|
pub fn LookaheadIterator::current_symbol_name(
  self : LookaheadIterator,
) -> String? {
  if self.index < 0 {
    Some("ERROR")
  } else {
    self.language.symbol_name(self.current_symbol())
  }
}
