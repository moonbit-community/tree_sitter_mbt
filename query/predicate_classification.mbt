///|
pub(all) suberror QueryPredicateError {
  Predicate(
    pattern_index~ : Int,
    byte_offset~ : Int,
    operator~ : String,
    reason~ : String
  )
}

///|
pub(all) enum QueryPredicateArg {
  ArgCapture(Int)
  ArgString(String)
} derive(Eq, Debug)

///|
pub(all) enum QueryTextPredicateKind {
  TextEq
  TextNotEq
  TextAnyEq
  TextAnyNotEq
  TextMatch
  TextNotMatch
  TextAnyMatch
  TextAnyNotMatch
  TextAnyOf
  TextNotAnyOf
} derive(Eq, Debug)

///|
pub(all) struct QueryTextPredicate {
  pattern_index : Int
  byte_offset : Int
  kind : QueryTextPredicateKind
  capture_id : Int
  args : Array[QueryPredicateArg]
} derive(Eq, Debug)

///|
pub(all) struct QueryPropertySetting {
  pattern_index : Int
  byte_offset : Int
  key : String
  value : String?
  capture_id : Int?
} derive(Eq, Debug)

///|
pub(all) struct QueryPropertyAssertion {
  pattern_index : Int
  byte_offset : Int
  is_positive : Bool
  key : String
  value : String?
  capture_id : Int?
} derive(Eq, Debug)

///|
pub(all) struct QueryGeneralPredicate {
  pattern_index : Int
  byte_offset : Int
  operator : String
  args : Array[QueryPredicateArg]
} derive(Eq, Debug)

///|
pub(all) struct QueryPredicateClasses {
  text_predicates : Array[QueryTextPredicate]
  property_settings : Array[QueryPropertySetting]
  property_assertions : Array[QueryPropertyAssertion]
  general_predicates : Array[QueryGeneralPredicate]
} derive(Eq, Debug)

///|
priv struct QueryRawPredicate {
  pattern_index : Int
  byte_offset : Int
  operator : String
  args : Array[QueryPredicateArg]
}

///|
pub fn Query::classify_predicates(
  self : Query,
) -> QueryPredicateClasses raise QueryPredicateError {
  let result = QueryPredicateClasses::{
    text_predicates: [],
    property_settings: [],
    property_assertions: [],
    general_predicates: [],
  }
  for pattern_index in 0..<self.patterns.length() {
    for
      predicate in self.raw_predicates_for_pattern(
        pattern_index,
        self.patterns[pattern_index],
      ) {
      query_classify_raw_predicate(predicate, result~)
    }
  }
  result
}

///|
fn query_classify_raw_predicate(
  predicate : QueryRawPredicate,
  result~ : QueryPredicateClasses,
) -> Unit raise QueryPredicateError {
  match query_text_predicate_kind(predicate.operator) {
    Some(kind) =>
      result.text_predicates.push(
        query_classify_text_predicate(predicate, kind),
      )
    None =>
      match predicate.operator {
        "set!" =>
          result.property_settings.push(
            query_classify_property_setting(predicate),
          )
        "is?" =>
          result.property_assertions.push(
            query_classify_property_assertion(predicate, is_positive=true),
          )
        "is-not?" =>
          result.property_assertions.push(
            query_classify_property_assertion(predicate, is_positive=false),
          )
        _ =>
          result.general_predicates.push(QueryGeneralPredicate::{
            pattern_index: predicate.pattern_index,
            byte_offset: predicate.byte_offset,
            operator: predicate.operator,
            args: predicate.args,
          })
      }
  }
}

///|
fn Query::raw_predicates_for_pattern(
  self : Query,
  pattern_index : Int,
  pattern : QueryPattern,
) -> Array[QueryRawPredicate] raise QueryPredicateError {
  let result : Array[QueryRawPredicate] = []
  let steps = pattern.predicate_steps
  let mut index = 0
  while index < steps.length() {
    let operator_offset = query_predicate_step_offset(pattern, index)
    let operator = match steps[index] {
      String(id) =>
        self.predicate_string(
          id,
          pattern_index~,
          byte_offset=operator_offset,
          operator="<predicate>",
        )
      _ =>
        raise QueryPredicateError::Predicate(
          pattern_index~,
          byte_offset=operator_offset,
          operator="<predicate>",
          reason="predicate must start with an operator",
        )
    }
    index += 1
    let args : Array[QueryPredicateArg] = []
    while index < steps.length() && !(steps[index] is Done) {
      match steps[index] {
        Capture(id) => args.push(ArgCapture(id))
        String(id) => {
          let arg_offset = query_predicate_step_offset(pattern, index)
          args.push(
            ArgString(
              self.predicate_string(
                id,
                pattern_index~,
                byte_offset=arg_offset,
                operator~,
              ),
            ),
          )
        }
        Done => ()
      }
      index += 1
    }
    if index >= steps.length() {
      raise QueryPredicateError::Predicate(
        pattern_index~,
        byte_offset=operator_offset,
        operator~,
        reason="unterminated predicate",
      )
    }
    index += 1
    result.push(QueryRawPredicate::{
      pattern_index,
      byte_offset: operator_offset,
      operator,
      args,
    })
  }
  result
}

///|
fn query_predicate_step_offset(pattern : QueryPattern, index : Int) -> Int {
  pattern.predicate_step_offsets.get(index).unwrap_or(pattern.start_byte)
}

///|
fn Query::predicate_string(
  self : Query,
  id : Int,
  pattern_index~ : Int,
  byte_offset~ : Int,
  operator~ : String,
) -> String raise QueryPredicateError {
  match self.string_values.get(id) {
    Some(value) => value
    None =>
      raise QueryPredicateError::Predicate(
        pattern_index~,
        byte_offset~,
        operator~,
        reason="predicate references an unknown string",
      )
  }
}

///|
fn query_text_predicate_kind(operator : String) -> QueryTextPredicateKind? {
  match operator {
    "eq?" => Some(TextEq)
    "not-eq?" => Some(TextNotEq)
    "any-eq?" => Some(TextAnyEq)
    "any-not-eq?" => Some(TextAnyNotEq)
    "match?" => Some(TextMatch)
    "not-match?" => Some(TextNotMatch)
    "any-match?" => Some(TextAnyMatch)
    "any-not-match?" => Some(TextAnyNotMatch)
    "any-of?" => Some(TextAnyOf)
    "not-any-of?" => Some(TextNotAnyOf)
    _ => None
  }
}

///|
fn query_classify_text_predicate(
  predicate : QueryRawPredicate,
  kind : QueryTextPredicateKind,
) -> QueryTextPredicate raise QueryPredicateError {
  let capture_id = query_expect_capture_arg(predicate, 0)
  let args : Array[QueryPredicateArg] = []
  match kind {
    TextAnyOf | TextNotAnyOf => {
      if predicate.args.length() < 2 {
        query_raise_predicate_error(
          predicate, "text predicate expects a capture and at least one string",
        )
      }
      for i in 1..<predicate.args.length() {
        args.push(ArgString(query_expect_string_arg(predicate, i)))
      }
    }
    TextMatch | TextNotMatch | TextAnyMatch | TextAnyNotMatch => {
      query_expect_exact_arg_count(predicate, 2)
      let regex = query_expect_string_arg(predicate, 1)
      query_validate_regex_pattern(predicate, regex)
      args.push(ArgString(regex))
    }
    _ => {
      query_expect_exact_arg_count(predicate, 2)
      match predicate.args[1] {
        ArgCapture(id) => args.push(ArgCapture(id))
        ArgString(value) => args.push(ArgString(value))
      }
    }
  }
  QueryTextPredicate::{
    pattern_index: predicate.pattern_index,
    byte_offset: predicate.byte_offset,
    kind,
    capture_id,
    args,
  }
}

///|
fn query_classify_property_setting(
  predicate : QueryRawPredicate,
) -> QueryPropertySetting raise QueryPredicateError {
  let (key, value, capture_id) = query_classify_property_args(predicate)
  QueryPropertySetting::{
    pattern_index: predicate.pattern_index,
    byte_offset: predicate.byte_offset,
    key,
    value,
    capture_id,
  }
}

///|
fn query_classify_property_assertion(
  predicate : QueryRawPredicate,
  is_positive~ : Bool,
) -> QueryPropertyAssertion raise QueryPredicateError {
  let (key, value, capture_id) = query_classify_property_args(predicate)
  QueryPropertyAssertion::{
    pattern_index: predicate.pattern_index,
    byte_offset: predicate.byte_offset,
    is_positive,
    key,
    value,
    capture_id,
  }
}

///|
fn query_classify_property_args(
  predicate : QueryRawPredicate,
) -> (String, String?, Int?) raise QueryPredicateError {
  if predicate.args.length() < 1 || predicate.args.length() > 3 {
    query_raise_predicate_error(
      predicate, "property predicate expects one to three arguments",
    )
  }
  let mut key : String? = None
  let mut value : String? = None
  let mut capture_id : Int? = None
  for arg in predicate.args {
    match arg {
      ArgCapture(id) =>
        if capture_id is Some(_) {
          query_raise_predicate_error(
            predicate, "property predicate accepts at most one capture",
          )
        } else {
          capture_id = Some(id)
        }
      ArgString(text) =>
        if key is None {
          key = Some(text)
        } else if value is None {
          value = Some(text)
        } else {
          query_raise_predicate_error(
            predicate, "property predicate accepts at most one value",
          )
        }
    }
  }
  match key {
    Some(key) => (key, value, capture_id)
    None =>
      query_raise_predicate_error(
        predicate, "property predicate key is required",
      )
  }
}

///|
fn query_expect_exact_arg_count(
  predicate : QueryRawPredicate,
  expected : Int,
) -> Unit raise QueryPredicateError {
  if predicate.args.length() != expected {
    query_raise_predicate_error(predicate, "expected \{expected} arguments")
  }
}

///|
fn query_expect_capture_arg(
  predicate : QueryRawPredicate,
  index : Int,
) -> Int raise QueryPredicateError {
  match predicate.args.get(index) {
    Some(ArgCapture(id)) => id
    _ => query_raise_predicate_error(predicate, "expected capture argument")
  }
}

///|
fn query_expect_string_arg(
  predicate : QueryRawPredicate,
  index : Int,
) -> String raise QueryPredicateError {
  match predicate.args.get(index) {
    Some(ArgString(value)) => value
    _ => query_raise_predicate_error(predicate, "expected string argument")
  }
}

///|
fn query_validate_regex_pattern(
  predicate : QueryRawPredicate,
  regex : String,
) -> Unit raise QueryPredicateError {
  if regex.is_empty() {
    query_raise_predicate_error(predicate, "regex must not be empty")
  }
  let normalized = query_normalize_text_regex(regex)
  let _ = Regex(normalized[:]) catch {
    _ => query_raise_predicate_error(predicate, "invalid regex")
  }
}

///|
fn query_normalize_text_regex(regex : String) -> String {
  let builder = StringBuilder::new()
  let mut escaped = false
  for offset = 0; offset < regex.length(); {
    match regex.get_char(offset) {
      Some(ch) => {
        if escaped {
          query_write_regex_escape(builder, ch)
          escaped = false
        } else if ch == '\\' {
          escaped = true
        } else if ch == '[' {
          let (normalized_class, next_offset) = query_normalize_regex_class(
            regex, offset,
          )
          builder.write_string(normalized_class)
          continue next_offset
        } else {
          builder.write_char(ch)
        }
        continue offset + ch.utf16_len()
      }
      None => break
    }
  }
  if escaped {
    builder.write_char('\\')
  }
  builder.to_string()
}

///|
fn query_normalize_regex_class(regex : String, start : Int) -> (String, Int) {
  let class_builder = StringBuilder::new()
  let complements : Array[String] = []
  let mut has_positive_atom = false
  let mut escaped = false
  let mut offset = start + 1
  class_builder.write_char('[')
  while offset < regex.length() {
    guard regex.get_char(offset) is Some(ch) else { break }
    if escaped {
      match query_regex_class_complement_escape(ch) {
        Some(complement) => complements.push(complement)
        None => {
          query_write_regex_class_escape(class_builder, ch)
          has_positive_atom = true
        }
      }
      escaped = false
    } else if ch == '\\' {
      escaped = true
    } else if ch == ']' {
      class_builder.write_char(']')
      let next_offset = offset + ch.utf16_len()
      if complements.is_empty() {
        return (class_builder.to_string(), next_offset)
      }
      return (
        query_join_regex_class_complements(
          complements,
          class_builder.to_string(),
          has_positive_atom~,
        ),
        next_offset,
      )
    } else {
      class_builder.write_char(ch)
      has_positive_atom = true
    }
    offset += ch.utf16_len()
  }
  if escaped {
    class_builder.write_char('\\')
    has_positive_atom = true
  }
  (class_builder.to_string(), offset)
}

///|
fn query_join_regex_class_complements(
  complements : Array[String],
  positive_class : String,
  has_positive_atom~ : Bool,
) -> String {
  if complements.length() == 1 && !has_positive_atom {
    return complements[0]
  }
  let builder = StringBuilder::new()
  builder.write_char('(')
  let mut first = true
  for complement in complements {
    if !first {
      builder.write_char('|')
    }
    builder.write_string(complement)
    first = false
  }
  if has_positive_atom {
    if !first {
      builder.write_char('|')
    }
    builder.write_string(positive_class)
  }
  builder.write_char(')')
  builder.to_string()
}

///|
fn query_write_regex_escape(builder : StringBuilder, ch : Char) -> Unit {
  match ch {
    'A' => builder.write_char('^')
    'd' => builder.write_string("[[:digit:]]")
    'D' => builder.write_string("[^[:digit:]]")
    's' => builder.write_string("[[:space:]]")
    'S' => builder.write_string("[^[:space:]]")
    'w' => builder.write_string("[[:word:]]")
    'W' => builder.write_string("[^[:word:]]")
    'z' => builder.write_char('$')
    _ => {
      builder.write_char('\\')
      builder.write_char(ch)
    }
  }
}

///|
fn query_regex_class_complement_escape(ch : Char) -> String? {
  match ch {
    'D' => Some("[^[:digit:]]")
    'S' => Some("[^[:space:]]")
    'W' => Some("[^[:word:]]")
    _ => None
  }
}

///|
fn query_write_regex_class_escape(builder : StringBuilder, ch : Char) -> Unit {
  match ch {
    'd' => builder.write_string("[:digit:]")
    's' => builder.write_string("[:space:]")
    'w' => builder.write_string("[:word:]")
    _ => {
      builder.write_char('\\')
      builder.write_char(ch)
    }
  }
}

///|
fn[T] query_raise_predicate_error(
  predicate : QueryRawPredicate,
  reason : String,
) -> T raise QueryPredicateError {
  raise QueryPredicateError::Predicate(
    pattern_index=predicate.pattern_index,
    byte_offset=predicate.byte_offset,
    operator=predicate.operator,
    reason~,
  )
}
