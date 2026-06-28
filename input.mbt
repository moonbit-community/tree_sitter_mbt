///|
struct Input {
  encoding : @api.InputEncoding
  source : String
  bytes : Bytes
  read_callback : ((UInt, @api.Point) -> InputChunk)?
  decode_callback : ((Bytes, Int) -> InputDecodeResult)?
}

///|
priv struct InputMaterialized {
  bytes : Bytes
  chunk_end_offsets : Array[Int]
}

///|
pub(all) struct InputChunk {
  chunk : Bytes?
  bytes_read : Int
} derive(Eq, Debug)

///|
pub fn InputChunk::new(chunk~ : Bytes?, bytes_read~ : Int) -> InputChunk {
  { chunk, bytes_read }
}

///|
pub fn InputChunk::from_bytes(chunk : Bytes) -> InputChunk {
  { chunk: Some(chunk), bytes_read: chunk.length() }
}

///|
pub fn InputChunk::eof() -> InputChunk {
  { chunk: Some(Bytes::new(0)), bytes_read: 0 }
}

///|
pub(all) enum InputDecodeResult {
  CodePoint(Int, bytes~ : Int)
  DecodeError
} derive(Eq, Debug)

///|
pub fn Input::from_string(
  source : String,
  encoding? : @api.InputEncoding = Utf8,
) -> Input {
  {
    encoding,
    source,
    bytes: encode_input_string(source, encoding),
    read_callback: None,
    decode_callback: None,
  }
}

///|
pub fn Input::from_bytes(
  source : Bytes,
  encoding? : @api.InputEncoding = Utf8,
) -> Input {
  {
    encoding,
    source: "",
    bytes: source,
    read_callback: None,
    decode_callback: None,
  }
}

///|
pub fn Input::from_callback(
  read : (UInt, @api.Point) -> InputChunk,
  encoding? : @api.InputEncoding = Utf8,
) -> Input {
  {
    encoding,
    source: "",
    bytes: Bytes::new(0),
    read_callback: Some(read),
    decode_callback: None,
  }
}

///|
pub fn Input::from_custom_bytes(
  source : Bytes,
  decode : (Bytes, Int) -> InputDecodeResult,
) -> Input {
  {
    encoding: Custom,
    source: "",
    bytes: source,
    read_callback: None,
    decode_callback: Some(decode),
  }
}

///|
pub fn Input::from_custom_callback(
  read : (UInt, @api.Point) -> InputChunk,
  decode : (Bytes, Int) -> InputDecodeResult,
) -> Input {
  {
    encoding: Custom,
    source: "",
    bytes: Bytes::new(0),
    read_callback: Some(read),
    decode_callback: Some(decode),
  }
}

///|
pub fn Input::encoding(self : Input) -> @api.InputEncoding {
  self.encoding
}

///|
pub fn Input::source(self : Input) -> String {
  self.source
}

///|
pub fn Input::bytes(self : Input) -> Bytes {
  self.bytes
}

///|
fn Input::materialize(self : Input) -> InputMaterialized raise ParseError {
  match self.read_callback {
    None => { bytes: self.bytes, chunk_end_offsets: [] }
    Some(read) =>
      materialize_input_callback(
        read,
        self.encoding,
        decode_callback=self.decode_callback,
      )
  }
}

///|
fn materialize_input_callback(
  read : (UInt, @api.Point) -> InputChunk,
  encoding : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
) -> InputMaterialized raise ParseError {
  let bytes : Array[Byte] = []
  let chunk_end_offsets : Array[Int] = []
  let mut offset : UInt = 0
  let mut point = @api.Point::zero()
  while true {
    let result = read(offset, point)
    validate_input_chunk(result, byte_offset=offset, point~)
    if result.bytes_read == 0 {
      return { bytes: Bytes::from_array(bytes), chunk_end_offsets }
    }
    guard result.chunk is Some(chunk) else {
      raise ParseError::InvalidInputCallback(
        byte_offset=offset,
        point~,
        reason="non-empty read without chunk",
      )
    }
    let start = bytes.length()
    for i in 0..<result.bytes_read {
      bytes.push(chunk[i])
    }
    chunk_end_offsets.push(bytes.length())
    point = advance_point_for_input_chunk(
      Bytes::from_array(bytes),
      start,
      result.bytes_read,
      encoding,
      decode_callback~,
      point,
    )
    offset += result.bytes_read.reinterpret_as_uint()
  }
  { bytes: Bytes::from_array(bytes), chunk_end_offsets }
}

///|
fn validate_input_chunk(
  result : InputChunk,
  byte_offset~ : UInt,
  point~ : @api.Point,
) -> Unit raise ParseError {
  if result.bytes_read < 0 {
    raise ParseError::InvalidInputCallback(
      byte_offset~,
      point~,
      reason="negative bytes_read",
    )
  }
  match result.chunk {
    None =>
      if result.bytes_read != 0 {
        raise ParseError::InvalidInputCallback(
          byte_offset~,
          point~,
          reason="non-empty read without chunk",
        )
      }
    Some(chunk) => {
      if result.bytes_read > chunk.length() {
        raise ParseError::InvalidInputCallback(
          byte_offset~,
          point~,
          reason="bytes_read exceeds chunk length",
        )
      }
      if result.bytes_read == 0 && !chunk.is_empty() {
        raise ParseError::InvalidInputCallback(
          byte_offset~,
          point~,
          reason="EOF read returned non-empty chunk",
        )
      }
    }
  }
}

///|
fn advance_point_for_input_chunk(
  bytes : Bytes,
  start : Int,
  bytes_read : Int,
  encoding : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  point : @api.Point,
) -> @api.Point raise ParseError {
  let mut byte_index = start
  let end = start + bytes_read
  let mut current = point
  while byte_index < end {
    match decode_input_scalar(bytes, byte_index, encoding~, decode_callback~) {
      Some(scalar) => {
        let width = if byte_index + scalar.byte_width > end {
          end - byte_index
        } else {
          scalar.byte_width
        }
        current = advance_point(current, width, scalar.codepoint)
        byte_index += width
      }
      None => {
        current = advance_point(current, 1, decode_error_codepoint)
        byte_index += 1
      }
    }
  }
  current
}

///|
fn encode_input_string(source : String, encoding : @api.InputEncoding) -> Bytes {
  match encoding {
    Utf8 | Custom => @utf8.encode(source)
    Utf16LE => encode_utf16_string(source, little_endian=true)
    Utf16BE => encode_utf16_string(source, little_endian=false)
  }
}

///|
fn encode_utf16_string(source : String, little_endian~ : Bool) -> Bytes {
  let bytes : Array[Byte] = []
  for i in 0..<source.length() {
    push_utf16_code_unit(bytes, source[i].to_int(), little_endian~)
  }
  Bytes::from_array(bytes)
}

///|
fn push_utf16_code_unit(
  bytes : Array[Byte],
  value : Int,
  little_endian~ : Bool,
) -> Unit {
  let low = (value % 0x100).to_byte()
  let high = (value / 0x100).to_byte()
  if little_endian {
    bytes.push(low)
    bytes.push(high)
  } else {
    bytes.push(high)
    bytes.push(low)
  }
}

///|
pub(all) enum LogType {
  Lex
  Parse
} derive(Eq, Debug)

///|
struct Logger {
  callback : (LogType, String) -> Unit
}

///|
pub fn Logger::new(callback : (LogType, String) -> Unit) -> Logger {
  { callback, }
}

///|
pub fn Logger::log(self : Logger, kind : LogType, message : String) -> Unit {
  (self.callback)(kind, message)
}
