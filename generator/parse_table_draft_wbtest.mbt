///|
fn parse_table_draft_for(
  grammar : PreparedGrammar,
) -> ParseTableDraft raise GenerateError {
  let symbol_sets = build_parse_symbol_sets(grammar)
  let builder = build_parse_item_set_builder(grammar, symbol_sets)
  let graph = build_parse_state_graph(builder)
  build_parse_table_draft(builder, graph)
}

///|
fn parse_table_terminal_entry(
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
fn parse_table_goto_entry(
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
fn parse_table_field_entry(
  info : ParseProductionInfoDraft,
  name : String,
) -> ParseFieldMapEntryDraft? {
  for entry in info.field_map {
    if entry.name == name {
      return Some(entry)
    }
  }
  None
}

///|
fn parse_table_has_field_location(
  draft : ParseTableDraft,
  name : String,
  index : Int,
  inherited : Bool,
) -> Bool {
  for info in draft.production_infos {
    match parse_table_field_entry(info, name) {
      Some(entry) =>
        for location in entry.locations {
          if location.index == index && location.inherited == inherited {
            return true
          }
        }
      None => ()
    }
  }
  false
}

///|
fn parse_table_small_row_for_state(
  layout : ParseTableLayoutDraft,
  state_id : Int,
) -> ParseSmallParseTableRowDraft? {
  for row in layout.small_rows {
    if row.state_id == state_id {
      return Some(row)
    }
  }
  None
}

///|
fn parse_table_shift_action(
  precedence : @grammar.PrecedenceValue?,
  associativity : Associativity,
) -> ParseActionDraft {
  ParseActionDraft::DraftShift(state_id=9, is_repetition=false, contributors=[
    { symbol: InternalSymbol::NonTerminal(0), precedence, associativity },
  ])
}

///|
fn parse_table_reduce_action(
  precedence : @grammar.PrecedenceValue?,
  associativity : Associativity,
) -> ParseActionDraft {
  ParseActionDraft::DraftReduce(
    symbol=InternalSymbol::NonTerminal(0),
    child_count=1,
    dynamic_precedence=0,
    production_id=0,
    precedence~,
    associativity~,
  )
}

///|
fn parse_table_prec_step(
  symbol : InternalSymbol,
  precedence : Int,
  associativity : Associativity,
) -> ProductionStep {
  {
    ..parse_analysis_step(symbol),
    precedence: Some(@grammar.PrecedenceValue::Number(precedence)),
    associativity,
  }
}

///|
fn parse_table_entry_has_shift_reduce(
  draft : ParseTableDraft,
  symbol : ParseTerminalSymbol,
) -> Bool {
  for state in draft.states {
    match parse_table_terminal_entry(state, symbol) {
      Some(entry) => {
        let mut has_shift = false
        let mut has_reduce = false
        for action in entry.actions {
          match action {
            DraftShift(_) => has_shift = true
            DraftReduce(_) => has_reduce = true
            DraftAccept | DraftShiftExtra => ()
          }
        }
        if has_shift && has_reduce {
          return true
        }
      }
      None => ()
    }
  }
  false
}

///|
test "parse table draft resolves static shift reduce precedence" {
  let shift_high = parse_table_shift_action(
    Some(@grammar.PrecedenceValue::Number(2)),
    Associativity::NoAssociativity,
  )
  let reduce_low = parse_table_reduce_action(
    Some(@grammar.PrecedenceValue::Number(1)),
    Associativity::NoAssociativity,
  )
  assert_true(
    parse_action_conflict_resolution(reduce_low, shift_high) is ReplaceExisting,
  )

  let shift_low = parse_table_shift_action(
    Some(@grammar.PrecedenceValue::Number(1)),
    Associativity::NoAssociativity,
  )
  let reduce_high = parse_table_reduce_action(
    Some(@grammar.PrecedenceValue::Number(2)),
    Associativity::NoAssociativity,
  )
  assert_true(
    parse_action_conflict_resolution(reduce_high, shift_low) is KeepExisting,
  )

  let reduce_default = parse_table_reduce_action(
    None,
    Associativity::NoAssociativity,
  )
  let shift_negative = parse_table_shift_action(
    Some(@grammar.PrecedenceValue::Number(-1)),
    Associativity::NoAssociativity,
  )
  assert_true(
    parse_action_conflict_resolution(reduce_default, shift_negative)
    is KeepExisting,
  )

  let shift_positive = parse_table_shift_action(
    Some(@grammar.PrecedenceValue::Number(1)),
    Associativity::NoAssociativity,
  )
  assert_true(
    parse_action_conflict_resolution(reduce_default, shift_positive)
    is ReplaceExisting,
  )

  let shift_zero = parse_table_shift_action(
    Some(@grammar.PrecedenceValue::Number(0)),
    Associativity::Right,
  )
  assert_true(
    parse_action_conflict_resolution(reduce_default, shift_zero) is KeepBoth,
  )

  let mixed_shift = ParseActionDraft::DraftShift(
    state_id=1,
    is_repetition=false,
    contributors=[
      {
        symbol: InternalSymbol::NonTerminal(1),
        precedence: None,
        associativity: Associativity::NoAssociativity,
      },
      {
        symbol: InternalSymbol::NonTerminal(2),
        precedence: Some(@grammar.PrecedenceValue::Number(-1)),
        associativity: Associativity::Right,
      },
    ],
  )
  assert_true(
    parse_action_conflict_resolution(reduce_default, mixed_shift)
    is KeepExisting,
  )
}

///|
test "parse table draft dedupes identical reduce actions" {
  let state : ParseStateDraft = {
    id: 0,
    core_id: 0,
    terminal_entries: [],
    nonterminal_entries: [],
    reserved_words: parse_token_set_empty(),
  }
  let action = parse_table_reduce_action(
    Some(@grammar.PrecedenceValue::Number(1)),
    Associativity::Left,
  )

  parse_state_draft_add_action(
    state,
    ParseTerminalSymbol::ParseTerminal(0),
    action,
  )
  parse_state_draft_add_action(
    state,
    ParseTerminalSymbol::ParseTerminal(0),
    action,
  )

  guard parse_table_terminal_entry(state, ParseTerminalSymbol::ParseTerminal(0))
    is Some(entry) else {
    fail("expected action entry")
  }
  assert_eq(entry.actions.length(), 1)
}

///|
test "parse table draft resolves tied shift reduce associativity" {
  let precedence = Some(@grammar.PrecedenceValue::Number(1))
  let shift = parse_table_shift_action(precedence, Associativity::Left)
  let reduce_left = parse_table_reduce_action(precedence, Associativity::Left)
  assert_true(
    parse_action_conflict_resolution(reduce_left, shift) is KeepExisting,
  )

  let reduce_right = parse_table_reduce_action(precedence, Associativity::Right)
  assert_true(
    parse_action_conflict_resolution(reduce_right, shift) is ReplaceExisting,
  )
}

///|
test "parse table draft preserves declared shift reduce conflict actions" {
  let expression = InternalSymbol::NonTerminal(0)
  let star = InternalSymbol::Terminal(0)
  let identifier = InternalSymbol::Terminal(1)
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_table_prec_step(expression, 1, Associativity::Left),
          parse_table_prec_step(star, 1, Associativity::Left),
          parse_table_prec_step(expression, 1, Associativity::Left),
        ]),
        parse_analysis_production([parse_analysis_step(identifier)]),
      ]),
    ],
    terminal_count=2,
    conflict_symbols=[[expression]],
  )
  let draft = parse_table_draft_for(grammar)
  assert_true(parse_table_entry_has_shift_reduce(draft, ParseTerminal(0)))
}

///|
fn parse_table_simple_terminal_draft() -> ParseTableDraft raise GenerateError {
  parse_table_draft_for(
    parse_analysis_prepared(
      [
        parse_analysis_variable(0, [
          parse_analysis_production([
            parse_analysis_step(InternalSymbol::Terminal(0)),
          ]),
        ]),
      ],
      terminal_count=1,
    ),
  )
}

///|
fn assert_parse_table_range_error(
  result : GenerateError,
  kind : String,
  value : Int,
  min : Int,
  max : Int,
) -> Unit raise {
  guard result
    is GenerateError::ParseTableValueOutOfRange(
      kind=actual_kind,
      value=actual_value,
      min=actual_min,
      max=actual_max
    ) else {
    fail("expected parse table range error")
  }
  assert_eq(actual_kind, kind)
  assert_eq(actual_value, value)
  assert_eq(actual_min, min)
  assert_eq(actual_max, max)
}

///|
test "parse table draft adds shift reduce goto and accept entries" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
    ],
    terminal_count=1,
  )
  let draft = parse_table_draft_for(grammar)

  let start_state = draft.states[1]

  guard parse_table_terminal_entry(
      start_state,
      ParseTerminalSymbol::ParseTerminal(0),
    )
    is Some(shift_entry) else {
    fail("start state should shift on terminal 0")
  }
  guard shift_entry.actions[0] is DraftShift(state_id~, is_repetition~, ..) else {
    fail("terminal entry should contain a shift")
  }
  assert_eq(state_id, 2)
  assert_true(!is_repetition)

  guard parse_table_goto_entry(start_state, InternalSymbol::NonTerminal(0))
    is Some(goto_entry) else {
    fail("start state should goto the completed start nonterminal")
  }
  guard goto_entry.action is ParseGotoDraft::DraftGoto(goto_state) else {
    fail("goto entry should contain a state id")
  }
  assert_eq(goto_state, 3)

  guard parse_table_terminal_entry(
      draft.states[2],
      ParseTerminalSymbol::ParseEnd,
    )
    is Some(reduce_entry) else {
    fail("state after terminal should reduce on EOF")
  }
  guard reduce_entry.actions[0]
    is DraftReduce(
      symbol~,
      child_count~,
      dynamic_precedence~,
      production_id~,
      ..
    ) else {
    fail("EOF entry should contain a reduce")
  }
  assert_true(symbol == InternalSymbol::NonTerminal(0))
  assert_eq(child_count, 1)
  assert_eq(dynamic_precedence, 0)
  assert_eq(production_id, 0)
  assert_eq(draft.production_infos.length(), 1)

  guard parse_table_terminal_entry(
      draft.states[3],
      ParseTerminalSymbol::ParseEnd,
    )
    is Some(accept_entry) else {
    fail("completed start state should accept on EOF")
  }
  assert_true(accept_entry.actions[0] is DraftAccept)
  assert_true(draft.primary_state_ids == [0, 1, 2, 3])
  assert_eq(draft.reserved_word_sets.sets.length(), 1)
  assert_eq(draft.reserved_word_sets.max_size, 0)
  assert_true(draft.reserved_word_sets.state_ids == [0, 0, 0, 0])
  assert_eq(draft.external_lex_states.sets.length(), 1)
  assert_true(draft.external_lex_states.state_ids == [0, 0, 0, 0])
}

///|
test "parse table draft records aliases fields and max production length" {
  let aliased = {
    ..parse_analysis_step(InternalSymbol::Terminal(0)),
    alias_name: Some("leaf"),
    alias_named: true,
    field_name: Some("left"),
  }
  let fielded = {
    ..parse_analysis_step(InternalSymbol::Terminal(1)),
    field_name: Some("right"),
  }
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          aliased,
          fielded,
          parse_analysis_step(InternalSymbol::Terminal(2)),
        ]),
      ]),
    ],
    terminal_count=3,
  )
  let draft = parse_table_draft_for(grammar)

  assert_eq(draft.production_infos.length(), 2)
  assert_eq(draft.max_aliased_production_length, 3)
  let info = draft.production_infos[1]
  assert_eq(info.alias_sequence.length(), 1)
  guard info.alias_sequence[0] is Some(alias_info) else {
    fail("first child should have an alias")
  }
  assert_eq(alias_info.value, "leaf")
  assert_true(alias_info.named)

  guard parse_table_field_entry(info, "left") is Some(left_field) else {
    fail("left field should be recorded")
  }
  assert_eq(left_field.locations[0].index, 0)
  assert_true(!left_field.locations[0].inherited)
  guard parse_table_field_entry(info, "right") is Some(right_field) else {
    fail("right field should be recorded")
  }
  assert_eq(right_field.locations[0].index, 1)
  assert_true(!right_field.locations[0].inherited)
}

///|
test "parse table draft records inherited fields from hidden children" {
  let hidden_child = {
    ..parse_analysis_variable(1, [
      parse_analysis_production([
        {
          ..parse_analysis_step(InternalSymbol::Terminal(0)),
          field_name: Some("inner"),
        },
      ]),
    ]),
    kind: VariableKind::Hidden,
  }
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::NonTerminal(1)),
        ]),
      ]),
      hidden_child,
    ],
    terminal_count=1,
  )
  let draft = parse_table_draft_for(grammar)

  assert_eq(draft.production_infos.length(), 3)
  assert_true(parse_table_has_field_location(draft, "inner", 0, true))
}

///|
test "parse table draft records used terminals eof and nonterminals" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
    ],
    terminal_count=1,
  )
  let draft = parse_table_draft_for(grammar)

  let expected_tokens = parse_analysis_token_set([0], [])
  expected_tokens.eof = true
  assert_true(parse_token_set_same(draft.used_symbols.tokens, expected_tokens))
  assert_true(draft.used_symbols.nonterminals == [0])
}

///|
test "parse table draft orders used symbols after eof" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
    ],
    terminal_count=1,
  )
  let draft = parse_table_draft_for(grammar)

  assert_eq(draft.symbols.length(), 3)
  assert_true(draft.symbols[0] is ParseTableSymbolDraft::ParseSymbolEnd)
  assert_true(draft.symbols[1] is ParseTableSymbolDraft::ParseSymbolTerminal(0))
  assert_true(
    draft.symbols[2] is ParseTableSymbolDraft::ParseSymbolNonTerminal(0),
  )
}

///|
test "parse table draft puts used word token in low symbol slot" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(2)),
        ]),
      ]),
    ],
    terminal_count=3,
    word_symbol=InternalSymbol::Terminal(2),
  )
  let draft = parse_table_draft_for(grammar)

  assert_eq(draft.symbols.length(), 4)
  assert_true(draft.symbols[0] is ParseTableSymbolDraft::ParseSymbolEnd)
  assert_true(draft.symbols[1] is ParseTableSymbolDraft::ParseSymbolTerminal(2))
  assert_true(draft.symbols[2] is ParseTableSymbolDraft::ParseSymbolTerminal(0))
  assert_true(
    draft.symbols[3] is ParseTableSymbolDraft::ParseSymbolNonTerminal(0),
  )
}

///|
test "parse table draft assigns reusable action list ids" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
    ],
    terminal_count=1,
  )
  let draft = parse_table_draft_for(grammar)

  assert_eq(draft.parse_action_lists.length(), 4)
  assert_true(!draft.parse_action_lists[0].reusable)
  assert_eq(draft.parse_action_lists[0].actions.length(), 0)
  guard parse_table_terminal_entry(
      draft.states[1],
      ParseTerminalSymbol::ParseTerminal(0),
    )
    is Some(shift_entry) else {
    fail("start state should shift on terminal 0")
  }
  assert_eq(shift_entry.action_list_id, 1)
  assert_true(draft.parse_action_lists[1].reusable)
  assert_true(draft.parse_action_lists[1].actions[0] is DraftShift(_))

  guard parse_table_terminal_entry(
      draft.states[2],
      ParseTerminalSymbol::ParseEnd,
    )
    is Some(reduce_entry) else {
    fail("state after terminal should reduce on EOF")
  }
  assert_eq(reduce_entry.action_list_id, 2)
  assert_true(draft.parse_action_lists[2].actions[0] is DraftReduce(_))

  guard parse_table_terminal_entry(
      draft.states[3],
      ParseTerminalSymbol::ParseEnd,
    )
    is Some(accept_entry) else {
    fail("completed start state should accept on EOF")
  }
  assert_eq(accept_entry.action_list_id, 3)
  assert_true(draft.parse_action_lists[3].actions[0] is DraftAccept)
}

///|
test "parse table draft validates action list id width" {
  let draft = parse_table_simple_terminal_draft()

  guard parse_table_terminal_entry(
      draft.states[1],
      ParseTerminalSymbol::ParseTerminal(0),
    )
    is Some(entry) else {
    fail("start state should shift on terminal 0")
  }
  entry.action_list_id = 65535

  let validation = @test.expect_error(() => {
    validate_parse_table_draft_width(draft)
  })
  assert_parse_table_range_error(
    validation, "parse_action_list_id", 65535, 0, 65534,
  )
}

///|
test "parse table draft validates primary state id width" {
  let draft = parse_table_simple_terminal_draft()

  draft.primary_state_ids[1] = 65535

  let validation = @test.expect_error(() => {
    validate_parse_table_draft_width(draft)
  })
  assert_parse_table_range_error(
    validation, "primary_state_id", 65535, 0, 65534,
  )
}

///|
test "parse table draft validates reserved word set id width" {
  let draft = parse_table_simple_terminal_draft()

  draft.reserved_word_sets.state_ids[0] = 1

  let validation = @test.expect_error(() => {
    validate_parse_table_draft_width(draft)
  })
  assert_parse_table_range_error(validation, "reserved_word_set_id", 1, 0, 0)
}

///|
test "parse table draft validates external lex state id width" {
  let draft = parse_table_simple_terminal_draft()

  draft.external_lex_states.state_ids[0] = 1

  let validation = @test.expect_error(() => {
    validate_parse_table_draft_width(draft)
  })
  assert_parse_table_range_error(validation, "external_lex_state_id", 1, 0, 0)
}

///|
test "parse table draft validates action entry count width" {
  let draft = parse_table_simple_terminal_draft()

  while draft.parse_action_lists[1].actions.length() <= 255 {
    draft.parse_action_lists[1].actions.push(ParseActionDraft::DraftAccept)
  }

  let validation = @test.expect_error(() => {
    validate_parse_table_draft_width(draft)
  })
  assert_parse_table_range_error(validation, "parse_action_count", 256, 0, 255)
}

///|
test "parse table draft validates reduce metadata width" {
  let draft = parse_table_simple_terminal_draft()

  draft.parse_action_lists[2].actions[0] = ParseActionDraft::DraftReduce(
    symbol=InternalSymbol::NonTerminal(0),
    child_count=256,
    dynamic_precedence=0,
    production_id=0,
    precedence=None,
    associativity=Associativity::NoAssociativity,
  )

  let validation = @test.expect_error(() => {
    validate_parse_table_draft_width(draft)
  })
  assert_parse_table_range_error(validation, "reduce_child_count", 256, 0, 255)
}

///|
test "parse table draft validates large table cell width" {
  let draft = parse_table_simple_terminal_draft()

  draft.layout.large_rows[1][1] = ParseTableCellDraft::ParseCellAction(65535)

  let validation = @test.expect_error(() => {
    validate_parse_table_draft_width(draft)
  })
  assert_parse_table_range_error(
    validation, "large_cell_action_id", 65535, 1, 65534,
  )
}

///|
test "parse table draft builds large rows and small offsets" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
    ],
    terminal_count=1,
  )
  let draft = parse_table_draft_for(grammar)

  assert_eq(draft.layout.large_state_count, 2)
  assert_eq(draft.layout.large_rows.length(), 2)
  assert_eq(draft.layout.large_rows[1].length(), draft.symbols.length())
  assert_true(
    draft.layout.large_rows[1][0] is ParseTableCellDraft::ParseCellEmpty,
  )
  assert_true(
    draft.layout.large_rows[1][1] is ParseTableCellDraft::ParseCellAction(1),
  )
  assert_true(
    draft.layout.large_rows[1][2] is ParseTableCellDraft::ParseCellState(3),
  )
  assert_true(draft.layout.small_state_offsets == [0, 4])
  assert_eq(draft.layout.small_rows[0].state_id, 2)
  assert_eq(draft.layout.small_rows[0].sections.length(), 1)
  assert_true(
    draft.layout.small_rows[0].sections[0].kind
    is ParseSmallParseTableSectionKindDraft::ParseSmallAction,
  )
  assert_eq(draft.layout.small_rows[0].sections[0].value, 2)
  assert_true(
    draft.layout.small_rows[0].sections[0].symbols[0]
    is ParseTableSymbolDraft::ParseSymbolEnd,
  )
}

///|
test "parse table draft dedupes identical action lists" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::NonTerminal(1)),
          parse_analysis_step(InternalSymbol::NonTerminal(2)),
        ]),
      ]),
      parse_analysis_variable(1, [parse_analysis_production([])]),
      parse_analysis_variable(2, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(1)),
        ]),
      ]),
    ],
    terminal_count=2,
  )
  let draft = parse_table_draft_for(grammar)

  guard parse_table_terminal_entry(
      draft.states[1],
      ParseTerminalSymbol::ParseTerminal(0),
    )
    is Some(left_entry) else {
    fail("start state should reduce on terminal 0")
  }
  guard parse_table_terminal_entry(
      draft.states[1],
      ParseTerminalSymbol::ParseTerminal(1),
    )
    is Some(right_entry) else {
    fail("start state should reduce on terminal 1")
  }
  assert_eq(left_entry.action_list_id, right_entry.action_list_id)
  let action_list = draft.parse_action_lists[left_entry.action_list_id]
  guard action_list.actions[0] is DraftReduce(symbol~, child_count~, ..) else {
    fail("shared list should contain a reduce")
  }
  assert_true(symbol == InternalSymbol::NonTerminal(1))
  assert_eq(child_count, 0)
}

///|
test "parse table draft maps duplicate core states to primary state" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::NonTerminal(1)),
          parse_analysis_step(InternalSymbol::Terminal(1)),
        ]),
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(3)),
          parse_analysis_step(InternalSymbol::NonTerminal(1)),
          parse_analysis_step(InternalSymbol::Terminal(2)),
        ]),
      ]),
      parse_analysis_variable(1, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
    ],
    terminal_count=4,
  )
  let draft = parse_table_draft_for(grammar)

  let mut duplicate_core_found = false
  for i in 0..<draft.states.length() {
    if draft.primary_state_ids[i] != draft.states[i].id {
      duplicate_core_found = true
      let primary_state_id = draft.primary_state_ids[i]
      assert_true(primary_state_id < draft.states[i].id)
      assert_eq(draft.states[primary_state_id].core_id, draft.states[i].core_id)
    }
  }
  assert_true(duplicate_core_found)
}

///|
test "parse table draft groups small table symbols by value" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
          parse_analysis_step(InternalSymbol::NonTerminal(1)),
          parse_analysis_step(InternalSymbol::NonTerminal(2)),
        ]),
      ]),
      parse_analysis_variable(1, [parse_analysis_production([])]),
      parse_analysis_variable(2, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(1)),
        ]),
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(2)),
        ]),
      ]),
    ],
    terminal_count=3,
  )
  let draft = parse_table_draft_for(grammar)

  guard parse_table_terminal_entry(
      draft.states[1],
      ParseTerminalSymbol::ParseTerminal(0),
    )
    is Some(prefix_entry) else {
    fail("start state should shift on terminal 0")
  }
  guard prefix_entry.actions[0] is DraftShift(state_id=prefix_state, ..) else {
    fail("terminal 0 should shift")
  }
  guard parse_table_small_row_for_state(draft.layout, prefix_state)
    is Some(prefix_row) else {
    fail("state after terminal 0 should use the small table")
  }

  let mut found_group = false
  for section in prefix_row.sections {
    if section.kind is ParseSmallParseTableSectionKindDraft::ParseSmallAction &&
      section.symbols.length() == 2 {
      assert_true(
        section.symbols[0] is ParseTableSymbolDraft::ParseSymbolTerminal(1),
      )
      assert_true(
        section.symbols[1] is ParseTableSymbolDraft::ParseSymbolTerminal(2),
      )
      found_group = true
    }
  }
  assert_true(found_group)
}

///|
test "parse table draft records used externals and extra end token" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
      parse_analysis_variable(1, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::External(0)),
          parse_analysis_step(InternalSymbol::Terminal(1)),
        ]),
      ]),
    ],
    external_count=1,
    terminal_count=2,
    extra_symbols=[InternalSymbol::NonTerminal(1)],
  )
  let draft = parse_table_draft_for(grammar)

  let expected_tokens = parse_analysis_token_set([0, 1], [0])
  expected_tokens.eof = true
  expected_tokens.end_of_nonterminal_extra = true
  assert_true(parse_token_set_same(draft.used_symbols.tokens, expected_tokens))
  assert_true(draft.used_symbols.nonterminals == [0, 1])
  assert_eq(draft.symbols.length(), 6)
  assert_true(draft.symbols[0] is ParseTableSymbolDraft::ParseSymbolEnd)
  assert_true(draft.symbols[1] is ParseTableSymbolDraft::ParseSymbolTerminal(0))
  assert_true(draft.symbols[2] is ParseTableSymbolDraft::ParseSymbolTerminal(1))
  assert_true(draft.symbols[3] is ParseTableSymbolDraft::ParseSymbolExternal(0))
  assert_true(
    draft.symbols[4] is ParseTableSymbolDraft::ParseSymbolNonTerminal(0),
  )
  assert_true(
    draft.symbols[5] is ParseTableSymbolDraft::ParseSymbolNonTerminal(1),
  )
}

///|
test "parse table draft records direct external lex states" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::External(0)),
        ]),
      ]),
    ],
    external_count=1,
  )
  let draft = parse_table_draft_for(grammar)

  assert_eq(draft.external_lex_states.sets.length(), 2)
  assert_eq(draft.external_lex_states.state_ids[0], 0)
  assert_eq(draft.external_lex_states.state_ids[1], 1)
  assert_true(
    parse_token_set_same(
      draft.external_lex_states.sets[0],
      parse_analysis_token_set([], []),
    ),
  )
  assert_true(
    parse_token_set_same(
      draft.external_lex_states.sets[1],
      parse_analysis_token_set([], [0]),
    ),
  )
}

///|
test "parse table draft records paired external lex states" {
  let paired_external = {
    ..parse_analysis_external_token(0),
    corresponding_internal_token: Some(InternalSymbol::Terminal(0)),
  }
  let base = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
    ],
    terminal_count=1,
  )
  let grammar : PreparedGrammar = {
    ..base,
    syntax: { ..base.syntax, external_tokens: [paired_external] },
  }
  let draft = parse_table_draft_for(grammar)

  assert_eq(draft.external_lex_states.sets.length(), 2)
  assert_eq(draft.external_lex_states.state_ids[1], 1)
  assert_true(
    parse_token_set_same(
      draft.external_lex_states.sets[1],
      parse_analysis_token_set([], [0]),
    ),
  )
}

///|
test "parse table draft records reserved words as used tokens" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(2), reserved=1),
        ]),
      ]),
    ],
    terminal_count=3,
    word_symbol=InternalSymbol::Terminal(2),
    reserved_sets=[
      { name: "", rules: [] },
      {
        name: "keyword",
        rules: [InternedRule::IRSymbol(InternalSymbol::Terminal(1))],
      },
    ],
  )
  let draft = parse_table_draft_for(grammar)

  let expected_tokens = parse_analysis_token_set([1, 2], [])
  expected_tokens.eof = true
  assert_true(parse_token_set_same(draft.used_symbols.tokens, expected_tokens))
  assert_true(draft.used_symbols.nonterminals == [0])
}

///|
test "parse table draft preserves token set terminal ordering" {
  let set = parse_token_set_empty()
  parse_token_set_insert_symbol(set, InternalSymbol::External(1))
  parse_token_set_insert_symbol(set, InternalSymbol::Terminal(2))
  parse_token_set_insert_symbol(set, InternalSymbol::Terminal(0))
  parse_token_set_insert_symbol(set, InternalSymbol::External(0))
  set.eof = true
  set.end_of_nonterminal_extra = true
  let symbols = parse_terminal_symbols_from_set(set)

  assert_true(symbols[0] is ParseTerminalSymbol::ParseTerminal(0))
  assert_true(symbols[1] is ParseTerminalSymbol::ParseTerminal(2))
  assert_true(symbols[2] is ParseTerminalSymbol::ParseExternal(0))
  assert_true(symbols[3] is ParseTerminalSymbol::ParseExternal(1))
  assert_true(symbols[4] is ParseTerminalSymbol::ParseEnd)
  assert_true(symbols[5] is ParseTerminalSymbol::ParseEndOfNonTerminalExtra)
}

///|
test "parse table draft adds terminal extra shift extra actions" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
    ],
    terminal_count=2,
    extra_symbols=[InternalSymbol::Terminal(1)],
  )
  let draft = parse_table_draft_for(grammar)

  guard parse_table_terminal_entry(
      draft.states[1],
      ParseTerminalSymbol::ParseTerminal(1),
    )
    is Some(extra_entry) else {
    fail("start state should include terminal extra")
  }
  assert_true(extra_entry.actions[0] is DraftShiftExtra)
}

///|
test "parse table draft adds nonterminal extra shifts and gotos" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
      parse_analysis_variable(1, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(1)),
          parse_analysis_step(InternalSymbol::Terminal(2)),
        ]),
      ]),
    ],
    terminal_count=3,
    extra_symbols=[InternalSymbol::NonTerminal(1)],
  )
  let draft = parse_table_draft_for(grammar)

  guard parse_table_terminal_entry(
      draft.states[1],
      ParseTerminalSymbol::ParseTerminal(1),
    )
    is Some(extra_start_entry) else {
    fail("start state should shift to the nonterminal extra state")
  }
  guard extra_start_entry.actions[0]
    is DraftShift(state_id~, is_repetition~, ..) else {
    fail("nonterminal extra start token should shift")
  }
  assert_eq(state_id, 2)
  assert_true(!is_repetition)
  guard parse_table_goto_entry(draft.states[1], InternalSymbol::NonTerminal(1))
    is Some(extra_goto) else {
    fail("start state should include nonterminal extra goto")
  }
  assert_true(extra_goto.action is ParseGotoDraft::DraftGotoShiftExtra)
}

///|
test "parse table draft rejects ambiguous nonterminal extra endings" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
      parse_analysis_variable(1, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(1)),
        ]),
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(1)),
          parse_analysis_step(InternalSymbol::Terminal(2)),
        ]),
      ]),
    ],
    terminal_count=3,
    extra_symbols=[InternalSymbol::NonTerminal(1)],
  )
  let result = @test.expect_error(() => parse_table_draft_for(grammar))
  assert_true(result is GenerateError::AmbiguousExtra(["v1"]))
}

///|
test "parse table draft records reserved words for next word token" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(2), reserved=1),
        ]),
      ]),
    ],
    terminal_count=3,
    word_symbol=InternalSymbol::Terminal(2),
    reserved_sets=[
      { name: "", rules: [] },
      {
        name: "keyword",
        rules: [InternedRule::IRSymbol(InternalSymbol::Terminal(1))],
      },
    ],
  )
  let draft = parse_table_draft_for(grammar)

  assert_true(
    parse_token_set_same(
      draft.states[1].reserved_words,
      parse_analysis_token_set([1], []),
    ),
  )
  assert_eq(draft.reserved_word_sets.sets.length(), 2)
  assert_eq(draft.reserved_word_sets.max_size, 1)
  assert_eq(draft.reserved_word_sets.state_ids[1], 1)
  assert_true(
    parse_token_set_same(
      draft.reserved_word_sets.sets[1],
      parse_analysis_token_set([1], []),
    ),
  )
}

///|
test "parse table draft records reserved words through nonterminal first set" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::NonTerminal(1)),
        ]),
      ]),
      parse_analysis_variable(1, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(2), reserved=1),
        ]),
      ]),
    ],
    terminal_count=3,
    word_symbol=InternalSymbol::Terminal(2),
    reserved_sets=[
      { name: "", rules: [] },
      {
        name: "keyword",
        rules: [InternedRule::IRSymbol(InternalSymbol::Terminal(1))],
      },
    ],
  )
  let symbol_sets = build_parse_symbol_sets(grammar)
  let builder = build_parse_item_set_builder(grammar, symbol_sets)
  let item_set = parse_item_set_empty()
  ignore(
    item_set.insert(
      parse_item_for_production(
        0,
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::NonTerminal(1)),
        ]),
      ),
    ),
  )

  assert_true(
    parse_token_set_same(
      parse_state_reserved_words(builder, item_set),
      parse_analysis_token_set([1], []),
    ),
  )
}

///|
test "parse table draft records reserved words for done item word lookahead" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::NonTerminal(1)),
          parse_analysis_step(InternalSymbol::NonTerminal(2)),
        ]),
      ]),
      parse_analysis_variable(1, [parse_analysis_production([])]),
      parse_analysis_variable(2, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(2), reserved=1),
        ]),
      ]),
    ],
    terminal_count=3,
    word_symbol=InternalSymbol::Terminal(2),
    reserved_sets=[
      { name: "", rules: [] },
      {
        name: "keyword",
        rules: [InternedRule::IRSymbol(InternalSymbol::Terminal(1))],
      },
    ],
  )
  let draft = parse_table_draft_for(grammar)

  assert_true(
    parse_token_set_same(
      draft.states[1].reserved_words,
      parse_analysis_token_set([1], []),
    ),
  )
}

///|
test "parse table draft dedupes reserved word sets by token set" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(2), reserved=1),
        ]),
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
          parse_analysis_step(InternalSymbol::Terminal(2), reserved=1),
        ]),
      ]),
    ],
    terminal_count=3,
    word_symbol=InternalSymbol::Terminal(2),
    reserved_sets=[
      { name: "", rules: [] },
      {
        name: "keyword",
        rules: [InternedRule::IRSymbol(InternalSymbol::Terminal(1))],
      },
    ],
  )
  let draft = parse_table_draft_for(grammar)

  guard parse_table_terminal_entry(
      draft.states[1],
      ParseTerminalSymbol::ParseTerminal(0),
    )
    is Some(shift_entry) else {
    fail("start state should shift on terminal 0")
  }
  guard shift_entry.actions[0] is DraftShift(state_id=after_first, ..) else {
    fail("terminal 0 should shift")
  }

  assert_eq(draft.reserved_word_sets.sets.length(), 2)
  assert_eq(draft.reserved_word_sets.state_ids[1], 1)
  assert_eq(draft.reserved_word_sets.state_ids[after_first], 1)
}
