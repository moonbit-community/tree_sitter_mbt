///|
async fn read_cli_grammar_json_from_path(
  grammar_path : String,
  js_runtime? : String? = None,
) -> String {
  if grammar_path.has_suffix(".json") {
    read_cli_file_string(grammar_path)
  } else if grammar_path.has_suffix(".js") {
    read_cli_grammar_js(grammar_path, js_runtime~)
  } else {
    raise CliFileIoError::UnsupportedGrammarFileExtension(path=grammar_path)
  }
}

///|
async fn read_cli_grammar_js(
  grammar_path : String,
  js_runtime? : String? = None,
) -> String {
  let runtime = cli_effective_js_runtime(js_runtime)
  let grammar_realpath = @fs.realpath(grammar_path) catch {
    err =>
      raise CliFileIoError::GrammarJsLoadFailed(
        path=grammar_path,
        runtime~,
        status=-1,
        stderr=render_cli_file_io_reason(err),
      )
  }
  @async.with_task_group() <| group => {
    let dsl_dir = @fs.tmpdir(prefix="tree-sitter-mbt-dsl")
    group.add_defer(() => {
      @async.protect_from_cancel(() => @fs.rmdir(dsl_dir, recursive=true)) catch {
        _ => ()
      }
    })
    let dsl_path = dsl_dir + "/grammar-dsl.mjs"
    @fs.write_file(
      dsl_path,
      cli_grammar_js_dsl_source(),
      create_mode=CreateOrTruncate,
    ) catch {
      err =>
        raise CliFileIoError::GrammarJsLoadFailed(
          path=grammar_path,
          runtime~,
          status=-1,
          stderr=render_cli_file_io_reason(err),
        )
    }
    let (status, stdout_data, stderr_data) = @process.collect_output(
      runtime,
      [dsl_path],
      extra_env={ "TREE_SITTER_GRAMMAR_PATH": grammar_realpath },
    ) catch {
      err =>
        raise CliFileIoError::GrammarJsLoadFailed(
          path=grammar_path,
          runtime~,
          status=-1,
          stderr=render_cli_file_io_reason(err),
        )
    }
    let stdout = stdout_data.text() catch {
      err =>
        raise CliFileIoError::GrammarJsLoadFailed(
          path=grammar_path,
          runtime~,
          status~,
          stderr=render_cli_file_io_reason(err),
        )
    }
    let stderr = stderr_data.text() catch {
      err =>
        raise CliFileIoError::GrammarJsLoadFailed(
          path=grammar_path,
          runtime~,
          status~,
          stderr=render_cli_file_io_reason(err),
        )
    }
    if status != 0 {
      raise CliFileIoError::GrammarJsLoadFailed(
        path=grammar_path,
        runtime~,
        status~,
        stderr~,
      )
    }
    match cli_final_stdout_line(stdout) {
      Some(json) => json
      None =>
        raise CliFileIoError::GrammarJsLoadFailed(
          path=grammar_path,
          runtime~,
          status~,
          stderr="grammar js runtime produced no stdout",
        )
    }
  }
}

///|
fn cli_effective_js_runtime(js_runtime : String?) -> String {
  match js_runtime {
    Some(runtime) => runtime
    None =>
      match @env.get_env_var("TREE_SITTER_JS_RUNTIME") {
        Some(runtime) => runtime
        None => "node"
      }
  }
}

///|
fn cli_final_stdout_line(stdout : String) -> String? {
  let trimmed = stdout.trim_end(chars="\r\n").to_owned()
  if trimmed.is_empty() {
    None
  } else {
    match trimmed.rev_find("\n") {
      Some(index) => Some(trimmed[index + 1:].to_owned())
      None => Some(trimmed)
    }
  }
}
