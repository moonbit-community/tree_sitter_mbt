///|
priv enum ParseTerminalSymbol {
  ParseTerminal(Int)
  ParseExternal(Int)
  ParseEnd
  ParseEndOfNonTerminalExtra
}

///|
priv enum ParseTableSymbolDraft {
  ParseSymbolEnd
  ParseSymbolTerminal(Int)
  ParseSymbolExternal(Int)
  ParseSymbolNonTerminal(Int)
}

///|
priv struct ParseShiftContributor {
  symbol : InternalSymbol
  precedence : @grammar.PrecedenceValue?
  associativity : Associativity
}

///|
priv enum ParseActionDraft {
  DraftAccept
  DraftShift(
    state_id~ : Int,
    is_repetition~ : Bool,
    contributors~ : Array[ParseShiftContributor]
  )
  DraftShiftExtra
  DraftReduce(
    symbol~ : InternalSymbol,
    child_count~ : Int,
    dynamic_precedence~ : Int,
    production_id~ : Int,
    precedence~ : @grammar.PrecedenceValue?,
    associativity~ : Associativity
  )
}

///|
priv enum ParseActionConflictResolution {
  KeepBoth
  KeepExisting
  ReplaceExisting
  DropBoth
}

///|
priv enum ParseShiftReduceDecision {
  PreferShift
  PreferReduce
  PreserveBoth
  DropShiftAndReduce
} derive(Eq)

///|
priv enum ParseGotoDraft {
  DraftGoto(Int)
  DraftGotoShiftExtra
}

///|
priv enum ParseTableCellDraft {
  ParseCellEmpty
  ParseCellAction(Int)
  ParseCellState(Int)
}

///|
priv enum ParseSmallParseTableSectionKindDraft {
  ParseSmallAction
  ParseSmallState
}

///|
priv struct ParseTerminalEntryDraft {
  symbol : ParseTerminalSymbol
  actions : Array[ParseActionDraft]
  mut action_list_id : Int
}

///|
priv struct ParseGotoEntryDraft {
  symbol : InternalSymbol
  action : ParseGotoDraft
}

///|
priv struct ParseStateDraft {
  id : Int
  core_id : Int
  terminal_entries : Array[ParseTerminalEntryDraft]
  nonterminal_entries : Array[ParseGotoEntryDraft]
  mut reserved_words : ParseTokenSet
}

///|
priv struct ParseAliasDraft {
  value : String
  named : Bool
}

///|
priv struct ParseFieldLocationDraft {
  index : Int
  inherited : Bool
}

///|
priv struct ParseFieldMapEntryDraft {
  name : String
  locations : Array[ParseFieldLocationDraft]
}

///|
priv struct ParseProductionInfoDraft {
  alias_sequence : Array[ParseAliasDraft?]
  field_map : Array[ParseFieldMapEntryDraft]
}

///|
priv struct ParseActionListDraft {
  actions : Array[ParseActionDraft]
  reusable : Bool
}

///|
priv struct ParseUsedSymbolsDraft {
  tokens : ParseTokenSet
  nonterminals : Array[Int]
}

///|
priv struct ParseReservedWordSetsDraft {
  sets : Array[ParseTokenSet]
  state_ids : Array[Int]
  mut max_size : Int
}

///|
priv struct ParseExternalLexStatesDraft {
  sets : Array[ParseTokenSet]
  state_ids : Array[Int]
}

///|
priv struct ParseSmallParseTableSectionDraft {
  kind : ParseSmallParseTableSectionKindDraft
  value : Int
  first_symbol : ParseTableSymbolDraft
  symbols : Array[ParseTableSymbolDraft]
}

///|
priv struct ParseSmallParseTableRowDraft {
  state_id : Int
  offset : Int
  sections : Array[ParseSmallParseTableSectionDraft]
}

///|
priv struct ParseTableLayoutDraft {
  large_state_count : Int
  large_rows : Array[Array[ParseTableCellDraft]]
  small_rows : Array[ParseSmallParseTableRowDraft]
  small_state_offsets : Array[Int]
}

///|
priv struct ParseTableDraft {
  mut states : Array[ParseStateDraft]
  mut symbols : Array[ParseTableSymbolDraft]
  mut primary_state_ids : Array[Int]
  nonterminal_extra_state_ids : Array[Int]
  mut reserved_word_sets : ParseReservedWordSetsDraft
  mut external_lex_states : ParseExternalLexStatesDraft
  parse_action_lists : Array[ParseActionListDraft]
  mut layout : ParseTableLayoutDraft
  production_infos : Array[ParseProductionInfoDraft]
  mut max_aliased_production_length : Int
  mut used_symbols : ParseUsedSymbolsDraft
}

///|
fn build_parse_table_draft(
  builder : ParseItemSetBuilder,
  graph : ParseStateGraph,
) -> ParseTableDraft raise GenerateError {
  let table : ParseTableDraft = {
    states: [],
    symbols: [],
    primary_state_ids: [],
    nonterminal_extra_state_ids: [],
    reserved_word_sets: parse_reserved_word_sets_empty(),
    external_lex_states: parse_external_lex_states_empty(),
    parse_action_lists: [],
    layout: parse_table_layout_empty(),
    production_infos: [parse_production_info_empty()],
    max_aliased_production_length: 1,
    used_symbols: parse_used_symbols_empty(),
  }
  let states : Array[ParseStateDraft] = []
  for state in graph.states {
    let draft_state : ParseStateDraft = {
      id: state.id,
      core_id: state.core_id,
      terminal_entries: [],
      nonterminal_entries: [],
      reserved_words: parse_token_set_empty(),
    }
    let closed = builder.transitive_closure(state.item_set)
    if parse_item_set_has_nonterminal_extra_end(closed) {
      table.nonterminal_extra_state_ids.push(state.id)
    }
    draft_state.reserved_words = parse_state_reserved_words(builder, closed)
    add_reduce_actions(table, draft_state, builder, closed)
    for transition in state.terminal_transitions {
      parse_state_draft_add_action(
        draft_state,
        parse_terminal_symbol_from_internal(transition.symbol),
        parse_shift_action_for_transition(closed, transition),
        grammar=builder.grammar,
      )
    }
    for transition in state.nonterminal_transitions {
      parse_state_draft_add_goto(
        draft_state,
        transition.symbol,
        ParseGotoDraft::DraftGoto(transition.state_id),
      )
    }
    add_extra_actions(draft_state, builder, graph, closed)
    states.push(draft_state)
  }
  table.states = states
  table.reserved_word_sets = parse_reserved_word_sets_from_states(table.states)
  table.external_lex_states = parse_external_lex_states_from_states(
    builder.grammar,
    table.states,
  )
  table.used_symbols = parse_used_symbols_collect_table(table)
  table.symbols = parse_table_symbols_from_used(
    builder.grammar,
    table.used_symbols,
  )
  table.primary_state_ids = parse_table_primary_state_ids(table.states)
  parse_table_draft_assign_action_lists(table, builder.grammar)
  table.layout = parse_table_layout_from_draft(table)
  validate_parse_table_draft_width(table)
  table
}

///|
fn parse_used_symbols_empty() -> ParseUsedSymbolsDraft {
  { tokens: parse_token_set_empty(), nonterminals: [] }
}

///|
fn parse_action_list_empty() -> ParseActionListDraft {
  { actions: [], reusable: false }
}

///|
fn parse_reserved_word_sets_empty() -> ParseReservedWordSetsDraft {
  { sets: [parse_token_set_empty()], state_ids: [], max_size: 0 }
}

///|
fn parse_external_lex_states_empty() -> ParseExternalLexStatesDraft {
  { sets: [parse_token_set_empty()], state_ids: [] }
}

///|
fn parse_table_layout_empty() -> ParseTableLayoutDraft {
  {
    large_state_count: 0,
    large_rows: [],
    small_rows: [],
    small_state_offsets: [],
  }
}

///|
fn parse_reserved_word_sets_from_states(
  states : Array[ParseStateDraft],
) -> ParseReservedWordSetsDraft {
  let result = parse_reserved_word_sets_empty()
  for state in states {
    let id = parse_reserved_word_set_id(result, state.reserved_words)
    result.state_ids.push(id)
    let size = parse_token_set_symbol_count(result.sets[id])
    if size > result.max_size {
      result.max_size = size
    }
  }
  result
}

///|
fn parse_external_lex_states_from_states(
  grammar : PreparedGrammar,
  states : Array[ParseStateDraft],
) -> ParseExternalLexStatesDraft {
  let result = parse_external_lex_states_empty()
  for state in states {
    let id = parse_external_lex_state_id(
      result,
      parse_external_lex_state_for_state(grammar, state),
    )
    result.state_ids.push(id)
  }
  result
}

///|
fn parse_external_lex_state_for_state(
  grammar : PreparedGrammar,
  state : ParseStateDraft,
) -> ParseTokenSet {
  let set = parse_token_set_empty()
  for entry in state.terminal_entries {
    match entry.symbol {
      ParseExternal(index) =>
        parse_token_set_insert_symbol(set, InternalSymbol::External(index))
      ParseTerminal(index) =>
        match parse_external_token_for_internal(grammar, index) {
          Some(external_index) =>
            parse_token_set_insert_symbol(
              set,
              InternalSymbol::External(external_index),
            )
          None => ()
        }
      ParseEnd | ParseEndOfNonTerminalExtra => ()
    }
  }
  set
}

///|
fn parse_item_set_has_nonterminal_extra_end(item_set : ParseItemSet) -> Bool {
  for entry in item_set.entries {
    if entry.lookaheads.end_of_nonterminal_extra {
      return true
    }
  }
  false
}

///|
fn parse_external_token_for_internal(
  grammar : PreparedGrammar,
  terminal_index : Int,
) -> Int? {
  let mut result : Int? = None
  for i in 0..<grammar.syntax.external_tokens.length() {
    if grammar.syntax.external_tokens[i].corresponding_internal_token ==
      Some(InternalSymbol::Terminal(terminal_index)) {
      result = Some(i)
    }
  }
  result
}

///|
fn parse_external_lex_state_id(
  table : ParseExternalLexStatesDraft,
  set : ParseTokenSet,
) -> Int {
  for i in 0..<table.sets.length() {
    if parse_token_set_same(table.sets[i], set) {
      return i
    }
  }
  let id = table.sets.length()
  table.sets.push(parse_token_set_clone(set))
  id
}

///|
fn parse_reserved_word_set_id(
  table : ParseReservedWordSetsDraft,
  set : ParseTokenSet,
) -> Int {
  for i in 0..<table.sets.length() {
    if parse_token_set_same(table.sets[i], set) {
      return i
    }
  }
  let id = table.sets.length()
  table.sets.push(parse_token_set_clone(set))
  id
}

///|
fn parse_token_set_symbol_count(set : ParseTokenSet) -> Int {
  let mut count = set.terminals.length() + set.externals.length()
  if set.eof {
    count += 1
  }
  if set.end_of_nonterminal_extra {
    count += 1
  }
  count
}

///|
fn parse_table_primary_state_ids(states : Array[ParseStateDraft]) -> Array[Int] {
  let primary_ids : Array[Int] = []
  for i in 0..<states.length() {
    primary_ids.push(parse_table_primary_state_id(states, i))
  }
  primary_ids
}

///|
fn parse_table_primary_state_id(
  states : Array[ParseStateDraft],
  state_index : Int,
) -> Int {
  for i in 0..<=state_index {
    if states[i].core_id == states[state_index].core_id {
      return states[i].id
    }
  }
  states[state_index].id
}

///|
fn validate_parse_table_draft_width(
  table : ParseTableDraft,
) -> Unit raise GenerateError {
  parse_table_validate_range(
    "state_count",
    table.states.length(),
    0,
    parse_table_u16_id_count_max(),
  )
  parse_table_validate_range(
    "parse_symbol_count",
    table.symbols.length(),
    0,
    parse_table_u16_count_max(),
  )
  parse_table_validate_range(
    "parse_action_list_count",
    table.parse_action_lists.length(),
    0,
    parse_table_u16_id_count_max(),
  )
  parse_table_validate_range(
    "primary_state_id_count",
    table.primary_state_ids.length(),
    table.states.length(),
    table.states.length(),
  )
  parse_table_validate_range(
    "reserved_word_set_count",
    table.reserved_word_sets.sets.length(),
    1,
    parse_table_u16_id_count_max(),
  )
  parse_table_validate_range(
    "reserved_word_set_id_count",
    table.reserved_word_sets.state_ids.length(),
    table.states.length(),
    table.states.length(),
  )
  parse_table_validate_range(
    "external_lex_state_count",
    table.external_lex_states.sets.length(),
    1,
    parse_table_u16_id_count_max(),
  )
  parse_table_validate_range(
    "external_lex_state_id_count",
    table.external_lex_states.state_ids.length(),
    table.states.length(),
    table.states.length(),
  )
  parse_table_validate_range(
    "max_reserved_word_set_size",
    table.reserved_word_sets.max_size,
    0,
    parse_table_u16_max(),
  )
  for i in 0..<table.states.length() {
    validate_parse_state_draft_width(table, table.states[i])
  }
  for primary_state_id in table.primary_state_ids {
    parse_table_validate_range(
      "primary_state_id",
      primary_state_id,
      0,
      parse_table_u16_reserved_max(),
    )
  }
  for reserved_word_set_id in table.reserved_word_sets.state_ids {
    parse_table_validate_range(
      "reserved_word_set_id",
      reserved_word_set_id,
      0,
      parse_reserved_word_set_id_max(table.reserved_word_sets),
    )
  }
  for external_lex_state_id in table.external_lex_states.state_ids {
    parse_table_validate_range(
      "external_lex_state_id",
      external_lex_state_id,
      0,
      parse_external_lex_state_id_max(table.external_lex_states),
    )
  }
  for i in 0..<table.parse_action_lists.length() {
    parse_table_validate_range(
      "parse_action_list_id",
      i,
      0,
      parse_table_u16_reserved_max(),
    )
    validate_parse_action_list_draft_width(table, table.parse_action_lists[i])
  }
  validate_parse_table_layout_width(table)
}

///|
fn validate_no_unresolved_parse_conflicts(
  grammar : PreparedGrammar,
  table : ParseTableDraft,
) -> Unit raise GenerateError {
  for state in table.states {
    for entry in state.terminal_entries {
      if entry.actions.length() > 1 &&
        !parse_actions_are_auxiliary_repeat_continuation(grammar, entry.actions) {
        raise GenerateError::InvalidGrammar(
          "unresolved conflict in parse state \{state.id}: \{parse_action_summaries(entry.actions)}",
        )
      }
    }
  }
}

///|
fn parse_actions_are_auxiliary_repeat_continuation(
  grammar : PreparedGrammar,
  actions : Array[ParseActionDraft],
) -> Bool {
  if actions.length() != 2 {
    return false
  }
  let mut has_shift = false
  let mut has_auxiliary_reduce = false
  for action in actions {
    match action {
      DraftShift(_) => has_shift = true
      DraftReduce(symbol~, ..) =>
        if parse_symbol_is_auxiliary_nonterminal(grammar, symbol) {
          has_auxiliary_reduce = true
        }
      DraftAccept | DraftShiftExtra => ()
    }
  }
  has_shift && has_auxiliary_reduce
}

///|
fn parse_symbol_is_auxiliary_nonterminal(
  grammar : PreparedGrammar,
  symbol : InternalSymbol,
) -> Bool {
  match symbol {
    NonTerminal(index) =>
      index >= 0 &&
      index < grammar.syntax.variables.length() &&
      is_auxiliary_kind(grammar.syntax.variables[index].kind)
    Terminal(_) | External(_) => false
  }
}

///|
fn parse_action_summaries(actions : Array[ParseActionDraft]) -> String {
  let parts : Array[String] = []
  for action in actions {
    parts.push(parse_action_summary(action))
  }
  parts.join(", ")
}

///|
fn parse_action_summary(action : ParseActionDraft) -> String {
  match action {
    DraftAccept => "accept"
    DraftShift(state_id~, ..) => "shift(\{state_id})"
    DraftShiftExtra => "shift_extra"
    DraftReduce(symbol~, child_count~, dynamic_precedence~, production_id~, ..) =>
      "reduce(\{internal_symbol_summary(symbol)}, children=\{child_count}, dynamic=\{dynamic_precedence}, production=\{production_id})"
  }
}

///|
fn internal_symbol_summary(symbol : InternalSymbol) -> String {
  match symbol {
    Terminal(index) => "terminal:\{index}"
    External(index) => "external:\{index}"
    NonTerminal(index) => "nonterminal:\{index}"
  }
}

///|
fn parse_reserved_word_set_id_max(table : ParseReservedWordSetsDraft) -> Int {
  min_int(table.sets.length() - 1, parse_table_u16_reserved_max())
}

///|
fn parse_external_lex_state_id_max(table : ParseExternalLexStatesDraft) -> Int {
  min_int(table.sets.length() - 1, parse_table_u16_reserved_max())
}

///|
fn validate_parse_state_draft_width(
  table : ParseTableDraft,
  state : ParseStateDraft,
) -> Unit raise GenerateError {
  parse_table_validate_range(
    "state_id",
    state.id,
    0,
    parse_table_u16_reserved_max(),
  )
  for entry in state.terminal_entries {
    parse_table_validate_range(
      "parse_action_list_id",
      entry.action_list_id,
      0,
      parse_table_u16_reserved_max(),
    )
    for action in entry.actions {
      validate_parse_action_draft_width(table, action)
    }
  }
  for entry in state.nonterminal_entries {
    validate_parse_goto_draft_width(entry.action)
  }
}

///|
fn validate_parse_action_list_draft_width(
  table : ParseTableDraft,
  action_list : ParseActionListDraft,
) -> Unit raise GenerateError {
  parse_table_validate_range(
    "parse_action_count",
    action_list.actions.length(),
    0,
    parse_table_u8_max(),
  )
  for action in action_list.actions {
    validate_parse_action_draft_width(table, action)
  }
}

///|
fn validate_parse_action_draft_width(
  table : ParseTableDraft,
  action : ParseActionDraft,
) -> Unit raise GenerateError {
  match action {
    DraftAccept | DraftShiftExtra => ()
    DraftShift(state_id~, ..) =>
      parse_table_validate_range(
        "shift_state_id",
        state_id,
        0,
        parse_table_u16_reserved_max(),
      )
    DraftReduce(symbol~, child_count~, dynamic_precedence~, production_id~, ..) => {
      parse_table_validate_range(
        "reduce_symbol_id",
        parse_table_symbol_id_for_internal(table, symbol),
        0,
        parse_table_u16_max(),
      )
      parse_table_validate_range(
        "reduce_child_count",
        child_count,
        0,
        parse_table_u8_max(),
      )
      parse_table_validate_range(
        "reduce_dynamic_precedence",
        dynamic_precedence,
        parse_table_i16_min(),
        parse_table_i16_max(),
      )
      parse_table_validate_range(
        "reduce_production_id",
        production_id,
        0,
        parse_table_u16_max(),
      )
    }
  }
}

///|
fn validate_parse_goto_draft_width(
  action : ParseGotoDraft,
) -> Unit raise GenerateError {
  match action {
    DraftGoto(state_id) =>
      parse_table_validate_range(
        "goto_state_id",
        state_id,
        0,
        parse_table_u16_reserved_max(),
      )
    DraftGotoShiftExtra => ()
  }
}

///|
fn validate_parse_table_layout_width(
  table : ParseTableDraft,
) -> Unit raise GenerateError {
  parse_table_validate_range(
    "large_state_count",
    table.layout.large_state_count,
    0,
    table.states.length(),
  )
  for row in table.layout.large_rows {
    for cell in row {
      validate_parse_table_cell_width(cell)
    }
  }
  for offset in table.layout.small_state_offsets {
    parse_table_validate_range(
      "small_table_offset",
      offset,
      0,
      parse_table_int_index_max(),
    )
  }
  for row in table.layout.small_rows {
    parse_table_validate_range(
      "small_table_offset",
      row.offset,
      0,
      parse_table_int_index_max(),
    )
    parse_table_validate_range(
      "small_section_count",
      row.sections.length(),
      0,
      parse_table_u16_max(),
    )
    for section in row.sections {
      validate_parse_small_section_width(table, section)
    }
  }
}

///|
fn validate_parse_table_cell_width(
  cell : ParseTableCellDraft,
) -> Unit raise GenerateError {
  match cell {
    ParseCellEmpty => ()
    ParseCellAction(action_id) =>
      parse_table_validate_range(
        "large_cell_action_id",
        action_id,
        1,
        parse_table_u16_reserved_max(),
      )
    ParseCellState(state_id) =>
      parse_table_validate_range(
        "large_cell_state_id",
        state_id,
        0,
        parse_table_u16_reserved_max(),
      )
  }
}

///|
fn validate_parse_small_section_width(
  table : ParseTableDraft,
  section : ParseSmallParseTableSectionDraft,
) -> Unit raise GenerateError {
  let minimum_value = match section.kind {
    ParseSmallAction => 1
    ParseSmallState => 0
  }
  parse_table_validate_range(
    "small_section_value",
    section.value,
    minimum_value,
    parse_table_u16_reserved_max(),
  )
  parse_table_validate_range(
    "small_section_symbol_count",
    section.symbols.length(),
    0,
    parse_table_u16_max(),
  )
  for symbol in section.symbols {
    parse_table_validate_range(
      "small_section_symbol_id",
      parse_table_find_symbol_id(table.symbols, symbol),
      0,
      parse_table_u16_max(),
    )
  }
}

///|
fn parse_table_validate_range(
  kind : String,
  value : Int,
  min : Int,
  max : Int,
) -> Unit raise GenerateError {
  if value < min || value > max {
    raise GenerateError::ParseTableValueOutOfRange(kind~, value~, min~, max~)
  }
}

///|
fn parse_table_u8_max() -> Int {
  255
}

///|
fn parse_table_i16_min() -> Int {
  -32768
}

///|
fn parse_table_i16_max() -> Int {
  32767
}

///|
fn parse_table_u16_max() -> Int {
  65535
}

///|
fn parse_table_u16_reserved_max() -> Int {
  65534
}

///|
fn parse_table_u16_count_max() -> Int {
  65536
}

///|
fn parse_table_u16_id_count_max() -> Int {
  65535
}

///|
fn parse_table_int_index_max() -> Int {
  2147483647
}

///|
fn parse_table_symbol_id_for_internal(
  table : ParseTableDraft,
  symbol : InternalSymbol,
) -> Int {
  parse_table_find_symbol_id(
    table.symbols,
    parse_table_symbol_from_internal(symbol),
  )
}

///|
fn parse_table_draft_assign_action_lists(
  table : ParseTableDraft,
  grammar : PreparedGrammar,
) -> Unit {
  table.parse_action_lists.push(parse_action_list_empty())
  for state in table.states {
    for entry in state.terminal_entries {
      entry.action_list_id = parse_table_draft_action_list_id(table, {
        actions: entry.actions.copy(),
        reusable: parse_action_list_is_reusable(grammar, entry.actions),
      })
    }
  }
}

///|
fn parse_action_list_is_reusable(
  grammar : PreparedGrammar,
  actions : Array[ParseActionDraft],
) -> Bool {
  actions.length() <= 1 ||
  parse_actions_are_auxiliary_repeat_continuation(grammar, actions) ||
  !parse_actions_match_declared_conflict(grammar, actions)
}

///|
fn parse_actions_match_declared_conflict(
  grammar : PreparedGrammar,
  actions : Array[ParseActionDraft],
) -> Bool {
  for i in 0..<actions.length() {
    for j in (i + 1)..<actions.length() {
      if parse_action_pair_matches_declared_conflict(
          grammar,
          actions[i],
          actions[j],
        ) {
        return true
      }
    }
  }
  false
}

///|
fn parse_action_pair_matches_declared_conflict(
  grammar : PreparedGrammar,
  left : ParseActionDraft,
  right : ParseActionDraft,
) -> Bool {
  match (left, right) {
    (DraftShift(_), DraftReduce(_)) =>
      parse_shift_reduce_conflict_is_declared(grammar, left, right)
    (DraftReduce(_), DraftShift(_)) =>
      parse_shift_reduce_conflict_is_declared(grammar, right, left)
    (DraftReduce(symbol=left_symbol, ..), DraftReduce(symbol=right_symbol, ..)) =>
      parse_symbols_have_declared_conflict(grammar, left_symbol, right_symbol)
    _ => false
  }
}

///|
fn parse_symbols_have_declared_conflict(
  grammar : PreparedGrammar,
  left : InternalSymbol,
  right : InternalSymbol,
) -> Bool {
  for row in grammar.syntax.conflict_symbols {
    if contains_internal_symbol(row, left) &&
      contains_internal_symbol(row, right) {
      return true
    }
  }
  false
}

///|
fn parse_table_draft_action_list_id(
  table : ParseTableDraft,
  action_list : ParseActionListDraft,
) -> Int {
  for i in 0..<table.parse_action_lists.length() {
    if parse_action_list_same(table.parse_action_lists[i], action_list) {
      return i
    }
  }
  let index = table.parse_action_lists.length()
  table.parse_action_lists.push(action_list)
  index
}

///|
fn parse_action_list_same(
  left : ParseActionListDraft,
  right : ParseActionListDraft,
) -> Bool {
  left.reusable == right.reusable &&
  parse_action_draft_array_same(left.actions, right.actions)
}

///|
fn parse_action_draft_array_same(
  left : Array[ParseActionDraft],
  right : Array[ParseActionDraft],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if !parse_action_draft_same(left[i], right[i]) {
      return false
    }
  }
  true
}

///|
fn parse_action_draft_same(
  left : ParseActionDraft,
  right : ParseActionDraft,
) -> Bool {
  parse_action_draft_rank(left) == parse_action_draft_rank(right) &&
  parse_action_draft_state_id(left) == parse_action_draft_state_id(right) &&
  parse_action_draft_is_repetition(left) ==
  parse_action_draft_is_repetition(right) &&
  parse_action_draft_reduce_symbol(left) ==
  parse_action_draft_reduce_symbol(right) &&
  parse_action_draft_child_count(left) == parse_action_draft_child_count(right) &&
  parse_action_draft_dynamic_precedence(left) ==
  parse_action_draft_dynamic_precedence(right) &&
  parse_action_draft_production_id(left) ==
  parse_action_draft_production_id(right)
}

///|
fn parse_action_draft_rank(action : ParseActionDraft) -> Int {
  match action {
    DraftAccept => 0
    DraftShift(_) => 1
    DraftShiftExtra => 2
    DraftReduce(_) => 3
  }
}

///|
fn parse_action_draft_state_id(action : ParseActionDraft) -> Int {
  match action {
    DraftShift(state_id~, ..) => state_id
    DraftAccept | DraftShiftExtra | DraftReduce(_) => 0
  }
}

///|
fn parse_action_draft_is_repetition(action : ParseActionDraft) -> Bool {
  match action {
    DraftShift(is_repetition~, ..) => is_repetition
    DraftAccept | DraftShiftExtra | DraftReduce(_) => false
  }
}

///|
fn parse_action_draft_reduce_symbol(
  action : ParseActionDraft,
) -> InternalSymbol {
  match action {
    DraftReduce(symbol~, ..) => symbol
    DraftAccept | DraftShift(_) | DraftShiftExtra =>
      InternalSymbol::Terminal(-1)
  }
}

///|
fn parse_action_draft_child_count(action : ParseActionDraft) -> Int {
  match action {
    DraftReduce(child_count~, ..) => child_count
    DraftAccept | DraftShift(_) | DraftShiftExtra => 0
  }
}

///|
fn parse_action_draft_dynamic_precedence(action : ParseActionDraft) -> Int {
  match action {
    DraftReduce(dynamic_precedence~, ..) => dynamic_precedence
    DraftAccept | DraftShift(_) | DraftShiftExtra => 0
  }
}

///|
fn parse_action_draft_production_id(action : ParseActionDraft) -> Int {
  match action {
    DraftReduce(production_id~, ..) => production_id
    DraftAccept | DraftShift(_) | DraftShiftExtra => 0
  }
}

///|
fn parse_table_symbols_from_used(
  grammar : PreparedGrammar,
  used : ParseUsedSymbolsDraft,
) -> Array[ParseTableSymbolDraft] {
  let symbols = [ParseTableSymbolDraft::ParseSymbolEnd]
  let mut word_terminal = -1
  match grammar.syntax.word_symbol {
    Some(InternalSymbol::Terminal(index)) => word_terminal = index
    Some(InternalSymbol::External(_))
    | Some(InternalSymbol::NonTerminal(_))
    | None => ()
  }
  if word_terminal >= 0 && contains_int(used.tokens.terminals, word_terminal) {
    symbols.push(ParseTableSymbolDraft::ParseSymbolTerminal(word_terminal))
  }
  for terminal in used.tokens.terminals {
    if terminal != word_terminal {
      symbols.push(ParseTableSymbolDraft::ParseSymbolTerminal(terminal))
    }
  }
  for external_token in used.tokens.externals {
    symbols.push(ParseTableSymbolDraft::ParseSymbolExternal(external_token))
  }
  for nonterminal in used.nonterminals {
    symbols.push(ParseTableSymbolDraft::ParseSymbolNonTerminal(nonterminal))
  }
  symbols
}

///|
fn parse_table_layout_from_draft(
  table : ParseTableDraft,
) -> ParseTableLayoutDraft {
  let large_state_count = parse_table_large_state_count(table)
  let large_rows : Array[Array[ParseTableCellDraft]] = []
  for i in 0..<large_state_count {
    large_rows.push(parse_table_large_row(table, table.states[i], i))
  }
  let small_rows : Array[ParseSmallParseTableRowDraft] = []
  let small_state_offsets : Array[Int] = []
  let mut offset = 0
  for i in large_state_count..<table.states.length() {
    small_state_offsets.push(offset)
    let row = parse_table_small_row(table, table.states[i], i, offset)
    offset += parse_table_small_row_encoded_length(row)
    small_rows.push(row)
  }
  { large_state_count, large_rows, small_rows, small_state_offsets }
}

///|
fn parse_table_large_state_count(table : ParseTableDraft) -> Int {
  let threshold = min_int(64, parse_table_half_int(table.symbols.length()))
  let mut count = 0
  for i in 0..<table.states.length() {
    let entry_count = parse_state_draft_entry_count(table.states[i])
    if i <= 1 || entry_count > threshold {
      count += 1
    } else {
      break
    }
  }
  count
}

///|
fn parse_table_half_int(value : Int) -> Int {
  let mut remaining = value
  let mut result = 0
  while remaining >= 2 {
    result += 1
    remaining -= 2
  }
  result
}

///|
fn parse_state_draft_entry_count(state : ParseStateDraft) -> Int {
  state.terminal_entries.length() + state.nonterminal_entries.length()
}

///|
fn parse_table_large_row(
  table : ParseTableDraft,
  state : ParseStateDraft,
  state_index : Int,
) -> Array[ParseTableCellDraft] {
  let row : Array[ParseTableCellDraft] = []
  for symbol in table.symbols {
    row.push(parse_table_cell_for_state_symbol(state, state_index, symbol))
  }
  row
}

///|
fn parse_table_cell_for_state_symbol(
  state : ParseStateDraft,
  state_index : Int,
  symbol : ParseTableSymbolDraft,
) -> ParseTableCellDraft {
  match parse_state_draft_terminal_entry_for_symbol(state, symbol) {
    Some(entry) => ParseTableCellDraft::ParseCellAction(entry.action_list_id)
    None =>
      match parse_state_draft_goto_entry_for_symbol(state, symbol) {
        Some(entry) =>
          ParseTableCellDraft::ParseCellState(
            parse_goto_draft_state_id(entry.action, state_index),
          )
        None => ParseTableCellDraft::ParseCellEmpty
      }
  }
}

///|
fn parse_table_small_row(
  table : ParseTableDraft,
  state : ParseStateDraft,
  state_index : Int,
  offset : Int,
) -> ParseSmallParseTableRowDraft {
  let sections : Array[ParseSmallParseTableSectionDraft] = []
  for symbol in table.symbols {
    match parse_state_draft_terminal_entry_for_symbol(state, symbol) {
      Some(entry) =>
        parse_small_sections_add_symbol(
          table.symbols,
          sections,
          ParseSmallParseTableSectionKindDraft::ParseSmallAction,
          entry.action_list_id,
          symbol,
        )
      None => ()
    }
  }
  for entry in state.nonterminal_entries {
    parse_small_sections_add_symbol(
      table.symbols,
      sections,
      ParseSmallParseTableSectionKindDraft::ParseSmallState,
      parse_goto_draft_state_id(entry.action, state_index),
      parse_table_symbol_from_internal(entry.symbol),
    )
  }
  {
    state_id: state.id,
    offset,
    sections: parse_small_sections_sorted(table.symbols, sections),
  }
}

///|
fn parse_table_small_row_encoded_length(
  row : ParseSmallParseTableRowDraft,
) -> Int {
  let mut length = 1
  for section in row.sections {
    length += 2 + section.symbols.length()
  }
  length
}

///|
fn parse_small_sections_add_symbol(
  table_symbols : Array[ParseTableSymbolDraft],
  sections : Array[ParseSmallParseTableSectionDraft],
  kind : ParseSmallParseTableSectionKindDraft,
  value : Int,
  symbol : ParseTableSymbolDraft,
) -> Unit {
  for i in 0..<sections.length() {
    if parse_small_section_kind_rank(sections[i].kind) ==
      parse_small_section_kind_rank(kind) &&
      sections[i].value == value {
      parse_small_section_insert_symbol(table_symbols, sections[i], symbol)
      return
    }
  }
  sections.push({ kind, value, first_symbol: symbol, symbols: [symbol] })
}

///|
fn parse_small_sections_sorted(
  table_symbols : Array[ParseTableSymbolDraft],
  sections : Array[ParseSmallParseTableSectionDraft],
) -> Array[ParseSmallParseTableSectionDraft] {
  let sorted : Array[ParseSmallParseTableSectionDraft] = []
  for section in sections {
    parse_small_sections_insert_sorted(table_symbols, sorted, section)
  }
  sorted
}

///|
fn parse_small_sections_insert_sorted(
  table_symbols : Array[ParseTableSymbolDraft],
  sections : Array[ParseSmallParseTableSectionDraft],
  section : ParseSmallParseTableSectionDraft,
) -> Unit {
  for i in 0..<sections.length() {
    if compare_parse_small_section(table_symbols, section, sections[i]) < 0 {
      sections.insert(i, section)
      return
    }
  }
  sections.push(section)
}

///|
fn parse_small_section_insert_symbol(
  table_symbols : Array[ParseTableSymbolDraft],
  section : ParseSmallParseTableSectionDraft,
  symbol : ParseTableSymbolDraft,
) -> Unit {
  for i in 0..<section.symbols.length() {
    if compare_parse_table_symbol_by_order(
        table_symbols,
        symbol,
        section.symbols[i],
      ) <
      0 {
      section.symbols.insert(i, symbol)
      return
    }
  }
  section.symbols.push(symbol)
}

///|
fn compare_parse_small_section(
  table_symbols : Array[ParseTableSymbolDraft],
  left : ParseSmallParseTableSectionDraft,
  right : ParseSmallParseTableSectionDraft,
) -> Int {
  let mut comparison = compare_int(
    left.symbols.length(),
    right.symbols.length(),
  )
  if comparison != 0 {
    return comparison
  }
  comparison = compare_int(
    parse_small_section_kind_rank(left.kind),
    parse_small_section_kind_rank(right.kind),
  )
  if comparison != 0 {
    return comparison
  }
  comparison = compare_int(left.value, right.value)
  if comparison != 0 {
    return comparison
  }
  compare_parse_table_symbol_by_order(
    table_symbols,
    left.first_symbol,
    right.first_symbol,
  )
}

///|
fn parse_small_section_kind_rank(
  kind : ParseSmallParseTableSectionKindDraft,
) -> Int {
  match kind {
    ParseSmallAction => 0
    ParseSmallState => 1
  }
}

///|
fn compare_parse_table_symbol_by_order(
  table_symbols : Array[ParseTableSymbolDraft],
  left : ParseTableSymbolDraft,
  right : ParseTableSymbolDraft,
) -> Int {
  compare_int(
    parse_table_symbol_index(table_symbols, left),
    parse_table_symbol_index(table_symbols, right),
  )
}

///|
fn parse_table_symbol_index(
  table_symbols : Array[ParseTableSymbolDraft],
  symbol : ParseTableSymbolDraft,
) -> Int {
  let index = parse_table_find_symbol_id(table_symbols, symbol)
  if index >= 0 {
    return index
  }
  0
}

///|
fn parse_table_find_symbol_id(
  table_symbols : Array[ParseTableSymbolDraft],
  symbol : ParseTableSymbolDraft,
) -> Int {
  for i in 0..<table_symbols.length() {
    if parse_table_symbol_same(table_symbols[i], symbol) {
      return i
    }
  }
  -1
}

///|
fn parse_table_symbol_same(
  left : ParseTableSymbolDraft,
  right : ParseTableSymbolDraft,
) -> Bool {
  parse_table_symbol_kind_rank(left) == parse_table_symbol_kind_rank(right) &&
  parse_table_symbol_value(left) == parse_table_symbol_value(right)
}

///|
fn parse_table_symbol_kind_rank(symbol : ParseTableSymbolDraft) -> Int {
  match symbol {
    ParseSymbolEnd => 0
    ParseSymbolTerminal(_) => 1
    ParseSymbolExternal(_) => 2
    ParseSymbolNonTerminal(_) => 3
  }
}

///|
fn parse_table_symbol_value(symbol : ParseTableSymbolDraft) -> Int {
  match symbol {
    ParseSymbolEnd => 0
    ParseSymbolTerminal(index)
    | ParseSymbolExternal(index)
    | ParseSymbolNonTerminal(index) => index
  }
}

///|
fn parse_used_symbols_collect_table(
  table : ParseTableDraft,
) -> ParseUsedSymbolsDraft {
  let used = parse_used_symbols_empty()
  for state in table.states {
    for entry in state.terminal_entries {
      parse_used_symbols_insert_terminal(used, entry.symbol)
      for action in entry.actions {
        parse_used_symbols_insert_action(used, action)
      }
    }
    parse_token_set_insert_all(used.tokens, state.reserved_words)
    for entry in state.nonterminal_entries {
      parse_used_symbols_insert_internal(used, entry.symbol)
    }
  }
  used
}

///|
fn parse_used_symbols_insert_terminal(
  used : ParseUsedSymbolsDraft,
  symbol : ParseTerminalSymbol,
) -> Unit {
  match symbol {
    ParseTerminal(index) =>
      parse_token_set_insert_symbol(
        used.tokens,
        InternalSymbol::Terminal(index),
      )
    ParseExternal(index) =>
      parse_token_set_insert_symbol(
        used.tokens,
        InternalSymbol::External(index),
      )
    ParseEnd => used.tokens.eof = true
    ParseEndOfNonTerminalExtra => used.tokens.end_of_nonterminal_extra = true
  }
}

///|
fn parse_used_symbols_insert_action(
  used : ParseUsedSymbolsDraft,
  action : ParseActionDraft,
) -> Unit {
  match action {
    DraftReduce(symbol~, ..) => parse_used_symbols_insert_internal(used, symbol)
    DraftAccept | DraftShift(_) | DraftShiftExtra => ()
  }
}

///|
fn parse_used_symbols_insert_internal(
  used : ParseUsedSymbolsDraft,
  symbol : InternalSymbol,
) -> Unit {
  match symbol {
    NonTerminal(index) => parse_token_set_insert_index(used.nonterminals, index)
    Terminal(_) | External(_) =>
      parse_token_set_insert_symbol(used.tokens, symbol)
  }
}

///|
fn parse_state_reserved_words(
  builder : ParseItemSetBuilder,
  item_set : ParseItemSet,
) -> ParseTokenSet {
  match builder.grammar.syntax.word_symbol {
    Some(word_symbol) => {
      let mut reserved_word_set_id = -1
      for entry in item_set.entries {
        match entry.item.step() {
          Some(step) => {
            let step_reserved_word_set_id = if step.symbol == word_symbol {
              step.reserved_word_set_id
            } else if parse_token_set_contains_symbol(
                parse_symbol_first_set(builder.symbol_sets, step.symbol),
                word_symbol,
              ) {
              parse_symbol_reserved_first_set(builder.symbol_sets, step.symbol)
            } else {
              -1
            }
            if step_reserved_word_set_id > reserved_word_set_id {
              reserved_word_set_id = step_reserved_word_set_id
            }
          }
          None =>
            if parse_token_set_contains_symbol(entry.lookaheads, word_symbol) &&
              entry.following_reserved_word_set > reserved_word_set_id {
              reserved_word_set_id = entry.following_reserved_word_set
            }
        }
      }
      parse_reserved_token_set(builder.grammar, reserved_word_set_id)
    }
    None => parse_token_set_empty()
  }
}

///|
fn add_extra_actions(
  state : ParseStateDraft,
  builder : ParseItemSetBuilder,
  graph : ParseStateGraph,
  item_set : ParseItemSet,
) -> Unit raise GenerateError {
  if parse_state_draft_has_terminal(
      state,
      ParseTerminalSymbol::ParseEndOfNonTerminalExtra,
    ) {
    if state.terminal_entries.length() > 1 {
      raise GenerateError::AmbiguousExtra(
        parse_extra_parent_symbols(builder.grammar, item_set),
      )
    }
    return
  }
  for transition in graph.nonterminal_extra_transitions {
    parse_state_draft_ensure_action(
      state,
      parse_terminal_symbol_from_internal(transition.symbol),
      ParseActionDraft::DraftShift(
        state_id=transition.state_id,
        is_repetition=false,
        contributors=[],
      ),
    )
  }
  for extra in builder.grammar.syntax.extra_symbols {
    match extra {
      NonTerminal(_) =>
        parse_state_draft_add_goto(
          state,
          extra,
          ParseGotoDraft::DraftGotoShiftExtra,
        )
      Terminal(_) | External(_) =>
        parse_state_draft_ensure_action(
          state,
          parse_terminal_symbol_from_internal(extra),
          ParseActionDraft::DraftShiftExtra,
        )
    }
  }
}

///|
fn parse_extra_parent_symbols(
  grammar : PreparedGrammar,
  item_set : ParseItemSet,
) -> Array[String] {
  let result : Array[String] = []
  for entry in item_set.entries {
    if !entry.item.is_augmented() && entry.item.step_index > 0 {
      push_unique_string(
        result,
        parse_state_graph_symbol_name(
          grammar,
          InternalSymbol::NonTerminal(entry.item.variable_index),
        ),
      )
    }
  }
  result
}

///|
fn parse_shift_action_for_transition(
  item_set : ParseItemSet,
  transition : ParseTransition,
) -> ParseActionDraft {
  ParseActionDraft::DraftShift(
    state_id=transition.state_id,
    is_repetition=false,
    contributors=parse_shift_contributors_for_symbol(
      item_set,
      transition.symbol,
    ),
  )
}

///|
fn parse_shift_contributors_for_symbol(
  item_set : ParseItemSet,
  symbol : InternalSymbol,
) -> Array[ParseShiftContributor] {
  let contributors : Array[ParseShiftContributor] = []
  for entry in item_set.entries {
    if entry.item.symbol() == Some(symbol) {
      match entry.item.step() {
        Some(step) =>
          push_shift_contributor_unique(contributors, {
            symbol: InternalSymbol::NonTerminal(entry.item.variable_index),
            precedence: parse_shift_contributor_precedence(entry.item, step),
            associativity: parse_shift_contributor_associativity(
              entry.item,
              step,
            ),
          })
        None => ()
      }
    }
  }
  contributors
}

///|
fn parse_shift_contributor_precedence(
  item : ParseItem,
  step : ProductionStep,
) -> @grammar.PrecedenceValue? {
  match step.precedence {
    Some(_) => step.precedence
    None => item.inherited_precedence
  }
}

///|
fn parse_shift_contributor_associativity(
  item : ParseItem,
  step : ProductionStep,
) -> Associativity {
  match step.associativity {
    NoAssociativity => item.inherited_associativity
    Left | Right => step.associativity
  }
}

///|
fn push_shift_contributor_unique(
  contributors : Array[ParseShiftContributor],
  contributor : ParseShiftContributor,
) -> Unit {
  for existing in contributors {
    if parse_shift_contributor_same(existing, contributor) {
      return
    }
  }
  contributors.push(contributor)
}

///|
fn parse_shift_contributor_same(
  left : ParseShiftContributor,
  right : ParseShiftContributor,
) -> Bool {
  left.symbol == right.symbol &&
  left.precedence == right.precedence &&
  same_associativity(left.associativity, right.associativity)
}

///|
fn add_reduce_actions(
  table : ParseTableDraft,
  state : ParseStateDraft,
  builder : ParseItemSetBuilder,
  item_set : ParseItemSet,
) -> Unit {
  for entry in item_set.entries {
    if entry.item.symbol() is None {
      let action = if entry.item.is_augmented() {
        ParseActionDraft::DraftAccept
      } else {
        let production_id = parse_table_draft_production_id(
          table,
          builder.grammar,
          entry.item,
        )
        ParseActionDraft::DraftReduce(
          symbol=InternalSymbol::NonTerminal(entry.item.variable_index),
          child_count=entry.item.step_index,
          dynamic_precedence=entry.item.production.dynamic_precedence,
          production_id~,
          precedence=parse_item_static_precedence(entry.item),
          associativity=parse_item_associativity(entry.item),
        )
      }
      for symbol in parse_terminal_symbols_from_set(entry.lookaheads) {
        parse_state_draft_add_action(
          state,
          symbol,
          action,
          grammar=builder.grammar,
        )
      }
    }
  }
}

///|
fn parse_item_static_precedence(item : ParseItem) -> @grammar.PrecedenceValue? {
  match item.previous_step() {
    Some(step) => step.precedence
    None => None
  }
}

///|
fn parse_table_draft_production_id(
  table : ParseTableDraft,
  grammar : PreparedGrammar,
  item : ParseItem,
) -> Int {
  let info = parse_production_info_for_item(grammar, item)
  if item.production.steps.length() > table.max_aliased_production_length {
    table.max_aliased_production_length = item.production.steps.length()
  }
  for i in 0..<table.production_infos.length() {
    if parse_production_info_same(table.production_infos[i], info) {
      return i
    }
  }
  let index = table.production_infos.length()
  table.production_infos.push(info)
  index
}

///|
fn parse_production_info_for_item(
  grammar : PreparedGrammar,
  item : ParseItem,
) -> ParseProductionInfoDraft {
  let alias_sequence : Array[ParseAliasDraft?] = []
  let field_map : Array[ParseFieldMapEntryDraft] = []
  for i in 0..<item.production.steps.length() {
    let step = item.production.steps[i]
    match step.alias_name {
      Some(value) =>
        alias_sequence.push(Some({ value, named: step.alias_named }))
      None => alias_sequence.push(None)
    }
    match step.field_name {
      Some(name) => parse_field_map_insert(field_map, name, i, false)
      None => ()
    }
    match step.symbol {
      NonTerminal(index) =>
        if parse_nonterminal_fields_are_inherited(grammar, index) {
          for field_name in parse_variable_field_names(grammar, index) {
            parse_field_map_insert(field_map, field_name, i, true)
          }
        }
      Terminal(_) | External(_) => ()
    }
  }
  while alias_sequence.length() > 0 &&
        alias_sequence[alias_sequence.length() - 1] is None {
    ignore(alias_sequence.pop())
  }
  { alias_sequence, field_map }
}

///|
fn parse_production_info_empty() -> ParseProductionInfoDraft {
  { alias_sequence: [], field_map: [] }
}

///|
fn parse_nonterminal_fields_are_inherited(
  grammar : PreparedGrammar,
  variable_index : Int,
) -> Bool {
  variable_index >= 0 &&
  variable_index < grammar.syntax.variables.length() &&
  (
    is_hidden_kind(grammar.syntax.variables[variable_index].kind) ||
    is_auxiliary_kind(grammar.syntax.variables[variable_index].kind)
  )
}

///|
fn parse_variable_field_names(
  grammar : PreparedGrammar,
  variable_index : Int,
) -> Array[String] {
  let names : Array[String] = []
  if variable_index >= 0 && variable_index < grammar.syntax.variables.length() {
    for production in grammar.syntax.variables[variable_index].productions {
      for step in production.steps {
        match step.field_name {
          Some(name) => push_unique_string(names, name)
          None => ()
        }
      }
    }
  }
  names
}

///|
fn parse_field_map_insert(
  field_map : Array[ParseFieldMapEntryDraft],
  name : String,
  index : Int,
  inherited : Bool,
) -> Unit {
  for i in 0..<field_map.length() {
    let comparison = field_map[i].name.compare(name)
    if comparison == 0 {
      field_map[i].locations.push({ index, inherited })
      return
    }
    if comparison > 0 {
      field_map.insert(i, { name, locations: [{ index, inherited }] })
      return
    }
  }
  field_map.push({ name, locations: [{ index, inherited }] })
}

///|
fn parse_production_info_same(
  left : ParseProductionInfoDraft,
  right : ParseProductionInfoDraft,
) -> Bool {
  parse_alias_sequence_same(left.alias_sequence, right.alias_sequence) &&
  parse_field_map_same(left.field_map, right.field_map)
}

///|
fn parse_alias_sequence_same(
  left : Array[ParseAliasDraft?],
  right : Array[ParseAliasDraft?],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    match (left[i], right[i]) {
      (None, None) => ()
      (Some(left_alias), Some(right_alias)) =>
        if left_alias.value != right_alias.value ||
          left_alias.named != right_alias.named {
          return false
        }
      _ => return false
    }
  }
  true
}

///|
fn parse_field_map_same(
  left : Array[ParseFieldMapEntryDraft],
  right : Array[ParseFieldMapEntryDraft],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if left[i].name != right[i].name ||
      !parse_field_locations_same(left[i].locations, right[i].locations) {
      return false
    }
  }
  true
}

///|
fn parse_field_locations_same(
  left : Array[ParseFieldLocationDraft],
  right : Array[ParseFieldLocationDraft],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if left[i].index != right[i].index ||
      left[i].inherited != right[i].inherited {
      return false
    }
  }
  true
}

///|
fn parse_terminal_symbols_from_set(
  set : ParseTokenSet,
) -> Array[ParseTerminalSymbol] {
  let symbols : Array[ParseTerminalSymbol] = []
  for terminal in set.terminals {
    symbols.push(ParseTerminalSymbol::ParseTerminal(terminal))
  }
  for external_token in set.externals {
    symbols.push(ParseTerminalSymbol::ParseExternal(external_token))
  }
  if set.eof {
    symbols.push(ParseTerminalSymbol::ParseEnd)
  }
  if set.end_of_nonterminal_extra {
    symbols.push(ParseTerminalSymbol::ParseEndOfNonTerminalExtra)
  }
  symbols
}

///|
fn parse_terminal_symbol_from_internal(
  symbol : InternalSymbol,
) -> ParseTerminalSymbol {
  match symbol {
    Terminal(index) => ParseTerminalSymbol::ParseTerminal(index)
    External(index) => ParseTerminalSymbol::ParseExternal(index)
    NonTerminal(index) => ParseTerminalSymbol::ParseTerminal(index)
  }
}

///|
fn parse_table_symbol_from_internal(
  symbol : InternalSymbol,
) -> ParseTableSymbolDraft {
  match symbol {
    Terminal(index) => ParseTableSymbolDraft::ParseSymbolTerminal(index)
    External(index) => ParseTableSymbolDraft::ParseSymbolExternal(index)
    NonTerminal(index) => ParseTableSymbolDraft::ParseSymbolNonTerminal(index)
  }
}

///|
fn parse_goto_draft_state_id(
  action : ParseGotoDraft,
  current_state : Int,
) -> Int {
  match action {
    DraftGoto(state_id) => state_id
    DraftGotoShiftExtra => current_state
  }
}

///|
fn parse_state_draft_add_action(
  state : ParseStateDraft,
  symbol : ParseTerminalSymbol,
  action : ParseActionDraft,
  grammar? : PreparedGrammar,
) -> Unit {
  let entry = parse_state_draft_terminal_entry(state, symbol)
  let kept : Array[ParseActionDraft] = []
  let mut should_add = true
  for existing in entry.actions {
    let resolution = match grammar {
      Some(grammar) =>
        parse_action_conflict_resolution(existing, action, grammar~)
      None => parse_action_conflict_resolution(existing, action)
    }
    match resolution {
      KeepBoth => kept.push(existing)
      KeepExisting => {
        kept.push(existing)
        should_add = false
      }
      ReplaceExisting => ()
      DropBoth => should_add = false
    }
  }
  while !entry.actions.is_empty() {
    ignore(entry.actions.pop())
  }
  for kept_action in kept {
    entry.actions.push(kept_action)
  }
  if should_add {
    entry.actions.push(action)
  }
}

///|
fn parse_action_conflict_resolution(
  existing : ParseActionDraft,
  incoming : ParseActionDraft,
  grammar? : PreparedGrammar,
) -> ParseActionConflictResolution {
  if parse_action_draft_equivalent(existing, incoming) {
    return KeepExisting
  }
  match (existing, incoming) {
    (DraftShift(_), DraftReduce(_)) =>
      match grammar {
        Some(grammar) =>
          parse_shift_reduce_conflict_resolution(
            existing,
            incoming,
            shift_is_existing=true,
            grammar~,
          )
        None =>
          parse_shift_reduce_conflict_resolution(
            existing,
            incoming,
            shift_is_existing=true,
          )
      }
    (DraftReduce(_), DraftShift(_)) =>
      match grammar {
        Some(grammar) =>
          parse_shift_reduce_conflict_resolution(
            incoming,
            existing,
            shift_is_existing=false,
            grammar~,
          )
        None =>
          parse_shift_reduce_conflict_resolution(
            incoming,
            existing,
            shift_is_existing=false,
          )
      }
    _ => KeepBoth
  }
}

///|
fn parse_action_draft_equivalent(
  left : ParseActionDraft,
  right : ParseActionDraft,
) -> Bool {
  if !parse_action_draft_same(left, right) {
    return false
  }
  match (left, right) {
    (
      DraftShift(contributors=left_contributors, ..),
      DraftShift(contributors=right_contributors, ..),
    ) =>
      parse_shift_contributor_arrays_same(left_contributors, right_contributors)
    (
      DraftReduce(
        precedence=left_precedence,
        associativity=left_associativity,
        ..
      ),
      DraftReduce(
        precedence=right_precedence,
        associativity=right_associativity,
        ..
      ),
    ) =>
      left_precedence == right_precedence &&
      same_associativity(left_associativity, right_associativity)
    _ => true
  }
}

///|
fn parse_shift_contributor_arrays_same(
  left : Array[ParseShiftContributor],
  right : Array[ParseShiftContributor],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if !parse_shift_contributor_same(left[i], right[i]) {
      return false
    }
  }
  true
}

///|
fn parse_shift_reduce_conflict_resolution(
  shift : ParseActionDraft,
  reduce : ParseActionDraft,
  shift_is_existing~ : Bool,
  grammar? : PreparedGrammar,
) -> ParseActionConflictResolution {
  match grammar {
    Some(grammar) =>
      if parse_shift_reduce_conflict_is_declared(grammar, shift, reduce) {
        return KeepBoth
      }
    None => ()
  }
  let contributors = parse_shift_action_contributors(shift)
  if contributors.is_empty() {
    return parse_shift_reduce_decision_to_resolution(
      parse_shift_reduce_decision(
        parse_action_static_precedence(shift),
        parse_action_associativity(shift),
        reduce,
      ),
      shift_is_existing~,
    )
  }
  let mut selected : ParseShiftReduceDecision? = None
  for contributor in contributors {
    let decision = parse_shift_reduce_decision(
      contributor.precedence,
      contributor.associativity,
      reduce,
    )
    match selected {
      Some(previous) =>
        if decision is PreserveBoth {
          ()
        } else if previous is PreserveBoth {
          selected = Some(decision)
        } else if previous != decision {
          return KeepBoth
        }
      None => selected = Some(decision)
    }
  }
  match selected {
    Some(decision) =>
      parse_shift_reduce_decision_to_resolution(decision, shift_is_existing~)
    None => KeepBoth
  }
}

///|
fn parse_shift_reduce_decision(
  shift_precedence : @grammar.PrecedenceValue?,
  shift_associativity : Associativity,
  reduce : ParseActionDraft,
) -> ParseShiftReduceDecision {
  let reduce_precedence = parse_action_static_precedence(reduce)
  let comparison = match (shift_precedence, reduce_precedence) {
    (None, None) => return PreserveBoth
    (Some(@grammar.PrecedenceValue::Number(0)), None) => return PreserveBoth
    (Some(@grammar.PrecedenceValue::Number(value)), None) => value
    (Some(@grammar.PrecedenceValue::Name(_)), None) => 1
    (None, Some(_)) => -1
    (Some(left), Some(right)) => compare_precedence_value(left, right)
  }
  if comparison > 0 {
    PreferShift
  } else if comparison < 0 {
    PreferReduce
  } else {
    match
      parse_shift_reduce_conflict_associativity(shift_associativity, reduce) {
      Left => PreferReduce
      Right => PreferShift
      NoAssociativity => DropShiftAndReduce
    }
  }
}

///|
fn parse_shift_reduce_decision_to_resolution(
  decision : ParseShiftReduceDecision,
  shift_is_existing~ : Bool,
) -> ParseActionConflictResolution {
  match decision {
    PreserveBoth => KeepBoth
    DropShiftAndReduce => DropBoth
    PreferShift =>
      if shift_is_existing {
        KeepExisting
      } else {
        ReplaceExisting
      }
    PreferReduce =>
      if shift_is_existing {
        ReplaceExisting
      } else {
        KeepExisting
      }
  }
}

///|
fn parse_shift_reduce_conflict_is_declared(
  grammar : PreparedGrammar,
  shift : ParseActionDraft,
  reduce : ParseActionDraft,
) -> Bool {
  let reduce_symbol = parse_action_draft_reduce_symbol(reduce)
  let contributors = parse_shift_action_contributors(shift)
  for row in grammar.syntax.conflict_symbols {
    if !contains_internal_symbol(row, reduce_symbol) {
      continue
    }
    for contributor in contributors {
      if contains_internal_symbol(row, contributor.symbol) {
        return true
      }
    }
  }
  false
}

///|
fn parse_shift_action_contributors(
  action : ParseActionDraft,
) -> Array[ParseShiftContributor] {
  match action {
    DraftShift(contributors~, ..) => contributors
    DraftAccept | DraftShiftExtra | DraftReduce(_) => []
  }
}

///|
fn parse_action_static_precedence(
  action : ParseActionDraft,
) -> @grammar.PrecedenceValue? {
  match action {
    DraftShift(contributors~, ..) =>
      parse_shift_effective_metadata(contributors).0
    DraftReduce(precedence~, ..) => precedence
    DraftAccept | DraftShiftExtra => None
  }
}

///|
fn parse_shift_effective_metadata(
  contributors : Array[ParseShiftContributor],
) -> (@grammar.PrecedenceValue?, Associativity) {
  let mut precedence : @grammar.PrecedenceValue? = None
  let mut associativity = Associativity::NoAssociativity
  for contributor in contributors {
    if compare_precedence_value_option(contributor.precedence, precedence) > 0 ||
      (
        compare_precedence_value_option(contributor.precedence, precedence) == 0 &&
        compare_associativity(contributor.associativity, associativity) > 0
      ) {
      precedence = contributor.precedence
      associativity = contributor.associativity
    }
  }
  (precedence, associativity)
}

///|
fn parse_shift_reduce_conflict_associativity(
  shift_associativity : Associativity,
  reduce : ParseActionDraft,
) -> Associativity {
  let reduce_associativity = parse_action_associativity(reduce)
  if reduce_associativity is NoAssociativity {
    shift_associativity
  } else {
    reduce_associativity
  }
}

///|
fn parse_action_associativity(action : ParseActionDraft) -> Associativity {
  match action {
    DraftShift(contributors~, ..) =>
      parse_shift_effective_metadata(contributors).1
    DraftReduce(associativity~, ..) => associativity
    DraftAccept | DraftShiftExtra => Associativity::NoAssociativity
  }
}

///|
fn parse_state_draft_ensure_action(
  state : ParseStateDraft,
  symbol : ParseTerminalSymbol,
  action : ParseActionDraft,
) -> Unit {
  if !parse_state_draft_has_terminal(state, symbol) {
    parse_state_draft_add_action(state, symbol, action)
  }
}

///|
fn parse_state_draft_has_terminal(
  state : ParseStateDraft,
  symbol : ParseTerminalSymbol,
) -> Bool {
  for entry in state.terminal_entries {
    if compare_parse_terminal_symbol(entry.symbol, symbol) == 0 {
      return true
    }
  }
  false
}

///|
fn parse_state_draft_terminal_entry_for_symbol(
  state : ParseStateDraft,
  symbol : ParseTableSymbolDraft,
) -> ParseTerminalEntryDraft? {
  match symbol {
    ParseSymbolEnd =>
      match
        parse_state_draft_find_terminal_entry(
          state,
          ParseTerminalSymbol::ParseEnd,
        ) {
        Some(entry) => Some(entry)
        None =>
          parse_state_draft_find_terminal_entry(
            state,
            ParseTerminalSymbol::ParseEndOfNonTerminalExtra,
          )
      }
    ParseSymbolTerminal(index) =>
      parse_state_draft_find_terminal_entry(
        state,
        ParseTerminalSymbol::ParseTerminal(index),
      )
    ParseSymbolExternal(index) =>
      parse_state_draft_find_terminal_entry(
        state,
        ParseTerminalSymbol::ParseExternal(index),
      )
    ParseSymbolNonTerminal(_) => None
  }
}

///|
fn parse_state_draft_find_terminal_entry(
  state : ParseStateDraft,
  symbol : ParseTerminalSymbol,
) -> ParseTerminalEntryDraft? {
  for entry in state.terminal_entries {
    if compare_parse_terminal_symbol(entry.symbol, symbol) == 0 {
      return Some(entry)
    }
  }
  None
}

///|
fn parse_state_draft_goto_entry_for_symbol(
  state : ParseStateDraft,
  symbol : ParseTableSymbolDraft,
) -> ParseGotoEntryDraft? {
  match symbol {
    ParseSymbolNonTerminal(index) =>
      parse_state_draft_find_goto_entry(
        state,
        InternalSymbol::NonTerminal(index),
      )
    ParseSymbolEnd | ParseSymbolTerminal(_) | ParseSymbolExternal(_) => None
  }
}

///|
fn parse_state_draft_find_goto_entry(
  state : ParseStateDraft,
  symbol : InternalSymbol,
) -> ParseGotoEntryDraft? {
  for entry in state.nonterminal_entries {
    if entry.symbol == symbol {
      return Some(entry)
    }
  }
  None
}

///|
fn parse_state_draft_terminal_entry(
  state : ParseStateDraft,
  symbol : ParseTerminalSymbol,
) -> ParseTerminalEntryDraft {
  for i in 0..<state.terminal_entries.length() {
    let comparison = compare_parse_terminal_symbol(
      state.terminal_entries[i].symbol,
      symbol,
    )
    if comparison == 0 {
      return state.terminal_entries[i]
    }
    if comparison > 0 {
      let entry = { symbol, actions: [], action_list_id: 0 }
      state.terminal_entries.insert(i, entry)
      return entry
    }
  }
  let entry = { symbol, actions: [], action_list_id: 0 }
  state.terminal_entries.push(entry)
  entry
}

///|
fn parse_state_draft_add_goto(
  state : ParseStateDraft,
  symbol : InternalSymbol,
  action : ParseGotoDraft,
) -> Unit {
  for i in 0..<state.nonterminal_entries.length() {
    let comparison = compare_internal_symbol(
      state.nonterminal_entries[i].symbol,
      symbol,
    )
    if comparison == 0 {
      state.nonterminal_entries[i] = { symbol, action }
      return
    }
    if comparison > 0 {
      state.nonterminal_entries.insert(i, { symbol, action })
      return
    }
  }
  state.nonterminal_entries.push({ symbol, action })
}

///|
fn compare_parse_terminal_symbol(
  left : ParseTerminalSymbol,
  right : ParseTerminalSymbol,
) -> Int {
  let mut comparison = compare_int(
    parse_terminal_symbol_rank(left),
    parse_terminal_symbol_rank(right),
  )
  if comparison != 0 {
    return comparison
  }
  comparison = compare_int(
    parse_terminal_symbol_index(left),
    parse_terminal_symbol_index(right),
  )
  comparison
}

///|
fn parse_terminal_symbol_rank(symbol : ParseTerminalSymbol) -> Int {
  match symbol {
    ParseTerminal(_) => 0
    ParseExternal(_) => 1
    ParseEnd => 2
    ParseEndOfNonTerminalExtra => 3
  }
}

///|
fn parse_terminal_symbol_index(symbol : ParseTerminalSymbol) -> Int {
  match symbol {
    ParseTerminal(index) | ParseExternal(index) => index
    ParseEnd | ParseEndOfNonTerminalExtra => 0
  }
}

///|
fn parse_table_draft_weight(draft : ParseTableDraft) -> Int {
  let mut weight = 0
  for state in draft.states {
    weight += state.id
    weight += state.core_id
    for entry in state.terminal_entries {
      weight += parse_terminal_symbol_rank(entry.symbol)
      weight += entry.action_list_id
      for action in entry.actions {
        weight += parse_action_draft_weight(action)
      }
    }
    weight += parse_token_set_weight(state.reserved_words)
    for entry in state.nonterminal_entries {
      weight += internal_symbol_weight(entry.symbol)
      weight += parse_goto_draft_weight(entry.action)
    }
  }
  for production_info in draft.production_infos {
    weight += parse_production_info_weight(production_info)
  }
  for symbol in draft.symbols {
    weight += parse_table_symbol_weight(symbol)
  }
  for primary_state_id in draft.primary_state_ids {
    weight += primary_state_id + 10007
  }
  for state_id in draft.nonterminal_extra_state_ids {
    weight += state_id + 10103
  }
  weight += parse_reserved_word_sets_weight(draft.reserved_word_sets)
  weight += parse_external_lex_states_weight(draft.external_lex_states)
  for action_list in draft.parse_action_lists {
    weight += parse_action_list_weight(action_list)
  }
  weight += parse_table_layout_weight(draft.layout)
  weight += draft.max_aliased_production_length
  weight += parse_used_symbols_weight(draft.used_symbols)
  weight
}

///|
fn parse_action_draft_weight(action : ParseActionDraft) -> Int {
  match action {
    DraftAccept => 1
    DraftShift(state_id~, is_repetition~, ..) =>
      if is_repetition {
        state_id + 11
      } else {
        state_id + 3
      }
    DraftShiftExtra => 13
    DraftReduce(symbol~, child_count~, dynamic_precedence~, production_id~, ..) =>
      internal_symbol_weight(symbol) +
      child_count +
      dynamic_precedence +
      production_id +
      17
  }
}

///|
fn parse_goto_draft_weight(action : ParseGotoDraft) -> Int {
  match action {
    DraftGoto(state_id) => state_id + 1
    DraftGotoShiftExtra => 31
  }
}

///|
fn parse_table_symbol_weight(symbol : ParseTableSymbolDraft) -> Int {
  match symbol {
    ParseSymbolEnd => 4001
    ParseSymbolTerminal(index) => index + 4011
    ParseSymbolExternal(index) => index + 5003
    ParseSymbolNonTerminal(index) => index + 6007
  }
}

///|
fn parse_action_list_weight(action_list : ParseActionListDraft) -> Int {
  let mut weight = if action_list.reusable { 7001 } else { 0 }
  for action in action_list.actions {
    weight += parse_action_draft_weight(action)
  }
  weight
}

///|
fn parse_table_layout_weight(layout : ParseTableLayoutDraft) -> Int {
  let mut weight = layout.large_state_count
  for row in layout.large_rows {
    for cell in row {
      weight += parse_table_cell_weight(cell)
    }
  }
  for offset in layout.small_state_offsets {
    weight += offset
  }
  for row in layout.small_rows {
    weight += row.state_id + row.offset
    for section in row.sections {
      weight += parse_small_section_kind_rank(section.kind)
      weight += section.value
      weight += parse_table_symbol_weight(section.first_symbol)
      for symbol in section.symbols {
        weight += parse_table_symbol_weight(symbol)
      }
    }
  }
  weight
}

///|
fn parse_reserved_word_sets_weight(table : ParseReservedWordSetsDraft) -> Int {
  let mut weight = table.max_size
  for set in table.sets {
    weight += parse_token_set_weight(set)
  }
  for state_id in table.state_ids {
    weight += state_id + 11003
  }
  weight
}

///|
fn parse_external_lex_states_weight(table : ParseExternalLexStatesDraft) -> Int {
  let mut weight = 0
  for set in table.sets {
    weight += parse_token_set_weight(set)
  }
  for state_id in table.state_ids {
    weight += state_id + 12007
  }
  weight
}

///|
fn parse_table_cell_weight(cell : ParseTableCellDraft) -> Int {
  match cell {
    ParseCellEmpty => 0
    ParseCellAction(index) => index + 8009
    ParseCellState(index) => index + 9001
  }
}

///|
fn parse_production_info_weight(info : ParseProductionInfoDraft) -> Int {
  let mut weight = info.alias_sequence.length()
  for alias_entry in info.alias_sequence {
    match alias_entry {
      Some(value) => {
        weight += value.value.length()
        if value.named {
          weight += 1
        }
      }
      None => ()
    }
  }
  for field in info.field_map {
    weight += field.name.length()
    for location in field.locations {
      weight += location.index
      if location.inherited {
        weight += 1
      }
    }
  }
  weight
}

///|
fn parse_used_symbols_weight(used : ParseUsedSymbolsDraft) -> Int {
  let mut weight = parse_token_set_weight(used.tokens)
  for symbol in used.nonterminals {
    weight += symbol + 3001
  }
  weight
}
