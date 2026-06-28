///|
fn parse_state_graph_for(
  grammar : PreparedGrammar,
) -> ParseStateGraph raise GenerateError {
  let symbol_sets = build_parse_symbol_sets(grammar)
  let builder = build_parse_item_set_builder(grammar, symbol_sets)
  build_parse_state_graph(builder)
}

///|
test "parse state graph creates error start and successor states" {
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
  let graph = parse_state_graph_for(grammar)

  assert_eq(graph.states.length(), 4)
  assert_eq(graph.start_state, 1)
  assert_eq(graph.states[0].terminal_transitions.length(), 0)
  let start_state = graph.states[graph.start_state]
  assert_eq(start_state.terminal_transitions.length(), 1)
  assert_eq(start_state.nonterminal_transitions.length(), 1)
  assert_true(
    start_state.terminal_transitions[0].symbol == InternalSymbol::Terminal(0),
  )
  assert_true(
    start_state.nonterminal_transitions[0].symbol ==
    InternalSymbol::NonTerminal(0),
  )
}

///|
test "parse state graph groups shared terminal successor item sets" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
          parse_analysis_step(InternalSymbol::Terminal(1)),
        ]),
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
          parse_analysis_step(InternalSymbol::Terminal(2)),
        ]),
      ]),
    ],
    terminal_count=3,
  )
  let graph = parse_state_graph_for(grammar)

  let start_state = graph.states[graph.start_state]
  assert_eq(start_state.terminal_transitions.length(), 1)
  let after_first = graph.states[start_state.terminal_transitions[0].state_id]
  assert_eq(after_first.item_set.entries.length(), 2)
  assert_eq(after_first.terminal_transitions.length(), 2)
  assert_true(
    after_first.terminal_transitions[0].symbol == InternalSymbol::Terminal(1),
  )
  assert_true(
    after_first.terminal_transitions[1].symbol == InternalSymbol::Terminal(2),
  )
}

///|
test "parse state graph orders terminal successors before externals" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::External(0)),
        ]),
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
    ],
    external_count=1,
    terminal_count=1,
  )
  let graph = parse_state_graph_for(grammar)

  let start_state = graph.states[graph.start_state]

  assert_eq(start_state.terminal_transitions.length(), 2)
  assert_true(
    start_state.terminal_transitions[0].symbol == InternalSymbol::Terminal(0),
  )
  assert_true(
    start_state.terminal_transitions[1].symbol == InternalSymbol::External(0),
  )
}

///|
test "parse state graph inserts nonterminal extra states after start state" {
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
  let graph = parse_state_graph_for(grammar)

  assert_eq(graph.states.length(), 6)
  assert_eq(graph.states[2].item_set.entries.length(), 1)
  assert_eq(graph.states[2].item_set.entries[0].item.variable_index, 1)
  assert_eq(graph.states[2].item_set.entries[0].item.step_index, 1)
  assert_true(
    graph.states[2].item_set.entries[0].lookaheads.end_of_nonterminal_extra,
  )
}

///|
test "parse state graph rejects nonterminal extra starting with nonterminal" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
      parse_analysis_variable(1, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::NonTerminal(0)),
        ]),
      ]),
    ],
    terminal_count=1,
    extra_symbols=[InternalSymbol::NonTerminal(1)],
  )
  let result = @test.expect_error(() => parse_state_graph_for(grammar))
  assert_true(result is GenerateError::ImproperNonTerminalExtra("v0"))
}
