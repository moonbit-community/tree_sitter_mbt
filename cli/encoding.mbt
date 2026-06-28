///|
pub(all) suberror CliEncodingError {
  UnknownEncoding(String)
} derive(Eq, Debug)

///|
pub fn parse_cli_input_encoding(
  name : String,
) -> @api.InputEncoding raise CliEncodingError {
  match name {
    "utf8" => Utf8
    "utf16-le" => Utf16LE
    "utf16-be" => Utf16BE
    _ => raise CliEncodingError::UnknownEncoding(name)
  }
}

///|
pub fn detect_utf16_bom_encoding(bytes : Bytes) -> @api.InputEncoding? {
  match bytes {
    [b'\xFF', b'\xFE', ..] => Some(Utf16LE)
    [b'\xFE', b'\xFF', ..] => Some(Utf16BE)
    _ => None
  }
}

///|
pub fn select_cli_input_encoding(
  bytes : Bytes,
  requested? : @api.InputEncoding,
) -> @api.InputEncoding {
  match requested {
    Some(encoding) => encoding
    None =>
      match detect_utf16_bom_encoding(bytes) {
        Some(encoding) => encoding
        None => Utf8
      }
  }
}

///|
pub fn cli_input_from_bytes(
  bytes : Bytes,
  requested? : @api.InputEncoding,
) -> @tree_sitter_mbt.Input {
  let encoding = match requested {
    Some(encoding) => select_cli_input_encoding(bytes, requested=encoding)
    None => select_cli_input_encoding(bytes)
  }
  @tree_sitter_mbt.Input::from_bytes(bytes, encoding~)
}
