///|
pub(all) struct GenerateOptions {
  abi_version : Int
  language_name : String
  semantic_version : @tables.LanguageMetadata?
  root_alias : String
  tables_alias : String
  api_alias : String
} derive(Eq, Debug)

///|
pub fn GenerateOptions::default() -> GenerateOptions {
  {
    abi_version: @tables.target_abi_version(),
    language_name: "unknown",
    semantic_version: None,
    root_alias: "tree_sitter_mbt",
    tables_alias: "tables",
    api_alias: "api",
  }
}

///|
pub(all) struct GeneratedSource {
  path : String
  content : String
} derive(Eq, Debug)

///|
pub(all) enum GenerateWarning {
  UnsupportedRegexFlag(String)
  NamedExtraMayBeEmpty(String)
  SimplifiableRule(String)
} derive(Eq, Debug)

///|
pub(all) struct GeneratedLanguage {
  moonbit_sources : Array[GeneratedSource]
  node_types_json : String
  tables : @tables.GeneratedLanguageTables
  language_name : String
  abi_version : Int
  metadata : @tables.LanguageMetadata
  warnings : Array[GenerateWarning]
} derive(Eq, Debug)

///|
priv struct GeneratedMainLexTablesDraft {
  tables : Array[@tables.GeneratedLexTable]
  state_ids : Array[Int]
}

///|
priv struct GeneratedKeywordLexTableDraft {
  capture_token : Int?
  table : @tables.GeneratedLexTable?
  candidate_terminals : Array[Int]
  word_terminal : Int
}

///|
priv struct GeneratedPublicSymbolsDraft {
  public_symbol_map : Array[Int]
  alias_symbols : Array[@tables.GeneratedAlias]
  non_terminal_aliases : Array[@tables.GeneratedNonTerminalAliasEntry]
}

///|
pub(all) suberror GenerateError {
  UnsupportedAbi(Int)
  InvalidImportAlias(String)
  InvalidGrammar(String)
  UndeclaredPrecedence(String)
  ConflictingPrecedenceOrdering(left~ : String, right~ : String)
  IndirectRecursion(String)
  UndefinedSymbol(String)
  TerminalSupertype(String)
  InvalidExternalToken(String)
  InvalidRegex(String)
  InvalidLexicalToken(String)
  InvalidInline(String)
  ImproperNonTerminalExtra(String)
  AmbiguousExtra(Array[String])
  ParseTableValueOutOfRange(
    kind~ : String,
    value~ : Int,
    min~ : Int,
    max~ : Int
  )
} derive(Eq, Debug)

///|
pub fn generate_language(
  grammar_json : String,
  options? : GenerateOptions = GenerateOptions::default(),
) -> GeneratedLanguage raise GenerateError {
  let grammar = @grammar.parse_grammar(grammar_json) catch {
    err => raise GenerateError::InvalidGrammar(describe_grammar_error(err))
  }
  let warnings = collect_generate_warnings(grammar)
  if options.abi_version != @tables.target_abi_version() {
    raise GenerateError::UnsupportedAbi(options.abi_version)
  }
  validate_import_aliases(options)
  validate_precedences(grammar)
  validate_indirect_recursion(grammar)
  let interned = intern_symbols(grammar)
  let _ = interned_snapshot_weight(interned)
  let extracted = extract_tokens(interned)
  let _ = extracted_snapshot_weight(extracted)
  let expanded = expand_repeats(extracted)
  let _ = extracted_snapshot_weight(expanded)
  let flattened = flatten_grammar(expanded)
  let _ = flattened_snapshot_weight(flattened)
  let token_expanded = expand_tokens(flattened)
  let _ = token_expanded_snapshot_weight(token_expanded)
  let _ = lex_dfa_smoke_weight(token_expanded.lexical)
  let _ = lex_large_character_sets_smoke_weight(token_expanded.lexical)
  let default_aliased = extract_default_aliases(token_expanded)
  let prepared = process_inlines(default_aliased)
  let _ = prepared_snapshot_weight(prepared)
  let symbol_sets = build_parse_symbol_sets(prepared)
  let _ = parse_symbol_sets_weight(symbol_sets)
  let following_token_sets = build_following_token_sets(prepared, symbol_sets)
  let _ = following_token_sets_weight(following_token_sets)
  let _ = parse_items_smoke_weight()
  let _ = parse_item_set_builder_smoke_weight(prepared, symbol_sets)
  let _ = parse_state_graph_smoke_weight(
    build_parse_item_set_builder(prepared, symbol_sets),
  )
  let builder = build_parse_item_set_builder(prepared, symbol_sets)
  let graph = build_parse_state_graph(builder)
  let parse_table = build_parse_table_draft(builder, graph)
  let _ = parse_table_draft_weight(parse_table)
  let _ = character_set_smoke_weight()
  let _ = regex_parser_smoke_weight()
  let _ = nfa_smoke_weight()
  let _ = nfa_cursor_smoke_weight()
  let language_name = if options.language_name == "unknown" {
    grammar.name
  } else {
    options.language_name
  }
  let metadata = match options.semantic_version {
    Some(version) => version
    None => @tables.LanguageMetadata::zero()
  }
  let tables = generated_language_tables_from_draft(
    language_name,
    options.abi_version,
    metadata,
    prepared,
    parse_table,
  )
  {
    moonbit_sources: generated_moonbit_sources(tables, options),
    node_types_json: generated_node_types_json(prepared),
    tables,
    language_name,
    abi_version: options.abi_version,
    metadata,
    warnings,
  }
}

///|
fn generated_language_tables_from_draft(
  language_name : String,
  abi_version : Int,
  metadata : @tables.LanguageMetadata,
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
) -> @tables.GeneratedLanguageTables {
  let field_names = generated_field_names(parse_table.production_infos)
  let keyword_lex = generated_keyword_lex_table(grammar, parse_table)
  let main_lex = generated_main_lex_tables(grammar, parse_table, keyword_lex)
  let public_symbols = generated_public_symbols(grammar, parse_table)
  @tables.GeneratedLanguageTables::new(
    name=language_name,
    abi_version~,
    metadata~,
    symbol_count=parse_table.symbols.length(),
    alias_count=public_symbols.alias_symbols.length(),
    token_count=generated_token_count(grammar, parse_table.symbols),
    external_token_count=grammar.syntax.external_tokens.length(),
    state_count=parse_table.states.length(),
    field_count=field_names.length() - 1,
    production_id_count=parse_table.production_infos.length(),
    max_alias_sequence_length=parse_table.max_aliased_production_length,
    supertype_count=grammar.syntax.supertype_symbols.length(),
    main_lex_state_count=main_lex.tables.length(),
    external_lex_state_count=parse_table.external_lex_states.sets.length(),
    reserved_word_set_count=parse_table.reserved_word_sets.sets.length(),
    max_reserved_word_set_size=parse_table.reserved_word_sets.max_size,
    large_state_count=parse_table.layout.large_state_count,
    keyword_capture_token=keyword_lex.capture_token,
    symbol_names=generated_symbol_names(grammar, parse_table.symbols),
    symbol_types=generated_symbol_types(grammar, parse_table.symbols),
    public_symbol_map=public_symbols.public_symbol_map,
    alias_symbols=public_symbols.alias_symbols,
    non_terminal_aliases=public_symbols.non_terminal_aliases,
    field_names~,
    lex_modes=generated_lex_modes(parse_table, main_lex.state_ids),
    primary_state_ids=parse_table.primary_state_ids.copy(),
    parse_action_lists=generated_parse_action_lists(parse_table),
    large_parse_table=generated_large_parse_table(parse_table),
    small_parse_table=generated_small_parse_table(parse_table),
    small_parse_table_map=parse_table.layout.small_state_offsets.copy(),
    default_aliases=generated_default_aliases(grammar, parse_table),
    supertype_entries=generated_supertype_entries(grammar, parse_table),
    reserved_word_sets=generated_reserved_word_sets(parse_table),
    external_lex_states=generated_external_lex_states(parse_table),
    external_scanner=generated_external_scanner(grammar, parse_table),
    production_infos=generated_production_infos(parse_table, field_names),
    main_lex_tables=main_lex.tables,
    keyword_lex_table=keyword_lex.table,
  )
}

///|
fn generated_public_symbols(
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
) -> GeneratedPublicSymbolsDraft {
  let public_symbol_map : Array[Int] = []
  let alias_symbols : Array[@tables.GeneratedAlias] = []
  for i in 0..<parse_table.symbols.length() {
    public_symbol_map.push(i)
  }
  for default_alias in grammar.default_aliases {
    let grammar_symbol_id = parse_table_symbol_id_for_internal(
      parse_table,
      default_alias.symbol,
    )
    if grammar_symbol_id >= 0 && grammar_symbol_id < public_symbol_map.length() {
      public_symbol_map[grammar_symbol_id] = generated_public_symbol_id_for_alias(
        grammar,
        parse_table,
        alias_symbols,
        @tables.GeneratedAlias::new(
          value=default_alias.value,
          named=default_alias.named,
        ),
      )
    }
  }
  for production_info in parse_table.production_infos {
    for alias_entry in production_info.alias_sequence {
      match alias_entry {
        Some(production_alias) =>
          ignore(
            generated_public_symbol_id_for_alias(
              grammar,
              parse_table,
              alias_symbols,
              @tables.GeneratedAlias::new(
                value=production_alias.value,
                named=production_alias.named,
              ),
            ),
          )
        None => ()
      }
    }
  }
  {
    public_symbol_map,
    alias_symbols,
    non_terminal_aliases: generated_non_terminal_alias_entries(
      grammar, parse_table, alias_symbols,
    ),
  }
}

///|
fn generated_non_terminal_alias_entries(
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
  alias_symbols : Array[@tables.GeneratedAlias],
) -> Array[@tables.GeneratedNonTerminalAliasEntry] {
  let entries : Array[@tables.GeneratedNonTerminalAliasEntry] = []
  for variable in grammar.syntax.variables {
    for production in variable.productions {
      for step in production.steps {
        match (step.symbol, step.alias_name) {
          (InternalSymbol::NonTerminal(_), Some(alias_name)) => {
            let symbol_id = parse_table_symbol_id_for_internal(
              parse_table,
              step.symbol,
            )
            if symbol_id >= 0 {
              let public_symbol_id = generated_public_symbol_id_for_alias(
                grammar,
                parse_table,
                alias_symbols,
                @tables.GeneratedAlias::new(
                  value=alias_name,
                  named=step.alias_named,
                ),
              )
              push_unique_non_terminal_alias_entry(
                entries,
                @tables.GeneratedNonTerminalAliasEntry::new(
                  symbol_id~,
                  public_symbol_id~,
                ),
              )
            }
          }
          _ => ()
        }
      }
    }
  }
  entries
}

///|
fn push_unique_non_terminal_alias_entry(
  entries : Array[@tables.GeneratedNonTerminalAliasEntry],
  entry : @tables.GeneratedNonTerminalAliasEntry,
) -> Unit {
  for existing in entries {
    if existing == entry {
      return
    }
  }
  entries.push(entry)
}

///|
fn generated_public_symbol_id_for_alias(
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
  alias_symbols : Array[@tables.GeneratedAlias],
  alias_info : @tables.GeneratedAlias,
) -> Int {
  match
    generated_existing_public_symbol_id_for_alias(
      grammar, parse_table, alias_info,
    ) {
    Some(symbol_id) => symbol_id
    None => {
      for i in 0..<alias_symbols.length() {
        if alias_symbols[i] == alias_info {
          return parse_table.symbols.length() + i
        }
      }
      alias_symbols.push(alias_info)
      parse_table.symbols.length() + alias_symbols.length() - 1
    }
  }
}

///|
fn generated_existing_public_symbol_id_for_alias(
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
  alias_info : @tables.GeneratedAlias,
) -> Int? {
  for i in 0..<parse_table.symbols.length() {
    if generated_symbol_name(grammar, parse_table.symbols[i]) ==
      alias_info.value &&
      generated_symbol_type_matches_alias(
        generated_symbol_type(grammar, parse_table.symbols[i]),
        alias_info.named,
      ) {
      return Some(i)
    }
  }
  None
}

///|
fn generated_symbol_type_matches_alias(
  symbol_type : @api.SymbolType,
  alias_named : Bool,
) -> Bool {
  if alias_named {
    symbol_type == @api.SymbolType::Regular ||
    symbol_type == @api.SymbolType::Supertype
  } else {
    symbol_type == @api.SymbolType::Anonymous
  }
}

///|
fn generated_default_aliases(
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
) -> Array[@tables.GeneratedDefaultAlias] {
  let aliases : Array[@tables.GeneratedDefaultAlias] = []
  for default_alias in grammar.default_aliases {
    aliases.push(
      @tables.GeneratedDefaultAlias::new(
        symbol_id=parse_table_symbol_id_for_internal(
          parse_table,
          default_alias.symbol,
        ),
        value=default_alias.value,
        named=default_alias.named,
      ),
    )
  }
  aliases
}

///|
fn generated_supertype_entries(
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
) -> Array[@tables.GeneratedSupertypeEntry] {
  let entries : Array[@tables.GeneratedSupertypeEntry] = []
  for symbol in grammar.syntax.supertype_symbols {
    entries.push(
      @tables.GeneratedSupertypeEntry::new(
        symbol_id=parse_table_symbol_id_for_internal(parse_table, symbol),
        subtype_symbol_ids=generated_subtype_symbol_ids(
          grammar, parse_table, symbol,
        ),
      ),
    )
  }
  entries
}

///|
fn generated_subtype_symbol_ids(
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
  supertype : InternalSymbol,
) -> Array[Int] {
  let symbol_ids : Array[Int] = []
  match supertype {
    InternalSymbol::NonTerminal(index) =>
      if index >= 0 && index < grammar.syntax.variables.length() {
        for production in grammar.syntax.variables[index].productions {
          for step in production.steps {
            push_generated_subtype_symbol_id(
              symbol_ids,
              grammar,
              parse_table,
              supertype,
              step.symbol,
            )
          }
        }
      }
    _ => ()
  }
  symbol_ids.sort()
  symbol_ids
}

///|
fn push_generated_subtype_symbol_id(
  symbol_ids : Array[Int],
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
  supertype : InternalSymbol,
  subtype : InternalSymbol,
) -> Unit {
  if subtype == supertype ||
    !generated_subtype_symbol_is_public(grammar, subtype) {
    return
  }
  let symbol_id = parse_table_symbol_id_for_internal(parse_table, subtype)
  if symbol_id >= 0 {
    push_unique_int(symbol_ids, symbol_id)
  }
}

///|
fn generated_subtype_symbol_is_public(
  grammar : PreparedGrammar,
  symbol : InternalSymbol,
) -> Bool {
  match symbol {
    InternalSymbol::Terminal(index) =>
      index >= 0 &&
      index < grammar.lexical.variables.length() &&
      !is_auxiliary_kind(grammar.lexical.variables[index].kind)
    InternalSymbol::External(index) =>
      index >= 0 &&
      index < grammar.syntax.external_tokens.length() &&
      !is_auxiliary_kind(grammar.syntax.external_tokens[index].kind)
    InternalSymbol::NonTerminal(index) =>
      contains_internal_symbol(grammar.syntax.supertype_symbols, symbol) ||
      (
        index >= 0 &&
        index < grammar.syntax.variables.length() &&
        !is_auxiliary_kind(grammar.syntax.variables[index].kind)
      )
  }
}

///|
fn generated_main_lex_tables(
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
  keyword_lex : GeneratedKeywordLexTableDraft,
) -> GeneratedMainLexTablesDraft {
  let tables : Array[@tables.GeneratedLexTable] = []
  let state_ids : Array[Int] = []
  for state in parse_table.states {
    let tokens = generated_main_lex_tokens_for_state(state, keyword_lex)
    if generated_lex_token_set_has_main_tokens(tokens) {
      let table_id = tables.length()
      tables.push(
        generated_lex_table(parse_table, build_lex_dfa(grammar.lexical, tokens)),
      )
      state_ids.push(table_id)
    } else {
      state_ids.push(@tables.lex_state_none())
    }
  }
  { tables, state_ids }
}

///|
fn generated_main_lex_tokens_for_state(
  state : ParseStateDraft,
  keyword_lex : GeneratedKeywordLexTableDraft,
) -> LexTokenSet {
  let terminals : Array[Int] = []
  let externals : Array[Int] = []
  let mut eof = false
  for entry in state.terminal_entries {
    match entry.symbol {
      ParseTerminal(index) =>
        generated_main_lex_push_terminal(terminals, index, keyword_lex)
      ParseExternal(index) => push_unique_int(externals, index)
      ParseEnd => eof = true
      ParseEndOfNonTerminalExtra => ()
    }
  }
  for terminal in state.reserved_words.terminals {
    generated_main_lex_push_terminal(terminals, terminal, keyword_lex)
  }
  for external_token in state.reserved_words.externals {
    push_unique_int(externals, external_token)
  }
  lex_token_set(terminals, eof~, externals~)
}

///|
fn generated_main_lex_push_terminal(
  terminals : Array[Int],
  terminal : Int,
  keyword_lex : GeneratedKeywordLexTableDraft,
) -> Unit {
  if keyword_lex.word_terminal >= 0 &&
    contains_int(keyword_lex.candidate_terminals, terminal) {
    push_unique_int(terminals, keyword_lex.word_terminal)
  } else {
    push_unique_int(terminals, terminal)
  }
}

///|
fn generated_keyword_lex_table(
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
) -> GeneratedKeywordLexTableDraft {
  match grammar.syntax.word_symbol {
    Some(InternalSymbol::Terminal(word_terminal)) => {
      let capture_token = parse_table_symbol_id_for_internal(
        parse_table,
        InternalSymbol::Terminal(word_terminal),
      )
      if capture_token < 0 {
        return {
          capture_token: None,
          table: None,
          candidate_terminals: [],
          word_terminal: -1,
        }
      }
      let candidate_terminals = generated_keyword_candidate_terminals(
        grammar, parse_table, word_terminal,
      )
      if candidate_terminals.length() == 0 {
        return {
          capture_token: None,
          table: None,
          candidate_terminals,
          word_terminal: -1,
        }
      }
      {
        capture_token: Some(capture_token),
        table: Some(
          generated_lex_table(
            parse_table,
            build_lex_dfa(grammar.lexical, lex_token_set(candidate_terminals)),
          ),
        ),
        candidate_terminals,
        word_terminal,
      }
    }
    Some(InternalSymbol::External(_))
    | Some(InternalSymbol::NonTerminal(_))
    | None =>
      {
        capture_token: None,
        table: None,
        candidate_terminals: [],
        word_terminal: -1,
      }
  }
}

///|
fn generated_keyword_candidate_terminals(
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
  word_terminal : Int,
) -> Array[Int] {
  let terminals : Array[Int] = []
  for set in parse_table.reserved_word_sets.sets {
    for terminal in set.terminals {
      if terminal != word_terminal &&
        keyword_candidate_in_parse_symbols(parse_table, terminal) {
        push_unique_int(terminals, terminal)
      }
    }
  }
  if word_terminal >= 0 && word_terminal < grammar.lexical.variables.length() {
    let word = grammar.lexical.variables[word_terminal]
    for i in 0..<grammar.lexical.variables.length() {
      if i != word_terminal {
        match grammar.lexical.variables[i].literal {
          Some(literal) =>
            if keyword_literal_is_word_like(literal) &&
              nfa_matches(word.nfa, literal) &&
              keyword_candidate_in_parse_symbols(parse_table, i) {
              push_unique_int(terminals, i)
            }
          None => ()
        }
      }
    }
  }
  terminals.sort()
  terminals
}

///|
fn keyword_candidate_in_parse_symbols(
  parse_table : ParseTableDraft,
  terminal : Int,
) -> Bool {
  parse_table_symbol_id_for_internal(
    parse_table,
    InternalSymbol::Terminal(terminal),
  ) >=
  0
}

///|
fn keyword_literal_is_word_like(literal : String) -> Bool {
  let mut index = 0
  for char in literal {
    if index == 0 {
      if !(char == '_' ||
        ('A' <= char && char <= 'Z') ||
        ('a' <= char && char <= 'z')) {
        return false
      }
    } else if !(char == '_' ||
      ('A' <= char && char <= 'Z') ||
      ('a' <= char && char <= 'z') ||
      ('0' <= char && char <= '9')) {
      return false
    }
    index += 1
  }
  index > 0
}

///|
fn generated_lex_token_set_has_main_tokens(tokens : LexTokenSet) -> Bool {
  tokens.terminals.length() > 0 || tokens.eof
}

///|
fn generated_lex_table(
  parse_table : ParseTableDraft,
  dfa : LexDfa,
) -> @tables.GeneratedLexTable {
  let states : Array[@tables.GeneratedLexState] = []
  for state in dfa.states {
    states.push(generated_lex_state(parse_table, state))
  }
  @tables.GeneratedLexTable::new(states~, start_state=dfa.start_state)
}

///|
fn generated_lex_state(
  parse_table : ParseTableDraft,
  state : LexDfaState,
) -> @tables.GeneratedLexState {
  @tables.GeneratedLexState::new(
    accept_symbol_id=generated_lex_accept_symbol_id(parse_table, state.accept),
    eof_action=state.eof_action,
    transitions=generated_lex_transitions(state.transitions),
  )
}

///|
fn generated_lex_accept_symbol_id(
  parse_table : ParseTableDraft,
  accept : LexAccept?,
) -> Int? {
  match accept {
    Some(value) =>
      match value.symbol {
        Some(symbol) =>
          Some(parse_table_symbol_id_for_internal(parse_table, symbol))
        None => Some(0)
      }
    None => None
  }
}

///|
fn generated_lex_transitions(
  transitions : Array[LexDfaTransition],
) -> Array[@tables.GeneratedLexTransition] {
  let result : Array[@tables.GeneratedLexTransition] = []
  for transition in transitions {
    result.push(
      @tables.GeneratedLexTransition::new(
        ranges=generated_character_ranges(transition.characters),
        target_state=transition.target_state,
        is_separator=transition.is_separator,
        precedence=transition.precedence,
      ),
    )
  }
  result
}

///|
fn generated_character_ranges(
  set : CharacterSet,
) -> Array[@tables.GeneratedCharacterRange] {
  let ranges : Array[@tables.GeneratedCharacterRange] = []
  for range in set.ranges {
    ranges.push(
      @tables.GeneratedCharacterRange::new(
        start=range.start.reinterpret_as_int(),
        end=range.end.reinterpret_as_int(),
      ),
    )
  }
  ranges
}

///|
fn generated_production_infos(
  parse_table : ParseTableDraft,
  field_names : Array[String],
) -> Array[@tables.GeneratedProductionInfo] {
  let infos : Array[@tables.GeneratedProductionInfo] = []
  for info in parse_table.production_infos {
    infos.push(
      @tables.GeneratedProductionInfo::new(
        alias_sequence=generated_alias_sequence(info.alias_sequence),
        field_map=generated_field_map(field_names, info.field_map),
      ),
    )
  }
  infos
}

///|
fn generated_alias_sequence(
  aliases : Array[ParseAliasDraft?],
) -> Array[@tables.GeneratedAlias?] {
  let result : Array[@tables.GeneratedAlias?] = []
  for alias_entry in aliases {
    match alias_entry {
      Some(value) =>
        result.push(
          Some(
            @tables.GeneratedAlias::new(value=value.value, named=value.named),
          ),
        )
      None => result.push(None)
    }
  }
  result
}

///|
fn generated_field_map(
  field_names : Array[String],
  field_map : Array[ParseFieldMapEntryDraft],
) -> Array[@tables.GeneratedFieldMapEntry] {
  let entries : Array[@tables.GeneratedFieldMapEntry] = []
  for entry in field_map {
    let locations : Array[@tables.GeneratedFieldLocation] = []
    for location in entry.locations {
      locations.push(
        @tables.GeneratedFieldLocation::new(
          index=location.index,
          inherited=location.inherited,
        ),
      )
    }
    entries.push(
      @tables.GeneratedFieldMapEntry::new(
        field_id=generated_field_id(field_names, entry.name),
        locations~,
      ),
    )
  }
  entries
}

///|
fn generated_field_id(field_names : Array[String], name : String) -> Int {
  for i in 1..<field_names.length() {
    if field_names[i] == name {
      return i
    }
  }
  0
}

///|
fn generated_external_scanner(
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
) -> @tables.ExternalScannerDescriptor {
  let external_token_count = grammar.syntax.external_tokens.length()
  if external_token_count == 0 {
    @tables.ExternalScannerDescriptor::none()
  } else {
    @tables.ExternalScannerDescriptor::new(
      external_token_count~,
      external_state_count=parse_table.external_lex_states.sets.length(),
      states=generated_external_scanner_states(
        external_token_count, parse_table,
      ),
      symbol_map=generated_external_scanner_symbol_map(grammar, parse_table),
    )
  }
}

///|
fn generated_external_scanner_states(
  external_token_count : Int,
  parse_table : ParseTableDraft,
) -> Array[Array[Bool]] {
  let rows : Array[Array[Bool]] = []
  for set in parse_table.external_lex_states.sets {
    let row : Array[Bool] = []
    for external_token_id in 0..<external_token_count {
      row.push(contains_int(set.externals, external_token_id))
    }
    rows.push(row)
  }
  rows
}

///|
fn generated_external_scanner_symbol_map(
  grammar : PreparedGrammar,
  parse_table : ParseTableDraft,
) -> Array[Int] {
  let symbols : Array[Int] = []
  for i in 0..<grammar.syntax.external_tokens.length() {
    match grammar.syntax.external_tokens[i].corresponding_internal_token {
      Some(symbol) =>
        symbols.push(parse_table_symbol_id_for_internal(parse_table, symbol))
      None =>
        symbols.push(
          parse_table_find_symbol_id(
            parse_table.symbols,
            ParseTableSymbolDraft::ParseSymbolExternal(i),
          ),
        )
    }
  }
  symbols
}

///|
fn generated_reserved_word_sets(
  parse_table : ParseTableDraft,
) -> Array[@tables.GeneratedTokenSet] {
  let rows : Array[@tables.GeneratedTokenSet] = []
  for set in parse_table.reserved_word_sets.sets {
    rows.push(
      @tables.GeneratedTokenSet::new(
        symbol_ids=generated_token_set_symbol_ids(parse_table, set),
      ),
    )
  }
  rows
}

///|
fn generated_token_set_symbol_ids(
  parse_table : ParseTableDraft,
  set : ParseTokenSet,
) -> Array[Int] {
  let ids : Array[Int] = []
  for terminal in set.terminals {
    push_unique_int(
      ids,
      parse_table_find_symbol_id(
        parse_table.symbols,
        ParseTableSymbolDraft::ParseSymbolTerminal(terminal),
      ),
    )
  }
  for external_token in set.externals {
    push_unique_int(
      ids,
      parse_table_find_symbol_id(
        parse_table.symbols,
        ParseTableSymbolDraft::ParseSymbolExternal(external_token),
      ),
    )
  }
  if set.eof {
    push_unique_int(
      ids,
      parse_table_find_symbol_id(
        parse_table.symbols,
        ParseTableSymbolDraft::ParseSymbolEnd,
      ),
    )
  }
  if set.end_of_nonterminal_extra {
    push_unique_int(
      ids,
      parse_table_find_symbol_id(
        parse_table.symbols,
        ParseTableSymbolDraft::ParseSymbolEnd,
      ),
    )
  }
  ids
}

///|
fn generated_external_lex_states(
  parse_table : ParseTableDraft,
) -> Array[@tables.GeneratedExternalLexState] {
  let rows : Array[@tables.GeneratedExternalLexState] = []
  for set in parse_table.external_lex_states.sets {
    rows.push(
      @tables.GeneratedExternalLexState::new(
        external_token_ids=set.externals.copy(),
      ),
    )
  }
  rows
}

///|
fn generated_large_parse_table(
  parse_table : ParseTableDraft,
) -> Array[Array[@tables.GeneratedParseTableCell]] {
  let rows : Array[Array[@tables.GeneratedParseTableCell]] = []
  for row in parse_table.layout.large_rows {
    let generated_row : Array[@tables.GeneratedParseTableCell] = []
    for cell in row {
      generated_row.push(generated_parse_table_cell(cell))
    }
    rows.push(generated_row)
  }
  rows
}

///|
fn generated_parse_table_cell(
  cell : ParseTableCellDraft,
) -> @tables.GeneratedParseTableCell {
  match cell {
    ParseCellEmpty => @tables.GeneratedParseTableCell::EmptyCell
    ParseCellAction(action_id) =>
      @tables.GeneratedParseTableCell::ActionCell(action_id)
    ParseCellState(state_id) =>
      @tables.GeneratedParseTableCell::StateCell(state_id)
  }
}

///|
fn generated_small_parse_table(
  parse_table : ParseTableDraft,
) -> Array[@tables.GeneratedSmallParseTableRow] {
  let rows : Array[@tables.GeneratedSmallParseTableRow] = []
  for row in parse_table.layout.small_rows {
    rows.push(
      @tables.GeneratedSmallParseTableRow::new(
        state_id=row.state_id,
        offset=row.offset,
        sections=generated_small_parse_table_sections(parse_table, row.sections),
      ),
    )
  }
  rows
}

///|
fn generated_small_parse_table_sections(
  parse_table : ParseTableDraft,
  sections : Array[ParseSmallParseTableSectionDraft],
) -> Array[@tables.GeneratedSmallParseTableSection] {
  let generated : Array[@tables.GeneratedSmallParseTableSection] = []
  for section in sections {
    let symbols : Array[Int] = []
    for symbol in section.symbols {
      symbols.push(parse_table_find_symbol_id(parse_table.symbols, symbol))
    }
    generated.push(
      @tables.GeneratedSmallParseTableSection::new(
        kind=generated_small_parse_table_section_kind(section.kind),
        value=section.value,
        symbols~,
      ),
    )
  }
  generated
}

///|
fn generated_small_parse_table_section_kind(
  kind : ParseSmallParseTableSectionKindDraft,
) -> @tables.GeneratedSmallParseTableSectionKind {
  match kind {
    ParseSmallAction => @tables.GeneratedSmallParseTableSectionKind::SmallAction
    ParseSmallState => @tables.GeneratedSmallParseTableSectionKind::SmallState
  }
}

///|
fn generated_parse_action_lists(
  parse_table : ParseTableDraft,
) -> Array[@tables.GeneratedParseActionList] {
  let lists : Array[@tables.GeneratedParseActionList] = []
  for action_list in parse_table.parse_action_lists {
    let actions : Array[@tables.GeneratedParseAction] = []
    for action in action_list.actions {
      actions.push(generated_parse_action(parse_table, action))
    }
    lists.push(
      @tables.GeneratedParseActionList::new(
        actions~,
        reusable=action_list.reusable,
      ),
    )
  }
  lists
}

///|
fn generated_parse_action(
  parse_table : ParseTableDraft,
  action : ParseActionDraft,
) -> @tables.GeneratedParseAction {
  match action {
    DraftAccept => @tables.GeneratedParseAction::Accept
    DraftShift(state_id~, is_repetition~, ..) =>
      @tables.GeneratedParseAction::Shift(state_id~, is_repetition~)
    DraftShiftExtra => @tables.GeneratedParseAction::ShiftExtra
    DraftReduce(symbol~, child_count~, dynamic_precedence~, production_id~, ..) =>
      @tables.GeneratedParseAction::Reduce(
        symbol_id=parse_table_symbol_id_for_internal(parse_table, symbol),
        child_count~,
        dynamic_precedence~,
        production_id~,
      )
  }
}

///|
fn generated_lex_modes(
  parse_table : ParseTableDraft,
  main_lex_state_ids : Array[Int],
) -> Array[@tables.GeneratedLexMode] {
  let modes : Array[@tables.GeneratedLexMode] = []
  for i in 0..<parse_table.states.length() {
    modes.push(
      @tables.GeneratedLexMode::new(
        lex_state=main_lex_state_ids[i],
        external_lex_state=parse_table.external_lex_states.state_ids[i],
        reserved_word_set_id=parse_table.reserved_word_sets.state_ids[i],
      ),
    )
  }
  modes
}

///|
fn generated_token_count(
  grammar : PreparedGrammar,
  symbols : Array[ParseTableSymbolDraft],
) -> Int {
  let mut count = 0
  for symbol in symbols {
    match symbol {
      ParseSymbolEnd | ParseSymbolTerminal(_) => count += 1
      ParseSymbolExternal(index) =>
        if !generated_external_token_has_internal(grammar, index) {
          count += 1
        }
      ParseSymbolNonTerminal(_) => ()
    }
  }
  count
}

///|
fn generated_external_token_has_internal(
  grammar : PreparedGrammar,
  index : Int,
) -> Bool {
  index >= 0 &&
  index < grammar.syntax.external_tokens.length() &&
  grammar.syntax.external_tokens[index].corresponding_internal_token is Some(_)
}

///|
fn generated_symbol_names(
  grammar : PreparedGrammar,
  symbols : Array[ParseTableSymbolDraft],
) -> Array[String] {
  let names : Array[String] = []
  for symbol in symbols {
    names.push(generated_symbol_name(grammar, symbol))
  }
  names
}

///|
fn generated_symbol_name(
  grammar : PreparedGrammar,
  symbol : ParseTableSymbolDraft,
) -> String {
  match symbol {
    ParseSymbolEnd => "end"
    ParseSymbolTerminal(index) =>
      if index >= 0 && index < grammar.lexical.variables.length() {
        grammar.lexical.variables[index].name
      } else {
        "terminal\{index}"
      }
    ParseSymbolExternal(index) =>
      if index >= 0 && index < grammar.syntax.external_tokens.length() {
        grammar.syntax.external_tokens[index].name
      } else {
        "external\{index}"
      }
    ParseSymbolNonTerminal(index) =>
      if index >= 0 && index < grammar.syntax.variables.length() {
        grammar.syntax.variables[index].name
      } else {
        "v\{index}"
      }
  }
}

///|
fn generated_symbol_types(
  grammar : PreparedGrammar,
  symbols : Array[ParseTableSymbolDraft],
) -> Array[@api.SymbolType] {
  let types : Array[@api.SymbolType] = []
  for symbol in symbols {
    types.push(generated_symbol_type(grammar, symbol))
  }
  types
}

///|
fn generated_symbol_type(
  grammar : PreparedGrammar,
  symbol : ParseTableSymbolDraft,
) -> @api.SymbolType {
  match symbol {
    ParseSymbolEnd => @api.SymbolType::Regular
    ParseSymbolTerminal(index) =>
      if index >= 0 && index < grammar.lexical.variables.length() {
        generated_symbol_type_from_kind(grammar.lexical.variables[index].kind)
      } else {
        @api.SymbolType::Regular
      }
    ParseSymbolExternal(index) =>
      if index >= 0 && index < grammar.syntax.external_tokens.length() {
        generated_symbol_type_from_kind(
          grammar.syntax.external_tokens[index].kind,
        )
      } else {
        @api.SymbolType::Regular
      }
    ParseSymbolNonTerminal(index) => {
      let symbol = InternalSymbol::NonTerminal(index)
      if contains_internal_symbol(grammar.syntax.supertype_symbols, symbol) {
        @api.SymbolType::Supertype
      } else if index >= 0 && index < grammar.syntax.variables.length() {
        generated_symbol_type_from_kind(grammar.syntax.variables[index].kind)
      } else {
        @api.SymbolType::Regular
      }
    }
  }
}

///|
fn generated_symbol_type_from_kind(kind : VariableKind) -> @api.SymbolType {
  match kind {
    Anonymous => @api.SymbolType::Anonymous
    Auxiliary => @api.SymbolType::Auxiliary
    Named | Hidden => @api.SymbolType::Regular
  }
}

///|
fn generated_field_names(
  production_infos : Array[ParseProductionInfoDraft],
) -> Array[String] {
  let names : Array[String] = []
  for info in production_infos {
    for field in info.field_map {
      push_unique_string(names, field.name)
    }
  }
  names.sort()
  let result = [""]
  for name in names {
    result.push(name)
  }
  result
}

///|
fn collect_generate_warnings(
  grammar : @grammar.InputGrammar,
) -> Array[GenerateWarning] {
  let unsupported_regex_flags : Array[String] = []
  for variable in grammar.rules {
    collect_unsupported_regex_flags_in_rule(
      variable.rule,
      unsupported_regex_flags,
    )
  }
  for rule in grammar.extras {
    collect_unsupported_regex_flags_in_rule(rule, unsupported_regex_flags)
  }
  for rule in grammar.externals {
    collect_unsupported_regex_flags_in_rule(rule, unsupported_regex_flags)
  }
  for reserved_set in grammar.reserved {
    for rule in reserved_set.rules {
      collect_unsupported_regex_flags_in_rule(rule, unsupported_regex_flags)
    }
  }

  let warnings : Array[GenerateWarning] = []
  for flag in unsupported_regex_flags {
    warnings.push(GenerateWarning::UnsupportedRegexFlag(flag))
  }
  warnings
}

///|
fn collect_unsupported_regex_flags_in_rule(
  rule : @grammar.Rule,
  unsupported_flags : Array[String],
) -> Unit {
  match rule {
    Pattern(flags~, ..) =>
      collect_unsupported_regex_flags(flags, unsupported_flags)
    Alias(content~, ..)
    | Repeat(content)
    | Repeat1(content)
    | Field(content~, ..)
    | Prec(content~, ..)
    | PrecLeft(content~, ..)
    | PrecRight(content~, ..)
    | PrecDynamic(content~, ..)
    | Token(content)
    | ImmediateToken(content)
    | Reserved(content~, ..) =>
      collect_unsupported_regex_flags_in_rule(content, unsupported_flags)
    Seq(members) | Choice(members) =>
      for item in members {
        collect_unsupported_regex_flags_in_rule(item, unsupported_flags)
      }
    Blank | String(_) | Symbol(_) => ()
  }
}

///|
fn collect_unsupported_regex_flags(
  flags : String,
  unsupported_flags : Array[String],
) -> Unit {
  for flag in flags.to_array() {
    match flag {
      'i' | 'u' | 'v' => ()
      _ => push_unique_string(unsupported_flags, flag.to_string())
    }
  }
}

///|
priv enum VariableKind {
  Named
  Hidden
  Anonymous
  Auxiliary
}

///|
priv enum InternalSymbol {
  Terminal(Int)
  External(Int)
  NonTerminal(Int)
} derive(Eq, Debug)

///|
priv enum InternedRule {
  IRAlias(content~ : InternedRule, value~ : String, named~ : Bool)
  IRBlank
  IRString(String)
  IRPattern(value~ : String, flags~ : String)
  IRSymbol(InternalSymbol)
  IRSeq(Array[InternedRule])
  IRChoice(Array[InternedRule])
  IRRepeat(InternedRule)
  IRRepeat1(InternedRule)
  IRField(name~ : String, content~ : InternedRule)
  IRPrec(value~ : @grammar.PrecedenceValue, content~ : InternedRule)
  IRPrecLeft(value~ : @grammar.PrecedenceValue, content~ : InternedRule)
  IRPrecRight(value~ : @grammar.PrecedenceValue, content~ : InternedRule)
  IRPrecDynamic(value~ : Int, content~ : InternedRule)
  IRToken(InternedRule)
  IRImmediateToken(InternedRule)
  IRReserved(context_name~ : String, content~ : InternedRule)
} derive(Eq, Debug)

///|
priv struct InternedVariable {
  symbol : InternalSymbol
  name : String
  kind : VariableKind
  rule : InternedRule
}

///|
priv struct InternedExternalToken {
  symbol : InternalSymbol
  name : String
  kind : VariableKind
  rule : InternedRule
}

///|
priv struct InternedReservedSet {
  name : String
  rules : Array[InternedRule]
}

///|
priv struct InternedGrammar {
  name : String
  start_symbol : InternalSymbol?
  variables : Array[InternedVariable]
  extras : Array[InternedRule]
  external_tokens : Array[InternedExternalToken]
  inline_symbols : Array[InternalSymbol]
  conflict_symbols : Array[Array[InternalSymbol]]
  precedence_orderings : Array[Array[@grammar.PrecedenceValue]]
  word_symbol : InternalSymbol?
  reserved_sets : Array[InternedReservedSet]
  supertype_symbols : Array[InternalSymbol]
}

///|
priv struct LexicalVariable {
  symbol : InternalSymbol
  name : String
  kind : VariableKind
  rule : InternedRule
}

///|
priv struct ExtractedExternalToken {
  symbol : InternalSymbol
  name : String
  kind : VariableKind
  corresponding_internal_token : InternalSymbol?
  rule : InternedRule
}

///|
priv struct ExtractedReservedSet {
  name : String
  rules : Array[InternedRule]
}

///|
priv struct ExtractedSyntaxGrammar {
  name : String
  start_symbol : InternalSymbol?
  variables : Array[InternedVariable]
  extra_symbols : Array[InternalSymbol]
  external_tokens : Array[ExtractedExternalToken]
  inline_symbols : Array[InternalSymbol]
  conflict_symbols : Array[Array[InternalSymbol]]
  precedence_orderings : Array[Array[@grammar.PrecedenceValue]]
  word_symbol : InternalSymbol?
  reserved_sets : Array[ExtractedReservedSet]
  supertype_symbols : Array[InternalSymbol]
}

///|
priv struct ExtractedLexicalGrammar {
  variables : Array[LexicalVariable]
  separators : Array[InternedRule]
}

///|
priv struct ExtractedGrammar {
  syntax : ExtractedSyntaxGrammar
  lexical : ExtractedLexicalGrammar
}

///|
priv enum Associativity {
  NoAssociativity
  Left
  Right
}

///|
priv struct FlattenContext {
  alias_name : String?
  alias_named : Bool
  field_name : String?
  precedence : @grammar.PrecedenceValue?
  associativity : Associativity
  dynamic_precedence : Int
  reserved_word_set_id : Int
}

///|
priv struct ProductionStep {
  symbol : InternalSymbol
  alias_name : String?
  alias_named : Bool
  field_name : String?
  precedence : @grammar.PrecedenceValue?
  associativity : Associativity
  reserved_word_set_id : Int
}

///|
priv struct FlattenedProduction {
  steps : Array[ProductionStep]
  dynamic_precedence : Int
}

///|
priv struct FlattenedVariable {
  symbol : InternalSymbol
  name : String
  kind : VariableKind
  productions : Array[FlattenedProduction]
}

///|
priv struct FlattenedSyntaxGrammar {
  name : String
  start_symbol : InternalSymbol?
  variables : Array[FlattenedVariable]
  extra_symbols : Array[InternalSymbol]
  external_tokens : Array[ExtractedExternalToken]
  inline_symbols : Array[InternalSymbol]
  conflict_symbols : Array[Array[InternalSymbol]]
  precedence_orderings : Array[Array[@grammar.PrecedenceValue]]
  word_symbol : InternalSymbol?
  reserved_sets : Array[ExtractedReservedSet]
  supertype_symbols : Array[InternalSymbol]
}

///|
priv struct FlattenedGrammar {
  syntax : FlattenedSyntaxGrammar
  lexical : ExtractedLexicalGrammar
}

///|
fn interned_snapshot_weight(snapshot : InternedGrammar) -> Int {
  let mut weight = snapshot.name.length()
  weight += optional_internal_symbol_weight(snapshot.start_symbol)
  for variable in snapshot.variables {
    weight += internal_symbol_weight(variable.symbol)
    weight += variable.name.length()
    weight += variable_kind_weight(variable.kind)
    weight += interned_rule_weight(variable.rule)
  }
  for rule in snapshot.extras {
    weight += interned_rule_weight(rule)
  }
  for token in snapshot.external_tokens {
    weight += internal_symbol_weight(token.symbol)
    weight += token.name.length()
    weight += variable_kind_weight(token.kind)
    weight += interned_rule_weight(token.rule)
  }
  for symbol in snapshot.inline_symbols {
    weight += internal_symbol_weight(symbol)
  }
  for row in snapshot.conflict_symbols {
    for symbol in row {
      weight += internal_symbol_weight(symbol)
    }
  }
  for row in snapshot.precedence_orderings {
    for entry in row {
      weight += precedence_value_weight(entry)
    }
  }
  weight += optional_internal_symbol_weight(snapshot.word_symbol)
  for set in snapshot.reserved_sets {
    weight += set.name.length()
    for rule in set.rules {
      weight += interned_rule_weight(rule)
    }
  }
  for symbol in snapshot.supertype_symbols {
    weight += internal_symbol_weight(symbol)
  }
  weight
}

///|
fn optional_internal_symbol_weight(symbol : InternalSymbol?) -> Int {
  match symbol {
    Some(value) => internal_symbol_weight(value)
    None => 0
  }
}

///|
fn internal_symbol_weight(symbol : InternalSymbol) -> Int {
  match symbol {
    Terminal(index) | External(index) | NonTerminal(index) => index + 1
  }
}

///|
fn variable_kind_weight(kind : VariableKind) -> Int {
  match kind {
    Named => 1
    Hidden => 2
    Anonymous => 3
    Auxiliary => 4
  }
}

///|
fn precedence_value_weight(value : @grammar.PrecedenceValue) -> Int {
  match value {
    Number(value) => value
    Name(value) => value.length()
  }
}

///|
fn interned_rule_weight(rule : InternedRule) -> Int {
  match rule {
    IRAlias(content~, value~, named~) => {
      let named_weight = if named { 1 } else { 0 }
      interned_rule_weight(content) + value.length() + named_weight
    }
    IRBlank => 1
    IRString(value) => value.length()
    IRPattern(value~, flags~) => value.length() + flags.length()
    IRSymbol(symbol) => internal_symbol_weight(symbol)
    IRSeq(members) | IRChoice(members) => {
      let mut weight = members.length()
      for item in members {
        weight += interned_rule_weight(item)
      }
      weight
    }
    IRRepeat(content) | IRRepeat1(content) => interned_rule_weight(content)
    IRField(name~, content~) => name.length() + interned_rule_weight(content)
    IRPrec(value~, content~)
    | IRPrecLeft(value~, content~)
    | IRPrecRight(value~, content~) =>
      precedence_value_weight(value) + interned_rule_weight(content)
    IRPrecDynamic(value~, content~) => value + interned_rule_weight(content)
    IRToken(content) | IRImmediateToken(content) =>
      interned_rule_weight(content)
    IRReserved(context_name~, content~) =>
      context_name.length() + interned_rule_weight(content)
  }
}

///|
fn extracted_snapshot_weight(snapshot : ExtractedGrammar) -> Int {
  let mut weight = 0
  weight += extracted_syntax_weight(snapshot.syntax)
  for variable in snapshot.lexical.variables {
    weight += internal_symbol_weight(variable.symbol)
    weight += variable.name.length()
    weight += variable_kind_weight(variable.kind)
    weight += interned_rule_weight(variable.rule)
  }
  for separator in snapshot.lexical.separators {
    weight += interned_rule_weight(separator)
  }
  weight
}

///|
fn extracted_syntax_weight(snapshot : ExtractedSyntaxGrammar) -> Int {
  let mut weight = snapshot.name.length()
  weight += optional_internal_symbol_weight(snapshot.start_symbol)
  for variable in snapshot.variables {
    weight += internal_symbol_weight(variable.symbol)
    weight += variable.name.length()
    weight += variable_kind_weight(variable.kind)
    weight += interned_rule_weight(variable.rule)
  }
  for symbol in snapshot.extra_symbols {
    weight += internal_symbol_weight(symbol)
  }
  for token in snapshot.external_tokens {
    weight += internal_symbol_weight(token.symbol)
    weight += token.name.length()
    weight += variable_kind_weight(token.kind)
    weight += optional_internal_symbol_weight(
      token.corresponding_internal_token,
    )
    weight += interned_rule_weight(token.rule)
  }
  for symbol in snapshot.inline_symbols {
    weight += internal_symbol_weight(symbol)
  }
  for row in snapshot.conflict_symbols {
    for symbol in row {
      weight += internal_symbol_weight(symbol)
    }
  }
  for row in snapshot.precedence_orderings {
    for entry in row {
      weight += precedence_value_weight(entry)
    }
  }
  weight += optional_internal_symbol_weight(snapshot.word_symbol)
  for set in snapshot.reserved_sets {
    weight += set.name.length()
    for rule in set.rules {
      weight += interned_rule_weight(rule)
    }
  }
  for symbol in snapshot.supertype_symbols {
    weight += internal_symbol_weight(symbol)
  }
  weight
}

///|
fn flattened_snapshot_weight(snapshot : FlattenedGrammar) -> Int {
  let mut weight = snapshot.syntax.name.length()
  weight += optional_internal_symbol_weight(snapshot.syntax.start_symbol)
  for variable in snapshot.syntax.variables {
    weight += internal_symbol_weight(variable.symbol)
    weight += variable.name.length()
    weight += variable_kind_weight(variable.kind)
    for production in variable.productions {
      weight += flattened_production_weight(production)
    }
  }
  for symbol in snapshot.syntax.extra_symbols {
    weight += internal_symbol_weight(symbol)
  }
  for token in snapshot.syntax.external_tokens {
    weight += internal_symbol_weight(token.symbol)
    weight += token.name.length()
    weight += variable_kind_weight(token.kind)
    weight += optional_internal_symbol_weight(
      token.corresponding_internal_token,
    )
    weight += interned_rule_weight(token.rule)
  }
  for symbol in snapshot.syntax.inline_symbols {
    weight += internal_symbol_weight(symbol)
  }
  for row in snapshot.syntax.conflict_symbols {
    for symbol in row {
      weight += internal_symbol_weight(symbol)
    }
  }
  for row in snapshot.syntax.precedence_orderings {
    for entry in row {
      weight += precedence_value_weight(entry)
    }
  }
  weight += optional_internal_symbol_weight(snapshot.syntax.word_symbol)
  for set in snapshot.syntax.reserved_sets {
    weight += set.name.length()
    for rule in set.rules {
      weight += interned_rule_weight(rule)
    }
  }
  for symbol in snapshot.syntax.supertype_symbols {
    weight += internal_symbol_weight(symbol)
  }
  for variable in snapshot.lexical.variables {
    weight += internal_symbol_weight(variable.symbol)
    weight += variable.name.length()
    weight += variable_kind_weight(variable.kind)
    weight += interned_rule_weight(variable.rule)
  }
  for separator in snapshot.lexical.separators {
    weight += interned_rule_weight(separator)
  }
  weight
}

///|
fn flattened_production_weight(production : FlattenedProduction) -> Int {
  let mut weight = production.dynamic_precedence
  for step in production.steps {
    weight += production_step_weight(step)
  }
  weight
}

///|
fn production_step_weight(step : ProductionStep) -> Int {
  let mut weight = internal_symbol_weight(step.symbol)
  match step.alias_name {
    Some(name) => weight += name.length()
    None => ()
  }
  if step.alias_named {
    weight += 1
  }
  match step.field_name {
    Some(name) => weight += name.length()
    None => ()
  }
  match step.precedence {
    Some(value) => weight += precedence_value_weight(value)
    None => ()
  }
  weight += associativity_weight(step.associativity)
  weight += step.reserved_word_set_id
  weight
}

///|
fn associativity_weight(associativity : Associativity) -> Int {
  match associativity {
    NoAssociativity => 0
    Left => 1
    Right => 2
  }
}

///|
fn flatten_grammar(grammar : ExtractedGrammar) -> FlattenedGrammar {
  let variables : Array[FlattenedVariable] = []
  for variable in grammar.syntax.variables {
    variables.push({
      symbol: variable.symbol,
      name: variable.name,
      kind: variable.kind,
      productions: flatten_rule(
        variable.rule,
        flatten_context_default(),
        true,
        grammar.syntax.reserved_sets,
      ),
    })
  }
  {
    syntax: {
      name: grammar.syntax.name,
      start_symbol: grammar.syntax.start_symbol,
      variables,
      extra_symbols: grammar.syntax.extra_symbols,
      external_tokens: grammar.syntax.external_tokens,
      inline_symbols: grammar.syntax.inline_symbols,
      conflict_symbols: grammar.syntax.conflict_symbols,
      precedence_orderings: grammar.syntax.precedence_orderings,
      word_symbol: grammar.syntax.word_symbol,
      reserved_sets: grammar.syntax.reserved_sets,
      supertype_symbols: grammar.syntax.supertype_symbols,
    },
    lexical: grammar.lexical,
  }
}

///|
fn flatten_context_default() -> FlattenContext {
  {
    alias_name: None,
    alias_named: false,
    field_name: None,
    precedence: None,
    associativity: Associativity::NoAssociativity,
    dynamic_precedence: 0,
    reserved_word_set_id: 0,
  }
}

///|
fn flatten_rule(
  rule : InternedRule,
  context : FlattenContext,
  at_end : Bool,
  reserved_sets : Array[ExtractedReservedSet],
) -> Array[FlattenedProduction] {
  match rule {
    IRAlias(content~, value~, named~) =>
      flatten_rule(
        content,
        { ..context, alias_name: Some(value), alias_named: named },
        at_end,
        reserved_sets,
      )
    IRBlank => [{ steps: [], dynamic_precedence: context.dynamic_precedence }]
    IRString(_) | IRPattern(_) => []
    IRSymbol(symbol) =>
      [
        {
          steps: [production_step(symbol, context)],
          dynamic_precedence: context.dynamic_precedence,
        },
      ]
    IRSeq(members) => flatten_sequence(members, context, at_end, reserved_sets)
    IRChoice(members) => flatten_choice(members, context, at_end, reserved_sets)
    IRRepeat(content) | IRRepeat1(content) =>
      flatten_rule(content, context, at_end, reserved_sets)
    IRField(name~, content~) =>
      flatten_rule(
        content,
        { ..context, field_name: Some(name) },
        at_end,
        reserved_sets,
      )
    IRPrec(value~, content~) =>
      flatten_precedence_scope(
        content,
        {
          ..context,
          precedence: Some(value),
          associativity: Associativity::NoAssociativity,
        },
        context,
        at_end,
        reserved_sets,
      )
    IRPrecLeft(value~, content~) =>
      flatten_precedence_scope(
        content,
        {
          ..context,
          precedence: Some(value),
          associativity: Associativity::Left,
        },
        context,
        at_end,
        reserved_sets,
      )
    IRPrecRight(value~, content~) =>
      flatten_precedence_scope(
        content,
        {
          ..context,
          precedence: Some(value),
          associativity: Associativity::Right,
        },
        context,
        at_end,
        reserved_sets,
      )
    IRPrecDynamic(value~, content~) =>
      flatten_rule(
        content,
        {
          ..context,
          dynamic_precedence: strongest_dynamic_precedence(
            context.dynamic_precedence,
            value,
          ),
        },
        at_end,
        reserved_sets,
      )
    IRToken(content) | IRImmediateToken(content) =>
      flatten_rule(content, context, at_end, reserved_sets)
    IRReserved(context_name~, content~) =>
      flatten_rule(
        content,
        {
          ..context,
          reserved_word_set_id: reserved_set_id(reserved_sets, context_name),
        },
        at_end,
        reserved_sets,
      )
  }
}

///|
fn flatten_precedence_scope(
  content : InternedRule,
  scoped_context : FlattenContext,
  outer_context : FlattenContext,
  at_end : Bool,
  reserved_sets : Array[ExtractedReservedSet],
) -> Array[FlattenedProduction] {
  let productions = flatten_rule(content, scoped_context, at_end, reserved_sets)
  if at_end {
    productions
  } else {
    rollback_last_precedence(productions, outer_context)
  }
}

///|
fn production_step(
  symbol : InternalSymbol,
  context : FlattenContext,
) -> ProductionStep {
  {
    symbol,
    alias_name: context.alias_name,
    alias_named: context.alias_named,
    field_name: context.field_name,
    precedence: context.precedence,
    associativity: context.associativity,
    reserved_word_set_id: context.reserved_word_set_id,
  }
}

///|
fn flatten_sequence(
  members : Array[InternedRule],
  context : FlattenContext,
  at_end : Bool,
  reserved_sets : Array[ExtractedReservedSet],
) -> Array[FlattenedProduction] {
  let mut result : Array[FlattenedProduction] = [
    { steps: [], dynamic_precedence: 0 },
  ]
  for i in 0..<members.length() {
    let member_at_end = at_end && i + 1 == members.length()
    let member_productions = flatten_rule(
      members[i],
      context,
      member_at_end,
      reserved_sets,
    )
    result = product_productions(result, member_productions)
  }
  dedupe_productions(result)
}

///|
fn flatten_choice(
  members : Array[InternedRule],
  context : FlattenContext,
  at_end : Bool,
  reserved_sets : Array[ExtractedReservedSet],
) -> Array[FlattenedProduction] {
  let result : Array[FlattenedProduction] = []
  for item in members {
    let productions = flatten_rule(item, context, at_end, reserved_sets)
    for production in productions {
      push_unique_production(result, production)
    }
  }
  result
}

///|
fn product_productions(
  left : Array[FlattenedProduction],
  right : Array[FlattenedProduction],
) -> Array[FlattenedProduction] {
  let result : Array[FlattenedProduction] = []
  for left_production in left {
    for right_production in right {
      push_unique_production(
        result,
        concatenate_productions(left_production, right_production),
      )
    }
  }
  result
}

///|
fn concatenate_productions(
  left : FlattenedProduction,
  right : FlattenedProduction,
) -> FlattenedProduction {
  {
    steps: append_production_steps(left.steps, right.steps),
    dynamic_precedence: strongest_dynamic_precedence(
      left.dynamic_precedence,
      right.dynamic_precedence,
    ),
  }
}

///|
fn append_production_steps(
  left : Array[ProductionStep],
  right : Array[ProductionStep],
) -> Array[ProductionStep] {
  let result : Array[ProductionStep] = []
  for step in left {
    result.push(step)
  }
  for step in right {
    result.push(step)
  }
  result
}

///|
fn dedupe_productions(
  productions : Array[FlattenedProduction],
) -> Array[FlattenedProduction] {
  let result : Array[FlattenedProduction] = []
  for production in productions {
    push_unique_production(result, production)
  }
  result
}

///|
fn push_unique_production(
  productions : Array[FlattenedProduction],
  production : FlattenedProduction,
) -> Unit {
  if !contains_production(productions, production) {
    productions.push(production)
  }
}

///|
fn contains_production(
  productions : Array[FlattenedProduction],
  production : FlattenedProduction,
) -> Bool {
  for existing in productions {
    if same_production(existing, production) {
      return true
    }
  }
  false
}

///|
fn same_production(
  left : FlattenedProduction,
  right : FlattenedProduction,
) -> Bool {
  if left.dynamic_precedence != right.dynamic_precedence ||
    left.steps.length() != right.steps.length() {
    return false
  }
  for i in 0..<left.steps.length() {
    if !same_production_step(left.steps[i], right.steps[i]) {
      return false
    }
  }
  true
}

///|
fn same_production_step(left : ProductionStep, right : ProductionStep) -> Bool {
  left.symbol == right.symbol &&
  left.alias_name == right.alias_name &&
  left.alias_named == right.alias_named &&
  left.field_name == right.field_name &&
  left.precedence == right.precedence &&
  same_associativity(left.associativity, right.associativity) &&
  left.reserved_word_set_id == right.reserved_word_set_id
}

///|
fn same_associativity(left : Associativity, right : Associativity) -> Bool {
  match (left, right) {
    (NoAssociativity, NoAssociativity) | (Left, Left) | (Right, Right) => true
    _ => false
  }
}

///|
fn rollback_last_precedence(
  productions : Array[FlattenedProduction],
  outer_context : FlattenContext,
) -> Array[FlattenedProduction] {
  let result : Array[FlattenedProduction] = []
  for production in productions {
    result.push(rollback_last_step_precedence(production, outer_context))
  }
  result
}

///|
fn rollback_last_step_precedence(
  production : FlattenedProduction,
  outer_context : FlattenContext,
) -> FlattenedProduction {
  if production.steps.length() == 0 {
    return production
  }
  let steps : Array[ProductionStep] = []
  let last = production.steps.length() - 1
  for i in 0..<production.steps.length() {
    let step = production.steps[i]
    if i == last {
      steps.push({
        ..step,
        precedence: outer_context.precedence,
        associativity: outer_context.associativity,
      })
    } else {
      steps.push(step)
    }
  }
  { steps, dynamic_precedence: production.dynamic_precedence }
}

///|
fn reserved_set_id(sets : Array[ExtractedReservedSet], name : String) -> Int {
  for i in 0..<sets.length() {
    if sets[i].name == name {
      return i
    }
  }
  0
}

///|
fn strongest_dynamic_precedence(left : Int, right : Int) -> Int {
  if abs_int(right) > abs_int(left) {
    right
  } else {
    left
  }
}

///|
fn abs_int(value : Int) -> Int {
  if value < 0 {
    0 - value
  } else {
    value
  }
}

///|
fn expand_repeats(grammar : ExtractedGrammar) -> ExtractedGrammar {
  let transformed_variables : Array[InternedVariable] = []
  let auxiliary_variables : Array[InternedVariable] = []
  let repeat_symbols : Array[(InternedRule, InternalSymbol)] = []
  let repeat_counts : Array[(String, Int)] = []
  let inline_removals : Array[InternalSymbol] = []
  for variable in grammar.syntax.variables {
    match variable.rule {
      IRRepeat(content) if is_hidden_kind(variable.kind) => {
        let inner = expand_repeats_in_rule(
          content,
          variable.name,
          grammar.syntax.variables,
          auxiliary_variables,
          repeat_symbols,
          repeat_counts,
        )
        let rule = repeat_rule(variable.symbol, inner)
        transformed_variables.push({
          symbol: variable.symbol,
          name: variable.name,
          kind: VariableKind::Auxiliary,
          rule,
        })
        push_repeat_symbol(repeat_symbols, inner, variable.symbol)
        push_unique_internal_symbol(inline_removals, variable.symbol)
      }
      _ => {
        let rule = expand_repeats_in_rule(
          variable.rule,
          variable.name,
          grammar.syntax.variables,
          auxiliary_variables,
          repeat_symbols,
          repeat_counts,
        )
        transformed_variables.push({
          symbol: variable.symbol,
          name: variable.name,
          kind: variable.kind,
          rule,
        })
      }
    }
  }
  {
    syntax: {
      name: grammar.syntax.name,
      start_symbol: grammar.syntax.start_symbol,
      variables: append_interned_variables(
        transformed_variables, auxiliary_variables,
      ),
      extra_symbols: grammar.syntax.extra_symbols,
      external_tokens: grammar.syntax.external_tokens,
      inline_symbols: filter_internal_symbols(
        grammar.syntax.inline_symbols,
        inline_removals,
      ),
      conflict_symbols: grammar.syntax.conflict_symbols,
      precedence_orderings: grammar.syntax.precedence_orderings,
      word_symbol: grammar.syntax.word_symbol,
      reserved_sets: grammar.syntax.reserved_sets,
      supertype_symbols: grammar.syntax.supertype_symbols,
    },
    lexical: grammar.lexical,
  }
}

///|
fn append_interned_variables(
  left : Array[InternedVariable],
  right : Array[InternedVariable],
) -> Array[InternedVariable] {
  let result : Array[InternedVariable] = []
  for variable in left {
    result.push(variable)
  }
  for variable in right {
    result.push(variable)
  }
  result
}

///|
fn expand_repeats_in_rule(
  rule : InternedRule,
  current_name : String,
  base_variables : Array[InternedVariable],
  auxiliary_variables : Array[InternedVariable],
  repeat_symbols : Array[(InternedRule, InternalSymbol)],
  repeat_counts : Array[(String, Int)],
) -> InternedRule {
  match rule {
    IRAlias(content~, value~, named~) =>
      InternedRule::IRAlias(
        content=expand_repeats_in_rule(
          content, current_name, base_variables, auxiliary_variables, repeat_symbols,
          repeat_counts,
        ),
        value~,
        named~,
      )
    IRBlank | IRString(_) | IRPattern(_) | IRSymbol(_) => rule
    IRSeq(members) =>
      InternedRule::IRSeq(
        expand_repeats_in_rule_array(
          members, current_name, base_variables, auxiliary_variables, repeat_symbols,
          repeat_counts,
        ),
      )
    IRChoice(members) =>
      InternedRule::IRChoice(
        expand_repeats_in_rule_array(
          members, current_name, base_variables, auxiliary_variables, repeat_symbols,
          repeat_counts,
        ),
      )
    IRRepeat(content) => {
      let inner = expand_repeats_in_rule(
        content, current_name, base_variables, auxiliary_variables, repeat_symbols,
        repeat_counts,
      )
      InternedRule::IRSymbol(
        repeat_symbol(
          inner, current_name, base_variables, auxiliary_variables, repeat_symbols,
          repeat_counts,
        ),
      )
    }
    IRRepeat1(content) =>
      InternedRule::IRRepeat1(
        expand_repeats_in_rule(
          content, current_name, base_variables, auxiliary_variables, repeat_symbols,
          repeat_counts,
        ),
      )
    IRField(name~, content~) =>
      InternedRule::IRField(
        name~,
        content=expand_repeats_in_rule(
          content, current_name, base_variables, auxiliary_variables, repeat_symbols,
          repeat_counts,
        ),
      )
    IRPrec(value~, content~) =>
      InternedRule::IRPrec(
        value~,
        content=expand_repeats_in_rule(
          content, current_name, base_variables, auxiliary_variables, repeat_symbols,
          repeat_counts,
        ),
      )
    IRPrecLeft(value~, content~) =>
      InternedRule::IRPrecLeft(
        value~,
        content=expand_repeats_in_rule(
          content, current_name, base_variables, auxiliary_variables, repeat_symbols,
          repeat_counts,
        ),
      )
    IRPrecRight(value~, content~) =>
      InternedRule::IRPrecRight(
        value~,
        content=expand_repeats_in_rule(
          content, current_name, base_variables, auxiliary_variables, repeat_symbols,
          repeat_counts,
        ),
      )
    IRPrecDynamic(value~, content~) =>
      InternedRule::IRPrecDynamic(
        value~,
        content=expand_repeats_in_rule(
          content, current_name, base_variables, auxiliary_variables, repeat_symbols,
          repeat_counts,
        ),
      )
    IRToken(content) =>
      InternedRule::IRToken(
        expand_repeats_in_rule(
          content, current_name, base_variables, auxiliary_variables, repeat_symbols,
          repeat_counts,
        ),
      )
    IRImmediateToken(content) =>
      InternedRule::IRImmediateToken(
        expand_repeats_in_rule(
          content, current_name, base_variables, auxiliary_variables, repeat_symbols,
          repeat_counts,
        ),
      )
    IRReserved(context_name~, content~) =>
      InternedRule::IRReserved(
        context_name~,
        content=expand_repeats_in_rule(
          content, current_name, base_variables, auxiliary_variables, repeat_symbols,
          repeat_counts,
        ),
      )
  }
}

///|
fn expand_repeats_in_rule_array(
  rules : Array[InternedRule],
  current_name : String,
  base_variables : Array[InternedVariable],
  auxiliary_variables : Array[InternedVariable],
  repeat_symbols : Array[(InternedRule, InternalSymbol)],
  repeat_counts : Array[(String, Int)],
) -> Array[InternedRule] {
  let result = []
  for rule in rules {
    result.push(
      expand_repeats_in_rule(
        rule, current_name, base_variables, auxiliary_variables, repeat_symbols,
        repeat_counts,
      ),
    )
  }
  result
}

///|
fn repeat_symbol(
  inner : InternedRule,
  current_name : String,
  base_variables : Array[InternedVariable],
  auxiliary_variables : Array[InternedVariable],
  repeat_symbols : Array[(InternedRule, InternalSymbol)],
  repeat_counts : Array[(String, Int)],
) -> InternalSymbol {
  match find_repeat_symbol(repeat_symbols, inner) {
    Some(symbol) => symbol
    None => {
      let symbol = next_non_terminal_symbol(base_variables, auxiliary_variables)
      let index = next_repeat_index(current_name, repeat_counts)
      repeat_counts.push((current_name, index))
      auxiliary_variables.push({
        symbol,
        name: "\{current_name}_repeat\{index}",
        kind: VariableKind::Auxiliary,
        rule: repeat_rule(symbol, inner),
      })
      repeat_symbols.push((inner, symbol))
      symbol
    }
  }
}

///|
fn repeat_rule(symbol : InternalSymbol, inner : InternedRule) -> InternedRule {
  InternedRule::IRChoice([
    InternedRule::IRSeq([
      InternedRule::IRSymbol(symbol),
      InternedRule::IRSymbol(symbol),
    ]),
    inner,
  ])
}

///|
fn find_repeat_symbol(
  repeat_symbols : Array[(InternedRule, InternalSymbol)],
  inner : InternedRule,
) -> InternalSymbol? {
  for entry in repeat_symbols {
    if entry.0 == inner {
      return Some(entry.1)
    }
  }
  None
}

///|
fn push_repeat_symbol(
  repeat_symbols : Array[(InternedRule, InternalSymbol)],
  inner : InternedRule,
  symbol : InternalSymbol,
) -> Unit {
  if find_repeat_symbol(repeat_symbols, inner) is None {
    repeat_symbols.push((inner, symbol))
  }
}

///|
fn next_non_terminal_symbol(
  base_variables : Array[InternedVariable],
  auxiliary_variables : Array[InternedVariable],
) -> InternalSymbol {
  let mut next = 0
  for variable in base_variables {
    match variable.symbol {
      NonTerminal(index) => if index >= next { next = index + 1 }
      _ => ()
    }
  }
  for variable in auxiliary_variables {
    match variable.symbol {
      NonTerminal(index) => if index >= next { next = index + 1 }
      _ => ()
    }
  }
  InternalSymbol::NonTerminal(next)
}

///|
fn next_repeat_index(
  current_name : String,
  repeat_counts : Array[(String, Int)],
) -> Int {
  let mut next = 1
  for entry in repeat_counts {
    if entry.0 == current_name && entry.1 >= next {
      next = entry.1 + 1
    }
  }
  next
}

///|
fn filter_internal_symbols(
  symbols : Array[InternalSymbol],
  removals : Array[InternalSymbol],
) -> Array[InternalSymbol] {
  let result = []
  for symbol in symbols {
    if !contains_internal_symbol(removals, symbol) {
      result.push(symbol)
    }
  }
  result
}

///|
fn push_unique_internal_symbol(
  symbols : Array[InternalSymbol],
  symbol : InternalSymbol,
) -> Unit {
  if !contains_internal_symbol(symbols, symbol) {
    symbols.push(symbol)
  }
}

///|
fn extract_tokens(
  grammar : InternedGrammar,
) -> ExtractedGrammar raise GenerateError {
  let lexical_variables : Array[LexicalVariable] = []
  let lexical_renames : Array[(InternalSymbol, String, VariableKind)] = []
  let replacements : Array[(InternalSymbol, InternalSymbol)] = []
  let initial_variables : Array[InternedVariable] = []
  for variable in grammar.variables {
    let default_kind = start_rule_lexical_default_kind(
      variable.rule,
      variable.kind,
      is_start=is_start_symbol(variable.symbol, grammar.start_symbol),
    )
    let rule = extract_tokens_in_rule(
      variable.rule,
      lexical_variables,
      variable.name,
      default_kind,
    )
    match rule {
      IRSymbol(Terminal(_)) if !is_start_symbol(
          variable.symbol,
          grammar.start_symbol,
        ) => {
        if contains_internal_symbol(grammar.supertype_symbols, variable.symbol) {
          raise GenerateError::TerminalSupertype(variable.name)
        }
        let terminal = rule_symbol(rule)
        if should_transfer_lexical_name(
            terminal,
            variable.kind,
            lexical_variables,
          ) {
          lexical_renames.push((terminal, variable.name, variable.kind))
        }
        replacements.push((variable.symbol, terminal))
      }
      _ =>
        initial_variables.push({
          symbol: variable.symbol,
          name: variable.name,
          kind: variable.kind,
          rule,
        })
    }
  }

  let variables : Array[InternedVariable] = []
  for variable in initial_variables {
    variables.push({
      symbol: variable.symbol,
      name: variable.name,
      kind: variable.kind,
      rule: replace_symbols_in_rule(variable.rule, replacements),
    })
  }
  let external_tokens = extract_external_tokens(
    grammar.external_tokens,
    replacements,
    lexical_variables,
  )
  let extras = extract_extras(grammar.extras, replacements, lexical_variables)
  {
    syntax: {
      name: grammar.name,
      start_symbol: replace_optional_symbol(grammar.start_symbol, replacements),
      variables,
      extra_symbols: extras.symbols,
      external_tokens,
      inline_symbols: replace_symbol_array(grammar.inline_symbols, replacements),
      conflict_symbols: replace_symbol_matrix(
        grammar.conflict_symbols,
        replacements,
      ),
      precedence_orderings: grammar.precedence_orderings,
      word_symbol: replace_optional_symbol(grammar.word_symbol, replacements),
      reserved_sets: replace_reserved_sets(grammar.reserved_sets, replacements),
      supertype_symbols: replace_symbol_array(
        grammar.supertype_symbols,
        replacements,
      ),
    },
    lexical: {
      variables: apply_lexical_renames(lexical_variables, lexical_renames),
      separators: extras.separators,
    },
  }
}

///|
fn start_rule_lexical_default_kind(
  rule : InternedRule,
  default_kind : VariableKind,
  is_start~ : Bool,
) -> VariableKind {
  if is_start && is_direct_lexical_rule(rule) {
    VariableKind::Auxiliary
  } else {
    default_kind
  }
}

///|
fn rule_symbol(rule : InternedRule) -> InternalSymbol {
  match rule {
    IRSymbol(symbol) => symbol
    _ => InternalSymbol::NonTerminal(0)
  }
}

///|
fn is_start_symbol(symbol : InternalSymbol, start : InternalSymbol?) -> Bool {
  match start {
    Some(start_symbol) => symbol == start_symbol
    None => false
  }
}

///|
fn should_transfer_lexical_name(
  symbol : InternalSymbol,
  syntax_kind : VariableKind,
  lexical_variables : Array[LexicalVariable],
) -> Bool {
  match symbol {
    Terminal(index) =>
      if index >= 0 && index < lexical_variables.length() {
        is_auxiliary_kind(lexical_variables[index].kind) ||
        !is_hidden_kind(syntax_kind)
      } else {
        false
      }
    _ => false
  }
}

///|
fn is_hidden_kind(kind : VariableKind) -> Bool {
  kind is VariableKind::Hidden
}

///|
fn is_auxiliary_kind(kind : VariableKind) -> Bool {
  kind is VariableKind::Auxiliary
}

///|
fn apply_lexical_renames(
  variables : Array[LexicalVariable],
  renames : Array[(InternalSymbol, String, VariableKind)],
) -> Array[LexicalVariable] {
  let result : Array[LexicalVariable] = []
  for variable in variables {
    match find_lexical_rename(variable.symbol, renames) {
      Some(rename) =>
        result.push({
          symbol: variable.symbol,
          name: rename.0,
          kind: rename.1,
          rule: variable.rule,
        })
      None => result.push(variable)
    }
  }
  result
}

///|
fn find_lexical_rename(
  symbol : InternalSymbol,
  renames : Array[(InternalSymbol, String, VariableKind)],
) -> (String, VariableKind)? {
  for rename in renames {
    if rename.0 == symbol {
      return Some((rename.1, rename.2))
    }
  }
  None
}

///|
fn extract_tokens_in_rule(
  rule : InternedRule,
  lexical_variables : Array[LexicalVariable],
  default_name : String,
  default_kind : VariableKind,
) -> InternedRule {
  if is_direct_lexical_rule(rule) {
    return InternedRule::IRSymbol(
      find_or_create_lexical_variable(
        lexical_variables,
        rule,
        lexical_rule_name(rule, default_name, lexical_variables.length()),
        lexical_rule_kind(rule, default_kind),
      ),
    )
  }
  match rule {
    IRAlias(content~, value~, named~) =>
      InternedRule::IRAlias(
        content=extract_tokens_in_rule(
          content, lexical_variables, default_name, default_kind,
        ),
        value~,
        named~,
      )
    IRBlank => InternedRule::IRBlank
    IRString(_) | IRPattern(_) | IRToken(_) | IRImmediateToken(_) => rule
    IRSymbol(_) => rule
    IRSeq(members) =>
      InternedRule::IRSeq(
        extract_tokens_in_rule_array(
          members, lexical_variables, default_name, default_kind,
        ),
      )
    IRChoice(members) =>
      InternedRule::IRChoice(
        extract_tokens_in_rule_array(
          members, lexical_variables, default_name, default_kind,
        ),
      )
    IRRepeat(content) =>
      InternedRule::IRRepeat(
        extract_tokens_in_rule(
          content, lexical_variables, default_name, default_kind,
        ),
      )
    IRRepeat1(content) =>
      InternedRule::IRRepeat1(
        extract_tokens_in_rule(
          content, lexical_variables, default_name, default_kind,
        ),
      )
    IRField(name~, content~) =>
      InternedRule::IRField(
        name~,
        content=extract_tokens_in_rule(
          content, lexical_variables, default_name, default_kind,
        ),
      )
    IRPrec(value~, content~) =>
      InternedRule::IRPrec(
        value~,
        content=extract_tokens_in_rule(
          content, lexical_variables, default_name, default_kind,
        ),
      )
    IRPrecLeft(value~, content~) =>
      InternedRule::IRPrecLeft(
        value~,
        content=extract_tokens_in_rule(
          content, lexical_variables, default_name, default_kind,
        ),
      )
    IRPrecRight(value~, content~) =>
      InternedRule::IRPrecRight(
        value~,
        content=extract_tokens_in_rule(
          content, lexical_variables, default_name, default_kind,
        ),
      )
    IRPrecDynamic(value~, content~) =>
      InternedRule::IRPrecDynamic(
        value~,
        content=extract_tokens_in_rule(
          content, lexical_variables, default_name, default_kind,
        ),
      )
    IRReserved(context_name~, content~) =>
      InternedRule::IRReserved(
        context_name~,
        content=extract_tokens_in_rule(
          content, lexical_variables, default_name, default_kind,
        ),
      )
  }
}

///|
fn extract_tokens_in_rule_array(
  rules : Array[InternedRule],
  lexical_variables : Array[LexicalVariable],
  default_name : String,
  default_kind : VariableKind,
) -> Array[InternedRule] {
  let result = []
  for rule in rules {
    result.push(
      extract_tokens_in_rule(
        rule, lexical_variables, default_name, default_kind,
      ),
    )
  }
  result
}

///|
fn is_direct_lexical_rule(rule : InternedRule) -> Bool {
  match rule {
    IRString(_) | IRPattern(_) | IRToken(_) | IRImmediateToken(_) => true
    _ => false
  }
}

///|
fn lexical_rule_name(
  rule : InternedRule,
  default_name : String,
  fallback_index : Int,
) -> String {
  match rule {
    IRString(value) => value
    _ =>
      if default_name.is_empty() {
        "_token\{fallback_index}"
      } else {
        default_name
      }
  }
}

///|
fn lexical_rule_kind(
  rule : InternedRule,
  default_kind : VariableKind,
) -> VariableKind {
  match rule {
    IRString(_) => VariableKind::Anonymous
    IRPattern(_) | IRToken(_) | IRImmediateToken(_) => default_kind
    _ => VariableKind::Auxiliary
  }
}

///|
fn find_or_create_lexical_variable(
  variables : Array[LexicalVariable],
  rule : InternedRule,
  name : String,
  kind : VariableKind,
) -> InternalSymbol {
  match find_lexical_variable(variables, rule) {
    Some(symbol) => symbol
    None => {
      let index = variables.length()
      variables.push({
        symbol: InternalSymbol::Terminal(index),
        name,
        kind,
        rule,
      })
      InternalSymbol::Terminal(index)
    }
  }
}

///|
fn find_lexical_variable(
  variables : Array[LexicalVariable],
  rule : InternedRule,
) -> InternalSymbol? {
  for i in 0..<variables.length() {
    if variables[i].rule == rule {
      return Some(InternalSymbol::Terminal(i))
    }
  }
  None
}

///|
fn extract_external_tokens(
  tokens : Array[InternedExternalToken],
  replacements : Array[(InternalSymbol, InternalSymbol)],
  lexical_variables : Array[LexicalVariable],
) -> Array[ExtractedExternalToken] raise GenerateError {
  let result : Array[ExtractedExternalToken] = []
  for token in tokens {
    let extracted = extract_tokens_in_rule(
      token.rule,
      lexical_variables,
      token.name,
      token.kind,
    )
    let rule = replace_symbols_in_rule(extracted, replacements)
    let corresponding_internal_token = match rule {
      IRSymbol(External(_)) => None
      IRSymbol(Terminal(_)) => Some(rule_symbol(rule))
      _ => raise GenerateError::InvalidExternalToken(token.name)
    }
    result.push({
      symbol: token.symbol,
      name: token.name,
      kind: token.kind,
      corresponding_internal_token,
      rule,
    })
  }
  result
}

///|
priv struct ExtractedExtras {
  symbols : Array[InternalSymbol]
  separators : Array[InternedRule]
}

///|
fn extract_extras(
  extras : Array[InternedRule],
  replacements : Array[(InternalSymbol, InternalSymbol)],
  lexical_variables : Array[LexicalVariable],
) -> ExtractedExtras {
  let symbols = []
  let separators = []
  for extra in extras {
    let rule = replace_symbols_in_rule(extra, replacements)
    match rule {
      IRSymbol(symbol) => symbols.push(symbol)
      _ =>
        if is_direct_lexical_rule(rule) {
          match find_lexical_variable(lexical_variables, rule) {
            Some(symbol) => symbols.push(symbol)
            None => separators.push(rule)
          }
        } else {
          separators.push(rule)
        }
    }
  }
  { symbols, separators }
}

///|
fn replace_optional_symbol(
  symbol : InternalSymbol?,
  replacements : Array[(InternalSymbol, InternalSymbol)],
) -> InternalSymbol? {
  match symbol {
    Some(value) => Some(replace_symbol(value, replacements))
    None => None
  }
}

///|
fn replace_symbol_array(
  symbols : Array[InternalSymbol],
  replacements : Array[(InternalSymbol, InternalSymbol)],
) -> Array[InternalSymbol] {
  let result = []
  for symbol in symbols {
    result.push(replace_symbol(symbol, replacements))
  }
  result
}

///|
fn replace_symbol_matrix(
  rows : Array[Array[InternalSymbol]],
  replacements : Array[(InternalSymbol, InternalSymbol)],
) -> Array[Array[InternalSymbol]] {
  let result = []
  for row in rows {
    result.push(replace_symbol_array(row, replacements))
  }
  result
}

///|
fn replace_reserved_sets(
  sets : Array[InternedReservedSet],
  replacements : Array[(InternalSymbol, InternalSymbol)],
) -> Array[ExtractedReservedSet] {
  let result : Array[ExtractedReservedSet] = []
  for set in sets {
    result.push({
      name: set.name,
      rules: replace_symbols_in_rule_array(set.rules, replacements),
    })
  }
  result
}

///|
fn replace_symbols_in_rule_array(
  rules : Array[InternedRule],
  replacements : Array[(InternalSymbol, InternalSymbol)],
) -> Array[InternedRule] {
  let result = []
  for rule in rules {
    result.push(replace_symbols_in_rule(rule, replacements))
  }
  result
}

///|
fn replace_symbols_in_rule(
  rule : InternedRule,
  replacements : Array[(InternalSymbol, InternalSymbol)],
) -> InternedRule {
  match rule {
    IRAlias(content~, value~, named~) =>
      InternedRule::IRAlias(
        content=replace_symbols_in_rule(content, replacements),
        value~,
        named~,
      )
    IRBlank | IRString(_) | IRPattern(_) => rule
    IRSymbol(symbol) =>
      InternedRule::IRSymbol(replace_symbol(symbol, replacements))
    IRSeq(members) =>
      InternedRule::IRSeq(replace_symbols_in_rule_array(members, replacements))
    IRChoice(members) =>
      InternedRule::IRChoice(
        replace_symbols_in_rule_array(members, replacements),
      )
    IRRepeat(content) =>
      InternedRule::IRRepeat(replace_symbols_in_rule(content, replacements))
    IRRepeat1(content) =>
      InternedRule::IRRepeat1(replace_symbols_in_rule(content, replacements))
    IRField(name~, content~) =>
      InternedRule::IRField(
        name~,
        content=replace_symbols_in_rule(content, replacements),
      )
    IRPrec(value~, content~) =>
      InternedRule::IRPrec(
        value~,
        content=replace_symbols_in_rule(content, replacements),
      )
    IRPrecLeft(value~, content~) =>
      InternedRule::IRPrecLeft(
        value~,
        content=replace_symbols_in_rule(content, replacements),
      )
    IRPrecRight(value~, content~) =>
      InternedRule::IRPrecRight(
        value~,
        content=replace_symbols_in_rule(content, replacements),
      )
    IRPrecDynamic(value~, content~) =>
      InternedRule::IRPrecDynamic(
        value~,
        content=replace_symbols_in_rule(content, replacements),
      )
    IRToken(content) =>
      InternedRule::IRToken(replace_symbols_in_rule(content, replacements))
    IRImmediateToken(content) =>
      InternedRule::IRImmediateToken(
        replace_symbols_in_rule(content, replacements),
      )
    IRReserved(context_name~, content~) =>
      InternedRule::IRReserved(
        context_name~,
        content=replace_symbols_in_rule(content, replacements),
      )
  }
}

///|
fn replace_symbol(
  symbol : InternalSymbol,
  replacements : Array[(InternalSymbol, InternalSymbol)],
) -> InternalSymbol {
  for replacement in replacements {
    if replacement.0 == symbol {
      return replacement.1
    }
  }
  symbol
}

///|
fn contains_internal_symbol(
  symbols : Array[InternalSymbol],
  symbol : InternalSymbol,
) -> Bool {
  for existing in symbols {
    if existing == symbol {
      return true
    }
  }
  false
}

///|
fn intern_symbols(
  grammar : @grammar.InputGrammar,
) -> InternedGrammar raise GenerateError {
  let variables : Array[InternedVariable] = []
  for i in 0..<grammar.rules.length() {
    let variable = grammar.rules[i]
    variables.push({
      symbol: InternalSymbol::NonTerminal(i),
      name: variable.name,
      kind: variable_kind(variable.name, grammar.supertypes),
      rule: intern_rule(variable.rule, grammar),
    })
  }
  {
    name: grammar.name,
    start_symbol: match grammar.start_rule {
      Some(name) => Some(resolve_symbol(grammar, name))
      None => None
    },
    variables,
    extras: intern_rule_array(grammar.extras, grammar),
    external_tokens: intern_external_tokens(grammar),
    inline_symbols: intern_symbol_names(grammar.inline, grammar),
    conflict_symbols: intern_symbol_matrix(grammar.conflicts, grammar),
    precedence_orderings: grammar.precedences,
    word_symbol: match grammar.word {
      Some(name) => Some(resolve_symbol(grammar, name))
      None => None
    },
    reserved_sets: intern_reserved_sets(grammar.reserved, grammar),
    supertype_symbols: intern_symbol_names(grammar.supertypes, grammar),
  }
}

///|
fn intern_external_tokens(
  grammar : @grammar.InputGrammar,
) -> Array[InternedExternalToken] raise GenerateError {
  let tokens : Array[InternedExternalToken] = []
  for i in 0..<grammar.externals.length() {
    let rule = grammar.externals[i]
    let name = external_token_name(rule, i)
    tokens.push({
      symbol: InternalSymbol::External(i),
      name,
      kind: variable_kind(name, []),
      rule: intern_external_rule(rule, grammar, i),
    })
  }
  tokens
}

///|
fn external_token_name(rule : @grammar.Rule, index : Int) -> String {
  match rule {
    Symbol(name) => name
    _ => "_external_token\{index}"
  }
}

///|
fn intern_external_rule(
  rule : @grammar.Rule,
  grammar : @grammar.InputGrammar,
  external_index : Int,
) -> InternedRule raise GenerateError {
  match rule {
    Symbol(name) =>
      match resolve_non_terminal(grammar, name) {
        Some(symbol) => InternedRule::IRSymbol(symbol)
        None =>
          if external_token_name(rule, external_index) == name {
            InternedRule::IRSymbol(InternalSymbol::External(external_index))
          } else {
            InternedRule::IRSymbol(resolve_symbol(grammar, name))
          }
      }
    _ => intern_rule(rule, grammar)
  }
}

///|
fn intern_rule_array(
  rules : Array[@grammar.Rule],
  grammar : @grammar.InputGrammar,
) -> Array[InternedRule] raise GenerateError {
  let interned = []
  for rule in rules {
    interned.push(intern_rule(rule, grammar))
  }
  interned
}

///|
fn intern_rule(
  rule : @grammar.Rule,
  grammar : @grammar.InputGrammar,
) -> InternedRule raise GenerateError {
  match rule {
    Alias(content~, value~, named~) =>
      InternedRule::IRAlias(
        content=intern_rule(content, grammar),
        value~,
        named~,
      )
    Blank => InternedRule::IRBlank
    String(value) => InternedRule::IRString(value)
    Pattern(value~, flags~) => InternedRule::IRPattern(value~, flags~)
    Symbol(name) => InternedRule::IRSymbol(resolve_symbol(grammar, name))
    Seq(members) => InternedRule::IRSeq(intern_rule_array(members, grammar))
    Choice(members) =>
      InternedRule::IRChoice(intern_rule_array(members, grammar))
    Repeat(content) => InternedRule::IRRepeat(intern_rule(content, grammar))
    Repeat1(content) => InternedRule::IRRepeat1(intern_rule(content, grammar))
    Field(name~, content~) =>
      InternedRule::IRField(name~, content=intern_rule(content, grammar))
    Prec(value~, content~) =>
      InternedRule::IRPrec(value~, content=intern_rule(content, grammar))
    PrecLeft(value~, content~) =>
      InternedRule::IRPrecLeft(value~, content=intern_rule(content, grammar))
    PrecRight(value~, content~) =>
      InternedRule::IRPrecRight(value~, content=intern_rule(content, grammar))
    PrecDynamic(value~, content~) =>
      InternedRule::IRPrecDynamic(value~, content=intern_rule(content, grammar))
    Token(content) => InternedRule::IRToken(intern_rule(content, grammar))
    ImmediateToken(content) =>
      InternedRule::IRImmediateToken(intern_rule(content, grammar))
    Reserved(context_name~, content~) =>
      InternedRule::IRReserved(
        context_name~,
        content=intern_rule(content, grammar),
      )
  }
}

///|
fn intern_symbol_names(
  names : Array[String],
  grammar : @grammar.InputGrammar,
) -> Array[InternalSymbol] raise GenerateError {
  let symbols = []
  for name in names {
    symbols.push(resolve_symbol(grammar, name))
  }
  symbols
}

///|
fn intern_symbol_matrix(
  rows : Array[Array[String]],
  grammar : @grammar.InputGrammar,
) -> Array[Array[InternalSymbol]] raise GenerateError {
  let interned_rows = []
  for row in rows {
    interned_rows.push(intern_symbol_names(row, grammar))
  }
  interned_rows
}

///|
fn intern_reserved_sets(
  sets : Array[@grammar.ReservedSet],
  grammar : @grammar.InputGrammar,
) -> Array[InternedReservedSet] raise GenerateError {
  let interned_sets : Array[InternedReservedSet] = []
  for set in sets {
    interned_sets.push({
      name: set.name,
      rules: intern_rule_array(set.rules, grammar),
    })
  }
  interned_sets
}

///|
fn resolve_symbol(
  grammar : @grammar.InputGrammar,
  name : String,
) -> InternalSymbol raise GenerateError {
  match resolve_non_terminal(grammar, name) {
    Some(symbol) => symbol
    None =>
      match resolve_external(grammar, name) {
        Some(symbol) => symbol
        None => raise GenerateError::UndefinedSymbol(name)
      }
  }
}

///|
fn resolve_non_terminal(
  grammar : @grammar.InputGrammar,
  name : String,
) -> InternalSymbol? {
  for i in 0..<grammar.rules.length() {
    if grammar.rules[i].name == name {
      return Some(InternalSymbol::NonTerminal(i))
    }
  }
  None
}

///|
fn resolve_external(
  grammar : @grammar.InputGrammar,
  name : String,
) -> InternalSymbol? {
  for i in 0..<grammar.externals.length() {
    if external_token_name(grammar.externals[i], i) == name {
      return Some(InternalSymbol::External(i))
    }
  }
  None
}

///|
fn variable_kind(name : String, supertypes : Array[String]) -> VariableKind {
  if contains_string(supertypes, name) || has_hidden_prefix(name) {
    VariableKind::Hidden
  } else {
    VariableKind::Named
  }
}

///|
fn has_hidden_prefix(name : String) -> Bool {
  let chars = name.to_array()
  chars.length() > 0 && chars[0] == '_'
}

///|
fn validate_indirect_recursion(
  grammar : @grammar.InputGrammar,
) -> Unit raise GenerateError {
  for variable in grammar.rules {
    let path = [variable.name]
    match find_indirect_recursion(grammar, variable.name, variable.name, path) {
      Some(cycle) => raise GenerateError::IndirectRecursion(cycle)
      None => ()
    }
  }
}

///|
fn find_indirect_recursion(
  grammar : @grammar.InputGrammar,
  start : String,
  current : String,
  path : Array[String],
) -> String? {
  match find_rule(grammar, current) {
    Some(variable) => {
      let targets = single_symbol_targets(variable.rule, current)
      for target in targets {
        if target == start {
          let cycle = path.copy()
          cycle.push(target)
          return Some(cycle.join(" -> "))
        }
        if !contains_string(path, target) {
          let next_path = path.copy()
          next_path.push(target)
          match find_indirect_recursion(grammar, start, target, next_path) {
            Some(cycle) => return Some(cycle)
            None => ()
          }
        }
      }
      None
    }
    None => None
  }
}

///|
fn find_rule(
  grammar : @grammar.InputGrammar,
  name : String,
) -> @grammar.NamedRule? {
  for variable in grammar.rules {
    if variable.name == name {
      return Some(variable)
    }
  }
  None
}

///|
fn single_symbol_targets(
  rule : @grammar.Rule,
  source : String,
) -> Array[String] {
  let targets = []
  collect_single_symbol_targets(rule, source, targets)
  targets
}

///|
fn collect_single_symbol_targets(
  rule : @grammar.Rule,
  source : String,
  targets : Array[String],
) -> Unit {
  match rule {
    Symbol(name) => if name != source { push_unique_string(targets, name) }
    Choice(members) =>
      for item in members {
        collect_single_symbol_targets(item, source, targets)
      }
    Alias(content~, ..)
    | Field(content~, ..)
    | Prec(content~, ..)
    | PrecLeft(content~, ..)
    | PrecRight(content~, ..)
    | PrecDynamic(content~, ..) =>
      collect_single_symbol_targets(content, source, targets)
    Blank
    | String(_)
    | Pattern(_)
    | Seq(_)
    | Repeat(_)
    | Repeat1(_)
    | Token(_)
    | ImmediateToken(_)
    | Reserved(..) => ()
  }
}

///|
fn validate_precedences(
  grammar : @grammar.InputGrammar,
) -> Unit raise GenerateError {
  let declarations = precedence_declarations(grammar.precedences)
  validate_precedence_ordering(grammar.precedences)
  for variable in grammar.rules {
    validate_precedences_in_rule(variable.rule, declarations)
  }
}

///|
fn precedence_declarations(
  precedences : Array[Array[@grammar.PrecedenceValue]],
) -> Array[String] {
  let declarations = []
  for row in precedences {
    for entry in row {
      match entry {
        Name(name) => push_unique_string(declarations, name)
        Number(_) => ()
      }
    }
  }
  declarations
}

///|
fn validate_precedence_ordering(
  precedences : Array[Array[@grammar.PrecedenceValue]],
) -> Unit raise GenerateError {
  let relations : Array[(String, String)] = []
  for row in precedences {
    for i in 0..<row.length() {
      match row[i] {
        Name(left) => {
          let start = i + 1
          for j in start..<row.length() {
            match row[j] {
              Name(right) =>
                if left != right {
                  if contains_relation(relations, right, left) {
                    raise GenerateError::ConflictingPrecedenceOrdering(
                      left~,
                      right~,
                    )
                  }
                  if !contains_relation(relations, left, right) {
                    relations.push((left, right))
                  }
                }
              Number(_) => ()
            }
          }
        }
        Number(_) => ()
      }
    }
  }
}

///|
fn validate_precedences_in_rule(
  rule : @grammar.Rule,
  declarations : Array[String],
) -> Unit raise GenerateError {
  match rule {
    Prec(value~, content~)
    | PrecLeft(value~, content~)
    | PrecRight(value~, content~) => {
      match value {
        Name(name) =>
          if !contains_string(declarations, name) {
            raise GenerateError::UndeclaredPrecedence(name)
          }
        Number(_) => ()
      }
      validate_precedences_in_rule(content, declarations)
    }
    Alias(content~, ..)
    | Repeat(content)
    | Repeat1(content)
    | Field(content~, ..)
    | PrecDynamic(content~, ..)
    | Token(content)
    | ImmediateToken(content) =>
      validate_precedences_in_rule(content, declarations)
    Seq(members) | Choice(members) =>
      for item in members {
        validate_precedences_in_rule(item, declarations)
      }
    Reserved(..) => ()
    Blank | String(_) | Pattern(_) | Symbol(_) => ()
  }
}

///|
fn contains_relation(
  relations : Array[(String, String)],
  left : String,
  right : String,
) -> Bool {
  for relation in relations {
    if relation.0 == left && relation.1 == right {
      return true
    }
  }
  false
}

///|
fn push_unique_string(values : Array[String], value : String) -> Unit {
  if !contains_string(values, value) {
    values.push(value)
  }
}

///|
fn contains_string(values : Array[String], value : String) -> Bool {
  for existing in values {
    if existing == value {
      return true
    }
  }
  false
}

///|
fn describe_grammar_error(err : @grammar.GrammarError) -> String {
  match err {
    InvalidJson(message) => "InvalidJson: \{message}"
    ExpectedObject(path) => "ExpectedObject: \{path}"
    ExpectedArray(path) => "ExpectedArray: \{path}"
    ExpectedString(path) => "ExpectedString: \{path}"
    ExpectedBool(path) => "ExpectedBool: \{path}"
    ExpectedNumber(path) => "ExpectedNumber: \{path}"
    MissingField(path~, field~) => "MissingField: \{path}.\{field}"
    UnknownRuleType(path~, rule_type~) =>
      "UnknownRuleType: \{path} \{rule_type}"
    InvalidPrecedence(path) => "InvalidPrecedence: \{path}"
    TokenContainsSymbol(path~, symbol~) =>
      "TokenContainsSymbol: \{path} \{symbol}"
    EmptyStringExtra(path) => "EmptyStringExtra: \{path}"
    UndeclaredReservedContext(context_name) =>
      "UndeclaredReservedContext: \{context_name}"
  }
}

///|
fn validate_import_alias(import_alias : String) -> Unit raise GenerateError {
  let chars = import_alias.to_array()
  if chars.is_empty() ||
    !import_alias_start_char_is_valid(chars[0]) ||
    moonbit_keyword_is_reserved(import_alias) {
    raise GenerateError::InvalidImportAlias(import_alias)
  }
  for i in 1..<chars.length() {
    if !import_alias_continue_char_is_valid(chars[i]) {
      raise GenerateError::InvalidImportAlias(import_alias)
    }
  }
}

///|
fn validate_import_aliases(
  options : GenerateOptions,
) -> Unit raise GenerateError {
  validate_import_alias(options.root_alias)
  validate_import_alias(options.tables_alias)
  validate_import_alias(options.api_alias)
  if options.root_alias == options.tables_alias {
    raise GenerateError::InvalidImportAlias(options.root_alias)
  }
  if options.root_alias == options.api_alias {
    raise GenerateError::InvalidImportAlias(options.root_alias)
  }
  if options.tables_alias == options.api_alias {
    raise GenerateError::InvalidImportAlias(options.tables_alias)
  }
}

///|
fn import_alias_start_char_is_valid(char : Char) -> Bool {
  import_alias_char_is_ascii_alpha(char) || char == '_'
}

///|
fn import_alias_continue_char_is_valid(char : Char) -> Bool {
  import_alias_start_char_is_valid(char) ||
  import_alias_char_is_ascii_digit(char)
}

///|
fn import_alias_char_is_ascii_alpha(char : Char) -> Bool {
  let value = char.to_uint()
  (65U <= value && value <= 90U) || (97U <= value && value <= 122U)
}

///|
fn import_alias_char_is_ascii_digit(char : Char) -> Bool {
  let value = char.to_uint()
  48U <= value && value <= 57U
}

///|
fn moonbit_keyword_is_reserved(value : String) -> Bool {
  match value {
    "as"
    | "async"
    | "break"
    | "catch"
    | "const"
    | "continue"
    | "derive"
    | "else"
    | "enum"
    | "extern"
    | "false"
    | "fn"
    | "for"
    | "guard"
    | "if"
    | "impl"
    | "import"
    | "in"
    | "interface"
    | "is"
    | "let"
    | "loop"
    | "match"
    | "mut"
    | "priv"
    | "pub"
    | "raise"
    | "return"
    | "struct"
    | "suberror"
    | "test"
    | "trait"
    | "true"
    | "try"
    | "type"
    | "while"
    | "with" => true
    _ => false
  }
}
