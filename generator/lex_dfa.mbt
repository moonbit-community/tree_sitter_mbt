///|
priv struct LexTokenSet {
  terminals : Array[Int]
  externals : Array[Int]
  eof : Bool
}

///|
priv struct LexExternalTokenSlot {
  external_index : Int
  symbol : InternalSymbol
  corresponding_internal_token : InternalSymbol?
}

///|
priv struct LexAccept {
  variable_index : Int
  symbol : InternalSymbol?
  precedence : Int
  implicit_precedence : Int
}

///|
priv struct LexDfaTransition {
  characters : CharacterSet
  target_state : Int
  is_separator : Bool
  precedence : Int
}

///|
priv struct LexDfaState {
  nfa_states : Array[Int]
  eof_valid : Bool
  accept : LexAccept?
  eof_action : Int?
  transitions : Array[LexDfaTransition]
}

///|
priv struct LexDfa {
  states : Array[LexDfaState]
  start_state : Int
  external_tokens : Array[LexExternalTokenSlot]
}

///|
priv struct LexDfaStateKey {
  nfa_states : Array[Int]
  eof_valid : Bool
}

///|
priv struct LexDfaQueueEntry {
  state_id : Int
  nfa_states : Array[Int]
  eof_valid : Bool
}

///|
priv struct LexDfaBuilder {
  nfa : Nfa
  lexical : ExpandedLexicalGrammar
  states : Array[LexDfaState]
  keys : Array[LexDfaStateKey]
  queue : Array[LexDfaQueueEntry]
  mut queue_index : Int
}

///|
fn lex_token_set(
  terminals : Array[Int],
  eof? : Bool = false,
  externals? : Array[Int] = [],
) -> LexTokenSet {
  let normalized : Array[Int] = []
  for terminal in terminals {
    push_unique_int(normalized, terminal)
  }
  normalized.sort()
  let normalized_externals : Array[Int] = []
  for external_token in externals {
    push_unique_int(normalized_externals, external_token)
  }
  normalized_externals.sort()
  { terminals: normalized, externals: normalized_externals, eof }
}

///|
fn build_lex_dfa(
  lexical : ExpandedLexicalGrammar,
  tokens : LexTokenSet,
) -> LexDfa {
  let nfa = lex_nfa_for_token_set(lexical, tokens)
  let builder : LexDfaBuilder = {
    nfa,
    lexical,
    states: [],
    keys: [],
    queue: [],
    queue_index: 0,
  }
  let start_state = lex_dfa_add_state(builder, [nfa.start], tokens.eof)
  while builder.queue_index < builder.queue.length() {
    let entry = builder.queue[builder.queue_index]
    builder.queue_index += 1
    lex_dfa_populate_state(builder, entry)
  }
  {
    states: builder.states,
    start_state,
    external_tokens: lex_external_token_slots(lexical, tokens),
  }
}

///|
fn lex_nfa_for_token_set(
  lexical : ExpandedLexicalGrammar,
  tokens : LexTokenSet,
) -> Nfa {
  let states : Array[NfaState] = [
    NfaState::NfaSplit([]),
    NfaState::NfaSplit([]),
  ]
  let starts : Array[Int] = []
  let after_separator_starts : Array[Int] = []
  for i in 0..<lexical.variables.length() {
    if lex_token_set_contains(tokens, i) {
      let variable = lexical.variables[i]
      let offset = states.length()
      append_offset_states(states, variable.nfa.states, offset)
      let start = variable.nfa.start + offset
      starts.push(start)
      if !variable.immediate {
        after_separator_starts.push(start)
      }
    }
  }
  if lex_should_include_separators(lexical, tokens) {
    for separator in lexical.separators {
      let offset = states.length()
      append_separator_nfa_states(states, separator, offset, 1)
      let start = separator.start + offset
      starts.push(start)
      after_separator_starts.push(start)
    }
  }
  states[0] = NfaState::NfaSplit(starts)
  states[1] = NfaState::NfaSplit(after_separator_starts)
  { states, start: 0 }
}

///|
fn lex_should_include_separators(
  lexical : ExpandedLexicalGrammar,
  tokens : LexTokenSet,
) -> Bool {
  if lexical.separators.length() == 0 {
    return false
  }
  if tokens.eof {
    return true
  }
  for terminal in tokens.terminals {
    if terminal >= 0 &&
      terminal < lexical.variables.length() &&
      !lexical.variables[terminal].immediate {
      return true
    }
  }
  false
}

///|
fn append_separator_nfa_states(
  target : Array[NfaState],
  separator : Nfa,
  offset : Int,
  after_separator_state : Int,
) -> Unit {
  for state in separator.states {
    match state {
      NfaAdvance(set, next, is_separator, precedence) =>
        target.push(
          NfaState::NfaAdvance(set, next + offset, is_separator, precedence),
        )
      NfaSplit(targets) =>
        target.push(NfaState::NfaSplit(offset_targets(targets, offset)))
      NfaAccept(_, _) =>
        target.push(NfaState::NfaSplit([after_separator_state]))
    }
  }
}

///|
fn lex_token_set_contains(tokens : LexTokenSet, terminal : Int) -> Bool {
  contains_int(tokens.terminals, terminal)
}

///|
fn lex_token_set_contains_external(
  tokens : LexTokenSet,
  external_token : Int,
) -> Bool {
  contains_int(tokens.externals, external_token)
}

///|
fn lex_external_token_slots(
  lexical : ExpandedLexicalGrammar,
  tokens : LexTokenSet,
) -> Array[LexExternalTokenSlot] {
  let slots : Array[LexExternalTokenSlot] = []
  for external_index in 0..<lexical.external_tokens.length() {
    let external_token = lexical.external_tokens[external_index]
    if lex_token_set_contains_external(tokens, external_index) ||
      lex_external_token_corresponds_to_terminal(external_token, tokens) {
      slots.push({
        external_index,
        symbol: external_token.symbol,
        corresponding_internal_token: external_token.corresponding_internal_token,
      })
    }
  }
  slots
}

///|
fn lex_external_token_corresponds_to_terminal(
  token : ExpandedExternalToken,
  tokens : LexTokenSet,
) -> Bool {
  match token.corresponding_internal_token {
    Some(InternalSymbol::Terminal(index)) =>
      lex_token_set_contains(tokens, index)
    Some(InternalSymbol::External(_))
    | Some(InternalSymbol::NonTerminal(_))
    | None => false
  }
}

///|
fn lex_dfa_add_state(
  builder : LexDfaBuilder,
  nfa_states : Array[Int],
  eof_valid : Bool,
) -> Int {
  let key = {
    nfa_states: nfa_canonical_state_ids(builder.nfa, nfa_states),
    eof_valid,
  }
  match lex_dfa_find_state(builder.keys, key) {
    Some(state_id) => state_id
    None => {
      let state_id = builder.states.length()
      builder.keys.push(key)
      builder.states.push({
        nfa_states: key.nfa_states,
        eof_valid,
        accept: None,
        eof_action: None,
        transitions: [],
      })
      builder.queue.push({ state_id, nfa_states: key.nfa_states, eof_valid })
      state_id
    }
  }
}

///|
fn lex_dfa_find_state(
  keys : Array[LexDfaStateKey],
  key : LexDfaStateKey,
) -> Int? {
  for i in 0..<keys.length() {
    if lex_dfa_state_key_matches(keys[i], key) {
      return Some(i)
    }
  }
  None
}

///|
fn lex_dfa_state_key_matches(
  left : LexDfaStateKey,
  right : LexDfaStateKey,
) -> Bool {
  left.eof_valid == right.eof_valid && left.nfa_states == right.nfa_states
}

///|
fn lex_dfa_populate_state(
  builder : LexDfaBuilder,
  entry : LexDfaQueueEntry,
) -> Unit {
  let cursor : NfaCursor = { nfa: builder.nfa, state_ids: entry.nfa_states }
  let completion = lex_dfa_completion(
    builder.nfa,
    builder.lexical,
    entry.nfa_states,
  )
  let (transitions, has_separator) = nfa_cursor_transitions_and_any_separator(
    cursor,
  )
  let eof_action = if entry.eof_valid {
    Some(lex_dfa_add_state(builder, [], false))
  } else {
    None
  }
  let dfa_transitions : Array[LexDfaTransition] = []
  for transition in transitions {
    if lex_dfa_should_keep_transition(
        builder.nfa,
        builder.lexical,
        transition,
        completion,
        has_separator,
      ) {
      let target_state = lex_dfa_add_state(
        builder,
        transition.states,
        entry.eof_valid && transition.is_separator,
      )
      dfa_transitions.push({
        characters: transition.characters,
        target_state,
        is_separator: transition.is_separator,
        precedence: transition.precedence,
      })
    }
  }
  let accept = match completion {
    Some(value) => Some(value)
    None =>
      if entry.nfa_states.length() == 0 {
        Some({
          variable_index: -1,
          symbol: None,
          precedence: 0,
          implicit_precedence: 0,
        })
      } else {
        None
      }
  }
  builder.states[entry.state_id] = {
    nfa_states: entry.nfa_states,
    eof_valid: entry.eof_valid,
    accept,
    eof_action,
    transitions: dfa_transitions,
  }
}

///|
fn lex_dfa_completion(
  nfa : Nfa,
  lexical : ExpandedLexicalGrammar,
  state_ids : Array[Int],
) -> LexAccept? {
  let mut result : LexAccept? = None
  for state_id in state_ids {
    if state_id >= 0 && state_id < nfa.states.length() {
      match nfa.states[state_id] {
        NfaAccept(variable_index, precedence) =>
          if variable_index >= 0 {
            let candidate = lex_accept_for_variable(
              lexical, variable_index, precedence,
            )
            match result {
              Some(previous) =>
                if !lex_prefer_accept(previous, candidate) {
                  result = Some(candidate)
                }
              None => result = Some(candidate)
            }
          }
        NfaAdvance(_, _, _, _) | NfaSplit(_) => ()
      }
    }
  }
  result
}

///|
fn lex_accept_for_variable(
  lexical : ExpandedLexicalGrammar,
  variable_index : Int,
  precedence : Int,
) -> LexAccept {
  let implicit_precedence = if variable_index >= 0 &&
    variable_index < lexical.variables.length() {
    lexical.variables[variable_index].implicit_precedence
  } else {
    0
  }
  {
    variable_index,
    symbol: Some(InternalSymbol::Terminal(variable_index)),
    precedence,
    implicit_precedence,
  }
}

///|
fn lex_prefer_accept(left : LexAccept, right : LexAccept) -> Bool {
  if left.precedence > right.precedence {
    true
  } else if left.precedence < right.precedence {
    false
  } else if left.implicit_precedence > right.implicit_precedence {
    true
  } else if left.implicit_precedence < right.implicit_precedence {
    false
  } else {
    left.variable_index < right.variable_index
  }
}

///|
fn lex_dfa_should_keep_transition(
  nfa : Nfa,
  lexical : ExpandedLexicalGrammar,
  transition : NfaTransition,
  completion : LexAccept?,
  has_separator : Bool,
) -> Bool {
  match completion {
    None => true
    Some(completed) => {
      if transition.precedence < completed.precedence {
        return false
      }
      if transition.precedence == completed.precedence {
        if transition.is_separator {
          return false
        }
        if has_separator &&
          !lex_transition_can_reach_variable(
            nfa,
            lexical,
            transition.states,
            completed.variable_index,
          ) {
          return false
        }
      }
      true
    }
  }
}

///|
fn lex_transition_can_reach_variable(
  nfa : Nfa,
  lexical : ExpandedLexicalGrammar,
  state_ids : Array[Int],
  variable_index : Int,
) -> Bool {
  let closure = nfa_epsilon_closure(nfa, state_ids)
  for state_id in closure {
    if state_id >= 0 && state_id < nfa.states.length() {
      match nfa.states[state_id] {
        NfaAccept(index, _) => if index == variable_index { return true }
        NfaAdvance(_, _, _, _) | NfaSplit(_) => ()
      }
    }
  }
  let _ = lexical
  false
}

///|
fn lex_dfa_smoke_weight(lexical : ExpandedLexicalGrammar) -> Int {
  let token_count = lexical.variables.length()
  let terminals : Array[Int] = []
  for i in 0..<token_count {
    terminals.push(i)
  }
  let dfa = build_lex_dfa(lexical, lex_token_set(terminals, eof=true))
  lex_dfa_weight(dfa)
}

///|
fn lex_dfa_weight(dfa : LexDfa) -> Int {
  let mut weight = dfa.start_state
  for external_token in dfa.external_tokens {
    weight += external_token.external_index
    weight += internal_symbol_weight(external_token.symbol)
    weight += optional_internal_symbol_weight(
      external_token.corresponding_internal_token,
    )
  }
  for state in dfa.states {
    weight += state.nfa_states.length()
    if state.eof_valid {
      weight += 1
    }
    match state.accept {
      Some(accept) => {
        weight += accept.variable_index
        weight += optional_internal_symbol_weight(accept.symbol)
        weight += accept.precedence
        weight += accept.implicit_precedence
      }
      None => ()
    }
    match state.eof_action {
      Some(target) => weight += target
      None => ()
    }
    for transition in state.transitions {
      weight += character_set_weight(transition.characters)
      weight += transition.target_state
      weight += transition.precedence
      if transition.is_separator {
        weight += 1
      }
    }
  }
  weight
}
