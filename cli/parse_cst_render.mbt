///|
pub fn render_parse_cst_tree(
  source : Bytes,
  tree : @tree_sitter_mbt.Tree,
  no_ranges? : Bool = false,
) -> String {
  render_parse_cst_cursor(source, tree.walk(), no_ranges~)
}

///|
pub fn render_parse_cst_cursor(
  source : Bytes,
  cursor : @tree_sitter_mbt.TreeCursor,
  no_ranges? : Bool = false,
) -> String {
  let out = StringBuilder::new()
  let total_width = cst_total_range_width(source)
  let mut current = cursor
  let mut indent_level = if no_ranges { 0 } else { 1 }
  let mut did_visit_children = false
  let mut done = false
  while !done {
    if did_visit_children {
      match current.goto_next_sibling() {
        Some(next) => {
          current = next
          did_visit_children = false
        }
        None =>
          match current.goto_parent() {
            Some(parent) => {
              current = parent
              did_visit_children = true
              indent_level -= 1
            }
            None => done = true
          }
      }
    } else {
      write_cst_node(
        out,
        current,
        source,
        total_width,
        indent_level,
        no_ranges~,
      )
      match current.goto_first_child() {
        Some(child) => {
          current = child
          did_visit_children = false
          indent_level += 1
        }
        None => did_visit_children = true
      }
    }
  }
  out.to_string()
}

///|
fn write_cst_node(
  out : StringBuilder,
  cursor : @tree_sitter_mbt.TreeCursor,
  source : Bytes,
  total_width : Int,
  indent_level : Int,
  no_ranges~ : Bool,
) -> Unit {
  let node = cursor.current_node()
  if !no_ranges {
    write_cst_range(out, node.start_point(), node.end_point(), total_width)
  }
  write_parse_indent(out, indent_level)
  if node.is_named() {
    match cursor.current_field_name() {
      Some(field_name) => {
        out.write_string(field_name)
        out.write_string(": ")
      }
      None => ()
    }
    if node.has_error() || node.is_error() {
      out.write_string("•")
    }
    out.write_string(node.type_())
    if node.child_count() == 0 {
      out.write_char(' ')
      out.write_char('`')
      write_cst_escaped_text(out, source_text_for_node(source, node))
      out.write_char('`')
    }
  } else if node.is_missing() {
    out.write_string("MISSING: \"")
    write_cst_escaped_text(out, node.type_())
    out.write_char('"')
  } else {
    out.write_char('"')
    write_cst_escaped_text(out, node.type_())
    out.write_char('"')
  }
  out.write_char('\n')
}

///|
fn source_text_for_node(source : Bytes, node : @tree_sitter_mbt.Node) -> String {
  let start = node.start_byte().reinterpret_as_int()
  let end = node.end_byte().reinterpret_as_int()
  match source.get_view(start~, end~) {
    Some(view) => @utf8.decode_lossy(view)
    None => ""
  }
}

///|
fn write_cst_range(
  out : StringBuilder,
  start : @api.Point,
  end : @api.Point,
  total_width : Int,
) -> Unit {
  out.write_string(start.row.to_string())
  out.write_char(':')
  out.write_string(start.column.to_string())
  write_cst_padding(out, cst_remaining_width(total_width, start))
  out.write_string("- ")
  out.write_string(end.row.to_string())
  out.write_char(':')
  out.write_string(end.column.to_string())
  write_cst_padding(out, cst_remaining_width(total_width, end))
}

///|
fn write_cst_padding(out : StringBuilder, width : Int) -> Unit {
  for _ in 0..<width {
    out.write_char(' ')
  }
}

///|
fn cst_remaining_width(total_width : Int, point : @api.Point) -> Int {
  let remaining = total_width -
    cst_digit_extra(point.row.reinterpret_as_int()) -
    cst_digit_extra(point.column.reinterpret_as_int())
  if remaining < 1 {
    1
  } else {
    remaining
  }
}

///|
fn cst_total_range_width(source : Bytes) -> Int {
  let mut max_width = 1
  let mut row = 0
  let mut column = 0
  for _, byte in source {
    if byte == b'\n' {
      let width = cst_digit_extra(row) + cst_digit_extra(column) + 1
      if width > max_width {
        max_width = width
      }
      row += 1
      column = 0
    } else {
      column += 1
    }
  }
  let width = cst_digit_extra(row) + cst_digit_extra(column) + 1
  if width > max_width {
    width
  } else {
    max_width
  }
}

///|
fn cst_digit_extra(value : Int) -> Int {
  let mut extra = 0
  let mut remaining = value
  while remaining >= 10 {
    extra += 1
    remaining /= 10
  }
  extra
}

///|
fn write_cst_escaped_text(out : StringBuilder, text : String) -> Unit {
  for char in text {
    match escape_parse_problem_char(char) {
      Some(escaped) => out.write_string(escaped)
      None =>
        match char {
          '"' => out.write_string("\\\"")
          '`' => out.write_string("\\`")
          _ => out.write_char(char)
        }
    }
  }
}
