///|
priv struct ParseTransition {
  symbol : InternalSymbol
  state_id : Int
}

///|
priv struct ParseStateGraphState {
  id : Int
  item_set : ParseItemSet
  core_id : Int
  terminal_transitions : Array[ParseTransition]
  nonterminal_transitions : Array[ParseTransition]
}

///|
priv struct ParseStateGraph {
  states : Array[ParseStateGraphState]
  start_state : Int
  nonterminal_extra_transitions : Array[ParseTransition]
}

///|
priv struct ParseSuccessorSet {
  symbol : InternalSymbol
  item_set : ParseItemSet
}

///|
fn build_parse_state_graph(
  builder : ParseItemSetBuilder,
) -> ParseStateGraph raise GenerateError {
  let graph : ParseStateGraph = {
    states: [],
    start_state: 1,
    nonterminal_extra_transitions: [],
  }
  let queue : Array[Int] = []
  let core_sets : Array[ParseItemSetCore] = []
  ignore(
    parse_state_graph_add_state(graph, queue, core_sets, parse_item_set_empty()),
  )
  let start_set = parse_item_set_empty()
  let start_index = start_set.insert(parse_item_start())
  start_set.entries[start_index].lookaheads.eof = true
  ignore(parse_state_graph_add_state(graph, queue, core_sets, start_set))
  parse_state_graph_add_nonterminal_extra_states(
    graph, queue, core_sets, builder,
  )
  let mut queue_index = 0
  while queue_index < queue.length() {
    let state_id = queue[queue_index]
    queue_index += 1
    let closed = builder.transitive_closure(graph.states[state_id].item_set)
    parse_state_graph_add_successors(
      graph, queue, core_sets, builder, state_id, closed,
    )
  }
  graph
}

///|
fn parse_state_graph_add_nonterminal_extra_states(
  graph : ParseStateGraph,
  queue : Array[Int],
  core_sets : Array[ParseItemSetCore],
  builder : ParseItemSetBuilder,
) -> Unit raise GenerateError {
  let extras : Array[ParseSuccessorSet] = []
  for extra in builder.grammar.syntax.extra_symbols {
    match extra {
      NonTerminal(variable_index) =>
        if variable_index >= 0 &&
          variable_index < builder.grammar.syntax.variables.length() {
          let variable = builder.grammar.syntax.variables[variable_index]
          for production_index in 0..<variable.productions.length() {
            let production = variable.productions[production_index]
            if production.steps.length() > 0 {
              let first_symbol = production.steps[0].symbol
              match first_symbol {
                NonTerminal(_) =>
                  raise GenerateError::ImproperNonTerminalExtra(
                    parse_state_graph_symbol_name(builder.grammar, first_symbol),
                  )
                Terminal(_) | External(_) => {
                  let successor_set = parse_successor_set_for_symbol(
                    extras, first_symbol,
                  )
                  let item = {
                    ..parse_item_for_grammar_production(
                      variable_index, production_index, production,
                    ),
                    step_index: 1,
                  }
                  let entry_index = successor_set.item_set.insert(item)
                  successor_set.item_set.entries[entry_index].lookaheads.end_of_nonterminal_extra
                  = true
                }
              }
            }
          }
        }
      Terminal(_) | External(_) => ()
    }
  }
  for extra_state in extras {
    let state_id = parse_state_graph_add_state(
      graph,
      queue,
      core_sets,
      extra_state.item_set,
    )
    graph.nonterminal_extra_transitions.push({
      symbol: extra_state.symbol,
      state_id,
    })
  }
}

///|
fn parse_state_graph_add_successors(
  graph : ParseStateGraph,
  queue : Array[Int],
  core_sets : Array[ParseItemSetCore],
  builder : ParseItemSetBuilder,
  state_id : Int,
  item_set : ParseItemSet,
) -> Unit {
  let terminal_successors : Array[ParseSuccessorSet] = []
  let nonterminal_successors : Array[ParseSuccessorSet] = []
  for entry in item_set.entries {
    match entry.item.symbol() {
      Some(symbol) => {
        let successor = entry.item.successor()
        let successors = match symbol {
          NonTerminal(_) => nonterminal_successors
          Terminal(_) | External(_) => terminal_successors
        }
        let successor_set = parse_successor_set_for_symbol(successors, symbol)
        let successor_index = successor_set.item_set.insert(successor)
        parse_token_set_insert_all(
          successor_set.item_set.entries[successor_index].lookaheads,
          entry.lookaheads,
        )
        parse_item_set_entry_max_reserved(
          successor_set.item_set.entries[successor_index],
          entry.following_reserved_word_set,
        )
      }
      None => ()
    }
  }
  for successor in terminal_successors {
    let next_state = parse_state_graph_add_state(
      graph,
      queue,
      core_sets,
      successor.item_set,
    )
    graph.states[state_id].terminal_transitions.push({
      symbol: successor.symbol,
      state_id: next_state,
    })
  }
  for successor in nonterminal_successors {
    let next_state = parse_state_graph_add_state(
      graph,
      queue,
      core_sets,
      successor.item_set,
    )
    graph.states[state_id].nonterminal_transitions.push({
      symbol: successor.symbol,
      state_id: next_state,
    })
  }
  ignore(builder)
}

///|
fn parse_successor_set_for_symbol(
  successors : Array[ParseSuccessorSet],
  symbol : InternalSymbol,
) -> ParseSuccessorSet {
  for i in 0..<successors.length() {
    let comparison = compare_internal_symbol(successors[i].symbol, symbol)
    if comparison == 0 {
      return successors[i]
    }
    if comparison > 0 {
      let successor = { symbol, item_set: parse_item_set_empty() }
      successors.insert(i, successor)
      return successor
    }
  }
  let successor = { symbol, item_set: parse_item_set_empty() }
  successors.push(successor)
  successor
}

///|
fn parse_state_graph_add_state(
  graph : ParseStateGraph,
  queue : Array[Int],
  core_sets : Array[ParseItemSetCore],
  item_set : ParseItemSet,
) -> Int {
  for state in graph.states {
    if parse_item_set_same(state.item_set, item_set) {
      return state.id
    }
  }
  let core = item_set.core()
  let core_id = parse_state_graph_core_id(core_sets, core)
  let state_id = graph.states.length()
  graph.states.push({
    id: state_id,
    item_set,
    core_id,
    terminal_transitions: [],
    nonterminal_transitions: [],
  })
  queue.push(state_id)
  state_id
}

///|
fn parse_state_graph_core_id(
  core_sets : Array[ParseItemSetCore],
  core : ParseItemSetCore,
) -> Int {
  for i in 0..<core_sets.length() {
    if parse_item_set_core_same(core_sets[i], core) {
      return i
    }
  }
  let id = core_sets.length()
  core_sets.push(core)
  id
}

///|
fn parse_item_set_same(left : ParseItemSet, right : ParseItemSet) -> Bool {
  if left.entries.length() != right.entries.length() {
    return false
  }
  for i in 0..<left.entries.length() {
    if !parse_item_set_entry_same(left.entries[i], right.entries[i]) {
      return false
    }
  }
  true
}

///|
fn parse_item_set_entry_same(
  left : ParseItemSetEntry,
  right : ParseItemSetEntry,
) -> Bool {
  parse_item_same(left.item, right.item) &&
  parse_token_set_same(left.lookaheads, right.lookaheads) &&
  left.following_reserved_word_set == right.following_reserved_word_set
}

///|
fn parse_item_set_core_same(
  left : ParseItemSetCore,
  right : ParseItemSetCore,
) -> Bool {
  if left.entries.length() != right.entries.length() {
    return false
  }
  for i in 0..<left.entries.length() {
    if !parse_item_same(left.entries[i], right.entries[i]) {
      return false
    }
  }
  true
}

///|
fn parse_state_graph_smoke_weight(
  builder : ParseItemSetBuilder,
) -> Int raise GenerateError {
  let graph = build_parse_state_graph(builder)
  let mut weight = graph.start_state
  for state in graph.states {
    weight += state.id + state.core_id
    weight += parse_item_set_weight(state.item_set)
    for transition in state.terminal_transitions {
      weight += internal_symbol_weight(transition.symbol) + transition.state_id
    }
    for transition in state.nonterminal_transitions {
      weight += internal_symbol_weight(transition.symbol) + transition.state_id
    }
  }
  for transition in graph.nonterminal_extra_transitions {
    weight += internal_symbol_weight(transition.symbol) + transition.state_id
  }
  weight
}

///|
fn parse_state_graph_symbol_name(
  grammar : PreparedGrammar,
  symbol : InternalSymbol,
) -> String {
  match symbol {
    Terminal(index) =>
      if index >= 0 && index < grammar.lexical.variables.length() {
        grammar.lexical.variables[index].name
      } else {
        "terminal\{index}"
      }
    External(index) =>
      if index >= 0 && index < grammar.syntax.external_tokens.length() {
        grammar.syntax.external_tokens[index].name
      } else {
        "external\{index}"
      }
    NonTerminal(index) =>
      if index >= 0 && index < grammar.syntax.variables.length() {
        grammar.syntax.variables[index].name
      } else {
        "nonterminal\{index}"
      }
  }
}
