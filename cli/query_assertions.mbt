///|
priv struct CliQueryAssertion {
  position : @api.Point
  length : UInt
  negative : Bool
  expected_capture_name : String
}

///|
priv struct CliQueryAssertionRange {
  start : @api.Point
  end : @api.Point
}

///|
fn assert_cli_query_captures(
  source : Bytes,
  root : @tree_sitter_mbt.Node,
  captures : Array[CliQueryCaptureInfo],
) -> Result[Int, String] {
  match parse_cli_query_assertions(source, root) {
    Ok(assertions) => {
      let captures = cli_query_captures_with_utf8_columns(source, captures)
      for assertion in assertions {
        match cli_query_assertion_error(assertion, captures) {
          Some(message) => return Err(message)
          None => ()
        }
      }
      Ok(assertions.length())
    }
    Err(message) => Err(message)
  }
}

///|
fn render_cli_query_test_success(
  source_name : String?,
  assertion_count : Int,
) -> String {
  let noun = if assertion_count == 1 { "assertion" } else { "assertions" }
  "\{cli_query_test_source_label(source_name)}\t\{assertion_count} \{noun} passed\n"
}

///|
fn render_cli_query_test_failure(
  source_name : String?,
  message : String,
) -> String {
  "\{cli_query_test_source_label(source_name)}\t\{message}\n"
}

///|
fn cli_query_test_source_label(source_name : String?) -> String {
  source_name.unwrap_or("<input>")
}

///|
fn parse_cli_query_assertions(
  source : Bytes,
  root : @tree_sitter_mbt.Node,
) -> Result[Array[CliQueryAssertion], String] {
  let assertions : Array[CliQueryAssertion] = []
  let ranges : Array[CliQueryAssertionRange] = []
  collect_cli_query_assertions(source, root, assertions, ranges)
  adjust_cli_query_assertions(source, assertions, ranges)
}

///|
fn collect_cli_query_assertions(
  source : Bytes,
  node : @tree_sitter_mbt.Node,
  assertions : Array[CliQueryAssertion],
  ranges : Array[CliQueryAssertionRange],
) -> Unit {
  if node.type_().to_lower().contains("comment") {
    match parse_cli_query_comment_assertion(source, node) {
      Some(assertion) => {
        assertions.push(assertion)
        ranges.push({ start: node.start_point(), end: node.end_point() })
      }
      None => ()
    }
  }
  for index in 0..<node.child_count() {
    collect_cli_query_assertions(source, node.child(index), assertions, ranges)
  }
}

///|
fn parse_cli_query_comment_assertion(
  source : Bytes,
  node : @tree_sitter_mbt.Node,
) -> CliQueryAssertion? {
  let position = node.start_point()
  if position.row == 0U {
    return None
  }
  match cli_query_node_source_view(source, node) {
    Some(text) => {
      let mut offset = 0
      while offset < text.length() {
        if text[offset] == b'^' {
          let mut length = 1
          while offset + length < text.length() && text[offset + length] == b'^' {
            length += 1
          }
          return cli_query_assertion_after_arrow(
            text,
            offset + length,
            cli_query_point_with_utf8_column(
              source,
              @api.Point::new(
                row=position.row,
                column=position.column + offset.reinterpret_as_uint(),
              ),
            ),
            length.reinterpret_as_uint(),
          )
        } else if offset > 0 && text[offset - 1] == b'<' && text[offset] == b'-' {
          return cli_query_assertion_after_arrow(
            text,
            offset + 1,
            cli_query_point_with_utf8_column(source, position),
            1U,
          )
        }
        offset += 1
      }
      None
    }
    None => None
  }
}

///|
fn cli_query_node_source_view(
  source : Bytes,
  node : @tree_sitter_mbt.Node,
) -> BytesView? {
  let start = node.start_byte().reinterpret_as_int()
  let end = node.end_byte().reinterpret_as_int()
  if start < 0 || end < start || end > source.length() {
    None
  } else {
    Some(source[start:end])
  }
}

///|
fn cli_query_assertion_after_arrow(
  text : BytesView,
  arrow_end : Int,
  position : @api.Point,
  length : UInt,
) -> CliQueryAssertion? {
  let mut offset = arrow_end
  let mut negative = false
  while offset < text.length() {
    let byte = text[offset]
    if byte == b'!' {
      negative = true
      offset += 1
      break
    } else if !cli_query_assertion_whitespace_byte(byte) {
      break
    }
    offset += 1
  }
  while offset < text.length() &&
        !cli_query_assertion_capture_name_byte(text[offset]) {
    offset += 1
  }
  let name_start = offset
  while offset < text.length() &&
        cli_query_assertion_capture_name_byte(text[offset]) {
    offset += 1
  }
  if name_start == offset {
    None
  } else {
    Some({
      position,
      length,
      negative,
      expected_capture_name: @utf8.decode_lossy(text[name_start:offset]),
    })
  }
}

///|
fn cli_query_assertion_whitespace_byte(byte : Byte) -> Bool {
  byte == b' ' || byte == b'\t' || byte == b'\n' || byte == b'\r'
}

///|
fn cli_query_assertion_capture_name_byte(byte : Byte) -> Bool {
  (byte >= b'a' && byte <= b'z') ||
  (byte >= b'A' && byte <= b'Z') ||
  (byte >= b'0' && byte <= b'9') ||
  byte == b'_' ||
  byte == b'-' ||
  byte == b'.'
}

///|
fn adjust_cli_query_assertions(
  source : Bytes,
  assertions : Array[CliQueryAssertion],
  ranges : Array[CliQueryAssertionRange],
) -> Result[Array[CliQueryAssertion], String] {
  let line_lengths = cli_query_source_line_lengths(source)
  let adjusted : Array[CliQueryAssertion] = []
  for assertion in assertions {
    let original = assertion.position
    let mut row = assertion.position.row
    while cli_query_assertion_needs_row_adjustment(
            row,
            assertion.position.column,
            ranges,
            line_lengths,
          ) {
      if row == 0U {
        return Err(
          "Error: could not find a line that corresponds to the assertion `\{assertion.expected_capture_name}` located at \{render_cli_query_point(original)}",
        )
      }
      row -= 1U
    }
    adjusted.push({
      ..assertion,
      position: @api.Point::new(row~, column=assertion.position.column),
    })
  }
  adjusted.sort_by((left, right) => {
    cli_query_point_compare(left.position, right.position)
  })
  Ok(adjusted)
}

///|
fn cli_query_source_line_lengths(source : Bytes) -> Array[UInt] {
  let lengths : Array[UInt] = []
  let mut line_start = 0
  let mut offset = 0
  while offset < source.length() {
    if source[offset] == b'\n' {
      lengths.push(cli_query_utf8_grapheme_length(source[line_start:offset]))
      line_start = offset + 1
    }
    offset += 1
  }
  lengths.push(cli_query_utf8_grapheme_length(source[line_start:]))
  lengths
}

///|
fn cli_query_assertion_needs_row_adjustment(
  row : UInt,
  column : UInt,
  ranges : Array[CliQueryAssertionRange],
  line_lengths : Array[UInt],
) -> Bool {
  cli_query_assertion_row_is_in_ranges(row, ranges) ||
  cli_query_assertion_line_too_short(row, column, line_lengths)
}

///|
fn cli_query_assertion_row_is_in_ranges(
  row : UInt,
  ranges : Array[CliQueryAssertionRange],
) -> Bool {
  for range in ranges {
    if range.start.row <= row && row <= range.end.row {
      return true
    }
  }
  false
}

///|
fn cli_query_assertion_line_too_short(
  row : UInt,
  column : UInt,
  line_lengths : Array[UInt],
) -> Bool {
  let index = row.reinterpret_as_int()
  if index < 0 || index >= line_lengths.length() {
    true
  } else {
    line_lengths[index] <= column
  }
}

///|
fn cli_query_assertion_error(
  assertion : CliQueryAssertion,
  captures : Array[CliQueryCaptureInfo],
) -> String? {
  if assertion.negative {
    match find_cli_query_matching_capture(assertion, captures) {
      Some(_) =>
        Some(
          "Assertion failed: expected no \{assertion.expected_capture_name} at row \{assertion.position.row}, column \{cli_query_assertion_end_column(assertion)}",
        )
      None => None
    }
  } else {
    match find_cli_query_covering_capture(assertion, captures) {
      Some(found) =>
        if cli_query_capture_name_matches(assertion, found) {
          None
        } else {
          Some(
            "Assertion failed: at \{render_cli_query_point(found.start)}, found \{found.name}, expected \{assertion.expected_capture_name}",
          )
        }
      None =>
        Some(
          "Assertion failed: could not match \{assertion.expected_capture_name} at row \{assertion.position.row}, column \{cli_query_assertion_end_column(assertion)}",
        )
    }
  }
}

///|
fn find_cli_query_covering_capture(
  assertion : CliQueryAssertion,
  captures : Array[CliQueryCaptureInfo],
) -> CliQueryCaptureInfo? {
  for capture in captures {
    if cli_query_capture_covers_assertion(capture, assertion) {
      return Some(capture)
    }
  }
  None
}

///|
fn find_cli_query_matching_capture(
  assertion : CliQueryAssertion,
  captures : Array[CliQueryCaptureInfo],
) -> CliQueryCaptureInfo? {
  for capture in captures {
    if cli_query_capture_covers_assertion(capture, assertion) &&
      cli_query_capture_name_matches(assertion, capture) {
      return Some(capture)
    }
  }
  None
}

///|
fn cli_query_capture_covers_assertion(
  capture : CliQueryCaptureInfo,
  assertion : CliQueryAssertion,
) -> Bool {
  assertion.position.gte(capture.start) &&
  (
    assertion.position.row < capture.end.row ||
    cli_query_assertion_end_column(assertion) < capture.end.column
  )
}

///|
fn cli_query_captures_with_utf8_columns(
  source : Bytes,
  captures : Array[CliQueryCaptureInfo],
) -> Array[CliQueryCaptureInfo] {
  let converted : Array[CliQueryCaptureInfo] = []
  for capture in captures {
    converted.push({
      ..capture,
      start: cli_query_point_with_utf8_column(source, capture.start),
      end: cli_query_point_with_utf8_column(source, capture.end),
    })
  }
  converted
}

///|
fn cli_query_point_with_utf8_column(
  source : Bytes,
  point : @api.Point,
) -> @api.Point {
  match cli_query_line_prefix_view(source, point.row, point.column) {
    Some(prefix) =>
      @api.Point::new(
        row=point.row,
        column=cli_query_utf8_grapheme_length(prefix),
      )
    None => point
  }
}

///|
fn cli_query_line_prefix_view(
  source : Bytes,
  row : UInt,
  byte_column : UInt,
) -> BytesView? {
  let mut current_row = 0U
  let mut line_start = 0
  let mut offset = 0
  while offset < source.length() && current_row < row {
    if source[offset] == b'\n' {
      current_row += 1U
      line_start = offset + 1
    }
    offset += 1
  }
  if current_row != row {
    return None
  }
  let mut line_end = line_start
  while line_end < source.length() && source[line_end] != b'\n' {
    line_end += 1
  }
  let column = byte_column.reinterpret_as_int()
  if column < 0 {
    return None
  }
  let prefix_end = Int::min(line_start + column, line_end)
  Some(source[line_start:prefix_end])
}

///|
fn cli_query_utf8_grapheme_length(bytes : BytesView) -> UInt {
  let mut count = 0U
  for _char in @utf8.decode_lossy(bytes) {
    count += 1U
  }
  count
}

///|
fn cli_query_capture_name_matches(
  assertion : CliQueryAssertion,
  capture : CliQueryCaptureInfo,
) -> Bool {
  assertion.expected_capture_name == capture.name || capture.name == "name"
}

///|
fn cli_query_assertion_end_column(assertion : CliQueryAssertion) -> UInt {
  assertion.position.column + assertion.length - 1U
}

///|
fn cli_query_point_compare(left : @api.Point, right : @api.Point) -> Int {
  if left.row < right.row {
    -1
  } else if left.row > right.row {
    1
  } else if left.column < right.column {
    -1
  } else if left.column > right.column {
    1
  } else {
    0
  }
}

///|
fn render_cli_query_point(point : @api.Point) -> String {
  "(\{point.row}, \{point.column})"
}
