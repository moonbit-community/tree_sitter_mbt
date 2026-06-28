///|
pub(all) enum CliCorpusRunStatus {
  CorpusRunPassed
  CorpusRunFailed
  CorpusRunSkipped
  CorpusRunPlatformSkipped
} derive(Eq, Debug)

///|
pub(all) struct CliCorpusRunResult {
  name : String
  status : CliCorpusRunStatus
  expected : String
  actual : String
  is_cst : Bool
  has_parse_error : Bool
  expectation : CliCorpusExpectation
  file_name : String?
} derive(Eq, Debug)

///|
pub(all) struct CliCorpusCorrection {
  name : String
  input : String
  output : String
  attributes_str : String
  header_delim_len : Int
  divider_delim_len : Int
} derive(Eq, Debug)

///|
pub(all) struct CliCorpusUpdatePlan {
  results : Array[CliCorpusRunResult]
  corrections : Array[CliCorpusCorrection]
  has_unexpected_parse_errors : Bool
  can_update : Bool
  stopped_on_fail_fast : Bool
} derive(Eq, Debug)

///|
priv struct CliCorpusSexpFormatter {
  chars : Array[Char]
  mut index : Int
  mut quote : Char?
  mut saw_paren : Bool
  mut did_last : Bool
}

///|
pub fn cli_corpus_example_is_selected(
  example : CliCorpusExample,
  include_pattern? : String,
  exclude_pattern? : String,
  file_name? : String,
) -> Bool {
  cli_corpus_example_is_selected_values(
    example, include_pattern, exclude_pattern, file_name,
  )
}

///|
fn cli_corpus_example_is_selected_values(
  example : CliCorpusExample,
  include_pattern : String?,
  exclude_pattern : String?,
  file_name : String?,
) -> Bool {
  match (example.file_name, file_name) {
    (Some(example_file_name), Some(filter_file_name)) =>
      if example_file_name != filter_file_name {
        return false
      }
    _ => ()
  }
  match include_pattern {
    Some(include_pattern) => example.name.contains(include_pattern)
    None =>
      match exclude_pattern {
        Some(exclude_pattern) => !example.name.contains(exclude_pattern)
        None => true
      }
  }
}

///|
pub fn cli_corpus_correction_from_example(
  example : CliCorpusExample,
  output? : String,
) -> CliCorpusCorrection {
  {
    name: example.name,
    input: @utf8.decode_lossy(example.input),
    output: output.unwrap_or(example.output),
    attributes_str: example.attributes_str,
    header_delim_len: example.header_delim_len,
    divider_delim_len: example.divider_delim_len,
  }
}

///|
pub fn render_cli_corpus_corrections(
  corrections : Array[CliCorpusCorrection],
) -> String {
  let out = StringBuilder::new()
  for index, correction in corrections {
    if index > 0 {
      out.write_char('\n')
    }
    out.write_string(render_cli_corpus_correction(correction))
  }
  out.to_string()
}

///|
pub fn run_cli_corpus_file(
  parser : @tree_sitter_mbt.Parser,
  file : CliCorpusFile,
  include_pattern? : String,
  exclude_pattern? : String,
  file_name? : String,
  show_fields? : Bool = false,
) -> Array[CliCorpusRunResult] raise {
  let results : Array[CliCorpusRunResult] = []
  for example in file.examples {
    if !cli_corpus_example_is_selected_values(
        example, include_pattern, exclude_pattern, file_name,
      ) {
      continue
    }
    let result = run_cli_corpus_example(parser, example, show_fields~)
    let should_stop = cli_corpus_result_should_fail_fast(example, result)
    results.push(result)
    if should_stop {
      break
    }
  }
  results
}

///|
pub fn plan_cli_corpus_update(
  parser : @tree_sitter_mbt.Parser,
  file : CliCorpusFile,
  include_pattern? : String,
  exclude_pattern? : String,
  file_name? : String,
  show_fields? : Bool = false,
) -> CliCorpusUpdatePlan raise {
  let results : Array[CliCorpusRunResult] = []
  let corrections : Array[CliCorpusCorrection] = []
  let mut has_unexpected_parse_errors = false
  let mut stopped_on_fail_fast = false
  for example in file.examples {
    if stopped_on_fail_fast ||
      !cli_corpus_example_is_selected_values(
        example, include_pattern, exclude_pattern, file_name,
      ) {
      corrections.push(cli_corpus_preserved_correction(example))
      continue
    }
    let result = run_cli_corpus_example(parser, example, show_fields~)
    let (correction, has_unexpected) = cli_corpus_update_correction(
      example, result,
    )
    results.push(result)
    corrections.push(correction)
    if has_unexpected {
      has_unexpected_parse_errors = true
    }
    if cli_corpus_result_should_fail_fast(example, result) {
      stopped_on_fail_fast = true
    }
  }
  {
    results,
    corrections,
    has_unexpected_parse_errors,
    can_update: !has_unexpected_parse_errors,
    stopped_on_fail_fast,
  }
}

///|
pub fn run_cli_corpus_example(
  parser : @tree_sitter_mbt.Parser,
  example : CliCorpusExample,
  show_fields? : Bool = false,
) -> CliCorpusRunResult raise {
  if example.attributes.expectation is Skip {
    return cli_corpus_run_result(
      example,
      CorpusRunSkipped,
      expected="",
      actual="",
      has_parse_error=false,
    )
  }
  if !example.attributes.platform {
    return cli_corpus_run_result(
      example,
      CorpusRunPlatformSkipped,
      expected="",
      actual="",
      has_parse_error=false,
    )
  }
  let tree = parser.parse_bytes(example.input)
  let has_parse_error = tree.root_node().has_error()
  let actual = render_cli_corpus_actual(example, tree, show_fields~)
  if example.attributes.expectation is Error {
    if has_parse_error {
      cli_corpus_run_result(
        example,
        CorpusRunPassed,
        expected="ERROR",
        actual~,
        has_parse_error~,
      )
    } else {
      cli_corpus_run_result(
        example,
        CorpusRunFailed,
        expected="NO ERROR",
        actual~,
        has_parse_error~,
      )
    }
  } else {
    cli_corpus_run_result(
      example,
      if actual == example.output {
        CorpusRunPassed
      } else {
        CorpusRunFailed
      },
      expected=example.output,
      actual~,
      has_parse_error~,
    )
  }
}

///|
fn cli_corpus_result_should_fail_fast(
  example : CliCorpusExample,
  result : CliCorpusRunResult,
) -> Bool {
  example.attributes.fail_fast &&
  (
    result.status is CorpusRunFailed ||
    (
      example.attributes.expectation is Error &&
      result.status is CorpusRunPassed
    )
  )
}

///|
pub fn cli_corpus_run_results_have_failure(
  results : Array[CliCorpusRunResult],
) -> Bool {
  for result in results {
    if result.status is CorpusRunFailed {
      return true
    }
  }
  false
}

///|
pub fn cli_corpus_run_exit_code(results : Array[CliCorpusRunResult]) -> Int {
  if cli_corpus_run_results_have_failure(results) {
    1
  } else {
    0
  }
}

///|
pub fn format_cli_corpus_sexp(
  sexp : String,
  initial_indent_level? : Int = 0,
) -> String {
  let formatter = CliCorpusSexpFormatter::new(sexp)
  let out = StringBuilder::new()
  let mut indent_level = initial_indent_level
  let mut has_field = false
  while formatter.fetch_next() is Some(scratch) {
    if scratch.is_empty() && indent_level > 0 {
      indent_level -= 1
      out.write_char(')')
    } else if scratch.has_prefix("(") {
      if has_field {
        has_field = false
      } else {
        if indent_level > 0 {
          out.write_char('\n')
          cli_corpus_write_indent(out, indent_level)
        }
        indent_level += 1
      }
      out.write_string(scratch)
      if scratch.has_prefix("(MISSING") || scratch.has_prefix("(UNEXPECTED") {
        match formatter.fetch_next() {
          Some(next) =>
            if next.is_empty() {
              while indent_level > 0 {
                indent_level -= 1
                out.write_char(')')
              }
            } else {
              out.write_char(' ')
              out.write_string(next)
            }
          None => ()
        }
      }
    } else if scratch.has_suffix(":") {
      out.write_char('\n')
      cli_corpus_write_indent(out, indent_level)
      out.write_string(scratch)
      out.write_char(' ')
      has_field = true
      indent_level += 1
    }
  }
  out.to_string()
}

///|
pub fn strip_cli_corpus_sexp_fields(sexp : String) -> String {
  let out = StringBuilder::new()
  let mut offset = 0
  while offset < sexp.length() {
    match sexp.get_char(offset) {
      Some(' ') =>
        match cli_corpus_field_label_end_after_space(sexp, offset + 1) {
          Some(next_offset) => {
            out.write_char(' ')
            out.write_char('(')
            offset = next_offset
          }
          None => {
            out.write_char(' ')
            offset += 1
          }
        }
      Some(char) => {
        out.write_char(char)
        offset += char.utf16_len()
      }
      None => break
    }
  }
  out.to_string()
}

///|
fn cli_corpus_run_result(
  example : CliCorpusExample,
  status : CliCorpusRunStatus,
  expected~ : String,
  actual~ : String,
  has_parse_error~ : Bool,
) -> CliCorpusRunResult {
  {
    name: example.name,
    status,
    expected,
    actual,
    is_cst: example.attributes.cst,
    has_parse_error,
    expectation: example.attributes.expectation,
    file_name: example.file_name,
  }
}

///|
fn render_cli_corpus_correction(correction : CliCorpusCorrection) -> String {
  let out = StringBuilder::new()
  let header = cli_corpus_repeat_char('=', correction.header_delim_len)
  let divider = cli_corpus_repeat_char('-', correction.divider_delim_len)
  out.write_string(header)
  out.write_char('\n')
  out.write_string(correction.name)
  out.write_char('\n')
  if !correction.attributes_str.is_empty() {
    out.write_string(correction.attributes_str)
    out.write_char('\n')
  }
  out.write_string(header)
  out.write_char('\n')
  out.write_string(correction.input)
  out.write_char('\n')
  out.write_string(divider)
  out.write_string("\n\n")
  out.write_string(correction.output.trim().to_owned())
  out.write_char('\n')
  out.to_string()
}

///|
fn cli_corpus_update_correction(
  example : CliCorpusExample,
  result : CliCorpusRunResult,
) -> (CliCorpusCorrection, Bool) {
  if example.attributes.expectation is Error ||
    result.status is CorpusRunSkipped ||
    result.status is CorpusRunPlatformSkipped {
    return (cli_corpus_preserved_correction(example), false)
  }
  if result.status is CorpusRunPassed {
    return (
      cli_corpus_correction_from_example(
        example,
        output=cli_corpus_format_update_output(
          example.output,
          example.attributes.cst,
        ),
      ),
      false,
    )
  }
  let has_unexpected = cli_corpus_output_has_unexpected_parse_error(
    result.actual,
  )
  if has_unexpected {
    (cli_corpus_preserved_correction(example), true)
  } else {
    (
      cli_corpus_correction_from_example(
        example,
        output=cli_corpus_format_update_output(
          result.actual,
          example.attributes.cst,
        ),
      ),
      false,
    )
  }
}

///|
fn cli_corpus_preserved_correction(
  example : CliCorpusExample,
) -> CliCorpusCorrection {
  cli_corpus_correction_from_example(
    example,
    output=cli_corpus_format_update_output(
      example.output,
      example.attributes.cst,
    ),
  )
}

///|
fn cli_corpus_format_update_output(output : String, is_cst : Bool) -> String {
  if is_cst {
    output
  } else {
    format_cli_corpus_sexp(output)
  }
}

///|
fn cli_corpus_output_has_unexpected_parse_error(output : String) -> Bool {
  output.contains("ERROR") || output.contains("MISSING")
}

///|
fn render_cli_corpus_actual(
  example : CliCorpusExample,
  tree : @tree_sitter_mbt.Tree,
  show_fields~ : Bool,
) -> String {
  if example.attributes.cst {
    render_parse_cst_tree(example.input, tree).trim().to_owned()
  } else {
    let actual = tree.to_sexp()
    if show_fields || example.has_fields {
      actual
    } else {
      strip_cli_corpus_sexp_fields(actual)
    }
  }
}

///|
fn CliCorpusSexpFormatter::new(sexp : String) -> CliCorpusSexpFormatter {
  {
    chars: sexp.to_array(),
    index: 0,
    quote: None,
    saw_paren: false,
    did_last: false,
  }
}

///|
fn CliCorpusSexpFormatter::peek(self : CliCorpusSexpFormatter) -> Char? {
  if self.index < self.chars.length() {
    Some(self.chars[self.index])
  } else {
    None
  }
}

///|
fn CliCorpusSexpFormatter::advance(self : CliCorpusSexpFormatter) -> Char? {
  match self.peek() {
    Some(char) => {
      self.index += 1
      Some(char)
    }
    None => None
  }
}

///|
fn CliCorpusSexpFormatter::fetch_next(self : CliCorpusSexpFormatter) -> String? {
  let next = StringBuilder::new()
  while self.advance() is Some(char) {
    if char == '\'' || char == '"' {
      self.quote = Some(char)
    } else if char == ' ' || (char == ')' && self.quote is Some(_)) {
      match (self.peek(), self.quote) {
        (Some(next_char), Some(quote)) if next_char == quote => {
          next.write_char(char)
          next.write_char(next_char)
          let _ = self.advance()
          self.quote = None
          continue
        }
        _ => break
      }
    }
    if char == ')' {
      self.saw_paren = true
      break
    }
    next.write_char(char)
  }
  let result = next.to_string()
  if self.peek() is None && result.is_empty() {
    if self.saw_paren {
      self.saw_paren = false
      return Some("")
    }
    if !self.did_last {
      self.did_last = true
      return Some("")
    }
    return None
  }
  Some(result)
}

///|
fn cli_corpus_field_label_end_after_space(sexp : String, start : Int) -> Int? {
  let mut offset = start
  let mut saw_field_char = false
  while offset < sexp.length() {
    match sexp.get_char(offset) {
      Some(char) if cli_corpus_field_char_is_ascii_alphanumeric(char) ||
        char == '_' => {
        saw_field_char = true
        offset += char.utf16_len()
      }
      Some(':') if saw_field_char => {
        let space_offset = offset + 1
        let open_offset = space_offset + 1
        if sexp.get_char(space_offset) == Some(' ') &&
          sexp.get_char(open_offset) == Some('(') {
          return Some(open_offset + 1)
        }
        return None
      }
      _ => return None
    }
  }
  None
}

///|
fn cli_corpus_field_char_is_ascii_alphanumeric(char : Char) -> Bool {
  let value = char.to_uint()
  (48U <= value && value <= 57U) ||
  (65U <= value && value <= 90U) ||
  (97U <= value && value <= 122U)
}

///|
fn cli_corpus_repeat_char(char : Char, count : Int) -> String {
  let out = StringBuilder::new()
  for _ in 0..<count {
    out.write_char(char)
  }
  out.to_string()
}

///|
fn cli_corpus_write_indent(out : StringBuilder, indent_level : Int) -> Unit {
  for _ in 0..<indent_level {
    out.write_string("  ")
  }
}
