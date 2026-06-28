///|
let native_abi_version = 15

///|
pub fn target_abi_version() -> Int {
  native_abi_version
}

///|
let lex_state_none_value = 65535

///|
let decode_error_codepoint_value = -1

///|
pub fn lex_state_none() -> Int {
  lex_state_none_value
}

///|
pub(all) struct GeneratedLexMode {
  lex_state : Int
  external_lex_state : Int
  reserved_word_set_id : Int
} derive(Eq, Debug)

///|
pub fn GeneratedLexMode::new(
  lex_state? : Int = lex_state_none_value,
  external_lex_state? : Int = 0,
  reserved_word_set_id? : Int = 0,
) -> GeneratedLexMode {
  { lex_state, external_lex_state, reserved_word_set_id }
}

///|
pub(all) struct GeneratedCharacterRange {
  start : Int
  end : Int
} derive(Eq, Debug)

///|
pub fn GeneratedCharacterRange::new(
  start~ : Int,
  end~ : Int,
) -> GeneratedCharacterRange {
  { start, end }
}

///|
pub(all) struct GeneratedLexTransition {
  ranges : Array[GeneratedCharacterRange]
  target_state : Int
  is_separator : Bool
  precedence : Int
} derive(Eq, Debug)

///|
pub fn GeneratedLexTransition::new(
  ranges? : Array[GeneratedCharacterRange] = [],
  target_state~ : Int,
  is_separator? : Bool = false,
  precedence? : Int = 0,
) -> GeneratedLexTransition {
  { ranges, target_state, is_separator, precedence }
}

///|
pub(all) struct GeneratedLexState {
  accept_symbol_id : Int?
  eof_action : Int?
  transitions : Array[GeneratedLexTransition]
} derive(Eq, Debug)

///|
pub fn GeneratedLexState::new(
  accept_symbol_id? : Int? = None,
  eof_action? : Int? = None,
  transitions? : Array[GeneratedLexTransition] = [],
) -> GeneratedLexState {
  { accept_symbol_id, eof_action, transitions }
}

///|
pub(all) struct GeneratedLexTable {
  states : Array[GeneratedLexState]
  start_state : Int
} derive(Eq, Debug)

///|
pub fn GeneratedLexTable::new(
  states? : Array[GeneratedLexState] = [],
  start_state? : Int = 0,
) -> GeneratedLexTable {
  { states, start_state }
}

///|
pub(all) enum GeneratedParseAction {
  Accept
  Recover
  Shift(state_id~ : Int, is_repetition~ : Bool)
  ShiftExtra
  Reduce(
    symbol_id~ : Int,
    child_count~ : Int,
    dynamic_precedence~ : Int,
    production_id~ : Int
  )
} derive(Eq, Debug)

///|
pub(all) struct GeneratedParseActionList {
  actions : Array[GeneratedParseAction]
  reusable : Bool
} derive(Eq, Debug)

///|
pub fn GeneratedParseActionList::new(
  actions? : Array[GeneratedParseAction] = [],
  reusable? : Bool = false,
) -> GeneratedParseActionList {
  { actions, reusable }
}

///|
pub(all) enum GeneratedParseTableCell {
  EmptyCell
  ActionCell(Int)
  StateCell(Int)
} derive(Eq, Debug)

///|
pub(all) enum GeneratedSmallParseTableSectionKind {
  SmallAction
  SmallState
} derive(Eq, Debug)

///|
pub(all) struct GeneratedSmallParseTableSection {
  kind : GeneratedSmallParseTableSectionKind
  value : Int
  symbols : Array[Int]
} derive(Eq, Debug)

///|
pub fn GeneratedSmallParseTableSection::new(
  kind~ : GeneratedSmallParseTableSectionKind,
  value~ : Int,
  symbols? : Array[Int] = [],
) -> GeneratedSmallParseTableSection {
  { kind, value, symbols }
}

///|
pub(all) struct GeneratedSmallParseTableRow {
  state_id : Int
  offset : Int
  sections : Array[GeneratedSmallParseTableSection]
} derive(Eq, Debug)

///|
pub fn GeneratedSmallParseTableRow::new(
  state_id~ : Int,
  offset~ : Int,
  sections? : Array[GeneratedSmallParseTableSection] = [],
) -> GeneratedSmallParseTableRow {
  { state_id, offset, sections }
}

///|
pub(all) struct GeneratedTokenSet {
  symbol_ids : Array[Int]
} derive(Eq, Debug)

///|
pub fn GeneratedTokenSet::new(
  symbol_ids? : Array[Int] = [],
) -> GeneratedTokenSet {
  { symbol_ids, }
}

///|
pub(all) struct GeneratedSupertypeEntry {
  symbol_id : Int
  subtype_symbol_ids : Array[Int]
} derive(Eq, Debug)

///|
pub fn GeneratedSupertypeEntry::new(
  symbol_id~ : Int,
  subtype_symbol_ids? : Array[Int] = [],
) -> GeneratedSupertypeEntry {
  { symbol_id, subtype_symbol_ids }
}

///|
pub(all) struct GeneratedExternalLexState {
  external_token_ids : Array[Int]
} derive(Eq, Debug)

///|
pub fn GeneratedExternalLexState::new(
  external_token_ids? : Array[Int] = [],
) -> GeneratedExternalLexState {
  { external_token_ids, }
}

///|
pub(all) struct GeneratedAlias {
  value : String
  named : Bool
} derive(Eq, Debug)

///|
pub fn GeneratedAlias::new(value~ : String, named~ : Bool) -> GeneratedAlias {
  { value, named }
}

///|
pub(all) struct GeneratedDefaultAlias {
  symbol_id : Int
  value : String
  named : Bool
} derive(Eq, Debug)

///|
pub fn GeneratedDefaultAlias::new(
  symbol_id~ : Int,
  value~ : String,
  named~ : Bool,
) -> GeneratedDefaultAlias {
  { symbol_id, value, named }
}

///|
pub(all) struct GeneratedNonTerminalAliasEntry {
  symbol_id : Int
  public_symbol_id : Int
  alias_symbol_ids : Array[Int]
} derive(Eq, Debug)

///|
pub fn GeneratedNonTerminalAliasEntry::new(
  symbol_id~ : Int,
  public_symbol_id~ : Int,
  alias_symbol_ids? : Array[Int] = [],
) -> GeneratedNonTerminalAliasEntry {
  { symbol_id, public_symbol_id, alias_symbol_ids }
}

///|
pub(all) struct GeneratedFieldLocation {
  index : Int
  inherited : Bool
} derive(Eq, Debug)

///|
pub fn GeneratedFieldLocation::new(
  index~ : Int,
  inherited~ : Bool,
) -> GeneratedFieldLocation {
  { index, inherited }
}

///|
pub(all) struct GeneratedFieldMapEntry {
  field_id : Int
  locations : Array[GeneratedFieldLocation]
} derive(Eq, Debug)

///|
pub fn GeneratedFieldMapEntry::new(
  field_id~ : Int,
  locations? : Array[GeneratedFieldLocation] = [],
) -> GeneratedFieldMapEntry {
  { field_id, locations }
}

///|
pub(all) struct GeneratedProductionInfo {
  alias_sequence : Array[GeneratedAlias?]
  field_map : Array[GeneratedFieldMapEntry]
} derive(Eq, Debug)

///|
pub fn GeneratedProductionInfo::new(
  alias_sequence? : Array[GeneratedAlias?] = [],
  field_map? : Array[GeneratedFieldMapEntry] = [],
) -> GeneratedProductionInfo {
  { alias_sequence, field_map }
}

///|
pub(all) struct GeneratedLanguageTables {
  abi_version : Int
  name : String
  metadata : LanguageMetadata
  symbol_count : Int
  alias_count : Int
  token_count : Int
  external_token_count : Int
  state_count : Int
  field_count : Int
  production_id_count : Int
  max_alias_sequence_length : Int
  supertype_count : Int
  main_lex_state_count : Int
  external_lex_state_count : Int
  reserved_word_set_count : Int
  max_reserved_word_set_size : Int
  large_state_count : Int
  keyword_capture_token : Int?
  symbol_names : Array[String]
  symbol_types : Array[@api.SymbolType]
  public_symbol_map : Array[Int]
  alias_symbols : Array[GeneratedAlias]
  non_terminal_aliases : Array[GeneratedNonTerminalAliasEntry]
  field_names : Array[String]
  lex_modes : Array[GeneratedLexMode]
  primary_state_ids : Array[Int]
  parse_action_lists : Array[GeneratedParseActionList]
  large_parse_table : Array[Array[GeneratedParseTableCell]]
  small_parse_table : Array[GeneratedSmallParseTableRow]
  small_parse_table_map : Array[Int]
  default_aliases : Array[GeneratedDefaultAlias]
  supertype_entries : Array[GeneratedSupertypeEntry]
  reserved_word_sets : Array[GeneratedTokenSet]
  external_lex_states : Array[GeneratedExternalLexState]
  external_scanner : ExternalScannerDescriptor
  production_infos : Array[GeneratedProductionInfo]
  main_lex_tables : Array[GeneratedLexTable]
  keyword_lex_table : GeneratedLexTable?
} derive(Eq, Debug)

///|
pub fn GeneratedLanguageTables::new(
  name~ : String,
  abi_version? : Int = native_abi_version,
  metadata? : LanguageMetadata = LanguageMetadata::zero(),
  symbol_count? : Int = 0,
  alias_count? : Int = 0,
  token_count? : Int = 0,
  external_token_count? : Int = 0,
  state_count? : Int = 0,
  field_count? : Int = 0,
  production_id_count? : Int = 0,
  max_alias_sequence_length? : Int = 0,
  supertype_count? : Int = 0,
  main_lex_state_count? : Int = 0,
  external_lex_state_count? : Int = 1,
  reserved_word_set_count? : Int = 1,
  max_reserved_word_set_size? : Int = 0,
  large_state_count? : Int = 0,
  keyword_capture_token? : Int? = None,
  symbol_names? : Array[String] = [],
  symbol_types? : Array[@api.SymbolType] = [],
  public_symbol_map? : Array[Int] = [],
  alias_symbols? : Array[GeneratedAlias] = [],
  non_terminal_aliases? : Array[GeneratedNonTerminalAliasEntry] = [],
  field_names? : Array[String] = [""],
  lex_modes? : Array[GeneratedLexMode] = [],
  primary_state_ids? : Array[Int] = [],
  parse_action_lists? : Array[GeneratedParseActionList] = [],
  large_parse_table? : Array[Array[GeneratedParseTableCell]] = [],
  small_parse_table? : Array[GeneratedSmallParseTableRow] = [],
  small_parse_table_map? : Array[Int] = [],
  default_aliases? : Array[GeneratedDefaultAlias] = [],
  supertype_entries? : Array[GeneratedSupertypeEntry] = [],
  reserved_word_sets? : Array[GeneratedTokenSet] = [GeneratedTokenSet::new()],
  external_lex_states? : Array[GeneratedExternalLexState] = [
    GeneratedExternalLexState::new(),
  ],
  external_scanner? : ExternalScannerDescriptor = ExternalScannerDescriptor::none(),
  production_infos? : Array[GeneratedProductionInfo] = [],
  main_lex_tables? : Array[GeneratedLexTable] = [],
  keyword_lex_table? : GeneratedLexTable? = None,
) -> GeneratedLanguageTables {
  let public_symbol_map = if public_symbol_map.length() == 0 && symbol_count > 0 {
    generated_identity_public_symbol_map(symbol_count)
  } else {
    public_symbol_map
  }
  {
    abi_version,
    name,
    metadata,
    symbol_count,
    alias_count,
    token_count,
    external_token_count,
    state_count,
    field_count,
    production_id_count,
    max_alias_sequence_length,
    supertype_count,
    main_lex_state_count,
    external_lex_state_count,
    reserved_word_set_count,
    max_reserved_word_set_size,
    large_state_count,
    keyword_capture_token,
    symbol_names,
    symbol_types,
    public_symbol_map,
    alias_symbols,
    non_terminal_aliases,
    field_names,
    lex_modes,
    primary_state_ids,
    parse_action_lists,
    large_parse_table,
    small_parse_table,
    small_parse_table_map,
    default_aliases,
    supertype_entries,
    reserved_word_sets,
    external_lex_states,
    external_scanner,
    production_infos,
    main_lex_tables,
    keyword_lex_table,
  }
}

///|
fn generated_identity_public_symbol_map(symbol_count : Int) -> Array[Int] {
  let ids : Array[Int] = []
  for i in 0..<symbol_count {
    ids.push(i)
  }
  ids
}

///|
struct ValidatedLanguageTables {
  raw : GeneratedLanguageTables
} derive(Eq, Debug)

///|
pub(all) suberror TableValidationError {
  UnsupportedAbi(Int)
  EmptyLanguageName
  NegativeCount(field~ : String, value~ : Int)
  InvalidLength(field~ : String, expected~ : Int, actual~ : Int)
  InvalidId(field~ : String, value~ : Int, min~ : Int, max~ : Int)
  InvalidFieldZero(String)
} derive(Eq, Debug)

///|
pub fn validate(
  tables : GeneratedLanguageTables,
) -> ValidatedLanguageTables raise TableValidationError {
  if tables.abi_version != native_abi_version {
    raise TableValidationError::UnsupportedAbi(tables.abi_version)
  }
  if tables.name.is_empty() {
    raise TableValidationError::EmptyLanguageName
  }
  validate_non_negative("symbol_count", tables.symbol_count)
  validate_non_negative("alias_count", tables.alias_count)
  validate_non_negative("token_count", tables.token_count)
  validate_non_negative("external_token_count", tables.external_token_count)
  validate_non_negative("state_count", tables.state_count)
  validate_non_negative("field_count", tables.field_count)
  validate_non_negative("production_id_count", tables.production_id_count)
  validate_non_negative(
    "max_alias_sequence_length",
    tables.max_alias_sequence_length,
  )
  validate_non_negative("supertype_count", tables.supertype_count)
  validate_non_negative("main_lex_state_count", tables.main_lex_state_count)
  validate_non_negative(
    "max_reserved_word_set_size",
    tables.max_reserved_word_set_size,
  )
  validate_range(
    "large_state_count",
    tables.large_state_count,
    0,
    tables.state_count,
  )
  validate_range(
    "external_lex_state_count",
    tables.external_lex_state_count,
    1,
    int_index_max(),
  )
  validate_range(
    "reserved_word_set_count",
    tables.reserved_word_set_count,
    1,
    int_index_max(),
  )
  validate_length(
    "symbol_names",
    tables.symbol_count,
    tables.symbol_names.length(),
  )
  validate_length(
    "symbol_types",
    tables.symbol_count,
    tables.symbol_types.length(),
  )
  validate_public_symbol_metadata(tables)
  validate_length(
    "field_names",
    tables.field_count + 1,
    tables.field_names.length(),
  )
  match tables.field_names.get(0) {
    Some("") => ()
    Some(name) => raise TableValidationError::InvalidFieldZero(name)
    None => raise TableValidationError::InvalidFieldZero("<missing>")
  }
  validate_length("lex_modes", tables.state_count, tables.lex_modes.length())
  validate_length(
    "primary_state_ids",
    tables.state_count,
    tables.primary_state_ids.length(),
  )
  for i in 0..<tables.lex_modes.length() {
    validate_lex_mode(tables, i, tables.lex_modes[i])
  }
  for i in 0..<tables.primary_state_ids.length() {
    validate_range(
      "primary_state_ids[\{i}]",
      tables.primary_state_ids[i],
      0,
      tables.state_count - 1,
    )
  }
  for i in 0..<tables.parse_action_lists.length() {
    validate_parse_action_list(tables, i, tables.parse_action_lists[i])
  }
  validate_parse_table_layout(tables)
  validate_supertype_entries(tables)
  validate_token_set_rows(tables)
  validate_external_scanner(tables)
  validate_production_infos(tables)
  validate_lex_tables(tables)
  validate_keyword_lex_table(tables)
  { raw: tables }
}

///|
fn validate_non_negative(
  field : String,
  value : Int,
) -> Unit raise TableValidationError {
  if value < 0 {
    raise TableValidationError::NegativeCount(field~, value~)
  }
}

///|
fn validate_length(
  field : String,
  expected : Int,
  actual : Int,
) -> Unit raise TableValidationError {
  if expected != actual {
    raise TableValidationError::InvalidLength(field~, expected~, actual~)
  }
}

///|
fn validate_range(
  field : String,
  value : Int,
  min : Int,
  max : Int,
) -> Unit raise TableValidationError {
  if value < min || value > max {
    raise TableValidationError::InvalidId(field~, value~, min~, max~)
  }
}

///|
fn validate_lex_mode(
  tables : GeneratedLanguageTables,
  index : Int,
  mode : GeneratedLexMode,
) -> Unit raise TableValidationError {
  if mode.lex_state != lex_state_none_value {
    validate_range(
      "lex_modes[\{index}].lex_state",
      mode.lex_state,
      0,
      tables.main_lex_state_count - 1,
    )
  }
  validate_range(
    "lex_modes[\{index}].external_lex_state",
    mode.external_lex_state,
    0,
    tables.external_lex_state_count - 1,
  )
  validate_range(
    "lex_modes[\{index}].reserved_word_set_id",
    mode.reserved_word_set_id,
    0,
    tables.reserved_word_set_count - 1,
  )
}

///|
fn validate_lex_tables(
  tables : GeneratedLanguageTables,
) -> Unit raise TableValidationError {
  validate_length(
    "main_lex_tables",
    tables.main_lex_state_count,
    tables.main_lex_tables.length(),
  )
  for i in 0..<tables.main_lex_tables.length() {
    validate_lex_table(
      tables,
      "main_lex_tables[\{i}]",
      tables.main_lex_tables[i],
    )
  }
}

///|
fn validate_lex_table(
  tables : GeneratedLanguageTables,
  field : String,
  table : GeneratedLexTable,
) -> Unit raise TableValidationError {
  if table.states.length() == 0 {
    validate_range("\{field}.start_state", table.start_state, 0, -1)
  } else {
    validate_range(
      "\{field}.start_state",
      table.start_state,
      0,
      table.states.length() - 1,
    )
  }
  for i in 0..<table.states.length() {
    validate_lex_state(tables, field, table, i, table.states[i])
  }
}

///|
fn validate_lex_state(
  tables : GeneratedLanguageTables,
  table_field : String,
  table : GeneratedLexTable,
  state_index : Int,
  state : GeneratedLexState,
) -> Unit raise TableValidationError {
  match state.accept_symbol_id {
    Some(symbol_id) =>
      validate_range(
        "\{table_field}.states[\{state_index}].accept_symbol_id",
        symbol_id,
        0,
        tables.symbol_count - 1,
      )
    None => ()
  }
  match state.eof_action {
    Some(target) =>
      validate_range(
        "\{table_field}.states[\{state_index}].eof_action",
        target,
        0,
        table.states.length() - 1,
      )
    None => ()
  }
  for i in 0..<state.transitions.length() {
    validate_lex_transition(
      "\{table_field}.states[\{state_index}].transitions[\{i}]",
      table,
      state.transitions[i],
    )
  }
}

///|
fn validate_keyword_lex_table(
  tables : GeneratedLanguageTables,
) -> Unit raise TableValidationError {
  match (tables.keyword_capture_token, tables.keyword_lex_table) {
    (Some(symbol_id), Some(table)) => {
      validate_range(
        "keyword_capture_token",
        symbol_id,
        0,
        tables.symbol_count - 1,
      )
      validate_lex_table(tables, "keyword_lex_table", table)
    }
    (None, None) => ()
    (Some(_), None) =>
      raise TableValidationError::InvalidLength(
        field="keyword_lex_table",
        expected=1,
        actual=0,
      )
    (None, Some(_)) =>
      raise TableValidationError::InvalidLength(
        field="keyword_capture_token",
        expected=1,
        actual=0,
      )
  }
}

///|
fn validate_lex_transition(
  field : String,
  table : GeneratedLexTable,
  transition : GeneratedLexTransition,
) -> Unit raise TableValidationError {
  validate_range(
    "\{field}.target_state",
    transition.target_state,
    0,
    table.states.length() - 1,
  )
  for i in 0..<transition.ranges.length() {
    validate_character_range("\{field}.ranges[\{i}]", transition.ranges[i])
  }
}

///|
fn validate_character_range(
  field : String,
  range : GeneratedCharacterRange,
) -> Unit raise TableValidationError {
  if range.start == decode_error_codepoint_value &&
    range.end == decode_error_codepoint_value {
    return
  }
  validate_range("\{field}.start", range.start, 0, unicode_scalar_max_int())
  validate_range("\{field}.end", range.end, 0, unicode_scalar_max_int())
  if range.start > range.end {
    raise TableValidationError::InvalidId(
      field="\{field}.end",
      value=range.end,
      min=range.start,
      max=unicode_scalar_max_int(),
    )
  }
}

///|
fn validate_parse_action_list(
  tables : GeneratedLanguageTables,
  index : Int,
  action_list : GeneratedParseActionList,
) -> Unit raise TableValidationError {
  validate_range(
    "parse_action_lists[\{index}].action_count",
    action_list.actions.length(),
    0,
    u8_max(),
  )
  for i in 0..<action_list.actions.length() {
    validate_parse_action(
      tables,
      "parse_action_lists[\{index}].actions[\{i}]",
      action_list.actions[i],
    )
  }
}

///|
fn validate_parse_action(
  tables : GeneratedLanguageTables,
  field : String,
  action : GeneratedParseAction,
) -> Unit raise TableValidationError {
  match action {
    Accept | Recover | ShiftExtra => ()
    Shift(state_id~, ..) =>
      validate_range("\{field}.state_id", state_id, 0, tables.state_count - 1)
    Reduce(symbol_id~, child_count~, dynamic_precedence~, production_id~) => {
      validate_range(
        "\{field}.symbol_id",
        symbol_id,
        0,
        tables.symbol_count - 1,
      )
      validate_range("\{field}.child_count", child_count, 0, u8_max())
      validate_range(
        "\{field}.dynamic_precedence",
        dynamic_precedence,
        i16_min(),
        i16_max(),
      )
      validate_range("\{field}.production_id", production_id, 0, u16_max())
    }
  }
}

///|
fn validate_parse_table_layout(
  tables : GeneratedLanguageTables,
) -> Unit raise TableValidationError {
  validate_length(
    "large_parse_table",
    tables.large_state_count,
    tables.large_parse_table.length(),
  )
  for i in 0..<tables.large_parse_table.length() {
    validate_length(
      "large_parse_table[\{i}]",
      tables.symbol_count,
      tables.large_parse_table[i].length(),
    )
    for j in 0..<tables.large_parse_table[i].length() {
      validate_parse_table_cell(
        tables,
        "large_parse_table[\{i}][\{j}]",
        tables.large_parse_table[i][j],
      )
    }
  }
  let small_state_count = tables.state_count - tables.large_state_count
  validate_length(
    "small_parse_table_map",
    small_state_count,
    tables.small_parse_table_map.length(),
  )
  validate_length(
    "small_parse_table",
    small_state_count,
    tables.small_parse_table.length(),
  )
  for i in 0..<tables.small_parse_table_map.length() {
    validate_range(
      "small_parse_table_map[\{i}]",
      tables.small_parse_table_map[i],
      0,
      int_index_max(),
    )
  }
  for i in 0..<tables.small_parse_table.length() {
    let expected_state_id = tables.large_state_count + i
    validate_range(
      "small_parse_table[\{i}].state_id",
      tables.small_parse_table[i].state_id,
      expected_state_id,
      expected_state_id,
    )
    validate_range(
      "small_parse_table[\{i}].offset",
      tables.small_parse_table[i].offset,
      tables.small_parse_table_map[i],
      tables.small_parse_table_map[i],
    )
    validate_small_parse_table_row(tables, i, tables.small_parse_table[i])
  }
}

///|
fn validate_supertype_entries(
  tables : GeneratedLanguageTables,
) -> Unit raise TableValidationError {
  validate_length(
    "supertype_entries",
    tables.supertype_count,
    tables.supertype_entries.length(),
  )
  for i in 0..<tables.supertype_entries.length() {
    let entry = tables.supertype_entries[i]
    validate_range(
      "supertype_entries[\{i}].symbol_id",
      entry.symbol_id,
      0,
      tables.symbol_count - 1,
    )
    match tables.symbol_types.get(entry.symbol_id) {
      Some(@api.SymbolType::Supertype) => ()
      _ =>
        raise TableValidationError::InvalidId(
          field="supertype_entries[\{i}].symbol_id",
          value=entry.symbol_id,
          min=0,
          max=-1,
        )
    }
    for j in 0..<entry.subtype_symbol_ids.length() {
      validate_range(
        "supertype_entries[\{i}].subtype_symbol_ids[\{j}]",
        entry.subtype_symbol_ids[j],
        0,
        tables.symbol_count - 1,
      )
    }
  }
}

///|
fn validate_public_symbol_metadata(
  tables : GeneratedLanguageTables,
) -> Unit raise TableValidationError {
  validate_length(
    "public_symbol_map",
    tables.symbol_count,
    tables.public_symbol_map.length(),
  )
  validate_length(
    "alias_symbols",
    tables.alias_count,
    tables.alias_symbols.length(),
  )
  let public_symbol_count = tables.symbol_count + tables.alias_count
  for i in 0..<tables.public_symbol_map.length() {
    validate_range(
      "public_symbol_map[\{i}]",
      tables.public_symbol_map[i],
      0,
      public_symbol_count - 1,
    )
  }
  for i in 0..<tables.non_terminal_aliases.length() {
    validate_non_terminal_alias_entry(tables, i, tables.non_terminal_aliases[i])
  }
}

///|
fn validate_non_terminal_alias_entry(
  tables : GeneratedLanguageTables,
  index : Int,
  entry : GeneratedNonTerminalAliasEntry,
) -> Unit raise TableValidationError {
  let public_symbol_count = tables.symbol_count + tables.alias_count
  validate_range(
    "non_terminal_aliases[\{index}].symbol_id",
    entry.symbol_id,
    0,
    tables.symbol_count - 1,
  )
  validate_range(
    "non_terminal_aliases[\{index}].public_symbol_id",
    entry.public_symbol_id,
    0,
    public_symbol_count - 1,
  )
  for i in 0..<entry.alias_symbol_ids.length() {
    validate_range(
      "non_terminal_aliases[\{index}].alias_symbol_ids[\{i}]",
      entry.alias_symbol_ids[i],
      0,
      public_symbol_count - 1,
    )
  }
}

///|
fn validate_token_set_rows(
  tables : GeneratedLanguageTables,
) -> Unit raise TableValidationError {
  validate_length(
    "reserved_word_sets",
    tables.reserved_word_set_count,
    tables.reserved_word_sets.length(),
  )
  validate_length(
    "external_lex_states",
    tables.external_lex_state_count,
    tables.external_lex_states.length(),
  )
  if tables.reserved_word_sets.length() > 0 {
    validate_length(
      "reserved_word_sets[0].symbol_ids",
      0,
      tables.reserved_word_sets[0].symbol_ids.length(),
    )
  }
  if tables.external_lex_states.length() > 0 {
    validate_length(
      "external_lex_states[0].external_token_ids",
      0,
      tables.external_lex_states[0].external_token_ids.length(),
    )
  }
  for i in 0..<tables.reserved_word_sets.length() {
    validate_generated_token_set(tables, i, tables.reserved_word_sets[i])
  }
  for i in 0..<tables.external_lex_states.length() {
    validate_generated_external_lex_state(
      tables,
      i,
      tables.external_lex_states[i],
    )
  }
}

///|
fn validate_generated_token_set(
  tables : GeneratedLanguageTables,
  index : Int,
  set : GeneratedTokenSet,
) -> Unit raise TableValidationError {
  validate_range(
    "reserved_word_sets[\{index}].symbol_count",
    set.symbol_ids.length(),
    0,
    tables.max_reserved_word_set_size,
  )
  for i in 0..<set.symbol_ids.length() {
    validate_range(
      "reserved_word_sets[\{index}].symbol_ids[\{i}]",
      set.symbol_ids[i],
      0,
      tables.symbol_count - 1,
    )
  }
}

///|
fn validate_generated_external_lex_state(
  tables : GeneratedLanguageTables,
  index : Int,
  state : GeneratedExternalLexState,
) -> Unit raise TableValidationError {
  validate_range(
    "external_lex_states[\{index}].external_token_count",
    state.external_token_ids.length(),
    0,
    tables.external_token_count,
  )
  for i in 0..<state.external_token_ids.length() {
    validate_range(
      "external_lex_states[\{index}].external_token_ids[\{i}]",
      state.external_token_ids[i],
      0,
      tables.external_token_count - 1,
    )
  }
}

///|
fn validate_external_scanner(
  tables : GeneratedLanguageTables,
) -> Unit raise TableValidationError {
  validate_range(
    "external_scanner.external_token_count",
    tables.external_scanner.external_token_count,
    0,
    int_index_max(),
  )
  validate_range(
    "external_scanner.external_state_count",
    tables.external_scanner.external_state_count,
    0,
    int_index_max(),
  )
  validate_range(
    "external_scanner.external_token_count",
    tables.external_scanner.external_token_count,
    tables.external_token_count,
    tables.external_token_count,
  )
  let expected_state_count = if tables.external_token_count == 0 {
    0
  } else {
    tables.external_lex_state_count
  }
  validate_range(
    "external_scanner.external_state_count",
    tables.external_scanner.external_state_count,
    expected_state_count,
    expected_state_count,
  )
  validate_length(
    "external_scanner.states",
    tables.external_scanner.external_state_count,
    tables.external_scanner.states.length(),
  )
  validate_length(
    "external_scanner.symbol_map",
    tables.external_token_count,
    tables.external_scanner.symbol_map.length(),
  )
  for i in 0..<tables.external_scanner.states.length() {
    validate_length(
      "external_scanner.states[\{i}]",
      tables.external_token_count,
      tables.external_scanner.states[i].length(),
    )
    for j in 0..<tables.external_scanner.states[i].length() {
      if i == 0 && tables.external_scanner.states[i][j] {
        raise TableValidationError::InvalidId(
          field="external_scanner.states[0][\{j}]",
          value=1,
          min=0,
          max=0,
        )
      }
    }
  }
  for i in 0..<tables.external_scanner.symbol_map.length() {
    validate_range(
      "external_scanner.symbol_map[\{i}]",
      tables.external_scanner.symbol_map[i],
      0,
      tables.symbol_count - 1,
    )
  }
}

///|
fn validate_production_infos(
  tables : GeneratedLanguageTables,
) -> Unit raise TableValidationError {
  validate_length(
    "production_infos",
    tables.production_id_count,
    tables.production_infos.length(),
  )
  for i in 0..<tables.production_infos.length() {
    validate_production_info(tables, i, tables.production_infos[i])
  }
  for i in 0..<tables.default_aliases.length() {
    validate_default_alias(tables, i, tables.default_aliases[i])
  }
}

///|
fn validate_default_alias(
  tables : GeneratedLanguageTables,
  index : Int,
  default_alias : GeneratedDefaultAlias,
) -> Unit raise TableValidationError {
  validate_range(
    "default_aliases[\{index}].symbol_id",
    default_alias.symbol_id,
    0,
    tables.symbol_count - 1,
  )
}

///|
fn validate_production_info(
  tables : GeneratedLanguageTables,
  index : Int,
  info : GeneratedProductionInfo,
) -> Unit raise TableValidationError {
  validate_range(
    "production_infos[\{index}].alias_sequence_length",
    info.alias_sequence.length(),
    0,
    tables.max_alias_sequence_length,
  )
  for i in 0..<info.field_map.length() {
    validate_field_map_entry(
      tables,
      "production_infos[\{index}].field_map[\{i}]",
      info.field_map[i],
    )
  }
}

///|
fn validate_field_map_entry(
  tables : GeneratedLanguageTables,
  field : String,
  entry : GeneratedFieldMapEntry,
) -> Unit raise TableValidationError {
  validate_range("\{field}.field_id", entry.field_id, 1, tables.field_count)
  validate_range(
    "\{field}.location_count",
    entry.locations.length(),
    0,
    u16_max(),
  )
  for i in 0..<entry.locations.length() {
    validate_range(
      "\{field}.locations[\{i}].index",
      entry.locations[i].index,
      0,
      u8_max(),
    )
  }
}

///|
fn validate_parse_table_cell(
  tables : GeneratedLanguageTables,
  field : String,
  cell : GeneratedParseTableCell,
) -> Unit raise TableValidationError {
  match cell {
    EmptyCell => ()
    ActionCell(action_id) =>
      validate_range(
        "\{field}.action_id",
        action_id,
        1,
        tables.parse_action_lists.length() - 1,
      )
    StateCell(state_id) =>
      validate_range("\{field}.state_id", state_id, 0, tables.state_count - 1)
  }
}

///|
fn validate_small_parse_table_row(
  tables : GeneratedLanguageTables,
  index : Int,
  row : GeneratedSmallParseTableRow,
) -> Unit raise TableValidationError {
  validate_range(
    "small_parse_table[\{index}].state_id",
    row.state_id,
    0,
    tables.state_count - 1,
  )
  validate_range(
    "small_parse_table[\{index}].offset",
    row.offset,
    0,
    int_index_max(),
  )
  validate_range(
    "small_parse_table[\{index}].section_count",
    row.sections.length(),
    0,
    u16_max(),
  )
  for i in 0..<row.sections.length() {
    validate_small_parse_table_section(
      tables,
      "small_parse_table[\{index}].sections[\{i}]",
      row.sections[i],
    )
  }
}

///|
fn validate_small_parse_table_section(
  tables : GeneratedLanguageTables,
  field : String,
  section : GeneratedSmallParseTableSection,
) -> Unit raise TableValidationError {
  match section.kind {
    SmallAction =>
      validate_range(
        "\{field}.value",
        section.value,
        1,
        tables.parse_action_lists.length() - 1,
      )
    SmallState =>
      validate_range("\{field}.value", section.value, 0, tables.state_count - 1)
  }
  validate_range(
    "\{field}.symbol_count",
    section.symbols.length(),
    0,
    u16_max(),
  )
  for i in 0..<section.symbols.length() {
    validate_range(
      "\{field}.symbols[\{i}]",
      section.symbols[i],
      0,
      tables.symbol_count - 1,
    )
  }
}

///|
fn u8_max() -> Int {
  255
}

///|
fn i16_min() -> Int {
  -32768
}

///|
fn i16_max() -> Int {
  32767
}

///|
fn u16_max() -> Int {
  65535
}

///|
fn int_index_max() -> Int {
  2147483647
}

///|
fn unicode_scalar_max_int() -> Int {
  1114111
}

///|
pub fn ValidatedLanguageTables::abi_version(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.abi_version
}

///|
pub fn ValidatedLanguageTables::name(self : ValidatedLanguageTables) -> String {
  self.raw.name
}

///|
pub fn ValidatedLanguageTables::metadata(
  self : ValidatedLanguageTables,
) -> LanguageMetadata {
  self.raw.metadata
}

///|
pub fn ValidatedLanguageTables::symbol_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.symbol_count
}

///|
pub fn ValidatedLanguageTables::public_symbol_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.symbol_count + self.raw.alias_count
}

///|
pub fn ValidatedLanguageTables::alias_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.alias_count
}

///|
pub fn ValidatedLanguageTables::public_symbol_for_grammar_symbol(
  self : ValidatedLanguageTables,
  id : @api.SymbolId,
) -> @api.SymbolId? {
  let value = id.value()
  if value >= self.raw.public_symbol_map.length().reinterpret_as_uint() {
    None
  } else {
    Some(
      @api.SymbolId::new(
        self.raw.public_symbol_map[value.reinterpret_as_int()].reinterpret_as_uint(),
      ),
    )
  }
}

///|
pub fn ValidatedLanguageTables::public_symbol_for_alias(
  self : ValidatedLanguageTables,
  alias_info : GeneratedAlias,
) -> @api.SymbolId? {
  let alias_type = generated_alias_symbol_type(alias_info)
  for i in 0..<self.raw.symbol_count {
    if self.raw.symbol_names[i] == alias_info.value &&
      symbol_type_matches_alias(self.raw.symbol_types[i], alias_type) {
      return self.public_symbol_for_grammar_symbol(
        @api.SymbolId::new(i.reinterpret_as_uint()),
      )
    }
  }
  for i in 0..<self.raw.alias_symbols.length() {
    if self.raw.alias_symbols[i] == alias_info {
      return Some(
        @api.SymbolId::new((self.raw.symbol_count + i).reinterpret_as_uint()),
      )
    }
  }
  None
}

///|
fn generated_alias_symbol_type(alias_info : GeneratedAlias) -> @api.SymbolType {
  if alias_info.named {
    @api.SymbolType::Regular
  } else {
    @api.SymbolType::Anonymous
  }
}

///|
fn symbol_type_matches_alias(
  symbol_type : @api.SymbolType,
  alias_type : @api.SymbolType,
) -> Bool {
  match (symbol_type, alias_type) {
    (@api.SymbolType::Supertype, @api.SymbolType::Regular) => true
    _ => symbol_type == alias_type
  }
}

///|
pub fn ValidatedLanguageTables::token_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.token_count
}

///|
pub fn ValidatedLanguageTables::external_token_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.external_token_count
}

///|
pub fn ValidatedLanguageTables::state_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.state_count
}

///|
pub fn ValidatedLanguageTables::field_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.field_count
}

///|
pub fn ValidatedLanguageTables::production_id_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.production_id_count
}

///|
pub fn ValidatedLanguageTables::max_alias_sequence_length(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.max_alias_sequence_length
}

///|
pub fn ValidatedLanguageTables::supertype_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.supertype_count
}

///|
pub fn ValidatedLanguageTables::supertypes(
  self : ValidatedLanguageTables,
) -> Array[@api.SymbolId] {
  let result : Array[@api.SymbolId] = []
  for entry in self.raw.supertype_entries {
    match
      self.public_symbol_for_grammar_symbol(
        @api.SymbolId::new(entry.symbol_id.reinterpret_as_uint()),
      ) {
      Some(symbol) => result.push(symbol)
      None => ()
    }
  }
  result
}

///|
pub fn ValidatedLanguageTables::subtypes(
  self : ValidatedLanguageTables,
  supertype : @api.SymbolId,
) -> Array[@api.SymbolId] {
  let supertype_id = supertype.value().reinterpret_as_int()
  for entry in self.raw.supertype_entries {
    let public_id = self.public_symbol_for_grammar_symbol(
      @api.SymbolId::new(entry.symbol_id.reinterpret_as_uint()),
    )
    if public_id == Some(supertype) || entry.symbol_id == supertype_id {
      let result : Array[@api.SymbolId] = []
      for subtype in entry.subtype_symbol_ids {
        match
          self.public_symbol_for_grammar_symbol(
            @api.SymbolId::new(subtype.reinterpret_as_uint()),
          ) {
          Some(symbol) => result.push(symbol)
          None => ()
        }
      }
      return result
    }
  }
  []
}

///|
pub fn ValidatedLanguageTables::main_lex_state_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.main_lex_state_count
}

///|
pub fn ValidatedLanguageTables::external_lex_state_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.external_lex_state_count
}

///|
pub fn ValidatedLanguageTables::reserved_word_set_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.reserved_word_set_count
}

///|
pub fn ValidatedLanguageTables::max_reserved_word_set_size(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.max_reserved_word_set_size
}

///|
pub fn ValidatedLanguageTables::large_state_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.large_state_count
}

///|
pub fn ValidatedLanguageTables::keyword_capture_token(
  self : ValidatedLanguageTables,
) -> @api.SymbolId? {
  match self.raw.keyword_capture_token {
    Some(value) => Some(@api.SymbolId::new(value.reinterpret_as_uint()))
    None => None
  }
}

///|
pub fn ValidatedLanguageTables::lex_mode(
  self : ValidatedLanguageTables,
  state_id : @api.StateId,
) -> GeneratedLexMode? {
  let value = state_id.value()
  if value >= self.raw.lex_modes.length().reinterpret_as_uint() {
    None
  } else {
    Some(self.raw.lex_modes[value.reinterpret_as_int()])
  }
}

///|
pub fn ValidatedLanguageTables::main_lex_table(
  self : ValidatedLanguageTables,
  lex_state_id : Int,
) -> GeneratedLexTable? {
  if lex_state_id < 0 || lex_state_id >= self.raw.main_lex_tables.length() {
    None
  } else {
    Some(self.raw.main_lex_tables[lex_state_id])
  }
}

///|
pub fn ValidatedLanguageTables::keyword_lex_table(
  self : ValidatedLanguageTables,
) -> GeneratedLexTable? {
  self.raw.keyword_lex_table
}

///|
pub fn ValidatedLanguageTables::primary_state_id(
  self : ValidatedLanguageTables,
  state_id : @api.StateId,
) -> @api.StateId? {
  let value = state_id.value()
  if value >= self.raw.primary_state_ids.length().reinterpret_as_uint() {
    None
  } else {
    Some(
      @api.StateId::new(
        self.raw.primary_state_ids[value.reinterpret_as_int()].reinterpret_as_uint(),
      ),
    )
  }
}

///|
pub fn ValidatedLanguageTables::parse_action_list_count(
  self : ValidatedLanguageTables,
) -> Int {
  self.raw.parse_action_lists.length()
}

///|
pub fn ValidatedLanguageTables::parse_action_list(
  self : ValidatedLanguageTables,
  index : Int,
) -> GeneratedParseActionList? {
  if index < 0 || index >= self.raw.parse_action_lists.length() {
    None
  } else {
    Some(self.raw.parse_action_lists[index])
  }
}

///|
pub fn ValidatedLanguageTables::large_parse_table_cell(
  self : ValidatedLanguageTables,
  state_id : @api.StateId,
  symbol_id : @api.SymbolId,
) -> GeneratedParseTableCell? {
  let state = state_id.value()
  let symbol = symbol_id.value()
  if state >= self.raw.large_parse_table.length().reinterpret_as_uint() {
    None
  } else if symbol >= self.raw.symbol_count.reinterpret_as_uint() {
    None
  } else {
    Some(
      self.raw.large_parse_table[state.reinterpret_as_int()][symbol.reinterpret_as_int()],
    )
  }
}

///|
pub fn ValidatedLanguageTables::parse_table_cell(
  self : ValidatedLanguageTables,
  state_id : @api.StateId,
  symbol_id : @api.SymbolId,
) -> GeneratedParseTableCell? {
  let state = state_id.value()
  let symbol = symbol_id.value()
  if state >= self.raw.state_count.reinterpret_as_uint() ||
    symbol >= self.raw.symbol_count.reinterpret_as_uint() {
    None
  } else if state < self.raw.large_state_count.reinterpret_as_uint() {
    self.large_parse_table_cell(state_id, symbol_id)
  } else {
    let state_index = state.reinterpret_as_int()
    let row_index = state_index - self.raw.large_state_count
    match self.raw.small_parse_table.get(row_index) {
      Some(row) =>
        if row.state_id == state_index {
          Some(small_parse_table_cell(row, symbol.reinterpret_as_int()))
        } else {
          None
        }
      None => None
    }
  }
}

///|
pub fn ValidatedLanguageTables::parse_action_list_for_symbol(
  self : ValidatedLanguageTables,
  state_id : @api.StateId,
  symbol_id : @api.SymbolId,
) -> GeneratedParseActionList? {
  match self.parse_table_cell(state_id, symbol_id) {
    Some(GeneratedParseTableCell::ActionCell(action_id)) =>
      self.parse_action_list(action_id)
    _ => None
  }
}

///|
pub fn ValidatedLanguageTables::lookahead_symbols(
  self : ValidatedLanguageTables,
  state_id : @api.StateId,
) -> Array[@api.SymbolId]? {
  let state = state_id.value()
  if state >= self.raw.state_count.reinterpret_as_uint() {
    return None
  }
  let result : Array[@api.SymbolId] = []
  if state < self.raw.large_state_count.reinterpret_as_uint() {
    for symbol in 0..<self.raw.symbol_count {
      match self.raw.large_parse_table[state.reinterpret_as_int()][symbol] {
        EmptyCell => ()
        ActionCell(_) | StateCell(_) =>
          result.push(@api.SymbolId::new(symbol.reinterpret_as_uint()))
      }
    }
  } else {
    let row_index = state.reinterpret_as_int() - self.raw.large_state_count
    match self.raw.small_parse_table.get(row_index) {
      Some(row) =>
        if row.state_id == state.reinterpret_as_int() {
          for section in row.sections {
            for symbol in section.symbols {
              result.push(@api.SymbolId::new(symbol.reinterpret_as_uint()))
            }
          }
        }
      None => ()
    }
  }
  Some(result)
}

///|
pub fn ValidatedLanguageTables::goto_state_for_symbol(
  self : ValidatedLanguageTables,
  state_id : @api.StateId,
  symbol_id : @api.SymbolId,
) -> @api.StateId? {
  match self.parse_table_cell(state_id, symbol_id) {
    Some(GeneratedParseTableCell::StateCell(state_id)) =>
      Some(@api.StateId::new(state_id.reinterpret_as_uint()))
    _ => None
  }
}

///|
fn small_parse_table_cell(
  row : GeneratedSmallParseTableRow,
  symbol_id : Int,
) -> GeneratedParseTableCell {
  for section in row.sections {
    for symbol in section.symbols {
      if symbol == symbol_id {
        match section.kind {
          GeneratedSmallParseTableSectionKind::SmallAction =>
            return GeneratedParseTableCell::ActionCell(section.value)
          GeneratedSmallParseTableSectionKind::SmallState =>
            return GeneratedParseTableCell::StateCell(section.value)
        }
      }
    }
  }
  GeneratedParseTableCell::EmptyCell
}

///|
pub fn ValidatedLanguageTables::small_parse_table_row(
  self : ValidatedLanguageTables,
  index : Int,
) -> GeneratedSmallParseTableRow? {
  if index < 0 || index >= self.raw.small_parse_table.length() {
    None
  } else {
    Some(self.raw.small_parse_table[index])
  }
}

///|
pub fn ValidatedLanguageTables::small_parse_table_offset(
  self : ValidatedLanguageTables,
  index : Int,
) -> Int? {
  if index < 0 || index >= self.raw.small_parse_table_map.length() {
    None
  } else {
    Some(self.raw.small_parse_table_map[index])
  }
}

///|
pub fn ValidatedLanguageTables::reserved_word_set(
  self : ValidatedLanguageTables,
  index : Int,
) -> GeneratedTokenSet? {
  if index < 0 || index >= self.raw.reserved_word_sets.length() {
    None
  } else {
    Some(self.raw.reserved_word_sets[index])
  }
}

///|
pub fn ValidatedLanguageTables::external_lex_state(
  self : ValidatedLanguageTables,
  index : Int,
) -> GeneratedExternalLexState? {
  if index < 0 || index >= self.raw.external_lex_states.length() {
    None
  } else {
    Some(self.raw.external_lex_states[index])
  }
}

///|
pub fn ValidatedLanguageTables::external_scanner(
  self : ValidatedLanguageTables,
) -> ExternalScannerDescriptor {
  self.raw.external_scanner
}

///|
pub fn ValidatedLanguageTables::production_info(
  self : ValidatedLanguageTables,
  production_id : Int,
) -> GeneratedProductionInfo? {
  if production_id < 0 || production_id >= self.raw.production_infos.length() {
    None
  } else {
    Some(self.raw.production_infos[production_id])
  }
}

///|
pub fn ValidatedLanguageTables::default_alias_for_symbol(
  self : ValidatedLanguageTables,
  id : @api.SymbolId,
) -> GeneratedAlias? {
  let symbol_id = id.value().reinterpret_as_int()
  for default_alias in self.raw.default_aliases {
    if default_alias.symbol_id == symbol_id {
      return Some(
        GeneratedAlias::new(
          value=default_alias.value,
          named=default_alias.named,
        ),
      )
    }
  }
  None
}

///|
pub fn ValidatedLanguageTables::symbol_name(
  self : ValidatedLanguageTables,
  id : @api.SymbolId,
) -> String? {
  let value = id.value()
  if value >= self.public_symbol_count().reinterpret_as_uint() {
    None
  } else if value >= self.raw.symbol_count.reinterpret_as_uint() {
    let alias_index = value.reinterpret_as_int() - self.raw.symbol_count
    match self.raw.alias_symbols.get(alias_index) {
      Some(alias_info) => Some(alias_info.value)
      None => None
    }
  } else {
    Some(self.raw.symbol_names[value.reinterpret_as_int()])
  }
}

///|
pub fn ValidatedLanguageTables::symbol_type(
  self : ValidatedLanguageTables,
  id : @api.SymbolId,
) -> @api.SymbolType? {
  let value = id.value()
  if value >= self.public_symbol_count().reinterpret_as_uint() {
    None
  } else if value >= self.raw.symbol_count.reinterpret_as_uint() {
    let alias_index = value.reinterpret_as_int() - self.raw.symbol_count
    match self.raw.alias_symbols.get(alias_index) {
      Some(alias_info) => Some(generated_alias_symbol_type(alias_info))
      None => None
    }
  } else {
    Some(self.raw.symbol_types[value.reinterpret_as_int()])
  }
}

///|
pub fn ValidatedLanguageTables::field_name_for_id(
  self : ValidatedLanguageTables,
  id : @api.FieldId,
) -> String? {
  let value = id.value()
  if value == 0 || value >= self.raw.field_names.length().reinterpret_as_uint() {
    None
  } else {
    Some(self.raw.field_names[value.reinterpret_as_int()])
  }
}

///|
pub fn ValidatedLanguageTables::field_id_for_name(
  self : ValidatedLanguageTables,
  name : String,
) -> @api.FieldId? {
  if name.is_empty() {
    return None
  }
  for index in 1..<self.raw.field_names.length() {
    if self.raw.field_names[index] == name {
      return Some(@api.FieldId::new(index.reinterpret_as_uint()))
    }
  }
  None
}
