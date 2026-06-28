///|
pub fn render_parse_normal_tree(
  tree : @tree_sitter_mbt.Tree,
  no_ranges? : Bool = false,
) -> String {
  render_parse_normal_cursor(tree.walk(), no_ranges~)
}

///|
pub fn render_parse_normal_cursor(
  cursor : @tree_sitter_mbt.TreeCursor,
  no_ranges? : Bool = false,
) -> String {
  let out = StringBuilder::new()
  let mut current = cursor
  let mut needs_newline = false
  let mut indent_level = 0
  let mut did_visit_children = false
  let mut done = false
  while !done {
    let node = current.current_node()
    let is_named = node.is_named()
    if did_visit_children {
      if is_named {
        out.write_char(')')
        needs_newline = true
      }
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
      if is_named {
        if needs_newline {
          out.write_char('\n')
        }
        write_parse_indent(out, indent_level)
        match current.current_field_name() {
          Some(field_name) => {
            out.write_string(field_name)
            out.write_string(": ")
          }
          None => ()
        }
        out.write_char('(')
        out.write_string(node.type_())
        if !no_ranges {
          write_parse_range(out, node.start_point(), node.end_point())
        }
        needs_newline = true
      }
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
  out.write_char('\n')
  out.to_string()
}

///|
fn write_parse_indent(out : StringBuilder, indent_level : Int) -> Unit {
  for _ in 0..<indent_level {
    out.write_string("  ")
  }
}

///|
fn write_parse_range(
  out : StringBuilder,
  start : @api.Point,
  end : @api.Point,
) -> Unit {
  out.write_string(
    " [\{start.row}, \{start.column}] - [\{end.row}, \{end.column}]",
  )
}
