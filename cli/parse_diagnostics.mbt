///|
pub(all) enum CliParseProblemKind {
  ErrorNode
  MissingNode
} derive(Eq, Debug)

///|
pub(all) struct CliParseProblem {
  kind : CliParseProblemKind
  node_type : String
  is_named : Bool
  start_byte : UInt
  end_byte : UInt
  start_point : @api.Point
  end_point : @api.Point
} derive(Eq, Debug)

///|
pub fn tree_has_parse_problem(tree : @tree_sitter_mbt.Tree) -> Bool {
  first_parse_problem(tree) is Some(_)
}

///|
pub fn first_parse_problem(tree : @tree_sitter_mbt.Tree) -> CliParseProblem? {
  first_parse_problem_node(tree.root_node())
}

///|
pub fn render_parse_problem(problem : CliParseProblem) -> String {
  let out = StringBuilder::new()
  out.write_char('(')
  write_parse_problem_label(out, problem)
  write_parse_range(out, problem.start_point, problem.end_point)
  out.write_char(')')
  out.to_string()
}

///|
fn first_parse_problem_node(node : @tree_sitter_mbt.Node) -> CliParseProblem? {
  let mut problem = parse_problem_from_node(node)
  let mut child_index = 0
  while problem is None && child_index < node.child_count() {
    problem = first_parse_problem_node(node.child(child_index))
    child_index += 1
  }
  problem
}

///|
fn parse_problem_from_node(node : @tree_sitter_mbt.Node) -> CliParseProblem? {
  if node.is_error() {
    Some(CliParseProblem::{
      kind: ErrorNode,
      node_type: node.type_(),
      is_named: node.is_named(),
      start_byte: node.start_byte(),
      end_byte: node.end_byte(),
      start_point: node.start_point(),
      end_point: node.end_point(),
    })
  } else if node.is_missing() {
    Some(CliParseProblem::{
      kind: MissingNode,
      node_type: node.type_(),
      is_named: node.is_named(),
      start_byte: node.start_byte(),
      end_byte: node.end_byte(),
      start_point: node.start_point(),
      end_point: node.end_point(),
    })
  } else {
    None
  }
}

///|
fn write_parse_problem_label(
  out : StringBuilder,
  problem : CliParseProblem,
) -> Unit {
  let node_text = escape_parse_problem_text(problem.node_type)
  match problem.kind {
    ErrorNode => out.write_string(node_text)
    MissingNode =>
      if problem.is_named {
        out.write_string("MISSING ")
        out.write_string(node_text)
      } else {
        out.write_string("MISSING \"")
        out.write_string(node_text)
        out.write_char('"')
      }
  }
}

///|
fn escape_parse_problem_text(text : String) -> String {
  let out = StringBuilder::new()
  for char in text {
    match escape_parse_problem_char(char) {
      Some(escaped) => out.write_string(escaped)
      None => out.write_char(char)
    }
  }
  out.to_string()
}

///|
fn escape_parse_problem_char(char : Char) -> String? {
  let codepoint = char.to_int()
  if codepoint == 0 {
    Some("\\0")
  } else if codepoint == 0x0b {
    Some("\\v")
  } else if codepoint == 0x0c {
    Some("\\f")
  } else {
    match char {
      '\n' => Some("\\n")
      '\r' => Some("\\r")
      '\t' => Some("\\t")
      '\\' => Some("\\\\")
      _ => None
    }
  }
}
