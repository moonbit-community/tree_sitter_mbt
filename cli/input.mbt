///|
pub(all) suberror CliInputError {
  EmptyPathSelection
} derive(Eq, Debug)

///|
pub(all) enum CliInputSource {
  Stdin
  Paths(Array[String])
  TestNumber(UInt)
} derive(Eq, Debug)

///|
pub(all) struct CliPathExpansion {
  argument : String
  paths : Array[String]
} derive(Eq, Debug)

///|
pub fn parse_paths_file_contents(contents : String) -> Array[String] {
  let trimmed = contents.trim().to_owned()
  if trimmed == "" {
    []
  } else {
    let paths : Array[String] = []
    for line in trimmed.split("\n") {
      paths.push(line.to_owned())
    }
    paths
  }
}

///|
pub fn normalize_test_number(test_number : UInt) -> UInt {
  if test_number == 0 {
    1
  } else {
    test_number
  }
}

///|
pub fn select_input_source(
  paths_file_contents? : String,
  positional_paths? : Array[CliPathExpansion],
  test_number? : UInt,
) -> CliInputSource raise CliInputError {
  match paths_file_contents {
    Some(contents) => Paths(parse_paths_file_contents(contents))
    None =>
      match test_number {
        Some(number) => TestNumber(normalize_test_number(number))
        None =>
          match positional_paths {
            Some(paths) => Paths(resolve_positional_paths(paths))
            None => Stdin
          }
      }
  }
}

///|
pub fn resolve_positional_paths(
  expansions : Array[CliPathExpansion],
) -> Array[String] raise CliInputError {
  let result : Array[String] = []
  for expansion in expansions {
    if expansion.argument.has_prefix("!") {
      for path in expansion.paths {
        remove_first_path(result, path)
      }
    } else {
      for path in expansion.paths {
        result.push(path)
      }
    }
  }
  if result.is_empty() {
    raise CliInputError::EmptyPathSelection
  }
  result
}

///|
fn remove_first_path(paths : Array[String], target : String) -> Unit {
  let mut found_index = -1
  for index, path in paths {
    if found_index == -1 && path == target {
      found_index = index
    }
  }
  if found_index >= 0 {
    paths.remove(found_index) |> ignore
  }
}
