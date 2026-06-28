///|
test "cli corpus parser parses examples and normalizes sexp" {
  let parsed = parse_corpus_file_contents(
    "corpus.txt",
    (
      #|===============
      #|The first test
      #|===============
      #|
      #|a b c
      #|
      #|---
      #|
      #|(a
      #|    (b c))
      #|
      #|================
      #|The second test
      #|================
      #|d
      #|---
      #|(d)
    ),
  )
  assert_eq(parsed.name, "corpus.txt")
  assert_eq(parsed.examples.length(), 2)
  let first = parsed.examples[0]
  assert_eq(first.name, "The first test")
  assert_true(first.input == b"\na b c\n")
  assert_eq(first.output, "(a (b c))")
  assert_eq(first.header_delim_len, 15)
  assert_eq(first.divider_delim_len, 3)
  assert_true(!first.has_fields)

  let second = parsed.examples[1]
  assert_eq(second.name, "The second test")
  assert_true(second.input == b"d")
  assert_eq(second.output, "(d)")
}

///|
test "cli corpus parser prefers longest later divider" {
  let parsed = parse_corpus_file_contents(
    "corpus.txt",
    (
      #|==================
      #|Code with dashes
      #|==================
      #|abc
      #|---
      #|defg
      #|----
      #|hijkl
      #|-------
      #|
      #|(a (b))
    ),
  )
  assert_eq(parsed.examples.length(), 1)
  let example = parsed.examples[0]
  assert_true(example.input == b"abc\n---\ndefg\n----\nhijkl")
  assert_eq(example.output, "(a (b))")
  assert_eq(example.divider_delim_len, 7)
}

///|
test "cli corpus parser handles attributes and cst output" {
  let parsed = parse_corpus_file_contents(
    "corpus.txt",
    (
      #|=========================
      #|Test with platform marker
      #|:platform(test-os)
      #|:fail-fast
      #|=========================
      #|a
      #|---
      #|(b)
      #|
      #|====================
      #|Test with cst marker
      #|:cst
      #|:language(foo)
      #|====================
      #|1
      #|---
      #|0:0 - 0:1   number `1`
    ),
    current_platform="test-os",
  )
  assert_eq(parsed.examples.length(), 2)
  let platform = parsed.examples[0]
  assert_eq(platform.attributes_str, ":platform(test-os)\n:fail-fast")
  assert_true(platform.attributes.platform)
  assert_true(platform.attributes.fail_fast)
  assert_true(platform.attributes.expectation is Pass)
  assert_true(platform.attributes.languages == [""])

  let cst = parsed.examples[1]
  assert_true(cst.attributes.cst)
  assert_true(cst.attributes.languages == ["foo"])
  assert_eq(cst.output, "0:0 - 0:1   number `1`")
  assert_true(!cst.has_fields)
}

///|
test "cli corpus parser respects delimiter suffix" {
  let parsed = parse_corpus_file_contents(
    "corpus.txt",
    (
      #|=== js
      #|Suffix test
      #|=== js
      #|a
      #|--- other
      #|literal
      #|--- js
      #|(ok)
      #|
      #|=== js
      #|Trailing header without divider
      #|=== js
    ),
  )
  assert_eq(parsed.examples.length(), 1)
  let example = parsed.examples[0]
  assert_true(example.input == b"a\n--- other\nliteral")
  assert_eq(example.output, "(ok)")
}

///|
test "cli corpus sexp normalization strips comments and detects fields" {
  let normalized = normalize_corpus_sexp_output(
    (
      #|; comment
      #|(root
      #|  field: (item )
      #|)
    ),
  )
  assert_eq(normalized.output, "(root field: (item))")
  assert_true(normalized.has_fields)
}
