///|
pub(all) struct LanguageMetadata {
  major : Int
  minor : Int
  patch : Int
} derive(Eq, Debug)

///|
pub fn LanguageMetadata::new(
  major~ : Int,
  minor~ : Int,
  patch~ : Int,
) -> LanguageMetadata {
  { major, minor, patch }
}

///|
pub fn LanguageMetadata::zero() -> LanguageMetadata {
  { major: 0, minor: 0, patch: 0 }
}
