///|
pub(all) suberror CliTagsRunError {
  TagsFailed(@tags.TagsError)
}

///|
pub(all) struct CliTagsCommandSourceResult {
  name : String?
  output : String
  tag_count : Int
  has_parse_error : Bool
  successful : Bool
} derive(Eq, Debug)

///|
pub(all) struct CliTagsCommandRunResult {
  results : Array[CliTagsCommandSourceResult]
  stdout : String
  exit_code : Int
} derive(Eq, Debug)

///|
pub fn run_cli_tags_command(
  command : CliTagsCommand,
  config : @tags.TagsConfiguration,
  sources : Array[CliParseCommandSource],
) -> CliTagsCommandRunResult raise CliTagsRunError {
  let results : Array[CliTagsCommandSourceResult] = []
  let stdout = StringBuilder::new()
  let indent = sources.length() > 1
  for source in sources {
    let result = run_cli_tags_source(command, config, source, indent)
    stdout.write_string(result.output)
    results.push(result)
  }
  { results, stdout: stdout.to_string(), exit_code: 0 }
}

///|
fn run_cli_tags_source(
  command : CliTagsCommand,
  config : @tags.TagsConfiguration,
  source : CliParseCommandSource,
  indent : Bool,
) -> CliTagsCommandSourceResult raise CliTagsRunError {
  let start_time = if command.time { Some(@env.now()) } else { None }
  let generated = @tags.generate_tags(config, source.contents) catch {
    err => raise CliTagsRunError::TagsFailed(err)
  }
  let output = StringBuilder::new()
  if indent && !command.quiet {
    output.write_string(cli_tags_source_label(source.name))
    output.write_char('\n')
  }
  if !command.quiet {
    for tag in generated.tags {
      write_cli_tags_line(output, source.contents, tag, indent)
    }
  }
  match start_time {
    Some(start) => {
      if indent {
        output.write_char('\t')
      }
      output.write_string("time: \{cli_tags_elapsed_millis(start)}ms\n")
    }
    None => ()
  }
  {
    name: source.name,
    output: output.to_string(),
    tag_count: generated.tags.length(),
    has_parse_error: generated.has_error,
    successful: true,
  }
}

///|
fn write_cli_tags_line(
  output : StringBuilder,
  source : Bytes,
  tag : @tags.Tag,
  indent : Bool,
) -> Unit {
  if indent {
    output.write_char('\t')
  }
  output.write_string(cli_tags_pad_right(tag.name, 10))
  output.write_string("\t | ")
  output.write_string(cli_tags_pad_right(tag.syntax_type, 8))
  output.write_char('\t')
  output.write_string(cli_tags_kind_label(tag.kind))
  output.write_char(' ')
  output.write_string(cli_tags_point(tag.span.start_point))
  output.write_string(" - ")
  output.write_string(cli_tags_point(tag.span.end_point))
  output.write_string(" `")
  output.write_string(cli_tags_range_text(source, tag.line_range))
  output.write_char('`')
  output.write_string(cli_tags_docs_suffix(tag.docs))
  output.write_char('\n')
}

///|
fn cli_tags_kind_label(kind : @tags.TagKind) -> String {
  match kind {
    Definition => "def"
    Reference => "ref"
  }
}

///|
fn cli_tags_point(point : @api.Point) -> String {
  "[\{point.row}, \{point.column}]"
}

///|
fn cli_tags_range_text(source : Bytes, range : @api.Range) -> String {
  let start = range.start_byte.reinterpret_as_int()
  let end = range.end_byte.reinterpret_as_int()
  if start >= 0 && start <= end && end <= source.length() {
    @utf8.decode_lossy(source[start:end])
  } else {
    ""
  }
}

///|
fn cli_tags_docs_suffix(docs : String) -> String {
  if docs.is_empty() {
    ""
  } else {
    let (excerpt, truncated) = cli_tags_truncate_docs(docs, 120)
    let suffix = if truncated { "..." } else { "" }
    "\t\{@debug.to_string(excerpt)}\{suffix}"
  }
}

///|
fn cli_tags_truncate_docs(text : String, limit : Int) -> (String, Bool) {
  let out = StringBuilder::new()
  let mut width = 0
  for char in text {
    let char_width = char.utf16_len()
    if width + char_width > limit {
      return (out.to_string(), true)
    }
    out.write_char(char)
    width += char_width
  }
  (out.to_string(), false)
}

///|
fn cli_tags_pad_right(text : String, width : Int) -> String {
  let out = StringBuilder::new()
  out.write_string(text)
  let mut padding = width - text.length()
  while padding > 0 {
    out.write_char(' ')
    padding -= 1
  }
  out.to_string()
}

///|
fn cli_tags_source_label(name : String?) -> String {
  name.unwrap_or("stdin")
}

///|
fn cli_tags_elapsed_millis(start : UInt64) -> UInt64 {
  let finish = @env.now()
  if finish >= start {
    finish - start
  } else {
    0
  }
}
