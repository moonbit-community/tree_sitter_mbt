///|
priv struct ParseItem {
  variable_index : Int
  step_index : Int
  production : FlattenedProduction
  source : InlinedProductionSource?
  has_preceding_inherited_fields : Bool
}

///|
priv struct ParseItemSetEntry {
  item : ParseItem
  lookaheads : ParseTokenSet
  mut following_reserved_word_set : Int
}

///|
priv struct ParseItemSet {
  entries : Array[ParseItemSetEntry]
}

///|
priv struct ParseItemSetCore {
  entries : Array[ParseItem]
}

///|
priv struct ParseFollowSetInfo {
  lookaheads : ParseTokenSet
  mut reserved_lookaheads : Int
  mut propagates_lookaheads : Bool
}

///|
priv struct ParseClosureAddition {
  item : ParseItem
  info : ParseFollowSetInfo
}

///|
priv struct ParseItemSetBuilder {
  grammar : PreparedGrammar
  symbol_sets : ParseSymbolSets
  transitive_closure_additions : Array[Array[ParseClosureAddition]]
}

///|
priv struct ParseFollowInfoEntry {
  variable_index : Int
  info : ParseFollowSetInfo
}

///|
priv struct ParseFollowStackEntry {
  variable_index : Int
  lookaheads : ParseTokenSet
  reserved_word_set_id : Int
  propagates_lookaheads : Bool
}

///|
fn build_parse_item_set_builder(
  grammar : PreparedGrammar,
  symbol_sets : ParseSymbolSets,
) -> ParseItemSetBuilder {
  let transitive_closure_additions : Array[Array[ParseClosureAddition]] = []
  for _ in grammar.syntax.variables {
    transitive_closure_additions.push([])
  }
  let builder = { grammar, symbol_sets, transitive_closure_additions }
  for variable_index in 0..<grammar.syntax.variables.length() {
    build_transitive_closure_additions(builder, variable_index)
  }
  builder
}

///|
fn build_transitive_closure_additions(
  builder : ParseItemSetBuilder,
  variable_index : Int,
) -> Unit {
  let follow_infos = parse_follow_infos_for_non_terminal(
    builder.grammar,
    builder.symbol_sets,
    variable_index,
  )
  for entry in follow_infos {
    let non_terminal = InternalSymbol::NonTerminal(entry.variable_index)
    if contains_internal_symbol(
        builder.grammar.syntax.inline_symbols,
        non_terminal,
      ) {
      continue
    }
    if entry.variable_index < 0 ||
      entry.variable_index >= builder.grammar.syntax.variables.length() {
      continue
    }
    let variable = builder.grammar.syntax.variables[entry.variable_index]
    for production_index in 0..<variable.productions.length() {
      let item = parse_item_for_grammar_production(
        entry.variable_index,
        production_index,
        variable.productions[production_index],
      )
      let inlined = inlined_productions_for_item(builder.grammar.inlines, item)
      if inlined.length() > 0 {
        for generated in inlined {
          push_unique_closure_addition(
            builder.transitive_closure_additions[variable_index],
            {
              item: parse_item_substitute_generated(
                item,
                generated.0,
                generated.1,
              ),
              info: parse_follow_set_info_clone(entry.info),
            },
          )
        }
      } else {
        push_unique_closure_addition(
          builder.transitive_closure_additions[variable_index],
          { item, info: parse_follow_set_info_clone(entry.info) },
        )
      }
    }
  }
}

///|
fn parse_follow_infos_for_non_terminal(
  grammar : PreparedGrammar,
  symbol_sets : ParseSymbolSets,
  variable_index : Int,
) -> Array[ParseFollowInfoEntry] {
  let infos : Array[ParseFollowInfoEntry] = []
  let stack : Array[ParseFollowStackEntry] = [
    {
      variable_index,
      lookaheads: parse_token_set_empty(),
      reserved_word_set_id: 0,
      propagates_lookaheads: true,
    },
  ]
  while stack.length() > 0 {
    let current = stack[stack.length() - 1]
    let _ = stack.pop()
    if current.variable_index < 0 ||
      current.variable_index >= grammar.syntax.variables.length() {
      continue
    }
    let info = parse_follow_info_entry(infos, current.variable_index)
    let did_add = parse_follow_set_info_insert(
      info,
      current.lookaheads,
      current.reserved_word_set_id,
      current.propagates_lookaheads,
    )
    if !did_add {
      continue
    }
    for
      production in grammar.syntax.variables[current.variable_index].productions {
      if production.steps.length() > 0 {
        match production.steps[0].symbol {
          NonTerminal(index) =>
            if production.steps.length() > 1 {
              let next_step = production.steps[1]
              stack.push({
                variable_index: index,
                lookaheads: parse_symbol_first_set(
                  symbol_sets,
                  next_step.symbol,
                ),
                reserved_word_set_id: parse_symbol_reserved_first_set(
                  symbol_sets,
                  next_step.symbol,
                ),
                propagates_lookaheads: false,
              })
            } else {
              stack.push({
                variable_index: index,
                lookaheads: parse_token_set_clone(current.lookaheads),
                reserved_word_set_id: current.reserved_word_set_id,
                propagates_lookaheads: current.propagates_lookaheads,
              })
            }
          Terminal(_) | External(_) => ()
        }
      }
    }
  }
  infos
}

///|
fn parse_follow_info_entry(
  infos : Array[ParseFollowInfoEntry],
  variable_index : Int,
) -> ParseFollowSetInfo {
  for entry in infos {
    if entry.variable_index == variable_index {
      return entry.info
    }
  }
  let info = parse_follow_set_info_empty()
  infos.push({ variable_index, info })
  info
}

///|
fn parse_follow_set_info_empty() -> ParseFollowSetInfo {
  {
    lookaheads: parse_token_set_empty(),
    reserved_lookaheads: 0,
    propagates_lookaheads: false,
  }
}

///|
fn parse_follow_set_info_clone(info : ParseFollowSetInfo) -> ParseFollowSetInfo {
  {
    lookaheads: parse_token_set_clone(info.lookaheads),
    reserved_lookaheads: info.reserved_lookaheads,
    propagates_lookaheads: info.propagates_lookaheads,
  }
}

///|
fn parse_follow_set_info_same(
  left : ParseFollowSetInfo,
  right : ParseFollowSetInfo,
) -> Bool {
  parse_token_set_same(left.lookaheads, right.lookaheads) &&
  left.reserved_lookaheads == right.reserved_lookaheads &&
  left.propagates_lookaheads == right.propagates_lookaheads
}

///|
fn parse_follow_set_info_insert(
  info : ParseFollowSetInfo,
  lookaheads : ParseTokenSet,
  reserved_word_set_id : Int,
  propagates_lookaheads : Bool,
) -> Bool {
  let before = parse_token_set_clone(info.lookaheads)
  parse_token_set_insert_all(info.lookaheads, lookaheads)
  let mut did_add = !parse_token_set_same(before, info.lookaheads)
  if reserved_word_set_id > info.reserved_lookaheads {
    info.reserved_lookaheads = reserved_word_set_id
    did_add = true
  }
  if propagates_lookaheads && !info.propagates_lookaheads {
    info.propagates_lookaheads = true
    did_add = true
  }
  did_add
}

///|
fn parse_item_start() -> ParseItem {
  {
    variable_index: -1,
    step_index: 0,
    production: parse_item_start_production(),
    source: None,
    has_preceding_inherited_fields: false,
  }
}

///|
fn parse_item_start_production() -> FlattenedProduction {
  {
    steps: [
      {
        symbol: InternalSymbol::NonTerminal(0),
        alias_name: None,
        alias_named: false,
        field_name: None,
        precedence: None,
        associativity: Associativity::NoAssociativity,
        reserved_word_set_id: 0,
      },
    ],
    dynamic_precedence: 0,
  }
}

///|
fn parse_item_for_production(
  variable_index : Int,
  production : FlattenedProduction,
) -> ParseItem {
  {
    variable_index,
    step_index: 0,
    production,
    source: None,
    has_preceding_inherited_fields: false,
  }
}

///|
fn parse_item_for_grammar_production(
  variable_index : Int,
  production_index : Int,
  production : FlattenedProduction,
) -> ParseItem {
  {
    variable_index,
    step_index: 0,
    production,
    source: Some(
      InlinedProductionSource::GrammarProduction(
        variable_index~,
        production_index~,
      ),
    ),
    has_preceding_inherited_fields: false,
  }
}

///|
fn parse_item_for_generated_production(
  generated_index : Int,
  variable_index : Int,
  production : FlattenedProduction,
) -> ParseItem {
  {
    variable_index,
    step_index: 0,
    production,
    source: Some(InlinedProductionSource::GeneratedProduction(generated_index)),
    has_preceding_inherited_fields: false,
  }
}

///|
fn ParseItem::step(self : ParseItem) -> ProductionStep? {
  self.production.steps.get(self.step_index)
}

///|
fn ParseItem::symbol(self : ParseItem) -> InternalSymbol? {
  match self.step() {
    Some(step) => Some(step.symbol)
    None => None
  }
}

///|
fn ParseItem::previous_step(self : ParseItem) -> ProductionStep? {
  if self.step_index > 0 {
    self.production.steps.get(self.step_index - 1)
  } else {
    None
  }
}

///|
fn ParseItem::is_done(self : ParseItem) -> Bool {
  self.step_index == self.production.steps.length()
}

///|
fn ParseItem::is_augmented(self : ParseItem) -> Bool {
  self.variable_index == -1
}

///|
fn ParseItem::successor(self : ParseItem) -> ParseItem {
  { ..self, step_index: self.step_index + 1 }
}

///|
fn ParseItem::substitute_production(
  self : ParseItem,
  production : FlattenedProduction,
) -> ParseItem {
  { ..self, production, }
}

///|
fn parse_item_substitute_generated(
  item : ParseItem,
  generated_index : Int,
  production : FlattenedProduction,
) -> ParseItem {
  {
    ..item.substitute_production(production),
    source: Some(InlinedProductionSource::GeneratedProduction(generated_index)),
  }
}

///|
fn parse_item_set_empty() -> ParseItemSet {
  { entries: [] }
}

///|
fn ParseItemSet::insert(self : ParseItemSet, item : ParseItem) -> Int {
  for i in 0..<self.entries.length() {
    let comparison = parse_item_compare(self.entries[i].item, item)
    if comparison == 0 {
      return i
    }
    if comparison > 0 {
      self.entries.insert(i, {
        item,
        lookaheads: parse_token_set_empty(),
        following_reserved_word_set: 0,
      })
      return i
    }
  }
  let index = self.entries.length()
  self.entries.push({
    item,
    lookaheads: parse_token_set_empty(),
    following_reserved_word_set: 0,
  })
  index
}

///|
fn ParseItemSet::core(self : ParseItemSet) -> ParseItemSetCore {
  let entries : Array[ParseItem] = []
  for entry in self.entries {
    entries.push(entry.item)
  }
  { entries, }
}

///|
fn ParseItemSetBuilder::transitive_closure(
  self : ParseItemSetBuilder,
  item_set : ParseItemSet,
) -> ParseItemSet {
  let result = parse_item_set_empty()
  for entry in item_set.entries {
    let inlined = inlined_productions_for_item(self.grammar.inlines, entry.item)
    if inlined.length() > 0 {
      for generated in inlined {
        self.add_item(result, {
          item: parse_item_substitute_generated(
            entry.item,
            generated.0,
            generated.1,
          ),
          lookaheads: parse_token_set_clone(entry.lookaheads),
          following_reserved_word_set: entry.following_reserved_word_set,
        })
      }
    } else {
      self.add_item(result, entry)
    }
  }
  result
}

///|
fn ParseItemSetBuilder::add_item(
  self : ParseItemSetBuilder,
  set : ParseItemSet,
  entry : ParseItemSetEntry,
) -> Unit {
  match entry.item.step() {
    Some(step) =>
      match step.symbol {
        NonTerminal(index) =>
          if index >= 0 && index < self.transitive_closure_additions.length() {
            let next_step = entry.item.successor().step()
            let (following_tokens, following_reserved_tokens) = match
              next_step {
              Some(step) =>
                (
                  parse_symbol_first_set(self.symbol_sets, step.symbol),
                  parse_symbol_reserved_first_set(self.symbol_sets, step.symbol),
                )
              None =>
                (
                  parse_token_set_clone(entry.lookaheads),
                  entry.following_reserved_word_set,
                )
            }
            for addition in self.transitive_closure_additions[index] {
              let addition_index = set.insert(addition.item)
              parse_token_set_insert_all(
                set.entries[addition_index].lookaheads,
                addition.info.lookaheads,
              )
              match self.grammar.syntax.word_symbol {
                Some(word_symbol) =>
                  if parse_token_set_contains_symbol(
                      addition.info.lookaheads,
                      word_symbol,
                    ) {
                    parse_item_set_entry_max_reserved(
                      set.entries[addition_index],
                      addition.info.reserved_lookaheads,
                    )
                  }
                None => ()
              }
              if addition.info.propagates_lookaheads {
                parse_token_set_insert_all(
                  set.entries[addition_index].lookaheads,
                  following_tokens,
                )
                match self.grammar.syntax.word_symbol {
                  Some(word_symbol) =>
                    if parse_token_set_contains_symbol(
                        following_tokens, word_symbol,
                      ) {
                      parse_item_set_entry_max_reserved(
                        set.entries[addition_index],
                        following_reserved_tokens,
                      )
                    }
                  None => ()
                }
              }
            }
          }
        Terminal(_) | External(_) => ()
      }
    None => ()
  }
  let index = set.insert(entry.item)
  parse_token_set_insert_all(set.entries[index].lookaheads, entry.lookaheads)
  parse_item_set_entry_max_reserved(
    set.entries[index],
    entry.following_reserved_word_set,
  )
}

///|
fn parse_item_set_entry_max_reserved(
  entry : ParseItemSetEntry,
  reserved_word_set_id : Int,
) -> Unit {
  if reserved_word_set_id > entry.following_reserved_word_set {
    entry.following_reserved_word_set = reserved_word_set_id
  }
}

///|
fn inlined_productions_for_item(
  inlines : InlinedProductionMap,
  item : ParseItem,
) -> Array[(Int, FlattenedProduction)] {
  match item.source {
    Some(source) =>
      inlined_productions_for_source(inlines, source, item.step_index)
    None => []
  }
}

///|
fn inlined_productions_for_source(
  inlines : InlinedProductionMap,
  source : InlinedProductionSource,
  step_index : Int,
) -> Array[(Int, FlattenedProduction)] {
  let result : Array[(Int, FlattenedProduction)] = []
  for entry in inlines.entries {
    if entry.source == source && entry.step_index == step_index {
      for index in entry.production_indices {
        if index >= 0 && index < inlines.productions.length() {
          result.push((index, inlines.productions[index]))
        }
      }
    }
  }
  result
}

///|
fn push_unique_closure_addition(
  additions : Array[ParseClosureAddition],
  addition : ParseClosureAddition,
) -> Unit {
  for existing in additions {
    if parse_closure_addition_same(existing, addition) {
      return
    }
  }
  additions.push(addition)
}

///|
fn parse_closure_addition_same(
  left : ParseClosureAddition,
  right : ParseClosureAddition,
) -> Bool {
  parse_item_same(left.item, right.item) &&
  parse_follow_set_info_same(left.info, right.info)
}

///|
fn parse_item_same(left : ParseItem, right : ParseItem) -> Bool {
  if left.variable_index != right.variable_index ||
    left.step_index != right.step_index ||
    left.production.dynamic_precedence != right.production.dynamic_precedence ||
    left.production.steps.length() != right.production.steps.length() ||
    !parse_item_precedence_same(left, right) ||
    !same_associativity(
      parse_item_associativity(left),
      parse_item_associativity(right),
    ) ||
    left.has_preceding_inherited_fields != right.has_preceding_inherited_fields {
    return false
  }
  for i in 0..<left.production.steps.length() {
    if i < left.step_index {
      if left.production.steps[i].alias_name !=
        right.production.steps[i].alias_name ||
        left.production.steps[i].alias_named !=
        right.production.steps[i].alias_named ||
        left.production.steps[i].field_name !=
        right.production.steps[i].field_name {
        return false
      }
      if left.has_preceding_inherited_fields &&
        left.production.steps[i].symbol != right.production.steps[i].symbol {
        return false
      }
    } else if !same_production_step(
        left.production.steps[i],
        right.production.steps[i],
      ) {
      return false
    }
  }
  true
}

///|
fn parse_item_compare(left : ParseItem, right : ParseItem) -> Int {
  let mut comparison = compare_int(left.step_index, right.step_index)
  if comparison != 0 {
    return comparison
  }
  comparison = compare_int(left.variable_index, right.variable_index)
  if comparison != 0 {
    return comparison
  }
  comparison = compare_int(
    left.production.dynamic_precedence,
    right.production.dynamic_precedence,
  )
  if comparison != 0 {
    return comparison
  }
  comparison = compare_int(
    left.production.steps.length(),
    right.production.steps.length(),
  )
  if comparison != 0 {
    return comparison
  }
  comparison = compare_production_step_precedence(
    parse_item_precedence_step(left),
    parse_item_precedence_step(right),
  )
  if comparison != 0 {
    return comparison
  }
  comparison = compare_associativity(
    parse_item_associativity(left),
    parse_item_associativity(right),
  )
  if comparison != 0 {
    return comparison
  }
  for i in 0..<left.production.steps.length() {
    if i < left.step_index {
      comparison = compare_string_option(
        left.production.steps[i].alias_name,
        right.production.steps[i].alias_name,
      )
      if comparison != 0 {
        return comparison
      }
      comparison = compare_bool(
        left.production.steps[i].alias_named,
        right.production.steps[i].alias_named,
      )
      if comparison != 0 {
        return comparison
      }
      comparison = compare_string_option(
        left.production.steps[i].field_name,
        right.production.steps[i].field_name,
      )
      if comparison != 0 {
        return comparison
      }
    } else {
      comparison = compare_production_step(
        left.production.steps[i],
        right.production.steps[i],
      )
      if comparison != 0 {
        return comparison
      }
    }
  }
  0
}

///|
fn parse_item_precedence_step(item : ParseItem) -> ProductionStep? {
  item.previous_step()
}

///|
fn parse_item_precedence_same(left : ParseItem, right : ParseItem) -> Bool {
  match (parse_item_precedence_step(left), parse_item_precedence_step(right)) {
    (None, None) => true
    (Some(left_step), Some(right_step)) =>
      left_step.precedence == right_step.precedence
    _ => false
  }
}

///|
fn parse_item_associativity(item : ParseItem) -> Associativity {
  match item.previous_step() {
    Some(step) => step.associativity
    None => Associativity::NoAssociativity
  }
}

///|
fn compare_production_step_precedence(
  left : ProductionStep?,
  right : ProductionStep?,
) -> Int {
  compare_precedence_value_option(
    match left {
      Some(step) => step.precedence
      None => None
    },
    match right {
      Some(step) => step.precedence
      None => None
    },
  )
}

///|
fn compare_production_step(
  left : ProductionStep,
  right : ProductionStep,
) -> Int {
  let mut comparison = compare_internal_symbol(left.symbol, right.symbol)
  if comparison != 0 {
    return comparison
  }
  comparison = compare_string_option(left.alias_name, right.alias_name)
  if comparison != 0 {
    return comparison
  }
  comparison = compare_bool(left.alias_named, right.alias_named)
  if comparison != 0 {
    return comparison
  }
  comparison = compare_string_option(left.field_name, right.field_name)
  if comparison != 0 {
    return comparison
  }
  comparison = compare_precedence_value_option(
    left.precedence,
    right.precedence,
  )
  if comparison != 0 {
    return comparison
  }
  comparison = compare_associativity(left.associativity, right.associativity)
  if comparison != 0 {
    return comparison
  }
  compare_int(left.reserved_word_set_id, right.reserved_word_set_id)
}

///|
fn compare_internal_symbol(
  left : InternalSymbol,
  right : InternalSymbol,
) -> Int {
  let comparison = compare_int(
    internal_symbol_kind_rank(left),
    internal_symbol_kind_rank(right),
  )
  if comparison != 0 {
    return comparison
  }
  compare_int(internal_symbol_index(left), internal_symbol_index(right))
}

///|
fn internal_symbol_kind_rank(symbol : InternalSymbol) -> Int {
  match symbol {
    Terminal(_) => 0
    External(_) => 1
    NonTerminal(_) => 2
  }
}

///|
fn internal_symbol_index(symbol : InternalSymbol) -> Int {
  match symbol {
    Terminal(index) | External(index) | NonTerminal(index) => index
  }
}

///|
fn compare_precedence_value_option(
  left : @grammar.PrecedenceValue?,
  right : @grammar.PrecedenceValue?,
) -> Int {
  match (left, right) {
    (None, None) => 0
    (None, Some(_)) => -1
    (Some(_), None) => 1
    (Some(left_value), Some(right_value)) =>
      compare_precedence_value(left_value, right_value)
  }
}

///|
fn compare_precedence_value(
  left : @grammar.PrecedenceValue,
  right : @grammar.PrecedenceValue,
) -> Int {
  match (left, right) {
    (Number(left_number), Number(right_number)) =>
      compare_int(left_number, right_number)
    (Name(left_name), Name(right_name)) => left_name.compare(right_name)
    (Number(_), Name(_)) => -1
    (Name(_), Number(_)) => 1
  }
}

///|
fn compare_associativity(left : Associativity, right : Associativity) -> Int {
  compare_int(associativity_rank(left), associativity_rank(right))
}

///|
fn associativity_rank(value : Associativity) -> Int {
  match value {
    NoAssociativity => 0
    Left => 1
    Right => 2
  }
}

///|
fn compare_bool(left : Bool, right : Bool) -> Int {
  match (left, right) {
    (false, false) | (true, true) => 0
    (false, true) => -1
    (true, false) => 1
  }
}

///|
fn compare_string_option(left : String?, right : String?) -> Int {
  match (left, right) {
    (None, None) => 0
    (None, Some(_)) => -1
    (Some(_), None) => 1
    (Some(left_value), Some(right_value)) => left_value.compare(right_value)
  }
}

///|
fn parse_items_smoke_weight() -> Int {
  let production = {
    steps: [
      {
        symbol: InternalSymbol::Terminal(0),
        alias_name: Some("alias"),
        alias_named: true,
        field_name: Some("field"),
        precedence: Some(@grammar.PrecedenceValue::Number(1)),
        associativity: Associativity::Left,
        reserved_word_set_id: 0,
      },
    ],
    dynamic_precedence: 2,
  }
  let start = parse_item_start()
  let item = parse_item_for_production(0, production)
  let tagged = parse_item_for_grammar_production(0, 0, production)
  let generated = parse_item_for_generated_production(0, 0, production)
  let successor = item.successor()
  let substituted = successor.substitute_production(production)
  let set = parse_item_set_empty()
  let first_index = set.insert(start)
  let second_index = set.insert(item)
  let third_index = set.insert(substituted)
  let core = set.core()
  let mut weight = first_index + second_index + third_index
  weight += core.entries.length()
  weight += parse_item_set_weight(set)
  match start.symbol() {
    Some(symbol) => weight += internal_symbol_weight(symbol)
    None => ()
  }
  if start.is_augmented() {
    weight += 1
  }
  if successor.is_done() {
    weight += 1
  }
  if parse_item_same(successor, substituted) {
    weight += 1
  }
  if tagged.source is Some(_) {
    weight += 1
  }
  if generated.source is Some(_) {
    weight += 1
  }
  weight
}

///|
fn parse_item_set_builder_smoke_weight(
  grammar : PreparedGrammar,
  symbol_sets : ParseSymbolSets,
) -> Int {
  let builder = build_parse_item_set_builder(grammar, symbol_sets)
  let item_set = parse_item_set_empty()
  let start_index = item_set.insert(parse_item_start())
  item_set.entries[start_index].lookaheads.eof = true
  let closure = builder.transitive_closure(item_set)
  let mut weight = parse_item_set_weight(closure)
  for additions in builder.transitive_closure_additions {
    for addition in additions {
      weight += parse_item_weight(addition.item)
      weight += parse_token_set_weight(addition.info.lookaheads)
      weight += addition.info.reserved_lookaheads
      if addition.info.propagates_lookaheads {
        weight += 1
      }
    }
  }
  weight
}

///|
fn parse_item_set_weight(set : ParseItemSet) -> Int {
  let mut weight = 0
  for entry in set.entries {
    weight += parse_item_weight(entry.item)
    weight += parse_token_set_weight(entry.lookaheads)
    weight += entry.following_reserved_word_set
  }
  weight
}

///|
fn parse_item_weight(item : ParseItem) -> Int {
  let mut weight = item.variable_index + item.step_index
  weight += flattened_production_weight(item.production)
  if item.has_preceding_inherited_fields {
    weight += 1
  }
  weight
}
