///|
pub(all) enum CliCorpusExpectation {
  Pass
  Error
  Skip
} derive(Eq, Debug)

///|
pub(all) struct CliCorpusAttributes {
  platform : Bool
  fail_fast : Bool
  expectation : CliCorpusExpectation
  cst : Bool
  languages : Array[String]
} derive(Eq, Debug)

///|
pub(all) struct CliCorpusExample {
  name : String
  input : Bytes
  output : String
  header_delim_len : Int
  divider_delim_len : Int
  has_fields : Bool
  attributes_str : String
  attributes : CliCorpusAttributes
  file_name : String?
} derive(Eq, Debug)

///|
pub(all) struct CliCorpusFile {
  name : String
  examples : Array[CliCorpusExample]
  file_name : String?
} derive(Eq, Debug)

///|
pub(all) struct CliCorpusNormalizedOutput {
  output : String
  has_fields : Bool
} derive(Eq, Debug)

///|
priv struct CliCorpusPendingTest {
  name : String
  attributes_str : String
  header_delim_len : Int
  attributes : CliCorpusAttributes
  body_start_line : Int
}

///|
pub fn parse_corpus_file_contents(
  name : String,
  contents : String,
  file_name? : String,
  current_platform? : String = "",
) -> CliCorpusFile {
  let lines = split_corpus_lines_inclusive(contents)
  let first_suffix = first_corpus_suffix(lines)
  let examples : Array[CliCorpusExample] = []
  let mut line_num = 0
  let mut pending : CliCorpusPendingTest? = None
  while line_num < lines.length() {
    match
      parse_corpus_header(lines, first_suffix, line_num, current_platform~) {
      Some((next_pending, body_start_line)) => {
        let opening_line = line_num
        match pending {
          Some(previous) =>
            match
              build_corpus_example(
                lines,
                previous.body_start_line,
                opening_line,
                first_suffix,
                previous,
                file_name,
              ) {
              Some(example) => examples.push(example)
              None => ()
            }
          None => ()
        }
        pending = Some(next_pending)
        line_num = body_start_line
      }
      None => line_num += 1
    }
  }
  match pending {
    Some(previous) =>
      match
        build_corpus_example(
          lines,
          previous.body_start_line,
          lines.length(),
          first_suffix,
          previous,
          file_name,
        ) {
        Some(example) => examples.push(example)
        None => ()
      }
    None => ()
  }
  { name, examples, file_name }
}

///|
pub fn normalize_corpus_sexp_output(raw : String) -> CliCorpusNormalizedOutput {
  let result : Array[Char] = []
  let mut prev_was_space = false
  for line in split_corpus_lines_inclusive(raw) {
    if line.trim_start().has_prefix(";") {
      continue
    }
    for char in line {
      if char.is_whitespace() {
        if !prev_was_space && !result.is_empty() {
          result.push(' ')
          prev_was_space = true
        }
      } else {
        if char == ')' && prev_was_space {
          result.pop() |> ignore
        }
        result.push(char)
        prev_was_space = false
      }
    }
    if !result.is_empty() && !prev_was_space {
      result.push(' ')
      prev_was_space = true
    }
  }
  if prev_was_space {
    result.pop() |> ignore
  }
  let output = String::from_array(result)
  { output, has_fields: output.contains(": (") }
}

///|
fn parse_corpus_header(
  lines : Array[String],
  first_suffix : String?,
  start_line : Int,
  current_platform~ : String,
) -> (CliCorpusPendingTest, Int)? {
  let (header_delim_len, suffix) = match
    parse_corpus_delimiter_line(lines[start_line], '=') {
    Some(result) => result
    None => return None
  }
  if !corpus_suffix_matches(first_suffix, suffix) {
    return None
  }
  let name_out = StringBuilder::new()
  let marker_out = StringBuilder::new()
  let languages : Array[String] = []
  let mut seen_marker = false
  let mut seen_skip = false
  let mut seen_error = false
  let mut fail_fast = false
  let mut cst = false
  let mut platform_seen = false
  let mut platform = false
  let mut line_num = start_line + 1
  while line_num < lines.length() {
    if parse_corpus_delimiter_line(lines[line_num], '=')
      is Some((_, closing_suffix)) &&
      corpus_suffix_matches(first_suffix, closing_suffix) {
      break
    }
    let line = lines[line_num]
    let trimmed = line.trim().to_owned()
    if trimmed == "" && !seen_marker {
      return None
    }
    if trimmed == ":skip" {
      seen_marker = true
      seen_skip = true
    } else if trimmed == ":fail-fast" {
      seen_marker = true
      fail_fast = true
    } else if trimmed == ":error" {
      seen_marker = true
      seen_error = true
    } else if trimmed == ":cst" {
      seen_marker = true
      cst = true
    } else if trimmed.has_prefix(":language(") && trimmed.has_suffix(")") {
      seen_marker = true
      languages.push(corpus_marker_inner(trimmed, ":language("))
    } else if trimmed.has_prefix(":platform(") && trimmed.has_suffix(")") {
      seen_marker = true
      platform_seen = true
      platform = platform ||
        corpus_marker_inner(trimmed, ":platform(").trim().to_owned() ==
        current_platform
    } else if !seen_marker {
      name_out.write_string(line)
    }
    if seen_marker {
      marker_out.write_string(line)
    }
    line_num += 1
  }
  if line_num >= lines.length() {
    return None
  }
  if languages.is_empty() {
    languages.push("")
  }
  let expectation = match (seen_skip, seen_error) {
    (true, _) => Skip
    (false, true) => Error
    (false, false) => Pass
  }
  Some(
    (
      {
        name: name_out.to_string().trim_end().to_owned(),
        attributes_str: marker_out.to_string().trim_end().to_owned(),
        header_delim_len,
        attributes: {
          platform: if platform_seen {
            platform
          } else {
            true
          },
          fail_fast,
          expectation,
          cst,
          languages,
        },
        body_start_line: line_num + 1,
      },
      line_num + 1,
    ),
  )
}

///|
fn build_corpus_example(
  lines : Array[String],
  start_line : Int,
  end_line : Int,
  first_suffix : String?,
  pending : CliCorpusPendingTest,
  file_name : String?,
) -> CliCorpusExample? {
  let mut best_divider_line = -1
  let mut best_divider_len = 0
  let mut best_total_len = 0
  for line_index in start_line..<end_line {
    match parse_corpus_delimiter_line(lines[line_index], '-') {
      Some((delim_len, suffix)) =>
        if corpus_suffix_matches(first_suffix, suffix) {
          let total_len = delim_len + suffix.length()
          if total_len >= best_total_len {
            best_total_len = total_len
            best_divider_line = line_index
            best_divider_len = delim_len
          }
        }
      None => ()
    }
  }
  if best_divider_line < 0 {
    return None
  }
  let input = corpus_input_bytes(lines, start_line, best_divider_line)
  let output_raw = join_corpus_lines(lines, best_divider_line + 1, end_line)
  let (output, has_fields) = if pending.attributes.cst {
    (output_raw.trim().to_owned(), false)
  } else {
    let normalized = normalize_corpus_sexp_output(output_raw)
    (normalized.output, normalized.has_fields)
  }
  Some({
    name: pending.name,
    input,
    output,
    header_delim_len: pending.header_delim_len,
    divider_delim_len: best_divider_len,
    has_fields,
    attributes_str: pending.attributes_str,
    attributes: pending.attributes,
    file_name,
  })
}

///|
fn split_corpus_lines_inclusive(contents : String) -> Array[String] {
  let lines : Array[String] = []
  let current = StringBuilder::new()
  for char in contents {
    current.write_char(char)
    if char == '\n' {
      lines.push(current.to_string())
      current.reset()
    }
  }
  if !current.is_empty() {
    lines.push(current.to_string())
  }
  lines
}

///|
fn parse_corpus_delimiter_line(
  line : String,
  delimiter : Char,
) -> (Int, String)? {
  let mut delim_len = 0
  let mut done = false
  while !done && delim_len < line.length() {
    if line.get_char(delim_len) == Some(delimiter) {
      delim_len += 1
    } else {
      done = true
    }
  }
  if delim_len < 3 {
    None
  } else {
    Some((delim_len, line[delim_len:].trim_end(chars="\r\n").to_owned()))
  }
}

///|
fn first_corpus_suffix(lines : Array[String]) -> String? {
  for line in lines {
    match parse_corpus_delimiter_line(line, '=') {
      Some((_, suffix)) => if suffix != "" { return Some(suffix) }
      None => ()
    }
  }
  None
}

///|
fn corpus_suffix_matches(first_suffix : String?, suffix : String) -> Bool {
  match (first_suffix, suffix == "") {
    (None, true) => true
    (Some(first), false) => first == suffix
    _ => false
  }
}

///|
fn corpus_marker_inner(marker : String, prefix : String) -> String {
  let start = prefix.length()
  let end = marker.length() - 1
  marker[start:end].to_owned()
}

///|
fn join_corpus_lines(lines : Array[String], start : Int, end : Int) -> String {
  let out = StringBuilder::new()
  for index in start..<end {
    out.write_string(lines[index])
  }
  out.to_string()
}

///|
fn corpus_input_bytes(lines : Array[String], start : Int, end : Int) -> Bytes {
  let bytes = @utf8.encode(join_corpus_lines(lines, start, end)).to_array()
  if bytes.length() > 0 && bytes[bytes.length() - 1] == b'\n' {
    bytes.pop() |> ignore
  }
  if bytes.length() > 0 && bytes[bytes.length() - 1] == b'\r' {
    bytes.pop() |> ignore
  }
  Bytes::from_array(bytes)
}
