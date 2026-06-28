///|
priv struct ParseTokenSet {
  terminals : Array[Int]
  externals : Array[Int]
  mut eof : Bool
  mut end_of_nonterminal_extra : Bool
}

///|
priv struct ParseSymbolSets {
  first_sets : Array[ParseTokenSet]
  last_sets : Array[ParseTokenSet]
  reserved_first_sets : Array[Int]
}

///|
fn build_parse_symbol_sets(grammar : PreparedGrammar) -> ParseSymbolSets {
  let first_sets : Array[ParseTokenSet] = []
  let last_sets : Array[ParseTokenSet] = []
  let reserved_first_sets : Array[Int] = []
  for _ in grammar.syntax.variables {
    first_sets.push(parse_token_set_empty())
    last_sets.push(parse_token_set_empty())
    reserved_first_sets.push(0)
  }
  let result = { first_sets, last_sets, reserved_first_sets }
  for i in 0..<grammar.syntax.variables.length() {
    fill_first_set(result, grammar.syntax, i)
    fill_last_set(result, grammar.syntax, i)
  }
  result
}

///|
fn build_following_token_sets(
  grammar : PreparedGrammar,
  symbol_sets : ParseSymbolSets,
) -> Array[ParseTokenSet] {
  let result : Array[ParseTokenSet] = []
  for _ in grammar.lexical.variables {
    result.push(parse_token_set_empty())
  }
  let all_tokens = parse_token_set_empty()
  for i in 0..<result.length() {
    parse_token_set_insert_symbol(all_tokens, InternalSymbol::Terminal(i))
  }
  for variable in grammar.syntax.variables {
    for production in variable.productions {
      add_following_tokens_for_production(
        result, grammar, symbol_sets, production,
      )
    }
  }
  for production in grammar.inlines.productions {
    add_following_tokens_for_production(
      result, grammar, symbol_sets, production,
    )
  }
  for extra in grammar.syntax.extra_symbols {
    match extra {
      Terminal(index) =>
        if index >= 0 && index < result.length() {
          for entry in result {
            parse_token_set_insert_symbol(entry, extra)
          }
          result[index] = parse_token_set_clone(all_tokens)
        }
      External(_) | NonTerminal(_) => ()
    }
  }
  result
}

///|
fn add_following_tokens_for_production(
  result : Array[ParseTokenSet],
  grammar : PreparedGrammar,
  symbol_sets : ParseSymbolSets,
  production : FlattenedProduction,
) -> Unit {
  for i in 1..<production.steps.length() {
    let left_tokens = parse_symbol_last_set(
      symbol_sets,
      production.steps[i - 1].symbol,
    )
    let right_tokens = parse_symbol_first_set(
      symbol_sets,
      production.steps[i].symbol,
    )
    let right_reserved_tokens = parse_reserved_token_set(
      grammar,
      parse_symbol_reserved_first_set(symbol_sets, production.steps[i].symbol),
    )
    for left_token in left_tokens.terminals {
      if left_token >= 0 && left_token < result.length() {
        parse_token_set_insert_all_terminals(result[left_token], right_tokens)
        parse_token_set_insert_all_terminals(
          result[left_token],
          right_reserved_tokens,
        )
      }
    }
  }
}

///|
fn parse_reserved_token_set(
  grammar : PreparedGrammar,
  reserved_set_id : Int,
) -> ParseTokenSet {
  let result = parse_token_set_empty()
  if reserved_set_id >= 0 &&
    reserved_set_id < grammar.syntax.reserved_sets.length() {
    for rule in grammar.syntax.reserved_sets[reserved_set_id].rules {
      parse_token_set_insert_rule_symbols(result, rule)
    }
  }
  result
}

///|
fn parse_token_set_insert_rule_symbols(
  set : ParseTokenSet,
  rule : InternedRule,
) -> Unit {
  match rule {
    IRAlias(content~, ..)
    | IRRepeat(content)
    | IRRepeat1(content)
    | IRField(content~, ..)
    | IRPrec(content~, ..)
    | IRPrecLeft(content~, ..)
    | IRPrecRight(content~, ..)
    | IRPrecDynamic(content~, ..)
    | IRToken(content)
    | IRImmediateToken(content)
    | IRReserved(content~, ..) =>
      parse_token_set_insert_rule_symbols(set, content)
    IRSymbol(symbol) => parse_token_set_insert_symbol(set, symbol)
    IRSeq(members) | IRChoice(members) =>
      for item_rule in members {
        parse_token_set_insert_rule_symbols(set, item_rule)
      }
    IRBlank | IRString(_) | IRPattern(_) => ()
  }
}

///|
fn fill_first_set(
  sets : ParseSymbolSets,
  syntax : FlattenedSyntaxGrammar,
  variable_index : Int,
) -> Unit {
  let target = sets.first_sets[variable_index]
  let mut reserved_id = sets.reserved_first_sets[variable_index]
  let work : Array[InternalSymbol] = [
    InternalSymbol::NonTerminal(variable_index),
  ]
  let processed : Array[InternalSymbol] = []
  while work.length() > 0 {
    let symbol = work[work.length() - 1]
    let _ = work.pop()
    match symbol {
      NonTerminal(index) =>
        if index >= 0 && index < syntax.variables.length() {
          for production in syntax.variables[index].productions {
            if production.steps.length() > 0 {
              let first_step = production.steps[0]
              match first_step.symbol {
                Terminal(_) | External(_) =>
                  parse_token_set_insert_symbol(target, first_step.symbol)
                NonTerminal(_) =>
                  if !contains_internal_symbol(processed, first_step.symbol) {
                    processed.push(first_step.symbol)
                    work.push(first_step.symbol)
                  }
              }
              if first_step.reserved_word_set_id > reserved_id {
                reserved_id = first_step.reserved_word_set_id
              }
            }
          }
        }
      Terminal(_) | External(_) => parse_token_set_insert_symbol(target, symbol)
    }
  }
  sets.reserved_first_sets[variable_index] = reserved_id
}

///|
fn fill_last_set(
  sets : ParseSymbolSets,
  syntax : FlattenedSyntaxGrammar,
  variable_index : Int,
) -> Unit {
  let target = sets.last_sets[variable_index]
  let work : Array[InternalSymbol] = [
    InternalSymbol::NonTerminal(variable_index),
  ]
  let processed : Array[InternalSymbol] = []
  while work.length() > 0 {
    let symbol = work[work.length() - 1]
    let _ = work.pop()
    match symbol {
      NonTerminal(index) =>
        if index >= 0 && index < syntax.variables.length() {
          for production in syntax.variables[index].productions {
            if production.steps.length() > 0 {
              let last_step = production.steps[production.steps.length() - 1]
              match last_step.symbol {
                Terminal(_) | External(_) =>
                  parse_token_set_insert_symbol(target, last_step.symbol)
                NonTerminal(_) =>
                  if !contains_internal_symbol(processed, last_step.symbol) {
                    processed.push(last_step.symbol)
                    work.push(last_step.symbol)
                  }
              }
            }
          }
        }
      Terminal(_) | External(_) => parse_token_set_insert_symbol(target, symbol)
    }
  }
}

///|
fn parse_symbol_first_set(
  sets : ParseSymbolSets,
  symbol : InternalSymbol,
) -> ParseTokenSet {
  match symbol {
    Terminal(_) | External(_) => parse_token_set_single(symbol)
    NonTerminal(index) =>
      if index >= 0 && index < sets.first_sets.length() {
        parse_token_set_clone(sets.first_sets[index])
      } else {
        parse_token_set_empty()
      }
  }
}

///|
fn parse_symbol_last_set(
  sets : ParseSymbolSets,
  symbol : InternalSymbol,
) -> ParseTokenSet {
  match symbol {
    Terminal(_) | External(_) => parse_token_set_single(symbol)
    NonTerminal(index) =>
      if index >= 0 && index < sets.last_sets.length() {
        parse_token_set_clone(sets.last_sets[index])
      } else {
        parse_token_set_empty()
      }
  }
}

///|
fn parse_symbol_reserved_first_set(
  sets : ParseSymbolSets,
  symbol : InternalSymbol,
) -> Int {
  match symbol {
    NonTerminal(index) =>
      if index >= 0 && index < sets.reserved_first_sets.length() {
        sets.reserved_first_sets[index]
      } else {
        0
      }
    Terminal(_) | External(_) => 0
  }
}

///|
fn parse_token_set_empty() -> ParseTokenSet {
  { terminals: [], externals: [], eof: false, end_of_nonterminal_extra: false }
}

///|
fn parse_token_set_single(symbol : InternalSymbol) -> ParseTokenSet {
  let set = parse_token_set_empty()
  parse_token_set_insert_symbol(set, symbol)
  set
}

///|
fn parse_token_set_clone(set : ParseTokenSet) -> ParseTokenSet {
  {
    terminals: set.terminals.copy(),
    externals: set.externals.copy(),
    eof: set.eof,
    end_of_nonterminal_extra: set.end_of_nonterminal_extra,
  }
}

///|
fn parse_token_set_insert_symbol(
  set : ParseTokenSet,
  symbol : InternalSymbol,
) -> Unit {
  match symbol {
    Terminal(index) => parse_token_set_insert_index(set.terminals, index)
    External(index) => parse_token_set_insert_index(set.externals, index)
    NonTerminal(_) => ()
  }
}

///|
fn parse_token_set_insert_all(
  target : ParseTokenSet,
  source : ParseTokenSet,
) -> Unit {
  for terminal in source.terminals {
    parse_token_set_insert_index(target.terminals, terminal)
  }
  for external_token in source.externals {
    parse_token_set_insert_index(target.externals, external_token)
  }
  if source.eof {
    target.eof = true
  }
  if source.end_of_nonterminal_extra {
    target.end_of_nonterminal_extra = true
  }
}

///|
fn parse_token_set_insert_all_terminals(
  target : ParseTokenSet,
  source : ParseTokenSet,
) -> Unit {
  for terminal in source.terminals {
    parse_token_set_insert_index(target.terminals, terminal)
  }
}

///|
fn parse_token_set_insert_index(values : Array[Int], value : Int) -> Unit {
  if !contains_int(values, value) {
    values.push(value)
    values.sort()
  }
}

///|
fn parse_token_set_contains_symbol(
  set : ParseTokenSet,
  symbol : InternalSymbol,
) -> Bool {
  match symbol {
    Terminal(index) => contains_int(set.terminals, index)
    External(index) => contains_int(set.externals, index)
    NonTerminal(_) => false
  }
}

///|
fn parse_token_set_same(left : ParseTokenSet, right : ParseTokenSet) -> Bool {
  left.terminals == right.terminals &&
  left.externals == right.externals &&
  left.eof == right.eof &&
  left.end_of_nonterminal_extra == right.end_of_nonterminal_extra
}

///|
fn parse_symbol_sets_weight(sets : ParseSymbolSets) -> Int {
  let mut weight = 0
  for i in 0..<sets.first_sets.length() {
    let first_set = parse_symbol_first_set(sets, InternalSymbol::NonTerminal(i))
    let first_clone = parse_token_set_empty()
    parse_token_set_insert_all(first_clone, first_set)
    weight += parse_token_set_weight(first_clone)
    if parse_token_set_same(first_clone, first_set) {
      weight += 1
    }
    if first_set.terminals.length() > 0 &&
      parse_token_set_contains_symbol(
        first_set,
        InternalSymbol::Terminal(first_set.terminals[0]),
      ) {
      weight += 1
    }
    let last_set = parse_symbol_last_set(sets, InternalSymbol::NonTerminal(i))
    weight += parse_token_set_weight(last_set)
    weight += parse_symbol_reserved_first_set(
      sets,
      InternalSymbol::NonTerminal(i),
    )
  }
  weight
}

///|
fn following_token_sets_weight(sets : Array[ParseTokenSet]) -> Int {
  let mut weight = 0
  for set in sets {
    weight += parse_token_set_weight(set)
  }
  weight
}

///|
fn parse_token_set_weight(set : ParseTokenSet) -> Int {
  let mut weight = 0
  for terminal in set.terminals {
    weight += terminal + 1
  }
  for external_token in set.externals {
    weight += external_token + 101
  }
  if set.eof {
    weight += 1009
  }
  if set.end_of_nonterminal_extra {
    weight += 2003
  }
  weight
}
