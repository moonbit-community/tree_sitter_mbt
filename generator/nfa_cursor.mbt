///|
priv struct NfaCursor {
  nfa : Nfa
  state_ids : Array[Int]
}

///|
priv struct NfaRawTransition {
  characters : CharacterSet
  is_separator : Bool
  precedence : Int
  state : Int
}

///|
priv struct NfaTransition {
  characters : CharacterSet
  is_separator : Bool
  precedence : Int
  states : Array[Int]
}

///|
fn nfa_cursor_new(nfa : Nfa, states : Array[Int]) -> NfaCursor {
  { nfa, state_ids: nfa_canonical_state_ids(nfa, states) }
}

///|
fn nfa_cursor_transitions(cursor : NfaCursor) -> Array[NfaTransition] {
  nfa_group_raw_transitions(nfa_cursor_raw_transitions(cursor))
}

///|
fn nfa_cursor_transitions_and_any_separator(
  cursor : NfaCursor,
) -> (Array[NfaTransition], Bool) {
  let raw = nfa_cursor_raw_transitions(cursor)
  let mut any_separator = false
  for transition in raw {
    if transition.is_separator {
      any_separator = true
    }
  }
  (nfa_group_raw_transitions(raw), any_separator)
}

///|
fn nfa_cursor_raw_transitions(cursor : NfaCursor) -> Array[NfaRawTransition] {
  let result : Array[NfaRawTransition] = []
  for state_id in cursor.state_ids {
    if state_id >= 0 && state_id < cursor.nfa.states.length() {
      match cursor.nfa.states[state_id] {
        NfaAdvance(set, target, is_separator, precedence) =>
          result.push({
            characters: set,
            is_separator,
            precedence,
            state: target,
          })
        NfaSplit(_) | NfaAccept(_, _) => ()
      }
    }
  }
  result
}

///|
fn nfa_canonical_state_ids(nfa : Nfa, states : Array[Int]) -> Array[Int] {
  let closure = nfa_epsilon_closure(nfa, states)
  let result : Array[Int] = []
  for state_id in closure {
    if state_id >= 0 && state_id < nfa.states.length() {
      match nfa.states[state_id] {
        NfaSplit(_) => ()
        NfaAdvance(_, _, _, _) | NfaAccept(_, _) => result.push(state_id)
      }
    }
  }
  result.sort()
  result
}

///|
fn nfa_group_raw_transitions(
  raw_transitions : Array[NfaRawTransition],
) -> Array[NfaTransition] {
  let mut result : Array[NfaTransition] = []
  for raw in raw_transitions {
    result = nfa_add_raw_transition(result, raw)
  }
  result = nfa_merge_equivalent_transitions(result)
  result.sort_by(nfa_transition_compare)
  result
}

///|
fn nfa_add_raw_transition(
  transitions : Array[NfaTransition],
  raw : NfaRawTransition,
) -> Array[NfaTransition] {
  let result : Array[NfaTransition] = []
  let mut remaining = raw.characters
  for transition in transitions {
    let intersection = character_set_intersection(
      transition.characters,
      remaining,
    )
    if character_set_is_empty(intersection) {
      result.push(transition)
    } else {
      let existing_only = character_set_difference(
        transition.characters,
        intersection,
      )
      if !character_set_is_empty(existing_only) {
        result.push({ ..transition, characters: existing_only })
      }
      result.push({
        characters: intersection,
        is_separator: transition.is_separator && raw.is_separator,
        precedence: max_int(transition.precedence, raw.precedence),
        states: sorted_unique_with_int(transition.states, raw.state),
      })
      remaining = character_set_difference(remaining, intersection)
    }
  }
  if !character_set_is_empty(remaining) {
    result.push({
      characters: remaining,
      is_separator: raw.is_separator,
      precedence: raw.precedence,
      states: [raw.state],
    })
  }
  result
}

///|
fn nfa_merge_equivalent_transitions(
  transitions : Array[NfaTransition],
) -> Array[NfaTransition] {
  let result : Array[NfaTransition] = []
  for transition in transitions {
    merge_or_push_transition(result, transition)
  }
  result
}

///|
fn merge_or_push_transition(
  transitions : Array[NfaTransition],
  transition : NfaTransition,
) -> Unit {
  for i in 0..<transitions.length() {
    if nfa_transition_signature_matches(transitions[i], transition) {
      transitions[i] = {
        ..transitions[i],
        characters: character_set_union(
          transitions[i].characters,
          transition.characters,
        ),
      }
      return
    }
  }
  transitions.push(transition)
}

///|
fn nfa_transition_signature_matches(
  left : NfaTransition,
  right : NfaTransition,
) -> Bool {
  left.is_separator == right.is_separator &&
  left.precedence == right.precedence &&
  left.states == right.states
}

///|
fn nfa_transition_compare(left : NfaTransition, right : NfaTransition) -> Int {
  character_set_compare(left.characters, right.characters)
}

///|
fn sorted_unique_with_int(values : Array[Int], value : Int) -> Array[Int] {
  let result : Array[Int] = []
  for existing in values {
    result.push(existing)
  }
  if !contains_int(result, value) {
    result.push(value)
  }
  result.sort()
  result
}

///|
fn max_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn nfa_cursor_smoke_weight() -> Int {
  match parse_regex_to_nfa("a|b") {
    Ok(nfa) => {
      let cursor = nfa_cursor_new(nfa, [nfa.start])
      let direct_transitions = nfa_cursor_transitions(cursor)
      let (transitions, any_separator) = nfa_cursor_transitions_and_any_separator(
        cursor,
      )
      let mut weight = transitions.length() + direct_transitions.length()
      for transition in transitions {
        weight += character_set_weight(transition.characters)
        weight += transition.precedence
        for state in transition.states {
          weight += state
        }
        if transition.is_separator {
          weight += 1
        }
      }
      if any_separator {
        weight += 1
      }
      weight
    }
    Err(message) => message.length()
  }
}
