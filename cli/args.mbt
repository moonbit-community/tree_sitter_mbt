///|
pub(all) suberror CliArgsError {
  MissingCommand
  UnknownCommand(String)
  UnknownOption(String)
  MissingOptionValue(String)
  InvalidOptionValue(option~ : String, value~ : String)
  ConflictingOptions(String, String)
  UnexpectedArgument(String)
} derive(Eq, Debug)

///|
pub(all) enum CliCommand {
  CliParse(CliParseCommand)
  CliTest(CliTestCommand)
  CliGenerate(CliGenerateCommand)
  CliQuery(CliQueryCommand)
  CliTags(CliTagsCommand)
} derive(Eq, Debug)

///|
pub(all) struct CliByteRange {
  start : UInt
  end : UInt
} derive(Eq, Debug)

///|
pub(all) enum CliQueryOutputMode {
  CliQueryCaptures
  CliQueryMatches
} derive(Eq, Debug)

///|
pub(all) enum CliTestStatsMode {
  CliTestStatsAll
  CliTestStatsOutliersAndTotal
  CliTestStatsTotalOnly
} derive(Eq, Debug)

///|
pub(all) struct CliParseCommand {
  paths_file : String?
  paths : Array[String]
  config_path : String?
  grammar_path : String?
  lib_path : String?
  lang_name : String?
  scope : String?
  output : CliParseOutputMode
  no_ranges : Bool
  time : Bool
  encoding : @api.InputEncoding?
  test_number : UInt?
  rebuild : Bool
} derive(Eq, Debug)

///|
pub(all) struct CliTestCommand {
  include_pattern : String?
  exclude_pattern : String?
  file_name : String?
  config_path : String?
  grammar_path : String?
  lib_path : String?
  lang_name : String?
  update : Bool
  show_fields : Bool
  rebuild : Bool
  overview_only : Bool
  json_summary : Bool
  stats : CliTestStatsMode?
} derive(Eq, Debug)

///|
pub(all) struct CliGenerateCommand {
  grammar_path : String?
  output_dir : String?
  abi_version : String?
  js_runtime : String?
  log : Bool
  no_parser : Bool
  report_states_for_rule : String?
  json_summary : Bool
  disable_optimizations : Bool
} derive(Eq, Debug)

///|
pub(all) struct CliQueryCommand {
  query_path : String?
  source_paths : Array[String]
  config_path : String?
  grammar_path : String?
  lib_path : String?
  lang_name : String?
  scope : String?
  encoding : @api.InputEncoding?
  test_number : UInt?
  rebuild : Bool
  output : CliQueryOutputMode
  byte_range : CliByteRange?
  containing_byte_range : CliByteRange?
  test_mode : Bool
} derive(Eq, Debug)

///|
pub(all) struct CliTagsCommand {
  paths_file : String?
  paths : Array[String]
  config_path : String?
  grammar_path : String?
  scope : String?
  time : Bool
  quiet : Bool
  test_number : UInt?
  rebuild : Bool
} derive(Eq, Debug)

///|
pub fn parse_cli_command_args(
  args : Array[String],
) -> CliCommand raise CliArgsError {
  if args.is_empty() {
    raise CliArgsError::MissingCommand
  }
  match args[0] {
    "parse" | "p" => CliParse(parse_cli_parse_command_args(args[1:]))
    "test" | "t" => CliTest(parse_cli_test_command_args(args[1:]))
    "generate" | "gen" | "g" =>
      CliGenerate(parse_cli_generate_command_args(args[1:]))
    "query" | "q" => CliQuery(parse_cli_query_command_args(args[1:]))
    "tags" => CliTags(parse_cli_tags_command_args(args[1:]))
    command => raise CliArgsError::UnknownCommand(command)
  }
}

///|
fn parse_cli_parse_command_args(
  args : ArrayView[String],
) -> CliParseCommand raise CliArgsError {
  let paths : Array[String] = []
  let mut paths_file : String? = None
  let mut config_path : String? = None
  let mut grammar_path : String? = None
  let mut lib_path : String? = None
  let mut lang_name : String? = None
  let mut scope : String? = None
  let mut output = CliParseNormal
  let mut no_ranges = false
  let mut time = false
  let mut encoding : @api.InputEncoding? = None
  let mut test_number : UInt? = None
  let mut rebuild = false
  let mut positional_mode = false
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if positional_mode {
      paths.push(arg)
      i += 1
      continue
    }
    if arg == "--" {
      positional_mode = true
      i += 1
      continue
    }
    match cli_long_option(arg) {
      Some((name, inline_value)) =>
        match name {
          "paths" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            paths_file = Some(value)
            i = consumed + 1
          }
          "config-path" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            config_path = Some(value)
            i = consumed + 1
          }
          "grammar-path" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            grammar_path = Some(value)
            i = consumed + 1
          }
          "lib-path" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            lib_path = Some(value)
            i = consumed + 1
          }
          "lang-name" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            lang_name = Some(value)
            i = consumed + 1
          }
          "scope" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            scope = Some(value)
            i = consumed + 1
          }
          "encoding" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            encoding = Some(cli_parse_encoding_option(arg, value))
            i = consumed + 1
          }
          "test-number" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            test_number = Some(cli_parse_uint_option(arg, value))
            i = consumed + 1
          }
          "no-ranges" => {
            cli_reject_inline_value(arg, inline_value)
            no_ranges = true
            i += 1
          }
          "time" => {
            cli_reject_inline_value(arg, inline_value)
            time = true
            i += 1
          }
          "cst" => {
            cli_reject_inline_value(arg, inline_value)
            if !(output is CliParseQuiet) {
              output = CliParseCst
            }
            i += 1
          }
          "quiet" => {
            cli_reject_inline_value(arg, inline_value)
            output = CliParseQuiet
            i += 1
          }
          "rebuild" => {
            cli_reject_inline_value(arg, inline_value)
            rebuild = true
            i += 1
          }
          _ => raise CliArgsError::UnknownOption(arg)
        }
      None =>
        match arg {
          "-c" => {
            if !(output is CliParseQuiet) {
              output = CliParseCst
            }
            i += 1
          }
          "-q" => {
            output = CliParseQuiet
            i += 1
          }
          "-t" => {
            time = true
            i += 1
          }
          "-n" => {
            let (value, consumed) = cli_option_value(args, i, arg, None)
            test_number = Some(cli_parse_uint_option(arg, value))
            i = consumed + 1
          }
          "-p" => {
            let (value, consumed) = cli_option_value(args, i, arg, None)
            grammar_path = Some(value)
            i = consumed + 1
          }
          "-l" => {
            let (value, consumed) = cli_option_value(args, i, arg, None)
            lib_path = Some(value)
            i = consumed + 1
          }
          "-r" => {
            rebuild = true
            i += 1
          }
          _ =>
            if arg.has_prefix("-") {
              raise CliArgsError::UnknownOption(arg)
            } else {
              paths.push(arg)
              i += 1
            }
        }
    }
  }
  if paths_file is Some(_) && !paths.is_empty() {
    raise CliArgsError::ConflictingOptions("--paths", "paths")
  }
  if test_number is Some(_) {
    if paths_file is Some(_) {
      raise CliArgsError::ConflictingOptions("--test-number", "--paths")
    }
    if !paths.is_empty() {
      raise CliArgsError::ConflictingOptions("--test-number", "paths")
    }
  }
  {
    paths_file,
    paths,
    config_path,
    grammar_path,
    lib_path,
    lang_name,
    scope,
    output,
    no_ranges,
    time,
    encoding,
    test_number,
    rebuild,
  }
}

///|
fn parse_cli_test_command_args(
  args : ArrayView[String],
) -> CliTestCommand raise CliArgsError {
  let mut include_pattern : String? = None
  let mut exclude_pattern : String? = None
  let mut file_name : String? = None
  let mut config_path : String? = None
  let mut grammar_path : String? = None
  let mut lib_path : String? = None
  let mut lang_name : String? = None
  let mut update = false
  let mut show_fields = false
  let mut rebuild = false
  let mut overview_only = false
  let mut json_summary = false
  let mut stats : CliTestStatsMode? = None
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    match cli_long_option(arg) {
      Some((name, inline_value)) =>
        match name {
          "include" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            include_pattern = Some(value)
            i = consumed + 1
          }
          "exclude" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            exclude_pattern = Some(value)
            i = consumed + 1
          }
          "file-name" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            file_name = Some(value)
            i = consumed + 1
          }
          "config-path" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            config_path = Some(value)
            i = consumed + 1
          }
          "grammar-path" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            grammar_path = Some(value)
            i = consumed + 1
          }
          "lib-path" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            lib_path = Some(value)
            i = consumed + 1
          }
          "lang-name" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            lang_name = Some(value)
            i = consumed + 1
          }
          "update" => {
            cli_reject_inline_value(arg, inline_value)
            update = true
            i += 1
          }
          "show-fields" => {
            cli_reject_inline_value(arg, inline_value)
            show_fields = true
            i += 1
          }
          "rebuild" => {
            cli_reject_inline_value(arg, inline_value)
            rebuild = true
            i += 1
          }
          "overview-only" => {
            cli_reject_inline_value(arg, inline_value)
            overview_only = true
            i += 1
          }
          "json-summary" | "json" => {
            cli_reject_inline_value(arg, inline_value)
            json_summary = true
            i += 1
          }
          "stat" => {
            let (mode, consumed) = cli_optional_stats_value(
              args, i, inline_value,
            )
            stats = Some(mode)
            i = consumed + 1
          }
          _ => raise CliArgsError::UnknownOption(arg)
        }
      None =>
        match arg {
          "-i" => {
            let (value, consumed) = cli_option_value(args, i, arg, None)
            include_pattern = Some(value)
            i = consumed + 1
          }
          "-e" => {
            let (value, consumed) = cli_option_value(args, i, arg, None)
            exclude_pattern = Some(value)
            i = consumed + 1
          }
          "-p" => {
            let (value, consumed) = cli_option_value(args, i, arg, None)
            grammar_path = Some(value)
            i = consumed + 1
          }
          "-l" => {
            let (value, consumed) = cli_option_value(args, i, arg, None)
            lib_path = Some(value)
            i = consumed + 1
          }
          "-u" => {
            update = true
            i += 1
          }
          "-r" => {
            rebuild = true
            i += 1
          }
          _ =>
            if arg.has_prefix("-") {
              raise CliArgsError::UnknownOption(arg)
            } else {
              raise CliArgsError::UnexpectedArgument(arg)
            }
        }
    }
  }
  {
    include_pattern,
    exclude_pattern,
    file_name,
    config_path,
    grammar_path,
    lib_path,
    lang_name,
    update,
    show_fields,
    rebuild,
    overview_only,
    json_summary,
    stats,
  }
}

///|
fn parse_cli_generate_command_args(
  args : ArrayView[String],
) -> CliGenerateCommand raise CliArgsError {
  let mut grammar_path : String? = None
  let mut output_dir : String? = None
  let mut abi_version : String? = None
  let mut js_runtime : String? = None
  let mut log = false
  let mut no_parser = false
  let mut report_states_for_rule : String? = None
  let mut json_summary = false
  let mut disable_optimizations = false
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    match cli_long_option(arg) {
      Some((name, inline_value)) =>
        match name {
          "output" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            output_dir = Some(value)
            i = consumed + 1
          }
          "abi" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            abi_version = Some(value)
            i = consumed + 1
          }
          "js-runtime" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            js_runtime = Some(value)
            i = consumed + 1
          }
          "report-states-for-rule" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            report_states_for_rule = Some(value)
            i = consumed + 1
          }
          "log" => {
            cli_reject_inline_value(arg, inline_value)
            log = true
            i += 1
          }
          "no-parser" => {
            cli_reject_inline_value(arg, inline_value)
            no_parser = true
            i += 1
          }
          "json-summary" | "json" => {
            cli_reject_inline_value(arg, inline_value)
            json_summary = true
            i += 1
          }
          "disable-optimizations" => {
            cli_reject_inline_value(arg, inline_value)
            disable_optimizations = true
            i += 1
          }
          _ => raise CliArgsError::UnknownOption(arg)
        }
      None =>
        match arg {
          "-o" => {
            let (value, consumed) = cli_option_value(args, i, arg, None)
            output_dir = Some(value)
            i = consumed + 1
          }
          "-l" => {
            log = true
            i += 1
          }
          _ =>
            if arg.has_prefix("-") {
              raise CliArgsError::UnknownOption(arg)
            } else if grammar_path is None {
              grammar_path = Some(arg)
              i += 1
            } else {
              raise CliArgsError::UnexpectedArgument(arg)
            }
        }
    }
  }
  {
    grammar_path,
    output_dir,
    abi_version,
    js_runtime,
    log,
    no_parser,
    report_states_for_rule,
    json_summary,
    disable_optimizations,
  }
}

///|
fn parse_cli_query_command_args(
  args : ArrayView[String],
) -> CliQueryCommand raise CliArgsError {
  let source_paths : Array[String] = []
  let mut query_path : String? = None
  let mut config_path : String? = None
  let mut grammar_path : String? = None
  let mut lib_path : String? = None
  let mut lang_name : String? = None
  let mut scope : String? = None
  let mut encoding : @api.InputEncoding? = None
  let mut test_number : UInt? = None
  let mut rebuild = false
  let mut output = CliQueryCaptures
  let mut byte_range : CliByteRange? = None
  let mut containing_byte_range : CliByteRange? = None
  let mut test_mode = false
  let mut positional_mode = false
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if positional_mode {
      query_path = cli_query_push_positional(arg, query_path, source_paths)
      i += 1
      continue
    }
    if arg == "--" {
      positional_mode = true
      i += 1
      continue
    }
    match cli_long_option(arg) {
      Some((name, inline_value)) =>
        match name {
          "config-path" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            config_path = Some(value)
            i = consumed + 1
          }
          "grammar-path" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            grammar_path = Some(value)
            i = consumed + 1
          }
          "lib-path" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            lib_path = Some(value)
            i = consumed + 1
          }
          "lang-name" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            lang_name = Some(value)
            i = consumed + 1
          }
          "scope" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            scope = Some(value)
            i = consumed + 1
          }
          "encoding" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            encoding = Some(cli_parse_encoding_option(arg, value))
            i = consumed + 1
          }
          "test-number" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            test_number = Some(cli_parse_uint_option(arg, value))
            i = consumed + 1
          }
          "captures" => {
            cli_reject_inline_value(arg, inline_value)
            output = CliQueryCaptures
            i += 1
          }
          "matches" => {
            cli_reject_inline_value(arg, inline_value)
            output = CliQueryMatches
            i += 1
          }
          "byte-range" | "range" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            byte_range = Some(cli_parse_byte_range_option(arg, value))
            i = consumed + 1
          }
          "containing-byte-range" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            containing_byte_range = Some(
              cli_parse_byte_range_option(arg, value),
            )
            i = consumed + 1
          }
          "test" => {
            cli_reject_inline_value(arg, inline_value)
            test_mode = true
            i += 1
          }
          "rebuild" => {
            cli_reject_inline_value(arg, inline_value)
            rebuild = true
            i += 1
          }
          _ => raise CliArgsError::UnknownOption(arg)
        }
      None =>
        match arg {
          "-c" => {
            output = CliQueryCaptures
            i += 1
          }
          "-m" => {
            output = CliQueryMatches
            i += 1
          }
          "-p" => {
            let (value, consumed) = cli_option_value(args, i, arg, None)
            grammar_path = Some(value)
            i = consumed + 1
          }
          "-l" => {
            let (value, consumed) = cli_option_value(args, i, arg, None)
            lib_path = Some(value)
            i = consumed + 1
          }
          "-n" => {
            let (value, consumed) = cli_option_value(args, i, arg, None)
            test_number = Some(cli_parse_uint_option(arg, value))
            i = consumed + 1
          }
          "-r" => {
            rebuild = true
            i += 1
          }
          _ =>
            if arg.has_prefix("-") {
              raise CliArgsError::UnknownOption(arg)
            } else {
              query_path = cli_query_push_positional(
                arg, query_path, source_paths,
              )
              i += 1
            }
        }
    }
  }
  if test_number is Some(_) && !source_paths.is_empty() {
    raise CliArgsError::ConflictingOptions("--test-number", "paths")
  }
  {
    query_path,
    source_paths,
    config_path,
    grammar_path,
    lib_path,
    lang_name,
    scope,
    encoding,
    test_number,
    rebuild,
    output,
    byte_range,
    containing_byte_range,
    test_mode,
  }
}

///|
fn parse_cli_tags_command_args(
  args : ArrayView[String],
) -> CliTagsCommand raise CliArgsError {
  let paths : Array[String] = []
  let mut paths_file : String? = None
  let mut config_path : String? = None
  let mut grammar_path : String? = None
  let mut scope : String? = None
  let mut time = false
  let mut quiet = false
  let mut test_number : UInt? = None
  let mut rebuild = false
  let mut positional_mode = false
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    if positional_mode {
      paths.push(arg)
      i += 1
      continue
    }
    if arg == "--" {
      positional_mode = true
      i += 1
      continue
    }
    match cli_long_option(arg) {
      Some((name, inline_value)) =>
        match name {
          "paths" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            paths_file = Some(value)
            i = consumed + 1
          }
          "config-path" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            config_path = Some(value)
            i = consumed + 1
          }
          "grammar-path" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            grammar_path = Some(value)
            i = consumed + 1
          }
          "scope" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            scope = Some(value)
            i = consumed + 1
          }
          "test-number" => {
            let (value, consumed) = cli_option_value(args, i, arg, inline_value)
            test_number = Some(cli_parse_uint_option(arg, value))
            i = consumed + 1
          }
          "time" => {
            cli_reject_inline_value(arg, inline_value)
            time = true
            i += 1
          }
          "quiet" => {
            cli_reject_inline_value(arg, inline_value)
            quiet = true
            i += 1
          }
          "rebuild" => {
            cli_reject_inline_value(arg, inline_value)
            rebuild = true
            i += 1
          }
          _ => raise CliArgsError::UnknownOption(arg)
        }
      None =>
        match arg {
          "-t" => {
            time = true
            i += 1
          }
          "-q" => {
            quiet = true
            i += 1
          }
          "-p" => {
            let (value, consumed) = cli_option_value(args, i, arg, None)
            grammar_path = Some(value)
            i = consumed + 1
          }
          "-n" => {
            let (value, consumed) = cli_option_value(args, i, arg, None)
            test_number = Some(cli_parse_uint_option(arg, value))
            i = consumed + 1
          }
          "-r" => {
            rebuild = true
            i += 1
          }
          _ =>
            if arg.has_prefix("-") {
              raise CliArgsError::UnknownOption(arg)
            } else {
              paths.push(arg)
              i += 1
            }
        }
    }
  }
  if paths_file is Some(_) && !paths.is_empty() {
    raise CliArgsError::ConflictingOptions("--paths", "paths")
  }
  if test_number is Some(_) {
    if paths_file is Some(_) {
      raise CliArgsError::ConflictingOptions("--test-number", "--paths")
    }
    if !paths.is_empty() {
      raise CliArgsError::ConflictingOptions("--test-number", "paths")
    }
  }
  {
    paths_file,
    paths,
    config_path,
    grammar_path,
    scope,
    time,
    quiet,
    test_number,
    rebuild,
  }
}

///|
fn cli_query_push_positional(
  arg : String,
  query_path : String?,
  source_paths : Array[String],
) -> String? {
  match query_path {
    Some(_) => {
      source_paths.push(arg)
      query_path
    }
    None => Some(arg)
  }
}

///|
fn cli_long_option(arg : String) -> (String, String?)? {
  if !arg.has_prefix("--") || arg == "--" {
    return None
  }
  let mut offset = 2
  while offset < arg.length() {
    match arg.get_char(offset) {
      Some('=') =>
        return Some(
          (arg[2:offset].to_owned(), Some(arg[offset + 1:].to_owned())),
        )
      Some(char) => offset += char.utf16_len()
      None => break
    }
  }
  Some((arg[2:].to_owned(), None))
}

///|
fn cli_option_value(
  args : ArrayView[String],
  index : Int,
  option : String,
  inline_value : String?,
) -> (String, Int) raise CliArgsError {
  match inline_value {
    Some(value) => (value, index)
    None =>
      if index + 1 < args.length() {
        (args[index + 1], index + 1)
      } else {
        raise CliArgsError::MissingOptionValue(option)
      }
  }
}

///|
fn cli_reject_inline_value(
  option : String,
  inline_value : String?,
) -> Unit raise CliArgsError {
  match inline_value {
    Some(value) => raise CliArgsError::InvalidOptionValue(option~, value~)
    None => ()
  }
}

///|
fn cli_parse_encoding_option(
  option : String,
  value : String,
) -> @api.InputEncoding raise CliArgsError {
  parse_cli_input_encoding(value) catch {
    UnknownEncoding(_) =>
      raise CliArgsError::InvalidOptionValue(option~, value~)
  }
}

///|
fn cli_parse_uint_option(
  option : String,
  value : String,
) -> UInt raise CliArgsError {
  if value.is_empty() {
    raise CliArgsError::InvalidOptionValue(option~, value~)
  }
  let mut result = 0U
  for char in value {
    let code = char.to_uint()
    if code < 48U || code > 57U {
      raise CliArgsError::InvalidOptionValue(option~, value~)
    }
    result = result * 10U + (code - 48U)
  }
  result
}

///|
fn cli_parse_byte_range_option(
  option : String,
  value : String,
) -> CliByteRange raise CliArgsError {
  match cli_split_once(value, ':') {
    Some((start, end)) => {
      let start = cli_parse_uint_option(option, start)
      let end = cli_parse_uint_option(option, end)
      if start > end {
        raise CliArgsError::InvalidOptionValue(option~, value~)
      }
      { start, end }
    }
    None => raise CliArgsError::InvalidOptionValue(option~, value~)
  }
}

///|
fn cli_split_once(value : String, needle : Char) -> (String, String)? {
  let mut offset = 0
  while offset < value.length() {
    match value.get_char(offset) {
      Some(char) if char == needle =>
        return Some(
          (
            value[:offset].to_owned(),
            value[offset + char.utf16_len():].to_owned(),
          ),
        )
      Some(char) => offset += char.utf16_len()
      None => break
    }
  }
  None
}

///|
fn cli_optional_stats_value(
  args : ArrayView[String],
  index : Int,
  inline_value : String?,
) -> (CliTestStatsMode, Int) raise CliArgsError {
  match inline_value {
    Some(value) => (cli_parse_stats_mode("--stat", value), index)
    None =>
      if index + 1 < args.length() && !args[index + 1].has_prefix("-") {
        (cli_parse_stats_mode("--stat", args[index + 1]), index + 1)
      } else {
        (CliTestStatsOutliersAndTotal, index)
      }
  }
}

///|
fn cli_parse_stats_mode(
  option : String,
  value : String,
) -> CliTestStatsMode raise CliArgsError {
  match value {
    "all" => CliTestStatsAll
    "outliers-and-total" => CliTestStatsOutliersAndTotal
    "total-only" => CliTestStatsTotalOnly
    _ => raise CliArgsError::InvalidOptionValue(option~, value~)
  }
}
