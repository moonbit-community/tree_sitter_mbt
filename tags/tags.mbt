///|
pub(all) suberror TagsError {
  Cancelled(TagsProgressState)
  InvalidCaptureName(String)
  LanguageFailed(@tree_sitter_mbt.LanguageError)
  ParseFailed(@tree_sitter_mbt.ParseError)
  PredicateFailed(@query.QueryPredicateError)
  QueryFailed(@query.QueryError)
}

///|
pub(all) enum TagsProgressPhase {
  Parse
  Query
} derive(Eq, Debug)

///|
pub(all) struct TagsProgressState {
  phase : TagsProgressPhase
  current_byte_offset : UInt
} derive(Eq, Debug)

///|
pub(all) struct TagsOptions {
  cancellation_state : TagsProgressState?
  progress_callback : ((TagsProgressState) -> Bool)?
}

///|
pub(all) enum TagKind {
  Definition
  Reference
} derive(Eq, Debug)

///|
pub(all) struct Utf16ColumnRange {
  start : UInt
  end : UInt
} derive(Eq, Debug)

///|
pub(all) struct Tag {
  name : String
  syntax_type : String
  kind : TagKind
  range : @api.Range
  name_range : @api.Range
  line_range : @api.Range
  span : @api.Range
  utf16_column_range : Utf16ColumnRange
  docs : String
} derive(Eq, Debug)

///|
pub(all) struct TagsResult {
  tags : Array[Tag]
  has_error : Bool
} derive(Eq, Debug)

///|
struct TagsConfiguration {
  language : @tree_sitter_mbt.Language
  query : @query.Query
  tags_pattern_start : Int
  local_definition_capture_index : Int?
  local_scope_capture_index : Int?
  local_scope_inherits_patterns : Array[Bool]
  non_local_patterns : Array[Bool]
  general_predicates : Array[@query.QueryGeneralPredicate]
}

///|
priv struct TagsLocalScope {
  start_byte : UInt
  end_byte : UInt
  inherits : Bool
}

///|
priv struct TagsLocalDefinition {
  start_byte : UInt
  name : Bytes
  scope_index : Int
}

///|
priv struct TagQueueEntry {
  tag : Tag
  pattern_index : Int
  ignored : Bool
}

///|
pub fn TagsConfiguration::new(
  language : @tree_sitter_mbt.Language,
  tags_query : String,
  locals_query? : String = "",
) -> TagsConfiguration raise TagsError {
  let local_query = compile_tags_query(language, locals_query)
  let tags_pattern_start = local_query.pattern_count()
  let query = compile_tags_query(
    language,
    combine_tags_query_sources([locals_query, tags_query]),
  )
  validate_tags_capture_names(query)
  let classes = classify_tags_query_predicates(query)
  {
    language,
    query,
    tags_pattern_start,
    local_definition_capture_index: tags_capture_id(query, "local.definition"),
    local_scope_capture_index: tags_capture_id(query, "local.scope"),
    local_scope_inherits_patterns: tags_local_scope_inherits_patterns(
      query.pattern_count(),
      classes.property_settings,
    ),
    non_local_patterns: tags_non_local_patterns(
      query.pattern_count(),
      classes.property_assertions,
    ),
    general_predicates: classes.general_predicates,
  }
}

///|
pub fn TagsConfiguration::tags_pattern_start(self : TagsConfiguration) -> Int {
  self.tags_pattern_start
}

///|
pub fn TagsConfiguration::pattern_count(self : TagsConfiguration) -> Int {
  self.query.pattern_count()
}

///|
pub fn TagsConfiguration::names(self : TagsConfiguration) -> Array[String] {
  let names : Array[String] = []
  for capture_id in 0..<self.query.capture_count() {
    match self.query.capture_name_for_id(capture_id) {
      Some(name) => names.push(name)
      None => ()
    }
  }
  names
}

///|
pub fn TagsProgressState::new(
  phase~ : TagsProgressPhase,
  current_byte_offset~ : UInt,
) -> TagsProgressState {
  { phase, current_byte_offset }
}

///|
pub fn TagsOptions::default() -> TagsOptions {
  { cancellation_state: None, progress_callback: None }
}

///|
pub fn TagsOptions::cancelled(state : TagsProgressState) -> TagsOptions {
  { cancellation_state: Some(state), progress_callback: None }
}

///|
pub fn TagsOptions::progress(
  callback : (TagsProgressState) -> Bool,
) -> TagsOptions {
  { cancellation_state: None, progress_callback: Some(callback) }
}

///|
pub fn generate_tags(
  config : TagsConfiguration,
  source : Bytes,
  options? : TagsOptions = TagsOptions::default(),
) -> TagsResult raise TagsError {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(config.language) catch {
    err => raise TagsError::LanguageFailed(err)
  }
  maybe_cancel_tags(
    options,
    TagsProgressState::new(phase=Parse, current_byte_offset=0U),
  )
  let tree = parser.parse_bytes(source, options=tags_parse_options(options)) catch {
    @tree_sitter_mbt.ParseError::Cancelled(state) =>
      raise TagsError::Cancelled(
        TagsProgressState::new(
          phase=Parse,
          current_byte_offset=state.current_byte_offset,
        ),
      )
    err => raise TagsError::ParseFailed(err)
  }
  let matches = collect_tags_query_matches(
    config.query,
    source,
    tree.root_node(),
    options,
  )
  let scopes = collect_tags_local_scopes(
    config,
    source.length().reinterpret_as_uint(),
    matches,
  )
  let definitions = collect_tags_local_definitions(
    config, source, matches, scopes,
  )
  let tag_queue : Array[TagQueueEntry] = []
  for matched in matches {
    if matched.pattern_index < config.tags_pattern_start {
      continue
    }
    match tag_from_match(config, source, matched, scopes, definitions) {
      Some(tag) =>
        if tag.kind is Definition || tag.kind is Reference {
          tag_queue.push({
            tag,
            pattern_index: matched.pattern_index,
            ignored: tag_match_has_ignore(matched),
          })
        }
      None => ()
    }
  }
  { tags: drain_tag_queue(tag_queue), has_error: tree.root_node().has_error() }
}

///|
fn tags_parse_options(options : TagsOptions) -> @tree_sitter_mbt.ParseOptions {
  @tree_sitter_mbt.ParseOptions::progress(state => {
    tags_cancellation_state(
      options,
      TagsProgressState::new(
        phase=Parse,
        current_byte_offset=state.current_byte_offset,
      ),
    )
    is Some(_)
  })
}

///|
fn tags_cancellation_state(
  options : TagsOptions,
  state : TagsProgressState,
) -> TagsProgressState? {
  match options.cancellation_state {
    Some(cancelled_state) => Some(cancelled_state)
    None =>
      match options.progress_callback {
        Some(callback) => if callback(state) { Some(state) } else { None }
        None => None
      }
  }
}

///|
fn maybe_cancel_tags(
  options : TagsOptions,
  state : TagsProgressState,
) -> Unit raise TagsError {
  match tags_cancellation_state(options, state) {
    Some(cancelled_state) => raise TagsError::Cancelled(cancelled_state)
    None => ()
  }
}

///|
fn compile_tags_query(
  language : @tree_sitter_mbt.Language,
  source : String,
) -> @query.Query raise TagsError {
  @query.Query::new(language, source) catch {
    err => raise TagsError::QueryFailed(err)
  }
}

///|
fn combine_tags_query_sources(sources : Array[String]) -> String {
  let out = StringBuilder::new()
  let mut needs_newline = false
  for source in sources {
    if source.is_empty() {
      continue
    }
    if needs_newline {
      out.write_char('\n')
    }
    out.write_string(source)
    needs_newline = true
  }
  out.to_string()
}

///|
fn classify_tags_query_predicates(
  query : @query.Query,
) -> @query.QueryPredicateClasses raise TagsError {
  query.classify_predicates() catch {
    err => raise TagsError::PredicateFailed(err)
  }
}

///|
fn collect_tags_query_matches(
  query : @query.Query,
  source : Bytes,
  root : @tree_sitter_mbt.Node,
  options : TagsOptions,
) -> Array[@query.QueryMatch] raise TagsError {
  let cursor = @query.QueryCursor::new()
  let cancelled_states : Array[TagsProgressState] = []
  cursor.set_progress_callback(
    Some(state => {
      let tags_state = TagsProgressState::new(
        phase=Query,
        current_byte_offset=state.current_byte_offset,
      )
      match tags_cancellation_state(options, tags_state) {
        Some(cancelled_state) => {
          cancelled_states.push(cancelled_state)
          true
        }
        None => false
      }
    }),
  )
  cursor.exec(query, root)
  match cancelled_states.get(0) {
    Some(state) => raise TagsError::Cancelled(state)
    None => ()
  }
  let matches : Array[@query.QueryMatch] = []
  while true {
    let matched = cursor.next_match_with_text_predicates_bytes(query, source) catch {
      err => raise TagsError::PredicateFailed(err)
    }
    match matched {
      Some(matched) => matches.push(matched)
      None => break
    }
  }
  matches
}

///|
fn tags_capture_id(query : @query.Query, capture_name : String) -> Int? {
  for capture_id in 0..<query.capture_count() {
    if query.capture_name_for_id(capture_id) == Some(capture_name) {
      return Some(capture_id)
    }
  }
  None
}

///|
fn validate_tags_capture_names(query : @query.Query) -> Unit raise TagsError {
  for capture_id in 0..<query.capture_count() {
    match query.capture_name_for_id(capture_id) {
      Some(name) =>
        if !tags_capture_name_is_valid(name) {
          raise TagsError::InvalidCaptureName(name)
        }
      None => ()
    }
  }
}

///|
fn tags_capture_name_is_valid(name : String) -> Bool {
  name == "name" ||
  name == "doc" ||
  name == "ignore" ||
  name == "local.scope" ||
  name == "local.definition" ||
  name == "local.reference" ||
  tag_capture_name_has_nonempty_suffix(name, "definition.") ||
  tag_capture_name_has_nonempty_suffix(name, "reference.")
}

///|
fn tag_capture_name_has_nonempty_suffix(name : String, prefix : String) -> Bool {
  name.has_prefix(prefix) && name.length() > prefix.length()
}

///|
fn tags_non_local_patterns(
  pattern_count : Int,
  assertions : Array[@query.QueryPropertyAssertion],
) -> Array[Bool] {
  let result : Array[Bool] = []
  for _ in 0..<pattern_count {
    result.push(false)
  }
  for assertion in assertions {
    if !assertion.is_positive && assertion.key == "local" {
      match result.get(assertion.pattern_index) {
        Some(_) => result[assertion.pattern_index] = true
        None => ()
      }
    }
  }
  result
}

///|
fn tags_local_scope_inherits_patterns(
  pattern_count : Int,
  settings : Array[@query.QueryPropertySetting],
) -> Array[Bool] {
  let result : Array[Bool] = []
  for _ in 0..<pattern_count {
    result.push(true)
  }
  for setting in settings {
    if setting.key == "local.scope-inherits" {
      match result.get(setting.pattern_index) {
        Some(_) =>
          result[setting.pattern_index] = match setting.value {
            Some(value) => value == "true"
            None => true
          }
        None => ()
      }
    }
  }
  result
}

///|
fn collect_tags_local_scopes(
  config : TagsConfiguration,
  source_length : UInt,
  matches : Array[@query.QueryMatch],
) -> Array[TagsLocalScope] {
  let scopes : Array[TagsLocalScope] = [
    { start_byte: 0U, end_byte: source_length, inherits: true },
  ]
  for matched in matches {
    if matched.pattern_index >= config.tags_pattern_start {
      continue
    }
    for capture in matched.captures {
      if Some(capture.index) == config.local_scope_capture_index {
        let start_byte = capture.node.start_byte()
        let end_byte = capture.node.end_byte()
        if start_byte < end_byte {
          scopes.push({
            start_byte,
            end_byte,
            inherits: tags_local_scope_inherits(config, matched.pattern_index),
          })
        }
      }
    }
  }
  scopes
}

///|
fn collect_tags_local_definitions(
  config : TagsConfiguration,
  source : Bytes,
  matches : Array[@query.QueryMatch],
  scopes : Array[TagsLocalScope],
) -> Array[TagsLocalDefinition] {
  let definitions : Array[TagsLocalDefinition] = []
  for matched in matches {
    if matched.pattern_index >= config.tags_pattern_start {
      continue
    }
    for capture in matched.captures {
      if Some(capture.index) == config.local_definition_capture_index {
        let start_byte = capture.node.start_byte()
        let end_byte = capture.node.end_byte()
        if start_byte < end_byte {
          definitions.push({
            start_byte,
            name: tags_source_bytes(source, start_byte, end_byte),
            scope_index: tags_scope_for_range(scopes, start_byte, end_byte),
          })
        }
      }
    }
  }
  definitions
}

///|
fn tags_local_scope_inherits(
  config : TagsConfiguration,
  pattern_index : Int,
) -> Bool {
  match config.local_scope_inherits_patterns.get(pattern_index) {
    Some(inherits) => inherits
    None => true
  }
}

///|
fn tag_from_match(
  config : TagsConfiguration,
  source : Bytes,
  matched : @query.QueryMatch,
  scopes : Array[TagsLocalScope],
  definitions : Array[TagsLocalDefinition],
) -> Tag? {
  let mut name_capture : @query.QueryCapture? = None
  let mut kind_capture : @query.QueryCapture? = None
  let mut kind = Definition
  let mut syntax_type = ""
  let doc_captures : Array[@query.QueryCapture] = []
  for capture in matched.captures {
    if capture.name == "name" {
      name_capture = Some(capture)
    } else if capture.name.has_prefix("definition.") {
      kind_capture = Some(capture)
      kind = Definition
      syntax_type = capture.name[11:].to_owned()
    } else if capture.name.has_prefix("reference.") {
      kind_capture = Some(capture)
      kind = Reference
      syntax_type = capture.name[10:].to_owned()
    } else if capture.name == "doc" {
      doc_captures.push(capture)
    }
  }
  guard name_capture is Some(name_capture) else { return None }
  guard kind_capture is Some(kind_capture) else { return None }
  if tags_pattern_is_non_local(config, matched.pattern_index) &&
    tags_name_is_local(source, scopes, definitions, name_capture) {
    return None
  }
  let name = tag_node_text(source, name_capture.node)
  let range = tag_node_range(kind_capture.node)
  let name_range = tag_node_range(name_capture.node)
  let line_range = tag_line_range(source, name_range)
  let docs = tag_docs_for_match(
    source,
    matched,
    config.general_predicates,
    doc_captures,
  )
  Some(Tag::{
    name,
    syntax_type,
    kind,
    range,
    name_range,
    line_range,
    span: range,
    utf16_column_range: tag_utf16_column_range(source, name_range),
    docs,
  })
}

///|
fn tag_docs_for_match(
  source : Bytes,
  matched : @query.QueryMatch,
  general_predicates : Array[@query.QueryGeneralPredicate],
  doc_captures : Array[@query.QueryCapture],
) -> String {
  let selected_docs = tag_select_adjacent_docs(
    matched, general_predicates, doc_captures,
  )
  let docs : Array[String] = []
  for doc in selected_docs {
    docs.push(
      tag_strip_doc_text(
        tag_node_text(source, doc.node),
        matched.pattern_index,
        doc.index,
        general_predicates,
      ),
    )
  }
  docs.join("\n")
}

///|
fn tag_select_adjacent_docs(
  matched : @query.QueryMatch,
  general_predicates : Array[@query.QueryGeneralPredicate],
  doc_captures : Array[@query.QueryCapture],
) -> Array[@query.QueryCapture] {
  let mut result = doc_captures
  for predicate in general_predicates {
    if predicate.pattern_index == matched.pattern_index &&
      predicate.operator == "select-adjacent!" {
      match predicate.args {
        [ArgCapture(doc_id), ArgCapture(target_id)] =>
          if tag_doc_capture_id_is_present(result, doc_id) {
            result = tag_select_adjacent_docs_for_capture(
              matched, result, doc_id, target_id,
            )
          }
        _ => ()
      }
    }
  }
  result
}

///|
fn tag_doc_capture_id_is_present(
  doc_captures : Array[@query.QueryCapture],
  capture_id : Int,
) -> Bool {
  for doc in doc_captures {
    if doc.index == capture_id {
      return true
    }
  }
  false
}

///|
fn tag_select_adjacent_docs_for_capture(
  matched : @query.QueryMatch,
  doc_captures : Array[@query.QueryCapture],
  doc_capture_id : Int,
  target_capture_id : Int,
) -> Array[@query.QueryCapture] {
  guard tag_first_capture_for_id(matched, target_capture_id) is Some(target) else {
    return doc_captures
  }
  let candidates : Array[@query.QueryCapture] = []
  for doc in doc_captures {
    if doc.index == doc_capture_id {
      candidates.push(doc)
    }
  }
  let selected : Array[@query.QueryCapture] = []
  let mut expected_row = target.node.start_point().row
  for i = candidates.length() - 1; i >= 0; i = i - 1 {
    let doc = candidates[i]
    if doc.node.end_point().row + 1U == expected_row {
      selected.push(doc)
      expected_row = doc.node.start_point().row
    } else {
      break
    }
  }
  let ordered : Array[@query.QueryCapture] = []
  let mut i = selected.length()
  while i > 0 {
    i -= 1
    ordered.push(selected[i])
  }
  ordered
}

///|
fn tag_first_capture_for_id(
  matched : @query.QueryMatch,
  capture_id : Int,
) -> @query.QueryCapture? {
  for capture in matched.captures {
    if capture.index == capture_id {
      return Some(capture)
    }
  }
  None
}

///|
fn tag_strip_doc_text(
  text : String,
  pattern_index : Int,
  doc_capture_id : Int,
  general_predicates : Array[@query.QueryGeneralPredicate],
) -> String {
  let mut result = text
  for predicate in general_predicates {
    if predicate.pattern_index == pattern_index &&
      predicate.operator == "strip!" {
      match predicate.args {
        [ArgCapture(capture_id), ArgString(regex)] =>
          if capture_id == doc_capture_id {
            let compiled = Regex(regex[:]) catch { _ => continue }
            result = compiled.replace_by(result[:], _ => "").to_owned()
          }
        _ => ()
      }
    }
  }
  result
}

///|
fn tag_match_has_ignore(matched : @query.QueryMatch) -> Bool {
  for capture in matched.captures {
    if capture.name == "ignore" {
      return true
    }
  }
  false
}

///|
fn tags_pattern_is_non_local(
  config : TagsConfiguration,
  pattern_index : Int,
) -> Bool {
  match config.non_local_patterns.get(pattern_index) {
    Some(value) => value
    None => false
  }
}

///|
fn tags_name_is_local(
  source : Bytes,
  scopes : Array[TagsLocalScope],
  definitions : Array[TagsLocalDefinition],
  capture : @query.QueryCapture,
) -> Bool {
  let start_byte = capture.node.start_byte()
  let end_byte = capture.node.end_byte()
  let name = tags_source_bytes(source, start_byte, end_byte)
  let scope_chain = tags_scope_chain_for_range(scopes, start_byte, end_byte)
  for scope_index in scope_chain {
    for definition in definitions {
      if definition.scope_index == scope_index &&
        definition.name == name &&
        definition.start_byte <= start_byte {
        return true
      }
    }
    if !scopes[scope_index].inherits {
      return false
    }
  }
  false
}

///|
fn tags_scope_for_range(
  scopes : Array[TagsLocalScope],
  start_byte : UInt,
  end_byte : UInt,
) -> Int {
  let mut result = 0
  for index, scope in scopes {
    if tags_scope_contains(scope, start_byte, end_byte) &&
      tags_scope_index_compare(scopes, index, result) < 0 {
      result = index
    }
  }
  result
}

///|
fn tags_scope_chain_for_range(
  scopes : Array[TagsLocalScope],
  start_byte : UInt,
  end_byte : UInt,
) -> Array[Int] {
  let result : Array[Int] = []
  for index, scope in scopes {
    if tags_scope_contains(scope, start_byte, end_byte) {
      result.push(index)
    }
  }
  result.sort_by((left, right) => tags_scope_index_compare(scopes, left, right))
  result
}

///|
fn tags_scope_contains(
  scope : TagsLocalScope,
  start_byte : UInt,
  end_byte : UInt,
) -> Bool {
  scope.start_byte <= start_byte && end_byte <= scope.end_byte
}

///|
fn tags_scope_index_compare(
  scopes : Array[TagsLocalScope],
  left_index : Int,
  right_index : Int,
) -> Int {
  let left = scopes[left_index]
  let right = scopes[right_index]
  let left_size = left.end_byte - left.start_byte
  let right_size = right.end_byte - right.start_byte
  if left_size < right_size {
    -1
  } else if left_size > right_size {
    1
  } else if left.start_byte > right.start_byte {
    -1
  } else if left.start_byte < right.start_byte {
    1
  } else {
    left_index - right_index
  }
}

///|
fn tag_node_text(source : Bytes, node : @tree_sitter_mbt.Node) -> String {
  let start = node.start_byte().reinterpret_as_int()
  let end = node.end_byte().reinterpret_as_int()
  if start < 0 || end < start || end > source.length() {
    return ""
  }
  @utf8.decode_lossy(source[start:end])
}

///|
fn tag_node_range(node : @tree_sitter_mbt.Node) -> @api.Range {
  @api.Range::new(
    start_byte=node.start_byte(),
    end_byte=node.end_byte(),
    start_point=node.start_point(),
    end_point=node.end_point(),
  )
}

///|
fn tag_line_range(source : Bytes, name_range : @api.Range) -> @api.Range {
  let name_start = name_range.start_byte.reinterpret_as_int()
  let source_len = source.length()
  let mut line_start = name_start
  while line_start > 0 && source[line_start - 1] != b'\n' {
    line_start -= 1
  }
  let raw_line_start = line_start
  let mut line_end = name_start
  while line_end < source_len && source[line_end] != b'\n' {
    line_end += 1
  }
  line_end = tag_valid_utf8_prefix_end(source, line_start, line_end)
  while line_start < line_end && tag_byte_is_ascii_space(source[line_start]) {
    line_start += 1
  }
  while line_end > line_start && tag_byte_is_ascii_space(source[line_end - 1]) {
    line_end -= 1
  }
  if line_end - line_start > 180 {
    line_end = line_start + 180
  }
  @api.Range::new(
    start_byte=line_start.reinterpret_as_uint(),
    end_byte=line_end.reinterpret_as_uint(),
    start_point=@api.Point::new(
      row=name_range.start_point.row,
      column=(line_start - raw_line_start).reinterpret_as_uint(),
    ),
    end_point=@api.Point::new(
      row=name_range.start_point.row,
      column=(line_end - raw_line_start).reinterpret_as_uint(),
    ),
  )
}

///|
fn tag_line_start(source : Bytes, offset : Int) -> Int {
  let mut line_start = offset
  while line_start > 0 && source[line_start - 1] != b'\n' {
    line_start -= 1
  }
  line_start
}

///|
fn tag_byte_is_ascii_space(byte : Byte) -> Bool {
  byte == b' ' || byte == b'\t' || byte == b'\r'
}

///|
fn tag_valid_utf8_prefix_end(source : Bytes, start : Int, end : Int) -> Int {
  let mut offset = start
  while offset < end {
    match tag_utf8_sequence_width(source, offset, end) {
      Some(width) => offset += width
      None => return offset
    }
  }
  end
}

///|
fn tag_utf8_sequence_width(source : Bytes, offset : Int, end : Int) -> Int? {
  let first = source[offset].to_int()
  if first < 0x80 {
    return Some(1)
  }
  if first >= 0xC2 && first <= 0xDF {
    match tag_utf8_continuation_value(source, offset + 1, end) {
      Some(_) => return Some(2)
      None => return None
    }
  }
  if first >= 0xE0 && first <= 0xEF {
    match
      (
        tag_utf8_continuation_value(source, offset + 1, end),
        tag_utf8_continuation_value(source, offset + 2, end),
      ) {
      (Some(second), Some(third)) => {
        let codepoint = (first - 0xE0) * 0x1000 + second * 0x40 + third
        if codepoint >= 0x800 && (codepoint < 0xD800 || codepoint > 0xDFFF) {
          return Some(3)
        }
      }
      _ => ()
    }
    return None
  }
  if first >= 0xF0 && first <= 0xF4 {
    match
      (
        tag_utf8_continuation_value(source, offset + 1, end),
        tag_utf8_continuation_value(source, offset + 2, end),
        tag_utf8_continuation_value(source, offset + 3, end),
      ) {
      (Some(second), Some(third), Some(fourth)) => {
        let codepoint = (first - 0xF0) * 0x40000 +
          second * 0x1000 +
          third * 0x40 +
          fourth
        if codepoint >= 0x10000 && codepoint <= 0x10FFFF {
          return Some(4)
        }
      }
      _ => ()
    }
  }
  None
}

///|
fn tag_utf8_continuation_value(source : Bytes, offset : Int, end : Int) -> Int? {
  if offset < 0 || offset >= source.length() || offset >= end {
    return None
  }
  let value = source[offset].to_int()
  if value >= 0x80 && value <= 0xBF {
    Some(value - 0x80)
  } else {
    None
  }
}

///|
fn tag_utf16_column_range(
  source : Bytes,
  name_range : @api.Range,
) -> Utf16ColumnRange {
  let line_start = tag_line_start(
    source,
    name_range.start_byte.reinterpret_as_int(),
  )
  {
    start: tag_utf16_column_for_byte(
      source,
      line_start,
      name_range.start_byte.reinterpret_as_int(),
    ),
    end: tag_utf16_column_for_byte(
      source,
      line_start,
      name_range.end_byte.reinterpret_as_int(),
    ),
  }
}

///|
fn tag_utf16_column_for_byte(
  source : Bytes,
  line_start : Int,
  end : Int,
) -> UInt {
  let text = if line_start <= end && end <= source.length() {
    @utf8.decode_lossy(source[line_start:end])
  } else {
    ""
  }
  let mut column = 0
  for char in text {
    column += char.utf16_len()
  }
  column.reinterpret_as_uint()
}

///|
fn tags_source_bytes(
  source : Bytes,
  start_byte : UInt,
  end_byte : UInt,
) -> Bytes {
  source[start_byte.reinterpret_as_int():end_byte.reinterpret_as_int()].to_owned()
}

///|
fn drain_tag_queue(entries : Array[TagQueueEntry]) -> Array[Tag] {
  entries.sort_by(tag_queue_entry_compare)
  let result : Array[Tag] = []
  let mut index = 0
  while index < entries.length() {
    let first = entries[index]
    let mut has_ignore = false
    let mut selected : Tag? = None
    while index < entries.length() &&
          tag_queue_entries_same_name_range(first, entries[index]) {
      let entry = entries[index]
      if entry.ignored {
        has_ignore = true
      } else if selected is None {
        selected = Some(entry.tag)
      }
      index += 1
    }
    if !has_ignore {
      match selected {
        Some(tag) => result.push(tag)
        None => ()
      }
    }
  }
  result
}

///|
fn tag_queue_entries_same_name_range(
  left : TagQueueEntry,
  right : TagQueueEntry,
) -> Bool {
  left.tag.name_range.start_byte == right.tag.name_range.start_byte &&
  left.tag.name_range.end_byte == right.tag.name_range.end_byte
}

///|
fn tag_queue_entry_compare(left : TagQueueEntry, right : TagQueueEntry) -> Int {
  if left.tag.name_range.end_byte < right.tag.name_range.end_byte {
    -1
  } else if left.tag.name_range.end_byte > right.tag.name_range.end_byte {
    1
  } else if left.tag.name_range.start_byte < right.tag.name_range.start_byte {
    -1
  } else if left.tag.name_range.start_byte > right.tag.name_range.start_byte {
    1
  } else if left.pattern_index < right.pattern_index {
    -1
  } else if left.pattern_index > right.pattern_index {
    1
  } else {
    0
  }
}
