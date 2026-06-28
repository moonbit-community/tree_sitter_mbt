///|
fn generated_moonbit_sources(
  tables : @tables.GeneratedLanguageTables,
  options : GenerateOptions,
) -> Array[GeneratedSource] {
  [
    { path: "moon.pkg", content: generated_moon_pkg_source(options) },
    {
      path: "language.mbt",
      content: generated_language_mbt_source(tables, options),
    },
  ]
}

///|
fn generated_moon_pkg_source(options : GenerateOptions) -> String {
  let root_import = render_import(
    "moonbit-community/tree_sitter_mbt",
    options.root_alias,
    "tree_sitter_mbt",
  )
  let tables_import = render_import(
    "moonbit-community/tree_sitter_mbt/runtime/tables",
    options.tables_alias,
    "tables",
  )
  let api_import = render_import(
    "moonbit-community/tree_sitter_mbt/api",
    options.api_alias,
    "api",
  )
  [
    "import {",
    "  \{root_import},",
    "  \{tables_import},",
    "  \{api_import},",
    "}",
  ].join("\n")
}

///|
fn render_import(
  path : String,
  import_alias : String,
  default_alias : String,
) -> String {
  if import_alias == default_alias {
    render_string_literal(path)
  } else {
    "\{render_string_literal(path)} @\{import_alias}"
  }
}

///|
fn generated_language_mbt_source(
  tables : @tables.GeneratedLanguageTables,
  options : GenerateOptions,
) -> String {
  let root = options.root_alias
  let table_alias = options.tables_alias
  let lines : Array[String] = []
  lines.push("///|")
  if tables.external_token_count == 0 {
    lines.push(
      "pub fn language() -> @\{root}.Language raise @\{table_alias}.TableValidationError {",
    )
    lines.push(
      "  @\{root}.language_from_generated_tables(generated_language_tables())",
    )
  } else {
    lines.push(
      "pub fn language(scanner : @\{table_alias}.ExternalScannerDescriptor) -> @\{root}.Language raise @\{table_alias}.TableValidationError {",
    )
    lines.push(
      "  @\{root}.language_from_generated_tables(generated_language_tables(external_scanner=scanner))",
    )
  }
  lines.push("}")
  lines.push("")
  lines.push("///|")
  if tables.external_token_count == 0 {
    lines.push(
      "fn generated_language_tables() -> @\{table_alias}.GeneratedLanguageTables {",
    )
  } else {
    lines.push(
      "fn generated_language_tables(external_scanner~ : @\{table_alias}.ExternalScannerDescriptor) -> @\{table_alias}.GeneratedLanguageTables {",
    )
  }
  lines.push(render_generated_language_tables(tables, options, indent="  "))
  lines.push("}")
  lines.join("\n")
}

///|
fn render_generated_language_tables(
  tables : @tables.GeneratedLanguageTables,
  options : GenerateOptions,
  indent~ : String,
) -> String {
  let table_alias = options.tables_alias
  let args : Array[String] = []
  args.push("name=\{render_string_literal(tables.name)}")
  args.push("abi_version=\{tables.abi_version}")
  args.push("metadata=\{render_metadata(tables.metadata, table_alias)}")
  args.push("symbol_count=\{tables.symbol_count}")
  args.push("alias_count=\{tables.alias_count}")
  args.push("token_count=\{tables.token_count}")
  args.push("external_token_count=\{tables.external_token_count}")
  args.push("state_count=\{tables.state_count}")
  args.push("field_count=\{tables.field_count}")
  args.push("production_id_count=\{tables.production_id_count}")
  args.push("max_alias_sequence_length=\{tables.max_alias_sequence_length}")
  args.push("supertype_count=\{tables.supertype_count}")
  args.push("main_lex_state_count=\{tables.main_lex_state_count}")
  args.push("external_lex_state_count=\{tables.external_lex_state_count}")
  args.push("reserved_word_set_count=\{tables.reserved_word_set_count}")
  args.push("max_reserved_word_set_size=\{tables.max_reserved_word_set_size}")
  args.push("large_state_count=\{tables.large_state_count}")
  args.push(
    "keyword_capture_token=\{render_int_option(tables.keyword_capture_token)}",
  )
  args.push("symbol_names=\{render_string_array(tables.symbol_names)}")
  args.push(
    "symbol_types=\{render_symbol_type_array(tables.symbol_types, options.api_alias)}",
  )
  args.push("public_symbol_map=\{render_int_array(tables.public_symbol_map)}")
  args.push(
    "alias_symbols=\{render_alias_array(tables.alias_symbols, table_alias)}",
  )
  args.push(
    "non_terminal_aliases=\{render_non_terminal_alias_entry_array(tables.non_terminal_aliases, table_alias)}",
  )
  args.push("field_names=\{render_string_array(tables.field_names)}")
  args.push("lex_modes=\{render_lex_mode_array(tables.lex_modes, table_alias)}")
  args.push("primary_state_ids=\{render_int_array(tables.primary_state_ids)}")
  args.push(
    "parse_action_lists=\{render_parse_action_list_array(tables.parse_action_lists, table_alias)}",
  )
  args.push(
    "large_parse_table=\{render_parse_table_cell_matrix(tables.large_parse_table, table_alias)}",
  )
  args.push(
    "small_parse_table=\{render_small_parse_table_row_array(tables.small_parse_table, table_alias)}",
  )
  args.push(
    "small_parse_table_map=\{render_int_array(tables.small_parse_table_map)}",
  )
  args.push(
    "default_aliases=\{render_default_alias_array(tables.default_aliases, table_alias)}",
  )
  args.push(
    "supertype_entries=\{render_supertype_entry_array(tables.supertype_entries, table_alias)}",
  )
  args.push(
    "reserved_word_sets=\{render_token_set_array(tables.reserved_word_sets, table_alias)}",
  )
  args.push(
    "external_lex_states=\{render_external_lex_state_array(tables.external_lex_states, table_alias)}",
  )
  let scanner = if tables.external_token_count == 0 {
    render_external_scanner(tables.external_scanner, table_alias)
  } else {
    "external_scanner"
  }
  args.push("external_scanner=\{scanner}")
  args.push(
    "production_infos=\{render_production_info_array(tables.production_infos, table_alias)}",
  )
  args.push(
    "main_lex_tables=\{render_lex_table_array(tables.main_lex_tables, table_alias)}",
  )
  args.push(
    "keyword_lex_table=\{render_lex_table_option(tables.keyword_lex_table, table_alias)}",
  )
  let body = args.map(arg => "\{indent}  \{arg}").join(",\n")
  "\{indent}@\{table_alias}.GeneratedLanguageTables::new(\n\{body},\n\{indent})"
}

///|
fn render_metadata(
  metadata : @tables.LanguageMetadata,
  table_alias : String,
) -> String {
  "@\{table_alias}.LanguageMetadata::new(major=\{metadata.major}, minor=\{metadata.minor}, patch=\{metadata.patch})"
}

///|
fn render_string_literal(value : String) -> String {
  let pieces : Array[String] = ["\""]
  for char in value.to_array() {
    match char {
      '"' => pieces.push("\\\"")
      '\\' => pieces.push("\\\\")
      '\n' => pieces.push("\\n")
      '\r' => pieces.push("\\r")
      '\t' => pieces.push("\\t")
      _ => pieces.push(char.to_string())
    }
  }
  pieces.push("\"")
  pieces.join("")
}

///|
fn render_bool(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
fn render_int_option(value : Int?) -> String {
  match value {
    Some(inner) => "Some(\{inner})"
    None => "None"
  }
}

///|
fn render_array(values : Array[String]) -> String {
  let joined = values.join(", ")
  "[\{joined}]"
}

///|
fn render_int_array(values : Array[Int]) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(value.to_string())
  }
  render_array(rendered)
}

///|
fn render_bool_array(values : Array[Bool]) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_bool(value))
  }
  render_array(rendered)
}

///|
fn render_string_array(values : Array[String]) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_string_literal(value))
  }
  render_array(rendered)
}

///|
fn render_symbol_type_array(
  values : Array[@api.SymbolType],
  api_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_symbol_type(value, api_alias))
  }
  render_array(rendered)
}

///|
fn render_symbol_type(value : @api.SymbolType, api_alias : String) -> String {
  match value {
    Regular => "@\{api_alias}.SymbolType::Regular"
    Anonymous => "@\{api_alias}.SymbolType::Anonymous"
    Supertype => "@\{api_alias}.SymbolType::Supertype"
    Auxiliary => "@\{api_alias}.SymbolType::Auxiliary"
  }
}

///|
fn render_lex_mode_array(
  values : Array[@tables.GeneratedLexMode],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_lex_mode(value, table_alias))
  }
  render_array(rendered)
}

///|
fn render_lex_mode(
  value : @tables.GeneratedLexMode,
  table_alias : String,
) -> String {
  "@\{table_alias}.GeneratedLexMode::new(lex_state=\{value.lex_state}, external_lex_state=\{value.external_lex_state}, reserved_word_set_id=\{value.reserved_word_set_id})"
}

///|
fn render_parse_action_list_array(
  values : Array[@tables.GeneratedParseActionList],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_parse_action_list(value, table_alias))
  }
  render_array(rendered)
}

///|
fn render_parse_action_list(
  value : @tables.GeneratedParseActionList,
  table_alias : String,
) -> String {
  "@\{table_alias}.GeneratedParseActionList::new(actions=\{render_parse_action_array(value.actions, table_alias)}, reusable=\{render_bool(value.reusable)})"
}

///|
fn render_parse_action_array(
  values : Array[@tables.GeneratedParseAction],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_parse_action(value, table_alias))
  }
  render_array(rendered)
}

///|
fn render_parse_action(
  value : @tables.GeneratedParseAction,
  table_alias : String,
) -> String {
  match value {
    Accept => "@\{table_alias}.GeneratedParseAction::Accept"
    Recover => "@\{table_alias}.GeneratedParseAction::Recover"
    Shift(state_id~, is_repetition~) =>
      "@\{table_alias}.GeneratedParseAction::Shift(state_id=\{state_id}, is_repetition=\{render_bool(is_repetition)})"
    ShiftExtra => "@\{table_alias}.GeneratedParseAction::ShiftExtra"
    Reduce(symbol_id~, child_count~, dynamic_precedence~, production_id~) =>
      "@\{table_alias}.GeneratedParseAction::Reduce(symbol_id=\{symbol_id}, child_count=\{child_count}, dynamic_precedence=\{dynamic_precedence}, production_id=\{production_id})"
  }
}

///|
fn render_parse_table_cell_matrix(
  values : Array[Array[@tables.GeneratedParseTableCell]],
  table_alias : String,
) -> String {
  let rows : Array[String] = []
  for row in values {
    rows.push(render_parse_table_cell_array(row, table_alias))
  }
  render_array(rows)
}

///|
fn render_parse_table_cell_array(
  values : Array[@tables.GeneratedParseTableCell],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_parse_table_cell(value, table_alias))
  }
  render_array(rendered)
}

///|
fn render_parse_table_cell(
  value : @tables.GeneratedParseTableCell,
  table_alias : String,
) -> String {
  match value {
    EmptyCell => "@\{table_alias}.GeneratedParseTableCell::EmptyCell"
    ActionCell(id) =>
      "@\{table_alias}.GeneratedParseTableCell::ActionCell(\{id})"
    StateCell(id) => "@\{table_alias}.GeneratedParseTableCell::StateCell(\{id})"
  }
}

///|
fn render_small_parse_table_row_array(
  values : Array[@tables.GeneratedSmallParseTableRow],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_small_parse_table_row(value, table_alias))
  }
  render_array(rendered)
}

///|
fn render_small_parse_table_row(
  value : @tables.GeneratedSmallParseTableRow,
  table_alias : String,
) -> String {
  "@\{table_alias}.GeneratedSmallParseTableRow::new(state_id=\{value.state_id}, offset=\{value.offset}, sections=\{render_small_parse_table_section_array(value.sections, table_alias)})"
}

///|
fn render_small_parse_table_section_array(
  values : Array[@tables.GeneratedSmallParseTableSection],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_small_parse_table_section(value, table_alias))
  }
  render_array(rendered)
}

///|
fn render_small_parse_table_section(
  value : @tables.GeneratedSmallParseTableSection,
  table_alias : String,
) -> String {
  "@\{table_alias}.GeneratedSmallParseTableSection::new(kind=\{render_small_parse_table_section_kind(value.kind, table_alias)}, value=\{value.value}, symbols=\{render_int_array(value.symbols)})"
}

///|
fn render_small_parse_table_section_kind(
  value : @tables.GeneratedSmallParseTableSectionKind,
  table_alias : String,
) -> String {
  match value {
    SmallAction =>
      "@\{table_alias}.GeneratedSmallParseTableSectionKind::SmallAction"
    SmallState =>
      "@\{table_alias}.GeneratedSmallParseTableSectionKind::SmallState"
  }
}

///|
fn render_default_alias_array(
  values : Array[@tables.GeneratedDefaultAlias],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(
      "@\{table_alias}.GeneratedDefaultAlias::new(symbol_id=\{value.symbol_id}, value=\{render_string_literal(value.value)}, named=\{render_bool(value.named)})",
    )
  }
  render_array(rendered)
}

///|
fn render_alias_array(
  values : Array[@tables.GeneratedAlias],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_alias(value, table_alias))
  }
  render_array(rendered)
}

///|
fn render_non_terminal_alias_entry_array(
  values : Array[@tables.GeneratedNonTerminalAliasEntry],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(
      "@\{table_alias}.GeneratedNonTerminalAliasEntry::new(symbol_id=\{value.symbol_id}, public_symbol_id=\{value.public_symbol_id}, alias_symbol_ids=\{render_int_array(value.alias_symbol_ids)})",
    )
  }
  render_array(rendered)
}

///|
fn render_supertype_entry_array(
  values : Array[@tables.GeneratedSupertypeEntry],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(
      "@\{table_alias}.GeneratedSupertypeEntry::new(symbol_id=\{value.symbol_id}, subtype_symbol_ids=\{render_int_array(value.subtype_symbol_ids)})",
    )
  }
  render_array(rendered)
}

///|
fn render_token_set_array(
  values : Array[@tables.GeneratedTokenSet],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(
      "@\{table_alias}.GeneratedTokenSet::new(symbol_ids=\{render_int_array(value.symbol_ids)})",
    )
  }
  render_array(rendered)
}

///|
fn render_external_lex_state_array(
  values : Array[@tables.GeneratedExternalLexState],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(
      "@\{table_alias}.GeneratedExternalLexState::new(external_token_ids=\{render_int_array(value.external_token_ids)})",
    )
  }
  render_array(rendered)
}

///|
fn render_external_scanner(
  value : @tables.ExternalScannerDescriptor,
  table_alias : String,
) -> String {
  if value.external_token_count() == 0 && value.external_state_count() == 0 {
    "@\{table_alias}.ExternalScannerDescriptor::none()"
  } else {
    "@\{table_alias}.ExternalScannerDescriptor::new(external_token_count=\{value.external_token_count()}, external_state_count=\{value.external_state_count()}, states=\{render_external_scanner_states(value)}, symbol_map=\{render_external_scanner_symbol_map(value)})"
  }
}

///|
fn render_external_scanner_states(
  value : @tables.ExternalScannerDescriptor,
) -> String {
  let rows : Array[String] = []
  for state_id in 0..<value.external_state_count() {
    let row : Array[Bool] = []
    for token_id in 0..<value.external_token_count() {
      match value.state_enabled(state_id, token_id) {
        Some(enabled) => row.push(enabled)
        None => row.push(false)
      }
    }
    rows.push(render_bool_array(row))
  }
  render_array(rows)
}

///|
fn render_external_scanner_symbol_map(
  value : @tables.ExternalScannerDescriptor,
) -> String {
  let symbols : Array[Int] = []
  for token_id in 0..<value.external_token_count() {
    match value.symbol_for_external_token(token_id) {
      Some(symbol) => symbols.push(symbol)
      None => symbols.push(0)
    }
  }
  render_int_array(symbols)
}

///|
fn render_production_info_array(
  values : Array[@tables.GeneratedProductionInfo],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_production_info(value, table_alias))
  }
  render_array(rendered)
}

///|
fn render_production_info(
  value : @tables.GeneratedProductionInfo,
  table_alias : String,
) -> String {
  "@\{table_alias}.GeneratedProductionInfo::new(alias_sequence=\{render_alias_option_array(value.alias_sequence, table_alias)}, field_map=\{render_field_map_entry_array(value.field_map, table_alias)})"
}

///|
fn render_alias_option_array(
  values : Array[@tables.GeneratedAlias?],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    match value {
      Some(item) => rendered.push("Some(\{render_alias(item, table_alias)})")
      None => rendered.push("None")
    }
  }
  render_array(rendered)
}

///|
fn render_alias(value : @tables.GeneratedAlias, table_alias : String) -> String {
  "@\{table_alias}.GeneratedAlias::new(value=\{render_string_literal(value.value)}, named=\{render_bool(value.named)})"
}

///|
fn render_field_map_entry_array(
  values : Array[@tables.GeneratedFieldMapEntry],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(
      "@\{table_alias}.GeneratedFieldMapEntry::new(field_id=\{value.field_id}, locations=\{render_field_location_array(value.locations, table_alias)})",
    )
  }
  render_array(rendered)
}

///|
fn render_field_location_array(
  values : Array[@tables.GeneratedFieldLocation],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(
      "@\{table_alias}.GeneratedFieldLocation::new(index=\{value.index}, inherited=\{render_bool(value.inherited)})",
    )
  }
  render_array(rendered)
}

///|
fn render_lex_table_array(
  values : Array[@tables.GeneratedLexTable],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_lex_table(value, table_alias))
  }
  render_array(rendered)
}

///|
fn render_lex_table_option(
  value : @tables.GeneratedLexTable?,
  table_alias : String,
) -> String {
  match value {
    Some(table) => "Some(\{render_lex_table(table, table_alias)})"
    None => "None"
  }
}

///|
fn render_lex_table(
  value : @tables.GeneratedLexTable,
  table_alias : String,
) -> String {
  "@\{table_alias}.GeneratedLexTable::new(states=\{render_lex_state_array(value.states, table_alias)}, start_state=\{value.start_state})"
}

///|
fn render_lex_state_array(
  values : Array[@tables.GeneratedLexState],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_lex_state(value, table_alias))
  }
  render_array(rendered)
}

///|
fn render_lex_state(
  value : @tables.GeneratedLexState,
  table_alias : String,
) -> String {
  "@\{table_alias}.GeneratedLexState::new(accept_symbol_id=\{render_int_option(value.accept_symbol_id)}, eof_action=\{render_int_option(value.eof_action)}, transitions=\{render_lex_transition_array(value.transitions, table_alias)})"
}

///|
fn render_lex_transition_array(
  values : Array[@tables.GeneratedLexTransition],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(render_lex_transition(value, table_alias))
  }
  render_array(rendered)
}

///|
fn render_lex_transition(
  value : @tables.GeneratedLexTransition,
  table_alias : String,
) -> String {
  "@\{table_alias}.GeneratedLexTransition::new(ranges=\{render_character_range_array(value.ranges, table_alias)}, target_state=\{value.target_state}, is_separator=\{render_bool(value.is_separator)}, precedence=\{value.precedence})"
}

///|
fn render_character_range_array(
  values : Array[@tables.GeneratedCharacterRange],
  table_alias : String,
) -> String {
  let rendered : Array[String] = []
  for value in values {
    rendered.push(
      "@\{table_alias}.GeneratedCharacterRange::new(start=\{value.start}, end=\{value.end})",
    )
  }
  render_array(rendered)
}
