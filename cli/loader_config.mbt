///|
pub(all) suberror CliConfigError {
  InvalidJson(String)
  ExpectedObject(String)
  ExpectedArray(String)
  ExpectedString(String)
  MissingField(path~ : String, field~ : String)
  InvalidSemanticVersion(path~ : String, value~ : String)
  InvalidRegex(path~ : String, pattern~ : String)
} derive(Eq, Debug)

///|
pub(all) struct CliGlobalConfig {
  parser_directories : Array[String]
  theme : Json?
} derive(Eq, Debug)

///|
pub(all) struct CliGlobalConfigPathEnvironment {
  tree_sitter_dir : String?
  xdg_config_home : String?
  home : String?
} derive(Eq, Debug)

///|
pub(all) struct CliTreeSitterConfig {
  grammars : Array[CliLanguageConfig]
} derive(Eq, Debug)

///|
pub(all) struct CliLanguageConfig {
  scope : String
  path : String?
  file_types : Array[String]
  content_regex : String?
  first_line_regex : String?
  injection_regex : String?
  highlights : Array[String]
  injections : Array[String]
  locals : Array[String]
  tags : Array[String]
  external_files : Array[String]
} derive(Eq, Debug)

///|
pub(all) struct CliLanguageFileTypeMatch {
  file_type : String
  exact_filename : Bool
  suffix_length : Int
} derive(Eq, Debug)

///|
pub(all) enum CliLanguageSelectionReason {
  CliLanguageByScope
  CliLanguageByFileType
  CliLanguageByFirstLine
} derive(Eq, Debug)

///|
pub(all) enum CliLanguageSelection {
  CliLanguageFromLibPath(String)
  CliLanguageFromConfig(CliLanguageConfig, CliLanguageSelectionReason)
} derive(Eq, Debug)

///|
pub(all) struct CliLanguageConfigLocation {
  parser_root : String
  grammar_root : String
  config : CliLanguageConfig
} derive(Eq, Debug)

///|
pub(all) enum CliLocatedLanguageSelection {
  CliLocatedLanguageFromLibPath(String)
  CliLocatedLanguageFromConfig(
    CliLanguageConfigLocation,
    CliLanguageSelectionReason
  )
} derive(Eq, Debug)

///|
pub(all) enum CliQueryFileKind {
  CliQueryFileHighlights
  CliQueryFileInjections
  CliQueryFileLocals
  CliQueryFileTags
  CliQueryFileOther
} derive(Eq, Debug)

///|
pub fn parse_cli_global_config_json(
  source : String,
) -> CliGlobalConfig raise CliConfigError {
  let json = @json.parse(source[:]) catch {
    err => raise CliConfigError::InvalidJson(err.to_string())
  }
  let fields = cli_config_expect_object(json, "$")
  {
    parser_directories: cli_config_optional_string_array_field(
      fields, "parser-directories", "$",
    ),
    theme: fields.get("theme"),
  }
}

///|
pub fn parse_cli_tree_sitter_config_json(
  source : String,
) -> CliTreeSitterConfig raise CliConfigError {
  let json = @json.parse(source[:]) catch {
    err => raise CliConfigError::InvalidJson(err.to_string())
  }
  parse_cli_tree_sitter_config(json)
}

///|
pub fn parse_cli_tree_sitter_metadata_json(
  source : String,
) -> @tables.LanguageMetadata raise CliConfigError {
  let json = @json.parse(source[:]) catch {
    err => raise CliConfigError::InvalidJson(err.to_string())
  }
  let fields = cli_config_expect_object(json, "$")
  let metadata_json = match fields.get("metadata") {
    Some(value) => value
    None => raise CliConfigError::MissingField(path="$", field="metadata")
  }
  let metadata_fields = cli_config_expect_object(metadata_json, "$.metadata")
  let version = cli_config_required_string_field(
    metadata_fields, "version", "$.metadata",
  )
  cli_config_parse_semantic_version(version, "$.metadata.version")
}

///|
pub fn classify_cli_query_file_path(path : String) -> CliQueryFileKind {
  let base = cli_config_basename(path)
  if base.has_suffix("highlights.scm") {
    CliQueryFileHighlights
  } else if base.has_suffix("injections.scm") {
    CliQueryFileInjections
  } else if base.has_suffix("locals.scm") {
    CliQueryFileLocals
  } else if base.has_suffix("tags.scm") {
    CliQueryFileTags
  } else {
    CliQueryFileOther
  }
}

///|
pub fn cli_global_config_path_candidates_for_environment(
  explicit_path : String?,
  environment : CliGlobalConfigPathEnvironment,
) -> Array[String] {
  match explicit_path {
    Some(path) => [path]
    None => {
      let paths : Array[String] = []
      match environment.tree_sitter_dir {
        Some(dir) => cli_config_push_joined_candidate(paths, dir, "config.json")
        None => ()
      }
      match environment.xdg_config_home {
        Some(dir) =>
          cli_config_push_joined_candidate(
            paths, dir, "tree-sitter/config.json",
          )
        None =>
          match environment.home {
            Some(home) =>
              cli_config_push_joined_candidate(
                paths, home, ".config/tree-sitter/config.json",
              )
            None => ()
          }
      }
      match environment.home {
        Some(home) =>
          cli_config_push_joined_candidate(
            paths, home, ".tree-sitter/config.json",
          )
        None => ()
      }
      paths
    }
  }
}

///|
pub fn cli_tree_sitter_config_path(parser_root : String) -> String {
  cli_query_join_path(parser_root, "tree-sitter.json")
}

///|
pub fn cli_language_config_grammar_root(
  parser_root : String,
  config : CliLanguageConfig,
) -> String {
  match config.path {
    Some(path) =>
      if path.is_empty() || path == "." {
        parser_root
      } else {
        cli_query_join_path(parser_root, path)
      }
    None => parser_root
  }
}

///|
pub fn locate_cli_language_configs(
  parser_root : String,
  tree_sitter_config : CliTreeSitterConfig,
) -> Array[CliLanguageConfigLocation] {
  let locations : Array[CliLanguageConfigLocation] = []
  for config in tree_sitter_config.grammars {
    locations.push({
      parser_root,
      grammar_root: cli_language_config_grammar_root(parser_root, config),
      config,
    })
  }
  locations
}

///|
pub fn select_cli_language_config_for_scope(
  configs : Array[CliLanguageConfig],
  scope : String,
) -> CliLanguageConfig? {
  for config in configs {
    if config.scope == scope {
      return Some(config)
    }
  }
  None
}

///|
pub fn cli_language_file_type_match(
  config : CliLanguageConfig,
  file_name : String,
) -> CliLanguageFileTypeMatch? {
  let base = cli_config_basename(file_name)
  let mut best : CliLanguageFileTypeMatch? = None
  for file_type in config.file_types {
    let candidate = if base == file_type {
      Some({
        file_type,
        exact_filename: true,
        suffix_length: file_type.length(),
      })
    } else {
      match cli_config_extension_suffix_length(base, file_type) {
        Some(length) =>
          Some({ file_type, exact_filename: false, suffix_length: length })
        None => None
      }
    }
    match (best, candidate) {
      (None, Some(next)) => best = Some(next)
      (Some(current), Some(next)) =>
        if cli_config_file_type_match_is_better(next, current) {
          best = Some(next)
        }
      _ => ()
    }
  }
  best
}

///|
pub fn select_cli_language_config_for_first_line(
  configs : Array[CliLanguageConfig],
  first_line : String,
) -> CliLanguageConfig? raise CliConfigError {
  for config in configs {
    match config.first_line_regex {
      Some(pattern) => {
        let compiled = Regex(pattern[:]) catch {
          _ =>
            raise CliConfigError::InvalidRegex(
              path="$.grammars[].first-line-regex",
              pattern~,
            )
        }
        match compiled.execute(first_line[:]) {
          Some(_) => return Some(config)
          None => ()
        }
      }
      None => ()
    }
  }
  None
}

///|
pub fn select_cli_language(
  configs : Array[CliLanguageConfig],
  lib_path? : String,
  scope? : String,
  file_name? : String,
  source? : String,
) -> CliLanguageSelection? raise CliConfigError {
  match lib_path {
    Some(path) => return Some(CliLanguageFromLibPath(path))
    None => ()
  }
  match scope {
    Some(scope) =>
      match select_cli_language_config_for_scope(configs, scope) {
        Some(config) =>
          return Some(CliLanguageFromConfig(config, CliLanguageByScope))
        None => return None
      }
    None => ()
  }
  match file_name {
    Some(file_name) =>
      match
        cli_select_language_config_for_file_with_optional_source(
          configs, file_name, source,
        ) {
        Some(config) =>
          return Some(CliLanguageFromConfig(config, CliLanguageByFileType))
        None => ()
      }
    None => ()
  }
  match source {
    Some(source) =>
      match
        select_cli_language_config_for_first_line(
          configs,
          cli_config_first_line(source),
        ) {
        Some(config) =>
          Some(CliLanguageFromConfig(config, CliLanguageByFirstLine))
        None => None
      }
    None => None
  }
}

///|
pub fn select_cli_language_location(
  locations : Array[CliLanguageConfigLocation],
  lib_path? : String,
  scope? : String,
  file_name? : String,
  source? : String,
) -> CliLocatedLanguageSelection? raise CliConfigError {
  match lib_path {
    Some(path) => return Some(CliLocatedLanguageFromLibPath(path))
    None => ()
  }
  match scope {
    Some(scope) =>
      match select_cli_language_location_for_scope(locations, scope) {
        Some(location) =>
          return Some(
            CliLocatedLanguageFromConfig(location, CliLanguageByScope),
          )
        None => return None
      }
    None => ()
  }
  let configs = cli_language_location_configs(locations)
  match file_name {
    Some(file_name) =>
      match
        cli_select_language_config_for_file_with_optional_source(
          configs, file_name, source,
        ) {
        Some(config) =>
          match cli_language_location_for_config(locations, config) {
            Some(location) =>
              return Some(
                CliLocatedLanguageFromConfig(location, CliLanguageByFileType),
              )
            None => ()
          }
        None => ()
      }
    None => ()
  }
  match source {
    Some(source) =>
      match
        select_cli_language_config_for_first_line(
          configs,
          cli_config_first_line(source),
        ) {
        Some(config) =>
          match cli_language_location_for_config(locations, config) {
            Some(location) =>
              Some(
                CliLocatedLanguageFromConfig(location, CliLanguageByFirstLine),
              )
            None => None
          }
        None => None
      }
    None => None
  }
}

///|
pub fn select_cli_language_location_for_scope(
  locations : Array[CliLanguageConfigLocation],
  scope : String,
) -> CliLanguageConfigLocation? {
  for location in locations {
    if location.config.scope == scope {
      return Some(location)
    }
  }
  None
}

///|
pub fn select_cli_language_config_for_file(
  configs : Array[CliLanguageConfig],
  file_name : String,
  source? : String,
) -> CliLanguageConfig? raise CliConfigError {
  let mut best_config : CliLanguageConfig? = None
  let mut best_file_score = -1
  let mut best_content_rank = -2
  let mut best_content_len = -1
  for config in configs {
    match cli_language_file_type_match(config, file_name) {
      Some(file_match) => {
        let file_score = cli_config_file_type_score(file_match)
        if file_score >= best_file_score {
          let (content_rank, content_len) = cli_config_content_regex_score(
            config, source,
          )
          if file_score > best_file_score ||
            cli_config_content_score_is_better(
              content_rank, content_len, best_content_rank, best_content_len,
            ) {
            best_config = Some(config)
            best_file_score = file_score
            best_content_rank = content_rank
            best_content_len = content_len
          }
        }
      }
      None => ()
    }
  }
  best_config
}

///|
pub fn select_cli_language_config_for_injection(
  configs : Array[CliLanguageConfig],
  injection_string : String,
) -> CliLanguageConfig? raise CliConfigError {
  let mut best_config : CliLanguageConfig? = None
  let mut best_length = -1
  for config in configs {
    match config.injection_regex {
      Some(pattern) => {
        let compiled = Regex(pattern[:]) catch {
          _ =>
            raise CliConfigError::InvalidRegex(
              path="$.grammars[].injection-regex",
              pattern~,
            )
        }
        match compiled.execute(injection_string[:]) {
          Some(result) => {
            let length = result.content().length()
            if length > best_length {
              best_length = length
              best_config = Some(config)
            }
          }
          None => ()
        }
      }
      None => ()
    }
  }
  best_config
}

///|
fn parse_cli_tree_sitter_config(
  json : Json,
) -> CliTreeSitterConfig raise CliConfigError {
  let fields = cli_config_expect_object(json, "$")
  let grammar_jsons = cli_config_optional_array_field(fields, "grammars", "$")
  let grammars : Array[CliLanguageConfig] = []
  for index, grammar_json in grammar_jsons {
    grammars.push(
      parse_cli_language_config(grammar_json, "$.grammars[\{index}]"),
    )
  }
  { grammars, }
}

///|
fn parse_cli_language_config(
  json : Json,
  path : String,
) -> CliLanguageConfig raise CliConfigError {
  let fields = cli_config_expect_object(json, path)
  {
    scope: cli_config_required_string_field(fields, "scope", path),
    path: cli_config_optional_string_field(fields, "path", path),
    file_types: cli_config_optional_string_array_field(
      fields, "file-types", path,
    ),
    content_regex: cli_config_optional_string_field(
      fields, "content-regex", path,
    ),
    first_line_regex: cli_config_optional_string_field(
      fields, "first-line-regex", path,
    ),
    injection_regex: cli_config_optional_string_field(
      fields, "injection-regex", path,
    ),
    highlights: cli_config_optional_string_array_field(
      fields, "highlights", path,
    ),
    injections: cli_config_optional_string_array_field(
      fields, "injections", path,
    ),
    locals: cli_config_optional_string_array_field(fields, "locals", path),
    tags: cli_config_optional_string_array_field(fields, "tags", path),
    external_files: cli_config_optional_string_array_field(
      fields, "external-files", path,
    ),
  }
}

///|
fn cli_config_expect_object(
  json : Json,
  path : String,
) -> Map[String, Json] raise CliConfigError {
  match json {
    Json::Object(fields) => fields
    _ => raise CliConfigError::ExpectedObject(path)
  }
}

///|
fn cli_config_expect_array(
  json : Json,
  path : String,
) -> Array[Json] raise CliConfigError {
  match json {
    Json::Array(items) => items
    _ => raise CliConfigError::ExpectedArray(path)
  }
}

///|
fn cli_config_expect_string(
  json : Json,
  path : String,
) -> String raise CliConfigError {
  match json {
    Json::String(value) => value
    _ => raise CliConfigError::ExpectedString(path)
  }
}

///|
fn cli_config_optional_array_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> Array[Json] raise CliConfigError {
  match fields.get(name) {
    Some(value) =>
      cli_config_expect_array(value, cli_config_path_key(path, name))
    None => []
  }
}

///|
fn cli_config_optional_string_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> String? raise CliConfigError {
  match fields.get(name) {
    Some(value) =>
      Some(cli_config_expect_string(value, cli_config_path_key(path, name)))
    None => None
  }
}

///|
fn cli_config_required_string_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> String raise CliConfigError {
  match cli_config_optional_string_field(fields, name, path) {
    Some(value) => value
    None => raise CliConfigError::MissingField(path~, field=name)
  }
}

///|
fn cli_config_parse_semantic_version(
  value : String,
  path : String,
) -> @tables.LanguageMetadata raise CliConfigError {
  let parts : Array[String] = []
  for part in value.split(".") {
    parts.push(part.to_owned())
  }
  if parts.length() != 3 {
    raise CliConfigError::InvalidSemanticVersion(path~, value~)
  }
  @tables.LanguageMetadata::new(
    major=cli_config_parse_semantic_version_part(parts[0], path, value),
    minor=cli_config_parse_semantic_version_part(parts[1], path, value),
    patch=cli_config_parse_semantic_version_part(parts[2], path, value),
  )
}

///|
fn cli_config_parse_semantic_version_part(
  part : String,
  path : String,
  value : String,
) -> Int raise CliConfigError {
  if part.is_empty() || (part.length() > 1 && part.get_char(0) == Some('0')) {
    raise CliConfigError::InvalidSemanticVersion(path~, value~)
  }
  let mut result = 0
  for char in part {
    let code = char.to_uint()
    if code < 48U || code > 57U {
      raise CliConfigError::InvalidSemanticVersion(path~, value~)
    }
    result = result * 10 + (code - 48U).reinterpret_as_int()
  }
  result
}

///|
fn cli_config_optional_string_array_field(
  fields : Map[String, Json],
  name : String,
  path : String,
) -> Array[String] raise CliConfigError {
  let items = cli_config_optional_array_field(fields, name, path)
  let strings : Array[String] = []
  let array_path = cli_config_path_key(path, name)
  for index, item in items {
    strings.push(cli_config_expect_string(item, "\{array_path}[\{index}]"))
  }
  strings
}

///|
fn cli_config_path_key(path : String, key : String) -> String {
  if path == "$" {
    "$.\{key}"
  } else {
    "\{path}.\{key}"
  }
}

///|
fn cli_config_basename(path : String) -> String {
  let slash = path.rev_find("/")
  let backslash = path.rev_find("\\")
  let index = match (slash, backslash) {
    (Some(a), Some(b)) => if a > b { a } else { b }
    (Some(a), None) => a
    (None, Some(b)) => b
    (None, None) => -1
  }
  if index >= 0 {
    path[index + 1:].to_owned()
  } else {
    path
  }
}

///|
fn cli_config_extension_suffix_length(
  base : String,
  file_type : String,
) -> Int? {
  if file_type.is_empty() {
    None
  } else if file_type.has_prefix(".") {
    if base.has_suffix(file_type) {
      Some(file_type.length() - 1)
    } else {
      None
    }
  } else {
    let suffix = ".\{file_type}"
    if base.has_suffix(suffix) {
      Some(file_type.length())
    } else {
      None
    }
  }
}

///|
fn cli_config_file_type_match_is_better(
  next : CliLanguageFileTypeMatch,
  current : CliLanguageFileTypeMatch,
) -> Bool {
  if next.exact_filename != current.exact_filename {
    next.exact_filename
  } else {
    next.suffix_length > current.suffix_length
  }
}

///|
fn cli_config_file_type_score(file_match : CliLanguageFileTypeMatch) -> Int {
  if file_match.exact_filename {
    1000000 + file_match.suffix_length
  } else {
    file_match.suffix_length
  }
}

///|
fn cli_config_content_regex_score(
  config : CliLanguageConfig,
  source : String?,
) -> (Int, Int) raise CliConfigError {
  match config.content_regex {
    None => (0, 0)
    Some(pattern) =>
      match source {
        None => (-1, 0)
        Some(source) => {
          let compiled = Regex(pattern[:]) catch {
            _ =>
              raise CliConfigError::InvalidRegex(
                path="$.grammars[].content-regex",
                pattern~,
              )
          }
          match compiled.execute(source[:]) {
            Some(result) => (1, result.content().length())
            None => (-1, 0)
          }
        }
      }
  }
}

///|
fn cli_config_content_score_is_better(
  rank : Int,
  length : Int,
  best_rank : Int,
  best_length : Int,
) -> Bool {
  rank > best_rank || (rank == best_rank && length > best_length)
}

///|
fn cli_select_language_config_for_file_with_optional_source(
  configs : Array[CliLanguageConfig],
  file_name : String,
  source : String?,
) -> CliLanguageConfig? raise CliConfigError {
  match source {
    Some(source) =>
      select_cli_language_config_for_file(configs, file_name, source~)
    None => select_cli_language_config_for_file(configs, file_name)
  }
}

///|
fn cli_language_location_configs(
  locations : Array[CliLanguageConfigLocation],
) -> Array[CliLanguageConfig] {
  let configs : Array[CliLanguageConfig] = []
  for location in locations {
    configs.push(location.config)
  }
  configs
}

///|
fn cli_language_location_for_config(
  locations : Array[CliLanguageConfigLocation],
  config : CliLanguageConfig,
) -> CliLanguageConfigLocation? {
  for location in locations {
    if location.config == config {
      return Some(location)
    }
  }
  None
}

///|
fn cli_config_first_line(source : String) -> String {
  let mut offset = 0
  while offset < source.length() {
    match source.get_char(offset) {
      Some('\n') =>
        return cli_config_strip_trailing_carriage_return(
          source[:offset].to_owned(),
        )
      Some(char) => offset += char.utf16_len()
      None => break
    }
  }
  cli_config_strip_trailing_carriage_return(source)
}

///|
fn cli_config_strip_trailing_carriage_return(line : String) -> String {
  match line.strip_suffix("\r") {
    Some(view) => view.to_owned()
    None => line
  }
}

///|
fn cli_config_push_joined_candidate(
  paths : Array[String],
  root : String,
  relative_path : String,
) -> Unit {
  if !root.is_empty() {
    cli_config_push_unique_path(paths, cli_query_join_path(root, relative_path))
  }
}

///|
fn cli_config_push_unique_path(paths : Array[String], path : String) -> Unit {
  for existing in paths {
    if existing == path {
      return
    }
  }
  paths.push(path)
}
