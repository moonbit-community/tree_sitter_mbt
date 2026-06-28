///|
let large_character_range_count : Int = 8

///|
priv struct LargeCharacterSet {
  symbol : InternalSymbol?
  characters : CharacterSet
}

///|
priv struct LargeCharacterSetChoice {
  set_index : Int
  additions : CharacterSet
  removals : CharacterSet
}

///|
fn collect_large_character_sets(
  lexical : ExpandedLexicalGrammar,
) -> Array[LargeCharacterSet] {
  let result : Array[LargeCharacterSet] = []
  for variable_index in 0..<lexical.variables.length() {
    let dfa = build_lex_dfa(lexical, lex_token_set([variable_index]))
    for state in dfa.states {
      let mut main_characters = character_set_empty()
      for transition in state.transitions {
        if transition.is_separator {
          if character_set_range_count(transition.characters) >
            large_character_range_count {
            push_unique_large_character_set(result, None, transition.characters)
          }
        } else {
          main_characters = character_set_union(
            main_characters,
            transition.characters,
          )
        }
      }
      if character_set_range_count(main_characters) >
        large_character_range_count {
        push_unique_large_character_set(
          result,
          Some(InternalSymbol::Terminal(variable_index)),
          main_characters,
        )
      }
    }
  }
  result
}

///|
fn push_unique_large_character_set(
  sets : Array[LargeCharacterSet],
  symbol : InternalSymbol?,
  characters : CharacterSet,
) -> Unit {
  for existing in sets {
    if character_set_same(existing.characters, characters) {
      return
    }
  }
  sets.push({ symbol, characters })
}

///|
fn choose_large_character_set(
  sets : Array[LargeCharacterSet],
  simplified_characters : CharacterSet,
  ruled_out_characters : CharacterSet,
) -> LargeCharacterSetChoice? {
  if character_set_range_count(simplified_characters) <
    large_character_range_count {
    return None
  }
  let mut best : LargeCharacterSetChoice? = None
  for index in 0..<sets.length() {
    let candidate = sets[index]
    let intersection = character_set_intersection(
      simplified_characters,
      candidate.characters,
    )
    if character_set_is_empty(intersection) {
      continue
    }
    let additions = character_set_simplify_ignoring(
      character_set_difference(simplified_characters, intersection),
      ruled_out_characters,
    )
    let removals = character_set_simplify_ignoring(
      character_set_difference(candidate.characters, intersection),
      ruled_out_characters,
    )
    let total = character_set_range_count(additions) +
      character_set_range_count(removals)
    if total >= character_set_range_count(simplified_characters) {
      continue
    }
    match best {
      Some(current) => {
        let current_total = character_set_range_count(current.additions) +
          character_set_range_count(current.removals)
        if current_total < total {
          continue
        }
      }
      None => ()
    }
    best = Some({ set_index: index, additions, removals })
  }
  best
}

///|
fn character_set_simplify_ignoring(
  characters : CharacterSet,
  ruled_out : CharacterSet,
) -> CharacterSet {
  character_set_difference(characters, ruled_out)
}

///|
fn large_character_sets_weight(sets : Array[LargeCharacterSet]) -> Int {
  let mut weight = sets.length()
  for set in sets {
    match set.symbol {
      Some(symbol) => weight += internal_symbol_weight(symbol)
      None => ()
    }
    weight += character_set_weight(set.characters)
  }
  weight
}

///|
fn lex_large_character_sets_smoke_weight(
  lexical : ExpandedLexicalGrammar,
) -> Int {
  let sets = collect_large_character_sets(lexical)
  let mut weight = large_character_sets_weight(sets)
  match
    choose_large_character_set(sets, character_set_any(), character_set_empty()) {
    Some(choice) => {
      weight += choice.set_index
      weight += character_set_weight(choice.additions)
      weight += character_set_weight(choice.removals)
    }
    None => ()
  }
  weight
}
