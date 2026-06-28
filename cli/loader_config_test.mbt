///|
test "cli parses global config json" {
  let config = parse_cli_global_config_json(
    (
      #|{
      #|  "parser-directories": ["vendor", "grammars"],
      #|  "theme": {"attribute": "bold"}
      #|}
    ),
  )
  assert_true(config.parser_directories == ["vendor", "grammars"])
  assert_true(config.theme is Some(_))
}

///|
test "cli global config path candidates follow loader precedence" {
  let environment = CliGlobalConfigPathEnvironment::{
    tree_sitter_dir: Some("/tree-sitter-dir"),
    xdg_config_home: Some("/xdg"),
    home: Some("/home/user"),
  }
  assert_true(
    cli_global_config_path_candidates_for_environment(
      Some("/custom/config.json"),
      environment,
    ) ==
    ["/custom/config.json"],
  )
  assert_true(
    cli_global_config_path_candidates_for_environment(None, environment) ==
    [
      "/tree-sitter-dir/config.json", "/xdg/tree-sitter/config.json", "/home/user/.tree-sitter/config.json",
    ],
  )
  let without_xdg = { ..environment, xdg_config_home: None }
  assert_true(
    cli_global_config_path_candidates_for_environment(None, without_xdg) ==
    [
      "/tree-sitter-dir/config.json", "/home/user/.config/tree-sitter/config.json",
      "/home/user/.tree-sitter/config.json",
    ],
  )
}

///|
test "cli parses tree-sitter language config json" {
  let config = parse_cli_tree_sitter_config_json(
    (
      #|{
      #|  "grammars": [{
      #|    "scope": "source.mbt",
      #|    "path": ".",
      #|    "file-types": ["mbt", "moon.pkg"],
      #|    "content-regex": "module\\s+moon",
      #|    "first-line-regex": "^#!.*moonbit",
      #|    "injection-regex": "moon(bit)?",
      #|    "highlights": ["queries/highlights.scm"],
      #|    "injections": ["queries/injections.scm"],
      #|    "locals": ["queries/locals.scm"],
      #|    "tags": ["queries/tags.scm"],
      #|    "external-files": ["scanner.c"]
      #|  }]
      #|}
    ),
  )
  assert_eq(config.grammars.length(), 1)
  let grammar = config.grammars[0]
  assert_eq(grammar.scope, "source.mbt")
  assert_true(grammar.path == Some("."))
  assert_true(grammar.file_types == ["mbt", "moon.pkg"])
  assert_true(grammar.content_regex == Some("module\\s+moon"))
  assert_true(grammar.highlights == ["queries/highlights.scm"])
  assert_true(grammar.injections == ["queries/injections.scm"])
  assert_true(grammar.locals == ["queries/locals.scm"])
  assert_true(grammar.tags == ["queries/tags.scm"])
  assert_true(grammar.external_files == ["scanner.c"])
}

///|
test "cli parses tree-sitter metadata version json" {
  let metadata = parse_cli_tree_sitter_metadata_json(
    "{\"metadata\":{\"version\":\"1.2.3\"}}",
  )
  assert_eq(metadata.major, 1)
  assert_eq(metadata.minor, 2)
  assert_eq(metadata.patch, 3)

  try parse_cli_tree_sitter_metadata_json("{\"metadata\":{}}") catch {
    err => assert_true(err is MissingField(path="$.metadata", field="version"))
  } noraise {
    _ => fail("expected missing metadata version")
  }

  try
    parse_cli_tree_sitter_metadata_json(
      "{\"metadata\":{\"version\":\"1.02.3\"}}",
    )
  catch {
    err =>
      assert_true(
        err is InvalidSemanticVersion(path="$.metadata.version", value="1.02.3"),
      )
  } noraise {
    _ => fail("expected invalid metadata version")
  }
}

///|
test "cli config reports typed json errors" {
  let invalid = @test.expect_error(() => {
    parse_cli_tree_sitter_config_json("{\"grammars\":[{\"file-types\":[]}]}")
  })
  assert_true(invalid is MissingField(path="$.grammars[0]", field="scope"))
  let wrong_type = @test.expect_error(() => {
    parse_cli_global_config_json("{\"parser-directories\":\"vendor\"}")
  })
  assert_true(wrong_type is ExpectedArray("$.parser-directories"))
}

///|
test "cli file type matching prefers exact file names then longest suffix" {
  let config = CliLanguageConfig::{
    scope: "source.test",
    path: None,
    file_types: ["pkg", "moon.pkg", "d.ts", "ts"],
    content_regex: None,
    first_line_regex: None,
    injection_regex: None,
    highlights: [],
    injections: [],
    locals: [],
    tags: [],
    external_files: [],
  }
  guard cli_language_file_type_match(config, "/tmp/moon.pkg") is Some(exact) else {
    fail("expected exact filename match")
  }
  assert_true(exact.exact_filename)
  assert_eq(exact.file_type, "moon.pkg")
  guard cli_language_file_type_match(config, "types/foo.d.ts") is Some(suffix) else {
    fail("expected suffix match")
  }
  assert_true(!suffix.exact_filename)
  assert_eq(suffix.file_type, "d.ts")
}

///|
test "cli language selection applies content regex tie-breaks" {
  let base = CliLanguageConfig::{
    scope: "source.base",
    path: None,
    file_types: ["txt"],
    content_regex: None,
    first_line_regex: None,
    injection_regex: None,
    highlights: [],
    injections: [],
    locals: [],
    tags: [],
    external_files: [],
  }
  let no_match = {
    ..base,
    scope: "source.no-match",
    content_regex: Some("zzz"),
  }
  let short_match = {
    ..base,
    scope: "source.short",
    content_regex: Some("moon"),
  }
  let long_match = {
    ..base,
    scope: "source.long",
    content_regex: Some("moonbit"),
  }
  let selected = select_cli_language_config_for_file(
    [base, no_match, short_match, long_match],
    "sample.txt",
    source="moonbit module",
  )
  assert_true(selected is Some({ scope: "source.long", .. }))
  let without_source = select_cli_language_config_for_file(
    [no_match, base],
    "sample.txt",
  )
  assert_true(without_source is Some({ scope: "source.base", .. }))
}

///|
test "cli query file classification uses known suffixes" {
  assert_true(
    classify_cli_query_file_path("queries/highlights.scm")
    is CliQueryFileHighlights,
  )
  assert_true(
    classify_cli_query_file_path("queries/injections.scm")
    is CliQueryFileInjections,
  )
  assert_true(
    classify_cli_query_file_path("queries/locals.scm") is CliQueryFileLocals,
  )
  assert_true(
    classify_cli_query_file_path("queries/tags.scm") is CliQueryFileTags,
  )
  assert_true(
    classify_cli_query_file_path("queries/other.scm") is CliQueryFileOther,
  )
}

///|
test "cli injection language selection uses longest regex match" {
  let base = CliLanguageConfig::{
    scope: "source.short",
    path: None,
    file_types: [],
    content_regex: None,
    first_line_regex: None,
    injection_regex: Some("moon"),
    highlights: [],
    injections: [],
    locals: [],
    tags: [],
    external_files: [],
  }
  let longer = {
    ..base,
    scope: "source.long",
    injection_regex: Some("moonbit"),
  }
  let selected = select_cli_language_config_for_injection(
    [base, longer],
    "moonbit",
  )
  assert_true(selected is Some({ scope: "source.long", .. }))
}

///|
fn cli_selection_test_language_config(
  scope : String,
  file_types? : Array[String] = [],
  first_line_regex? : String,
) -> CliLanguageConfig {
  CliLanguageConfig::{
    scope,
    path: None,
    file_types,
    content_regex: None,
    first_line_regex,
    injection_regex: None,
    highlights: [],
    injections: [],
    locals: [],
    tags: [],
    external_files: [],
  }
}

///|
test "cli language selection applies lib path and scope priority" {
  let file_config = cli_selection_test_language_config("source.file", file_types=[
    "mbt",
  ])
  let scope_config = cli_selection_test_language_config("source.scope", file_types=[
    "mbt",
  ])
  assert_true(
    select_cli_language(
      [file_config, scope_config],
      lib_path="parser.so",
      scope="source.scope",
      file_name="sample.mbt",
    )
    is Some(CliLanguageFromLibPath("parser.so")),
  )
  let scoped = select_cli_language(
    [file_config, scope_config],
    scope="source.scope",
    file_name="sample.mbt",
  )
  assert_true(
    scoped
    is Some(
      CliLanguageFromConfig({ scope: "source.scope", .. }, CliLanguageByScope)
    ),
  )
  assert_true(
    select_cli_language(
      [file_config],
      scope="missing.scope",
      file_name="sample.mbt",
    )
    is None,
  )
}

///|
test "cli language selection uses file type before first line fallback" {
  let file_config = cli_selection_test_language_config("source.file", file_types=[
    "mbt",
  ])
  let first_line_config = cli_selection_test_language_config(
    "source.shebang",
    first_line_regex="^#!.*moonbit",
  )
  let by_file = select_cli_language(
    [first_line_config, file_config],
    file_name="sample.mbt",
    source="#!/usr/bin/env moonbit\n",
  )
  assert_true(
    by_file
    is Some(
      CliLanguageFromConfig({ scope: "source.file", .. }, CliLanguageByFileType)
    ),
  )
  let by_first_line = select_cli_language(
    [first_line_config, file_config],
    file_name="sample.unknown",
    source="#!/usr/bin/env moonbit\r\nlet x = 1",
  )
  assert_true(
    by_first_line
    is Some(
      CliLanguageFromConfig(
        { scope: "source.shebang", .. },
        CliLanguageByFirstLine
      )
    ),
  )
}

///|
test "cli locates language configs relative to parser roots" {
  let root_config = cli_selection_test_language_config("source.root")
  let nested_config = {
    ..cli_selection_test_language_config("source.nested"),
    path: Some("grammar"),
  }
  let absolute_config = {
    ..cli_selection_test_language_config("source.absolute"),
    path: Some("/opt/tree-sitter-absolute"),
  }
  let locations = locate_cli_language_configs("/repo/parser", {
    grammars: [root_config, nested_config, absolute_config],
  })
  assert_eq(locations.length(), 3)
  assert_eq(locations[0].grammar_root, "/repo/parser")
  assert_eq(locations[1].grammar_root, "/repo/parser/grammar")
  assert_eq(locations[2].grammar_root, "/opt/tree-sitter-absolute")
  assert_eq(
    cli_tree_sitter_config_path("/repo/parser"),
    "/repo/parser/tree-sitter.json",
  )
}

///|
test "cli located language selection preserves grammar root" {
  let file_config = {
    ..cli_selection_test_language_config("source.file", file_types=["mbt"]),
    path: Some("grammar/file"),
  }
  let first_line_config = {
    ..cli_selection_test_language_config(
      "source.shebang",
      first_line_regex="^#!.*moonbit",
    ),
    path: Some("grammar/shebang"),
  }
  let locations = locate_cli_language_configs("/repo/parser", {
    grammars: [first_line_config, file_config],
  })
  let by_file = select_cli_language_location(
    locations,
    file_name="sample.mbt",
    source="#!/usr/bin/env moonbit\n",
  )
  assert_true(
    by_file
    is Some(
      CliLocatedLanguageFromConfig(
        { grammar_root: "/repo/parser/grammar/file", .. },
        CliLanguageByFileType
      )
    ),
  )
  let by_first_line = select_cli_language_location(
    locations,
    file_name="sample.unknown",
    source="#!/usr/bin/env moonbit\n",
  )
  assert_true(
    by_first_line
    is Some(
      CliLocatedLanguageFromConfig(
        { grammar_root: "/repo/parser/grammar/shebang", .. },
        CliLanguageByFirstLine
      )
    ),
  )
}

///|
test "cli first line language selection reports invalid regex" {
  let config = cli_selection_test_language_config(
    "source.bad",
    first_line_regex="[",
  )
  let result = @test.expect_error(() => {
    select_cli_language_config_for_first_line(
      [config],
      "#!/usr/bin/env moonbit",
    )
  })
  assert_true(
    result is InvalidRegex(path="$.grammars[].first-line-regex", pattern="["),
  )
}
