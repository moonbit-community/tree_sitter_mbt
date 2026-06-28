///|
test "cli parses paths file contents after trim" {
  assert_true(
    parse_paths_file_contents(" \nsource/a.mbt\nsource/b.mbt\n ") ==
    ["source/a.mbt", "source/b.mbt"],
  )
  assert_true(parse_paths_file_contents("\n\t\n") == [])
}

///|
test "cli reduces positional paths with removals" {
  let paths = resolve_positional_paths([
    { argument: "src/*.mbt", paths: ["src/a.mbt", "src/b.mbt"] },
    { argument: "src/*.mbt", paths: ["src/a.mbt"] },
    { argument: "!src/a.mbt", paths: ["src/a.mbt"] },
  ])
  assert_true(paths == ["src/b.mbt", "src/a.mbt"])

  let empty = @test.expect_error(() => {
    resolve_positional_paths([
      { argument: "src/a.mbt", paths: ["src/a.mbt"] },
      { argument: "!src/a.mbt", paths: ["src/a.mbt"] },
    ])
  })
  assert_true(empty is EmptyPathSelection)
}

///|
test "cli selects input source precedence" {
  let paths_file = select_input_source(
    paths_file_contents="alpha\nbeta",
    positional_paths=[{ argument: "ignored", paths: ["ignored"] }],
    test_number=0,
  )
  guard paths_file is Paths(paths) else { fail("expected paths file source") }
  assert_true(paths == ["alpha", "beta"])

  let selected_test = select_input_source(
    positional_paths=[{ argument: "ignored", paths: ["ignored"] }],
    test_number=0,
  )
  guard selected_test is TestNumber(number) else {
    fail("expected test source")
  }
  assert_eq(number, 1)

  let positional = select_input_source(positional_paths=[
    { argument: "src/*.mbt", paths: ["src/a.mbt"] },
  ])
  guard positional is Paths(positional_paths) else {
    fail("expected positional paths source")
  }
  assert_true(positional_paths == ["src/a.mbt"])

  assert_true(select_input_source() is Stdin)
}
