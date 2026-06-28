///|
pub fn Query::text_predicates_match_bytes(
  self : Query,
  matched : QueryMatch,
  source : Bytes,
) -> Bool raise QueryPredicateError {
  let classes = self.classify_predicates()
  for predicate in classes.text_predicates {
    if predicate.pattern_index == matched.pattern_index &&
      !query_text_predicate_matches(predicate, matched, source) {
      return false
    }
  }
  true
}

///|
pub fn Query::text_predicates_match_string(
  self : Query,
  matched : QueryMatch,
  source : String,
) -> Bool raise QueryPredicateError {
  self.text_predicates_match_bytes(matched, @utf8.encode(source))
}

///|
pub fn QueryCursor::next_match_with_text_predicates_bytes(
  self : QueryCursor,
  query : Query,
  source : Bytes,
) -> QueryMatch? raise QueryPredicateError {
  while true {
    match self.next_match() {
      Some(matched) =>
        if query.text_predicates_match_bytes(matched, source) {
          return Some(matched)
        } else {
          self.remove_match(matched.id)
        }
      None => return None
    }
  }
  None
}

///|
pub fn QueryCursor::next_match_with_text_predicates_string(
  self : QueryCursor,
  query : Query,
  source : String,
) -> QueryMatch? raise QueryPredicateError {
  self.next_match_with_text_predicates_bytes(query, @utf8.encode(source))
}

///|
pub fn QueryCursor::next_capture_with_text_predicates_bytes(
  self : QueryCursor,
  query : Query,
  source : Bytes,
) -> QueryCapture? raise QueryPredicateError {
  while true {
    match self.next_capture() {
      Some(capture) =>
        match self.match_with_id(capture.match_id) {
          Some(matched) =>
            if query.text_predicates_match_bytes(matched, source) {
              return Some(capture)
            } else {
              self.remove_match(matched.id)
            }
          None => ()
        }
      None => return None
    }
  }
  None
}

///|
pub fn QueryCursor::next_capture_with_text_predicates_string(
  self : QueryCursor,
  query : Query,
  source : String,
) -> QueryCapture? raise QueryPredicateError {
  self.next_capture_with_text_predicates_bytes(query, @utf8.encode(source))
}

///|
fn QueryCursor::match_with_id(
  self : QueryCursor,
  match_id : Int,
) -> QueryMatch? {
  for matched in self.matches {
    if matched.id == match_id {
      return Some(matched)
    }
  }
  None
}

///|
fn query_text_predicate_matches(
  predicate : QueryTextPredicate,
  matched : QueryMatch,
  source : Bytes,
) -> Bool raise QueryPredicateError {
  let captures = query_captures_for_id(matched, predicate.capture_id)
  match predicate.kind {
    TextEq => query_all_captures_equal_arg(captures, predicate, matched, source)
    TextNotEq =>
      query_all_captures_not_equal_arg(captures, predicate, matched, source)
    TextAnyEq =>
      query_any_capture_equals_arg(captures, predicate, matched, source)
    TextAnyNotEq =>
      query_any_capture_not_equal_arg(captures, predicate, matched, source)
    TextMatch => query_all_captures_match_regex(captures, predicate, source)
    TextNotMatch =>
      query_all_captures_not_match_regex(captures, predicate, source)
    TextAnyMatch => query_any_capture_matches_regex(captures, predicate, source)
    TextAnyNotMatch =>
      query_any_capture_not_matches_regex(captures, predicate, source)
    TextAnyOf =>
      query_all_captures_are_in_string_set(captures, predicate, source)
    TextNotAnyOf =>
      query_all_captures_are_not_in_string_set(captures, predicate, source)
  }
}

///|
fn query_captures_for_id(
  matched : QueryMatch,
  capture_id : Int,
) -> Array[QueryCapture] {
  let result : Array[QueryCapture] = []
  for capture in matched.captures {
    if capture.index == capture_id {
      result.push(capture)
    }
  }
  result
}

///|
fn query_all_captures_equal_arg(
  captures : Array[QueryCapture],
  predicate : QueryTextPredicate,
  matched : QueryMatch,
  source : Bytes,
) -> Bool raise QueryPredicateError {
  let arg = query_first_text_predicate_arg(predicate)
  if arg is ArgCapture(id) {
    return query_all_capture_pairs_equal(
      captures,
      query_captures_for_id(matched, id),
      source,
      predicate,
    )
  }
  for capture in captures {
    if !query_capture_text_equals_arg(capture, arg, predicate, matched, source) {
      return false
    }
  }
  true
}

///|
fn query_all_captures_not_equal_arg(
  captures : Array[QueryCapture],
  predicate : QueryTextPredicate,
  matched : QueryMatch,
  source : Bytes,
) -> Bool raise QueryPredicateError {
  let arg = query_first_text_predicate_arg(predicate)
  if arg is ArgCapture(id) {
    return query_all_capture_pairs_not_equal(
      captures,
      query_captures_for_id(matched, id),
      source,
      predicate,
    )
  }
  for capture in captures {
    if query_capture_text_equals_arg(capture, arg, predicate, matched, source) {
      return false
    }
  }
  true
}

///|
fn query_any_capture_equals_arg(
  captures : Array[QueryCapture],
  predicate : QueryTextPredicate,
  matched : QueryMatch,
  source : Bytes,
) -> Bool raise QueryPredicateError {
  let arg = query_first_text_predicate_arg(predicate)
  if arg is ArgCapture(id) {
    return query_any_capture_pair_equals(
      captures,
      query_captures_for_id(matched, id),
      source,
      predicate,
    )
  }
  for capture in captures {
    if query_capture_text_equals_arg(capture, arg, predicate, matched, source) {
      return true
    }
  }
  false
}

///|
fn query_any_capture_not_equal_arg(
  captures : Array[QueryCapture],
  predicate : QueryTextPredicate,
  matched : QueryMatch,
  source : Bytes,
) -> Bool raise QueryPredicateError {
  let arg = query_first_text_predicate_arg(predicate)
  if arg is ArgCapture(id) {
    return query_any_capture_pair_not_equal(
      captures,
      query_captures_for_id(matched, id),
      source,
      predicate,
    )
  }
  for capture in captures {
    if !query_capture_text_equals_arg(capture, arg, predicate, matched, source) {
      return true
    }
  }
  false
}

///|
fn query_capture_text_equals_arg(
  capture : QueryCapture,
  arg : QueryPredicateArg,
  predicate : QueryTextPredicate,
  matched : QueryMatch,
  source : Bytes,
) -> Bool raise QueryPredicateError {
  match arg {
    ArgString(value) =>
      query_capture_text_equals_string(capture, source, value, predicate)
    ArgCapture(id) => {
      let others = query_captures_for_id(matched, id)
      for other in others {
        if query_capture_text_equals_capture(capture, other, source, predicate) {
          return true
        }
      }
      false
    }
  }
}

///|
fn query_all_capture_pairs_equal(
  left : Array[QueryCapture],
  right : Array[QueryCapture],
  source : Bytes,
  predicate : QueryTextPredicate,
) -> Bool raise QueryPredicateError {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if !query_capture_text_equals_capture(left[i], right[i], source, predicate) {
      return false
    }
  }
  true
}

///|
fn query_all_capture_pairs_not_equal(
  left : Array[QueryCapture],
  right : Array[QueryCapture],
  source : Bytes,
  predicate : QueryTextPredicate,
) -> Bool raise QueryPredicateError {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if query_capture_text_equals_capture(left[i], right[i], source, predicate) {
      return false
    }
  }
  true
}

///|
fn query_any_capture_pair_equals(
  left : Array[QueryCapture],
  right : Array[QueryCapture],
  source : Bytes,
  predicate : QueryTextPredicate,
) -> Bool raise QueryPredicateError {
  let pair_count = query_min_int(left.length(), right.length())
  for i in 0..<pair_count {
    if query_capture_text_equals_capture(left[i], right[i], source, predicate) {
      return true
    }
  }
  false
}

///|
fn query_any_capture_pair_not_equal(
  left : Array[QueryCapture],
  right : Array[QueryCapture],
  source : Bytes,
  predicate : QueryTextPredicate,
) -> Bool raise QueryPredicateError {
  let pair_count = query_min_int(left.length(), right.length())
  for i in 0..<pair_count {
    if !query_capture_text_equals_capture(left[i], right[i], source, predicate) {
      return true
    }
  }
  false
}

///|
fn query_all_captures_match_regex(
  captures : Array[QueryCapture],
  predicate : QueryTextPredicate,
  source : Bytes,
) -> Bool raise QueryPredicateError {
  let regex = query_first_regex_arg(predicate)
  for capture in captures {
    if !query_capture_text_matches_regex(capture, source, regex, predicate) {
      return false
    }
  }
  true
}

///|
fn query_all_captures_not_match_regex(
  captures : Array[QueryCapture],
  predicate : QueryTextPredicate,
  source : Bytes,
) -> Bool raise QueryPredicateError {
  let regex = query_first_regex_arg(predicate)
  for capture in captures {
    if query_capture_text_matches_regex(capture, source, regex, predicate) {
      return false
    }
  }
  true
}

///|
fn query_any_capture_matches_regex(
  captures : Array[QueryCapture],
  predicate : QueryTextPredicate,
  source : Bytes,
) -> Bool raise QueryPredicateError {
  let regex = query_first_regex_arg(predicate)
  for capture in captures {
    if query_capture_text_matches_regex(capture, source, regex, predicate) {
      return true
    }
  }
  false
}

///|
fn query_any_capture_not_matches_regex(
  captures : Array[QueryCapture],
  predicate : QueryTextPredicate,
  source : Bytes,
) -> Bool raise QueryPredicateError {
  let regex = query_first_regex_arg(predicate)
  for capture in captures {
    if !query_capture_text_matches_regex(capture, source, regex, predicate) {
      return true
    }
  }
  false
}

///|
fn query_all_captures_are_in_string_set(
  captures : Array[QueryCapture],
  predicate : QueryTextPredicate,
  source : Bytes,
) -> Bool raise QueryPredicateError {
  for capture in captures {
    if !query_capture_text_is_in_string_set(capture, source, predicate) {
      return false
    }
  }
  true
}

///|
fn query_all_captures_are_not_in_string_set(
  captures : Array[QueryCapture],
  predicate : QueryTextPredicate,
  source : Bytes,
) -> Bool raise QueryPredicateError {
  for capture in captures {
    if query_capture_text_is_in_string_set(capture, source, predicate) {
      return false
    }
  }
  true
}

///|
fn query_capture_text_is_in_string_set(
  capture : QueryCapture,
  source : Bytes,
  predicate : QueryTextPredicate,
) -> Bool raise QueryPredicateError {
  for arg in predicate.args {
    match arg {
      ArgString(value) =>
        if query_capture_text_equals_string(capture, source, value, predicate) {
          return true
        }
      ArgCapture(_) =>
        query_raise_text_predicate_error(
          predicate, "string set predicate expects only string arguments",
        )
    }
  }
  false
}

///|
fn query_first_text_predicate_arg(
  predicate : QueryTextPredicate,
) -> QueryPredicateArg raise QueryPredicateError {
  match predicate.args.get(0) {
    Some(arg) => arg
    None =>
      query_raise_text_predicate_error(predicate, "missing predicate argument")
  }
}

///|
fn query_first_regex_arg(
  predicate : QueryTextPredicate,
) -> String raise QueryPredicateError {
  match query_first_text_predicate_arg(predicate) {
    ArgString(value) => value
    ArgCapture(_) =>
      query_raise_text_predicate_error(
        predicate, "regex predicate expects a string argument",
      )
  }
}

///|
fn query_capture_text_equals_string(
  capture : QueryCapture,
  source : Bytes,
  value : String,
  predicate : QueryTextPredicate,
) -> Bool raise QueryPredicateError {
  query_capture_text_view(capture, source, predicate).equal_to_bytes(
    @utf8.encode(value),
  )
}

///|
fn query_capture_text_equals_capture(
  left : QueryCapture,
  right : QueryCapture,
  source : Bytes,
  predicate : QueryTextPredicate,
) -> Bool raise QueryPredicateError {
  query_capture_text_view(left, source, predicate) ==
  query_capture_text_view(right, source, predicate)
}

///|
fn query_capture_text_matches_regex(
  capture : QueryCapture,
  source : Bytes,
  regex : String,
  predicate : QueryTextPredicate,
) -> Bool raise QueryPredicateError {
  let text = query_capture_text_view(capture, source, predicate)
  let normalized = query_normalize_text_regex(regex)
  let compiled = Regex(normalized[:]) catch {
    _ => query_raise_text_predicate_error(predicate, "invalid regex")
  }
  let decoded = @utf8.decode(text) catch {
    _ =>
      query_raise_text_predicate_error(
        predicate, "capture text is not valid utf8",
      )
  }
  compiled.execute(decoded[:]) is Some(_)
}

///|
fn query_capture_text_view(
  capture : QueryCapture,
  source : Bytes,
  predicate : QueryTextPredicate,
) -> BytesView raise QueryPredicateError {
  let start = capture.node.start_byte().reinterpret_as_int()
  let end = capture.node.end_byte().reinterpret_as_int()
  if start < 0 || end < start || end > source.length() {
    query_raise_text_predicate_error(
      predicate, "capture byte range is outside the provided source",
    )
  }
  source[start:end]
}

///|
fn[T] query_raise_text_predicate_error(
  predicate : QueryTextPredicate,
  reason : String,
) -> T raise QueryPredicateError {
  raise QueryPredicateError::Predicate(
    pattern_index=predicate.pattern_index,
    byte_offset=predicate.byte_offset,
    operator=query_text_predicate_operator(predicate.kind),
    reason~,
  )
}

///|
fn query_text_predicate_operator(kind : QueryTextPredicateKind) -> String {
  match kind {
    TextEq => "eq?"
    TextNotEq => "not-eq?"
    TextAnyEq => "any-eq?"
    TextAnyNotEq => "any-not-eq?"
    TextMatch => "match?"
    TextNotMatch => "not-match?"
    TextAnyMatch => "any-match?"
    TextAnyNotMatch => "any-not-match?"
    TextAnyOf => "any-of?"
    TextNotAnyOf => "not-any-of?"
  }
}
