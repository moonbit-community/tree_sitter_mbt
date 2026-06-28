///|
fn cli_corpus_run_pair_parser() -> @tree_sitter_mbt.Parser raise {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(cli_parse_pair_language())
  parser
}

///|
fn cli_corpus_run_diagnostics_parser() -> @tree_sitter_mbt.Parser raise {
  let parser = @tree_sitter_mbt.Parser::new()
  parser.set_language(cli_parse_diagnostics_language())
  parser
}

///|
test "cli corpus correction preserves parsed delimiter and attributes" {
  let file = parse_corpus_file_contents(
    "sample",
    (
      #|======
      #|Correction target
      #|:cst
      #|======
      #|ab
      #|-----
      #|old output
      #|
    ),
  )
  let correction = cli_corpus_correction_from_example(
    file.examples[0],
    output="  new output\n",
  )
  assert_eq(correction.name, "Correction target")
  assert_eq(correction.input, "ab")
  assert_eq(correction.output, "  new output\n")
  assert_eq(correction.attributes_str, ":cst")
  assert_eq(correction.header_delim_len, 6)
  assert_eq(correction.divider_delim_len, 5)
  assert_eq(
    render_cli_corpus_corrections([correction]),
    (
      #|======
      #|Correction target
      #|:cst
      #|======
      #|ab
      #|-----
      #|
      #|new output
      #|
    ),
  )
}

///|
test "cli corpus correction renderer separates multiple entries" {
  let rendered = render_cli_corpus_corrections([
    CliCorpusCorrection::{
      name: "first",
      input: "input 1",
      output: "output 1",
      attributes_str: "",
      header_delim_len: 4,
      divider_delim_len: 3,
    },
    CliCorpusCorrection::{
      name: "second",
      input: "input 2",
      output: "output 2",
      attributes_str: ":error",
      header_delim_len: 5,
      divider_delim_len: 4,
    },
  ])
  assert_eq(
    rendered,
    (
      #|====
      #|first
      #|====
      #|input 1
      #|---
      #|
      #|output 1
      #|
      #|=====
      #|second
      #|:error
      #|=====
      #|input 2
      #|----
      #|
      #|output 2
      #|
    ),
  )
}

///|
test "cli corpus sexp formatter mirrors upstream examples" {
  assert_eq(format_cli_corpus_sexp(""), "")
  assert_eq(
    format_cli_corpus_sexp("(a b: (c) (d) e: (f (g (h (MISSING i)))))"),
    (
      #|(a
      #|  b: (c)
      #|  (d)
      #|  e: (f
      #|    (g
      #|      (h
      #|        (MISSING i)))))
    ),
  )
  assert_eq(
    format_cli_corpus_sexp("(program (ERROR (UNEXPECTED ' ')) (identifier))"),
    (
      #|(program
      #|  (ERROR
      #|    (UNEXPECTED ' '))
      #|  (identifier))
    ),
  )
  assert_eq(
    format_cli_corpus_sexp("(source_file (MISSING \")\"))"),
    (
      #|(source_file
      #|  (MISSING ")"))
    ),
  )
}

///|
test "cli corpus update plan writes actual output for clean mismatch" {
  let parser = cli_corpus_run_pair_parser()
  let file = parse_corpus_file_contents(
    "sample",
    (
      #|===
      #|Needs update
      #|===
      #|ab
      #|---
      #|(wrong)
      #|
    ),
  )
  let plan = plan_cli_corpus_update(parser, file)
  assert_true(plan.can_update)
  assert_true(!plan.has_unexpected_parse_errors)
  assert_eq(plan.results.length(), 1)
  assert_true(plan.results[0].status is CorpusRunFailed)
  assert_eq(plan.corrections.length(), 1)
  assert_eq(
    render_cli_corpus_corrections(plan.corrections),
    (
      #|===
      #|Needs update
      #|===
      #|ab
      #|---
      #|
      #|(document
      #|  (item))
      #|
    ),
  )
}

///|
test "cli corpus update plan blocks unexpected parse errors" {
  let parser = cli_corpus_run_diagnostics_parser()
  let file = parse_corpus_file_contents(
    "sample",
    (
      #|===
      #|Unexpected error
      #|===
      #|x
      #|---
      #|(document)
      #|
    ),
  )
  let plan = plan_cli_corpus_update(parser, file)
  assert_true(!plan.can_update)
  assert_true(plan.has_unexpected_parse_errors)
  assert_eq(plan.results.length(), 1)
  assert_true(plan.results[0].status is CorpusRunFailed)
  assert_eq(
    render_cli_corpus_corrections(plan.corrections),
    (
      #|===
      #|Unexpected error
      #|===
      #|x
      #|---
      #|
      #|(document)
      #|
    ),
  )
}

///|
test "cli corpus update plan preserves filtered and fail-fast tail entries" {
  let parser = cli_corpus_run_pair_parser()
  let file = parse_corpus_file_contents(
    "sample",
    (
      #|===
      #|Filtered out
      #|===
      #|ab
      #|---
      #|(wrong)
      #|===
      #|Stop here
      #|:fail-fast
      #|===
      #|ab
      #|---
      #|(wrong)
      #|===
      #|Tail preserved
      #|===
      #|ab
      #|---
      #|(wrong_tail)
      #|
    ),
  )
  let plan = plan_cli_corpus_update(parser, file, exclude_pattern="Filtered")
  assert_true(plan.can_update)
  assert_true(plan.stopped_on_fail_fast)
  assert_eq(plan.results.length(), 1)
  assert_eq(plan.corrections.length(), 3)
  assert_eq(plan.corrections[0].name, "Filtered out")
  assert_eq(plan.corrections[0].output, "(wrong)")
  assert_eq(plan.corrections[1].name, "Stop here")
  assert_eq(plan.corrections[1].output, "(document\n  (item))")
  assert_eq(plan.corrections[2].name, "Tail preserved")
  assert_eq(plan.corrections[2].output, "(wrong_tail)")
}

///|
test "cli corpus update plan preserves error expectations" {
  let parser = cli_corpus_run_diagnostics_parser()
  let file = parse_corpus_file_contents(
    "sample",
    (
      #|===
      #|Missing expected error
      #|:error
      #|===
      #|a
      #|---
      #|(ignored)
      #|
    ),
  )
  let plan = plan_cli_corpus_update(parser, file)
  assert_true(plan.can_update)
  assert_true(!plan.has_unexpected_parse_errors)
  assert_eq(plan.results.length(), 1)
  assert_true(plan.results[0].status is CorpusRunFailed)
  assert_eq(plan.corrections[0].output, "(ignored)")
}

///|
test "cli corpus runner strips fields unless expected output keeps them" {
  let parser = cli_corpus_run_pair_parser()
  let file = parse_corpus_file_contents(
    "sample",
    (
      #|===
      #|Field-free expected
      #|===
      #|ab
      #|---
      #|(document (item))
      #|
    ),
    file_name="corpus.txt",
  )
  let results = run_cli_corpus_file(parser, file)
  assert_eq(results.length(), 1)
  let result = results[0]
  assert_true(result.status is CorpusRunPassed)
  assert_eq(result.expected, "(document (item))")
  assert_eq(result.actual, "(document (item))")
  assert_true(!result.has_parse_error)
  assert_true(result.file_name == Some("corpus.txt"))
  assert_true(!cli_corpus_run_results_have_failure(results))
  assert_eq(cli_corpus_run_exit_code(results), 0)
}

///|
test "cli corpus runner show_fields keeps fields for comparison" {
  let parser = cli_corpus_run_pair_parser()
  let file = parse_corpus_file_contents(
    "sample",
    (
      #|===
      #|Field-free expected
      #|===
      #|ab
      #|---
      #|(document (item))
      #|
    ),
  )
  let results = run_cli_corpus_file(parser, file, show_fields=true)
  assert_eq(results.length(), 1)
  let result = results[0]
  assert_true(result.status is CorpusRunFailed)
  assert_eq(result.expected, "(document (item))")
  assert_eq(result.actual, "(document left: (item))")
  assert_true(cli_corpus_run_results_have_failure(results))
  assert_eq(cli_corpus_run_exit_code(results), 1)
}

///|
test "cli corpus runner compares cst output" {
  let parser = cli_corpus_run_pair_parser()
  let file = parse_corpus_file_contents(
    "sample",
    (
      #|===
      #|CST expected
      #|:cst
      #|===
      #|ab
      #|---
      #|0:0 - 0:2   document
      #|0:0 - 0:1     left: item `a`
      #|0:1 - 0:2     "b"
      #|
    ),
  )
  let result = run_cli_corpus_example(parser, file.examples[0])
  assert_true(result.status is CorpusRunPassed)
  assert_true(result.is_cst)
  assert_eq(result.actual, file.examples[0].output)
}

///|
test "cli corpus runner handles error expectations" {
  let parser = cli_corpus_run_diagnostics_parser()
  let file = parse_corpus_file_contents(
    "sample",
    (
      #|===
      #|Expected error
      #|:error
      #|===
      #|x
      #|---
      #|(ignored)
      #|===
      #|Missing expected error
      #|:error
      #|===
      #|a
      #|---
      #|(ignored)
      #|
    ),
  )
  let passing = run_cli_corpus_example(parser, file.examples[0])
  assert_true(passing.status is CorpusRunPassed)
  assert_true(passing.has_parse_error)
  assert_eq(passing.expected, "ERROR")
  assert_eq(passing.actual, "(document (UNEXPECTED 'x') (MISSING \"a\"))")
  let failing = run_cli_corpus_example(parser, file.examples[1])
  assert_true(failing.status is CorpusRunFailed)
  assert_true(!failing.has_parse_error)
  assert_eq(failing.expected, "NO ERROR")
  assert_eq(failing.actual, "(document)")
}

///|
test "cli corpus runner returns skip and platform outcomes" {
  let parser = cli_corpus_run_pair_parser()
  let file = parse_corpus_file_contents(
    "sample",
    (
      #|===
      #|Explicit skip
      #|:skip
      #|===
      #|ab
      #|---
      #|(document (item))
      #|===
      #|Wrong platform
      #|:platform(windows)
      #|===
      #|ab
      #|---
      #|(document (item))
      #|
    ),
    current_platform="linux",
  )
  let results = run_cli_corpus_file(parser, file)
  assert_eq(results.length(), 2)
  assert_true(results[0].status is CorpusRunSkipped)
  assert_true(results[1].status is CorpusRunPlatformSkipped)
  assert_true(!cli_corpus_run_results_have_failure(results))
}

///|
test "cli corpus runner filters examples and honors fail fast" {
  let parser = cli_corpus_run_pair_parser()
  let file = parse_corpus_file_contents(
    "sample",
    (
      #|===
      #|First failure
      #|:fail-fast
      #|===
      #|ab
      #|---
      #|(wrong)
      #|===
      #|Second pass
      #|===
      #|ab
      #|---
      #|(document (item))
      #|
    ),
    file_name="corpus.txt",
  )
  assert_true(
    cli_corpus_example_is_selected(file.examples[0], include_pattern="First"),
  )
  assert_true(
    !cli_corpus_example_is_selected(file.examples[1], exclude_pattern="Second"),
  )
  assert_true(
    cli_corpus_example_is_selected(
      file.examples[0],
      include_pattern="First",
      exclude_pattern="First",
    ),
  )
  assert_true(
    !cli_corpus_example_is_selected(file.examples[0], file_name="other.txt"),
  )
  let filtered = run_cli_corpus_file(parser, file, include_pattern="Second")
  assert_eq(filtered.length(), 1)
  assert_true(filtered[0].status is CorpusRunPassed)
  let fail_fast = run_cli_corpus_file(parser, file)
  assert_eq(fail_fast.length(), 1)
  assert_true(fail_fast[0].status is CorpusRunFailed)
}

///|
test "cli corpus runner fail fast stops after passing error expectation" {
  let parser = cli_corpus_run_diagnostics_parser()
  let file = parse_corpus_file_contents(
    "sample",
    (
      #|===
      #|Expected error
      #|:error
      #|:fail-fast
      #|===
      #|x
      #|---
      #|(ignored)
      #|===
      #|Second pass
      #|===
      #|a
      #|---
      #|(document)
      #|
    ),
  )
  let results = run_cli_corpus_file(parser, file)
  assert_eq(results.length(), 1)
  assert_true(results[0].status is CorpusRunPassed)
  assert_true(results[0].expectation is Error)
}

///|
test "cli corpus sexp field stripper mirrors upstream shape" {
  assert_eq(
    strip_cli_corpus_sexp_fields("(a b: (c) (d) e: (f (g field: (MISSING i))))"),
    "(a (c) (d) (f (g (MISSING i))))",
  )
  assert_eq(
    strip_cli_corpus_sexp_fields("(a keyword-like: (c) invalid-: (d) (h: (i)))"),
    "(a keyword-like: (c) invalid-: (d) (h: (i)))",
  )
}
