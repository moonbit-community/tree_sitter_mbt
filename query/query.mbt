///|
pub(all) suberror QueryError {
  Syntax(byte_offset~ : Int, reason~ : String)
  NodeType(byte_offset~ : Int, name~ : String)
  Field(byte_offset~ : Int, name~ : String)
  Capture(byte_offset~ : Int, name~ : String)
  Structure(byte_offset~ : Int, reason~ : String)
}

///|
struct Query {
  language : @tree_sitter_mbt.Language
  patterns : Array[QueryPattern]
  capture_names : Array[String]
  string_values : Array[String]
  disabled_capture_ids : Array[Bool]
  disabled_pattern_indices : Array[Bool]
}

///|
struct QueryCursor {
  mut matches : Array[QueryMatch]
  mut match_index : Int
  mut captures : Array[QueryCapture]
  mut capture_index : Int
  mut removed_match_ids : Array[Int]
  mut byte_range_start : UInt
  mut byte_range_end : UInt
  mut point_range_start : @api.Point
  mut point_range_end : @api.Point
  mut containing_byte_range_start : UInt
  mut containing_byte_range_end : UInt
  mut containing_point_range_start : @api.Point
  mut containing_point_range_end : @api.Point
  mut max_start_depth : Int
  mut match_limit : UInt
  mut did_exceed_match_limit : Bool
  mut progress_callback : ((QueryCursorProgressState) -> Bool)?
}

///|
priv struct QueryMatchLimitTracker {
  limit : UInt
  mut did_exceed : Bool
}

///|
pub(all) struct QueryCapture {
  match_id : Int
  pattern_index : Int
  index : Int
  name : String
  node : @tree_sitter_mbt.Node
}

///|
pub(all) struct QueryMatch {
  id : Int
  pattern_index : Int
  captures : Array[QueryCapture]
}

///|
pub(all) struct QueryCursorProgressState {
  current_byte_offset : UInt
} derive(Eq, Debug)

///|
pub fn QueryCursorProgressState::new(
  current_byte_offset~ : UInt,
) -> QueryCursorProgressState {
  { current_byte_offset, }
}

///|
fn QueryMatchLimitTracker::new(limit : UInt) -> QueryMatchLimitTracker {
  { limit, did_exceed: false }
}

///|
fn QueryMatchLimitTracker::limit_sequence_states(
  self : QueryMatchLimitTracker,
  states : Array[QuerySequenceState],
) -> Array[QuerySequenceState] {
  let capture_count = query_sequence_states_capture_list_count(states)
  if capture_count.reinterpret_as_uint() <= self.limit {
    return states
  }
  self.did_exceed = true
  let keep_count = self.limit.reinterpret_as_int()
  let drop_count = capture_count - keep_count
  let drop_indices = query_sequence_state_drop_indices(states, drop_count)
  let result : Array[QuerySequenceState] = []
  for index, state in states {
    if !query_int_array_contains(drop_indices, index) {
      result.push(state)
    }
  }
  result
}

///|
fn QueryMatchLimitTracker::limit_sibling_sequence_states(
  self : QueryMatchLimitTracker,
  states : Array[QuerySiblingSequenceState],
) -> Array[QuerySiblingSequenceState] {
  let capture_count = query_sibling_sequence_states_capture_list_count(states)
  if capture_count.reinterpret_as_uint() <= self.limit {
    return states
  }
  self.did_exceed = true
  let keep_count = self.limit.reinterpret_as_int()
  let drop_count = capture_count - keep_count
  let drop_indices = query_sibling_sequence_state_drop_indices(
    states, drop_count,
  )
  let result : Array[QuerySiblingSequenceState] = []
  for index, state in states {
    if !query_int_array_contains(drop_indices, index) {
      result.push(state)
    }
  }
  result
}

///|
fn QueryMatchLimitTracker::limit_node_matches(
  self : QueryMatchLimitTracker,
  matches : Array[QueryNodeMatch],
) -> Array[QueryNodeMatch] {
  let capture_count = query_node_matches_capture_list_count(matches)
  if capture_count.reinterpret_as_uint() <= self.limit {
    return matches
  }
  self.did_exceed = true
  let keep_count = self.limit.reinterpret_as_int()
  let drop_count = capture_count - keep_count
  let drop_indices = query_node_match_drop_indices(matches, drop_count)
  let result : Array[QueryNodeMatch] = []
  for index, matched in matches {
    if !query_int_array_contains(drop_indices, index) {
      result.push(matched)
    }
  }
  result
}

///|
pub(all) enum QueryPredicateStep {
  Done
  Capture(Int)
  String(Int)
} derive(Eq, Debug)

///|
pub(all) enum QueryCaptureQuantifier {
  Zero
  ZeroOrOne
  ZeroOrMore
  One
  OneOrMore
} derive(Eq, Debug)

///|
priv struct QueryPattern {
  root : QueryNodePattern
  predicate_steps : Array[QueryPredicateStep]
  predicate_step_offsets : Array[Int]
  start_byte : Int
  end_byte : Int
}

///|
priv struct QueryRootMatch {
  captures : Array[QueryCapture]
  nodes : Array[@tree_sitter_mbt.Node]
}

///|
priv struct QueryNodeMatch {
  captures : Array[QueryCapture]
  nodes : Array[@tree_sitter_mbt.Node]
}

///|
priv struct QueryChildMatch {
  next_child_index : Int
  node_match : QueryNodeMatch
}

///|
priv struct QuerySequenceState {
  next_child_index : Int
  captures : Array[QueryCapture]
  nodes : Array[@tree_sitter_mbt.Node]
}

///|
priv struct QuerySiblingSequenceState {
  current : @tree_sitter_mbt.Node
  captures : Array[QueryCapture]
  nodes : Array[@tree_sitter_mbt.Node]
}

///|
priv struct QueryNodePattern {
  kind : QueryNodePatternKind
  field_name : String?
  mut start_byte : Int
  // Intentional divergence from upstream query bytecode: keep all parsed
  // capture ids and negated fields in the AST instead of capping each step.
  negated_field_names : Array[String]
  mut quantifier : QueryCaptureQuantifier
  mut anchor_before : Bool
  mut anchor_after : Bool
  capture_ids : Array[Int]
  children : Array[QueryNodePattern]
}

///|
priv struct QueryGuaranteedStepSearch {
  target : Int
  mut current : Int
  mut found : Bool
  mut guaranteed : Bool
  predicate_capture_ids : Array[Int]
}

///|
priv struct QueryGuaranteedStepInfo {
  byte_offset : Int
  guaranteed : Bool
}

///|
priv enum QueryNodePatternKind {
  Alternation(Array[QueryNodePattern])
  Sequence(Array[QueryNodePattern])
  Supertype(@api.SymbolId, @api.SymbolId?)
  Named(String)
  Anonymous(String)
  WildcardNamed
  WildcardAny
  Error
  MissingAny
  MissingNamed(String)
  MissingAnonymous(String)
}

///|
pub fn Query::new(
  language : @tree_sitter_mbt.Language,
  source : String,
) -> Query raise QueryError {
  let parser = QueryParser::new(language, source)
  parser.parse()
}

///|
pub fn Query::pattern_count(self : Query) -> Int {
  self.patterns.length()
}

///|
pub fn Query::language(self : Query) -> @tree_sitter_mbt.Language {
  self.language
}

///|
pub fn Query::capture_count(self : Query) -> Int {
  self.capture_names.length()
}

///|
pub fn Query::string_count(self : Query) -> Int {
  self.string_values.length()
}

///|
pub fn Query::capture_name_for_id(self : Query, id : Int) -> String? {
  self.capture_names.get(id)
}

///|
pub fn Query::string_value_for_id(self : Query, id : Int) -> String? {
  self.string_values.get(id)
}

///|
pub fn Query::disable_capture(self : Query, name : String) -> Bool {
  let mut disabled = false
  for id in 0..<self.capture_names.length() {
    if self.capture_names[id] == name {
      self.disabled_capture_ids[id] = true
      disabled = true
    }
  }
  disabled
}

///|
pub fn Query::disable_pattern(self : Query, pattern_index : Int) -> Bool {
  match self.disabled_pattern_indices.get(pattern_index) {
    Some(_) => {
      self.disabled_pattern_indices[pattern_index] = true
      true
    }
    None => false
  }
}

///|
pub fn Query::start_byte_for_pattern(self : Query, pattern_index : Int) -> Int? {
  match self.patterns.get(pattern_index) {
    Some(pattern) => Some(pattern.start_byte)
    None => None
  }
}

///|
pub fn Query::end_byte_for_pattern(self : Query, pattern_index : Int) -> Int? {
  match self.patterns.get(pattern_index) {
    Some(pattern) => Some(pattern.end_byte)
    None => None
  }
}

///|
pub fn Query::is_pattern_rooted(self : Query, pattern_index : Int) -> Bool? {
  match self.patterns.get(pattern_index) {
    Some(pattern) => Some(pattern.is_rooted())
    None => None
  }
}

///|
pub fn Query::is_pattern_non_local(self : Query, pattern_index : Int) -> Bool? {
  match self.patterns.get(pattern_index) {
    Some(pattern) => Some(pattern.is_non_local())
    None => None
  }
}

///|
pub fn Query::is_pattern_guaranteed_at_step(
  self : Query,
  pattern_index : Int,
  step_index : Int,
) -> Bool? {
  match self.patterns.get(pattern_index) {
    Some(pattern) => Some(pattern.is_guaranteed_at_step(step_index))
    None => None
  }
}

///|
pub fn Query::is_pattern_guaranteed_at_byte_offset(
  self : Query,
  byte_offset : Int,
) -> Bool {
  let mut found : QueryGuaranteedStepInfo? = None
  for pattern in self.patterns {
    let steps = pattern.guaranteed_step_infos()
    for step in steps {
      if step.byte_offset > byte_offset {
        return match found {
          Some(info) => info.guaranteed
          None => false
        }
      }
      found = Some(step)
    }
  }
  match found {
    Some(info) => info.guaranteed
    None => false
  }
}

///|
pub fn Query::capture_quantifier_for_id(
  self : Query,
  pattern_index : Int,
  capture_id : Int,
) -> QueryCaptureQuantifier? {
  match (self.patterns.get(pattern_index), self.capture_names.get(capture_id)) {
    (Some(pattern), Some(_)) =>
      Some(pattern.capture_quantifier(capture_id).unwrap_or(Zero))
    _ => None
  }
}

///|
pub fn Query::predicate_step_count_for_pattern(
  self : Query,
  pattern_index : Int,
) -> Int? {
  match self.patterns.get(pattern_index) {
    Some(pattern) => Some(pattern.predicate_steps.length())
    None => None
  }
}

///|
pub fn Query::predicate_step_for_pattern(
  self : Query,
  pattern_index : Int,
  step_index : Int,
) -> QueryPredicateStep? {
  match self.patterns.get(pattern_index) {
    Some(pattern) => pattern.predicate_steps.get(step_index)
    None => None
  }
}

///|
pub fn QueryCursor::new() -> QueryCursor {
  {
    matches: [],
    match_index: 0,
    captures: [],
    capture_index: 0,
    removed_match_ids: [],
    byte_range_start: 0,
    byte_range_end: 0,
    point_range_start: @api.Point::zero(),
    point_range_end: @api.Point::zero(),
    containing_byte_range_start: 0,
    containing_byte_range_end: 0,
    containing_point_range_start: @api.Point::zero(),
    containing_point_range_end: @api.Point::zero(),
    max_start_depth: -1,
    match_limit: @api.uint32_max(),
    did_exceed_match_limit: false,
    progress_callback: None,
  }
}

///|
fn QueryPattern::contains_capture(
  self : QueryPattern,
  capture_id : Int,
) -> Bool {
  self.root.contains_capture(capture_id)
}

///|
fn QueryPattern::capture_quantifier(
  self : QueryPattern,
  capture_id : Int,
) -> QueryCaptureQuantifier? {
  self.root.capture_quantifier(capture_id, inherited=One)
}

///|
fn QueryPattern::is_rooted(self : QueryPattern) -> Bool {
  self.root.is_rooted_start()
}

///|
fn QueryPattern::is_non_local(self : QueryPattern) -> Bool {
  self.root.is_non_local_start()
}

///|
fn QueryPattern::is_guaranteed_at_step(
  self : QueryPattern,
  step_index : Int,
) -> Bool {
  if step_index < 0 {
    return false
  }
  let search = QueryGuaranteedStepSearch::{
    target: step_index,
    current: 0,
    found: false,
    guaranteed: false,
    predicate_capture_ids: self.predicate_capture_ids(),
  }
  self.root.search_guaranteed_step(guaranteed_path=true, search~)
  search.found && search.guaranteed
}

///|
fn QueryPattern::guaranteed_step_infos(
  self : QueryPattern,
) -> Array[QueryGuaranteedStepInfo] {
  let result : Array[QueryGuaranteedStepInfo] = []
  self.root.collect_guaranteed_step_infos(
    guaranteed_path=true,
    self.predicate_capture_ids(),
    result~,
  )
  result
}

///|
fn QueryNodePattern::contains_capture(
  self : QueryNodePattern,
  capture_id : Int,
) -> Bool {
  for id in self.capture_ids {
    if id == capture_id {
      return true
    }
  }
  match self.kind {
    Alternation(alternatives) | Sequence(alternatives) =>
      for pattern in alternatives {
        if pattern.contains_capture(capture_id) {
          return true
        }
      }
    _ => ()
  }
  for child in self.children {
    if child.contains_capture(capture_id) {
      return true
    }
  }
  false
}

///|
fn QueryNodePattern::capture_quantifier(
  self : QueryNodePattern,
  capture_id : Int,
  inherited~ : QueryCaptureQuantifier,
) -> QueryCaptureQuantifier? {
  let quantifier = query_combine_capture_quantifiers(inherited, self.quantifier)
  let mut found = false
  let mut result = Zero
  for id in self.capture_ids {
    if id == capture_id {
      found = true
      result = query_add_capture_quantifiers(result, quantifier)
    }
  }
  match self.kind {
    Alternation(alternatives) =>
      match
        query_alternation_capture_quantifier(
          alternatives,
          capture_id,
          inherited=quantifier,
        ) {
        Some(alternation_quantifier) => {
          found = true
          result = query_add_capture_quantifiers(result, alternation_quantifier)
        }
        None => ()
      }
    Sequence(elements) =>
      for element in elements {
        match element.capture_quantifier(capture_id, inherited=quantifier) {
          Some(element_quantifier) => {
            found = true
            result = query_add_capture_quantifiers(result, element_quantifier)
          }
          None => ()
        }
      }
    _ => ()
  }
  for child in self.children {
    match child.capture_quantifier(capture_id, inherited=quantifier) {
      Some(child_quantifier) => {
        found = true
        result = query_add_capture_quantifiers(result, child_quantifier)
      }
      None => ()
    }
  }
  if found {
    Some(result)
  } else {
    None
  }
}

///|
fn QueryNodePattern::search_guaranteed_step(
  self : QueryNodePattern,
  guaranteed_path~ : Bool,
  search~ : QueryGuaranteedStepSearch,
) -> Unit {
  if search.found {
    return
  }
  match self.kind {
    Sequence(elements) => {
      let sequence_guaranteed = guaranteed_path && self.quantifier == One
      for element in elements {
        element.search_guaranteed_step(
          guaranteed_path=sequence_guaranteed,
          search~,
        )
        if search.found {
          return
        }
      }
      return
    }
    _ => ()
  }
  let current_guaranteed = guaranteed_path &&
    self.quantifier == One &&
    self.kind_is_single_step() &&
    !self.captures_predicate_capture(search.predicate_capture_ids)
  if search.current == search.target {
    search.found = true
    search.guaranteed = current_guaranteed
    return
  }
  search.current += 1
  if !current_guaranteed {
    return
  }
  for child in self.children {
    child.search_guaranteed_step(guaranteed_path=current_guaranteed, search~)
    if search.found {
      return
    }
  }
}

///|
fn QueryNodePattern::collect_guaranteed_step_infos(
  self : QueryNodePattern,
  guaranteed_path~ : Bool,
  predicate_capture_ids : Array[Int],
  result~ : Array[QueryGuaranteedStepInfo],
) -> Unit {
  match self.kind {
    Sequence(elements) => {
      let sequence_guaranteed = guaranteed_path && self.quantifier == One
      for element in elements {
        element.collect_guaranteed_step_infos(
          guaranteed_path=sequence_guaranteed,
          predicate_capture_ids,
          result~,
        )
      }
      return
    }
    _ => ()
  }
  let current_guaranteed = guaranteed_path &&
    self.quantifier == One &&
    self.kind_is_single_step() &&
    !self.captures_predicate_capture(predicate_capture_ids)
  result.push({ byte_offset: self.start_byte, guaranteed: current_guaranteed })
  if !current_guaranteed {
    return
  }
  for child in self.children {
    child.collect_guaranteed_step_infos(
      guaranteed_path=current_guaranteed,
      predicate_capture_ids,
      result~,
    )
  }
}

///|
fn QueryNodePattern::kind_is_single_step(self : QueryNodePattern) -> Bool {
  match self.kind {
    Alternation(_) | Sequence(_) => false
    _ => true
  }
}

///|
fn QueryNodePattern::captures_predicate_capture(
  self : QueryNodePattern,
  predicate_capture_ids : Array[Int],
) -> Bool {
  for capture_id in self.capture_ids {
    if query_int_array_contains(predicate_capture_ids, capture_id) {
      return true
    }
  }
  false
}

///|
fn QueryNodePattern::is_rooted_start(self : QueryNodePattern) -> Bool {
  if self.quantifier != One {
    return false
  }
  match self.kind {
    Alternation(alternatives) => {
      if alternatives.length() == 0 {
        return false
      }
      for alternative in alternatives {
        if !alternative.is_rooted_start() {
          return false
        }
      }
      true
    }
    Sequence(elements) =>
      elements.length() == 1 && elements[0].is_rooted_start()
    WildcardNamed | WildcardAny => self.is_rooted_wildcard_start()
    Anonymous(_) => self.children.length() == 0
    _ => true
  }
}

///|
fn QueryNodePattern::is_rooted_wildcard_start(self : QueryNodePattern) -> Bool {
  if self.children.length() == 0 {
    true
  } else if self.children[0].starts_with_wildcard() {
    true
  } else if self.children.length() == 1 {
    self.children[0].is_rooted_start()
  } else {
    false
  }
}

///|
fn QueryNodePattern::starts_with_wildcard(self : QueryNodePattern) -> Bool {
  match self.kind {
    WildcardNamed | WildcardAny => true
    _ => false
  }
}

///|
fn QueryNodePattern::is_non_local_start(self : QueryNodePattern) -> Bool {
  if query_capture_quantifier_is_repeating(self.quantifier) {
    return true
  }
  if self.has_non_local_wildcard_siblings() {
    return true
  }
  match self.kind {
    Alternation(alternatives) =>
      for alternative in alternatives {
        if alternative.is_non_local_start() {
          return true
        }
      }
    Sequence(elements) => {
      let mut non_local_sibling_count = 0
      for element in elements {
        if element.can_start_non_local_sibling() {
          non_local_sibling_count += 1
          if non_local_sibling_count > 1 {
            return true
          }
        }
        if element.is_non_local_start() {
          return true
        }
      }
    }
    _ => ()
  }
  for child in self.children {
    if child.is_non_local_start() {
      return true
    }
  }
  false
}

///|
fn QueryNodePattern::has_non_local_wildcard_siblings(
  self : QueryNodePattern,
) -> Bool {
  guard self.kind is (WildcardNamed | WildcardAny) else { return false }
  let mut named_child_count = 0
  for child in self.children {
    if child.can_start_non_local_sibling() {
      named_child_count += 1
      if named_child_count > 1 {
        return true
      }
    }
  }
  false
}

///|
fn QueryNodePattern::can_start_non_local_sibling(
  self : QueryNodePattern,
) -> Bool {
  match self.kind {
    Alternation(alternatives) => {
      for alternative in alternatives {
        if alternative.can_start_non_local_sibling() {
          return true
        }
      }
      false
    }
    Sequence(elements) =>
      match elements.get(0) {
        Some(element) => element.can_start_non_local_sibling()
        None => false
      }
    Named(_) | Supertype(_, _) | WildcardNamed => true
    _ => false
  }
}

///|
fn query_alternation_capture_quantifier(
  alternatives : Array[QueryNodePattern],
  capture_id : Int,
  inherited~ : QueryCaptureQuantifier,
) -> QueryCaptureQuantifier? {
  let mut found = false
  let mut result = Zero
  for alternative in alternatives {
    let alternative_quantifier = alternative
      .capture_quantifier(capture_id, inherited~)
      .unwrap_or(Zero)
    if alternative_quantifier != Zero {
      found = true
    }
    result = query_union_capture_quantifiers(result, alternative_quantifier)
  }
  if found {
    Some(result)
  } else {
    None
  }
}

///|
fn query_union_capture_quantifiers(
  left : QueryCaptureQuantifier,
  right : QueryCaptureQuantifier,
) -> QueryCaptureQuantifier {
  query_capture_quantifier_from_min_max(
    query_min_int(
      query_capture_quantifier_min(left),
      query_capture_quantifier_min(right),
    ),
    query_max_int(
      query_capture_quantifier_max(left),
      query_capture_quantifier_max(right),
    ),
  )
}

///|
fn query_add_capture_quantifiers(
  left : QueryCaptureQuantifier,
  right : QueryCaptureQuantifier,
) -> QueryCaptureQuantifier {
  query_capture_quantifier_from_min_max(
    query_capture_quantifier_min(left) + query_capture_quantifier_min(right),
    query_capture_quantifier_max(left) + query_capture_quantifier_max(right),
  )
}

///|
fn query_join_capture_quantifiers(
  left : QueryCaptureQuantifier,
  right : QueryCaptureQuantifier,
) -> QueryCaptureQuantifier {
  query_union_capture_quantifiers(left, right)
}

///|
fn query_capture_quantifier_min(quantifier : QueryCaptureQuantifier) -> Int {
  match quantifier {
    Zero | ZeroOrOne | ZeroOrMore => 0
    One | OneOrMore => 1
  }
}

///|
fn query_capture_quantifier_max(quantifier : QueryCaptureQuantifier) -> Int {
  match quantifier {
    Zero => 0
    One | ZeroOrOne => 1
    OneOrMore | ZeroOrMore => 2
  }
}

///|
fn query_capture_quantifier_is_repeating(
  quantifier : QueryCaptureQuantifier,
) -> Bool {
  match quantifier {
    OneOrMore | ZeroOrMore => true
    _ => false
  }
}

///|
fn query_capture_quantifier_from_min_max(
  min : Int,
  max : Int,
) -> QueryCaptureQuantifier {
  if min == 0 {
    if max == 0 {
      Zero
    } else if max == 1 {
      ZeroOrOne
    } else {
      ZeroOrMore
    }
  } else if max == 1 {
    One
  } else {
    OneOrMore
  }
}

///|
fn query_min_int(left : Int, right : Int) -> Int {
  if left < right {
    left
  } else {
    right
  }
}

///|
fn query_max_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}

///|
fn query_combine_capture_quantifiers(
  outer : QueryCaptureQuantifier,
  inner : QueryCaptureQuantifier,
) -> QueryCaptureQuantifier {
  match (outer, inner) {
    (Zero, _) | (_, Zero) => Zero
    (ZeroOrMore, _) | (_, ZeroOrMore) => ZeroOrMore
    (ZeroOrOne, One) | (One, ZeroOrOne) => ZeroOrOne
    (ZeroOrOne, ZeroOrOne) => ZeroOrOne
    (ZeroOrOne, OneOrMore) | (OneOrMore, ZeroOrOne) => ZeroOrMore
    (OneOrMore, _) | (_, OneOrMore) => OneOrMore
    (One, One) => One
  }
}

///|
fn QueryPattern::predicate_capture_ids(self : QueryPattern) -> Array[Int] {
  let result : Array[Int] = []
  for step in self.predicate_steps {
    match step {
      Capture(capture_id) =>
        if self.contains_capture(capture_id) &&
          !query_int_array_contains(result, capture_id) {
          result.push(capture_id)
        }
      _ => ()
    }
  }
  result
}

///|
fn query_int_array_contains(values : Array[Int], value : Int) -> Bool {
  for candidate in values {
    if candidate == value {
      return true
    }
  }
  false
}

///|
pub fn QueryCursor::set_byte_range(
  self : QueryCursor,
  start_byte : UInt,
  end_byte : UInt,
) -> Bool {
  if end_byte != 0 && start_byte > end_byte {
    false
  } else {
    self.byte_range_start = start_byte
    self.byte_range_end = end_byte
    true
  }
}

///|
pub fn QueryCursor::set_point_range(
  self : QueryCursor,
  start_point : @api.Point,
  end_point : @api.Point,
) -> Bool {
  if end_point != @api.Point::zero() && start_point.gt(end_point) {
    false
  } else {
    self.point_range_start = start_point
    self.point_range_end = end_point
    true
  }
}

///|
pub fn QueryCursor::set_containing_byte_range(
  self : QueryCursor,
  start_byte : UInt,
  end_byte : UInt,
) -> Bool {
  if end_byte != 0 && start_byte > end_byte {
    false
  } else {
    self.containing_byte_range_start = start_byte
    self.containing_byte_range_end = end_byte
    true
  }
}

///|
pub fn QueryCursor::set_containing_point_range(
  self : QueryCursor,
  start_point : @api.Point,
  end_point : @api.Point,
) -> Bool {
  if end_point != @api.Point::zero() && start_point.gt(end_point) {
    false
  } else {
    self.containing_point_range_start = start_point
    self.containing_point_range_end = end_point
    true
  }
}

///|
pub fn QueryCursor::set_max_start_depth(
  self : QueryCursor,
  max_start_depth : Int,
) -> Bool {
  if max_start_depth == -1 {
    self.max_start_depth = -1
    true
  } else if max_start_depth < 0 {
    false
  } else {
    self.max_start_depth = max_start_depth
    true
  }
}

///|
pub fn QueryCursor::set_match_limit(
  self : QueryCursor,
  match_limit : UInt,
) -> Unit {
  self.match_limit = match_limit
}

///|
pub fn QueryCursor::match_limit(self : QueryCursor) -> UInt {
  self.match_limit
}

///|
pub fn QueryCursor::did_exceed_match_limit(self : QueryCursor) -> Bool {
  self.did_exceed_match_limit
}

///|
pub fn QueryCursor::set_progress_callback(
  self : QueryCursor,
  callback : ((QueryCursorProgressState) -> Bool)?,
) -> Unit {
  self.progress_callback = callback
}

///|
pub fn QueryCursor::exec(
  self : QueryCursor,
  query : Query,
  node : @tree_sitter_mbt.Node,
) -> Unit {
  let matches : Array[QueryMatch] = []
  let captures : Array[QueryCapture] = []
  let mut next_match_id = 0
  let match_limit_tracker = QueryMatchLimitTracker::new(self.match_limit)
  let mut cancelled = false
  let mut operation_count = 0
  self.did_exceed_match_limit = false
  if !query_languages_compatible(query.language, node.language()) {
    self.matches = []
    self.match_index = 0
    self.captures = []
    self.capture_index = 0
    self.removed_match_ids = []
    return
  }
  let nodes = query_collect_public_nodes(node)
  for candidate in nodes {
    if cancelled {
      break
    }
    operation_count += 1
    if operation_count % 100 == 0 &&
      self.should_cancel_at(candidate.node.start_byte()) {
      cancelled = true
      break
    }
    if self.node_is_within_max_start_depth(candidate.depth) {
      for pattern_index in 0..<query.patterns.length() {
        if query.pattern_is_disabled(pattern_index) {
          continue
        }
        let pattern = query.patterns[pattern_index]
        for
          root_match in pattern.match_roots(
            candidate.node,
            query,
            pattern_index~,
            start_depth=candidate.depth,
            match_limit_tracker~,
          ) {
          if self.root_match_is_visible(root_match) {
            let match_id = next_match_id
            let root_match = query_root_match_with_id(root_match, match_id)
            next_match_id += 1
            for capture in root_match.captures {
              if self.capture_is_visible_in_range(capture) {
                captures.push(capture)
              }
            }
            matches.push(QueryMatch::{
              id: match_id,
              pattern_index,
              captures: root_match.captures,
            })
          }
        }
      }
    }
  }
  captures.sort_by(query_capture_compare)
  self.matches = matches
  self.match_index = 0
  self.captures = captures
  self.capture_index = 0
  self.removed_match_ids = []
  // Intentional approximation: this eager matcher prunes intermediate
  // capture-bearing states instead of modeling Tree-sitter's reusable capture
  // list pool exactly, but it still reports pressure when the configured pool
  // size is exceeded.
  self.did_exceed_match_limit = match_limit_tracker.did_exceed
}

///|
fn query_languages_compatible(
  left : @tree_sitter_mbt.Language,
  right : @tree_sitter_mbt.Language,
) -> Bool {
  if left.abi_version() != right.abi_version() ||
    left.name() != right.name() ||
    left.symbol_count() != right.symbol_count() ||
    left.field_count() != right.field_count() {
    return false
  }
  for i in 0..<left.symbol_count() {
    let id = @api.SymbolId::new(i.reinterpret_as_uint())
    if left.symbol_name(id) != right.symbol_name(id) ||
      left.symbol_type(id) != right.symbol_type(id) {
      return false
    }
  }
  for i in 0..<=left.field_count() {
    let id = @api.FieldId::new(i.reinterpret_as_uint())
    if left.field_name_for_id(id) != right.field_name_for_id(id) {
      return false
    }
  }
  let left_supertypes = left.supertypes()
  let right_supertypes = right.supertypes()
  if left_supertypes != right_supertypes {
    return false
  }
  for supertype in left_supertypes {
    if left.subtypes(supertype) != right.subtypes(supertype) {
      return false
    }
  }
  true
}

///|
fn QueryCursor::capture_is_visible_in_range(
  self : QueryCursor,
  capture : QueryCapture,
) -> Bool {
  self.node_intersects_range(capture.node)
}

///|
fn QueryCursor::root_match_is_visible(
  self : QueryCursor,
  matched : QueryRootMatch,
) -> Bool {
  self.root_match_intersects_range(matched) &&
  self.root_match_is_contained_in_range(matched)
}

///|
fn QueryCursor::root_match_intersects_range(
  self : QueryCursor,
  matched : QueryRootMatch,
) -> Bool {
  for node in matched.nodes {
    if self.node_intersects_range(node) {
      return true
    }
  }
  false
}

///|
fn QueryCursor::root_match_is_contained_in_range(
  self : QueryCursor,
  matched : QueryRootMatch,
) -> Bool {
  for node in matched.nodes {
    if !self.node_is_contained_in_range(node) {
      return false
    }
  }
  true
}

///|
fn QueryPattern::match_roots(
  self : QueryPattern,
  node : @tree_sitter_mbt.Node,
  query : Query,
  pattern_index~ : Int,
  start_depth~ : Int,
  match_limit_tracker~ : QueryMatchLimitTracker,
) -> Array[QueryRootMatch] {
  let result : Array[QueryRootMatch] = []
  match self.root.quantifier {
    Zero => ()
    One | ZeroOrOne => {
      for
        node_match in self.root.match_captures_all(
          node,
          query,
          pattern_index~,
          match_limit_tracker~,
        ) {
        result.push({ captures: node_match.captures, nodes: node_match.nodes })
      }
      if result.is_empty() &&
        self.root.quantifier == ZeroOrOne &&
        query_can_match_empty_root_at(node, start_depth~) {
        result.push({ captures: [], nodes: [node] })
      }
    }
    OneOrMore =>
      for
        root_match in self.root.match_repeated_roots_all(
          node,
          query,
          pattern_index~,
          match_limit_tracker~,
        ) {
        result.push(root_match)
      }
    ZeroOrMore => {
      let root_matches = self.root.match_repeated_roots_all(
        node,
        query,
        pattern_index~,
        match_limit_tracker~,
      )
      if root_matches.is_empty() {
        if query_can_match_empty_root_at(node, start_depth~) {
          result.push({ captures: [], nodes: [node] })
        }
      } else {
        for root_match in root_matches {
          result.push(root_match)
        }
      }
    }
  }
  result
}

///|
fn query_root_match_with_id(
  root_match : QueryRootMatch,
  match_id : Int,
) -> QueryRootMatch {
  let captures : Array[QueryCapture] = []
  for capture in root_match.captures {
    captures.push(QueryCapture::{
      match_id,
      pattern_index: capture.pattern_index,
      index: capture.index,
      name: capture.name,
      node: capture.node,
    })
  }
  { captures, nodes: query_copy_nodes(root_match.nodes) }
}

///|
fn query_can_match_empty_root_at(
  node : @tree_sitter_mbt.Node,
  start_depth~ : Int,
) -> Bool {
  start_depth == 0 && node.child_count() == 0
}

///|
fn QueryNodePattern::match_repeated_roots_all(
  self : QueryNodePattern,
  node : @tree_sitter_mbt.Node,
  query : Query,
  pattern_index~ : Int,
  match_limit_tracker~ : QueryMatchLimitTracker,
) -> Array[QueryRootMatch] {
  let result : Array[QueryRootMatch] = []
  let previous = node.previous_sibling()
  if !previous.is_null() &&
    !self
    .match_captures_all(previous, query, pattern_index~, match_limit_tracker~)
    .is_empty() {
    return result
  }
  let mut states : Array[QuerySequenceState] = [
    { next_child_index: 0, captures: [], nodes: [] },
  ]
  let mut current = node
  let mut matched_count = 0
  while !current.is_null() {
    let current_matches = match_limit_tracker.limit_node_matches(
      self.match_captures_all(
        current,
        query,
        pattern_index~,
        match_limit_tracker~,
      ),
    )
    if current_matches.is_empty() {
      break
    }
    let next_states : Array[QuerySequenceState] = []
    for state in states {
      for current_match in current_matches {
        next_states.push(
          query_sequence_state_append_node_match(
            state,
            current_match,
            next_child_index=0,
          ),
        )
      }
    }
    matched_count += 1
    states = match_limit_tracker.limit_sequence_states(
      query_dedup_sequence_states(next_states),
    )
    current = current.next_sibling()
  }
  if matched_count == 0 {
    return result
  }
  for state in states {
    result.push({ captures: state.captures, nodes: state.nodes })
  }
  result
}

///|
fn QueryNodePattern::match_captures_all(
  self : QueryNodePattern,
  node : @tree_sitter_mbt.Node,
  query : Query,
  pattern_index~ : Int,
  match_limit_tracker~ : QueryMatchLimitTracker,
) -> Array[QueryNodeMatch] {
  let result : Array[QueryNodeMatch] = []
  if !query_node_parent_field_matches(node, self.field_name) {
    return result
  }
  match self.kind {
    Alternation(alternatives) => {
      for alternative in alternatives {
        let local_captures = self.local_captures(node, query, pattern_index~)
        for
          alternative_match in alternative.match_captures_all(
            node,
            query,
            pattern_index~,
            match_limit_tracker~,
          ) {
          result.push(query_merge_node_match(local_captures, alternative_match))
        }
      }
      return match_limit_tracker.limit_node_matches(result)
    }
    Sequence(elements) => {
      let local_captures = self.local_captures(node, query, pattern_index~)
      for
        sequence_match in query_match_sibling_sequence_all(
          elements,
          node,
          query,
          pattern_index~,
          match_limit_tracker~,
        ) {
        result.push(query_merge_node_match(local_captures, sequence_match))
      }
      return match_limit_tracker.limit_node_matches(result)
    }
    _ => ()
  }
  if !query_node_pattern_kind_matches(self.kind, node) {
    return result
  }
  if query_node_has_negated_field(node, self.negated_field_names) {
    return result
  }
  let captures = self.local_captures(node, query, pattern_index~)
  let nodes = [node]
  let mut states : Array[QuerySequenceState] = [
    { next_child_index: 0, captures, nodes },
  ]
  for child_pattern in self.children {
    let next_states : Array[QuerySequenceState] = []
    for state in states {
      for
        child_match in child_pattern.match_child_captures_all(
          node,
          state.next_child_index,
          query,
          pattern_index~,
          match_limit_tracker~,
        ) {
        next_states.push(query_sequence_state_append(state, child_match))
      }
    }
    if next_states.is_empty() {
      return result
    }
    states = match_limit_tracker.limit_sequence_states(next_states)
  }
  states = match_limit_tracker.limit_sequence_states(states)
  for state in states {
    result.push({ captures: state.captures, nodes: state.nodes })
  }
  result
}

///|
fn query_match_sibling_sequence_all(
  elements : Array[QueryNodePattern],
  node : @tree_sitter_mbt.Node,
  query : Query,
  pattern_index~ : Int,
  match_limit_tracker~ : QueryMatchLimitTracker,
) -> Array[QueryNodeMatch] {
  let result : Array[QueryNodeMatch] = []
  let mut states : Array[QuerySiblingSequenceState] = [
    { current: node, captures: [], nodes: [] },
  ]
  for element_index in 0..<elements.length() {
    let element = elements[element_index]
    let next_states : Array[QuerySiblingSequenceState] = []
    for state in states {
      for
        element_state in element.match_sibling_sequence_element_all(
          state.current,
          query,
          pattern_index~,
          match_limit_tracker~,
          allow_skip=element_index > 0 && !state.nodes.is_empty(),
        ) {
        next_states.push(
          query_sibling_sequence_state_append(state, element_state),
        )
      }
    }
    if next_states.is_empty() {
      return result
    }
    states = match_limit_tracker.limit_sibling_sequence_states(
      query_dedup_sibling_sequence_states(next_states),
    )
  }
  states = match_limit_tracker.limit_sibling_sequence_states(states)
  for state in states {
    result.push({ captures: state.captures, nodes: state.nodes })
  }
  result
}

///|
fn QueryNodePattern::match_sibling_sequence_element_all(
  self : QueryNodePattern,
  node : @tree_sitter_mbt.Node,
  query : Query,
  pattern_index~ : Int,
  match_limit_tracker~ : QueryMatchLimitTracker,
  allow_skip~ : Bool,
) -> Array[QuerySiblingSequenceState] {
  let result : Array[QuerySiblingSequenceState] = []
  match self.quantifier {
    Zero => result.push({ current: node, captures: [], nodes: [] })
    ZeroOrOne => {
      for
        state in self.match_one_sibling_sequence_element_all(
          node,
          query,
          pattern_index~,
          match_limit_tracker~,
          allow_skip~,
        ) {
        result.push(state)
      }
      result.push({ current: node, captures: [], nodes: [] })
    }
    One =>
      for
        state in self.match_one_sibling_sequence_element_all(
          node,
          query,
          pattern_index~,
          match_limit_tracker~,
          allow_skip~,
        ) {
        result.push(state)
      }
    OneOrMore =>
      for
        state in self.match_repeated_sibling_sequence_element_all(
          node,
          query,
          pattern_index~,
          required=true,
          match_limit_tracker~,
          allow_skip~,
        ) {
        result.push(state)
      }
    ZeroOrMore =>
      for
        state in self.match_repeated_sibling_sequence_element_all(
          node,
          query,
          pattern_index~,
          required=false,
          match_limit_tracker~,
          allow_skip~,
        ) {
        result.push(state)
      }
  }
  result
}

///|
fn QueryNodePattern::match_one_sibling_sequence_element_all(
  self : QueryNodePattern,
  node : @tree_sitter_mbt.Node,
  query : Query,
  pattern_index~ : Int,
  match_limit_tracker~ : QueryMatchLimitTracker,
  allow_skip~ : Bool,
) -> Array[QuerySiblingSequenceState] {
  let result : Array[QuerySiblingSequenceState] = []
  let skips_anonymous = self.anchor_skips_anonymous()
  let mut current = node
  while !current.is_null() {
    if self.anchor_before &&
      !query_sibling_anchor_gap_clear(node, current, skips_anonymous~) {
      current = current.next_sibling()
      continue
    }
    if self.anchor_after &&
      !query_sibling_anchor_after_clear(current, skips_anonymous~) {
      current = current.next_sibling()
      continue
    }
    for
      node_match in self.match_captures_all(
        current,
        query,
        pattern_index~,
        match_limit_tracker~,
      ) {
      result.push({
        current: current.next_sibling(),
        captures: node_match.captures,
        nodes: node_match.nodes,
      })
    }
    if allow_skip {
      current = current.next_sibling()
    } else {
      break
    }
  }
  result
}

///|
fn QueryNodePattern::match_repeated_sibling_sequence_element_all(
  self : QueryNodePattern,
  node : @tree_sitter_mbt.Node,
  query : Query,
  pattern_index~ : Int,
  required~ : Bool,
  match_limit_tracker~ : QueryMatchLimitTracker,
  allow_skip~ : Bool,
) -> Array[QuerySiblingSequenceState] {
  let result : Array[QuerySiblingSequenceState] = []
  let mut states : Array[QuerySiblingSequenceState] = [
    { current: node, captures: [], nodes: [] },
  ]
  let mut matched_count = 0
  while true {
    let next_states : Array[QuerySiblingSequenceState] = []
    for state in states {
      for
        element_state in self.match_one_sibling_sequence_element_all(
          state.current,
          query,
          pattern_index~,
          match_limit_tracker~,
          allow_skip~,
        ) {
        next_states.push(
          query_sibling_sequence_state_append(state, element_state),
        )
      }
    }
    if next_states.is_empty() {
      break
    }
    matched_count += 1
    states = match_limit_tracker.limit_sibling_sequence_states(
      query_dedup_sibling_sequence_states(next_states),
    )
  }
  if required && matched_count == 0 {
    return result
  }
  for state in states {
    result.push(state)
  }
  result
}

///|
fn query_sibling_sequence_state_append(
  state : QuerySiblingSequenceState,
  element_state : QuerySiblingSequenceState,
) -> QuerySiblingSequenceState {
  let captures = query_copy_captures(state.captures)
  for capture in element_state.captures {
    captures.push(capture)
  }
  let nodes = query_copy_nodes(state.nodes)
  for node in element_state.nodes {
    nodes.push(node)
  }
  { current: element_state.current, captures, nodes }
}

///|
fn query_sibling_anchor_gap_clear(
  start : @tree_sitter_mbt.Node,
  matched : @tree_sitter_mbt.Node,
  skips_anonymous~ : Bool,
) -> Bool {
  let mut sibling = start
  while !sibling.is_null() && !sibling.eq(matched) {
    if !skips_anonymous || sibling.is_named() {
      return false
    }
    sibling = sibling.next_sibling()
  }
  true
}

///|
fn query_sibling_anchor_after_clear(
  matched : @tree_sitter_mbt.Node,
  skips_anonymous~ : Bool,
) -> Bool {
  let mut sibling = matched.next_sibling()
  while !sibling.is_null() {
    if !skips_anonymous || sibling.is_named() {
      return false
    }
    sibling = sibling.next_sibling()
  }
  true
}

///|
fn QueryNodePattern::local_captures(
  self : QueryNodePattern,
  node : @tree_sitter_mbt.Node,
  query : Query,
  pattern_index~ : Int,
) -> Array[QueryCapture] {
  let result : Array[QueryCapture] = []
  for capture_id in self.capture_ids {
    if query.capture_is_disabled(capture_id) {
      continue
    }
    guard query.capture_names.get(capture_id) is Some(name) else { continue }
    result.push(QueryCapture::{
      match_id: 0,
      pattern_index,
      index: capture_id,
      name,
      node,
    })
  }
  result
}

///|
fn query_merge_node_match(
  local_captures : Array[QueryCapture],
  node_match : QueryNodeMatch,
) -> QueryNodeMatch {
  let captures = query_copy_captures(local_captures)
  for capture in node_match.captures {
    captures.push(capture)
  }
  { captures, nodes: query_copy_nodes(node_match.nodes) }
}

///|
fn query_sequence_state_append(
  state : QuerySequenceState,
  child_match : QueryChildMatch,
) -> QuerySequenceState {
  query_sequence_state_append_node_match(
    state,
    child_match.node_match,
    next_child_index=child_match.next_child_index,
  )
}

///|
fn query_sequence_state_append_node_match(
  state : QuerySequenceState,
  node_match : QueryNodeMatch,
  next_child_index~ : Int,
) -> QuerySequenceState {
  let captures = query_copy_captures(state.captures)
  for capture in node_match.captures {
    captures.push(capture)
  }
  let nodes = query_copy_nodes(state.nodes)
  for node in node_match.nodes {
    nodes.push(node)
  }
  { next_child_index, captures, nodes }
}

///|
fn query_copy_captures(captures : Array[QueryCapture]) -> Array[QueryCapture] {
  let result : Array[QueryCapture] = []
  for capture in captures {
    result.push(capture)
  }
  result
}

///|
fn query_copy_nodes(
  nodes : Array[@tree_sitter_mbt.Node],
) -> Array[@tree_sitter_mbt.Node] {
  let result : Array[@tree_sitter_mbt.Node] = []
  for node in nodes {
    result.push(node)
  }
  result
}

///|
fn QueryNodePattern::match_child_captures_all(
  self : QueryNodePattern,
  parent : @tree_sitter_mbt.Node,
  start_child_index : Int,
  query : Query,
  pattern_index~ : Int,
  match_limit_tracker~ : QueryMatchLimitTracker,
) -> Array[QueryChildMatch] {
  let result : Array[QueryChildMatch] = []
  match self.quantifier {
    Zero =>
      result.push({
        next_child_index: start_child_index,
        node_match: { captures: [], nodes: [] },
      })
    ZeroOrOne => {
      for
        child_match in self.match_one_child_all(
          parent,
          start_child_index,
          query,
          pattern_index~,
          match_limit_tracker~,
        ) {
        result.push(child_match)
      }
      result.push({
        next_child_index: start_child_index,
        node_match: { captures: [], nodes: [] },
      })
    }
    One =>
      for
        child_match in self.match_one_child_all(
          parent,
          start_child_index,
          query,
          pattern_index~,
          match_limit_tracker~,
        ) {
        result.push(child_match)
      }
    OneOrMore =>
      for
        child_match in self.match_repeated_children_all(
          parent,
          start_child_index,
          query,
          pattern_index~,
          required=true,
          match_limit_tracker~,
        ) {
        result.push(child_match)
      }
    ZeroOrMore =>
      for
        child_match in self.match_repeated_children_all(
          parent,
          start_child_index,
          query,
          pattern_index~,
          required=false,
          match_limit_tracker~,
        ) {
        result.push(child_match)
      }
  }
  result
}

///|
fn QueryNodePattern::match_repeated_children_all(
  self : QueryNodePattern,
  parent : @tree_sitter_mbt.Node,
  start_child_index : Int,
  query : Query,
  pattern_index~ : Int,
  required~ : Bool,
  match_limit_tracker~ : QueryMatchLimitTracker,
) -> Array[QueryChildMatch] {
  let result : Array[QueryChildMatch] = []
  let mut states : Array[QuerySequenceState] = [
    { next_child_index: start_child_index, captures: [], nodes: [] },
  ]
  let mut matched_count = 0
  while true {
    let next_states : Array[QuerySequenceState] = []
    for state in states {
      for
        child_match in self.match_one_child_all(
          parent,
          state.next_child_index,
          query,
          pattern_index~,
          match_limit_tracker~,
        ) {
        next_states.push(query_sequence_state_append(state, child_match))
      }
    }
    if next_states.is_empty() {
      break
    }
    matched_count += 1
    states = match_limit_tracker.limit_sequence_states(
      query_dedup_sequence_states(next_states),
    )
  }
  if required && matched_count == 0 {
    return result
  }
  for state in states {
    result.push({
      next_child_index: state.next_child_index,
      node_match: { captures: state.captures, nodes: state.nodes },
    })
  }
  result
}

///|
fn query_dedup_sequence_states(
  states : Array[QuerySequenceState],
) -> Array[QuerySequenceState] {
  let result : Array[QuerySequenceState] = []
  for state in states {
    if !query_sequence_state_array_contains(result, state) {
      result.push(state)
    }
  }
  query_prune_sequence_state_capture_subsets(result)
}

///|
fn query_dedup_sibling_sequence_states(
  states : Array[QuerySiblingSequenceState],
) -> Array[QuerySiblingSequenceState] {
  let result : Array[QuerySiblingSequenceState] = []
  for state in states {
    if !query_sibling_sequence_state_array_contains(result, state) {
      result.push(state)
    }
  }
  query_prune_sibling_sequence_state_capture_subsets(result)
}

///|
fn query_prune_sequence_state_capture_subsets(
  states : Array[QuerySequenceState],
) -> Array[QuerySequenceState] {
  let result : Array[QuerySequenceState] = []
  for index, state in states {
    if !query_sequence_state_is_capture_subset_of_later_state(states, index) {
      result.push(state)
    }
  }
  result
}

///|
fn query_prune_sibling_sequence_state_capture_subsets(
  states : Array[QuerySiblingSequenceState],
) -> Array[QuerySiblingSequenceState] {
  let result : Array[QuerySiblingSequenceState] = []
  for index, state in states {
    if !query_sibling_sequence_state_is_capture_subset_of_later_state(
        states, index,
      ) {
      result.push(state)
    }
  }
  result
}

///|
fn query_sequence_states_capture_list_count(
  states : Array[QuerySequenceState],
) -> Int {
  let mut count = 0
  for state in states {
    if !state.captures.is_empty() {
      count += 1
    }
  }
  count
}

///|
fn query_sibling_sequence_states_capture_list_count(
  states : Array[QuerySiblingSequenceState],
) -> Int {
  let mut count = 0
  for state in states {
    if !state.captures.is_empty() {
      count += 1
    }
  }
  count
}

///|
fn query_node_matches_capture_list_count(
  matches : Array[QueryNodeMatch],
) -> Int {
  let mut count = 0
  for matched in matches {
    if !matched.captures.is_empty() {
      count += 1
    }
  }
  count
}

///|
fn query_sequence_state_drop_indices(
  states : Array[QuerySequenceState],
  drop_count : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  for _ in 0..<drop_count {
    let mut best_index = -1
    for index, state in states {
      if state.captures.is_empty() || query_int_array_contains(result, index) {
        continue
      }
      if best_index < 0 ||
        query_sequence_state_drop_order(state, states[best_index]) < 0 {
        best_index = index
      }
    }
    if best_index >= 0 {
      result.push(best_index)
    }
  }
  result
}

///|
fn query_sibling_sequence_state_drop_indices(
  states : Array[QuerySiblingSequenceState],
  drop_count : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  for _ in 0..<drop_count {
    let mut best_index = -1
    for index, state in states {
      if state.captures.is_empty() || query_int_array_contains(result, index) {
        continue
      }
      if best_index < 0 ||
        query_sibling_sequence_state_drop_order(state, states[best_index]) < 0 {
        best_index = index
      }
    }
    if best_index >= 0 {
      result.push(best_index)
    }
  }
  result
}

///|
fn query_node_match_drop_indices(
  matches : Array[QueryNodeMatch],
  drop_count : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  for _ in 0..<drop_count {
    let mut best_index = -1
    for index, matched in matches {
      if matched.captures.is_empty() || query_int_array_contains(result, index) {
        continue
      }
      if best_index < 0 ||
        query_node_match_drop_order(matched, matches[best_index]) < 0 {
        best_index = index
      }
    }
    if best_index >= 0 {
      result.push(best_index)
    }
  }
  result
}

///|
fn query_sequence_state_drop_order(
  left : QuerySequenceState,
  right : QuerySequenceState,
) -> Int {
  query_capture_arrays_drop_order(left.captures, right.captures)
}

///|
fn query_sibling_sequence_state_drop_order(
  left : QuerySiblingSequenceState,
  right : QuerySiblingSequenceState,
) -> Int {
  query_capture_arrays_drop_order(left.captures, right.captures)
}

///|
fn query_node_match_drop_order(
  left : QueryNodeMatch,
  right : QueryNodeMatch,
) -> Int {
  query_capture_arrays_drop_order(left.captures, right.captures)
}

///|
fn query_capture_arrays_drop_order(
  left : Array[QueryCapture],
  right : Array[QueryCapture],
) -> Int {
  let left_capture = query_earliest_capture(left)
  let right_capture = query_earliest_capture(right)
  match (left_capture, right_capture) {
    (Some(left), Some(right)) => query_capture_compare(left, right)
    (Some(_), None) => -1
    (None, Some(_)) => 1
    (None, None) => 0
  }
}

///|
fn query_earliest_capture(captures : Array[QueryCapture]) -> QueryCapture? {
  if captures.is_empty() {
    return None
  }
  let mut best = captures[0]
  for capture in captures {
    if query_capture_compare(capture, best) < 0 {
      best = capture
    }
  }
  Some(best)
}

///|
fn query_sequence_state_array_contains(
  states : Array[QuerySequenceState],
  state : QuerySequenceState,
) -> Bool {
  for candidate in states {
    if query_sequence_state_equals(candidate, state) {
      return true
    }
  }
  false
}

///|
fn query_sibling_sequence_state_array_contains(
  states : Array[QuerySiblingSequenceState],
  state : QuerySiblingSequenceState,
) -> Bool {
  for candidate in states {
    if query_sibling_sequence_state_equals(candidate, state) {
      return true
    }
  }
  false
}

///|
fn query_sequence_state_equals(
  left : QuerySequenceState,
  right : QuerySequenceState,
) -> Bool {
  left.next_child_index == right.next_child_index &&
  query_capture_arrays_equal(left.captures, right.captures) &&
  query_node_arrays_equal(left.nodes, right.nodes)
}

///|
fn query_sibling_sequence_state_equals(
  left : QuerySiblingSequenceState,
  right : QuerySiblingSequenceState,
) -> Bool {
  query_nodes_equal(left.current, right.current) &&
  query_capture_arrays_equal(left.captures, right.captures) &&
  query_node_arrays_equal(left.nodes, right.nodes)
}

///|
fn query_sequence_state_is_capture_subset_of_later_state(
  states : Array[QuerySequenceState],
  index : Int,
) -> Bool {
  for other_index in (index + 1)..<states.length() {
    if query_capture_array_strictly_contains(
        states[other_index].captures,
        states[index].captures,
      ) {
      return true
    }
  }
  false
}

///|
fn query_sibling_sequence_state_is_capture_subset_of_later_state(
  states : Array[QuerySiblingSequenceState],
  index : Int,
) -> Bool {
  for other_index in (index + 1)..<states.length() {
    if query_capture_array_strictly_contains(
        states[other_index].captures,
        states[index].captures,
      ) {
      return true
    }
  }
  false
}

///|
fn query_capture_array_strictly_contains(
  left : Array[QueryCapture],
  right : Array[QueryCapture],
) -> Bool {
  left.length() > right.length() &&
  query_capture_array_contains_all(left, right)
}

///|
fn query_capture_array_contains_all(
  left : Array[QueryCapture],
  right : Array[QueryCapture],
) -> Bool {
  for capture in right {
    if !query_capture_array_contains(left, capture) {
      return false
    }
  }
  true
}

///|
fn query_capture_array_contains(
  captures : Array[QueryCapture],
  target : QueryCapture,
) -> Bool {
  for capture in captures {
    if query_captures_equal(capture, target) {
      return true
    }
  }
  false
}

///|
fn query_capture_arrays_equal(
  left : Array[QueryCapture],
  right : Array[QueryCapture],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if !query_captures_equal(left[i], right[i]) {
      return false
    }
  }
  true
}

///|
fn query_captures_equal(left : QueryCapture, right : QueryCapture) -> Bool {
  left.pattern_index == right.pattern_index &&
  left.index == right.index &&
  left.name == right.name &&
  query_nodes_equal(left.node, right.node)
}

///|
fn query_node_arrays_equal(
  left : Array[@tree_sitter_mbt.Node],
  right : Array[@tree_sitter_mbt.Node],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if !query_nodes_equal(left[i], right[i]) {
      return false
    }
  }
  true
}

///|
fn query_nodes_equal(
  left : @tree_sitter_mbt.Node,
  right : @tree_sitter_mbt.Node,
) -> Bool {
  left.symbol() == right.symbol() &&
  left.start_byte() == right.start_byte() &&
  left.end_byte() == right.end_byte() &&
  left.is_named() == right.is_named() &&
  left.is_missing() == right.is_missing()
}

///|
fn QueryNodePattern::match_one_child_all(
  self : QueryNodePattern,
  parent : @tree_sitter_mbt.Node,
  start_child_index : Int,
  query : Query,
  pattern_index~ : Int,
  match_limit_tracker~ : QueryMatchLimitTracker,
) -> Array[QueryChildMatch] {
  let result : Array[QueryChildMatch] = []
  for child_index in start_child_index..<parent.child_count() {
    let child = parent.child(child_index)
    if !query_child_field_matches(parent, child_index, self.field_name) {
      continue
    }
    let skips_anonymous = self.anchor_skips_anonymous()
    if self.anchor_before &&
      !query_anchor_gap_clear(
        parent,
        start_child_index,
        child_index,
        skips_anonymous~,
      ) {
      continue
    }
    if self.anchor_after &&
      !query_anchor_after_clear(parent, child_index, skips_anonymous~) {
      continue
    }
    for
      child_match in self.match_captures_all(
        child,
        query,
        pattern_index~,
        match_limit_tracker~,
      ) {
      result.push({ next_child_index: child_index + 1, node_match: child_match })
    }
  }
  result
}

///|
fn QueryNodePattern::anchor_skips_anonymous(self : QueryNodePattern) -> Bool {
  !(self.kind is WildcardAny)
}

///|
fn query_anchor_gap_clear(
  parent : @tree_sitter_mbt.Node,
  start_child_index : Int,
  child_index : Int,
  skips_anonymous~ : Bool,
) -> Bool {
  for sibling_index in start_child_index..<child_index {
    let sibling = parent.child(sibling_index)
    if !skips_anonymous || sibling.is_named() {
      return false
    }
  }
  true
}

///|
fn query_anchor_after_clear(
  parent : @tree_sitter_mbt.Node,
  child_index : Int,
  skips_anonymous~ : Bool,
) -> Bool {
  for sibling_index in (child_index + 1)..<parent.child_count() {
    let sibling = parent.child(sibling_index)
    if !skips_anonymous || sibling.is_named() {
      return false
    }
  }
  true
}

///|
fn query_node_has_negated_field(
  node : @tree_sitter_mbt.Node,
  negated_field_names : Array[String],
) -> Bool {
  for negated_field_name in negated_field_names {
    for child_index in 0..<node.child_count() {
      if node.field_name_for_child(child_index) == Some(negated_field_name) {
        return true
      }
    }
  }
  false
}

///|
fn query_child_field_matches(
  parent : @tree_sitter_mbt.Node,
  child_index : Int,
  field_name : String?,
) -> Bool {
  match field_name {
    Some(name) => parent.field_name_for_child(child_index) == Some(name)
    None => true
  }
}

///|
fn query_node_parent_field_matches(
  node : @tree_sitter_mbt.Node,
  field_name : String?,
) -> Bool {
  match field_name {
    Some(name) => {
      let parent = node.parent()
      if parent.is_null() {
        return false
      }
      for child_index in 0..<parent.child_count() {
        if parent.child(child_index).eq(node) {
          return parent.field_name_for_child(child_index) == Some(name)
        }
      }
      false
    }
    None => true
  }
}

///|
fn Query::pattern_is_disabled(self : Query, pattern_index : Int) -> Bool {
  self.disabled_pattern_indices.get(pattern_index).unwrap_or(false)
}

///|
fn Query::capture_is_disabled(self : Query, capture_id : Int) -> Bool {
  self.disabled_capture_ids.get(capture_id).unwrap_or(false)
}

///|
fn QueryCursor::should_cancel_at(
  self : QueryCursor,
  current_byte_offset : UInt,
) -> Bool {
  match self.progress_callback {
    Some(callback) =>
      callback(QueryCursorProgressState::new(current_byte_offset~))
    None => false
  }
}

///|
pub fn QueryCursor::next_match(self : QueryCursor) -> QueryMatch? {
  while self.match_index < self.matches.length() {
    let value = self.matches[self.match_index]
    self.match_index += 1
    if !self.is_match_removed(value.id) {
      return Some(value)
    }
  }
  None
}

///|
pub fn QueryCursor::next_capture(self : QueryCursor) -> QueryCapture? {
  while self.capture_index < self.captures.length() {
    let value = self.captures[self.capture_index]
    self.capture_index += 1
    if !self.is_match_removed(value.match_id) {
      return Some(value)
    }
  }
  None
}

///|
pub fn QueryCursor::remove_match(self : QueryCursor, match_id : Int) -> Unit {
  if !self.is_match_removed(match_id) {
    self.removed_match_ids.push(match_id)
  }
}

///|
fn QueryCursor::is_match_removed(self : QueryCursor, match_id : Int) -> Bool {
  for id in self.removed_match_ids {
    if id == match_id {
      return true
    }
  }
  false
}

///|
fn QueryCursor::node_is_within_max_start_depth(
  self : QueryCursor,
  depth : Int,
) -> Bool {
  self.max_start_depth < 0 || depth <= self.max_start_depth
}

///|
fn QueryCursor::node_intersects_range(
  self : QueryCursor,
  node : @tree_sitter_mbt.Node,
) -> Bool {
  self.node_intersects_byte_range(node) &&
  self.node_intersects_point_range(node)
}

///|
fn QueryCursor::node_is_contained_in_range(
  self : QueryCursor,
  node : @tree_sitter_mbt.Node,
) -> Bool {
  self.node_is_contained_in_byte_range(node) &&
  self.node_is_contained_in_point_range(node)
}

///|
fn QueryCursor::node_intersects_byte_range(
  self : QueryCursor,
  node : @tree_sitter_mbt.Node,
) -> Bool {
  let range_end = if self.byte_range_end == 0 {
    @api.uint32_max()
  } else {
    self.byte_range_end
  }
  query_byte_ranges_intersect(
    node.start_byte(),
    node.end_byte(),
    self.byte_range_start,
    range_end,
  )
}

///|
fn QueryCursor::node_intersects_point_range(
  self : QueryCursor,
  node : @tree_sitter_mbt.Node,
) -> Bool {
  let range_end = if self.point_range_end == @api.Point::zero() {
    @api.Point::max()
  } else {
    self.point_range_end
  }
  query_point_ranges_intersect(
    node.start_point(),
    node.end_point(),
    self.point_range_start,
    range_end,
  )
}

///|
fn QueryCursor::node_is_contained_in_byte_range(
  self : QueryCursor,
  node : @tree_sitter_mbt.Node,
) -> Bool {
  let range_end = if self.containing_byte_range_end == 0 {
    @api.uint32_max()
  } else {
    self.containing_byte_range_end
  }
  query_byte_range_contains_node(
    node.start_byte(),
    node.end_byte(),
    self.containing_byte_range_start,
    range_end,
  )
}

///|
fn QueryCursor::node_is_contained_in_point_range(
  self : QueryCursor,
  node : @tree_sitter_mbt.Node,
) -> Bool {
  let range_end = if self.containing_point_range_end == @api.Point::zero() {
    @api.Point::max()
  } else {
    self.containing_point_range_end
  }
  query_point_range_contains_node(
    node.start_point(),
    node.end_point(),
    self.containing_point_range_start,
    range_end,
  )
}

///|
fn query_byte_ranges_intersect(
  node_start : UInt,
  node_end : UInt,
  range_start : UInt,
  range_end : UInt,
) -> Bool {
  if node_start == node_end || range_start == range_end {
    node_end >= range_start && node_start <= range_end
  } else {
    node_end > range_start && node_start < range_end
  }
}

///|
fn query_byte_range_contains_node(
  node_start : UInt,
  node_end : UInt,
  range_start : UInt,
  range_end : UInt,
) -> Bool {
  range_start <= node_start && node_end <= range_end
}

///|
fn query_point_range_contains_node(
  node_start : @api.Point,
  node_end : @api.Point,
  range_start : @api.Point,
  range_end : @api.Point,
) -> Bool {
  range_start.lte(node_start) && node_end.lte(range_end)
}

///|
fn query_point_ranges_intersect(
  node_start : @api.Point,
  node_end : @api.Point,
  range_start : @api.Point,
  range_end : @api.Point,
) -> Bool {
  if node_start == node_end || range_start == range_end {
    node_end.gte(range_start) && node_start.lte(range_end)
  } else {
    node_end.gt(range_start) && node_start.lt(range_end)
  }
}

///|
fn query_capture_compare(left : QueryCapture, right : QueryCapture) -> Int {
  let left_start = left.node.start_byte()
  let right_start = right.node.start_byte()
  if left_start < right_start {
    -1
  } else if left_start > right_start {
    1
  } else if left.pattern_index < right.pattern_index {
    -1
  } else if left.pattern_index > right.pattern_index {
    1
  } else if left.index < right.index {
    -1
  } else if left.index > right.index {
    1
  } else {
    0
  }
}

///|
priv struct QueryCandidate {
  node : @tree_sitter_mbt.Node
  depth : Int
}

///|
fn query_collect_public_nodes(
  root : @tree_sitter_mbt.Node,
) -> Array[QueryCandidate] {
  let result = []
  query_push_public_nodes(root, depth=0, result~)
  result
}

///|
fn query_push_public_nodes(
  node : @tree_sitter_mbt.Node,
  depth~ : Int,
  result~ : Array[QueryCandidate],
) -> Unit {
  if node.is_null() {
    return
  }
  result.push({ node, depth })
  // Query roots must not start inside ERROR nodes; (ERROR ...) still works
  // because the ERROR node itself remains a candidate.
  if node.is_error() {
    return
  }
  for i in 0..<node.child_count() {
    query_push_public_nodes(node.child(i), depth=depth + 1, result~)
  }
}

///|
fn query_node_pattern_kind_matches(
  pattern : QueryNodePatternKind,
  node : @tree_sitter_mbt.Node,
) -> Bool {
  match pattern {
    Alternation(_) | Sequence(_) => false
    Supertype(supertype, subtype) => {
      let symbol = node.symbol()
      match subtype {
        Some(subtype_symbol) => symbol == subtype_symbol
        None =>
          query_symbol_array_contains(
            node.language().subtypes(supertype),
            symbol,
          )
      }
    }
    Named(name) => !node.is_error() && node.type_() == name
    Anonymous(name) =>
      !node.is_error() && !node.is_named() && node.type_() == name
    WildcardNamed => node.is_named() && !node.is_error()
    WildcardAny => !node.is_error()
    Error => node.is_error()
    MissingAny => node.is_missing()
    MissingNamed(name) =>
      node.is_missing() && node.is_named() && node.type_() == name
    MissingAnonymous(name) =>
      node.is_missing() && !node.is_named() && node.type_() == name
  }
}

///|
fn query_node_pattern_kind_is_missing(kind : QueryNodePatternKind) -> Bool {
  match kind {
    MissingAny | MissingNamed(_) | MissingAnonymous(_) => true
    _ => false
  }
}

///|
fn query_symbol_array_contains(
  symbols : Array[@api.SymbolId],
  symbol : @api.SymbolId,
) -> Bool {
  for candidate in symbols {
    if candidate == symbol {
      return true
    }
  }
  false
}

///|
priv struct QueryParser {
  language : @tree_sitter_mbt.Language
  source : String
  mut offset : Int
  capture_names : Array[String]
  string_values : Array[String]
}

///|
fn QueryParser::new(
  language : @tree_sitter_mbt.Language,
  source : String,
) -> QueryParser {
  { language, source, offset: 0, capture_names: [], string_values: [] }
}

///|
fn QueryParser::parse(self : QueryParser) -> Query raise QueryError {
  let patterns : Array[QueryPattern] = []
  self.skip_ws_and_comments()
  while !self.is_eof() {
    patterns.push(self.parse_pattern())
    self.skip_ws_and_comments()
  }
  {
    language: self.language,
    patterns,
    capture_names: self.capture_names,
    string_values: self.string_values,
    disabled_capture_ids: query_false_flags(self.capture_names.length()),
    disabled_pattern_indices: query_false_flags(patterns.length()),
  }
}

///|
fn query_false_flags(length : Int) -> Array[Bool] {
  let result : Array[Bool] = []
  for _ in 0..<length {
    result.push(false)
  }
  result
}

///|
fn QueryParser::parse_pattern(
  self : QueryParser,
) -> QueryPattern raise QueryError {
  let start = self.offset
  let predicate_steps : Array[QueryPredicateStep] = []
  let predicate_step_offsets : Array[Int] = []
  let root = match self.peek_char() {
    Some('(') if self.next_paren_starts_grouped_pattern() =>
      self.parse_grouped_pattern(predicate_steps~, predicate_step_offsets~)
    Some('(') =>
      self.parse_parenthesized_node_pattern(
        predicate_steps~,
        predicate_step_offsets~,
      )
    Some('[') =>
      self.parse_alternation_pattern(predicate_steps~, predicate_step_offsets~)
    Some(ch) if query_identifier_start(ch) &&
      self.next_pattern_starts_field_constraint() =>
      self.parse_field_constrained_pattern(
        predicate_steps~,
        predicate_step_offsets~,
      )
    _ => {
      let root = self.parse_bare_pattern()
      self.skip_ws_and_comments()
      self.parse_suffix_modifiers_into(root)
      root
    }
  }
  self.skip_ws_and_comments()
  while self.next_list_starts_predicate() {
    self.parse_predicate_steps(predicate_steps~, predicate_step_offsets~)
    self.skip_ws_and_comments()
  }
  {
    root,
    predicate_steps,
    predicate_step_offsets,
    start_byte: self.source_byte_offset(start),
    end_byte: self.source_byte_offset(self.offset),
  }
}

///|
fn QueryParser::parse_grouped_pattern(
  self : QueryParser,
  predicate_steps~ : Array[QueryPredicateStep],
  predicate_step_offsets~ : Array[Int],
) -> QueryNodePattern raise QueryError {
  let start = self.offset
  self.expect_char('(')
  self.skip_ws_and_comments()
  let elements : Array[QueryNodePattern] = []
  let mut saw_anchor = false
  let mut pending_anchor_before = false
  let mut pending_anchor_after = false
  while self.grouped_pattern_has_member_or_anchor() {
    if self.peek_char() == Some('.') {
      self.offset += 1
      saw_anchor = true
      pending_anchor_before = true
      pending_anchor_after = true
    } else {
      let element = self.parse_grouped_pattern_member(
        predicate_steps~,
        predicate_step_offsets~,
      )
      if pending_anchor_before {
        element.anchor_before = true
        pending_anchor_before = false
        pending_anchor_after = false
      }
      elements.push(element)
    }
    self.skip_ws_and_comments()
  }
  if saw_anchor && elements.is_empty() {
    raise self.syntax_error(self.offset, "anchor requires a grouped pattern")
  }
  if pending_anchor_after && elements.length() > 0 {
    elements[elements.length() - 1].anchor_after = true
  }
  while self.next_list_starts_predicate() {
    self.parse_predicate_steps(predicate_steps~, predicate_step_offsets~)
    self.skip_ws_and_comments()
  }
  self.expect_char(')')
  self.skip_ws_and_comments()
  let root = match elements.length() {
    1 => elements[0]
    _ =>
      query_node_pattern(
        Sequence(elements),
        start_byte=self.source_byte_offset(start),
      )
  }
  self.parse_suffix_modifiers_into(root)
  root
}

///|
fn QueryParser::parse_grouped_pattern_member(
  self : QueryParser,
  predicate_steps~ : Array[QueryPredicateStep],
  predicate_step_offsets~ : Array[Int],
) -> QueryNodePattern raise QueryError {
  match self.peek_char() {
    Some('(') if self.next_paren_starts_grouped_pattern() =>
      self.parse_grouped_pattern(predicate_steps~, predicate_step_offsets~)
    Some('(') =>
      self.parse_parenthesized_node_pattern(
        predicate_steps~,
        predicate_step_offsets~,
      )
    Some('[') =>
      self.parse_alternation_pattern(predicate_steps~, predicate_step_offsets~)
    Some('"') => self.parse_bare_child_pattern()
    Some('_') if self.next_child_starts_bare_wildcard() =>
      self.parse_bare_child_pattern()
    _ => raise self.syntax_error(self.offset, "expected grouped pattern")
  }
}

///|
fn QueryParser::grouped_pattern_has_member_or_anchor(
  self : QueryParser,
) -> Bool {
  match self.peek_char() {
    Some('.') => true
    Some('[') => true
    Some('"') => true
    Some('(') => !self.next_list_starts_predicate()
    Some('_') if self.next_child_starts_bare_wildcard() => true
    None => false
    _ => false
  }
}

///|
fn QueryParser::next_paren_starts_grouped_pattern(self : QueryParser) -> Bool {
  if self.peek_char() == Some('(') {
    match self.peek_non_ws_char_after(self.offset + 1) {
      Some('(') | Some('[') | Some('"') => true
      _ => false
    }
  } else {
    false
  }
}

///|
fn QueryParser::source_byte_offset(self : QueryParser, offset : Int) -> Int {
  let mut byte_offset = 0
  for index = 0; index < offset; {
    match self.source.get_char(index) {
      Some(ch) => {
        byte_offset += @utf8.encode(ch.to_string()).length()
        continue index + ch.utf16_len()
      }
      None => break
    }
  }
  byte_offset
}

///|
fn QueryParser::syntax_error(
  self : QueryParser,
  offset : Int,
  reason : String,
) -> QueryError {
  QueryError::Syntax(byte_offset=self.source_byte_offset(offset), reason~)
}

///|
fn QueryParser::node_type_error(
  self : QueryParser,
  offset : Int,
  name : String,
) -> QueryError {
  QueryError::NodeType(byte_offset=self.source_byte_offset(offset), name~)
}

///|
fn QueryParser::field_error(
  self : QueryParser,
  offset : Int,
  name : String,
) -> QueryError {
  QueryError::Field(byte_offset=self.source_byte_offset(offset), name~)
}

///|
fn QueryParser::capture_error(
  self : QueryParser,
  offset : Int,
  name : String,
) -> QueryError {
  QueryError::Capture(byte_offset=self.source_byte_offset(offset), name~)
}

///|
fn QueryParser::structure_error(
  self : QueryParser,
  offset : Int,
  reason : String,
) -> QueryError {
  QueryError::Structure(byte_offset=self.source_byte_offset(offset), reason~)
}

///|
fn QueryParser::parse_parenthesized_node_pattern(
  self : QueryParser,
  predicate_steps~ : Array[QueryPredicateStep],
  predicate_step_offsets~ : Array[Int],
) -> QueryNodePattern raise QueryError {
  let start = self.offset
  self.expect_char('(')
  self.skip_ws_and_comments()
  let node_pattern = self.parse_node_pattern(
    predicate_steps~,
    predicate_step_offsets~,
  )
  node_pattern.start_byte = self.source_byte_offset(start)
  self.skip_ws_and_comments()
  self.expect_char(')')
  self.skip_ws_and_comments()
  self.parse_suffix_modifiers_into(node_pattern)
  node_pattern
}

///|
fn QueryParser::parse_suffix_modifiers_into(
  self : QueryParser,
  node_pattern : QueryNodePattern,
) -> Unit raise QueryError {
  let mut quantifier = One
  while true {
    match self.peek_char() {
      Some('?') => {
        self.offset += 1
        quantifier = query_join_capture_quantifiers(ZeroOrOne, quantifier)
        self.skip_ws_and_comments()
      }
      Some('*') => {
        self.offset += 1
        quantifier = query_join_capture_quantifiers(ZeroOrMore, quantifier)
        self.skip_ws_and_comments()
      }
      Some('+') => {
        self.offset += 1
        quantifier = query_join_capture_quantifiers(OneOrMore, quantifier)
        self.skip_ws_and_comments()
      }
      Some('@') => {
        node_pattern.capture_ids.push(self.parse_capture())
        self.skip_ws_and_comments()
      }
      _ => break
    }
  }
  node_pattern.quantifier = quantifier
}

///|
fn QueryParser::parse_bare_pattern(
  self : QueryParser,
) -> QueryNodePattern raise QueryError {
  match self.peek_char() {
    Some('_') => {
      let start = self.offset
      self.offset += 1
      query_node_pattern(WildcardAny, start_byte=self.source_byte_offset(start))
    }
    Some('"') => {
      let start = self.offset
      let value = self.parse_string_literal()
      self.intern_string(value) |> ignore
      match self.language.symbol_for_name(value, is_named=false) {
        Some(_) =>
          query_node_pattern(
            Anonymous(value),
            start_byte=self.source_byte_offset(start),
          )
        None => raise self.node_type_error(start, value)
      }
    }
    _ => raise self.syntax_error(self.offset, "expected pattern")
  }
}

///|
fn QueryParser::parse_node_pattern(
  self : QueryParser,
  predicate_steps~ : Array[QueryPredicateStep],
  predicate_step_offsets~ : Array[Int],
) -> QueryNodePattern raise QueryError {
  let kind_start = self.offset
  let kind = match self.peek_char() {
    Some('_') => {
      self.offset += 1
      WildcardNamed
    }
    Some('"') => {
      let start = self.offset
      let value = self.parse_string_literal()
      self.intern_string(value) |> ignore
      match self.language.symbol_for_name(value, is_named=false) {
        Some(_) => Anonymous(value)
        None => raise self.node_type_error(start, value)
      }
    }
    Some(_) => {
      let start = self.offset
      let name = self.parse_identifier()
      if self.peek_char() == Some('/') {
        self.parse_supertype_pattern(start, name)
      } else {
        match name {
          // Intentional divergence from upstream's prefix matching quirk:
          // special query node names are recognized exactly.
          "ERROR" => Error
          "MISSING" => self.parse_missing_pattern(start)
          _ =>
            match self.language.symbol_for_name(name, is_named=true) {
              Some(symbol) =>
                match self.language.symbol_type(symbol) {
                  Some(@api.SymbolType::Supertype) => Supertype(symbol, None)
                  _ => Named(name)
                }
              None => raise self.node_type_error(start, name)
            }
        }
      }
    }
    None => raise self.syntax_error(self.offset, "expected node pattern")
  }
  self.skip_ws_and_comments()
  if query_node_pattern_kind_is_missing(kind) && self.peek_char() != Some(')') {
    raise self.syntax_error(
      self.offset,
      "unexpected child in missing node pattern",
    )
  }
  let negated_field_names : Array[String] = []
  while self.peek_char() == Some('!') {
    negated_field_names.push(self.parse_negated_field())
    self.skip_ws_and_comments()
  }
  let children : Array[QueryNodePattern] = []
  let mut saw_anchor = false
  let mut pending_anchor_before = false
  let mut pending_anchor_after = false
  while self.node_pattern_has_child_or_anchor() ||
        self.next_list_starts_predicate() {
    if self.next_list_starts_predicate() {
      self.parse_predicate_steps(predicate_steps~, predicate_step_offsets~)
    } else if self.peek_char() == Some('.') {
      self.offset += 1
      saw_anchor = true
      pending_anchor_before = true
      pending_anchor_after = true
    } else {
      let child = self.parse_child_pattern(
        predicate_steps~,
        predicate_step_offsets~,
      )
      if pending_anchor_before {
        child.anchor_before = true
        pending_anchor_before = false
        pending_anchor_after = false
      }
      children.push(child)
    }
    self.skip_ws_and_comments()
  }
  if saw_anchor && children.is_empty() {
    raise self.syntax_error(self.offset, "anchor requires a child pattern")
  }
  if pending_anchor_after && children.length() > 0 {
    let last = children[children.length() - 1]
    last.anchor_after = true
  }
  if !children.is_empty() &&
    query_node_pattern_kind_cannot_have_children(kind, self.language) {
    raise self.structure_error(kind_start, "node pattern cannot have children")
  }
  query_node_pattern(kind, negated_field_names~, children~)
}

///|
fn query_node_pattern_kind_cannot_have_children(
  kind : QueryNodePatternKind,
  language : @tree_sitter_mbt.Language,
) -> Bool {
  match kind {
    Anonymous(_) => true
    Named(name) =>
      match language.symbol_for_name(name, is_named=true) {
        Some(symbol) => query_symbol_cannot_have_children(language, symbol)
        None => false
      }
    Supertype(_, Some(subtype)) =>
      language.symbol_type(subtype) == Some(@api.SymbolType::Anonymous) ||
      query_symbol_cannot_have_children(language, subtype)
    _ => false
  }
}

///|
fn query_symbol_cannot_have_children(
  language : @tree_sitter_mbt.Language,
  symbol : @api.SymbolId,
) -> Bool {
  symbol.value() < language.token_count().reinterpret_as_uint()
}

///|
fn QueryParser::parse_supertype_pattern(
  self : QueryParser,
  start : Int,
  name : String,
) -> QueryNodePatternKind raise QueryError {
  guard self.language.symbol_for_name(name, is_named=true) is Some(supertype) else {
    raise self.node_type_error(start, name)
  }
  if self.language.symbol_type(supertype) != Some(@api.SymbolType::Supertype) {
    raise self.node_type_error(start, name)
  }
  self.expect_char('/')
  let subtype_start = self.offset
  let (subtype_name, subtype) = self.parse_supertype_subtype_symbol(
    subtype_start,
  )
  if !query_symbol_array_contains(self.language.subtypes(supertype), subtype) {
    raise self.node_type_error(subtype_start, subtype_name)
  }
  Supertype(supertype, Some(subtype))
}

///|
fn QueryParser::parse_supertype_subtype_symbol(
  self : QueryParser,
  start : Int,
) -> (String, @api.SymbolId) raise QueryError {
  match self.peek_char() {
    Some('"') => {
      let value = self.parse_string_literal()
      self.intern_string(value) |> ignore
      match self.language.symbol_for_name(value, is_named=false) {
        Some(symbol) => (value, symbol)
        None => raise self.node_type_error(start, value)
      }
    }
    Some(_) => {
      let name = self.parse_identifier()
      match self.language.symbol_for_name(name, is_named=true) {
        Some(symbol) => (name, symbol)
        None => raise self.node_type_error(start, name)
      }
    }
    None => raise self.syntax_error(start, "expected supertype subtype")
  }
}

///|
fn QueryParser::node_pattern_has_child_or_anchor(self : QueryParser) -> Bool {
  match self.peek_char() {
    Some('.') => true
    Some('[') => true
    Some('"') => true
    Some('(') => !self.next_list_starts_predicate()
    Some(ch) => query_identifier_start(ch)
    None => false
  }
}

///|
fn QueryParser::parse_negated_field(
  self : QueryParser,
) -> String raise QueryError {
  self.expect_char('!')
  self.skip_ws_and_comments()
  let start = self.offset
  let name = self.parse_identifier()
  if name.is_empty() {
    raise self.syntax_error(start, "expected field name")
  }
  if self.language.field_id_for_name(name) is None {
    raise self.field_error(start, name)
  }
  name
}

///|
fn QueryParser::parse_child_pattern(
  self : QueryParser,
  predicate_steps~ : Array[QueryPredicateStep],
  predicate_step_offsets~ : Array[Int],
) -> QueryNodePattern raise QueryError {
  let mut field_name : String? = None
  let mut field_step_start_byte : Int? = None
  if self.child_starts_with_field_constraint() {
    let field_start = self.offset
    field_step_start_byte = Some(self.source_byte_offset(field_start))
    let name = self.parse_identifier()
    if self.language.field_id_for_name(name) is None {
      raise self.field_error(field_start, name)
    }
    field_name = Some(name)
    self.skip_ws_and_comments()
    self.expect_char(':')
    self.skip_ws_and_comments()
  }
  let child = self.parse_child_body_pattern(
    predicate_steps~,
    predicate_step_offsets~,
  )
  {
    kind: child.kind,
    field_name,
    start_byte: field_step_start_byte.unwrap_or(child.start_byte),
    negated_field_names: child.negated_field_names,
    quantifier: child.quantifier,
    anchor_before: child.anchor_before,
    anchor_after: child.anchor_after,
    capture_ids: child.capture_ids,
    children: child.children,
  }
}

///|
fn QueryParser::parse_field_constrained_pattern(
  self : QueryParser,
  predicate_steps~ : Array[QueryPredicateStep],
  predicate_step_offsets~ : Array[Int],
) -> QueryNodePattern raise QueryError {
  let field_start = self.offset
  let name = self.parse_identifier()
  if self.language.field_id_for_name(name) is None {
    raise self.field_error(field_start, name)
  }
  self.skip_ws_and_comments()
  self.expect_char(':')
  self.skip_ws_and_comments()
  let pattern = self.parse_child_body_pattern(
    predicate_steps~,
    predicate_step_offsets~,
  )
  {
    kind: pattern.kind,
    field_name: Some(name),
    start_byte: self.source_byte_offset(field_start),
    negated_field_names: pattern.negated_field_names,
    quantifier: pattern.quantifier,
    anchor_before: pattern.anchor_before,
    anchor_after: pattern.anchor_after,
    capture_ids: pattern.capture_ids,
    children: pattern.children,
  }
}

///|
fn QueryParser::child_starts_with_field_constraint(self : QueryParser) -> Bool {
  match self.identifier_end_after(self.offset) {
    Some(end) => self.peek_non_ws_char_after(end) == Some(':')
    None => false
  }
}

///|
fn QueryParser::next_pattern_starts_field_constraint(
  self : QueryParser,
) -> Bool {
  match self.identifier_end_after(self.offset) {
    Some(end) => self.peek_non_ws_char_after(end) == Some(':')
    None => false
  }
}

///|
fn QueryParser::identifier_end_after(self : QueryParser, offset : Int) -> Int? {
  guard self.source.get_char(offset) is Some(first) &&
    query_identifier_start(first) else {
    return None
  }
  let mut next = offset + first.utf16_len()
  while self.source.get_char(next) is Some(ch) && query_identifier_continue(ch) {
    next += ch.utf16_len()
  }
  Some(next)
}

///|
fn QueryParser::parse_child_body_pattern(
  self : QueryParser,
  predicate_steps~ : Array[QueryPredicateStep],
  predicate_step_offsets~ : Array[Int],
) -> QueryNodePattern raise QueryError {
  match self.peek_char() {
    Some('[') =>
      self.parse_alternation_pattern(predicate_steps~, predicate_step_offsets~)
    Some('(') if self.next_paren_starts_grouped_pattern() =>
      self.parse_grouped_pattern(predicate_steps~, predicate_step_offsets~)
    Some('(') =>
      self.parse_parenthesized_node_pattern(
        predicate_steps~,
        predicate_step_offsets~,
      )
    Some('"') => self.parse_bare_child_pattern()
    Some('_') if self.next_child_starts_bare_wildcard() =>
      self.parse_bare_child_pattern()
    _ =>
      self.parse_parenthesized_node_pattern(
        predicate_steps~,
        predicate_step_offsets~,
      )
  }
}

///|
fn QueryParser::next_child_starts_bare_wildcard(self : QueryParser) -> Bool {
  self.peek_char() == Some('_') &&
  self.peek_non_ws_char_after(self.offset + 1) != Some(':')
}

///|
fn QueryParser::parse_alternation_pattern(
  self : QueryParser,
  predicate_steps~ : Array[QueryPredicateStep],
  predicate_step_offsets~ : Array[Int],
) -> QueryNodePattern raise QueryError {
  let start = self.offset
  self.expect_char('[')
  self.skip_ws_and_comments()
  if self.peek_char() == Some(']') {
    raise self.syntax_error(self.offset, "expected alternation pattern")
  }
  let alternatives : Array[QueryNodePattern] = []
  while self.peek_char() != Some(']') {
    alternatives.push(
      self.parse_alternation_alternative(
        predicate_steps~,
        predicate_step_offsets~,
      ),
    )
    self.skip_ws_and_comments()
  }
  self.expect_char(']')
  self.skip_ws_and_comments()
  let pattern = query_node_pattern(
    Alternation(alternatives),
    start_byte=self.source_byte_offset(start),
  )
  self.parse_suffix_modifiers_into(pattern)
  pattern
}

///|
fn QueryParser::parse_alternation_alternative(
  self : QueryParser,
  predicate_steps~ : Array[QueryPredicateStep],
  predicate_step_offsets~ : Array[Int],
) -> QueryNodePattern raise QueryError {
  match self.peek_char() {
    Some('(') if self.next_paren_starts_grouped_pattern() =>
      self.parse_grouped_pattern(predicate_steps~, predicate_step_offsets~)
    Some('(') =>
      self.parse_parenthesized_node_pattern(
        predicate_steps~,
        predicate_step_offsets~,
      )
    Some('[') =>
      self.parse_alternation_pattern(predicate_steps~, predicate_step_offsets~)
    Some('"') => self.parse_bare_child_pattern()
    Some('_') => self.parse_bare_child_pattern()
    _ => raise self.syntax_error(self.offset, "expected alternation pattern")
  }
}

///|
fn QueryParser::parse_bare_child_pattern(
  self : QueryParser,
) -> QueryNodePattern raise QueryError {
  let child = self.parse_bare_pattern()
  self.skip_ws_and_comments()
  self.parse_suffix_modifiers_into(child)
  child
}

///|
fn query_node_pattern(
  kind : QueryNodePatternKind,
  field_name? : String,
  start_byte? : Int = 0,
  negated_field_names? : Array[String] = [],
  quantifier? : QueryCaptureQuantifier = One,
  anchor_before? : Bool = false,
  anchor_after? : Bool = false,
  children? : Array[QueryNodePattern] = [],
) -> QueryNodePattern {
  {
    kind,
    field_name,
    start_byte,
    negated_field_names,
    quantifier,
    anchor_before,
    anchor_after,
    capture_ids: [],
    children,
  }
}

///|
fn QueryParser::parse_missing_pattern(
  self : QueryParser,
  _start : Int,
) -> QueryNodePatternKind raise QueryError {
  self.skip_ws_and_comments()
  match self.peek_char() {
    Some(')') => MissingAny
    Some('"') => {
      let start = self.offset
      let value = self.parse_string_literal()
      self.intern_string(value) |> ignore
      match self.language.symbol_for_name(value, is_named=false) {
        Some(_) => MissingAnonymous(value)
        None => raise self.node_type_error(start, value)
      }
    }
    Some(_) => {
      let start = self.offset
      let name = self.parse_identifier()
      match self.language.symbol_for_name(name, is_named=true) {
        Some(_) => MissingNamed(name)
        None => raise self.node_type_error(start, name)
      }
    }
    None =>
      raise self.syntax_error(self.offset, "expected missing node pattern")
  }
}

///|
fn QueryParser::parse_capture(self : QueryParser) -> Int raise QueryError {
  self.expect_char('@')
  let start = self.offset
  let name = self.parse_identifier()
  if name.is_empty() {
    raise self.syntax_error(start, "expected capture name")
  }
  self.intern_capture(name)
}

///|
fn QueryParser::parse_predicate_capture(
  self : QueryParser,
) -> Int raise QueryError {
  self.expect_char('@')
  let start = self.offset
  let name = self.parse_identifier()
  match self.capture_id_for_name(name) {
    Some(capture_id) => capture_id
    None => raise self.capture_error(start, name)
  }
}

///|
fn QueryParser::parse_predicate_steps(
  self : QueryParser,
  predicate_steps~ : Array[QueryPredicateStep],
  predicate_step_offsets~ : Array[Int],
) -> Unit raise QueryError {
  self.expect_char('(')
  self.skip_ws_and_comments()
  self.expect_predicate_marker()
  let operator_start = self.offset
  let operator = self.parse_predicate_operator(operator_start)
  predicate_steps.push(String(self.intern_string(operator)))
  predicate_step_offsets.push(self.source_byte_offset(operator_start))
  self.skip_ws_and_comments()
  while self.peek_char() is Some(ch) && ch != ')' {
    let step_start = self.offset
    match ch {
      '@' => {
        let capture_id = self.parse_predicate_capture()
        predicate_steps.push(Capture(capture_id))
      }
      '"' =>
        predicate_steps.push(
          String(self.intern_string(self.parse_string_literal())),
        )
      _ =>
        predicate_steps.push(
          String(self.intern_string(self.parse_identifier())),
        )
    }
    predicate_step_offsets.push(self.source_byte_offset(step_start))
    self.skip_ws_and_comments()
  }
  let done_start = self.offset
  self.expect_char(')')
  predicate_steps.push(Done)
  predicate_step_offsets.push(self.source_byte_offset(done_start))
}

///|
fn QueryParser::parse_predicate_operator(
  self : QueryParser,
  start : Int,
) -> String raise QueryError {
  let name = self.parse_identifier()
  match self.peek_char() {
    Some('?') => {
      self.offset += 1
      name + "?"
    }
    Some('!') => {
      self.offset += 1
      name + "!"
    }
    _ => raise self.syntax_error(start, "expected predicate name")
  }
}

///|
fn QueryParser::expect_predicate_marker(
  self : QueryParser,
) -> Unit raise QueryError {
  match self.peek_char() {
    Some('#') | Some('.') => self.offset += 1
    Some(_) => raise self.syntax_error(self.offset, "expected predicate marker")
    None => raise self.syntax_error(self.offset, "expected predicate marker")
  }
}

///|
fn QueryParser::parse_identifier(self : QueryParser) -> String raise QueryError {
  let start = self.offset
  guard self.peek_char() is Some(first) && query_identifier_start(first) else {
    raise self.syntax_error(start, "expected identifier")
  }
  let builder = StringBuilder::new()
  builder.write_char(first)
  self.offset += first.utf16_len()
  while self.peek_char() is Some(ch) && query_identifier_continue(ch) {
    builder.write_char(ch)
    self.offset += ch.utf16_len()
  }
  builder.to_string()
}

///|
fn QueryParser::parse_string_literal(
  self : QueryParser,
) -> String raise QueryError {
  self.expect_char('"')
  let builder = StringBuilder::new()
  while self.peek_char() is Some(ch) {
    if ch == '"' {
      self.offset += 1
      return builder.to_string()
    }
    if ch == '\n' || ch == '\r' {
      raise self.syntax_error(self.offset, "newline in string literal")
    }
    if ch == '\\' {
      self.offset += 1
      guard self.peek_char() is Some(escaped) else {
        raise self.syntax_error(self.offset, "unterminated string literal")
      }
      builder.write_char(query_escape_char(escaped))
      self.offset += escaped.utf16_len()
    } else {
      builder.write_char(ch)
      self.offset += ch.utf16_len()
    }
  }
  raise self.syntax_error(self.offset, "unterminated string literal")
}

///|
fn QueryParser::intern_capture(self : QueryParser, name : String) -> Int {
  for i in 0..<self.capture_names.length() {
    if self.capture_names[i] == name {
      return i
    }
  }
  self.capture_names.push(name)
  self.capture_names.length() - 1
}

///|
fn QueryParser::capture_id_for_name(self : QueryParser, name : String) -> Int? {
  for i in 0..<self.capture_names.length() {
    if self.capture_names[i] == name {
      return Some(i)
    }
  }
  None
}

///|
fn QueryParser::intern_string(self : QueryParser, value : String) -> Int {
  for i in 0..<self.string_values.length() {
    if self.string_values[i] == value {
      return i
    }
  }
  self.string_values.push(value)
  self.string_values.length() - 1
}

///|
fn QueryParser::expect_char(
  self : QueryParser,
  expected : Char,
) -> Unit raise QueryError {
  match self.peek_char() {
    Some(ch) =>
      if ch == expected {
        self.offset += ch.utf16_len()
      } else {
        raise self.syntax_error(self.offset, "expected '\{expected}'")
      }
    None => raise self.syntax_error(self.offset, "expected '\{expected}'")
  }
}

///|
fn QueryParser::skip_ws_and_comments(self : QueryParser) -> Unit {
  while true {
    match self.peek_char() {
      Some(ch) if ch.is_whitespace() => self.offset += ch.utf16_len()
      Some(';') =>
        while self.peek_char() is Some(comment_ch) {
          self.offset += comment_ch.utf16_len()
          if comment_ch == '\n' {
            break
          }
        }
      _ => return
    }
  }
}

///|
fn QueryParser::peek_char(self : QueryParser) -> Char? {
  self.source.get_char(self.offset)
}

///|
fn QueryParser::peek_non_ws_char_after(
  self : QueryParser,
  offset : Int,
) -> Char? {
  for next = offset; next < self.source.length(); {
    match self.source.get_char(next) {
      Some(ch) if ch.is_whitespace() => continue next + ch.utf16_len()
      Some(';') => {
        let mut comment_next = next
        while self.source.get_char(comment_next) is Some(comment_ch) {
          comment_next += comment_ch.utf16_len()
          if comment_ch == '\n' {
            break
          }
        }
        continue comment_next
      }
      Some(ch) => return Some(ch)
      None => return None
    }
  } nobreak {
    None
  }
}

///|
fn QueryParser::next_list_starts_predicate(self : QueryParser) -> Bool {
  if self.peek_char() == Some('(') {
    match self.peek_non_ws_char_after(self.offset + 1) {
      Some('#') | Some('.') => true
      _ => false
    }
  } else {
    false
  }
}

///|
fn QueryParser::is_eof(self : QueryParser) -> Bool {
  self.offset >= self.source.length()
}

///|
fn query_identifier_start(ch : Char) -> Bool {
  ch == '_' ||
  ch == '-' ||
  ch.is_numeric() ||
  ch.is_ascii_alphabetic() ||
  query_char_is_unicode_letter(ch)
}

///|
fn query_identifier_continue(ch : Char) -> Bool {
  query_identifier_start(ch) || ch == '.'
}

///|
fn query_char_is_unicode_letter(ch : Char) -> Bool {
  // Mirrors the Unicode-letter subset currently used by generator regex
  // property lowering; a full Unicode category table can broaden this later.
  let code = ch.to_uint()
  query_code_in_range(code, 192U, 214U) ||
  query_code_in_range(code, 216U, 255U) ||
  query_code_in_range(code, 345U, 347U) ||
  code == 357U ||
  query_code_in_range(code, 384U, 385U) ||
  code == 390U ||
  code == 391U ||
  query_code_in_range(code, 393U, 394U) ||
  query_code_in_range(code, 398U, 401U) ||
  code == 404U ||
  query_code_in_range(code, 406U, 408U) ||
  query_code_in_range(code, 880U, 1023U) ||
  query_code_in_range(code, 4256U, 4351U) ||
  query_code_in_range(code, 12592U, 12687U) ||
  query_code_in_range(code, 19968U, 40959U) ||
  query_code_in_range(code, 44032U, 55203U)
}

///|
fn query_code_in_range(code : UInt, start : UInt, end : UInt) -> Bool {
  start <= code && code <= end
}

///|
fn query_escape_char(ch : Char) -> Char {
  match ch {
    'n' => '\n'
    'r' => '\r'
    't' => '\t'
    '0' => '\u0000'
    other => other
  }
}
