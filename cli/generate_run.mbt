///|
pub(all) suberror CliGenerateRunError {
  InvalidAbiVersion(String)
  UnsupportedGenerateOption(String)
  GenerateFailed(@generator.GenerateError)
} derive(Eq, Debug)

///|
pub(all) struct CliOutputFile {
  path : String
  content : String
} derive(Eq, Debug)

///|
pub(all) struct CliGenerateRunResult {
  files : Array[CliOutputFile]
  language_name : String
  abi_version : Int
  warnings : Array[@generator.GenerateWarning]
  json_summary : String?
} derive(Eq, Debug)

///|
pub fn run_cli_generate_command(
  command : CliGenerateCommand,
  grammar_json : String,
  semantic_version? : @tables.LanguageMetadata = @tables.LanguageMetadata::zero(),
  emit_grammar_json? : Bool = false,
) -> CliGenerateRunResult raise CliGenerateRunError {
  match command.report_states_for_rule {
    Some(_) =>
      raise CliGenerateRunError::UnsupportedGenerateOption(
        "--report-states-for-rule",
      )
    None => ()
  }
  let abi_version = cli_generate_abi_version(command.abi_version)
  let generated = @generator.generate_language(grammar_json, options={
    ..@generator.GenerateOptions::default(),
    abi_version,
    semantic_version: Some(semantic_version),
  }) catch {
    err => raise CliGenerateRunError::GenerateFailed(err)
  }
  let files = cli_generated_files(
    command, generated, grammar_json, emit_grammar_json,
  )
  {
    files,
    language_name: generated.language_name,
    abi_version: generated.abi_version,
    warnings: generated.warnings,
    json_summary: if command.json_summary {
      Some(cli_generate_summary_json(generated, files))
    } else {
      None
    },
  }
}

///|
fn cli_generate_abi_version(version : String?) -> Int raise CliGenerateRunError {
  match version {
    Some("latest") | None => @generator.GenerateOptions::default().abi_version
    Some(value) => cli_generate_parse_abi_version(value)
  }
}

///|
fn cli_generate_parse_abi_version(
  value : String,
) -> Int raise CliGenerateRunError {
  if value.is_empty() {
    raise CliGenerateRunError::InvalidAbiVersion(value)
  }
  let mut result = 0
  for char in value {
    let code = char.to_uint()
    if code < 48U || code > 57U {
      raise CliGenerateRunError::InvalidAbiVersion(value)
    }
    result = result * 10 + (code - 48U).reinterpret_as_int()
  }
  result
}

///|
fn cli_generated_files(
  command : CliGenerateCommand,
  generated : @generator.GeneratedLanguage,
  grammar_json : String,
  emit_grammar_json : Bool,
) -> Array[CliOutputFile] {
  let files : Array[CliOutputFile] = []
  if emit_grammar_json {
    files.push({
      path: cli_generate_output_path(command.output_dir, "grammar.json"),
      content: grammar_json,
    })
  }
  if !command.no_parser {
    for source in generated.moonbit_sources {
      files.push({
        path: cli_generate_output_path(command.output_dir, source.path),
        content: source.content,
      })
    }
  }
  files.push({
    path: cli_generate_output_path(command.output_dir, "node-types.json"),
    content: generated.node_types_json,
  })
  files
}

///|
fn cli_generate_output_path(output_dir : String?, path : String) -> String {
  match output_dir {
    Some(dir) =>
      if dir == "" || dir == "." {
        path
      } else if dir.has_suffix("/") {
        dir + path
      } else {
        dir + "/" + path
      }
    None => path
  }
}

///|
fn cli_generate_summary_json(
  generated : @generator.GeneratedLanguage,
  files : Array[CliOutputFile],
) -> String {
  [
    "{",
    "\"language\":\{cli_json_string(generated.language_name)},",
    "\"abi_version\":\{generated.abi_version},",
    "\"file_count\":\{files.length()},",
    "\"warning_count\":\{generated.warnings.length()}",
    "}",
  ].join("")
}

///|
fn cli_json_string(value : String) -> String {
  let out = StringBuilder::new()
  out.write_char('"')
  for char in value {
    match char {
      '"' => out.write_string("\\\"")
      '\\' => out.write_string("\\\\")
      '\n' => out.write_string("\\n")
      '\r' => out.write_string("\\r")
      '\t' => out.write_string("\\t")
      _ => out.write_char(char)
    }
  }
  out.write_char('"')
  out.to_string()
}
