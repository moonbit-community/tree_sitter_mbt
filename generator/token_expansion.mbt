///|
priv struct ExpandedLexicalVariable {
  symbol : InternalSymbol
  name : String
  kind : VariableKind
  nfa : Nfa
  immediate : Bool
  explicit_precedence : Int?
  implicit_precedence : Int
  main_token : Bool
  literal : String?
}

///|
priv struct ExpandedExternalToken {
  symbol : InternalSymbol
  name : String
  kind : VariableKind
  corresponding_internal_token : InternalSymbol?
}

///|
priv struct ExpandedLexicalGrammar {
  variables : Array[ExpandedLexicalVariable]
  separators : Array[Nfa]
  external_tokens : Array[ExpandedExternalToken]
}

///|
priv struct TokenExpandedGrammar {
  syntax : FlattenedSyntaxGrammar
  lexical : ExpandedLexicalGrammar
}

///|
priv struct TokenExpansionContext {
  mut immediate : Bool
  mut main_token : Bool
  mut explicit_precedence : Int?
  mut string_token : Bool
}

///|
fn expand_tokens(
  grammar : FlattenedGrammar,
) -> TokenExpandedGrammar raise GenerateError {
  let variables : Array[ExpandedLexicalVariable] = []
  for variable in grammar.lexical.variables {
    variables.push(expand_lexical_variable(variable))
  }
  let separators : Array[Nfa] = []
  for separator in grammar.lexical.separators {
    separators.push(expand_separator(separator))
  }
  let external_tokens : Array[ExpandedExternalToken] = []
  for token in grammar.syntax.external_tokens {
    external_tokens.push(expand_external_token(token))
  }
  {
    syntax: grammar.syntax,
    lexical: { variables, separators, external_tokens },
  }
}

///|
fn expand_lexical_variable(
  variable : LexicalVariable,
) -> ExpandedLexicalVariable raise GenerateError {
  if lexical_rule_is_structurally_empty(variable.rule) {
    raise GenerateError::InvalidLexicalToken(
      "Lexical token \{variable.name} can match empty input",
    )
  }
  let context = token_expansion_context_default()
  let ast = lexical_rule_to_regex_ast(variable.rule, variable.name, context)
  let accept_precedence = optional_int_or_zero(context.explicit_precedence)
  let transition_precedence = accept_precedence
  {
    symbol: variable.symbol,
    name: variable.name,
    kind: variable.kind,
    nfa: nfa_with_metadata(
      regex_ast_to_nfa(ast),
      terminal_index_for_symbol(variable.symbol),
      accept_precedence,
      false,
      transition_precedence,
    ),
    immediate: context.immediate,
    explicit_precedence: context.explicit_precedence,
    implicit_precedence: token_implicit_precedence(context),
    main_token: context.main_token,
    literal: lexical_rule_literal(variable.rule),
  }
}

///|
fn lexical_rule_literal(rule : InternedRule) -> String? {
  match rule {
    IRString(value) => Some(value)
    IRToken(content) | IRImmediateToken(content) =>
      lexical_rule_literal(content)
    _ => None
  }
}

///|
fn expand_separator(rule : InternedRule) -> Nfa raise GenerateError {
  if lexical_rule_is_structurally_empty(rule) {
    raise GenerateError::InvalidLexicalToken(
      "Lexical separator can match empty input",
    )
  }
  let context = token_expansion_context_default()
  nfa_with_metadata(
    regex_ast_to_nfa(lexical_rule_to_regex_ast(rule, "extra", context)),
    -1,
    0,
    true,
    0,
  )
}

///|
fn expand_external_token(
  token : ExtractedExternalToken,
) -> ExpandedExternalToken {
  {
    symbol: token.symbol,
    name: token.name,
    kind: token.kind,
    corresponding_internal_token: token.corresponding_internal_token,
  }
}

///|
fn token_expansion_context_default() -> TokenExpansionContext {
  {
    immediate: false,
    main_token: false,
    explicit_precedence: None,
    string_token: false,
  }
}

///|
fn token_implicit_precedence(context : TokenExpansionContext) -> Int {
  let string_precedence = if context.string_token { 2 } else { 0 }
  let token_precedence = if context.main_token || context.immediate {
    1
  } else {
    0
  }
  string_precedence + token_precedence
}

///|
fn optional_int_or_zero(value : Int?) -> Int {
  match value {
    Some(number) => number
    None => 0
  }
}

///|
fn terminal_index_for_symbol(symbol : InternalSymbol) -> Int {
  match symbol {
    Terminal(index) => index
    _ => -1
  }
}

///|
fn lexical_rule_is_structurally_empty(rule : InternedRule) -> Bool {
  match rule {
    IRAlias(content~, ..)
    | IRField(content~, ..)
    | IRPrec(content~, ..)
    | IRPrecLeft(content~, ..)
    | IRPrecRight(content~, ..)
    | IRPrecDynamic(content~, ..)
    | IRToken(content)
    | IRImmediateToken(content)
    | IRReserved(content~, ..) => lexical_rule_is_structurally_empty(content)
    IRBlank => true
    IRString(value) => value.is_empty()
    IRPattern(_) | IRSymbol(_) => false
    IRSeq(members) => lexical_rule_array_is_all_empty(members)
    IRChoice(members) => lexical_rule_array_contains_empty(members)
    IRRepeat(_) => true
    IRRepeat1(content) => lexical_rule_is_structurally_empty(content)
  }
}

///|
fn lexical_rule_array_is_all_empty(rules : Array[InternedRule]) -> Bool {
  for rule in rules {
    if !lexical_rule_is_structurally_empty(rule) {
      return false
    }
  }
  true
}

///|
fn lexical_rule_array_contains_empty(rules : Array[InternedRule]) -> Bool {
  for rule in rules {
    if lexical_rule_is_structurally_empty(rule) {
      return true
    }
  }
  false
}

///|
fn lexical_rule_to_regex_ast(
  rule : InternedRule,
  token_name : String,
  context : TokenExpansionContext,
) -> RegexAst raise GenerateError {
  match rule {
    IRAlias(content~, ..)
    | IRField(content~, ..)
    | IRPrecDynamic(content~, ..)
    | IRReserved(content~, ..) =>
      lexical_rule_to_regex_ast(content, token_name, context)
    IRBlank => RegexAst::RegexEmpty
    IRString(value) => {
      context.string_token = true
      string_to_regex_ast(value)
    }
    IRPattern(value~, flags~) => pattern_to_regex_ast(value, flags)
    IRSymbol(_) =>
      raise GenerateError::InvalidLexicalToken(
        "Lexical token \{token_name} contains a symbol reference",
      )
    IRSeq(members) =>
      RegexAst::RegexSeq(
        lexical_rule_array_to_regex_ast(members, token_name, context),
      )
    IRChoice(members) =>
      RegexAst::RegexChoice(
        lexical_rule_array_to_regex_ast(members, token_name, context),
      )
    IRRepeat(content) =>
      RegexAst::RegexRepeat(
        content=lexical_rule_to_regex_ast(content, token_name, context),
        min=0,
        max=None,
      )
    IRRepeat1(content) =>
      RegexAst::RegexRepeat(
        content=lexical_rule_to_regex_ast(content, token_name, context),
        min=1,
        max=None,
      )
    IRPrec(value~, content~)
    | IRPrecLeft(value~, content~)
    | IRPrecRight(value~, content~) => {
      match value {
        Number(precedence) => context.explicit_precedence = Some(precedence)
        Name(_) => ()
      }
      lexical_rule_to_regex_ast(content, token_name, context)
    }
    IRToken(content) => {
      context.main_token = true
      lexical_rule_to_regex_ast(content, token_name, context)
    }
    IRImmediateToken(content) => {
      context.main_token = true
      context.immediate = true
      lexical_rule_to_regex_ast(content, token_name, context)
    }
  }
}

///|
fn lexical_rule_array_to_regex_ast(
  rules : Array[InternedRule],
  token_name : String,
  context : TokenExpansionContext,
) -> Array[RegexAst] raise GenerateError {
  let result : Array[RegexAst] = []
  for rule in rules {
    result.push(lexical_rule_to_regex_ast(rule, token_name, context))
  }
  result
}

///|
fn string_to_regex_ast(value : String) -> RegexAst {
  let chars = value.to_array()
  if chars.length() == 0 {
    return RegexAst::RegexEmpty
  }
  if chars.length() == 1 {
    return RegexAst::RegexLiteral(chars[0].to_uint())
  }
  let items : Array[RegexAst] = []
  for char in chars {
    items.push(RegexAst::RegexLiteral(char.to_uint()))
  }
  RegexAst::RegexSeq(items)
}

///|
fn pattern_to_regex_ast(
  value : String,
  flags : String,
) -> RegexAst raise GenerateError {
  match parse_regex(value) {
    Err(message) => raise GenerateError::InvalidRegex(message)
    Ok(ast) =>
      if regex_flags_contains(flags, 'i') {
        regex_ast_case_insensitive(ast)
      } else {
        ast
      }
  }
}

///|
fn regex_flags_contains(flags : String, target : Char) -> Bool {
  for flag in flags.to_array() {
    if flag == target {
      return true
    }
  }
  false
}

///|
fn token_expanded_snapshot_weight(snapshot : TokenExpandedGrammar) -> Int {
  let mut weight = flattened_syntax_grammar_weight(snapshot.syntax)
  for variable in snapshot.lexical.variables {
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
  for separator in snapshot.lexical.separators {
    weight += nfa_weight(separator)
  }
  for token in snapshot.lexical.external_tokens {
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
fn flattened_syntax_grammar_weight(syntax : FlattenedSyntaxGrammar) -> Int {
  let mut weight = syntax.name.length()
  weight += optional_internal_symbol_weight(syntax.start_symbol)
  for variable in syntax.variables {
    weight += internal_symbol_weight(variable.symbol)
    weight += variable.name.length()
    weight += variable_kind_weight(variable.kind)
    for production in variable.productions {
      weight += flattened_production_weight(production)
    }
  }
  for symbol in syntax.extra_symbols {
    weight += internal_symbol_weight(symbol)
  }
  for token in syntax.external_tokens {
    weight += internal_symbol_weight(token.symbol)
    weight += token.name.length()
    weight += variable_kind_weight(token.kind)
    weight += optional_internal_symbol_weight(
      token.corresponding_internal_token,
    )
    weight += interned_rule_weight(token.rule)
  }
  for symbol in syntax.inline_symbols {
    weight += internal_symbol_weight(symbol)
  }
  for row in syntax.conflict_symbols {
    for symbol in row {
      weight += internal_symbol_weight(symbol)
    }
  }
  for row in syntax.precedence_orderings {
    for entry in row {
      weight += precedence_value_weight(entry)
    }
  }
  weight += optional_internal_symbol_weight(syntax.word_symbol)
  for set in syntax.reserved_sets {
    weight += set.name.length()
    for rule in set.rules {
      weight += interned_rule_weight(rule)
    }
  }
  for symbol in syntax.supertype_symbols {
    weight += internal_symbol_weight(symbol)
  }
  weight
}

///|
fn nfa_weight(nfa : Nfa) -> Int {
  let mut weight = nfa.start
  for state in nfa.states {
    weight += nfa_state_weight(state)
  }
  weight
}

///|
fn nfa_state_weight(state : NfaState) -> Int {
  match state {
    NfaAdvance(set, target, is_separator, precedence) => {
      let separator_weight = if is_separator { 1 } else { 0 }
      character_set_weight(set) + target + separator_weight + precedence
    }
    NfaSplit(targets) => {
      let mut weight = targets.length()
      for target in targets {
        weight += target
      }
      weight
    }
    NfaAccept(variable_index, precedence) => variable_index + precedence + 1
  }
}
