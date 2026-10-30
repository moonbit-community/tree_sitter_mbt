///|
pub(all) suberror ScannerError {
  Failure(String)
  InvalidResult(String)
} derive(Eq, Debug)

///|
pub extend ScannerError with Debug::{to_repr}

///|
pub extend ScannerError with Eq::{not_equal, equal}
