///|
#cfg(target="native")
extern "c" fn native_exit(code : Int) = "exit"

///|
#cfg(not(target="native"))
fn native_exit(_code : Int) -> Unit {
  panic()
}

///|
async fn main {
  let result = run_tree_sitter_mbt_cli(@env.args())
  if !result.stdout.is_empty() {
    println(trim_single_trailing_newline(result.stdout))
  }
  if result.exit_code != 0 {
    native_exit(result.exit_code)
  }
}

///|
priv struct CliMainResult {
  exit_code : Int
  stdout : String
}

///|
async fn run_tree_sitter_mbt_cli(argv : Array[String]) -> CliMainResult {
  run_tree_sitter_mbt_cli_args(cli_program_args(argv))
}

///|
async fn run_tree_sitter_mbt_cli_args(args : Array[String]) -> CliMainResult {
  try @cli.parse_cli_command_args(args) catch {
    err => { exit_code: 2, stdout: "error: \{render_cli_args_error(err)}" }
  } noraise {
    command => dispatch_cli_command(command)
  }
}

///|
async fn dispatch_cli_command(command : @cli.CliCommand) -> CliMainResult {
  match command {
    CliGenerate(command) => run_generate_command(command)
    CliParse(command) => run_parse_command(command)
    CliTest(command) => run_test_command(command)
    CliQuery(command) => run_query_command(command)
    CliTags(command) => run_tags_command(command)
  }
}

///|
async fn run_generate_command(
  command : @cli.CliGenerateCommand,
) -> CliMainResult {
  try @cli_native.run_cli_generate_command_files(command) catch {
    err => { exit_code: 1, stdout: "error: \{@debug.to_string(err)}" }
  } noraise {
    result => { exit_code: 0, stdout: result.json_summary.unwrap_or("") }
  }
}

///|
async fn run_parse_command(command : @cli.CliParseCommand) -> CliMainResult {
  try @cli_native.run_cli_parse_command_loaded_files(command) catch {
    err => { exit_code: 1, stdout: "error: \{err}" }
  } noraise {
    result => { exit_code: result.exit_code, stdout: result.stdout }
  }
}

///|
async fn run_test_command(command : @cli.CliTestCommand) -> CliMainResult {
  try @cli_native.run_cli_test_command_loaded_files(command) catch {
    err => { exit_code: 1, stdout: "error: \{err}" }
  } noraise {
    result => { exit_code: result.exit_code, stdout: result.stdout }
  }
}

///|
async fn run_query_command(command : @cli.CliQueryCommand) -> CliMainResult {
  try @cli_native.run_cli_query_command_loaded_files(command) catch {
    err => { exit_code: 1, stdout: "error: \{err}" }
  } noraise {
    result => { exit_code: result.exit_code, stdout: result.stdout }
  }
}

///|
async fn run_tags_command(command : @cli.CliTagsCommand) -> CliMainResult {
  try @cli_native.run_cli_tags_command_loaded_files(command) catch {
    err => { exit_code: 1, stdout: "error: \{err}" }
  } noraise {
    result => { exit_code: result.exit_code, stdout: result.stdout }
  }
}

///|
fn cli_program_args(argv : Array[String]) -> Array[String] {
  let args : Array[String] = []
  for index in 1..<argv.length() {
    args.push(argv[index])
  }
  args
}

///|
fn render_cli_args_error(error : @cli.CliArgsError) -> String {
  match error {
    MissingCommand => "missing command"
    UnknownCommand(command) => "unknown command `\{command}`"
    UnknownOption(option) => "unknown option `\{option}`"
    MissingOptionValue(option) => "missing value for option `\{option}`"
    InvalidOptionValue(option~, value~) =>
      "invalid value `\{value}` for option `\{option}`"
    ConflictingOptions(left, right) =>
      "conflicting options `\{left}` and `\{right}`"
    UnexpectedArgument(argument) => "unexpected argument `\{argument}`"
  }
}

///|
fn trim_single_trailing_newline(text : String) -> String {
  match text.strip_suffix("\n") {
    Some(view) => view.to_owned()
    None => text
  }
}
