///|
struct ExternalScannerDescriptor {
  external_token_count : Int
  external_state_count : Int
  states : Array[Array[Bool]]
  symbol_map : Array[Int]
  callback_id : Int
} derive(Eq, Debug)

///|
pub(all) struct ExternalScannerContext {
  input : Bytes
  byte_offset : UInt
  point : @api.Point
  valid_symbols : Array[Bool]
  is_at_included_range_start : Bool
  previous_included_range_end_byte : UInt?
  previous_included_range_end_point : @api.Point?
  eof : Bool
  mut column : UInt
  advance_steps : Array[ExternalScannerAdvanceStep]
  mut current_byte : UInt
  mut current_point : @api.Point
  mut current_step_index : Int
  mut token_start_byte : UInt
  mut token_start_point : @api.Point
  mut token_end_byte : UInt
  mut token_end_point : @api.Point
  mut has_marked_end : Bool
  mut did_get_column : Bool
  logs : Array[String]
} derive(Eq, Debug)

///|
pub(all) struct ExternalScannerAdvanceStep {
  byte_width : Int
  codepoint : Int
} derive(Eq, Debug)

///|
pub fn ExternalScannerAdvanceStep::new(
  byte_width~ : Int,
  codepoint~ : Int,
) -> ExternalScannerAdvanceStep {
  { byte_width, codepoint }
}

///|
pub fn ExternalScannerContext::new(
  input~ : Bytes,
  byte_offset~ : UInt,
  point~ : @api.Point,
  valid_symbols~ : Array[Bool],
  is_at_included_range_start? : Bool = false,
  previous_included_range_end_byte? : UInt? = None,
  previous_included_range_end_point? : @api.Point? = None,
  eof? : Bool = false,
  column? : UInt = point.column,
  advance_steps? : Array[ExternalScannerAdvanceStep] = [],
) -> ExternalScannerContext {
  {
    input,
    byte_offset,
    point,
    valid_symbols: valid_symbols.copy(),
    is_at_included_range_start,
    previous_included_range_end_byte,
    previous_included_range_end_point,
    eof,
    column,
    advance_steps,
    current_byte: byte_offset,
    current_point: point,
    current_step_index: 0,
    token_start_byte: byte_offset,
    token_start_point: point,
    token_end_byte: byte_offset,
    token_end_point: point,
    has_marked_end: false,
    did_get_column: false,
    logs: [],
  }
}

///|
pub fn ExternalScannerContext::is_at_included_range_start(
  self : ExternalScannerContext,
) -> Bool {
  self.is_at_included_range_start && self.current_byte == self.byte_offset
}

///|
pub fn ExternalScannerContext::eof(self : ExternalScannerContext) -> Bool {
  self.eof || self.current_step_index >= self.advance_steps.length()
}

///|
pub fn ExternalScannerContext::get_column(
  self : ExternalScannerContext,
) -> UInt {
  self.did_get_column = true
  self.column
}

///|
pub fn ExternalScannerContext::did_get_column(
  self : ExternalScannerContext,
) -> Bool {
  self.did_get_column
}

///|
pub fn ExternalScannerContext::log(
  self : ExternalScannerContext,
  message : String,
) -> Unit {
  self.logs.push(message)
}

///|
pub fn ExternalScannerContext::logged_messages(
  self : ExternalScannerContext,
) -> Array[String] {
  self.logs.copy()
}

///|
pub fn ExternalScannerContext::current_byte(
  self : ExternalScannerContext,
) -> UInt {
  self.current_byte
}

///|
pub fn ExternalScannerContext::current_point(
  self : ExternalScannerContext,
) -> @api.Point {
  self.current_point
}

///|
pub fn ExternalScannerContext::advance(
  self : ExternalScannerContext,
  skip? : Bool = false,
) -> Unit {
  if self.eof || self.current_step_index >= self.advance_steps.length() {
    return
  }
  let step = self.advance_steps[self.current_step_index]
  self.current_step_index += 1
  self.current_byte += step.byte_width.reinterpret_as_uint()
  self.current_point = external_scanner_advance_point(
    self.current_point,
    step.byte_width,
    step.codepoint,
  )
  if step.codepoint == 10 {
    self.column = 0
  } else if self.current_step_index == 1 &&
    self.byte_offset == 0 &&
    step.codepoint == 0xFEFF {
    ()
  } else {
    self.column += 1
  }
  if skip {
    self.token_start_byte = self.current_byte
    self.token_start_point = self.current_point
    if !self.has_marked_end {
      self.token_end_byte = self.current_byte
      self.token_end_point = self.current_point
    }
  }
}

///|
pub fn ExternalScannerContext::mark_end(self : ExternalScannerContext) -> Unit {
  if self.is_at_included_range_start && self.current_byte == self.byte_offset {
    match
      (
        self.previous_included_range_end_byte,
        self.previous_included_range_end_point,
      ) {
      (Some(byte), Some(point)) => {
        self.token_end_byte = byte
        self.token_end_point = point
      }
      _ => {
        self.token_end_byte = self.current_byte
        self.token_end_point = self.current_point
      }
    }
  } else {
    self.token_end_byte = self.current_byte
    self.token_end_point = self.current_point
  }
  self.has_marked_end = true
}

///|
pub fn ExternalScannerContext::token(
  self : ExternalScannerContext,
  external_token_id~ : Int,
  state_changed? : Bool = false,
) -> ExternalScanResult {
  let end_byte = if self.has_marked_end {
    self.token_end_byte
  } else {
    self.current_byte
  }
  let end_point = if self.has_marked_end {
    self.token_end_point
  } else {
    self.current_point
  }
  let start_byte = if end_byte < self.token_start_byte {
    end_byte
  } else {
    self.token_start_byte
  }
  let start_point = if end_byte < self.token_start_byte {
    end_point
  } else {
    self.token_start_point
  }
  ExternalScanResult::TokenRange(
    external_token_id~,
    start_byte~,
    end_byte~,
    start_point~,
    end_point~,
    state_changed~,
  )
}

///|
pub(all) enum ExternalScanResult {
  NoToken
  Token(external_token_id~ : Int, bytes_read~ : Int)
  TokenRange(
    external_token_id~ : Int,
    start_byte~ : UInt,
    end_byte~ : UInt,
    start_point~ : @api.Point,
    end_point~ : @api.Point,
    state_changed~ : Bool
  )
} derive(Eq, Debug)

///|
fn external_scanner_advance_point(
  point : @api.Point,
  byte_width : Int,
  codepoint : Int,
) -> @api.Point {
  if codepoint == 10 {
    @api.Point::new(row=point.row + 1, column=0)
  } else {
    @api.Point::new(
      row=point.row,
      column=point.column + byte_width.reinterpret_as_uint(),
    )
  }
}

///|
priv struct ExternalScannerCallbacks {
  create : () -> Unit raise @api.ScannerError
  destroy : () -> Unit raise @api.ScannerError
  deserialize : (Bytes) -> Unit raise @api.ScannerError
  serialize : () -> Bytes raise @api.ScannerError
  scan : (ExternalScannerContext) -> ExternalScanResult raise @api.ScannerError
}

///|
let external_scanner_callbacks : Array[ExternalScannerCallbacks] = []

///|
pub fn external_scanner_serialization_buffer_size() -> Int {
  1024
}

///|
pub fn ExternalScannerDescriptor::none() -> ExternalScannerDescriptor {
  {
    external_token_count: 0,
    external_state_count: 0,
    states: [],
    symbol_map: [],
    callback_id: -1,
  }
}

///|
pub fn ExternalScannerDescriptor::new(
  external_token_count~ : Int,
  external_state_count~ : Int,
  states? : Array[Array[Bool]] = [],
  symbol_map? : Array[Int] = [],
) -> ExternalScannerDescriptor {
  {
    external_token_count,
    external_state_count,
    states,
    symbol_map,
    callback_id: -1,
  }
}

///|
pub fn ExternalScannerDescriptor::with_scan(
  external_token_count~ : Int,
  external_state_count~ : Int,
  states? : Array[Array[Bool]] = [],
  symbol_map? : Array[Int] = [],
  scan~ : (ExternalScannerContext) -> ExternalScanResult raise @api.ScannerError,
) -> ExternalScannerDescriptor {
  ExternalScannerDescriptor::with_callbacks(
    external_token_count~,
    external_state_count~,
    states~,
    symbol_map~,
    create=external_scanner_noop_create,
    destroy=external_scanner_noop_destroy,
    deserialize=external_scanner_noop_deserialize,
    serialize=external_scanner_noop_serialize,
    scan~,
  )
}

///|
pub fn ExternalScannerDescriptor::with_callbacks(
  external_token_count~ : Int,
  external_state_count~ : Int,
  states? : Array[Array[Bool]] = [],
  symbol_map? : Array[Int] = [],
  create~ : () -> Unit raise @api.ScannerError,
  destroy~ : () -> Unit raise @api.ScannerError,
  deserialize~ : (Bytes) -> Unit raise @api.ScannerError,
  serialize~ : () -> Bytes raise @api.ScannerError,
  scan~ : (ExternalScannerContext) -> ExternalScanResult raise @api.ScannerError,
) -> ExternalScannerDescriptor {
  {
    external_token_count,
    external_state_count,
    states,
    symbol_map,
    callback_id: register_external_scanner_callbacks(
      create, destroy, deserialize, serialize, scan,
    ),
  }
}

///|
pub fn ExternalScannerDescriptor::external_token_count(
  self : ExternalScannerDescriptor,
) -> Int {
  self.external_token_count
}

///|
pub fn ExternalScannerDescriptor::external_state_count(
  self : ExternalScannerDescriptor,
) -> Int {
  self.external_state_count
}

///|
pub fn ExternalScannerDescriptor::state_enabled(
  self : ExternalScannerDescriptor,
  state_id : Int,
  external_token_id : Int,
) -> Bool? {
  if state_id < 0 || state_id >= self.states.length() {
    None
  } else if external_token_id < 0 ||
    external_token_id >= self.states[state_id].length() {
    None
  } else {
    Some(self.states[state_id][external_token_id])
  }
}

///|
pub fn ExternalScannerDescriptor::symbol_for_external_token(
  self : ExternalScannerDescriptor,
  external_token_id : Int,
) -> Int? {
  if external_token_id < 0 || external_token_id >= self.symbol_map.length() {
    None
  } else {
    Some(self.symbol_map[external_token_id])
  }
}

///|
pub fn ExternalScannerDescriptor::has_scan_callback(
  self : ExternalScannerDescriptor,
) -> Bool {
  self.callback_id >= 0 &&
  self.callback_id < external_scanner_callbacks.length()
}

///|
pub fn ExternalScannerDescriptor::scan(
  self : ExternalScannerDescriptor,
  context : ExternalScannerContext,
) -> ExternalScanResult raise @api.ScannerError {
  let callback = self.callbacks_or_raise()
  (callback.scan)(context)
}

///|
pub fn ExternalScannerDescriptor::create(
  self : ExternalScannerDescriptor,
) -> Unit raise @api.ScannerError {
  let callback = self.callbacks_or_raise()
  (callback.create)()
}

///|
pub fn ExternalScannerDescriptor::destroy(
  self : ExternalScannerDescriptor,
) -> Unit raise @api.ScannerError {
  let callback = self.callbacks_or_raise()
  (callback.destroy)()
}

///|
pub fn ExternalScannerDescriptor::deserialize(
  self : ExternalScannerDescriptor,
  state : Bytes,
) -> Unit raise @api.ScannerError {
  let callback = self.callbacks_or_raise()
  (callback.deserialize)(state)
}

///|
pub fn ExternalScannerDescriptor::serialize(
  self : ExternalScannerDescriptor,
) -> Bytes raise @api.ScannerError {
  let callback = self.callbacks_or_raise()
  (callback.serialize)()
}

///|
fn ExternalScannerDescriptor::callbacks_or_raise(
  self : ExternalScannerDescriptor,
) -> ExternalScannerCallbacks raise @api.ScannerError {
  if !self.has_scan_callback() {
    raise @api.ScannerError::Failure("external scanner scan callback missing")
  }
  external_scanner_callbacks[self.callback_id]
}

///|
fn register_external_scanner_callbacks(
  create : () -> Unit raise @api.ScannerError,
  destroy : () -> Unit raise @api.ScannerError,
  deserialize : (Bytes) -> Unit raise @api.ScannerError,
  serialize : () -> Bytes raise @api.ScannerError,
  scan : (ExternalScannerContext) -> ExternalScanResult raise @api.ScannerError,
) -> Int {
  let callback_id = external_scanner_callbacks.length()
  external_scanner_callbacks.push({
    create,
    destroy,
    deserialize,
    serialize,
    scan,
  })
  callback_id
}

///|
fn external_scanner_noop_create() -> Unit raise @api.ScannerError {
  if false {
    raise @api.ScannerError::Failure("unreachable")
  }
  ()
}

///|
fn external_scanner_noop_destroy() -> Unit raise @api.ScannerError {
  if false {
    raise @api.ScannerError::Failure("unreachable")
  }
  ()
}

///|
fn external_scanner_noop_deserialize(
  _state : Bytes,
) -> Unit raise @api.ScannerError {
  if false {
    raise @api.ScannerError::Failure("unreachable")
  }
  ()
}

///|
fn external_scanner_noop_serialize() -> Bytes raise @api.ScannerError {
  if false {
    raise @api.ScannerError::Failure("unreachable")
  }
  Bytes::new(0)
}
