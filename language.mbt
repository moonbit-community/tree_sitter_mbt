///|
struct Language {
  tables : @tables.ValidatedLanguageTables
}

///|
pub fn Language::from_validated_tables(
  tables : @tables.ValidatedLanguageTables,
) -> Language {
  { tables, }
}

///|
pub fn language_from_generated_tables(
  tables : @tables.GeneratedLanguageTables,
) -> Language raise @tables.TableValidationError {
  Language::from_validated_tables(@tables.validate(tables))
}

///|
pub fn Language::abi_version(self : Language) -> Int {
  self.tables.abi_version()
}

///|
pub fn Language::name(self : Language) -> String {
  self.tables.name()
}

///|
pub fn Language::metadata(self : Language) -> @tables.LanguageMetadata {
  self.tables.metadata()
}

///|
pub fn Language::symbol_count(self : Language) -> Int {
  self.tables.symbol_count() + self.tables.alias_count()
}

///|
pub fn Language::token_count(self : Language) -> Int {
  self.tables.token_count()
}

///|
pub fn Language::external_token_count(self : Language) -> Int {
  self.tables.external_token_count()
}

///|
pub fn Language::state_count(self : Language) -> Int {
  self.tables.state_count()
}

///|
pub fn Language::field_count(self : Language) -> Int {
  self.tables.field_count()
}

///|
pub fn Language::symbol_name(self : Language, id : @api.SymbolId) -> String? {
  self.tables.symbol_name(id)
}

///|
pub fn Language::symbol_type(
  self : Language,
  id : @api.SymbolId,
) -> @api.SymbolType? {
  self.tables.symbol_type(id)
}

///|
pub fn Language::supertypes(self : Language) -> Array[@api.SymbolId] {
  self.tables.supertypes()
}

///|
pub fn Language::subtypes(
  self : Language,
  supertype : @api.SymbolId,
) -> Array[@api.SymbolId] {
  self.tables.subtypes(supertype)
}

///|
pub fn Language::symbol_for_name(
  self : Language,
  name : String,
  is_named~ : Bool,
) -> @api.SymbolId? {
  // Intentional divergence from the C API prefix quirk: builtin ERROR only
  // resolves on an exact named lookup.
  if is_named && name == "ERROR" {
    return Some(@api.SymbolId::new(0))
  }
  for i in 0..<self.symbol_count() {
    let symbol_id = @api.SymbolId::new(i.reinterpret_as_uint())
    if self.symbol_name(symbol_id) == Some(name) &&
      symbol_type_matches_lookup(self.symbol_type(symbol_id), is_named~) {
      return Some(symbol_id)
    }
  }
  None
}

///|
pub fn Language::next_state(
  self : Language,
  state_id : @api.StateId,
  grammar_symbol_id : @api.SymbolId,
) -> @api.StateId? {
  match self.symbol_name(grammar_symbol_id) {
    Some("ERROR") | Some("_ERROR") => return Some(@api.StateId::new(0))
    _ => ()
  }
  if grammar_symbol_id.value() >=
    self.tables.symbol_count().reinterpret_as_uint() {
    return None
  }
  if grammar_symbol_id.value() < self.tables.token_count().reinterpret_as_uint() {
    self.next_terminal_state(state_id, grammar_symbol_id)
  } else {
    self.tables.goto_state_for_symbol(state_id, grammar_symbol_id)
  }
}

///|
fn Language::next_terminal_state(
  self : Language,
  state_id : @api.StateId,
  symbol_id : @api.SymbolId,
) -> @api.StateId? {
  match self.tables.parse_action_list_for_symbol(state_id, symbol_id) {
    Some(action_list) => {
      let mut found_shift_extra = false
      let mut next_state : @api.StateId? = None
      for action in action_list.actions {
        match action {
          @tables.GeneratedParseAction::Shift(state_id~, ..) =>
            next_state = Some(@api.StateId::new(state_id.reinterpret_as_uint()))
          @tables.GeneratedParseAction::ShiftExtra => found_shift_extra = true
          _ => ()
        }
      }
      match next_state {
        Some(value) => Some(value)
        None => if found_shift_extra { Some(state_id) } else { None }
      }
    }
    None => None
  }
}

///|
fn symbol_type_matches_lookup(
  symbol_type : @api.SymbolType?,
  is_named~ : Bool,
) -> Bool {
  match symbol_type {
    Some(@api.SymbolType::Regular) | Some(@api.SymbolType::Supertype) =>
      is_named
    Some(@api.SymbolType::Anonymous) => !is_named
    _ => false
  }
}

///|
pub fn Language::field_name_for_id(
  self : Language,
  id : @api.FieldId,
) -> String? {
  self.tables.field_name_for_id(id)
}

///|
pub fn Language::field_id_for_name(
  self : Language,
  name : String,
) -> @api.FieldId? {
  self.tables.field_id_for_name(name)
}
