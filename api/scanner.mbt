///|
pub(all) suberror ScannerError {
  Failure(String)
  InvalidResult(String)
} derive(Eq, Debug)
