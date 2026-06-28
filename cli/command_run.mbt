///|
pub(all) struct CliParseCommandSource {
  name : String?
  contents : Bytes
  language_names : Array[String]
} derive(Eq, Debug)

///|
pub(all) struct CliParseCommandSourceResult {
  name : String?
  result : CliParseResult
} derive(Eq, Debug)

///|
pub(all) struct CliParseCommandRunResult {
  results : Array[CliParseCommandSourceResult]
  stdout : String
  exit_code : Int
} derive(Eq, Debug)

///|
pub(all) struct CliTestCommandFile {
  name : String
  contents : String
  file_name : String?
  current_platform : String?
} derive(Eq, Debug)

///|
pub(all) struct CliTestCommandFileResult {
  name : String
  results : Array[CliCorpusRunResult]
  update : CliOutputFile?
} derive(Eq, Debug)

///|
pub(all) struct CliTestRunSummary {
  total : Int
  passed : Int
  failed : Int
  skipped : Int
  platform_skipped : Int
} derive(Eq, Debug)

///|
pub(all) struct CliTestCommandRunResult {
  files : Array[CliTestCommandFileResult]
  summary : CliTestRunSummary
  stdout : String
  json_summary : String?
  exit_code : Int
} derive(Eq, Debug)

///|
pub(all) suberror CliQueryRunError {
  LanguageFailed(@tree_sitter_mbt.LanguageError)
  ParseFailed(@tree_sitter_mbt.ParseError)
  QueryFailed(@query.QueryError)
  PredicateFailed(@query.QueryPredicateError)
  InvalidRange(String)
}

///|
pub(all) struct CliQueryCommandSourceResult {
  name : String?
  output : String
  match_count : Int
  capture_count : Int
  has_parse_error : Bool
  successful : Bool
} derive(Eq, Debug)

///|
pub(all) struct CliQueryCommandRunResult {
  results : Array[CliQueryCommandSourceResult]
  stdout : String
  exit_code : Int
} derive(Eq, Debug)

///|
pub fn run_cli_parse_command(
  command : CliParseCommand,
  parser : @tree_sitter_mbt.Parser,
  sources : Array[CliParseCommandSource],
) -> CliParseCommandRunResult raise {
  let results : Array[CliParseCommandSourceResult] = []
  let parse_results : Array[CliParseResult] = []
  let stdout = StringBuilder::new()
  for source in sources {
    let start_time = if command.time { Some(@env.now()) } else { None }
    let result = run_cli_parse_source_for_command(
      command,
      parser,
      source.contents,
    )
    write_cli_parse_command_result_output(
      stdout,
      source.name,
      result,
      duration_millis=cli_parse_elapsed_millis(start_time),
    )
    parse_results.push(result)
    results.push({ name: source.name, result })
  }
  {
    results,
    stdout: stdout.to_string(),
    exit_code: cli_parse_exit_code(parse_results),
  }
}

///|
pub fn run_cli_query_command(
  command : CliQueryCommand,
  language : @tree_sitter_mbt.Language,
  query_source : String,
  sources : Array[CliParseCommandSource],
) -> CliQueryCommandRunResult raise CliQueryRunError {
  let compiled = @query.Query::new(language, query_source) catch {
    err => raise CliQueryRunError::QueryFailed(err)
  }
  let results : Array[CliQueryCommandSourceResult] = []
  let stdout = StringBuilder::new()
  let mut exit_code = 0
  for source in sources {
    let result = run_cli_query_source(command, language, compiled, source)
    if !result.successful {
      exit_code = 1
    }
    if !result.output.is_empty() {
      stdout.write_string(result.output)
      if !result.output.has_suffix("\n") {
        stdout.write_char('\n')
      }
    }
    results.push(result)
  }
  { results, stdout: stdout.to_string(), exit_code }
}

///|
pub fn run_cli_test_command(
  command : CliTestCommand,
  parser : @tree_sitter_mbt.Parser,
  files : Array[CliTestCommandFile],
) -> CliTestCommandRunResult raise {
  let file_results : Array[CliTestCommandFileResult] = []
  let all_results : Array[CliCorpusRunResult] = []
  let mut update_blocked = false
  for input_file in files {
    let corpus = parse_cli_test_command_file(input_file)
    if command.update {
      let update_plan = plan_cli_corpus_update_for_command(
        command, parser, corpus,
      )
      for result in update_plan.results {
        all_results.push(result)
      }
      if !update_plan.can_update {
        update_blocked = true
      }
      file_results.push({
        name: input_file.name,
        results: update_plan.results,
        update: if update_plan.can_update {
          Some({
            path: input_file.name,
            content: render_cli_corpus_corrections(update_plan.corrections),
          })
        } else {
          None
        },
      })
    } else {
      let results = run_cli_corpus_file_for_command(command, parser, corpus)
      for result in results {
        all_results.push(result)
      }
      file_results.push({ name: input_file.name, results, update: None })
    }
  }
  let summary = summarize_cli_test_results(all_results)
  let json_summary = if command.json_summary {
    Some(render_cli_test_json_summary(summary))
  } else {
    None
  }
  let stdout = if command.json_summary {
    json_summary.unwrap()
  } else {
    render_cli_test_summary_for_command(summary, command)
  }
  {
    files: file_results,
    summary,
    stdout,
    json_summary,
    exit_code: if summary.failed > 0 || update_blocked {
      1
    } else {
      0
    },
  }
}

///|
fn write_cli_parse_command_result_output(
  stdout : StringBuilder,
  source_name : String?,
  result : CliParseResult,
  duration_millis~ : UInt64?,
) -> Unit {
  if !result.output.is_empty() {
    stdout.write_string(result.output)
    if !result.output.has_suffix("\n") {
      stdout.write_char('\n')
    }
  }
  match duration_millis {
    Some(duration) =>
      write_cli_parse_timing_summary(
        stdout,
        source_name,
        duration,
        result.problem,
      )
    None => write_cli_parse_problem_summary(stdout, source_name, result.problem)
  }
}

///|
fn cli_parse_elapsed_millis(start_time : UInt64?) -> UInt64? {
  match start_time {
    Some(start) => {
      let finish = @env.now()
      Some(if finish >= start { finish - start } else { 0 })
    }
    None => None
  }
}

///|
fn write_cli_parse_timing_summary(
  stdout : StringBuilder,
  source_name : String?,
  duration_millis : UInt64,
  problem : CliParseProblem?,
) -> Unit {
  stdout.write_string(cli_parse_timing_source_label(source_name))
  stdout.write_string("\tParse: \{duration_millis} ms")
  match problem {
    Some(problem) => {
      stdout.write_char('\t')
      stdout.write_string(render_parse_problem(problem))
    }
    None => ()
  }
  stdout.write_char('\n')
}

///|
fn write_cli_parse_problem_summary(
  stdout : StringBuilder,
  source_name : String?,
  problem : CliParseProblem?,
) -> Unit {
  match problem {
    Some(problem) => {
      match source_name {
        Some(name) => {
          stdout.write_string(name)
          stdout.write_char('\t')
        }
        None => ()
      }
      stdout.write_string(render_parse_problem(problem))
      stdout.write_char('\n')
    }
    None => ()
  }
}

///|
fn cli_parse_timing_source_label(source_name : String?) -> String {
  source_name.unwrap_or("<input>")
}

///|
fn run_cli_parse_source_for_command(
  command : CliParseCommand,
  parser : @tree_sitter_mbt.Parser,
  contents : Bytes,
) -> CliParseResult raise {
  match command.encoding {
    Some(encoding) =>
      run_cli_parse_source(
        parser,
        contents,
        output=command.output,
        no_ranges=command.no_ranges,
        encoding~,
      )
    None =>
      run_cli_parse_source(
        parser,
        contents,
        output=command.output,
        no_ranges=command.no_ranges,
      )
  }
}

///|
fn parse_cli_test_command_file(
  input_file : CliTestCommandFile,
) -> CliCorpusFile {
  match (input_file.file_name, input_file.current_platform) {
    (Some(file_name), Some(current_platform)) =>
      parse_corpus_file_contents(
        input_file.name,
        input_file.contents,
        file_name~,
        current_platform~,
      )
    (Some(file_name), None) =>
      parse_corpus_file_contents(
        input_file.name,
        input_file.contents,
        file_name~,
      )
    (None, Some(current_platform)) =>
      parse_corpus_file_contents(
        input_file.name,
        input_file.contents,
        current_platform~,
      )
    (None, None) =>
      parse_corpus_file_contents(input_file.name, input_file.contents)
  }
}

///|
fn plan_cli_corpus_update_for_command(
  command : CliTestCommand,
  parser : @tree_sitter_mbt.Parser,
  corpus : CliCorpusFile,
) -> CliCorpusUpdatePlan raise {
  match (command.include_pattern, command.exclude_pattern, command.file_name) {
    (Some(include_pattern), Some(exclude_pattern), Some(file_name)) =>
      plan_cli_corpus_update(
        parser,
        corpus,
        include_pattern~,
        exclude_pattern~,
        file_name~,
        show_fields=command.show_fields,
      )
    (Some(include_pattern), Some(exclude_pattern), None) =>
      plan_cli_corpus_update(
        parser,
        corpus,
        include_pattern~,
        exclude_pattern~,
        show_fields=command.show_fields,
      )
    (Some(include_pattern), None, Some(file_name)) =>
      plan_cli_corpus_update(
        parser,
        corpus,
        include_pattern~,
        file_name~,
        show_fields=command.show_fields,
      )
    (Some(include_pattern), None, None) =>
      plan_cli_corpus_update(
        parser,
        corpus,
        include_pattern~,
        show_fields=command.show_fields,
      )
    (None, Some(exclude_pattern), Some(file_name)) =>
      plan_cli_corpus_update(
        parser,
        corpus,
        exclude_pattern~,
        file_name~,
        show_fields=command.show_fields,
      )
    (None, Some(exclude_pattern), None) =>
      plan_cli_corpus_update(
        parser,
        corpus,
        exclude_pattern~,
        show_fields=command.show_fields,
      )
    (None, None, Some(file_name)) =>
      plan_cli_corpus_update(
        parser,
        corpus,
        file_name~,
        show_fields=command.show_fields,
      )
    (None, None, None) =>
      plan_cli_corpus_update(parser, corpus, show_fields=command.show_fields)
  }
}

///|
fn run_cli_corpus_file_for_command(
  command : CliTestCommand,
  parser : @tree_sitter_mbt.Parser,
  corpus : CliCorpusFile,
) -> Array[CliCorpusRunResult] raise {
  match (command.include_pattern, command.exclude_pattern, command.file_name) {
    (Some(include_pattern), Some(exclude_pattern), Some(file_name)) =>
      run_cli_corpus_file(
        parser,
        corpus,
        include_pattern~,
        exclude_pattern~,
        file_name~,
        show_fields=command.show_fields,
      )
    (Some(include_pattern), Some(exclude_pattern), None) =>
      run_cli_corpus_file(
        parser,
        corpus,
        include_pattern~,
        exclude_pattern~,
        show_fields=command.show_fields,
      )
    (Some(include_pattern), None, Some(file_name)) =>
      run_cli_corpus_file(
        parser,
        corpus,
        include_pattern~,
        file_name~,
        show_fields=command.show_fields,
      )
    (Some(include_pattern), None, None) =>
      run_cli_corpus_file(
        parser,
        corpus,
        include_pattern~,
        show_fields=command.show_fields,
      )
    (None, Some(exclude_pattern), Some(file_name)) =>
      run_cli_corpus_file(
        parser,
        corpus,
        exclude_pattern~,
        file_name~,
        show_fields=command.show_fields,
      )
    (None, Some(exclude_pattern), None) =>
      run_cli_corpus_file(
        parser,
        corpus,
        exclude_pattern~,
        show_fields=command.show_fields,
      )
    (None, None, Some(file_name)) =>
      run_cli_corpus_file(
        parser,
        corpus,
        file_name~,
        show_fields=command.show_fields,
      )
    (None, None, None) =>
      run_cli_corpus_file(parser, corpus, show_fields=command.show_fields)
  }
}

///|
fn render_cli_test_summary_for_command(
  summary : CliTestRunSummary,
  command : CliTestCommand,
) -> String {
  match command.stats {
    Some(stats) => render_cli_test_summary(summary, stats~)
    None => render_cli_test_summary(summary)
  }
}

///|
fn run_cli_query_source(
  command : CliQueryCommand,
  language : @tree_sitter_mbt.Language,
  compiled : @query.Query,
  source : CliParseCommandSource,
) -> CliQueryCommandSourceResult raise CliQueryRunError {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(language) catch {
    err => raise CliQueryRunError::LanguageFailed(err)
  }
  let input = match command.encoding {
    Some(encoding) => cli_input_from_bytes(source.contents, requested=encoding)
    None => cli_input_from_bytes(source.contents)
  }
  let tree = parser.parse(input) catch {
    err => raise CliQueryRunError::ParseFailed(err)
  }
  let root = tree.root_node()
  let execution = execute_cli_query_source(
    command,
    compiled,
    root,
    source.contents,
  )
  let has_parse_error = root.has_error()
  let (output, assertions_successful) = if command.test_mode {
    match assert_cli_query_captures(source.contents, root, execution.captures) {
      Ok(assertion_count) =>
        (render_cli_query_test_success(source.name, assertion_count), true)
      Err(message) =>
        (render_cli_query_test_failure(source.name, message), false)
    }
  } else {
    (execution.output, true)
  }
  {
    name: source.name,
    output,
    match_count: execution.match_count,
    capture_count: execution.capture_count,
    has_parse_error,
    successful: !has_parse_error && assertions_successful,
  }
}

///|
fn apply_cli_query_ranges(
  command : CliQueryCommand,
  cursor : @query.QueryCursor,
) -> Unit raise CliQueryRunError {
  match command.byte_range {
    Some(range) =>
      if !cursor.set_byte_range(range.start, range.end) {
        raise CliQueryRunError::InvalidRange("--byte-range")
      }
    None => ()
  }
  match command.containing_byte_range {
    Some(range) =>
      if !cursor.set_containing_byte_range(range.start, range.end) {
        raise CliQueryRunError::InvalidRange("--containing-byte-range")
      }
    None => ()
  }
}

///|
priv struct CliQueryCaptureInfo {
  name : String
  start : @api.Point
  end : @api.Point
}

///|
priv struct CliQueryExecution {
  output : String
  match_count : Int
  capture_count : Int
  captures : Array[CliQueryCaptureInfo]
}

///|
fn execute_cli_query_source(
  command : CliQueryCommand,
  compiled : @query.Query,
  root : @tree_sitter_mbt.Node,
  source : Bytes,
) -> CliQueryExecution raise CliQueryRunError {
  let cursor = @query.QueryCursor::new()
  apply_cli_query_ranges(command, cursor)
  cursor.exec(compiled, root)
  let out = StringBuilder::new()
  let captures : Array[CliQueryCaptureInfo] = []
  let (match_count, capture_count) = match command.output {
    CliQueryCaptures =>
      execute_cli_query_captures(
        command, cursor, compiled, source, out, captures,
      )
    CliQueryMatches =>
      execute_cli_query_matches(
        command, cursor, compiled, source, out, captures,
      )
  }
  { output: out.to_string(), match_count, capture_count, captures }
}

///|
fn execute_cli_query_captures(
  command : CliQueryCommand,
  cursor : @query.QueryCursor,
  compiled : @query.Query,
  source : Bytes,
  out : StringBuilder,
  captures : Array[CliQueryCaptureInfo],
) -> (Int, Int) raise CliQueryRunError {
  let mut capture_count = 0
  while true {
    let next = cursor.next_capture_with_text_predicates_bytes(compiled, source) catch {
      err => raise CliQueryRunError::PredicateFailed(err)
    }
    match next {
      Some(capture) => {
        capture_count += 1
        captures.push(cli_query_capture_info(compiled, capture))
        if !command.test_mode {
          out.write_string(render_cli_query_capture(capture))
          out.write_char('\n')
        }
      }
      None => return (capture_count, capture_count)
    }
  }
  (capture_count, capture_count)
}

///|
fn execute_cli_query_matches(
  command : CliQueryCommand,
  cursor : @query.QueryCursor,
  compiled : @query.Query,
  source : Bytes,
  out : StringBuilder,
  captures : Array[CliQueryCaptureInfo],
) -> (Int, Int) raise CliQueryRunError {
  let mut match_count = 0
  let mut capture_count = 0
  while true {
    let next = cursor.next_match_with_text_predicates_bytes(compiled, source) catch {
      err => raise CliQueryRunError::PredicateFailed(err)
    }
    match next {
      Some(matched) => {
        match_count += 1
        if !command.test_mode {
          out.write_string("pattern \{matched.pattern_index}\n")
        }
        for capture in matched.captures {
          capture_count += 1
          captures.push(cli_query_capture_info(compiled, capture))
          if !command.test_mode {
            out.write_string("  ")
            out.write_string(render_cli_query_capture(capture))
            out.write_char('\n')
          }
        }
      }
      None => return (match_count, capture_count)
    }
  }
  (match_count, capture_count)
}

///|
fn cli_query_capture_info(
  compiled : @query.Query,
  capture : @query.QueryCapture,
) -> CliQueryCaptureInfo {
  {
    name: compiled.capture_name_for_id(capture.index).unwrap_or(""),
    start: capture.node.start_point(),
    end: capture.node.end_point(),
  }
}

///|
fn render_cli_query_capture(capture : @query.QueryCapture) -> String {
  let node = capture.node
  "\{capture.name} \{node.type_()} \{node.start_byte()}:\{node.end_byte()}"
}

///|
pub fn summarize_cli_test_results(
  results : Array[CliCorpusRunResult],
) -> CliTestRunSummary {
  let mut passed = 0
  let mut failed = 0
  let mut skipped = 0
  let mut platform_skipped = 0
  for result in results {
    match result.status {
      CorpusRunPassed => passed += 1
      CorpusRunFailed => failed += 1
      CorpusRunSkipped => skipped += 1
      CorpusRunPlatformSkipped => platform_skipped += 1
    }
  }
  { total: results.length(), passed, failed, skipped, platform_skipped }
}

///|
pub fn render_cli_test_summary(
  summary : CliTestRunSummary,
  stats? : CliTestStatsMode,
) -> String {
  match stats {
    Some(CliTestStatsTotalOnly) => "total: \{summary.total}\n"
    Some(CliTestStatsOutliersAndTotal) | Some(CliTestStatsAll) | None =>
      [
        "total: \{summary.total}",
        "passed: \{summary.passed}",
        "failed: \{summary.failed}",
        "skipped: \{summary.skipped}",
        "platform_skipped: \{summary.platform_skipped}",
        "",
      ].join("\n")
  }
}

///|
pub fn render_cli_test_json_summary(summary : CliTestRunSummary) -> String {
  [
    "{",
    "\"total\":\{summary.total},",
    "\"passed\":\{summary.passed},",
    "\"failed\":\{summary.failed},",
    "\"skipped\":\{summary.skipped},",
    "\"platform_skipped\":\{summary.platform_skipped}",
    "}",
  ].join("")
}
