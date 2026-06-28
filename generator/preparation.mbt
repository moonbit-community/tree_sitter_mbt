///|
priv struct DefaultAlias {
  symbol : InternalSymbol
  value : String
  named : Bool
}

///|
priv struct AliasExtractedGrammar {
  syntax : FlattenedSyntaxGrammar
  lexical : ExpandedLexicalGrammar
  default_aliases : Array[DefaultAlias]
}

///|
priv enum InlinedProductionSource {
  GrammarProduction(variable_index~ : Int, production_index~ : Int)
  GeneratedProduction(Int)
} derive(Eq)

///|
priv struct InlinedProductionEntry {
  source : InlinedProductionSource
  step_index : Int
  production_indices : Array[Int]
}

///|
priv struct InlinedProductionMap {
  productions : Array[FlattenedProduction]
  entries : Array[InlinedProductionEntry]
}

///|
priv struct PreparedGrammar {
  syntax : FlattenedSyntaxGrammar
  lexical : ExpandedLexicalGrammar
  default_aliases : Array[DefaultAlias]
  inlines : InlinedProductionMap
}

///|
priv struct AliasCount {
  symbol : InternalSymbol
  value : String
  named : Bool
  count : Int
}

///|
fn extract_default_aliases(
  grammar : TokenExpandedGrammar,
) -> AliasExtractedGrammar {
  let alias_counts : Array[AliasCount] = []
  let unaliased_symbols : Array[InternalSymbol] = []
  for variable in grammar.syntax.variables {
    for production in variable.productions {
      for step in production.steps {
        if contains_internal_symbol(grammar.syntax.inline_symbols, step.symbol) {
          continue
        }
        match step.alias_name {
          Some(value) =>
            record_alias(alias_counts, step.symbol, value, step.alias_named)
          None => push_unique_internal_symbol(unaliased_symbols, step.symbol)
        }
      }
    }
  }
  for symbol in grammar.syntax.extra_symbols {
    push_unique_internal_symbol(unaliased_symbols, symbol)
  }
  let default_aliases = choose_default_aliases(
    grammar, alias_counts, unaliased_symbols,
  )
  {
    syntax: clear_default_aliases_from_syntax(grammar.syntax, default_aliases),
    lexical: grammar.lexical,
    default_aliases,
  }
}

///|
fn record_alias(
  alias_counts : Array[AliasCount],
  symbol : InternalSymbol,
  value : String,
  named : Bool,
) -> Unit {
  for i in 0..<alias_counts.length() {
    let entry = alias_counts[i]
    if entry.symbol == symbol && entry.value == value && entry.named == named {
      alias_counts[i] = { ..entry, count: entry.count + 1 }
      return
    }
  }
  alias_counts.push({ symbol, value, named, count: 1 })
}

///|
fn choose_default_aliases(
  grammar : TokenExpandedGrammar,
  alias_counts : Array[AliasCount],
  unaliased_symbols : Array[InternalSymbol],
) -> Array[DefaultAlias] {
  let result : Array[DefaultAlias] = []
  for i in 0..<grammar.lexical.variables.length() {
    push_default_alias_for_symbol(
      result,
      InternalSymbol::Terminal(i),
      alias_counts,
      unaliased_symbols,
    )
  }
  for i in 0..<grammar.syntax.variables.length() {
    push_default_alias_for_symbol(
      result,
      InternalSymbol::NonTerminal(i),
      alias_counts,
      unaliased_symbols,
    )
  }
  for i in 0..<grammar.syntax.external_tokens.length() {
    push_default_alias_for_symbol(
      result,
      InternalSymbol::External(i),
      alias_counts,
      unaliased_symbols,
    )
  }
  result
}

///|
fn push_default_alias_for_symbol(
  aliases : Array[DefaultAlias],
  symbol : InternalSymbol,
  alias_counts : Array[AliasCount],
  unaliased_symbols : Array[InternalSymbol],
) -> Unit {
  if contains_internal_symbol(unaliased_symbols, symbol) {
    return
  }
  match best_alias_for_symbol(symbol, alias_counts) {
    Some(alias_count) =>
      aliases.push({
        symbol,
        value: alias_count.value,
        named: alias_count.named,
      })
    None => ()
  }
}

///|
fn best_alias_for_symbol(
  symbol : InternalSymbol,
  alias_counts : Array[AliasCount],
) -> AliasCount? {
  let mut best : AliasCount? = None
  for alias_count in alias_counts {
    if alias_count.symbol == symbol {
      match best {
        Some(current) =>
          if alias_count.count > current.count {
            best = Some(alias_count)
          }
        None => best = Some(alias_count)
      }
    }
  }
  best
}

///|
fn clear_default_aliases_from_syntax(
  syntax : FlattenedSyntaxGrammar,
  default_aliases : Array[DefaultAlias],
) -> FlattenedSyntaxGrammar {
  let variables : Array[FlattenedVariable] = []
  for variable in syntax.variables {
    variables.push({
      ..variable,
      productions: clear_default_aliases_in_productions(
        variable.productions,
        default_aliases,
      ),
    })
  }
  { ..syntax, variables, }
}

///|
fn clear_default_aliases_in_productions(
  productions : Array[FlattenedProduction],
  default_aliases : Array[DefaultAlias],
) -> Array[FlattenedProduction] {
  let result : Array[FlattenedProduction] = []
  for production_index in 0..<productions.length() {
    result.push(
      clear_default_aliases_in_production(
        productions[production_index],
        productions,
        production_index,
        default_aliases,
      ),
    )
  }
  result
}

///|
fn clear_default_aliases_in_production(
  production : FlattenedProduction,
  all_productions : Array[FlattenedProduction],
  production_index : Int,
  default_aliases : Array[DefaultAlias],
) -> FlattenedProduction {
  let steps : Array[ProductionStep] = []
  for step_index in 0..<production.steps.length() {
    let step = production.steps[step_index]
    if step_matches_default_alias(step, default_aliases) &&
      !other_productions_need_alias(
        all_productions, production_index, step_index, step, default_aliases,
      ) {
      steps.push({ ..step, alias_name: None, alias_named: false })
    } else {
      steps.push(step)
    }
  }
  { steps, dynamic_precedence: production.dynamic_precedence }
}

///|
fn step_matches_default_alias(
  step : ProductionStep,
  default_aliases : Array[DefaultAlias],
) -> Bool {
  match step.alias_name {
    Some(value) =>
      default_alias_matches(
        default_aliases,
        step.symbol,
        value,
        step.alias_named,
      )
    None => false
  }
}

///|
fn default_alias_matches(
  default_aliases : Array[DefaultAlias],
  symbol : InternalSymbol,
  value : String,
  named : Bool,
) -> Bool {
  for default_alias in default_aliases {
    if default_alias.symbol == symbol &&
      default_alias.value == value &&
      default_alias.named == named {
      return true
    }
  }
  false
}

///|
fn other_productions_need_alias(
  productions : Array[FlattenedProduction],
  current_index : Int,
  step_index : Int,
  step : ProductionStep,
  default_aliases : Array[DefaultAlias],
) -> Bool {
  match step.alias_name {
    None => false
    Some(value) => {
      for i in 0..<productions.length() {
        if i != current_index && productions[i].steps.length() > step_index {
          let other_step = productions[i].steps[step_index]
          if other_step.alias_name == Some(value) &&
            other_step.alias_named == step.alias_named &&
            !default_alias_matches(
              default_aliases,
              other_step.symbol,
              value,
              step.alias_named,
            ) {
            return true
          }
        }
      }
      false
    }
  }
}

///|
priv struct InlinedProductionMapBuilder {
  productions : Array[FlattenedProduction]
  entries : Array[InlinedProductionEntry]
  processed_sources : Array[InlinedProductionSource]
}

///|
fn process_inlines(
  grammar : AliasExtractedGrammar,
) -> PreparedGrammar raise GenerateError {
  validate_inline_symbols(grammar.syntax, grammar.lexical)
  let builder : InlinedProductionMapBuilder = {
    productions: [],
    entries: [],
    processed_sources: [],
  }
  for variable_index in 0..<grammar.syntax.variables.length() {
    let variable = grammar.syntax.variables[variable_index]
    for production_index in 0..<variable.productions.length() {
      process_inline_entries_for_production(
        builder,
        InlinedProductionSource::GrammarProduction(
          variable_index~,
          production_index~,
        ),
        variable.productions[production_index],
        grammar.syntax,
      )
    }
  }
  {
    syntax: grammar.syntax,
    lexical: grammar.lexical,
    default_aliases: grammar.default_aliases,
    inlines: { productions: builder.productions, entries: builder.entries },
  }
}

///|
fn validate_inline_symbols(
  syntax : FlattenedSyntaxGrammar,
  lexical : ExpandedLexicalGrammar,
) -> Unit raise GenerateError {
  for symbol in syntax.inline_symbols {
    match symbol {
      External(index) =>
        raise GenerateError::InvalidInline(
          "External token `\{external_token_name_at(syntax, index)}` cannot be inlined",
        )
      Terminal(index) =>
        raise GenerateError::InvalidInline(
          "Token `\{lexical_variable_name_at(lexical, index)}` cannot be inlined",
        )
      NonTerminal(0) =>
        raise GenerateError::InvalidInline(
          "Rule `\{syntax_variable_name_at(syntax, 0)}` cannot be inlined because it is the first rule",
        )
      NonTerminal(_) => ()
    }
  }
}

///|
fn external_token_name_at(
  syntax : FlattenedSyntaxGrammar,
  index : Int,
) -> String {
  if index >= 0 && index < syntax.external_tokens.length() {
    syntax.external_tokens[index].name
  } else {
    "<unknown>"
  }
}

///|
fn lexical_variable_name_at(
  lexical : ExpandedLexicalGrammar,
  index : Int,
) -> String {
  if index >= 0 && index < lexical.variables.length() {
    lexical.variables[index].name
  } else {
    "<unknown>"
  }
}

///|
fn syntax_variable_name_at(
  syntax : FlattenedSyntaxGrammar,
  index : Int,
) -> String {
  if index >= 0 && index < syntax.variables.length() {
    syntax.variables[index].name
  } else {
    "<unknown>"
  }
}

///|
fn process_inline_entries_for_production(
  builder : InlinedProductionMapBuilder,
  source : InlinedProductionSource,
  production : FlattenedProduction,
  syntax : FlattenedSyntaxGrammar,
) -> Unit {
  if contains_inlined_source(builder.processed_sources, source) {
    return
  }
  builder.processed_sources.push(source)
  for step_index in 0..<production.steps.length() {
    let step = production.steps[step_index]
    if contains_internal_symbol(syntax.inline_symbols, step.symbol) {
      let inlined = inline_production_at_step(production, step_index, syntax)
      let production_indices = store_inlined_productions(builder, inlined)
      builder.entries.push({ source, step_index, production_indices })
      for index in production_indices {
        process_inline_entries_for_production(
          builder,
          InlinedProductionSource::GeneratedProduction(index),
          builder.productions[index],
          syntax,
        )
      }
    }
  }
}

///|
fn contains_inlined_source(
  sources : Array[InlinedProductionSource],
  source : InlinedProductionSource,
) -> Bool {
  for existing in sources {
    if existing == source {
      return true
    }
  }
  false
}

///|
fn inline_production_at_step(
  production : FlattenedProduction,
  step_index : Int,
  syntax : FlattenedSyntaxGrammar,
) -> Array[FlattenedProduction] {
  let mut candidates : Array[FlattenedProduction] = [production]
  let mut index = 0
  while index < candidates.length() {
    let candidate = candidates[index]
    if step_index < candidate.steps.length() &&
      contains_internal_symbol(
        syntax.inline_symbols,
        candidate.steps[step_index].symbol,
      ) {
      candidates = replace_candidate_with_inlined_productions(
        candidates,
        index,
        inline_single_candidate(candidate, step_index, syntax),
      )
    } else {
      index += 1
    }
  }
  candidates
}

///|
fn replace_candidate_with_inlined_productions(
  candidates : Array[FlattenedProduction],
  index : Int,
  replacements : Array[FlattenedProduction],
) -> Array[FlattenedProduction] {
  let result : Array[FlattenedProduction] = []
  for i in 0..<candidates.length() {
    if i == index {
      for replacement in replacements {
        result.push(replacement)
      }
    } else {
      result.push(candidates[i])
    }
  }
  result
}

///|
fn inline_single_candidate(
  production : FlattenedProduction,
  step_index : Int,
  syntax : FlattenedSyntaxGrammar,
) -> Array[FlattenedProduction] {
  match production.steps[step_index].symbol {
    NonTerminal(index) =>
      if index >= 0 && index < syntax.variables.length() {
        let result : Array[FlattenedProduction] = []
        for inline_production in syntax.variables[index].productions {
          result.push(
            inline_production_once(production, step_index, inline_production),
          )
        }
        result
      } else {
        [production]
      }
    _ => [production]
  }
}

///|
fn inline_production_once(
  production : FlattenedProduction,
  step_index : Int,
  inline_production : FlattenedProduction,
) -> FlattenedProduction {
  let removed_step = production.steps[step_index]
  let steps : Array[ProductionStep] = []
  for i in 0..<step_index {
    steps.push(production.steps[i])
  }
  for inserted_step in inline_production.steps {
    steps.push(apply_outer_inline_metadata(inserted_step, removed_step))
  }
  for i in (step_index + 1)..<production.steps.length() {
    steps.push(production.steps[i])
  }
  if inline_production.steps.length() > 0 {
    let last_index = step_index + inline_production.steps.length() - 1
    steps[last_index] = inherit_inline_tail_metadata(
      steps[last_index],
      removed_step,
    )
  }
  {
    steps,
    dynamic_precedence: strongest_dynamic_precedence(
      production.dynamic_precedence,
      inline_production.dynamic_precedence,
    ),
  }
}

///|
fn apply_outer_inline_metadata(
  inserted_step : ProductionStep,
  removed_step : ProductionStep,
) -> ProductionStep {
  let mut result = inserted_step
  match removed_step.alias_name {
    Some(value) =>
      result = {
        ..result,
        alias_name: Some(value),
        alias_named: removed_step.alias_named,
      }
    None => ()
  }
  match removed_step.field_name {
    Some(value) => result = { ..result, field_name: Some(value) }
    None => ()
  }
  result
}

///|
fn inherit_inline_tail_metadata(
  inserted_step : ProductionStep,
  removed_step : ProductionStep,
) -> ProductionStep {
  let with_precedence = match inserted_step.precedence {
    Some(_) => inserted_step
    None => { ..inserted_step, precedence: removed_step.precedence }
  }
  if with_precedence.associativity is Associativity::NoAssociativity {
    { ..with_precedence, associativity: removed_step.associativity }
  } else {
    with_precedence
  }
}

///|
fn store_inlined_productions(
  builder : InlinedProductionMapBuilder,
  productions : Array[FlattenedProduction],
) -> Array[Int] {
  let indices : Array[Int] = []
  for production in productions {
    indices.push(store_inlined_production(builder, production))
  }
  indices
}

///|
fn store_inlined_production(
  builder : InlinedProductionMapBuilder,
  production : FlattenedProduction,
) -> Int {
  for i in 0..<builder.productions.length() {
    if same_production(builder.productions[i], production) {
      return i
    }
  }
  builder.productions.push(production)
  builder.productions.length() - 1
}

///|
fn prepared_snapshot_weight(snapshot : PreparedGrammar) -> Int {
  let mut weight = flattened_syntax_grammar_weight(snapshot.syntax)
  weight += expanded_lexical_grammar_weight(snapshot.lexical)
  for default_alias in snapshot.default_aliases {
    weight += internal_symbol_weight(default_alias.symbol)
    weight += default_alias.value.length()
    if default_alias.named {
      weight += 1
    }
  }
  weight += inlined_production_map_weight(snapshot.inlines)
  weight
}

///|
fn expanded_lexical_grammar_weight(lexical : ExpandedLexicalGrammar) -> Int {
  let mut weight = 0
  for variable in lexical.variables {
    weight += internal_symbol_weight(variable.symbol)
    weight += variable.name.length()
    weight += variable_kind_weight(variable.kind)
    weight += nfa_weight(variable.nfa)
    if variable.immediate {
      weight += 1
    }
    match variable.explicit_precedence {
      Some(value) => weight += value
      None => ()
    }
    weight += variable.implicit_precedence
    if variable.main_token {
      weight += 1
    }
  }
  for separator in lexical.separators {
    weight += nfa_weight(separator)
  }
  for token in lexical.external_tokens {
    weight += internal_symbol_weight(token.symbol)
    weight += token.name.length()
    weight += variable_kind_weight(token.kind)
    weight += optional_internal_symbol_weight(
      token.corresponding_internal_token,
    )
  }
  weight
}

///|
fn inlined_production_map_weight(map : InlinedProductionMap) -> Int {
  let mut weight = 0
  for production in map.productions {
    weight += flattened_production_weight(production)
  }
  for entry in map.entries {
    weight += inlined_source_weight(entry.source)
    weight += entry.step_index
    for index in entry.production_indices {
      weight += index
    }
  }
  weight
}

///|
fn inlined_source_weight(source : InlinedProductionSource) -> Int {
  match source {
    GrammarProduction(variable_index~, production_index~) =>
      variable_index + production_index
    GeneratedProduction(index) => index
  }
}
