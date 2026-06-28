///|
test "parse items expose start step successor and previous step" {
  let start = parse_item_start()
  assert_true(start.is_augmented())
  assert_true(start.symbol() == Some(InternalSymbol::NonTerminal(0)))

  let production = parse_analysis_production([
    parse_analysis_step(InternalSymbol::Terminal(0)),
  ])
  let item = parse_item_for_production(2, production)
  assert_true(item.symbol() == Some(InternalSymbol::Terminal(0)))
  let successor = item.successor()
  assert_true(successor.is_done())
  guard successor.previous_step() is Some(previous) else {
    fail("successor should remember previous step")
  }
  assert_true(previous.symbol == InternalSymbol::Terminal(0))
}

///|
test "parse item set inserts entries in stable item order" {
  let later = parse_item_for_production(
    0,
    parse_analysis_production([parse_analysis_step(InternalSymbol::Terminal(1))]),
  )
  let earlier = parse_item_for_production(
    0,
    parse_analysis_production([parse_analysis_step(InternalSymbol::Terminal(0))]),
  )
  let set = parse_item_set_empty()
  let later_index = set.insert(later)
  let earlier_index = set.insert(earlier)
  let duplicate_index = set.insert(earlier)

  assert_eq(later_index, 0)
  assert_eq(earlier_index, 0)
  assert_eq(duplicate_index, 0)
  assert_eq(set.entries.length(), 2)
  assert_true(set.entries[0].item.symbol() == Some(InternalSymbol::Terminal(0)))
  assert_true(set.entries[1].item.symbol() == Some(InternalSymbol::Terminal(1)))
  assert_eq(set.core().entries.length(), 2)
}

///|
test "parse item set ordering mirrors upstream inherited-field quirk" {
  let first = {
    variable_index: 0,
    step_index: 1,
    production: parse_analysis_production([
      parse_analysis_step(InternalSymbol::Terminal(0)),
      parse_analysis_step(InternalSymbol::Terminal(2)),
    ]),
    source: None,
    has_preceding_inherited_fields: true,
  }
  let second = {
    variable_index: 0,
    step_index: 1,
    production: parse_analysis_production([
      parse_analysis_step(InternalSymbol::Terminal(1)),
      parse_analysis_step(InternalSymbol::Terminal(2)),
    ]),
    source: None,
    has_preceding_inherited_fields: true,
  }
  let set = parse_item_set_empty()
  let first_index = set.insert(first)
  let second_index = set.insert(second)

  assert_eq(first_index, 0)
  assert_eq(second_index, 0)
  assert_eq(set.entries.length(), 1)
  assert_true(!parse_item_same(first, second))
}

///|
fn parse_item_entry_for_variable(
  set : ParseItemSet,
  variable_index : Int,
) -> ParseItemSetEntry? {
  for entry in set.entries {
    if entry.item.variable_index == variable_index {
      return Some(entry)
    }
  }
  None
}

///|
test "parse item set builder closure expands start item with eof lookahead" {
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
  let symbol_sets = build_parse_symbol_sets(grammar)
  let builder = build_parse_item_set_builder(grammar, symbol_sets)
  let item_set = parse_item_set_empty()
  let start_index = item_set.insert(parse_item_start())
  item_set.entries[start_index].lookaheads.eof = true
  let closure = builder.transitive_closure(item_set)

  guard parse_item_entry_for_variable(closure, 0) is Some(entry) else {
    fail("closure should contain the start variable production")
  }
  assert_true(entry.lookaheads.eof)
}

///|
test "parse item set builder propagates first sets through prefix nonterminals" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
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
    terminal_count=3,
  )
  let symbol_sets = build_parse_symbol_sets(grammar)
  let builder = build_parse_item_set_builder(grammar, symbol_sets)
  let item_set = parse_item_set_empty()
  let start_index = item_set.insert(parse_item_start())
  item_set.entries[start_index].lookaheads.eof = true
  let closure = builder.transitive_closure(item_set)

  guard parse_item_entry_for_variable(closure, 1) is Some(entry) else {
    fail("closure should contain the prefix nonterminal production")
  }
  assert_true(
    parse_token_set_same(entry.lookaheads, parse_analysis_token_set([2], [])),
  )
}

///|
test "parse item set builder substitutes inline productions in closure" {
  let generated = parse_analysis_production([
    parse_analysis_step(InternalSymbol::Terminal(0)),
  ])
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::NonTerminal(1)),
        ]),
      ]),
      parse_analysis_variable(1, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
    ],
    terminal_count=1,
    inline_symbols=[InternalSymbol::NonTerminal(1)],
    inlines={
      productions: [generated],
      entries: [
        {
          source: InlinedProductionSource::GrammarProduction(
            variable_index=0,
            production_index=0,
          ),
          step_index: 0,
          production_indices: [0],
        },
      ],
    },
  )
  let symbol_sets = build_parse_symbol_sets(grammar)
  let builder = build_parse_item_set_builder(grammar, symbol_sets)
  let item_set = parse_item_set_empty()
  let start_index = item_set.insert(parse_item_start())
  item_set.entries[start_index].lookaheads.eof = true
  let closure = builder.transitive_closure(item_set)

  guard parse_item_entry_for_variable(closure, 0) is Some(entry) else {
    fail("closure should contain an item for the start variable")
  }
  assert_true(entry.item.symbol() == Some(InternalSymbol::Terminal(0)))
  assert_true(
    entry.item.source == Some(InlinedProductionSource::GeneratedProduction(0)),
  )
}

///|
test "parse item set builder propagates reserved set when word token follows" {
  let grammar = parse_analysis_prepared(
    [
      parse_analysis_variable(0, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::NonTerminal(1)),
          parse_analysis_step(InternalSymbol::NonTerminal(2)),
        ]),
      ]),
      parse_analysis_variable(1, [
        parse_analysis_production([
          parse_analysis_step(InternalSymbol::Terminal(0)),
        ]),
      ]),
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
        rules: [InternedRule::IRSymbol(InternalSymbol::Terminal(2))],
      },
    ],
  )
  let symbol_sets = build_parse_symbol_sets(grammar)
  let builder = build_parse_item_set_builder(grammar, symbol_sets)
  let item_set = parse_item_set_empty()
  let start_index = item_set.insert(parse_item_start())
  item_set.entries[start_index].lookaheads.eof = true
  let closure = builder.transitive_closure(item_set)

  guard parse_item_entry_for_variable(closure, 1) is Some(entry) else {
    fail("closure should contain the prefix nonterminal production")
  }
  assert_eq(entry.following_reserved_word_set, 1)
}
