///|
fn highlight_test_language() -> @tree_sitter_mbt.Language raise {
  highlight_literal_test_language("highlight_test", "a")
}

///|
fn highlight_literal_test_language(
  name : String,
  literal : String,
) -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      $|{
      $|  "name": "\{name}",
      $|  "rules": {
      $|    "document": {
      $|      "type": "REPEAT",
      $|      "content": { "type": "SYMBOL", "name": "item" }
      $|    },
      $|    "item": { "type": "STRING", "value": "\{literal}" }
      $|  }
      $|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
fn highlight_scope_test_language() -> @tree_sitter_mbt.Language raise {
  let generated = @generator.generate_language(
    (
      #|{
      #|  "name": "highlight_scope_test",
      #|  "rules": {
      #|    "document": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        { "type": "SYMBOL", "name": "item" },
      #|        { "type": "SYMBOL", "name": "scope" },
      #|        { "type": "SYMBOL", "name": "item" }
      #|      ]
      #|    },
      #|    "scope": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        { "type": "STRING", "value": "[" },
      #|        { "type": "SYMBOL", "name": "item" },
      #|        { "type": "SYMBOL", "name": "item" },
      #|        { "type": "STRING", "value": "]" }
      #|      ]
      #|    },
      #|    "item": { "type": "STRING", "value": "a" }
      #|  }
      #|}
    ),
  )
  @tree_sitter_mbt.language_from_generated_tables(generated.tables)
}

///|
test "highlight emits source and highlight events for captures" {
  let config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(item) @function",
  )
  assert_eq(config.language_name(), "highlight_test")
  assert_true(config.names() == ["function"])
  assert_eq(config.highlight_pattern_start(), 0)
  assert_eq(config.injection_pattern_start(), 1)
  assert_eq(config.local_pattern_start(), 1)
  config.configure(["function"])
  let events = Highlighter::new().highlight(config, b"aa")
  assert_true(
    events ==
    [
      HighlightStart("function"),
      Source(start_byte=0U, end_byte=1U),
      HighlightEnd("function"),
      HighlightStart("function"),
      Source(start_byte=1U, end_byte=2U),
      HighlightEnd("function"),
    ],
  )
}

///|
test "highlight supports UTF-16 encoded source bytes" {
  let config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(item) @function (#eq? @function \"a\")",
  )
  config.configure(["function"])
  let little_endian_events = Highlighter::new().highlight_encoded(
    config,
    Bytes::from_array([b'a', b'\x00']),
    encoding=Utf16LE,
  )
  assert_true(
    little_endian_events ==
    [
      HighlightStart("function"),
      Source(start_byte=0U, end_byte=2U),
      HighlightEnd("function"),
    ],
  )
  let big_endian_events = Highlighter::new().highlight_encoded(
    config,
    Bytes::from_array([b'\x00', b'a']),
    encoding=Utf16BE,
  )
  assert_true(
    big_endian_events ==
    [
      HighlightStart("function"),
      Source(start_byte=0U, end_byte=2U),
      HighlightEnd("function"),
    ],
  )
  let skipped_config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(item) @function (#eq? @function \"b\")",
  )
  skipped_config.configure(["function"])
  let skipped_events = Highlighter::new().highlight_encoded(
    skipped_config,
    Bytes::from_array([b'a', b'\x00']),
    encoding=Utf16LE,
  )
  assert_true(skipped_events == [Source(start_byte=0U, end_byte=2U)])
}

///|
test "render html escapes source and highlight classes" {
  let html = render_html(
    [
      Source(start_byte=0U, end_byte=1U),
      HighlightStart("function.builtin"),
      Source(start_byte=1U, end_byte=2U),
      HighlightEnd("function.builtin"),
      Source(start_byte=2U, end_byte=4U),
    ],
    b"<a&>",
  )
  assert_eq(html, "&lt;<span class=\"function builtin\">a</span>&amp;&gt;")
}

///|
test "render html decodes UTF-16 source ranges" {
  let html = render_html(
    [
      HighlightStart("string"),
      Source(start_byte=0U, end_byte=2U),
      HighlightEnd("string"),
    ],
    Bytes::from_array([b'<', b'\x00']),
    encoding=Utf16LE,
  )
  assert_eq(html, "<span class=\"string\">&lt;</span>")
}

///|
test "highlight applies text predicates before emitting captures" {
  let config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(item) @function (#eq? @function \"nope\")",
  )
  config.configure(["function"])
  let events = Highlighter::new().highlight(config, b"a")
  assert_true(events == [Source(start_byte=0U, end_byte=1U)])
}

///|
test "highlight uses longest configured highlight name by dot parts" {
  let config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(item) @function.method.builtin",
    highlight_names=["function", "function.builtin"],
  )
  let events = Highlighter::new().highlight(config, b"a")
  assert_true(
    events ==
    [
      HighlightStart("function.builtin"),
      Source(start_byte=0U, end_byte=1U),
      HighlightEnd("function.builtin"),
    ],
  )
}

///|
test "highlight reports nonconformant capture names" {
  let config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(item) @function @custom.capture @_private @variable.member",
  )
  assert_true(
    config.names() ==
    ["function", "custom.capture", "_private", "variable.member"],
  )
  assert_true(config.nonconformant_capture_names() == ["custom.capture"])
  assert_true(
    config.nonconformant_capture_names(capture_names=[
      "function", "custom.capture", "variable.member",
    ]) ==
    [],
  )
}

///|
test "highlight skips non-local patterns for local definitions" {
  let config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(item) @variable (#is-not? local)",
    locals_query="(item) @local.definition",
  )
  config.configure(["variable"])
  let events = Highlighter::new().highlight(config, b"a")
  assert_true(events == [Source(start_byte=0U, end_byte=1U)])
}

///|
test "highlight keeps non-local patterns without local captures" {
  let config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(item) @variable (#is-not? local)",
  )
  config.configure(["variable"])
  let events = Highlighter::new().highlight(config, b"a")
  assert_true(
    events ==
    [
      HighlightStart("variable"),
      Source(start_byte=0U, end_byte=1U),
      HighlightEnd("variable"),
    ],
  )
}

///|
test "highlight references inherit local definition highlight" {
  let config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(document (item) @function (item))",
    locals_query="(document (item) @local.definition (item) @local.reference)",
  )
  config.configure(["function"])
  let events = Highlighter::new().highlight(config, b"aa")
  assert_true(
    events ==
    [
      HighlightStart("function"),
      Source(start_byte=0U, end_byte=1U),
      HighlightEnd("function"),
      HighlightStart("function"),
      Source(start_byte=1U, end_byte=2U),
      HighlightEnd("function"),
    ],
  )
}

///|
test "highlight references wait until local definition value ends" {
  let config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(document (item) @function (item))",
    locals_query="(document (item) @local.definition (item) @local.definition-value @local.reference)",
  )
  config.configure(["function"])
  let events = Highlighter::new().highlight(config, b"aa")
  assert_true(
    events ==
    [
      HighlightStart("function"),
      Source(start_byte=0U, end_byte=1U),
      HighlightEnd("function"),
      Source(start_byte=1U, end_byte=2U),
    ],
  )
}

///|
test "highlight local scopes inherit outer definitions by default" {
  let config = HighlightConfiguration::new(
    highlight_scope_test_language(),
    "highlight_scope_test",
    "(document (item) @function (scope) (item))",
    locals_query=(
      #|(document (item) @local.definition)
      #|(scope) @local.scope
      #|(scope (item) @local.reference (item) @local.reference)
      #|(document (scope) (item) @local.reference)
    ),
  )
  config.configure(["function"])
  let events = Highlighter::new().highlight(config, b"a[aa]a")
  assert_true(
    events ==
    [
      HighlightStart("function"),
      Source(start_byte=0U, end_byte=1U),
      HighlightEnd("function"),
      Source(start_byte=1U, end_byte=2U),
      HighlightStart("function"),
      Source(start_byte=2U, end_byte=3U),
      HighlightEnd("function"),
      HighlightStart("function"),
      Source(start_byte=3U, end_byte=4U),
      HighlightEnd("function"),
      Source(start_byte=4U, end_byte=5U),
      HighlightStart("function"),
      Source(start_byte=5U, end_byte=6U),
      HighlightEnd("function"),
    ],
  )
}

///|
test "highlight local scope can stop outer definition inheritance" {
  let config = HighlightConfiguration::new(
    highlight_scope_test_language(),
    "highlight_scope_test",
    "(document (item) @function (scope) (item))",
    locals_query=(
      #|(document (item) @local.definition)
      #|(scope) @local.scope (#set! local.scope-inherits false)
      #|(scope (item) @local.reference (item) @local.reference)
      #|(document (scope) (item) @local.reference)
    ),
  )
  config.configure(["function"])
  let events = Highlighter::new().highlight(config, b"a[aa]a")
  assert_true(
    events ==
    [
      HighlightStart("function"),
      Source(start_byte=0U, end_byte=1U),
      HighlightEnd("function"),
      Source(start_byte=1U, end_byte=5U),
      HighlightStart("function"),
      Source(start_byte=5U, end_byte=6U),
      HighlightEnd("function"),
    ],
  )
}

///|
test "highlight can be cancelled before parsing" {
  let config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(item) @function",
  )
  config.configure(["function"])
  let state = HighlightProgressState::new(phase=Render, current_byte_offset=9U)
  let result = @test.expect_error(() => {
    Highlighter::new().highlight(
      config,
      b"a",
      options=HighlightOptions::cancelled(state),
    )
  })
  match result {
    Cancelled(cancelled) => assert_true(cancelled == state)
    _ => fail("expected highlight cancellation")
  }
}

///|
test "highlight progress callback can cancel query execution" {
  let config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(item) @function",
  )
  config.configure(["function"])
  let result = @test.expect_error(() => {
    Highlighter::new().highlight(
      config,
      Bytes::make(150, b'a'),
      options=HighlightOptions::progress(state => state.phase == Query),
    )
  })
  match result {
    Cancelled(state) => {
      assert_true(state.phase == Query)
      assert_true(state.current_byte_offset > 0U)
    }
    _ => fail("expected query cancellation")
  }
}

///|
test "highlight progress callback can cancel rendering" {
  let config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(item) @function",
  )
  config.configure(["function"])
  let result = @test.expect_error(() => {
    Highlighter::new().highlight(
      config,
      b"a",
      options=HighlightOptions::progress(state => {
        state.phase == Render && state.current_byte_offset >= 1U
      }),
    )
  })
  match result {
    Cancelled(state) => {
      assert_true(state.phase == Render)
      assert_eq(state.current_byte_offset, 1U)
    }
    _ => fail("expected render cancellation")
  }
}

///|
test "highlight disables injection combined patterns in main query" {
  let config = HighlightConfiguration::new(
    highlight_test_language(),
    "highlight_test",
    "(item) @function (#set! injection.combined)",
    injections_query="(item) @injection.content (#set! injection.combined)",
  )
  assert_eq(config.pattern_count(), 2)
  assert_true(config.has_combined_injections_query())
  let events = Highlighter::new().highlight(config, b"a")
  assert_true(events == [Source(start_byte=0U, end_byte=1U)])
}

///|
test "highlight recursively parses injected layers" {
  let host_config = HighlightConfiguration::new(
    highlight_literal_test_language("host", "b"),
    "host",
    "(item) @variable",
    injections_query=(
      #|(item) @injection.content
      #|  (#set! injection.language "middle")
    ),
  )
  host_config.configure(["variable"])
  let middle_config = HighlightConfiguration::new(
    highlight_literal_test_language("middle", "b"),
    "middle",
    "(item) @property",
    injections_query=(
      #|(item) @injection.content
      #|  (#set! injection.language "leaf")
    ),
  )
  middle_config.configure(["property"])
  let leaf_config = HighlightConfiguration::new(
    highlight_literal_test_language("leaf", "b"),
    "leaf",
    "(item) @function",
  )
  leaf_config.configure(["function"])
  let events = Highlighter::new().highlight_with_injections(host_config, b"b", name => {
    match name {
      "middle" => Some(middle_config)
      "leaf" => Some(leaf_config)
      _ => None
    }
  })
  assert_true(
    events ==
    [
      HighlightStart("function"),
      Source(start_byte=0U, end_byte=1U),
      HighlightEnd("function"),
    ],
  )
}
