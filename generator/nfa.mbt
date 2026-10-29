///|
priv enum NfaState {
  NfaAdvance(CharacterSet, Int32, Bool, Int32)
  NfaSplit(Array[Int32])
  NfaAccept(Int32, Int32)
}

///|
priv struct Nfa {
  states : Array[NfaState]
  start : Int32
}

///|
priv struct NfaFragment {
  states : Array[NfaState]
  start : Int32
  accepts : Array[Int32]
}

///|
fn parse_regex_to_nfa(pattern : String) -> Result[Nfa, String] {
  match parse_regex(pattern) {
    Ok(ast) => Ok(regex_ast_to_nfa(ast))
    Err(message) => Err(message)
  }
}

///|
fn regex_ast_to_nfa(ast : RegexAst) -> Nfa {
  let fragment = regex_ast_to_fragment(ast)
  { states: fragment.states, start: fragment.start, }
}

///|
fn regex_ast_to_fragment(ast : RegexAst) -> NfaFragment {
  match ast {
    RegexEmpty => empty_fragment()
    RegexLiteral(value) => advance_fragment(character_set_range(value, value))
    RegexClass(set) => advance_fragment(set)
    RegexSeq(items) => sequence_fragment(items)
    RegexChoice(items) => choice_fragment(items)
    RegexRepeat(content~, min~, max~) => repeat_fragment(content, min, max)
  }
}

///|
fn empty_fragment() -> NfaFragment {
  { states: [NfaState::NfaAccept(-1, 0)], start: 0, accepts: [0], }
}

///|
fn advance_fragment(set : CharacterSet) -> NfaFragment {
  {
    states: [NfaState::NfaAdvance(set, 1, false, 0), NfaState::NfaAccept(-1, 0)],
    start: 0,
    accepts: [1],
  }
}

///|
fn sequence_fragment(items : Array[RegexAst]) -> NfaFragment {
  if items.length() == 0 {
    return empty_fragment()
  }
  let mut result = regex_ast_to_fragment(items[0])
  for i in 1..<items.length() {
    result = concatenate_fragments(result, regex_ast_to_fragment(items[i]))
  }
  result
}

///|
fn choice_fragment(items : Array[RegexAst]) -> NfaFragment {
  if items.length() == 0 {
    return empty_fragment()
  }
  let states : Array[NfaState] = []
  let starts : Array[Int32] = []
  let accepts : Array[Int32] = []
  states.push(NfaState::NfaSplit(starts))
  for item in items {
    let fragment = regex_ast_to_fragment(item)
    let offset = states.length()
    starts.push(fragment.start + offset)
    append_offset_states(states, fragment.states, offset)
    for accept in fragment.accepts {
      accepts.push(accept + offset)
    }
  }
  { states, start: 0, accepts, }
}

///|
fn repeat_fragment(
  content : RegexAst,
  min : Int32,
  max : Int32?,
) -> NfaFragment {
  let mut result = exact_repeat_fragment(content, min)
  match max {
    None => concatenate_fragments(result, star_fragment(content))
    Some(value) => {
      let optional_count = value - min
      for _ in 0..<optional_count {
        result = concatenate_fragments(result, optional_fragment(content))
      }
      result
    }
  }
}

///|
fn exact_repeat_fragment(content : RegexAst, count : Int32) -> NfaFragment {
  if count <= 0 {
    return empty_fragment()
  }
  let mut result = regex_ast_to_fragment(content)
  for _ in 1..<count {
    result = concatenate_fragments(result, regex_ast_to_fragment(content))
  }
  result
}

///|
fn optional_fragment(content : RegexAst) -> NfaFragment {
  choice_fragment([content, RegexAst::RegexEmpty])
}

///|
fn star_fragment(content : RegexAst) -> NfaFragment {
  let body = regex_ast_to_fragment(content)
  let states : Array[NfaState] = []
  let body_offset = 1
  let accept_index = body.states.length() + 1
  states.push(NfaState::NfaSplit([body.start + body_offset, accept_index]))
  append_offset_states(
    states,
    replace_accepts(
      body.states,
      body.accepts,
      NfaState::NfaSplit([body.start, accept_index - body_offset]),
    ),
    body_offset,
  )
  states.push(NfaState::NfaAccept(-1, 0))
  { states, start: 0, accepts: [accept_index], }
}

///|
fn concatenate_fragments(
  left : NfaFragment,
  right : NfaFragment,
) -> NfaFragment {
  let right_offset = left.states.length()
  let states = replace_accepts(
    left.states,
    left.accepts,
    NfaState::NfaSplit([right.start + right_offset]),
  )
  append_offset_states(states, right.states, right_offset)
  let accepts : Array[Int32] = []
  for accept in right.accepts {
    accepts.push(accept + right_offset)
  }
  { states, start: left.start, accepts, }
}

///|
fn replace_accepts(
  states : Array[NfaState],
  accepts : Array[Int32],
  replacement : NfaState,
) -> Array[NfaState] {
  let result : Array[NfaState] = []
  for i in 0..<states.length() {
    if contains_int(accepts, i) {
      result.push(replacement)
    } else {
      result.push(states[i])
    }
  }
  result
}

///|
fn append_offset_states(
  target : Array[NfaState],
  states : Array[NfaState],
  offset : Int32,
) -> Unit {
  for state in states {
    target.push(offset_state(state, offset))
  }
}

///|
fn offset_state(state : NfaState, offset : Int32) -> NfaState {
  match state {
    NfaAdvance(set, target, is_separator, precedence) =>
      NfaState::NfaAdvance(set, target + offset, is_separator, precedence)
    NfaSplit(targets) => NfaState::NfaSplit(offset_targets(targets, offset))
    NfaAccept(variable_index, precedence) =>
      NfaState::NfaAccept(variable_index, precedence)
  }
}

///|
fn offset_targets(targets : Array[Int32], offset : Int32) -> Array[Int32] {
  let result : Array[Int32] = []
  for target in targets {
    result.push(target + offset)
  }
  result
}

///|
fn nfa_matches(nfa : Nfa, input : String) -> Bool {
  let mut states = nfa_epsilon_closure(nfa, [nfa.start])
  for char in input.to_array() {
    let next : Array[Int32] = []
    for state_id in states {
      if state_id >= 0 && state_id < nfa.states.length() {
        match nfa.states[state_id] {
          NfaAdvance(set, target, _, _) =>
            if character_set_contains(set, char.to_uint()) {
              push_unique_int(next, target)
            }
          NfaSplit(_) | NfaAccept(_, _) => ()
        }
      }
    }
    states = nfa_epsilon_closure(nfa, next)
  }
  nfa_states_include_accept(nfa, states)
}

///|
fn nfa_epsilon_closure(nfa : Nfa, starts : Array[Int32]) -> Array[Int32] {
  let result : Array[Int32] = []
  let work : Array[Int32] = []
  for start in starts {
    push_unique_int(work, start)
  }
  let mut index = 0
  while index < work.length() {
    let state_id = work[index]
    index += 1
    if state_id >= 0 && state_id < nfa.states.length() {
      push_unique_int(result, state_id)
      match nfa.states[state_id] {
        NfaSplit(targets) =>
          for target in targets {
            if !contains_int(result, target) {
              push_unique_int(work, target)
            }
          }
        NfaAdvance(_, _, _, _) | NfaAccept(_, _) => ()
      }
    }
  }
  result
}

///|
fn nfa_states_include_accept(nfa : Nfa, states : Array[Int32]) -> Bool {
  for state_id in states {
    if state_id >= 0 && state_id < nfa.states.length() {
      if nfa.states[state_id] is NfaState::NfaAccept(_, _) {
        return true
      }
    }
  }
  false
}

///|
fn nfa_smoke_weight() -> Int32 {
  match parse_regex_to_nfa("a{1,2}|\\d+") {
    Ok(nfa) => {
      let accepted = if nfa_matches(nfa, "42") { 1 } else { 0 }
      nfa.states.length() + nfa.start + accepted
    }
    Err(message) => message.length()
  }
}

///|
fn nfa_with_metadata(
  nfa : Nfa,
  variable_index : Int32,
  accept_precedence : Int32,
  is_separator : Bool,
  transition_precedence : Int32,
) -> Nfa {
  let states : Array[NfaState] = []
  for state in nfa.states {
    states.push(
      nfa_state_with_metadata(
        state, variable_index, accept_precedence, is_separator, transition_precedence,
      ),
    )
  }
  { states, start: nfa.start, }
}

///|
fn nfa_state_with_metadata(
  state : NfaState,
  variable_index : Int32,
  accept_precedence : Int32,
  is_separator : Bool,
  transition_precedence : Int32,
) -> NfaState {
  match state {
    NfaAdvance(set, target, _, _) =>
      NfaState::NfaAdvance(set, target, is_separator, transition_precedence)
    NfaSplit(targets) => NfaState::NfaSplit(targets)
    NfaAccept(_, _) => NfaState::NfaAccept(variable_index, accept_precedence)
  }
}

///|
fn contains_int(values : Array[Int32], value : Int32) -> Bool {
  for existing in values {
    if existing == value {
      return true
    }
  }
  false
}

///|
fn push_unique_int(values : Array[Int32], value : Int32) -> Unit {
  if !contains_int(values, value) {
    values.push(value)
  }
}
