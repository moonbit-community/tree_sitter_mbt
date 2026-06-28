///|
pub(all) suberror CliFileIoError {
  FileReadFailed(path~ : String, reason~ : String)
  FileWriteFailed(path~ : String, reason~ : String)
  MissingInputPaths(String)
  MissingQueryPath
  UnsupportedFileInput(String)
  UnsupportedGrammarFileExtension(path~ : String)
  UnsupportedDynamicLanguage(path~ : String)
  GrammarJsLoadFailed(
    path~ : String,
    runtime~ : String,
    status~ : Int,
    stderr~ : String
  )
  MissingLanguageConfig(String)
  ConfigFailed(String)
  GenerateFailed(String)
  LanguageValidationFailed(String)
} derive(Eq, Debug)

///|
priv struct CliLoadedTagsConfiguration {
  language : @tree_sitter_mbt.Language
  tags_query : String
  locals_query : String
}

///|
fn render_cli_tags_error(error : @tags.TagsError) -> String {
  match error {
    @tags.TagsError::Cancelled(_) => "tags cancelled"
    @tags.TagsError::InvalidCaptureName(name) =>
      "invalid tags capture `\{name}`"
    @tags.TagsError::LanguageFailed(_) => "tags language failed"
    @tags.TagsError::ParseFailed(_) => "tags parse failed"
    @tags.TagsError::PredicateFailed(_) => "tags predicate failed"
    @tags.TagsError::QueryFailed(_) => "tags query failed"
  }
}

///|
fn render_cli_file_io_reason(error : Error) -> String {
  @debug.to_string(error)
}

///|
pub async fn read_cli_file_bytes(path : String) -> Bytes {
  @fs.read_file(path).binary() catch {
    err =>
      raise CliFileIoError::FileReadFailed(
        path~,
        reason=render_cli_file_io_reason(err),
      )
  }
}

///|
pub async fn read_cli_file_string(path : String) -> String {
  @fs.read_file(path).text() catch {
    err =>
      raise CliFileIoError::FileReadFailed(
        path~,
        reason=render_cli_file_io_reason(err),
      )
  }
}

///|
pub async fn write_cli_output_file(file : @cli.CliOutputFile) -> Unit {
  @fs.write_file(file.path, file.content, create_mode=CreateOrTruncate) catch {
    err =>
      raise CliFileIoError::FileWriteFailed(
        path=file.path,
        reason=render_cli_file_io_reason(err),
      )
  }
}

///|
pub async fn write_cli_output_files(files : Array[@cli.CliOutputFile]) -> Unit {
  for file in files {
    write_cli_output_file(file)
  }
}

///|
pub async fn read_cli_parse_command_sources(
  command : @cli.CliParseCommand,
) -> Array[@cli.CliParseCommandSource] {
  match command.test_number {
    Some(number) => {
      if command.paths_file is Some(_) {
        raise CliFileIoError::UnsupportedFileInput("--paths with --test-number")
      }
      if !command.paths.is_empty() {
        raise CliFileIoError::UnsupportedFileInput("paths with --test-number")
      }
      return read_cli_test_number_command_sources(number)
    }
    None => ()
  }
  match command.paths_file {
    Some(paths_file) =>
      read_cli_path_sources(
        @cli.parse_paths_file_contents(read_cli_file_string(paths_file)),
        "parse",
      )
    None =>
      if command.paths.is_empty() {
        read_cli_stdin_source()
      } else {
        read_cli_path_sources(command.paths, "parse")
      }
  }
}

///|
pub async fn read_cli_query_command_sources(
  command : @cli.CliQueryCommand,
) -> Array[@cli.CliParseCommandSource] {
  match command.test_number {
    Some(number) => {
      if !command.source_paths.is_empty() {
        raise CliFileIoError::UnsupportedFileInput("paths with --test-number")
      }
      return read_cli_test_number_command_sources(number)
    }
    None => ()
  }
  if command.source_paths.is_empty() {
    read_cli_stdin_source()
  } else {
    read_cli_path_sources(command.source_paths, "query")
  }
}

///|
pub async fn read_cli_tags_command_sources(
  command : @cli.CliTagsCommand,
) -> Array[@cli.CliParseCommandSource] {
  match command.test_number {
    Some(number) => {
      if command.paths_file is Some(_) {
        raise CliFileIoError::UnsupportedFileInput("--paths with --test-number")
      }
      if !command.paths.is_empty() {
        raise CliFileIoError::UnsupportedFileInput("paths with --test-number")
      }
      return read_cli_test_number_command_sources(number)
    }
    None => ()
  }
  match command.paths_file {
    Some(paths_file) =>
      read_cli_path_sources(
        @cli.parse_paths_file_contents(read_cli_file_string(paths_file)),
        "tags",
      )
    None =>
      if command.paths.is_empty() {
        read_cli_stdin_source()
      } else {
        read_cli_path_sources(command.paths, "tags")
      }
  }
}

///|
pub async fn read_cli_query_command_file(
  command : @cli.CliQueryCommand,
) -> String {
  match command.query_path {
    Some(path) => read_cli_file_string(path)
    None => raise CliFileIoError::MissingQueryPath
  }
}

///|
pub async fn read_cli_query_files(
  paths : Array[String],
) -> Array[@cli.CliQueryFile] {
  let files : Array[@cli.CliQueryFile] = []
  for path in paths {
    files.push({ path, content: read_cli_file_string(path) })
  }
  files
}

///|
pub async fn read_cli_combined_query(
  paths : Array[String],
) -> @cli.CliCombinedQuery {
  @cli.combine_cli_query_files(read_cli_query_files(paths))
}

///|
pub async fn read_cli_global_config_file(path : String) -> @cli.CliGlobalConfig {
  @cli.parse_cli_global_config_json(read_cli_file_string(path))
}

///|
pub async fn read_cli_optional_global_config_file(
  path : String?,
) -> @cli.CliGlobalConfig? {
  match path {
    Some(path) => Some(read_cli_global_config_file(path))
    None => None
  }
}

///|
pub fn cli_global_config_path_candidates(
  explicit_path : String?,
) -> Array[String] {
  @cli.cli_global_config_path_candidates_for_environment(explicit_path, {
    tree_sitter_dir: @env.get_env_var("TREE_SITTER_DIR"),
    xdg_config_home: @env.get_env_var("XDG_CONFIG_HOME"),
    home: @env.get_env_var("HOME"),
  })
}

///|
pub async fn resolve_cli_global_config_path(explicit_path : String?) -> String? {
  match explicit_path {
    Some(path) => Some(path)
    None => {
      for path in cli_global_config_path_candidates(None) {
        if @fs.exists(path) {
          return Some(path)
        }
      }
      None
    }
  }
}

///|
pub async fn read_cli_discovered_global_config_file(
  explicit_path : String?,
) -> @cli.CliGlobalConfig? {
  match resolve_cli_global_config_path(explicit_path) {
    Some(path) => Some(read_cli_global_config_file(path))
    None => None
  }
}

///|
pub async fn read_cli_tree_sitter_config_file(
  path : String,
) -> @cli.CliTreeSitterConfig {
  @cli.parse_cli_tree_sitter_config_json(read_cli_file_string(path))
}

///|
pub async fn read_cli_tree_sitter_config_locations(
  parser_roots : Array[String],
) -> Array[@cli.CliLanguageConfigLocation] {
  let locations : Array[@cli.CliLanguageConfigLocation] = []
  for parser_root in parser_roots {
    let config = read_cli_tree_sitter_config_file(
      @cli.cli_tree_sitter_config_path(parser_root),
    )
    for location in @cli.locate_cli_language_configs(parser_root, config) {
      locations.push(location)
    }
  }
  locations
}

///|
pub async fn read_cli_language_from_grammar_path(
  grammar_path : String,
) -> @tree_sitter_mbt.Language {
  let grammar_json = read_cli_grammar_json_from_path(grammar_path)
  let generated = @generator.generate_language(grammar_json) catch {
    err => raise CliFileIoError::GenerateFailed(@debug.to_string(err))
  }
  @tree_sitter_mbt.language_from_generated_tables(generated.tables) catch {
    err => raise CliFileIoError::LanguageValidationFailed(@debug.to_string(err))
  }
}

///|
pub async fn read_cli_parse_command_language(
  command : @cli.CliParseCommand,
  sources : Array[@cli.CliParseCommandSource],
) -> @tree_sitter_mbt.Language {
  read_cli_command_language(
    config_path=command.config_path,
    grammar_path=command.grammar_path,
    lib_path=command.lib_path,
    scope=cli_command_effective_scope(
      command.scope,
      command.lang_name,
      cli_first_source_language_name(sources),
    ),
    file_name=cli_first_source_name(sources),
    source=cli_first_source_text(sources, command.encoding),
  )
}

///|
pub async fn read_cli_query_command_language(
  command : @cli.CliQueryCommand,
  sources : Array[@cli.CliParseCommandSource],
) -> @tree_sitter_mbt.Language {
  read_cli_command_language(
    config_path=command.config_path,
    grammar_path=command.grammar_path,
    lib_path=command.lib_path,
    scope=cli_command_effective_scope(
      command.scope,
      command.lang_name,
      cli_first_source_language_name(sources),
    ),
    file_name=cli_first_source_name(sources),
    source=cli_first_source_text(sources, command.encoding),
  )
}

///|
pub async fn read_cli_test_command_language(
  command : @cli.CliTestCommand,
) -> @tree_sitter_mbt.Language {
  read_cli_command_language(
    config_path=command.config_path,
    grammar_path=command.grammar_path,
    lib_path=command.lib_path,
    scope=cli_command_effective_scope(None, command.lang_name, None),
  )
}

///|
pub async fn read_cli_test_command_files(
  command : @cli.CliTestCommand,
  paths : Array[String],
) -> Array[@cli.CliTestCommandFile] {
  if paths.is_empty() {
    raise CliFileIoError::MissingInputPaths("test")
  }
  let files : Array[@cli.CliTestCommandFile] = []
  for path in paths {
    for corpus_path in cli_test_corpus_file_paths(path) {
      files.push({
        name: corpus_path,
        contents: read_cli_file_string(corpus_path),
        file_name: command.file_name,
        current_platform: None,
      })
    }
  }
  if files.is_empty() {
    raise CliFileIoError::MissingInputPaths("test")
  }
  files
}

///|
pub async fn run_cli_generate_command_files(
  command : @cli.CliGenerateCommand,
) -> @cli.CliGenerateRunResult {
  let grammar_path = command.grammar_path.unwrap_or(
    cli_default_generate_grammar_path(),
  )
  let emit_grammar_json = grammar_path.has_suffix(".js")
  let grammar_json = read_cli_grammar_json_from_path(
    grammar_path,
    js_runtime=command.js_runtime,
  )
  let semantic_version = read_cli_generate_command_semantic_version(
    grammar_path,
  )
  let result = @cli.run_cli_generate_command(
    command,
    grammar_json,
    semantic_version~,
    emit_grammar_json~,
  ) catch {
    err => raise CliFileIoError::GenerateFailed(@debug.to_string(err))
  }
  write_cli_output_files(result.files)
  result
}

///|
async fn cli_default_generate_grammar_path() -> String {
  if @fs.exists("grammar.js") {
    "grammar.js"
  } else {
    "grammar.json"
  }
}

///|
async fn read_cli_generate_command_semantic_version(
  grammar_path : String,
) -> @tables.LanguageMetadata {
  let config_path = cli_generate_tree_sitter_config_path(grammar_path)
  if @fs.exists(config_path) {
    @cli.parse_cli_tree_sitter_metadata_json(read_cli_file_string(config_path)) catch {
      err => raise CliFileIoError::ConfigFailed(err.to_string())
    }
  } else {
    @tables.LanguageMetadata::zero()
  }
}

///|
fn cli_generate_tree_sitter_config_path(grammar_path : String) -> String {
  cli_join_path(cli_dirname(grammar_path), "tree-sitter.json")
}

///|
pub async fn run_cli_parse_command_loaded_files(
  command : @cli.CliParseCommand,
) -> @cli.CliParseCommandRunResult {
  let sources = read_cli_parse_command_sources(command)
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(read_cli_parse_command_language(command, sources))
  @cli.run_cli_parse_command(command, parser, sources)
}

///|
pub async fn run_cli_parse_command_files(
  command : @cli.CliParseCommand,
  parser : @tree_sitter_mbt.Parser,
) -> @cli.CliParseCommandRunResult {
  @cli.run_cli_parse_command(
    command,
    parser,
    read_cli_parse_command_sources(command),
  )
}

///|
pub async fn run_cli_query_command_loaded_files(
  command : @cli.CliQueryCommand,
) -> @cli.CliQueryCommandRunResult {
  let sources = read_cli_query_command_sources(command)
  @cli.run_cli_query_command(
    command,
    read_cli_query_command_language(command, sources),
    read_cli_query_command_file(command),
    sources,
  )
}

///|
pub async fn run_cli_query_command_files(
  command : @cli.CliQueryCommand,
  language : @tree_sitter_mbt.Language,
) -> @cli.CliQueryCommandRunResult {
  @cli.run_cli_query_command(
    command,
    language,
    read_cli_query_command_file(command),
    read_cli_query_command_sources(command),
  )
}

///|
pub async fn run_cli_tags_command_loaded_files(
  command : @cli.CliTagsCommand,
) -> @cli.CliTagsCommandRunResult {
  let sources = read_cli_tags_command_sources(command)
  let loaded = read_cli_tags_command_configuration(command, sources)
  let config = @tags.TagsConfiguration::new(
    loaded.language,
    loaded.tags_query,
    locals_query=loaded.locals_query,
  ) catch {
    err => raise CliFileIoError::ConfigFailed(render_cli_tags_error(err))
  }
  @cli.run_cli_tags_command(command, config, sources)
}

///|
pub async fn run_cli_tags_command_files(
  command : @cli.CliTagsCommand,
  config : @tags.TagsConfiguration,
) -> @cli.CliTagsCommandRunResult {
  @cli.run_cli_tags_command(
    command,
    config,
    read_cli_tags_command_sources(command),
  )
}

///|
pub async fn run_cli_test_command_loaded_files(
  command : @cli.CliTestCommand,
) -> @cli.CliTestCommandRunResult {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(read_cli_test_command_language(command))
  run_cli_test_command_files(command, parser, cli_test_command_paths())
}

///|
pub async fn run_cli_test_command_files(
  command : @cli.CliTestCommand,
  parser : @tree_sitter_mbt.Parser,
  paths : Array[String],
) -> @cli.CliTestCommandRunResult {
  let result = @cli.run_cli_test_command(
    command,
    parser,
    read_cli_test_command_files(command, paths),
  )
  if command.update {
    for file in result.files {
      match file.update {
        Some(update) => write_cli_output_file(update)
        None => ()
      }
    }
  }
  result
}

///|
async fn read_cli_tags_command_configuration(
  command : @cli.CliTagsCommand,
  sources : Array[@cli.CliParseCommandSource],
) -> CliLoadedTagsConfiguration {
  let location = read_cli_tags_command_language_location(command, sources)
  let query_paths = @cli.resolve_cli_language_location_query_paths(location)
  if query_paths.tags.is_empty() {
    raise CliFileIoError::MissingLanguageConfig(
      "no tags query configured for selected language",
    )
  }
  let tags_query = read_cli_combined_query(query_paths.tags)
  let locals_query = read_cli_combined_query(query_paths.locals)
  let language = match command.grammar_path {
    Some(path) => read_cli_language_from_grammar_path(path)
    None => read_cli_language_from_config_location(location)
  }
  { language, tags_query: tags_query.source, locals_query: locals_query.source }
}

///|
async fn read_cli_tags_command_language_location(
  command : @cli.CliTagsCommand,
  sources : Array[@cli.CliParseCommandSource],
) -> @cli.CliLanguageConfigLocation {
  let locations = read_cli_language_config_locations(command.config_path)
  match
    select_cli_language_location_optional(
      locations,
      cli_command_effective_scope(
        command.scope,
        None,
        cli_first_source_language_name(sources),
      ),
      cli_first_source_name(sources),
      cli_first_source_text(sources, None),
    ) {
    Some(@cli.CliLocatedLanguageFromConfig(location, _)) => location
    Some(@cli.CliLocatedLanguageFromLibPath(path)) =>
      raise CliFileIoError::UnsupportedDynamicLanguage(path~)
    None =>
      raise CliFileIoError::MissingLanguageConfig(
        "no tags language selected; pass --scope or configure parser-directories",
      )
  }
}

///|
async fn read_cli_command_language(
  config_path~ : String?,
  grammar_path~ : String?,
  lib_path~ : String?,
  scope~ : String?,
  file_name? : String? = None,
  source? : String? = None,
) -> @tree_sitter_mbt.Language {
  match lib_path {
    Some(path) => raise CliFileIoError::UnsupportedDynamicLanguage(path~)
    None => ()
  }
  match grammar_path {
    Some(path) => read_cli_language_from_grammar_path(path)
    None => {
      let locations = read_cli_language_config_locations(config_path)
      match
        select_cli_language_location_optional(
          locations, scope, file_name, source,
        ) {
        Some(@cli.CliLocatedLanguageFromConfig(location, _)) =>
          read_cli_language_from_config_location(location)
        Some(@cli.CliLocatedLanguageFromLibPath(path)) =>
          raise CliFileIoError::UnsupportedDynamicLanguage(path~)
        None =>
          raise CliFileIoError::MissingLanguageConfig(
            "no grammar.json selected; pass --grammar-path or configure parser-directories",
          )
      }
    }
  }
}

///|
async fn read_cli_language_from_config_location(
  location : @cli.CliLanguageConfigLocation,
) -> @tree_sitter_mbt.Language {
  read_cli_language_from_grammar_path(
    resolve_cli_language_grammar_path(location),
  )
}

///|
async fn resolve_cli_language_grammar_path(
  location : @cli.CliLanguageConfigLocation,
) -> String {
  let grammar_json_path = @cli.resolve_cli_language_grammar_json_path(location)
  if @fs.exists(grammar_json_path) {
    grammar_json_path
  } else {
    let grammar_js_path = cli_join_path(
      cli_dirname(grammar_json_path),
      "grammar.js",
    )
    if @fs.exists(grammar_js_path) {
      grammar_js_path
    } else {
      grammar_json_path
    }
  }
}

///|
async fn read_cli_language_config_locations(
  config_path : String?,
) -> Array[@cli.CliLanguageConfigLocation] {
  let config = read_cli_discovered_global_config_file(config_path) catch {
    err => raise CliFileIoError::ConfigFailed(err.to_string())
  }
  match config {
    Some(config) =>
      read_cli_tree_sitter_config_locations(config.parser_directories) catch {
        err => raise CliFileIoError::ConfigFailed(err.to_string())
      }
    None => []
  }
}

///|
fn select_cli_language_location_optional(
  locations : Array[@cli.CliLanguageConfigLocation],
  scope : String?,
  file_name : String?,
  source : String?,
) -> @cli.CliLocatedLanguageSelection? raise CliFileIoError {
  select_cli_language_location_optional_inner(
    locations, scope, file_name, source,
  ) catch {
    err => raise CliFileIoError::ConfigFailed(@debug.to_string(err))
  }
}

///|
fn select_cli_language_location_optional_inner(
  locations : Array[@cli.CliLanguageConfigLocation],
  scope : String?,
  file_name : String?,
  source : String?,
) -> @cli.CliLocatedLanguageSelection? raise @cli.CliConfigError {
  match (scope, file_name, source) {
    (Some(scope), Some(file_name), Some(source)) =>
      @cli.select_cli_language_location(locations, scope~, file_name~, source~)
    (Some(scope), Some(file_name), None) =>
      @cli.select_cli_language_location(locations, scope~, file_name~)
    (Some(scope), None, Some(source)) =>
      @cli.select_cli_language_location(locations, scope~, source~)
    (Some(scope), None, None) =>
      @cli.select_cli_language_location(locations, scope~)
    (None, Some(file_name), Some(source)) =>
      @cli.select_cli_language_location(locations, file_name~, source~)
    (None, Some(file_name), None) =>
      @cli.select_cli_language_location(locations, file_name~)
    (None, None, Some(source)) =>
      @cli.select_cli_language_location(locations, source~)
    (None, None, None) => @cli.select_cli_language_location(locations)
  }
}

///|
fn cli_command_effective_scope(
  scope : String?,
  lang_name : String?,
  corpus_language_name : String?,
) -> String? {
  match scope {
    Some(_) => scope
    None =>
      match lang_name {
        Some(_) => lang_name
        None => corpus_language_name
      }
  }
}

///|
fn cli_first_source_name(
  sources : Array[@cli.CliParseCommandSource],
) -> String? {
  if sources.is_empty() {
    None
  } else {
    sources[0].name
  }
}

///|
fn cli_first_source_text(
  sources : Array[@cli.CliParseCommandSource],
  encoding : @api.InputEncoding?,
) -> String? {
  if sources.is_empty() {
    None
  } else {
    Some(cli_source_text(sources[0], encoding))
  }
}

///|
fn cli_first_source_language_name(
  sources : Array[@cli.CliParseCommandSource],
) -> String? {
  if sources.is_empty() {
    None
  } else {
    for language_name in sources[0].language_names {
      if !language_name.is_empty() {
        return Some(language_name)
      }
    }
    None
  }
}

///|
fn cli_source_text(
  source : @cli.CliParseCommandSource,
  encoding : @api.InputEncoding?,
) -> String {
  match encoding {
    Some(encoding) =>
      @cli.cli_input_from_bytes(source.contents, requested=encoding).source()
    None => @cli.cli_input_from_bytes(source.contents).source()
  }
}

///|
fn cli_test_command_paths() -> Array[String] {
  ["test/corpus"]
}

///|
async fn read_cli_test_number_command_sources(
  number : UInt,
) -> Array[@cli.CliParseCommandSource] {
  let example = read_cli_test_number_example(number)
  [
    {
      name: Some(example.name),
      contents: example.input,
      language_names: example.attributes.languages,
    },
  ]
}

///|
async fn read_cli_test_number_example(number : UInt) -> @cli.CliCorpusExample {
  let target = @cli.normalize_test_number(number)
  let mut current = 0U
  for path in cli_test_command_paths() {
    for corpus_path in cli_test_corpus_file_paths(path) {
      let corpus = @cli.parse_corpus_file_contents(
        corpus_path,
        read_cli_file_string(corpus_path),
      )
      for example in corpus.examples {
        current += 1
        if current == target {
          return example
        }
      }
    }
  }
  raise CliFileIoError::MissingInputPaths("test-number \{target}")
}

///|
async fn cli_test_corpus_file_paths(path : String) -> Array[String] {
  if @fs.exists(path) && cli_is_dir(path) {
    cli_collect_corpus_file_paths(path)
  } else {
    [path]
  }
}

///|
async fn cli_collect_corpus_file_paths(dir : String) -> Array[String] {
  let paths : Array[String] = []
  let entries = @fs.readdir(dir) catch {
    err =>
      raise CliFileIoError::FileReadFailed(
        path=dir,
        reason=render_cli_file_io_reason(err),
      )
  }
  entries.sort()
  for entry in entries {
    if cli_path_entry_is_hidden(entry) {
      continue
    }
    let path = cli_join_path(dir, entry)
    if cli_is_dir(path) {
      for nested in cli_collect_corpus_file_paths(path) {
        paths.push(nested)
      }
    } else {
      paths.push(path)
    }
  }
  paths
}

///|
fn cli_path_entry_is_hidden(path : String) -> Bool {
  path.has_prefix(".")
}

///|
async fn read_cli_path_sources(
  paths : Array[String],
  command_name : String,
) -> Array[@cli.CliParseCommandSource] {
  let paths = expand_cli_input_paths(paths, command_name)
  let sources : Array[@cli.CliParseCommandSource] = []
  for path in paths {
    sources.push({
      name: Some(path),
      contents: read_cli_file_bytes(path),
      language_names: [],
    })
  }
  sources
}

///|
fn read_cli_stdin_source() -> Array[@cli.CliParseCommandSource] {
  [{ name: None, contents: read_cli_stdin_bytes(), language_names: [] }]
}

///|
async fn expand_cli_input_paths(
  paths : Array[String],
  command_name : String,
) -> Array[String] {
  let expanded : Array[String] = []
  for path in paths {
    match path.strip_prefix("!") {
      Some(pattern) =>
        for excluded in expand_cli_positive_input_path(pattern.to_owned()) {
          remove_cli_input_path(expanded, excluded)
        }
      None =>
        for included in expand_cli_positive_input_path(path) {
          push_unique_cli_input_path(expanded, included)
        }
    }
  }
  if expanded.is_empty() {
    raise CliFileIoError::MissingInputPaths(command_name)
  }
  expanded
}

///|
async fn expand_cli_positive_input_path(path : String) -> Array[String] {
  if cli_path_has_glob(path) {
    let matches = expand_cli_glob_path(path)
    matches.sort()
    matches
  } else {
    [path]
  }
}

///|
async fn expand_cli_glob_path(pattern : String) -> Array[String] {
  let segments = cli_path_segments(pattern)
  expand_cli_glob_segments(
    if pattern.has_prefix("/") {
      "/"
    } else {
      ""
    },
    segments,
    0,
  )
}

///|
async fn expand_cli_glob_segments(
  prefix : String,
  segments : Array[String],
  index : Int,
) -> Array[String] {
  if index >= segments.length() {
    return if prefix.is_empty() { [] } else { [prefix] }
  }
  let segment = segments[index]
  let results : Array[String] = []
  if cli_path_segment_has_glob(segment) {
    let dir = if prefix.is_empty() { "." } else { prefix }
    let entries = @fs.readdir(dir) catch {
      err =>
        raise CliFileIoError::FileReadFailed(
          path=dir,
          reason=render_cli_file_io_reason(err),
        )
    }
    entries.sort()
    for entry in entries {
      if cli_glob_segment_matches(segment, entry) {
        let next = cli_join_path(prefix, entry)
        if index + 1 == segments.length() {
          results.push(next)
        } else if cli_is_dir(next) {
          for matched in expand_cli_glob_segments(next, segments, index + 1) {
            results.push(matched)
          }
        }
      }
    }
  } else {
    let next = cli_join_path(prefix, segment)
    if index + 1 == segments.length() {
      if @fs.exists(next) {
        results.push(next)
      }
    } else if cli_is_dir(next) {
      for matched in expand_cli_glob_segments(next, segments, index + 1) {
        results.push(matched)
      }
    }
  }
  results
}

///|
fn cli_path_segments(path : String) -> Array[String] {
  let segments : Array[String] = []
  for segment in path.split("/") {
    let segment = segment.to_owned()
    if !segment.is_empty() {
      segments.push(segment)
    }
  }
  segments
}

///|
fn cli_path_has_glob(path : String) -> Bool {
  path.find("*") is Some(_) || path.find("?") is Some(_)
}

///|
fn cli_path_segment_has_glob(segment : String) -> Bool {
  cli_path_has_glob(segment)
}

///|
fn cli_glob_segment_matches(pattern : String, text : String) -> Bool {
  cli_glob_segment_matches_at(pattern, 0, text, 0)
}

///|
fn cli_glob_segment_matches_at(
  pattern : String,
  pattern_offset : Int,
  text : String,
  text_offset : Int,
) -> Bool {
  if pattern_offset >= pattern.length() {
    return text_offset >= text.length()
  }
  match pattern.get_char(pattern_offset) {
    Some('*') => {
      let next_pattern_offset = pattern_offset + 1
      if cli_glob_segment_matches_at(
          pattern, next_pattern_offset, text, text_offset,
        ) {
        return true
      }
      let mut next_text_offset = text_offset
      while next_text_offset < text.length() {
        match text.get_char(next_text_offset) {
          Some(char) => {
            next_text_offset += char.utf16_len()
            if cli_glob_segment_matches_at(
                pattern, next_pattern_offset, text, next_text_offset,
              ) {
              return true
            }
          }
          None => return false
        }
      }
      false
    }
    Some('?') =>
      match text.get_char(text_offset) {
        Some(char) =>
          cli_glob_segment_matches_at(
            pattern,
            pattern_offset + 1,
            text,
            text_offset + char.utf16_len(),
          )
        None => false
      }
    Some(pattern_char) =>
      match text.get_char(text_offset) {
        Some(text_char) if text_char == pattern_char =>
          cli_glob_segment_matches_at(
            pattern,
            pattern_offset + pattern_char.utf16_len(),
            text,
            text_offset + text_char.utf16_len(),
          )
        _ => false
      }
    None => text_offset >= text.length()
  }
}

///|
fn cli_join_path(root : String, path : String) -> String {
  if root.is_empty() {
    path
  } else if root == "/" {
    "/" + path
  } else if root.has_suffix("/") {
    root + path
  } else {
    root + "/" + path
  }
}

///|
fn cli_dirname(path : String) -> String {
  let slash = path.rev_find("/")
  let backslash = path.rev_find("\\")
  let index = match (slash, backslash) {
    (Some(a), Some(b)) => if a > b { a } else { b }
    (Some(a), None) => a
    (None, Some(b)) => b
    (None, None) => -1
  }
  if index > 0 {
    path[:index].to_owned()
  } else if index == 0 {
    path[:1].to_owned()
  } else {
    ""
  }
}

///|
async fn cli_is_dir(path : String) -> Bool {
  (@fs.kind(path) is Directory) catch {
    err =>
      raise CliFileIoError::FileReadFailed(
        path~,
        reason=render_cli_file_io_reason(err),
      )
  }
}

///|
fn push_unique_cli_input_path(paths : Array[String], path : String) -> Unit {
  for existing in paths {
    if existing == path {
      return
    }
  }
  paths.push(path)
}

///|
fn remove_cli_input_path(paths : Array[String], path : String) -> Unit {
  let mut index = 0
  while index < paths.length() {
    if paths[index] == path {
      ignore(paths.remove(index))
    } else {
      index += 1
    }
  }
}
