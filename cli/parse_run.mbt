///|
pub(all) enum CliParseOutputMode {
  CliParseNormal
  CliParseCst
  CliParseQuiet
} derive(Eq, Debug)

///|
pub(all) struct CliParseResult {
  output : String
  successful : Bool
  problem : CliParseProblem?
  encoding : @api.InputEncoding
} derive(Eq, Debug)

///|
pub fn render_cli_parse_output(
  source : Bytes,
  tree : @tree_sitter_mbt.Tree,
  output? : CliParseOutputMode = CliParseNormal,
  no_ranges? : Bool = false,
) -> String {
  match output {
    CliParseNormal => render_parse_normal_tree(tree, no_ranges~)
    CliParseCst => render_parse_cst_tree(source, tree, no_ranges~)
    CliParseQuiet => ""
  }
}

///|
pub fn run_cli_parse_source(
  parser : @tree_sitter_mbt.Parser,
  source : Bytes,
  output? : CliParseOutputMode = CliParseNormal,
  no_ranges? : Bool = false,
  encoding? : @api.InputEncoding,
) -> CliParseResult raise {
  let input = match encoding {
    Some(encoding) => cli_input_from_bytes(source, requested=encoding)
    None => cli_input_from_bytes(source)
  }
  let selected_encoding = input.encoding()
  let tree = parser.parse(input)
  let problem = first_parse_problem(tree)
  {
    output: render_cli_parse_output(source, tree, output~, no_ranges~),
    successful: problem is None,
    problem,
    encoding: selected_encoding,
  }
}

///|
pub fn cli_parse_results_have_error(results : Array[CliParseResult]) -> Bool {
  for result in results {
    if !result.successful {
      return true
    }
  }
  false
}

///|
pub fn cli_parse_exit_code(results : Array[CliParseResult]) -> Int {
  if cli_parse_results_have_error(results) {
    1
  } else {
    0
  }
}
