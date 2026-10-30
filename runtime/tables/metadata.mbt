///|
pub(all) struct LanguageMetadata {
  major : Int32
  minor : Int32
  patch : Int32
} derive(Eq, Debug)

///|
pub fn LanguageMetadata::new(
  major~ : Int32,
  minor~ : Int32,
  patch~ : Int32,
) -> LanguageMetadata {
  { major, minor, patch, }
}

///|
pub fn LanguageMetadata::zero() -> LanguageMetadata {
  { major: 0, minor: 0, patch: 0, }
}

///|
pub extend LanguageMetadata with Debug::{to_repr}

///|
pub extend LanguageMetadata with Eq::{not_equal, equal}
