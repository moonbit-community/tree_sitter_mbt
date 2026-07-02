///|
pub(all) enum PrecedenceValue {
  Number(Int)
  Name(String)
} derive(Eq, Debug)

///|
pub(all) enum Rule {
  Alias(content~ : Rule, value~ : String, named~ : Bool)
  Blank
  String(String)
  Pattern(value~ : String, flags~ : String)
  Symbol(String)
  Seq(Array[Rule])
  Choice(Array[Rule])
  Repeat(Rule)
  Repeat1(Rule)
  Field(name~ : String, content~ : Rule)
  Prec(value~ : PrecedenceValue, content~ : Rule)
  PrecLeft(value~ : PrecedenceValue, content~ : Rule)
  PrecRight(value~ : PrecedenceValue, content~ : Rule)
  PrecDynamic(value~ : Int, content~ : Rule)
  Token(Rule)
  ImmediateToken(Rule)
  Reserved(context_name~ : String, content~ : Rule)
} derive(Eq, Debug)

///|
pub(all) struct NamedRule {
  name : String
  rule : Rule
} derive(Eq, Debug)

///|
pub(all) struct ReservedSet {
  name : String
  rules : Array[Rule]
} derive(Eq, Debug)

///|
pub(all) struct InputGrammar {
  name : String
  start_rule : String?
  rules : Array[NamedRule]
  extras : Array[Rule]
  externals : Array[Rule]
  inline : Array[String]
  conflicts : Array[Array[String]]
  precedences : Array[Array[PrecedenceValue]]
  word : String?
  reserved : Array[ReservedSet]
  supertypes : Array[String]
  inherits : String?
} derive(Eq, Debug)

///|
pub(all) suberror GrammarError {
  InvalidJson(String)
  ExpectedObject(String)
  ExpectedArray(String)
  ExpectedString(String)
  ExpectedBool(String)
  ExpectedNumber(String)
  MissingField(path~ : String, field~ : String)
  UnknownRuleType(path~ : String, rule_type~ : String)
  InvalidPrecedence(String)
  TokenContainsSymbol(path~ : String, symbol~ : String)
  EmptyStringExtra(String)
  UndeclaredReservedContext(String)
} derive(Eq, Debug)

///|
pub fn parse_grammar(grammar_json : String) -> InputGrammar raise GrammarError {
  let json = @json.parse(grammar_json[:]) catch {
    err => raise GrammarError::InvalidJson(err.to_string())
  }
  parse_input_grammar(json)
}

///|
fn parse_input_grammar(json : Json) -> InputGrammar raise GrammarError {
  let fields = expect_object(json, "$")
  let name = required_string_field(fields, "name", "$")
  let rules = required_named_rules_field(fields, "rules", "$")
  let start_rule = match rules.get(0) {
    Some(rule) => Some(rule.name)
    None => None
  }
  let reserved = reserved_sets_or_default(
    optional_reserved_sets_field(fields, "reserved", "$"),
  )
  let grammar = {
    name,
    start_rule,
    rules,
    extras: optional_rule_array_field(fields, "extras", "$", in_extra=true),
    externals: optional_rule_array_field(fields, "externals", "$"),
    inline: optional_string_array_field(fields, "inline", "$"),
    conflicts: optional_string_matrix_field(fields, "conflicts", "$"),
    precedences: optional_precedence_matrix_field(fields, "precedences", "$"),
    word: optional_string_field(fields, "word", "$"),
    reserved,
    supertypes: optional_string_array_field(fields, "supertypes", "$"),
    inherits: optional_string_field(fields, "inherits", "$"),
  }
  validate_reserved_contexts(grammar)
  normalize_input_grammar(grammar)
}

///|
fn parse_rule(json : Json, path : String) -> Rule raise GrammarError {
  let fields = expect_object(json, path)
  let rule_type = required_string_field(fields, "type", path)
  match rule_type {
    "ALIAS" =>
      Rule::Alias(
        content=parse_required_rule_field(fields, "content", path),
        value=required_string_field(fields, "value", path),
        named=required_bool_field(fields, "named", path),
      )
    "BLANK" => Rule::Blank
    "STRING" => Rule::String(required_string_field(fields, "value", path))
    "PATTERN" =>
      Rule::Pattern(
        value=required_string_field(fields, "value", path),
        flags=normalize_pattern_flags(
          optional_string_field(fields, "flags", path),
        ),
      )
    "SYMBOL" => Rule::Symbol(required_string_field(fields, "name", path))
    "SEQ" => Rule::Seq(required_rule_array_field(fields, "members", path))
    "CHOICE" => choice_rule(required_rule_array_field(fields, "members", path))
    "REPEAT" =>
      choice_rule([
        Rule::Repeat(parse_required_rule_field(fields, "content", path)),
        Rule::Blank,
      ])
    "REPEAT1" =>
      Rule::Repeat1(parse_required_rule_field(fields, "content", path))
    "FIELD" =>
      Rule::Field(
        name=required_string_field(fields, "name", path),
        content=parse_required_rule_field(fields, "content", path),
      )
    "PREC" =>
      Rule::Prec(
        value=parse_required_precedence_field(fields, "value", path),
        content=parse_required_rule_field(fields, "content", path),
      )
    "PREC_LEFT" =>
      Rule::PrecLeft(
        value=parse_required_precedence_field(fields, "value", path),
        content=parse_required_rule_field(fields, "content", path),
      )
    "PREC_RIGHT" =>
      Rule::PrecRight(
        value=parse_required_precedence_field(fields, "value", path),
        content=parse_required_rule_field(fields, "content", path),
      )
    "PREC_DYNAMIC" =>
      Rule::PrecDynamic(
        value=parse_required_int_field(fields, "value", path),
        content=parse_required_rule_field(fields, "content", path),
      )
    "TOKEN" => {
      let content = parse_required_rule_field(fields, "content", path)
      reject_symbol_in_token(content, path)
      Rule::Token(content)
    }
    "IMMEDIATE_TOKEN" => {
      let content = parse_required_rule_field(fields, "content", path)
      reject_symbol_in_token(content, path)
      Rule::ImmediateToken(content)
    }
    "RESERVED" =>
      Rule::Reserved(
        context_name=required_string_field(fields, "context_name", path),
        content=parse_required_rule_field(fields, "content", path),
      )
    _ => raise GrammarError::UnknownRuleType(path~, rule_type~)
  }
}

///|
fn choice_rule(members : Array[Rule]) -> Rule {
  let result = []
  for item in members {
    match item {
      Rule::Choice(nested) =>
        for nested_member in nested {
          push_unique_rule(result, nested_member)
        }
      _ => push_unique_rule(result, item)
    }
  }
  Rule::Choice(result)
}

///|
fn push_unique_rule(rules : Array[Rule], rule : Rule) -> Unit {
  for existing in rules {
    if existing == rule {
      return
    }
  }
  rules.push(rule)
}

///|
fn reject_symbol_in_token(
  rule : Rule,
  path : String,
) -> Unit raise GrammarError {
  match rule {
    Rule::Symbol(symbol) =>
      raise GrammarError::TokenContainsSymbol(path~, symbol~)
    Rule::Alias(content~, ..)
    | Rule::Repeat(content)
    | Rule::Repeat1(content)
    | Rule::Field(content~, ..)
    | Rule::Prec(content~, ..)
    | Rule::PrecLeft(content~, ..)
    | Rule::PrecRight(content~, ..)
    | Rule::PrecDynamic(content~, ..)
    | Rule::Token(content)
    | Rule::ImmediateToken(content)
    | Rule::Reserved(content~, ..) => reject_symbol_in_token(content, path)
    Rule::Seq(members) | Rule::Choice(members) =>
      for item in members {
        reject_symbol_in_token(item, path)
      }
    Rule::Blank | Rule::String(_) | Rule::Pattern(_) => ()
  }
}

///|
fn validate_reserved_contexts(
  grammar : InputGrammar,
) -> Unit raise GrammarError {
  let contexts = []
  for set in grammar.reserved {
    push_unique_string(contexts, set.name)
  }
  for named_rule in grammar.rules {
    validate_reserved_contexts_in_rule(named_rule.rule, contexts)
  }
  for rule in grammar.extras {
    validate_reserved_contexts_in_rule(rule, contexts)
  }
  for rule in grammar.externals {
    validate_reserved_contexts_in_rule(rule, contexts)
  }
  for set in grammar.reserved {
    for rule in set.rules {
      validate_reserved_contexts_in_rule(rule, contexts)
    }
  }
}

///|
fn validate_reserved_contexts_in_rule(
  rule : Rule,
  contexts : Array[String],
) -> Unit raise GrammarError {
  match rule {
    Rule::Reserved(context_name~, content~) => {
      if !contains_string(contexts, context_name) {
        raise GrammarError::UndeclaredReservedContext(context_name)
      }
      validate_reserved_contexts_in_rule(content, contexts)
    }
    Rule::Alias(content~, ..)
    | Rule::Repeat(content)
    | Rule::Repeat1(content)
    | Rule::Field(content~, ..)
    | Rule::Prec(content~, ..)
    | Rule::PrecLeft(content~, ..)
    | Rule::PrecRight(content~, ..)
    | Rule::PrecDynamic(content~, ..)
    | Rule::Token(content)
    | Rule::ImmediateToken(content) =>
      validate_reserved_contexts_in_rule(content, contexts)
    Rule::Seq(members) | Rule::Choice(members) =>
      for item in members {
        validate_reserved_contexts_in_rule(item, contexts)
      }
    Rule::Blank | Rule::String(_) | Rule::Pattern(_) | Rule::Symbol(_) => ()
  }
}

///|
fn normalize_input_grammar(grammar : InputGrammar) -> InputGrammar {
  let used = []
  match grammar.start_rule {
    Some(name) => push_unique_string(used, name)
    None => ()
  }
  match grammar.word {
    Some(name) => push_unique_string(used, name)
    None => ()
  }
  for rule in grammar.extras {
    collect_symbols(rule, symbols=used)
  }
  for rule in grammar.externals {
    collect_symbols(rule, symbols=used, include_top_symbol=false)
  }
  for set in grammar.reserved {
    for rule in set.rules {
      collect_symbols(rule, symbols=used)
    }
  }
  let mut changed = true
  while changed {
    changed = false
    let before = used.length()
    for named_rule in grammar.rules {
      if contains_string(used, named_rule.name) {
        collect_symbols(named_rule.rule, symbols=used)
      }
    }
    changed = used.length() != before
  }

  let surviving = []
  let normalized_rules = []
  for named_rule in grammar.rules {
    if contains_string(used, named_rule.name) {
      normalized_rules.push(named_rule)
      push_unique_string(surviving, named_rule.name)
    }
  }
  {
    name: grammar.name,
    start_rule: grammar.start_rule,
    rules: normalized_rules,
    extras: grammar.extras,
    externals: grammar.externals,
    inline: filter_strings(grammar.inline, surviving),
    conflicts: filter_conflicts(grammar.conflicts, surviving),
    precedences: grammar.precedences,
    word: if grammar.word is Some(name) && contains_string(surviving, name) {
      grammar.word
    } else {
      None
    },
    reserved: filter_reserved_sets(grammar.reserved, surviving),
    supertypes: filter_strings(grammar.supertypes, surviving),
    inherits: grammar.inherits,
  }
}

///|
fn collect_symbols(
  rule : Rule,
  symbols~ : Array[String],
  include_top_symbol? : Bool = true,
) -> Unit {
  match rule {
    Rule::Symbol(name) =>
      if include_top_symbol {
        push_unique_string(symbols, name)
      }
    Rule::Alias(content~, ..)
    | Rule::Repeat(content)
    | Rule::Repeat1(content)
    | Rule::Field(content~, ..)
    | Rule::Prec(content~, ..)
    | Rule::PrecLeft(content~, ..)
    | Rule::PrecRight(content~, ..)
    | Rule::PrecDynamic(content~, ..)
    | Rule::Token(content)
    | Rule::ImmediateToken(content)
    | Rule::Reserved(content~, ..) => collect_symbols(content, symbols~)
    Rule::Seq(members) | Rule::Choice(members) =>
      for item in members {
        collect_symbols(item, symbols~)
      }
    Rule::Blank | Rule::String(_) | Rule::Pattern(_) => ()
  }
}

///|
fn filter_strings(
  values : Array[String],
  surviving : Array[String],
) -> Array[String] {
  let result = []
  for value in values {
    if contains_string(surviving, value) {
      result.push(value)
    }
  }
  result
}

///|
fn filter_conflicts(
  conflicts : Array[Array[String]],
  surviving : Array[String],
) -> Array[Array[String]] {
  let result = []
  for conflict in conflicts {
    let kept = []
    for symbol in conflict {
      if contains_string(surviving, symbol) {
        kept.push(symbol)
      }
    }
    if !kept.is_empty() {
      result.push(kept)
    }
  }
  result
}

///|
fn filter_reserved_sets(
  sets : Array[ReservedSet],
  surviving : Array[String],
) -> Array[ReservedSet] {
  let result = []
  for set in sets {
    let rules = []
    for rule in set.rules {
      if !rule_references_missing_symbol(rule, surviving) {
        rules.push(rule)
      }
    }
    result.push({ name: set.name, rules })
  }
  result
}

///|
fn rule_references_missing_symbol(
  rule : Rule,
  surviving : Array[String],
) -> Bool {
  match rule {
    Rule::Symbol(name) => !contains_string(surviving, name)
    Rule::Alias(content~, ..)
    | Rule::Repeat(content)
    | Rule::Repeat1(content)
    | Rule::Field(content~, ..)
    | Rule::Prec(content~, ..)
    | Rule::PrecLeft(content~, ..)
    | Rule::PrecRight(content~, ..)
    | Rule::PrecDynamic(content~, ..)
    | Rule::Token(content)
    | Rule::ImmediateToken(content)
    | Rule::Reserved(content~, ..) =>
      rule_references_missing_symbol(content, surviving)
    Rule::Seq(members) | Rule::Choice(members) => {
      for item in members {
        if rule_references_missing_symbol(item, surviving) {
          return true
        }
      }
      false
    }
    Rule::Blank | Rule::String(_) | Rule::Pattern(_) => false
  }
}

///|
fn push_unique_string(values : Array[String], value : String) -> Unit {
  if !contains_string(values, value) {
    values.push(value)
  }
}

///|
fn contains_string(values : Array[String], value : String) -> Bool {
  for existing in values {
    if existing == value {
      return true
    }
  }
  false
}

///|
fn expect_object(
  json : Json,
  path : String,
) -> Map[String, Json] raise GrammarError {
  match json {
    Json::Object(fields) => fields
    _ => raise GrammarError::ExpectedObject(path)
  }
}

///|
fn expect_array(json : Json, path : String) -> Array[Json] raise GrammarError {
  match json {
    Json::Array(items) => items
    _ => raise GrammarError::ExpectedArray(path)
  }
}

///|
fn expect_string(json : Json, path : String) -> String raise GrammarError {
  match json {
    Json::String(value) => value
    _ => raise GrammarError::ExpectedString(path)
  }
}

///|
fn expect_bool(json : Json, path : String) -> Bool raise GrammarError {
  match json {
    Json::True => true
    Json::False => false
    _ => raise GrammarError::ExpectedBool(path)
  }
}

///|
fn expect_int(json : Json, path : String) -> Int raise GrammarError {
  match json {
    Json::Number(value, ..) => {
      let integer = value.to_int()
      if Double::from_int(integer) == value {
        integer
      } else {
        raise GrammarError::ExpectedNumber(path)
      }
    }
    _ => raise GrammarError::ExpectedNumber(path)
  }
}

///|
fn expect_precedence(
  json : Json,
  path : String,
) -> PrecedenceValue raise GrammarError {
  match json {
    Json::String(value) => PrecedenceValue::Name(value)
    Json::Number(value, ..) => {
      let integer = value.to_int()
      if Double::from_int(integer) == value {
        PrecedenceValue::Number(integer)
      } else {
        raise GrammarError::InvalidPrecedence(path)
      }
    }
    Json::Object(fields) =>
      match required_string_field(fields, "type", path) {
        "SYMBOL" =>
          PrecedenceValue::Name(required_string_field(fields, "name", path))
        "STRING" =>
          PrecedenceValue::Name(required_string_field(fields, "value", path))
        _ => raise GrammarError::InvalidPrecedence(path)
      }
    _ => raise GrammarError::InvalidPrecedence(path)
  }
}

///|
fn required_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> Json raise GrammarError {
  match fields.get(name) {
    Some(value) => value
    None => raise GrammarError::MissingField(path~, field=name)
  }
}

///|
fn optional_string_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> String? raise GrammarError {
  match fields.get(name) {
    Some(value) => Some(expect_string(value, path_key(path, name)))
    None => None
  }
}

///|
fn required_string_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> String raise GrammarError {
  expect_string(required_field(fields, name, path), path_key(path, name))
}

///|
fn required_bool_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> Bool raise GrammarError {
  expect_bool(required_field(fields, name, path), path_key(path, name))
}

///|
fn parse_required_int_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> Int raise GrammarError {
  expect_int(required_field(fields, name, path), path_key(path, name))
}

///|
fn parse_required_precedence_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> PrecedenceValue raise GrammarError {
  expect_precedence(required_field(fields, name, path), path_key(path, name))
}

///|
fn parse_required_rule_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> Rule raise GrammarError {
  parse_rule(required_field(fields, name, path), path_key(path, name))
}

///|
fn required_rule_array_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> Array[Rule] raise GrammarError {
  parse_rule_array(required_field(fields, name, path), path_key(path, name))
}

///|
fn optional_rule_array_field(
  fields : Map[String, Json],
  name : String,
  path : String,
  in_extra? : Bool = false,
) -> Array[Rule] raise GrammarError {
  match fields.get(name) {
    Some(value) => parse_rule_array(value, path_key(path, name), in_extra~)
    None => []
  }
}

///|
fn parse_rule_array(
  json : Json,
  path : String,
  in_extra? : Bool = false,
) -> Array[Rule] raise GrammarError {
  let items = expect_array(json, path)
  let result = []
  for i in 0..<items.length() {
    let rule = parse_rule(items[i], path_index(path, i))
    if in_extra {
      reject_empty_string_extra(rule, path_index(path, i))
    }
    result.push(rule)
  }
  result
}

///|
fn reject_empty_string_extra(
  rule : Rule,
  path : String,
) -> Unit raise GrammarError {
  match rule {
    Rule::String("") => raise GrammarError::EmptyStringExtra(path)
    _ => ()
  }
}

///|
fn required_named_rules_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> Array[NamedRule] raise GrammarError {
  let rules_object = expect_object(
    required_field(fields, name, path),
    path_key(path, name),
  )
  let result = []
  for rule_name, rule_json in rules_object {
    result.push({
      name: rule_name,
      rule: parse_rule(rule_json, path_key(path_key(path, name), rule_name)),
    })
  }
  result
}

///|
fn optional_string_array_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> Array[String] raise GrammarError {
  match fields.get(name) {
    Some(value) => parse_string_array(value, path_key(path, name))
    None => []
  }
}

///|
fn parse_string_array(
  json : Json,
  path : String,
) -> Array[String] raise GrammarError {
  let items = expect_array(json, path)
  let result = []
  for i in 0..<items.length() {
    result.push(expect_string(items[i], path_index(path, i)))
  }
  result
}

///|
fn optional_string_matrix_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> Array[Array[String]] raise GrammarError {
  match fields.get(name) {
    Some(value) => {
      let rows = expect_array(value, path_key(path, name))
      let result = []
      for i in 0..<rows.length() {
        result.push(
          parse_string_array(rows[i], path_index(path_key(path, name), i)),
        )
      }
      result
    }
    None => []
  }
}

///|
fn optional_precedence_matrix_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> Array[Array[PrecedenceValue]] raise GrammarError {
  match fields.get(name) {
    Some(value) => {
      let rows = expect_array(value, path_key(path, name))
      let result = []
      for i in 0..<rows.length() {
        let row_path = path_index(path_key(path, name), i)
        let row = expect_array(rows[i], row_path)
        let entries = []
        for j in 0..<row.length() {
          entries.push(expect_precedence(row[j], path_index(row_path, j)))
        }
        result.push(entries)
      }
      result
    }
    None => []
  }
}

///|
fn optional_reserved_sets_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> Array[ReservedSet] raise GrammarError {
  match fields.get(name) {
    Some(value) => {
      let reserved_object = expect_object(value, path_key(path, name))
      let result = []
      for set_name, set_json in reserved_object {
        result.push({
          name: set_name,
          rules: parse_rule_array(
            set_json,
            path_key(path_key(path, name), set_name),
          ),
        })
      }
      result
    }
    None => []
  }
}

///|
fn reserved_sets_or_default(sets : Array[ReservedSet]) -> Array[ReservedSet] {
  if sets.is_empty() {
    [{ name: "", rules: [] }]
  } else {
    sets
  }
}

///|
fn normalize_pattern_flags(flags : String?) -> String {
  match flags {
    Some(value) => value
    None => ""
  }
}

///|
fn path_key(path : String, key : String) -> String {
  "\{path}.\{key}"
}

///|
fn path_index(path : String, index : Int) -> String {
  "\{path}[\{index}]"
}
