///|
pub(all) suberror HighlightError {
  Cancelled(HighlightProgressState)
  IncludedRangesFailed(@tree_sitter_mbt.IncludedRangesError)
  LanguageFailed(@tree_sitter_mbt.LanguageError)
  ParseFailed(@tree_sitter_mbt.ParseError)
  QueryFailed(@query.QueryError)
  RenderFailed(String)
  PredicateFailed(@query.QueryPredicateError)
}

///|
pub(all) enum HighlightEvent {
  Source(start_byte~ : UInt, end_byte~ : UInt)
  HighlightStart(String)
  HighlightEnd(String)
} derive(Eq, Debug)

///|
pub(all) enum HighlightProgressPhase {
  Parse
  Query
  Render
} derive(Eq, Debug)

///|
pub(all) struct HighlightProgressState {
  phase : HighlightProgressPhase
  current_byte_offset : UInt
} derive(Eq, Debug)

///|
pub(all) struct HighlightOptions {
  cancellation_state : HighlightProgressState?
  progress_callback : ((HighlightProgressState) -> Bool)?
}

///|
struct HighlightConfiguration {
  language : @tree_sitter_mbt.Language
  language_name : String
  query : @query.Query
  combined_injections_query : @query.Query?
  mut capture_highlight_names : Array[String?]
  non_local_variable_patterns : Array[Bool]
  local_definition_capture_index : Int?
  local_definition_value_capture_index : Int?
  local_reference_capture_index : Int?
  local_scope_capture_index : Int?
  local_scope_inherits_patterns : Array[Bool]
  injection_pattern_start : Int
  local_pattern_start : Int
}

///|
struct Highlighter {
  marker : Bool
}

///|
priv struct HighlightRange {
  start_byte : UInt
  end_byte : UInt
  name : String
  pattern_index : Int
  capture_index : Int
  depth : Int
}

///|
priv struct HighlightBoundary {
  byte : UInt
  is_end : Bool
  start_byte : UInt
  end_byte : UInt
  name : String
  depth : Int
}

///|
priv struct HighlightInjectionLayer {
  config : HighlightConfiguration
  ranges : Array[@api.Range]
  depth : Int
}

///|
priv struct HighlightCombinedInjectionGroup {
  pattern_index : Int
  language_name : String
  config : HighlightConfiguration
  ranges : Array[@api.Range]
}

///|
priv struct HighlightLocalRange {
  start_byte : UInt
  end_byte : UInt
}

///|
priv struct HighlightLocalDefinition {
  start_byte : UInt
  value_end_byte : UInt
  name : Bytes
  highlight_name : String?
  scope_index : Int
}

///|
priv struct HighlightLocalScope {
  start_byte : UInt
  end_byte : UInt
  inherits : Bool
}

///|
priv struct HighlightLocalContext {
  ranges : Array[HighlightLocalRange]
  inherited_ranges : Array[HighlightRange]
}

///|
pub fn HighlightConfiguration::new(
  language : @tree_sitter_mbt.Language,
  language_name : String,
  highlights_query : String,
  injections_query? : String = "",
  locals_query? : String = "",
  highlight_names? : Array[String] = [],
) -> HighlightConfiguration raise HighlightError {
  let highlight_query = compile_highlight_query(language, highlights_query)
  let injection_query = compile_highlight_query(language, injections_query)
  let injection_pattern_start = highlight_query.pattern_count()
  let local_pattern_start = injection_pattern_start +
    injection_query.pattern_count()
  let query = compile_highlight_query(
    language,
    combine_highlight_query_sources([
      highlights_query, injections_query, locals_query,
    ]),
  )
  disable_combined_injection_patterns(query)
  let combined_injections_query = if injections_query.is_empty() {
    None
  } else {
    let combined = compile_highlight_query(language, injections_query)
    disable_non_combined_injection_patterns(combined)
    Some(combined)
  }
  let capture_highlight_names = highlight_capture_name_map(
    query, highlight_names,
  )
  let classes = classify_highlight_query_predicates(query)
  let non_local_variable_patterns = highlight_non_local_variable_patterns(
    query.pattern_count(),
    classes.property_assertions,
  )
  let local_scope_inherits_patterns = highlight_local_scope_inherits_patterns(
    query.pattern_count(),
    classes.property_settings,
  )
  {
    language,
    language_name,
    query,
    combined_injections_query,
    capture_highlight_names,
    non_local_variable_patterns,
    local_definition_capture_index: highlight_capture_id(
      query, "local.definition",
    ),
    local_definition_value_capture_index: highlight_capture_id(
      query, "local.definition-value",
    ),
    local_reference_capture_index: highlight_capture_id(
      query, "local.reference",
    ),
    local_scope_capture_index: highlight_capture_id(query, "local.scope"),
    local_scope_inherits_patterns,
    injection_pattern_start,
    local_pattern_start,
  }
}

///|
pub fn HighlightConfiguration::language_name(
  self : HighlightConfiguration,
) -> String {
  self.language_name
}

///|
pub fn HighlightConfiguration::highlight_pattern_start(
  _self : HighlightConfiguration,
) -> Int {
  0
}

///|
pub fn HighlightConfiguration::injection_pattern_start(
  self : HighlightConfiguration,
) -> Int {
  self.injection_pattern_start
}

///|
pub fn HighlightConfiguration::local_pattern_start(
  self : HighlightConfiguration,
) -> Int {
  self.local_pattern_start
}

///|
pub fn HighlightConfiguration::pattern_count(
  self : HighlightConfiguration,
) -> Int {
  self.query.pattern_count()
}

///|
pub fn HighlightConfiguration::has_combined_injections_query(
  self : HighlightConfiguration,
) -> Bool {
  self.combined_injections_query is Some(_)
}

///|
pub fn HighlightConfiguration::names(
  self : HighlightConfiguration,
) -> Array[String] {
  highlight_query_capture_names(self.query)
}

///|
pub fn HighlightConfiguration::configure(
  self : HighlightConfiguration,
  recognized_names : Array[String],
) -> Unit {
  self.capture_highlight_names = highlight_capture_name_map(
    self.query,
    recognized_names,
  )
}

///|
pub fn HighlightConfiguration::nonconformant_capture_names(
  self : HighlightConfiguration,
  capture_names? : Array[String] = [],
) -> Array[String] {
  let allowed_names = if capture_names.is_empty() {
    standard_highlight_capture_names()
  } else {
    capture_names
  }
  let result : Array[String] = []
  for name in self.names() {
    if !name.has_prefix("_") && !allowed_names.contains(name) {
      result.push(name)
    }
  }
  result
}

///|
pub fn Highlighter::new() -> Highlighter {
  { marker: true }
}

///|
pub fn Highlighter::highlight(
  self : Highlighter,
  config : HighlightConfiguration,
  source : Bytes,
  options? : HighlightOptions = HighlightOptions::default(),
) -> Array[HighlightEvent] raise HighlightError {
  self.highlight_encoded(config, source, encoding=Utf8, options~)
}

///|
pub fn Highlighter::highlight_encoded(
  self : Highlighter,
  config : HighlightConfiguration,
  source : Bytes,
  encoding? : @api.InputEncoding = Utf8,
  options? : HighlightOptions = HighlightOptions::default(),
) -> Array[HighlightEvent] raise HighlightError {
  self.highlight_with_injection_callback(config, source, encoding, options, _ => {
    None
  })
}

///|
pub fn Highlighter::highlight_with_injections(
  self : Highlighter,
  config : HighlightConfiguration,
  source : Bytes,
  injection_callback : (String) -> HighlightConfiguration?,
  encoding? : @api.InputEncoding = Utf8,
  options? : HighlightOptions = HighlightOptions::default(),
) -> Array[HighlightEvent] raise HighlightError {
  self.highlight_with_injection_callback(
    config, source, encoding, options, injection_callback,
  )
}

///|
fn Highlighter::highlight_with_injection_callback(
  self : Highlighter,
  config : HighlightConfiguration,
  source : Bytes,
  encoding : @api.InputEncoding,
  options : HighlightOptions,
  injection_callback : (String) -> HighlightConfiguration?,
) -> Array[HighlightEvent] raise HighlightError {
  ignore(self.marker)
  let tree = parse_highlight_tree(config, source, encoding, [], options)
  let ranges : Array[HighlightRange] = []
  collect_highlight_layer(
    config,
    source,
    encoding,
    tree.root_node(),
    [],
    options,
    injection_callback,
    None,
    0,
    ranges,
  )
  ranges.sort_by(highlight_range_compare)
  render_highlight_events(
    source.length().reinterpret_as_uint(),
    ranges,
    options,
  )
}

///|
pub fn HighlightProgressState::new(
  phase~ : HighlightProgressPhase,
  current_byte_offset~ : UInt,
) -> HighlightProgressState {
  { phase, current_byte_offset }
}

///|
pub fn HighlightOptions::default() -> HighlightOptions {
  { cancellation_state: None, progress_callback: None }
}

///|
pub fn HighlightOptions::cancelled(
  state : HighlightProgressState,
) -> HighlightOptions {
  { cancellation_state: Some(state), progress_callback: None }
}

///|
pub fn HighlightOptions::progress(
  callback : (HighlightProgressState) -> Bool,
) -> HighlightOptions {
  { cancellation_state: None, progress_callback: Some(callback) }
}

///|
pub fn HighlightOptions::with_progress(
  self : HighlightOptions,
  callback : (HighlightProgressState) -> Bool,
) -> HighlightOptions {
  { ..self, progress_callback: Some(callback) }
}

///|
pub fn render_html(
  events : Array[HighlightEvent],
  source : Bytes,
  encoding? : @api.InputEncoding = Utf8,
) -> String raise HighlightError {
  let out = StringBuilder::new()
  for event in events {
    match event {
      Source(start_byte~, end_byte~) => {
        let text = highlight_source_text(source, start_byte, end_byte, encoding)
        match text {
          Some(text) => highlight_write_html_escaped_text(out, text)
          None =>
            raise HighlightError::RenderFailed(
              "source range is not valid for the configured encoding",
            )
        }
      }
      HighlightStart(name) => {
        out.write_string("<span class=\"")
        highlight_write_html_class(out, name)
        out.write_string("\">")
      }
      HighlightEnd(_) => out.write_string("</span>")
    }
  }
  out.to_string()
}

///|
fn parse_highlight_tree(
  config : HighlightConfiguration,
  source : Bytes,
  encoding : @api.InputEncoding,
  included_ranges : Array[@api.Range],
  options : HighlightOptions,
) -> @tree_sitter_mbt.Tree raise HighlightError {
  maybe_cancel_highlight(
    options,
    HighlightProgressState::new(phase=Parse, current_byte_offset=0U),
  )
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(config.language) catch {
    err => raise HighlightError::LanguageFailed(err)
  }
  if !included_ranges.is_empty() {
    parser.set_included_ranges(included_ranges) catch {
      err => raise HighlightError::IncludedRangesFailed(err)
    }
  }
  parser.parse(
    @tree_sitter_mbt.Input::from_bytes(source, encoding~),
    options=highlight_parse_options(options),
  ) catch {
    @tree_sitter_mbt.ParseError::Cancelled(state) =>
      raise HighlightError::Cancelled(
        HighlightProgressState::new(
          phase=Parse,
          current_byte_offset=state.current_byte_offset,
        ),
      )
    err => raise HighlightError::ParseFailed(err)
  }
}

///|
fn collect_highlight_layer(
  config : HighlightConfiguration,
  source : Bytes,
  encoding : @api.InputEncoding,
  root : @tree_sitter_mbt.Node,
  included_ranges : Array[@api.Range],
  options : HighlightOptions,
  injection_callback : (String) -> HighlightConfiguration?,
  parent_config : HighlightConfiguration?,
  depth : Int,
  ranges : Array[HighlightRange],
) -> Unit raise HighlightError {
  let layer_ranges = collect_highlight_ranges(
    config, source, encoding, root, options, depth,
  )
  for range in layer_ranges {
    add_resolved_highlight_range(ranges, range)
  }
  if depth >= 8 {
    return
  }
  let injection_layers = collect_highlight_injection_layers(
    config, source, encoding, root, included_ranges, options, injection_callback,
    parent_config, depth,
  )
  for layer in injection_layers {
    let tree = parse_highlight_tree(
      layer.config,
      source,
      encoding,
      layer.ranges,
      options,
    )
    collect_highlight_layer(
      layer.config,
      source,
      encoding,
      tree.root_node(),
      layer.ranges,
      options,
      injection_callback,
      Some(config),
      layer.depth,
      ranges,
    )
  }
}

///|
fn highlight_parse_options(
  options : HighlightOptions,
) -> @tree_sitter_mbt.ParseOptions {
  @tree_sitter_mbt.ParseOptions::progress(state => {
    highlight_cancellation_state(
      options,
      HighlightProgressState::new(
        phase=Parse,
        current_byte_offset=state.current_byte_offset,
      ),
    )
    is Some(_)
  })
}

///|
fn highlight_cancellation_state(
  options : HighlightOptions,
  state : HighlightProgressState,
) -> HighlightProgressState? {
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
fn maybe_cancel_highlight(
  options : HighlightOptions,
  state : HighlightProgressState,
) -> Unit raise HighlightError {
  match highlight_cancellation_state(options, state) {
    Some(cancelled_state) => raise HighlightError::Cancelled(cancelled_state)
    None => ()
  }
}

///|
fn compile_highlight_query(
  language : @tree_sitter_mbt.Language,
  source : String,
) -> @query.Query raise HighlightError {
  @query.Query::new(language, source) catch {
    err => raise HighlightError::QueryFailed(err)
  }
}

///|
fn combine_highlight_query_sources(sources : Array[String]) -> String {
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
fn disable_combined_injection_patterns(
  query : @query.Query,
) -> Unit raise HighlightError {
  let classes = classify_highlight_query_predicates(query)
  for setting in classes.property_settings {
    if setting.key == "injection.combined" {
      ignore(query.disable_pattern(setting.pattern_index))
    }
  }
}

///|
fn disable_non_combined_injection_patterns(
  query : @query.Query,
) -> Unit raise HighlightError {
  let classes = classify_highlight_query_predicates(query)
  for pattern_index in 0..<query.pattern_count() {
    if !highlight_pattern_has_property(
        pattern_index,
        "injection.combined",
        classes.property_settings,
      ) {
      ignore(query.disable_pattern(pattern_index))
    }
  }
}

///|
fn classify_highlight_query_predicates(
  query : @query.Query,
) -> @query.QueryPredicateClasses raise HighlightError {
  query.classify_predicates() catch {
    err => raise HighlightError::PredicateFailed(err)
  }
}

///|
fn highlight_pattern_has_property(
  pattern_index : Int,
  key : String,
  settings : Array[@query.QueryPropertySetting],
) -> Bool {
  for setting in settings {
    if setting.pattern_index == pattern_index && setting.key == key {
      return true
    }
  }
  false
}

///|
fn collect_highlight_ranges(
  config : HighlightConfiguration,
  source : Bytes,
  encoding : @api.InputEncoding,
  root : @tree_sitter_mbt.Node,
  options : HighlightOptions,
  depth : Int,
) -> Array[HighlightRange] raise HighlightError {
  let matches = collect_highlight_query_matches(
    config.query,
    source,
    encoding,
    root,
    options,
  )
  let ranges : Array[HighlightRange] = []
  let local_context = collect_highlight_local_context(
    config, source, matches, depth,
  )
  for matched in matches {
    for capture in matched.captures {
      add_highlight_capture_range(
        config,
        ranges,
        local_context.ranges,
        capture,
        depth,
      )
    }
  }
  for inherited_range in local_context.inherited_ranges {
    add_resolved_highlight_range(ranges, inherited_range)
  }
  ranges.sort_by(highlight_range_compare)
  ranges
}

///|
fn collect_highlight_query_matches(
  query : @query.Query,
  source : Bytes,
  encoding : @api.InputEncoding,
  root : @tree_sitter_mbt.Node,
  options : HighlightOptions,
) -> Array[@query.QueryMatch] raise HighlightError {
  let cursor = @query.QueryCursor::new()
  let cancelled_states : Array[HighlightProgressState] = []
  cursor.set_progress_callback(
    Some(state => {
      let highlight_state = HighlightProgressState::new(
        phase=Query,
        current_byte_offset=state.current_byte_offset,
      )
      match highlight_cancellation_state(options, highlight_state) {
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
    Some(state) => raise HighlightError::Cancelled(state)
    None => ()
  }
  let matches : Array[@query.QueryMatch] = []
  while true {
    let matched = next_highlight_match_with_text_predicates(
      query, cursor, source, encoding,
    ) catch {
      err => raise HighlightError::PredicateFailed(err)
    }
    match matched {
      Some(matched) => matches.push(matched)
      None => break
    }
  }
  matches
}

///|
fn collect_highlight_injection_layers(
  config : HighlightConfiguration,
  source : Bytes,
  encoding : @api.InputEncoding,
  root : @tree_sitter_mbt.Node,
  included_ranges : Array[@api.Range],
  options : HighlightOptions,
  injection_callback : (String) -> HighlightConfiguration?,
  parent_config : HighlightConfiguration?,
  depth : Int,
) -> Array[HighlightInjectionLayer] raise HighlightError {
  let classes = classify_highlight_query_predicates(config.query)
  let matches = collect_highlight_query_matches(
    config.query,
    source,
    encoding,
    root,
    options,
  )
  let layers : Array[HighlightInjectionLayer] = []
  for matched in matches {
    if highlight_match_has_property(
        matched.pattern_index,
        "injection.combined",
        classes.property_settings,
      ) {
      continue
    }
    match
      highlight_injection_layer_from_match(
        config,
        source,
        encoding,
        matched,
        classes.property_settings,
        included_ranges,
        injection_callback,
        parent_config,
        depth,
      ) {
      Some(layer) => layers.push(layer)
      None => ()
    }
  }
  match config.combined_injections_query {
    Some(query) => {
      let combined_classes = classify_highlight_query_predicates(query)
      let combined_matches = collect_highlight_query_matches(
        query, source, encoding, root, options,
      )
      let groups : Array[HighlightCombinedInjectionGroup] = []
      for matched in combined_matches {
        match
          highlight_injection_layer_from_match(
            config,
            source,
            encoding,
            matched,
            combined_classes.property_settings,
            included_ranges,
            injection_callback,
            parent_config,
            depth,
          ) {
          Some(layer) =>
            add_highlight_combined_injection_group(
              groups,
              matched.pattern_index,
              layer.config,
              layer.ranges,
            )
          None => ()
        }
      }
      for group in groups {
        layers.push({
          config: group.config,
          ranges: group.ranges,
          depth: depth + 1,
        })
      }
    }
    None => ()
  }
  layers
}

///|
fn highlight_injection_layer_from_match(
  config : HighlightConfiguration,
  source : Bytes,
  encoding : @api.InputEncoding,
  matched : @query.QueryMatch,
  settings : Array[@query.QueryPropertySetting],
  included_ranges : Array[@api.Range],
  injection_callback : (String) -> HighlightConfiguration?,
  parent_config : HighlightConfiguration?,
  depth : Int,
) -> HighlightInjectionLayer? {
  let include_children = highlight_injection_include_children(
    matched.pattern_index,
    settings,
  )
  let ranges : Array[@api.Range] = []
  for capture in matched.captures {
    if capture.name == "injection.content" {
      let node_ranges = highlight_injection_ranges_for_node(
        capture.node,
        include_children~,
      )
      for range in node_ranges {
        for
          intersected in highlight_intersect_layer_ranges(
            range, included_ranges,
          ) {
          if !intersected.is_empty() {
            ranges.push(intersected)
          }
        }
      }
    }
  }
  if ranges.is_empty() {
    return None
  }
  ranges.sort_by(highlight_range_byte_compare)
  let language_name = highlight_injection_language_name(
    source, encoding, matched, settings,
  )
  let injection_config = highlight_injection_config(
    config,
    parent_config,
    matched.pattern_index,
    settings,
    language_name,
    injection_callback,
  )
  match injection_config {
    Some(injection_config) =>
      Some({ config: injection_config, ranges, depth: depth + 1 })
    None => None
  }
}

///|
fn add_highlight_combined_injection_group(
  groups : Array[HighlightCombinedInjectionGroup],
  pattern_index : Int,
  config : HighlightConfiguration,
  ranges : Array[@api.Range],
) -> Unit {
  let language_name = config.language_name()
  for index, group in groups {
    if group.pattern_index == pattern_index &&
      group.language_name == language_name {
      for range in ranges {
        group.ranges.push(range)
      }
      groups[index] = group
      return
    }
  }
  groups.push({ pattern_index, language_name, config, ranges })
}

///|
fn highlight_injection_include_children(
  pattern_index : Int,
  settings : Array[@query.QueryPropertySetting],
) -> Bool {
  match
    highlight_property_value_for_pattern(
      pattern_index, "injection.include-children", settings,
    ) {
    Some(value) => value == "true"
    None => false
  }
}

///|
fn highlight_injection_language_name(
  source : Bytes,
  encoding : @api.InputEncoding,
  matched : @query.QueryMatch,
  settings : Array[@query.QueryPropertySetting],
) -> String? {
  for capture in matched.captures {
    if capture.name == "injection.language" {
      match highlight_node_text(capture.node, source, encoding) {
        Some(name) => return Some(name)
        None => ()
      }
    }
  }
  for setting in settings {
    if setting.pattern_index == matched.pattern_index &&
      setting.key == "injection.language" {
      match setting.capture_id {
        Some(capture_id) =>
          match
            highlight_capture_text_for_id(matched, capture_id, source, encoding) {
            Some(name) => return Some(name)
            None => ()
          }
        None =>
          match setting.value {
            Some(value) => return Some(value)
            None => ()
          }
      }
    }
  }
  None
}

///|
fn highlight_injection_config(
  config : HighlightConfiguration,
  parent_config : HighlightConfiguration?,
  pattern_index : Int,
  settings : Array[@query.QueryPropertySetting],
  language_name : String?,
  injection_callback : (String) -> HighlightConfiguration?,
) -> HighlightConfiguration? {
  if highlight_match_has_property(pattern_index, "injection.self", settings) {
    return Some(config)
  }
  if highlight_match_has_property(pattern_index, "injection.parent", settings) {
    return match parent_config {
      Some(parent_config) => Some(parent_config)
      None => Some(config)
    }
  }
  match language_name {
    Some(name) =>
      if name == config.language_name() {
        Some(config)
      } else {
        injection_callback(name)
      }
    None => None
  }
}

///|
fn highlight_capture_text_for_id(
  matched : @query.QueryMatch,
  capture_id : Int,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> String? {
  for capture in matched.captures {
    if capture.index == capture_id {
      return highlight_node_text(capture.node, source, encoding)
    }
  }
  None
}

///|
fn highlight_node_text(
  node : @tree_sitter_mbt.Node,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> String? {
  let start = node.start_byte().reinterpret_as_int()
  let end = node.end_byte().reinterpret_as_int()
  highlight_source_text_for_int_range(source, start, end, encoding)
}

///|
fn highlight_source_text(
  source : Bytes,
  start_byte : UInt,
  end_byte : UInt,
  encoding : @api.InputEncoding,
) -> String? {
  highlight_source_text_for_int_range(
    source,
    start_byte.reinterpret_as_int(),
    end_byte.reinterpret_as_int(),
    encoding,
  )
}

///|
fn highlight_source_text_for_int_range(
  source : Bytes,
  start : Int,
  end : Int,
  encoding : @api.InputEncoding,
) -> String? {
  if start < 0 || end < start || end > source.length() {
    return None
  }
  let view = source[start:end]
  match encoding {
    Utf16LE => highlight_decode_utf16_text(view, little_endian=true)
    Utf16BE => highlight_decode_utf16_text(view, little_endian=false)
    Utf8 | Custom => {
      let decoded = @utf8.decode(view) catch { _ => return None }
      Some(decoded)
    }
  }
}

///|
fn highlight_write_html_escaped_text(
  out : StringBuilder,
  text : String,
) -> Unit {
  for char in text {
    match char {
      '&' => out.write_string("&amp;")
      '<' => out.write_string("&lt;")
      '>' => out.write_string("&gt;")
      _ => out.write_char(char)
    }
  }
}

///|
fn highlight_write_html_class(out : StringBuilder, name : String) -> Unit {
  let mut first = true
  for part in name.split(".") {
    let sanitized = highlight_sanitize_html_class_part(part)
    if sanitized.is_empty() {
      continue
    }
    if !first {
      out.write_char(' ')
    }
    out.write_string(sanitized)
    first = false
  }
}

///|
fn highlight_sanitize_html_class_part(part : StringView) -> String {
  let out = StringBuilder::new()
  for char in part {
    if highlight_html_class_char_is_allowed(char) {
      out.write_char(char)
    }
  }
  out.to_string()
}

///|
fn highlight_html_class_char_is_allowed(char : Char) -> Bool {
  match char {
    'a'..='z' | 'A'..='Z' | '0'..='9' | '_' | '-' => true
    _ => false
  }
}

///|
fn highlight_decode_utf16_text(
  source : BytesView,
  little_endian~ : Bool,
) -> String? {
  if source.length() % 2 != 0 {
    return None
  }
  let builder = StringBuilder::new()
  for i = 0; i < source.length(); {
    let code_unit = highlight_read_utf16_code_unit(source, i, little_endian~)
    if 0xD800 <= code_unit && code_unit <= 0xDBFF {
      if i + 2 >= source.length() {
        return None
      }
      let trail = highlight_read_utf16_code_unit(source, i + 2, little_endian~)
      if trail < 0xDC00 || trail > 0xDFFF {
        return None
      }
      let codepoint = 0x10000 + (code_unit - 0xD800) * 0x400 + (trail - 0xDC00)
      match codepoint.to_char() {
        Some(ch) => builder.write_char(ch)
        None => return None
      }
      continue i + 4
    } else if 0xDC00 <= code_unit && code_unit <= 0xDFFF {
      return None
    } else {
      match code_unit.to_char() {
        Some(ch) => builder.write_char(ch)
        None => return None
      }
      continue i + 2
    }
  }
  Some(builder.to_string())
}

///|
fn highlight_injection_ranges_for_node(
  node : @tree_sitter_mbt.Node,
  include_children~ : Bool,
) -> Array[@api.Range] {
  if include_children || node.child_count() == 0 {
    return [highlight_node_range(node)]
  }
  let ranges : Array[@api.Range] = []
  let mut start_byte = node.start_byte()
  let mut start_point = node.start_point()
  for child_index in 0..<node.child_count() {
    let child = node.child(child_index)
    if child.is_null() {
      continue
    }
    if start_byte < child.start_byte() {
      ranges.push(
        @api.Range::new(
          start_byte~,
          end_byte=child.start_byte(),
          start_point~,
          end_point=child.start_point(),
        ),
      )
    }
    start_byte = child.end_byte()
    start_point = child.end_point()
  }
  if start_byte < node.end_byte() {
    ranges.push(
      @api.Range::new(
        start_byte~,
        end_byte=node.end_byte(),
        start_point~,
        end_point=node.end_point(),
      ),
    )
  }
  ranges
}

///|
fn highlight_node_range(node : @tree_sitter_mbt.Node) -> @api.Range {
  @api.Range::new(
    start_byte=node.start_byte(),
    end_byte=node.end_byte(),
    start_point=node.start_point(),
    end_point=node.end_point(),
  )
}

///|
fn highlight_intersect_layer_ranges(
  range : @api.Range,
  included_ranges : Array[@api.Range],
) -> Array[@api.Range] {
  if included_ranges.is_empty() {
    return [range]
  }
  let result : Array[@api.Range] = []
  for included in included_ranges {
    match highlight_intersect_ranges(range, included) {
      Some(intersection) => result.push(intersection)
      None => ()
    }
  }
  result
}

///|
fn highlight_intersect_ranges(
  left : @api.Range,
  right : @api.Range,
) -> @api.Range? {
  let start_byte = if left.start_byte > right.start_byte {
    left.start_byte
  } else {
    right.start_byte
  }
  let end_byte = if left.end_byte < right.end_byte {
    left.end_byte
  } else {
    right.end_byte
  }
  if start_byte >= end_byte {
    return None
  }
  let start_point = if start_byte == left.start_byte {
    left.start_point
  } else {
    right.start_point
  }
  let end_point = if end_byte == left.end_byte {
    left.end_point
  } else {
    right.end_point
  }
  Some(@api.Range::new(start_byte~, end_byte~, start_point~, end_point~))
}

///|
fn highlight_range_byte_compare(left : @api.Range, right : @api.Range) -> Int {
  if left.start_byte < right.start_byte {
    -1
  } else if left.start_byte > right.start_byte {
    1
  } else if left.end_byte < right.end_byte {
    -1
  } else if left.end_byte > right.end_byte {
    1
  } else {
    0
  }
}

///|
fn highlight_match_has_property(
  pattern_index : Int,
  key : String,
  settings : Array[@query.QueryPropertySetting],
) -> Bool {
  for setting in settings {
    if setting.pattern_index == pattern_index && setting.key == key {
      return true
    }
  }
  false
}

///|
fn highlight_property_value_for_pattern(
  pattern_index : Int,
  key : String,
  settings : Array[@query.QueryPropertySetting],
) -> String? {
  for setting in settings {
    if setting.pattern_index == pattern_index && setting.key == key {
      return setting.value
    }
  }
  None
}

///|
fn next_highlight_match_with_text_predicates(
  query : @query.Query,
  cursor : @query.QueryCursor,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> @query.QueryMatch? raise @query.QueryPredicateError {
  if encoding == Utf8 || encoding == Custom {
    return cursor.next_match_with_text_predicates_bytes(query, source)
  }
  while true {
    match cursor.next_match() {
      Some(matched) =>
        if highlight_text_predicates_match(query, matched, source, encoding) {
          return Some(matched)
        } else {
          cursor.remove_match(matched.id)
        }
      None => return None
    }
  }
  None
}

///|
fn highlight_text_predicates_match(
  query : @query.Query,
  matched : @query.QueryMatch,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> Bool raise @query.QueryPredicateError {
  let classes = query.classify_predicates()
  for predicate in classes.text_predicates {
    if predicate.pattern_index == matched.pattern_index &&
      !highlight_text_predicate_matches(predicate, matched, source, encoding) {
      return false
    }
  }
  true
}

///|
fn highlight_text_predicate_matches(
  predicate : @query.QueryTextPredicate,
  matched : @query.QueryMatch,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> Bool raise @query.QueryPredicateError {
  let captures = highlight_captures_for_id(matched, predicate.capture_id)
  match predicate.kind {
    TextEq =>
      highlight_all_captures_equal_arg(
        captures, predicate, matched, source, encoding,
      )
    TextNotEq =>
      highlight_all_captures_not_equal_arg(
        captures, predicate, matched, source, encoding,
      )
    TextAnyEq =>
      highlight_any_capture_equals_arg(
        captures, predicate, matched, source, encoding,
      )
    TextAnyNotEq =>
      highlight_any_capture_not_equal_arg(
        captures, predicate, matched, source, encoding,
      )
    TextMatch =>
      highlight_all_captures_match_regex(captures, predicate, source, encoding)
    TextNotMatch =>
      highlight_all_captures_not_match_regex(
        captures, predicate, source, encoding,
      )
    TextAnyMatch =>
      highlight_any_capture_matches_regex(captures, predicate, source, encoding)
    TextAnyNotMatch =>
      highlight_any_capture_not_matches_regex(
        captures, predicate, source, encoding,
      )
    TextAnyOf =>
      highlight_all_captures_are_in_string_set(
        captures, predicate, source, encoding,
      )
    TextNotAnyOf =>
      highlight_all_captures_are_not_in_string_set(
        captures, predicate, source, encoding,
      )
  }
}

///|
fn highlight_captures_for_id(
  matched : @query.QueryMatch,
  capture_id : Int,
) -> Array[@query.QueryCapture] {
  let result : Array[@query.QueryCapture] = []
  for capture in matched.captures {
    if capture.index == capture_id {
      result.push(capture)
    }
  }
  result
}

///|
fn highlight_all_captures_equal_arg(
  captures : Array[@query.QueryCapture],
  predicate : @query.QueryTextPredicate,
  matched : @query.QueryMatch,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> Bool raise @query.QueryPredicateError {
  let arg = highlight_first_text_predicate_arg(predicate)
  if arg is ArgCapture(id) {
    return highlight_all_capture_pairs_equal(
      captures,
      highlight_captures_for_id(matched, id),
      source,
      encoding,
      predicate,
    )
  }
  for capture in captures {
    if !highlight_capture_text_equals_arg(
        capture, arg, predicate, matched, source, encoding,
      ) {
      return false
    }
  }
  true
}

///|
fn highlight_all_captures_not_equal_arg(
  captures : Array[@query.QueryCapture],
  predicate : @query.QueryTextPredicate,
  matched : @query.QueryMatch,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> Bool raise @query.QueryPredicateError {
  let arg = highlight_first_text_predicate_arg(predicate)
  if arg is ArgCapture(id) {
    return highlight_all_capture_pairs_not_equal(
      captures,
      highlight_captures_for_id(matched, id),
      source,
      encoding,
      predicate,
    )
  }
  for capture in captures {
    if highlight_capture_text_equals_arg(
        capture, arg, predicate, matched, source, encoding,
      ) {
      return false
    }
  }
  true
}

///|
fn highlight_any_capture_equals_arg(
  captures : Array[@query.QueryCapture],
  predicate : @query.QueryTextPredicate,
  matched : @query.QueryMatch,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> Bool raise @query.QueryPredicateError {
  let arg = highlight_first_text_predicate_arg(predicate)
  if arg is ArgCapture(id) {
    return highlight_any_capture_pair_equals(
      captures,
      highlight_captures_for_id(matched, id),
      source,
      encoding,
      predicate,
    )
  }
  for capture in captures {
    if highlight_capture_text_equals_arg(
        capture, arg, predicate, matched, source, encoding,
      ) {
      return true
    }
  }
  false
}

///|
fn highlight_any_capture_not_equal_arg(
  captures : Array[@query.QueryCapture],
  predicate : @query.QueryTextPredicate,
  matched : @query.QueryMatch,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> Bool raise @query.QueryPredicateError {
  let arg = highlight_first_text_predicate_arg(predicate)
  if arg is ArgCapture(id) {
    return highlight_any_capture_pair_not_equal(
      captures,
      highlight_captures_for_id(matched, id),
      source,
      encoding,
      predicate,
    )
  }
  for capture in captures {
    if !highlight_capture_text_equals_arg(
        capture, arg, predicate, matched, source, encoding,
      ) {
      return true
    }
  }
  false
}

///|
fn highlight_capture_text_equals_arg(
  capture : @query.QueryCapture,
  arg : @query.QueryPredicateArg,
  predicate : @query.QueryTextPredicate,
  matched : @query.QueryMatch,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> Bool raise @query.QueryPredicateError {
  match arg {
    ArgString(value) =>
      highlight_capture_text(capture, source, encoding, predicate) == value
    ArgCapture(id) => {
      let others = highlight_captures_for_id(matched, id)
      for other in others {
        if highlight_capture_text_equals_capture(
            capture, other, source, encoding, predicate,
          ) {
          return true
        }
      }
      false
    }
  }
}

///|
fn highlight_all_capture_pairs_equal(
  left : Array[@query.QueryCapture],
  right : Array[@query.QueryCapture],
  source : Bytes,
  encoding : @api.InputEncoding,
  predicate : @query.QueryTextPredicate,
) -> Bool raise @query.QueryPredicateError {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if !highlight_capture_text_equals_capture(
        left[i],
        right[i],
        source,
        encoding,
        predicate,
      ) {
      return false
    }
  }
  true
}

///|
fn highlight_all_capture_pairs_not_equal(
  left : Array[@query.QueryCapture],
  right : Array[@query.QueryCapture],
  source : Bytes,
  encoding : @api.InputEncoding,
  predicate : @query.QueryTextPredicate,
) -> Bool raise @query.QueryPredicateError {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if highlight_capture_text_equals_capture(
        left[i],
        right[i],
        source,
        encoding,
        predicate,
      ) {
      return false
    }
  }
  true
}

///|
fn highlight_any_capture_pair_equals(
  left : Array[@query.QueryCapture],
  right : Array[@query.QueryCapture],
  source : Bytes,
  encoding : @api.InputEncoding,
  predicate : @query.QueryTextPredicate,
) -> Bool raise @query.QueryPredicateError {
  let pair_count = highlight_min_int(left.length(), right.length())
  for i in 0..<pair_count {
    if highlight_capture_text_equals_capture(
        left[i],
        right[i],
        source,
        encoding,
        predicate,
      ) {
      return true
    }
  }
  false
}

///|
fn highlight_any_capture_pair_not_equal(
  left : Array[@query.QueryCapture],
  right : Array[@query.QueryCapture],
  source : Bytes,
  encoding : @api.InputEncoding,
  predicate : @query.QueryTextPredicate,
) -> Bool raise @query.QueryPredicateError {
  let pair_count = highlight_min_int(left.length(), right.length())
  for i in 0..<pair_count {
    if !highlight_capture_text_equals_capture(
        left[i],
        right[i],
        source,
        encoding,
        predicate,
      ) {
      return true
    }
  }
  false
}

///|
fn highlight_all_captures_match_regex(
  captures : Array[@query.QueryCapture],
  predicate : @query.QueryTextPredicate,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> Bool raise @query.QueryPredicateError {
  let regex = highlight_first_regex_arg(predicate)
  for capture in captures {
    if !highlight_capture_text_matches_regex(
        capture, source, encoding, regex, predicate,
      ) {
      return false
    }
  }
  true
}

///|
fn highlight_all_captures_not_match_regex(
  captures : Array[@query.QueryCapture],
  predicate : @query.QueryTextPredicate,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> Bool raise @query.QueryPredicateError {
  let regex = highlight_first_regex_arg(predicate)
  for capture in captures {
    if highlight_capture_text_matches_regex(
        capture, source, encoding, regex, predicate,
      ) {
      return false
    }
  }
  true
}

///|
fn highlight_any_capture_matches_regex(
  captures : Array[@query.QueryCapture],
  predicate : @query.QueryTextPredicate,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> Bool raise @query.QueryPredicateError {
  let regex = highlight_first_regex_arg(predicate)
  for capture in captures {
    if highlight_capture_text_matches_regex(
        capture, source, encoding, regex, predicate,
      ) {
      return true
    }
  }
  false
}

///|
fn highlight_any_capture_not_matches_regex(
  captures : Array[@query.QueryCapture],
  predicate : @query.QueryTextPredicate,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> Bool raise @query.QueryPredicateError {
  let regex = highlight_first_regex_arg(predicate)
  for capture in captures {
    if !highlight_capture_text_matches_regex(
        capture, source, encoding, regex, predicate,
      ) {
      return true
    }
  }
  false
}

///|
fn highlight_all_captures_are_in_string_set(
  captures : Array[@query.QueryCapture],
  predicate : @query.QueryTextPredicate,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> Bool raise @query.QueryPredicateError {
  for capture in captures {
    if !highlight_capture_text_is_in_string_set(
        capture, source, encoding, predicate,
      ) {
      return false
    }
  }
  true
}

///|
fn highlight_all_captures_are_not_in_string_set(
  captures : Array[@query.QueryCapture],
  predicate : @query.QueryTextPredicate,
  source : Bytes,
  encoding : @api.InputEncoding,
) -> Bool raise @query.QueryPredicateError {
  for capture in captures {
    if highlight_capture_text_is_in_string_set(
        capture, source, encoding, predicate,
      ) {
      return false
    }
  }
  true
}

///|
fn highlight_capture_text_is_in_string_set(
  capture : @query.QueryCapture,
  source : Bytes,
  encoding : @api.InputEncoding,
  predicate : @query.QueryTextPredicate,
) -> Bool raise @query.QueryPredicateError {
  for arg in predicate.args {
    match arg {
      ArgString(value) =>
        if highlight_capture_text(capture, source, encoding, predicate) == value {
          return true
        }
      ArgCapture(_) =>
        highlight_raise_text_predicate_error(
          predicate, "string set predicate expects only string arguments",
        )
    }
  }
  false
}

///|
fn highlight_first_text_predicate_arg(
  predicate : @query.QueryTextPredicate,
) -> @query.QueryPredicateArg raise @query.QueryPredicateError {
  match predicate.args.get(0) {
    Some(arg) => arg
    None =>
      highlight_raise_text_predicate_error(
        predicate, "missing predicate argument",
      )
  }
}

///|
fn highlight_first_regex_arg(
  predicate : @query.QueryTextPredicate,
) -> String raise @query.QueryPredicateError {
  match highlight_first_text_predicate_arg(predicate) {
    ArgString(value) => value
    ArgCapture(_) =>
      highlight_raise_text_predicate_error(
        predicate, "regex predicate expects a string argument",
      )
  }
}

///|
fn highlight_capture_text_equals_capture(
  left : @query.QueryCapture,
  right : @query.QueryCapture,
  source : Bytes,
  encoding : @api.InputEncoding,
  predicate : @query.QueryTextPredicate,
) -> Bool raise @query.QueryPredicateError {
  highlight_capture_text(left, source, encoding, predicate) ==
  highlight_capture_text(right, source, encoding, predicate)
}

///|
fn highlight_capture_text_matches_regex(
  capture : @query.QueryCapture,
  source : Bytes,
  encoding : @api.InputEncoding,
  regex : String,
  predicate : @query.QueryTextPredicate,
) -> Bool raise @query.QueryPredicateError {
  let normalized = highlight_normalize_text_regex(regex)
  let compiled = Regex(normalized[:]) catch {
    _ => highlight_raise_text_predicate_error(predicate, "invalid regex")
  }
  compiled.execute(
    highlight_capture_text(capture, source, encoding, predicate)[:],
  )
  is Some(_)
}

///|
fn highlight_capture_text(
  capture : @query.QueryCapture,
  source : Bytes,
  encoding : @api.InputEncoding,
  predicate : @query.QueryTextPredicate,
) -> String raise @query.QueryPredicateError {
  let start = capture.node.start_byte().reinterpret_as_int()
  let end = capture.node.end_byte().reinterpret_as_int()
  if start < 0 || end < start || end > source.length() {
    highlight_raise_text_predicate_error(
      predicate, "capture byte range is outside the provided source",
    )
  }
  let view = source[start:end]
  match encoding {
    Utf16LE => highlight_decode_utf16(view, little_endian=true, predicate)
    Utf16BE => highlight_decode_utf16(view, little_endian=false, predicate)
    Utf8 | Custom =>
      @utf8.decode(view) catch {
        _ =>
          highlight_raise_text_predicate_error(
            predicate, "capture text is not valid utf8",
          )
      }
  }
}

///|
fn highlight_decode_utf16(
  source : BytesView,
  little_endian~ : Bool,
  predicate : @query.QueryTextPredicate,
) -> String raise @query.QueryPredicateError {
  if source.length() % 2 != 0 {
    highlight_raise_text_predicate_error(
      predicate, "capture text is not valid utf16",
    )
  }
  let builder = StringBuilder::new()
  for i = 0; i < source.length(); {
    let code_unit = highlight_read_utf16_code_unit(source, i, little_endian~)
    if 0xD800 <= code_unit && code_unit <= 0xDBFF {
      if i + 2 >= source.length() {
        highlight_raise_text_predicate_error(
          predicate, "capture text is not valid utf16",
        )
      }
      let trail = highlight_read_utf16_code_unit(source, i + 2, little_endian~)
      if trail < 0xDC00 || trail > 0xDFFF {
        highlight_raise_text_predicate_error(
          predicate, "capture text is not valid utf16",
        )
      }
      let codepoint = 0x10000 + (code_unit - 0xD800) * 0x400 + (trail - 0xDC00)
      match codepoint.to_char() {
        Some(ch) => builder.write_char(ch)
        None =>
          highlight_raise_text_predicate_error(
            predicate, "capture text is not valid utf16",
          )
      }
      continue i + 4
    } else if 0xDC00 <= code_unit && code_unit <= 0xDFFF {
      highlight_raise_text_predicate_error(
        predicate, "capture text is not valid utf16",
      )
    } else {
      match code_unit.to_char() {
        Some(ch) => builder.write_char(ch)
        None =>
          highlight_raise_text_predicate_error(
            predicate, "capture text is not valid utf16",
          )
      }
      continue i + 2
    }
  }
  builder.to_string()
}

///|
fn highlight_read_utf16_code_unit(
  source : BytesView,
  offset : Int,
  little_endian~ : Bool,
) -> Int {
  let first = source[offset].to_int()
  let second = source[offset + 1].to_int()
  if little_endian {
    first + second * 0x100
  } else {
    first * 0x100 + second
  }
}

///|
fn highlight_normalize_text_regex(regex : String) -> String {
  let builder = StringBuilder::new()
  let mut escaped = false
  for offset = 0; offset < regex.length(); {
    match regex.get_char(offset) {
      Some(ch) => {
        if escaped {
          highlight_write_regex_escape(builder, ch)
          escaped = false
        } else if ch == '\\' {
          escaped = true
        } else if ch == '[' {
          let (normalized_class, next_offset) = highlight_normalize_regex_class(
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
fn highlight_normalize_regex_class(
  regex : String,
  start : Int,
) -> (String, Int) {
  let class_builder = StringBuilder::new()
  let complements : Array[String] = []
  let mut has_positive_atom = false
  let mut escaped = false
  let mut offset = start + 1
  class_builder.write_char('[')
  while offset < regex.length() {
    guard regex.get_char(offset) is Some(ch) else { break }
    if escaped {
      match highlight_regex_class_complement_escape(ch) {
        Some(complement) => complements.push(complement)
        None => {
          highlight_write_regex_class_escape(class_builder, ch)
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
        highlight_join_regex_class_complements(
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
fn highlight_join_regex_class_complements(
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
fn highlight_write_regex_escape(builder : StringBuilder, ch : Char) -> Unit {
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
fn highlight_regex_class_complement_escape(ch : Char) -> String? {
  match ch {
    'D' => Some("[^[:digit:]]")
    'S' => Some("[^[:space:]]")
    'W' => Some("[^[:word:]]")
    _ => None
  }
}

///|
fn highlight_write_regex_class_escape(
  builder : StringBuilder,
  ch : Char,
) -> Unit {
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
fn highlight_min_int(left : Int, right : Int) -> Int {
  if left < right {
    left
  } else {
    right
  }
}

///|
fn[T] highlight_raise_text_predicate_error(
  predicate : @query.QueryTextPredicate,
  reason : String,
) -> T raise @query.QueryPredicateError {
  raise @query.QueryPredicateError::Predicate(
    pattern_index=predicate.pattern_index,
    byte_offset=predicate.byte_offset,
    operator=highlight_text_predicate_operator(predicate.kind),
    reason~,
  )
}

///|
fn highlight_text_predicate_operator(
  kind : @query.QueryTextPredicateKind,
) -> String {
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

///|
fn add_highlight_capture_range(
  config : HighlightConfiguration,
  ranges : Array[HighlightRange],
  local_ranges : Array[HighlightLocalRange],
  capture : @query.QueryCapture,
  depth : Int,
) -> Unit {
  if capture.pattern_index >= config.injection_pattern_start {
    return
  }
  guard highlight_name_for_capture(config, capture) is Some(name) else {
    return
  }
  let start_byte = capture.node.start_byte()
  let end_byte = capture.node.end_byte()
  if start_byte >= end_byte {
    return
  }
  if highlight_pattern_is_non_local(config, capture.pattern_index) &&
    highlight_range_is_local(local_ranges, start_byte, end_byte) {
    return
  }
  let range = HighlightRange::{
    start_byte,
    end_byte,
    name,
    pattern_index: capture.pattern_index,
    capture_index: capture.index,
    depth,
  }
  add_resolved_highlight_range(ranges, range)
}

///|
fn add_resolved_highlight_range(
  ranges : Array[HighlightRange],
  range : HighlightRange,
) -> Unit {
  match find_exact_highlight_range(ranges, range.start_byte, range.end_byte) {
    Some(index) =>
      if highlight_range_overrides(range, ranges[index]) {
        ranges[index] = range
      }
    None => ranges.push(range)
  }
}

///|
fn highlight_name_for_capture(
  config : HighlightConfiguration,
  capture : @query.QueryCapture,
) -> String? {
  let capture_name = capture.name
  if capture_name.has_prefix("injection.") || capture_name.has_prefix("local.") {
    return None
  }
  match config.capture_highlight_names.get(capture.index) {
    Some(Some(name)) => Some(name)
    _ => None
  }
}

///|
fn collect_highlight_local_context(
  config : HighlightConfiguration,
  source : Bytes,
  matches : Array[@query.QueryMatch],
  depth : Int,
) -> HighlightLocalContext {
  let scopes = collect_highlight_local_scopes(
    config,
    source.length().reinterpret_as_uint(),
    matches,
  )
  let ranges : Array[HighlightLocalRange] = []
  let definitions : Array[HighlightLocalDefinition] = []
  let inherited_ranges : Array[HighlightRange] = []
  for matched in matches {
    for capture in matched.captures {
      if highlight_capture_is_local(config, capture) {
        let start_byte = capture.node.start_byte()
        let end_byte = capture.node.end_byte()
        if start_byte < end_byte {
          ranges.push({ start_byte, end_byte })
        }
      }
      if Some(capture.index) == config.local_definition_capture_index {
        collect_highlight_local_definition(
          config, source, scopes, matches, definitions, matched, capture,
        )
      }
    }
  }
  for matched in matches {
    for capture in matched.captures {
      if Some(capture.index) == config.local_reference_capture_index {
        match
          highlight_definition_for_reference(
            source, scopes, definitions, capture,
          ) {
          Some(definition) =>
            match definition.highlight_name {
              Some(name) =>
                inherited_ranges.push(HighlightRange::{
                  start_byte: capture.node.start_byte(),
                  end_byte: capture.node.end_byte(),
                  name,
                  pattern_index: config.query.pattern_count(),
                  capture_index: capture.index,
                  depth,
                })
              None => ()
            }
          None => ()
        }
      }
    }
  }
  { ranges, inherited_ranges }
}

///|
fn collect_highlight_local_scopes(
  config : HighlightConfiguration,
  source_length : UInt,
  matches : Array[@query.QueryMatch],
) -> Array[HighlightLocalScope] {
  let scopes : Array[HighlightLocalScope] = [
    { start_byte: 0U, end_byte: source_length, inherits: true },
  ]
  for matched in matches {
    for capture in matched.captures {
      if Some(capture.index) == config.local_scope_capture_index {
        let start_byte = capture.node.start_byte()
        let end_byte = capture.node.end_byte()
        if start_byte < end_byte {
          scopes.push({
            start_byte,
            end_byte,
            inherits: highlight_local_scope_inherits(
              config,
              matched.pattern_index,
            ),
          })
        }
      }
    }
  }
  scopes
}

///|
fn collect_highlight_local_definition(
  config : HighlightConfiguration,
  source : Bytes,
  scopes : Array[HighlightLocalScope],
  matches : Array[@query.QueryMatch],
  definitions : Array[HighlightLocalDefinition],
  matched : @query.QueryMatch,
  capture : @query.QueryCapture,
) -> Unit {
  let start_byte = capture.node.start_byte()
  let end_byte = capture.node.end_byte()
  if start_byte >= end_byte {
    return
  }
  let value_end_byte = highlight_local_definition_value_end(
    config, matched, end_byte,
  )
  let highlight_name = highlight_best_name_for_range(
    config,
    matches,
    start_byte,
    end_byte,
    is_local=true,
  )
  definitions.push({
    start_byte,
    value_end_byte,
    name: highlight_source_bytes(source, start_byte, end_byte),
    highlight_name,
    scope_index: highlight_scope_for_range(scopes, start_byte, end_byte),
  })
}

///|
fn highlight_local_definition_value_end(
  config : HighlightConfiguration,
  matched : @query.QueryMatch,
  fallback_end_byte : UInt,
) -> UInt {
  let mut value_end_byte = fallback_end_byte
  for capture in matched.captures {
    if Some(capture.index) == config.local_definition_value_capture_index {
      value_end_byte = capture.node.end_byte()
    }
  }
  value_end_byte
}

///|
fn highlight_local_scope_inherits(
  config : HighlightConfiguration,
  pattern_index : Int,
) -> Bool {
  match config.local_scope_inherits_patterns.get(pattern_index) {
    Some(inherits) => inherits
    None => true
  }
}

///|
fn highlight_definition_for_reference(
  source : Bytes,
  scopes : Array[HighlightLocalScope],
  definitions : Array[HighlightLocalDefinition],
  capture : @query.QueryCapture,
) -> HighlightLocalDefinition? {
  let start_byte = capture.node.start_byte()
  let end_byte = capture.node.end_byte()
  let name = highlight_source_bytes(source, start_byte, end_byte)
  let scope_chain = highlight_scope_chain_for_range(
    scopes, start_byte, end_byte,
  )
  for scope_index in scope_chain {
    let mut best : HighlightLocalDefinition? = None
    for definition in definitions {
      if definition.scope_index == scope_index &&
        definition.name == name &&
        definition.start_byte <= start_byte &&
        start_byte >= definition.value_end_byte {
        match best {
          Some(current) =>
            if definition.value_end_byte > current.value_end_byte ||
              (
                definition.value_end_byte == current.value_end_byte &&
                definition.start_byte > current.start_byte
              ) {
              best = Some(definition)
            }
          None => best = Some(definition)
        }
      }
    }
    if best is Some(_) {
      return best
    }
    if !scopes[scope_index].inherits {
      return None
    }
  }
  None
}

///|
fn highlight_scope_for_range(
  scopes : Array[HighlightLocalScope],
  start_byte : UInt,
  end_byte : UInt,
) -> Int {
  let mut result = 0
  for index, scope in scopes {
    if highlight_scope_contains(scope, start_byte, end_byte) &&
      highlight_scope_index_compare(scopes, index, result) < 0 {
      result = index
    }
  }
  result
}

///|
fn highlight_scope_chain_for_range(
  scopes : Array[HighlightLocalScope],
  start_byte : UInt,
  end_byte : UInt,
) -> Array[Int] {
  let result : Array[Int] = []
  for index, scope in scopes {
    if highlight_scope_contains(scope, start_byte, end_byte) {
      result.push(index)
    }
  }
  result.sort_by((left, right) => {
    highlight_scope_index_compare(scopes, left, right)
  })
  result
}

///|
fn highlight_scope_contains(
  scope : HighlightLocalScope,
  start_byte : UInt,
  end_byte : UInt,
) -> Bool {
  scope.start_byte <= start_byte && end_byte <= scope.end_byte
}

///|
fn highlight_scope_index_compare(
  scopes : Array[HighlightLocalScope],
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
fn highlight_best_name_for_range(
  config : HighlightConfiguration,
  matches : Array[@query.QueryMatch],
  start_byte : UInt,
  end_byte : UInt,
  is_local~ : Bool,
) -> String? {
  let mut best : HighlightRange? = None
  for matched in matches {
    for capture in matched.captures {
      if capture.node.start_byte() == start_byte &&
        capture.node.end_byte() == end_byte {
        if is_local &&
          highlight_pattern_is_non_local(config, capture.pattern_index) {
          continue
        }
        match highlight_name_for_capture(config, capture) {
          Some(name) => {
            let candidate = HighlightRange::{
              start_byte,
              end_byte,
              name,
              pattern_index: capture.pattern_index,
              capture_index: capture.index,
              depth: 0,
            }
            match best {
              Some(current) =>
                if highlight_range_overrides(candidate, current) {
                  best = Some(candidate)
                }
              None => best = Some(candidate)
            }
          }
          None => ()
        }
      }
    }
  }
  match best {
    Some(range) => Some(range.name)
    None => None
  }
}

///|
fn highlight_source_bytes(
  source : Bytes,
  start_byte : UInt,
  end_byte : UInt,
) -> Bytes {
  source[start_byte.reinterpret_as_int():end_byte.reinterpret_as_int()].to_owned()
}

///|
fn highlight_capture_is_local(
  config : HighlightConfiguration,
  capture : @query.QueryCapture,
) -> Bool {
  Some(capture.index) == config.local_definition_capture_index ||
  Some(capture.index) == config.local_reference_capture_index
}

///|
fn highlight_pattern_is_non_local(
  config : HighlightConfiguration,
  pattern_index : Int,
) -> Bool {
  match config.non_local_variable_patterns.get(pattern_index) {
    Some(value) => value
    None => false
  }
}

///|
fn highlight_range_is_local(
  local_ranges : Array[HighlightLocalRange],
  start_byte : UInt,
  end_byte : UInt,
) -> Bool {
  for range in local_ranges {
    if range.start_byte == start_byte && range.end_byte == end_byte {
      return true
    }
  }
  false
}

///|
fn highlight_query_capture_names(query : @query.Query) -> Array[String] {
  let names : Array[String] = []
  for capture_id in 0..<query.capture_count() {
    match query.capture_name_for_id(capture_id) {
      Some(name) => names.push(name)
      None => ()
    }
  }
  names
}

///|
fn highlight_capture_name_map(
  query : @query.Query,
  recognized_names : Array[String],
) -> Array[String?] {
  let result : Array[String?] = []
  for capture_name in highlight_query_capture_names(query) {
    result.push(
      highlight_recognized_name_for_capture(capture_name, recognized_names),
    )
  }
  result
}

///|
fn highlight_capture_id(query : @query.Query, capture_name : String) -> Int? {
  for capture_id in 0..<query.capture_count() {
    if query.capture_name_for_id(capture_id) == Some(capture_name) {
      return Some(capture_id)
    }
  }
  None
}

///|
fn highlight_non_local_variable_patterns(
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
fn highlight_local_scope_inherits_patterns(
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
fn highlight_recognized_name_for_capture(
  capture_name : String,
  recognized_names : Array[String],
) -> String? {
  let capture_parts = highlight_capture_name_parts(capture_name)
  let mut best_name : String? = None
  let mut best_part_count = 0
  for recognized_name in recognized_names {
    let recognized_parts = highlight_capture_name_parts(recognized_name)
    let mut matches = true
    for part in recognized_parts {
      if !capture_parts.contains(part) {
        matches = false
        break
      }
    }
    if matches && recognized_parts.length() > best_part_count {
      best_name = Some(recognized_name)
      best_part_count = recognized_parts.length()
    }
  }
  best_name
}

///|
fn highlight_capture_name_parts(name : String) -> Array[String] {
  let parts : Array[String] = []
  for part in name.split(".") {
    parts.push(part.to_owned())
  }
  parts
}

///|
fn standard_highlight_capture_names() -> Array[String] {
  [
    "attribute", "boolean", "carriage-return", "comment", "comment.documentation",
    "constant", "constant.builtin", "constructor", "constructor.builtin", "embedded",
    "error", "escape", "function", "function.builtin", "keyword", "markup", "markup.bold",
    "markup.heading", "markup.italic", "markup.link", "markup.link.url", "markup.list",
    "markup.list.checked", "markup.list.numbered", "markup.list.unchecked", "markup.list.unnumbered",
    "markup.quote", "markup.raw", "markup.raw.block", "markup.raw.inline", "markup.strikethrough",
    "module", "number", "operator", "property", "property.builtin", "punctuation",
    "punctuation.bracket", "punctuation.delimiter", "punctuation.special", "string",
    "string.escape", "string.regexp", "string.special", "string.special.symbol",
    "tag", "type", "type.builtin", "variable", "variable.builtin", "variable.member",
    "variable.parameter",
  ]
}

///|
fn find_exact_highlight_range(
  ranges : Array[HighlightRange],
  start_byte : UInt,
  end_byte : UInt,
) -> Int? {
  for index, range in ranges {
    if range.start_byte == start_byte && range.end_byte == end_byte {
      return Some(index)
    }
  }
  None
}

///|
fn highlight_range_overrides(
  candidate : HighlightRange,
  existing : HighlightRange,
) -> Bool {
  candidate.depth > existing.depth ||
  (
    candidate.depth == existing.depth &&
    (
      candidate.pattern_index > existing.pattern_index ||
      (
        candidate.pattern_index == existing.pattern_index &&
        candidate.capture_index >= existing.capture_index
      )
    )
  )
}

///|
fn render_highlight_events(
  source_length : UInt,
  ranges : Array[HighlightRange],
  options : HighlightOptions,
) -> Array[HighlightEvent] raise HighlightError {
  let boundaries : Array[HighlightBoundary] = []
  for range in ranges {
    boundaries.push({
      byte: range.start_byte,
      is_end: false,
      start_byte: range.start_byte,
      end_byte: range.end_byte,
      name: range.name,
      depth: range.depth,
    })
    boundaries.push({
      byte: range.end_byte,
      is_end: true,
      start_byte: range.start_byte,
      end_byte: range.end_byte,
      name: range.name,
      depth: range.depth,
    })
  }
  boundaries.sort_by(highlight_boundary_compare)
  let events : Array[HighlightEvent] = []
  let mut cursor = 0U
  maybe_cancel_highlight(
    options,
    HighlightProgressState::new(phase=Render, current_byte_offset=cursor),
  )
  for boundary in boundaries {
    maybe_cancel_highlight(
      options,
      HighlightProgressState::new(
        phase=Render,
        current_byte_offset=boundary.byte,
      ),
    )
    if boundary.byte > cursor {
      events.push(Source(start_byte=cursor, end_byte=boundary.byte))
      cursor = boundary.byte
    }
    if boundary.is_end {
      events.push(HighlightEnd(boundary.name))
    } else {
      events.push(HighlightStart(boundary.name))
    }
  }
  if cursor < source_length {
    maybe_cancel_highlight(
      options,
      HighlightProgressState::new(
        phase=Render,
        current_byte_offset=source_length,
      ),
    )
    events.push(Source(start_byte=cursor, end_byte=source_length))
  }
  events
}

///|
fn highlight_range_compare(
  left : HighlightRange,
  right : HighlightRange,
) -> Int {
  if left.start_byte < right.start_byte {
    -1
  } else if left.start_byte > right.start_byte {
    1
  } else if left.end_byte > right.end_byte {
    -1
  } else if left.end_byte < right.end_byte {
    1
  } else if left.depth > right.depth {
    -1
  } else if left.depth < right.depth {
    1
  } else if left.pattern_index < right.pattern_index {
    -1
  } else if left.pattern_index > right.pattern_index {
    1
  } else {
    0
  }
}

///|
fn highlight_boundary_compare(
  left : HighlightBoundary,
  right : HighlightBoundary,
) -> Int {
  if left.byte < right.byte {
    -1
  } else if left.byte > right.byte {
    1
  } else if left.is_end != right.is_end {
    if left.is_end {
      -1
    } else {
      1
    }
  } else if left.depth != right.depth {
    if left.depth > right.depth {
      -1
    } else {
      1
    }
  } else if !left.is_end {
    if left.end_byte > right.end_byte {
      -1
    } else if left.end_byte < right.end_byte {
      1
    } else {
      0
    }
  } else if left.start_byte > right.start_byte {
    -1
  } else if left.start_byte < right.start_byte {
    1
  } else {
    0
  }
}
