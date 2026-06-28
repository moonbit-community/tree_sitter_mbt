///|
pub(all) struct CliQueryFilePathSet {
  highlights : Array[String]
  injections : Array[String]
  locals : Array[String]
  tags : Array[String]
  others : Array[String]
} derive(Eq, Debug)

///|
pub(all) struct CliQueryFile {
  path : String
  content : String
} derive(Eq, Debug)

///|
pub(all) struct CliQuerySourceRange {
  path : String
  start_byte : Int
  end_byte : Int
} derive(Eq, Debug)

///|
pub(all) struct CliCombinedQuery {
  source : String
  ranges : Array[CliQuerySourceRange]
} derive(Eq, Debug)

///|
pub(all) struct CliQueryFileOffset {
  path : String
  byte_offset : Int
} derive(Eq, Debug)

///|
pub fn classify_cli_query_file_paths(
  paths : Array[String],
) -> CliQueryFilePathSet {
  let set = cli_query_empty_path_set()
  for path in paths {
    match classify_cli_query_file_path(path) {
      CliQueryFileHighlights => set.highlights.push(path)
      CliQueryFileInjections => set.injections.push(path)
      CliQueryFileLocals => set.locals.push(path)
      CliQueryFileTags => set.tags.push(path)
      CliQueryFileOther => set.others.push(path)
    }
  }
  set
}

///|
pub fn resolve_cli_explicit_query_paths(
  paths : Array[String],
) -> CliQueryFilePathSet {
  classify_cli_query_file_paths(paths)
}

///|
pub fn resolve_cli_language_query_paths(
  grammar_root : String,
  config : CliLanguageConfig,
) -> CliQueryFilePathSet {
  {
    highlights: config.highlights.map(path => {
      cli_query_join_path(grammar_root, path)
    }),
    injections: config.injections.map(path => {
      cli_query_join_path(grammar_root, path)
    }),
    locals: config.locals.map(path => cli_query_join_path(grammar_root, path)),
    tags: config.tags.map(path => cli_query_join_path(grammar_root, path)),
    others: [],
  }
}

///|
pub fn resolve_cli_language_location_query_paths(
  location : CliLanguageConfigLocation,
) -> CliQueryFilePathSet {
  resolve_cli_language_query_paths(location.grammar_root, location.config)
}

///|
pub fn resolve_cli_language_grammar_json_path(
  location : CliLanguageConfigLocation,
) -> String {
  cli_query_join_path(location.grammar_root, "grammar.json")
}

///|
pub fn combine_cli_query_files(files : Array[CliQueryFile]) -> CliCombinedQuery {
  let source = StringBuilder::new()
  let ranges : Array[CliQuerySourceRange] = []
  let mut start_byte = 0
  for file in files {
    let content_length = @utf8.encode(file.content).length()
    let end_byte = start_byte + content_length
    ranges.push({ path: file.path, start_byte, end_byte })
    source.write_string(file.content)
    start_byte = end_byte
  }
  { source: source.to_string(), ranges }
}

///|
pub fn cli_query_range_for_byte_offset(
  combined : CliCombinedQuery,
  byte_offset : Int,
) -> CliQuerySourceRange? {
  if byte_offset < 0 {
    None
  } else {
    let mut found : CliQuerySourceRange? = None
    let mut last : CliQuerySourceRange? = None
    for range in combined.ranges {
      if found is None &&
        byte_offset >= range.start_byte &&
        byte_offset < range.end_byte {
        found = Some(range)
      }
      last = Some(range)
    }
    match found {
      Some(_) => found
      None =>
        match last {
          Some(range) =>
            if byte_offset == range.end_byte {
              Some(range)
            } else {
              None
            }
          None => None
        }
    }
  }
}

///|
pub fn cli_query_file_offset(
  combined : CliCombinedQuery,
  byte_offset : Int,
) -> CliQueryFileOffset? {
  match cli_query_range_for_byte_offset(combined, byte_offset) {
    Some(range) =>
      Some({ path: range.path, byte_offset: byte_offset - range.start_byte })
    None => None
  }
}

///|
pub fn cli_query_error_byte_offset(error : @query.QueryError) -> Int {
  match error {
    @query.QueryError::Syntax(byte_offset~, ..) => byte_offset
    @query.QueryError::NodeType(byte_offset~, ..) => byte_offset
    @query.QueryError::Field(byte_offset~, ..) => byte_offset
    @query.QueryError::Capture(byte_offset~, ..) => byte_offset
    @query.QueryError::Structure(byte_offset~, ..) => byte_offset
  }
}

///|
pub fn cli_query_error_file_offset(
  combined : CliCombinedQuery,
  error : @query.QueryError,
) -> CliQueryFileOffset? {
  cli_query_file_offset(combined, cli_query_error_byte_offset(error))
}

///|
fn cli_query_empty_path_set() -> CliQueryFilePathSet {
  { highlights: [], injections: [], locals: [], tags: [], others: [] }
}

///|
fn cli_query_join_path(root : String, path : String) -> String {
  if root.is_empty() || root == "." || cli_query_path_is_absolute(path) {
    path
  } else if path.is_empty() {
    root
  } else if root.has_suffix("/") || root.has_suffix("\\") {
    root + path
  } else {
    root + "/" + path
  }
}

///|
fn cli_query_path_is_absolute(path : String) -> Bool {
  path.has_prefix("/") || path.has_prefix("\\")
}
