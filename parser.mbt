///|
fn[T, E : Error] capture_parser_result(f : () -> T raise E) -> Result[T, E] {
  try f() catch {
    error => Err(error)
  } noraise {
    value => Ok(value)
  }
}

///|
struct Parser {
  mut language : Language?
  mut included_ranges : Array[@api.Range]
  mut logger : Logger?
  mut outstanding_parse : OutstandingParseState?
  mut outstanding_external_scanner : @tables.ExternalScannerDescriptor?
}

///|
pub(all) suberror LanguageError {
  UnsupportedAbi(Int)
} derive(Eq, Debug)

///|
pub(all) suberror IncludedRangesError {
  InvalidRange(index~ : Int, range~ : @api.Range)
  Overlap(index~ : Int, previous~ : @api.Range, current~ : @api.Range)
} derive(Eq, Debug)

///|
pub(all) suberror ParseError {
  NoLanguage
  LanguageMismatch
  Cancelled(ParseState)
  InvalidInputCallback(
    byte_offset~ : UInt,
    point~ : @api.Point,
    reason~ : String
  )
  InvalidInputDecode(byte_offset~ : UInt, reason~ : String)
  ScannerError(@api.ScannerError)
  LexError(byte_offset~ : UInt, state_id~ : @api.StateId)
  ParseTableError(state_id~ : @api.StateId, symbol_id~ : @api.SymbolId)
  ParseStackUnderflow
} derive(Eq, Debug)

///|
priv struct ParseStackEntry {
  state_id : Int
  node_index : Int
}

///|
priv struct SelectedParseAction {
  action : @tables.GeneratedParseAction
  force_fragile : Bool
}

///|
priv struct PotentialReduceAction {
  symbol_id : Int
  child_count : Int
  dynamic_precedence : Int
  production_id : Int
}

///|
priv struct ParseBranchState {
  stack : Array[ParseStackEntry]
  nodes : Array[NodeData]
  leading_extras : Array[Array[Int]]
  mut pending_extras : Array[Int]
  mut current_byte : UInt
  mut current_point : @api.Point
  mut lookahead : LexedToken?
  mut last_external_scanner_state : Bytes
  mut did_insert_missing_token : Bool
  mut parse_has_error : Bool
  order : Int
}

///|
priv struct AcceptedParseBranch {
  tree : Tree
  error_cost : Int
  dynamic_precedence : Int
  order : Int
}

///|
priv struct LexedToken {
  symbol_id : Int
  start_byte : UInt
  end_byte : UInt
  start_point : @api.Point
  end_point : @api.Point
  lookahead_byte_count : Int
  external_scanner_state : Bytes?
  external_scanner_state_changed : Bool
  external_scanner_depends_on_column : Bool
}

///|
priv struct OutstandingParseState {
  stack : Array[ParseStackEntry]
  nodes : Array[NodeData]
  leading_extras : Array[Array[Int]]
  pending_extras : Array[Int]
  current_byte : UInt
  current_point : @api.Point
  lookahead : LexedToken?
  last_external_scanner_state : Bytes
  did_insert_missing_token : Bool
  parse_has_error : Bool
}

///|
fn OutstandingParseState::initial() -> OutstandingParseState {
  {
    stack: [{ state_id: 1, node_index: -1 }],
    nodes: [],
    leading_extras: [],
    pending_extras: [],
    current_byte: 0,
    current_point: @api.Point::zero(),
    lookahead: None,
    last_external_scanner_state: Bytes::new(0),
    did_insert_missing_token: false,
    parse_has_error: false,
  }
}

///|
priv struct DecodedScalar {
  codepoint : Int
  byte_width : Int
}

///|
let decode_error_codepoint = -1

///|
let bom_codepoint = 0xFEFF

///|
let error_cost_per_recovery = 500

///|
let error_cost_per_missing_tree = 110

///|
let error_cost_per_skipped_tree = 100

///|
let error_cost_per_skipped_line = 30

///|
let error_cost_per_skipped_char = 1

///|
pub fn Parser::new() -> Parser {
  {
    language: None,
    included_ranges: [],
    logger: None,
    outstanding_parse: None,
    outstanding_external_scanner: None,
  }
}

///|
pub fn Parser::language(self : Parser) -> Language? {
  self.language
}

///|
pub fn Parser::set_language(
  self : Parser,
  language : Language,
) -> Unit raise LanguageError {
  if language.abi_version() != @tables.target_abi_version() {
    raise LanguageError::UnsupportedAbi(language.abi_version())
  }
  self.reset()
  self.language = Some(language)
}

///|
pub fn Parser::set_included_ranges(
  self : Parser,
  ranges : Array[@api.Range],
) -> Unit raise IncludedRangesError {
  validate_included_ranges(ranges)
  self.included_ranges = ranges.copy()
}

///|
pub fn Parser::included_ranges(self : Parser) -> Array[@api.Range] {
  self.included_ranges.copy()
}

///|
pub fn Parser::set_logger(self : Parser, logger : Logger?) -> Unit {
  self.logger = logger
}

///|
pub fn Parser::logger(self : Parser) -> Logger? {
  self.logger
}

///|
pub fn Parser::reset(self : Parser) -> Unit {
  self.outstanding_parse = None
  self.destroy_outstanding_external_scanner()
}

///|
pub fn Parser::parse_bytes(
  self : Parser,
  input : Bytes,
  old_tree? : Tree? = None,
  options? : ParseOptions = ParseOptions::default(),
) -> Tree raise ParseError {
  self.parse_encoded_bytes(input, encoding=Utf8, old_tree~, options~)
}

///|
fn Parser::parse_encoded_bytes(
  self : Parser,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback? : ((Bytes, Int) -> InputDecodeResult)? = None,
  chunk_end_offsets? : Array[Int] = [],
  old_tree? : Tree? = None,
  options? : ParseOptions = ParseOptions::default(),
) -> Tree raise ParseError {
  match self.language {
    Some(language) => {
      let has_outstanding_parse = self.outstanding_parse is Some(_)
      if !has_outstanding_parse {
        check_old_tree_precondition(language, old_tree)
        match
          copy_reusable_old_tree_for_input(
            old_tree,
            input,
            encoding,
            decode_callback~,
            chunk_end_offsets~,
            included_ranges=self.included_ranges,
          ) {
          Some(tree) => {
            maybe_cancel_parse(options, ParseState::initial())
            parser_log(self.logger, Parse, "reuse old tree")
            return tree
          }
          None => ()
        }
      }
      maybe_cancel_configured_parse(options)
      ensure_custom_decode_callback(encoding, decode_callback)
      self.parse_full_input(
        language,
        input,
        encoding~,
        decode_callback~,
        chunk_end_offsets~,
        options~,
        initial_progress_checked=false,
        included_ranges=self.included_ranges,
        logger=self.logger,
      )
    }
    None => raise ParseError::NoLanguage
  }
}

///|
pub fn Parser::parse_string(
  self : Parser,
  input : String,
  old_tree? : Tree? = None,
  options? : ParseOptions = ParseOptions::default(),
) -> Tree raise ParseError {
  self.parse_bytes(@utf8.encode(input), old_tree~, options~)
}

///|
pub fn Parser::parse(
  self : Parser,
  input : Input,
  old_tree? : Tree? = None,
  options? : ParseOptions = ParseOptions::default(),
) -> Tree raise ParseError {
  match self.language {
    Some(language) => {
      let has_outstanding_parse = self.outstanding_parse is Some(_)
      if !has_outstanding_parse {
        check_old_tree_precondition(language, old_tree)
      }
      if has_outstanding_parse {
        maybe_cancel_configured_parse(options)
      } else {
        maybe_cancel_parse(options, ParseState::initial())
      }
      ensure_custom_decode_callback(input.encoding(), input.decode_callback)
      let materialized = input.materialize()
      let decode_callback = match input.encoding() {
        Custom => input.decode_callback
        _ => None
      }
      if !has_outstanding_parse {
        match
          copy_reusable_old_tree_for_input(
            old_tree,
            materialized.bytes,
            input.encoding(),
            decode_callback~,
            chunk_end_offsets=materialized.chunk_end_offsets,
            included_ranges=self.included_ranges,
          ) {
          Some(tree) => {
            parser_log(self.logger, Parse, "reuse old tree")
            return tree
          }
          None => ()
        }
      }
      self.parse_full_input(
        language,
        materialized.bytes,
        encoding=input.encoding(),
        decode_callback~,
        chunk_end_offsets=materialized.chunk_end_offsets,
        options~,
        initial_progress_checked=!has_outstanding_parse,
        included_ranges=self.included_ranges,
        logger=self.logger,
      )
    }
    None => raise ParseError::NoLanguage
  }
}

///|
fn check_old_tree_precondition(
  language : Language,
  old_tree : Tree?,
) -> Unit raise ParseError {
  match old_tree {
    Some(tree) =>
      if !language_identity_matches(tree.language(), language) {
        raise ParseError::LanguageMismatch
      }
    None => ()
  }
}

///|
fn copy_reusable_old_tree_for_input(
  old_tree : Tree?,
  input : Bytes,
  encoding : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  included_ranges~ : Array[@api.Range],
) -> Tree? {
  if decode_callback is Some(_) {
    return None
  }
  match old_tree {
    Some(tree) =>
      tree.copy_if_reusable_same_input(
        input, encoding, chunk_end_offsets, included_ranges,
      )
    None => None
  }
}

///|
fn ensure_custom_decode_callback(
  encoding : @api.InputEncoding,
  decode_callback : ((Bytes, Int) -> InputDecodeResult)?,
) -> Unit raise ParseError {
  if encoding == Custom && decode_callback is None {
    raise ParseError::InvalidInputDecode(
      byte_offset=0,
      reason="custom input requires decode callback",
    )
  }
}

///|
pub(all) struct ParseState {
  current_byte_offset : UInt
  has_error : Bool
} derive(Eq, Debug)

///|
pub fn ParseState::new(
  current_byte_offset~ : UInt,
  has_error~ : Bool,
) -> ParseState {
  { current_byte_offset, has_error }
}

///|
pub fn ParseState::initial() -> ParseState {
  { current_byte_offset: 0, has_error: false }
}

///|
pub(all) struct ParseOptions {
  cancellation_state : ParseState?
  progress_callback : ((ParseState) -> Bool)?
}

///|
pub fn ParseOptions::default() -> ParseOptions {
  { cancellation_state: None, progress_callback: None }
}

///|
pub fn ParseOptions::cancelled(state : ParseState) -> ParseOptions {
  { cancellation_state: Some(state), progress_callback: None }
}

///|
pub fn ParseOptions::progress(callback : (ParseState) -> Bool) -> ParseOptions {
  { cancellation_state: None, progress_callback: Some(callback) }
}

///|
pub fn ParseOptions::with_progress(
  self : ParseOptions,
  callback : (ParseState) -> Bool,
) -> ParseOptions {
  { ..self, progress_callback: Some(callback) }
}

///|
fn maybe_cancel_parse(
  options : ParseOptions,
  state : ParseState,
) -> Unit raise ParseError {
  match parse_cancellation_state(options, state) {
    Some(state) => raise ParseError::Cancelled(state)
    None => ()
  }
}

///|
fn parse_cancellation_state(
  options : ParseOptions,
  state : ParseState,
) -> ParseState? {
  match options.cancellation_state {
    Some(state) => Some(state)
    None =>
      match options.progress_callback {
        Some(callback) => if callback(state) { Some(state) } else { None }
        None => None
      }
  }
}

///|
fn maybe_cancel_configured_parse(
  options : ParseOptions,
) -> Unit raise ParseError {
  match options.cancellation_state {
    Some(state) => raise ParseError::Cancelled(state)
    None => ()
  }
}

///|
fn Parser::parse_full_input(
  self : Parser,
  language : Language,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  options~ : ParseOptions,
  initial_progress_checked~ : Bool,
  included_ranges~ : Array[@api.Range],
  logger~ : Logger?,
) -> Tree raise ParseError {
  let scanner_session = match self.outstanding_external_scanner {
    Some(scanner) => {
      self.outstanding_external_scanner = None
      Some(scanner)
    }
    None => create_external_scanner_session(language.tables)
  }
  let result : Result[Tree, ParseError] = capture_parser_result(() => {
    self.parse_full_input_loop(
      language,
      input,
      encoding~,
      decode_callback~,
      chunk_end_offsets~,
      options~,
      initial_progress_checked~,
      included_ranges~,
      logger~,
    )
  })
  match result {
    Ok(tree) => {
      self.outstanding_parse = None
      let cleanup_result : Result[Unit, ParseError] = capture_parser_result(() => {
        destroy_external_scanner_session(scanner_session)
      })
      match cleanup_result {
        Ok(_) => tree
        Err(error) => raise error
      }
    }
    Err(error) =>
      match error {
        Cancelled(_) => {
          self.outstanding_external_scanner = scanner_session
          raise error
        }
        _ => {
          self.outstanding_parse = None
          let cleanup_result : Result[Unit, ParseError] = capture_parser_result(() => {
              destroy_external_scanner_session(scanner_session)
            },
          )
          match cleanup_result {
            Ok(_) => raise error
            Err(cleanup_error) => raise cleanup_error
          }
        }
      }
  }
}

///|
fn Parser::parse_full_input_loop(
  self : Parser,
  language : Language,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  options~ : ParseOptions,
  initial_progress_checked~ : Bool,
  included_ranges~ : Array[@api.Range],
  logger~ : Logger?,
) -> Tree raise ParseError {
  parser_log(logger, Parse, "parse start")
  let tables = language.tables
  let initial_state = match self.outstanding_parse {
    Some(state) => {
      parser_log(logger, Parse, "resume parsing")
      self.outstanding_parse = None
      state
    }
    None => OutstandingParseState::initial()
  }
  let stack = initial_state.stack
  let nodes = initial_state.nodes
  let leading_extras = initial_state.leading_extras
  let mut pending_extras = initial_state.pending_extras
  let mut current_byte = initial_state.current_byte
  let mut current_point = initial_state.current_point
  let mut lookahead = initial_state.lookahead
  let mut last_external_scanner_state = initial_state.last_external_scanner_state
  let mut did_insert_missing_token = initial_state.did_insert_missing_token
  let mut parse_has_error = initial_state.parse_has_error
  let mut skip_progress_check = initial_progress_checked
  while true {
    if skip_progress_check {
      skip_progress_check = false
    } else {
      let progress_state = ParseState::new(
        current_byte_offset=current_byte,
        has_error=parse_has_error,
      )
      match parse_cancellation_state(options, progress_state) {
        Some(cancelled_state) => {
          self.outstanding_parse = Some({
            stack,
            nodes,
            leading_extras,
            pending_extras,
            current_byte,
            current_point,
            lookahead,
            last_external_scanner_state,
            did_insert_missing_token,
            parse_has_error,
          })
          raise ParseError::Cancelled(cancelled_state)
        }
        None => ()
      }
    }
    guard stack.last() is Some(top) else {
      raise ParseError::ParseStackUnderflow
    }
    match synthetic_extra_reduce_action(tables, top.state_id) {
      Some(action) => {
        if tables.is_extra_symbol(symbol_id_from_int(action.symbol_id)) {
          reduce_extra_stack(
            language,
            tables,
            nodes,
            leading_extras,
            stack,
            pending_extras,
            action~,
            fallback_byte=current_byte,
            fallback_point=current_point,
            force_fragile=false,
          )
        } else {
          reduce_stack(
            language,
            tables,
            nodes,
            leading_extras,
            stack,
            symbol_id=action.symbol_id,
            child_count=action.child_count,
            dynamic_precedence=action.dynamic_precedence,
            production_id=action.production_id,
            force_fragile=false,
            fallback_byte=current_byte,
            fallback_point=current_point,
            trailing_extras=[],
          )
        }
        continue
      }
      None => ()
    }
    let token = match lookahead {
      Some(value) => value
      None => {
        let lex_result : Result[LexedToken, ParseError] = capture_parser_result(() => {
            lex_main_token(
              tables,
              top.state_id,
              input,
              encoding~,
              decode_callback~,
              chunk_end_offsets~,
              current_byte,
              current_point,
              included_ranges~,
              external_scanner_state=last_external_scanner_state,
              logger~,
            )
          },
        )
        match lex_result {
          Ok(value) => {
            lookahead = Some(value)
            value
          }
          Err(LexError(byte_offset~, state_id~)) => {
            if try_reduce_all_potential_at(
                language,
                tables,
                nodes,
                leading_extras,
                stack,
                top.state_id,
                fallback_byte=current_byte,
                fallback_point=current_point,
                logger~,
              ) {
              continue
            }
            if stack.length() > 1 &&
              !did_insert_missing_token &&
              try_insert_missing_token_for_lex_error(
                language,
                tables,
                input,
                encoding~,
                decode_callback~,
                chunk_end_offsets~,
                included_ranges~,
                nodes,
                leading_extras,
                stack,
                top.state_id,
                current_byte,
                current_point,
                external_scanner_state=last_external_scanner_state,
                pending_extras,
                logger~,
              ) {
              did_insert_missing_token = true
              parse_has_error = true
              pending_extras = []
              continue
            }
            if stack.length() == 1 {
              match
                recover_lex_error(
                  language,
                  tables,
                  input,
                  encoding~,
                  decode_callback~,
                  chunk_end_offsets~,
                  current_byte,
                  current_point,
                  included_ranges~,
                  external_scanner_state=last_external_scanner_state,
                  nodes,
                  leading_extras,
                  pending_extras,
                  logger~,
                ) {
                Some((next_byte, next_point)) => {
                  current_byte = next_byte
                  current_point = next_point
                  parse_has_error = true
                  continue
                }
                None => ()
              }
            }
            raise ParseError::LexError(byte_offset~, state_id~)
          }
          Err(error) => raise error
        }
      }
    }
    let token_symbol = symbol_id_from_int(token.symbol_id)
    let selected_action = match
      tables.parse_action_list_for_symbol(
        state_id_from_int(top.state_id),
        token_symbol,
      ) {
      Some(action_list) => {
        let runtime_actions = runtime_parse_actions(action_list.actions)
        if !action_list.reusable && runtime_actions.length() > 1 {
          return self.parse_full_input_branch_loop(
            language,
            input,
            encoding~,
            decode_callback~,
            chunk_end_offsets~,
            options~,
            included_ranges~,
            logger~,
            initial_branch={
              stack: stack.copy(),
              nodes: nodes.copy(),
              leading_extras: copy_leading_extras(leading_extras),
              pending_extras: pending_extras.copy(),
              current_byte,
              current_point,
              lookahead: Some(token),
              last_external_scanner_state,
              did_insert_missing_token,
              parse_has_error,
              order: 0,
            },
          )
        }
        match selected_parse_action(action_list.actions) {
          Some(selected) => selected
          None =>
            raise ParseError::ParseTableError(
              state_id=state_id_from_int(top.state_id),
              symbol_id=token_symbol,
            )
        }
      }
      None => {
        if try_reduce_all_potential(
            language,
            tables,
            nodes,
            leading_extras,
            stack,
            top.state_id,
            token,
            pending_extras,
            logger~,
          ) {
          continue
        }
        if !did_insert_missing_token &&
          try_insert_missing_token(
            language,
            tables,
            nodes,
            leading_extras,
            stack,
            top.state_id,
            token,
            pending_extras,
            logger~,
          ) {
          did_insert_missing_token = true
          parse_has_error = true
          pending_extras = []
          continue
        }
        if try_synchronize_stack_to_root(
            language,
            tables,
            nodes,
            leading_extras,
            stack,
            pending_extras,
            token,
            logger~,
          ) {
          parse_has_error = true
          continue
        }
        if stack.length() > 1 {
          match
            try_skip_unexpected_token(
              language,
              input,
              encoding~,
              decode_callback~,
              chunk_end_offsets~,
              nodes,
              leading_extras,
              pending_extras,
              token,
              logger~,
            ) {
            Some((next_byte, next_point)) => {
              match token.external_scanner_state {
                Some(state) => last_external_scanner_state = state
                None => ()
              }
              current_byte = next_byte
              current_point = next_point
              lookahead = None
              parse_has_error = true
              continue
            }
            None => ()
          }
        }
        raise ParseError::ParseTableError(
          state_id=state_id_from_int(top.state_id),
          symbol_id=token_symbol,
        )
      }
    }
    match selected_action.action {
      @tables.GeneratedParseAction::Accept => {
        parser_log(logger, Parse, "parse accept")
        return parser_tree_from_stack(
          language,
          nodes,
          leading_extras,
          stack,
          pending_extras~,
          included_ranges~,
          source_bytes=if decode_callback is None { Some(input) } else { None },
          source_encoding=encoding,
          source_chunk_end_offsets=chunk_end_offsets,
        )
      }
      @tables.GeneratedParseAction::Shift(state_id~, is_repetition~) => {
        if is_repetition {
          raise ParseError::ParseTableError(
            state_id=state_id_from_int(top.state_id),
            symbol_id=token_symbol,
          )
        }
        let node_index = push_parser_node(
          nodes,
          leading_extras,
          node_data_for_symbol(
            language,
            token.symbol_id,
            token.start_byte,
            token.end_byte,
            token.start_point,
            token.end_point,
            external_scanner_state=token.external_scanner_state,
            external_scanner_state_changed=token.external_scanner_state_changed,
            external_scanner_depends_on_column=token.external_scanner_depends_on_column,
            lookahead_byte_count=token.lookahead_byte_count,
            parse_state=Some(state_id_from_int(top.state_id)),
            next_parse_state=Some(state_id_from_int(state_id)),
          ),
          leading=pending_extras,
        )
        pending_extras = []
        stack.push({ state_id, node_index })
        match token.external_scanner_state {
          Some(state) => last_external_scanner_state = state
          None => ()
        }
        current_byte = token.end_byte
        current_point = token.end_point
        lookahead = None
      }
      @tables.GeneratedParseAction::ShiftExtra => {
        let node_index = push_parser_node(nodes, leading_extras, {
          ..node_data_for_symbol(
            language,
            token.symbol_id,
            token.start_byte,
            token.end_byte,
            token.start_point,
            token.end_point,
            external_scanner_state=token.external_scanner_state,
            external_scanner_state_changed=token.external_scanner_state_changed,
            external_scanner_depends_on_column=token.external_scanner_depends_on_column,
            lookahead_byte_count=token.lookahead_byte_count,
            parse_state=Some(state_id_from_int(top.state_id)),
            next_parse_state=Some(state_id_from_int(top.state_id)),
          ),
          extra: true,
        })
        pending_extras.push(node_index)
        match token.external_scanner_state {
          Some(state) => last_external_scanner_state = state
          None => ()
        }
        current_byte = token.end_byte
        current_point = token.end_point
        lookahead = None
      }
      @tables.GeneratedParseAction::Recover =>
        if token.symbol_id == 0 && token.end_byte <= token.start_byte {
          push_empty_recovered_error_node(
            language,
            nodes,
            leading_extras,
            stack,
            token.start_byte,
            token.start_point,
            logger~,
          )
          parse_has_error = true
        } else {
          match
            try_skip_unexpected_token(
              language,
              input,
              encoding~,
              decode_callback~,
              chunk_end_offsets~,
              nodes,
              leading_extras,
              pending_extras,
              token,
              logger~,
            ) {
            Some((next_byte, next_point)) => {
              match token.external_scanner_state {
                Some(state) => last_external_scanner_state = state
                None => ()
              }
              current_byte = next_byte
              current_point = next_point
              lookahead = None
              parse_has_error = true
            }
            None =>
              raise ParseError::ParseTableError(
                state_id=state_id_from_int(top.state_id),
                symbol_id=token_symbol,
              )
          }
        }
      @tables.GeneratedParseAction::Reduce(
        symbol_id~,
        child_count~,
        dynamic_precedence~,
        production_id~
      ) =>
        reduce_stack(
          language,
          tables,
          nodes,
          leading_extras,
          stack,
          symbol_id~,
          child_count~,
          dynamic_precedence~,
          production_id~,
          force_fragile=selected_action.force_fragile,
          fallback_byte=token.start_byte,
          fallback_point=token.start_point,
          trailing_extras=[],
        )
    }
  }
  raise ParseError::ParseStackUnderflow
}

///|
fn copy_leading_extras(leading_extras : Array[Array[Int]]) -> Array[Array[Int]] {
  let result : Array[Array[Int]] = []
  for extras in leading_extras {
    result.push(extras.copy())
  }
  result
}

///|
fn Parser::parse_full_input_branch_loop(
  self : Parser,
  language : Language,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  options~ : ParseOptions,
  included_ranges~ : Array[@api.Range],
  logger~ : Logger?,
  initial_branch~ : ParseBranchState,
) -> Tree raise ParseError {
  let tables = language.tables
  let branches : Array[ParseBranchState] = [initial_branch]
  let mut next_order = 1
  let mut accepted : AcceptedParseBranch? = None
  let mut first_error : ParseError? = None
  while !branches.is_empty() {
    let branch = match branches.pop() {
      Some(branch) => branch
      None => raise ParseError::ParseStackUnderflow
    }
    let progress_state = ParseState::new(
      current_byte_offset=branch.current_byte,
      has_error=branch.parse_has_error,
    )
    match parse_cancellation_state(options, progress_state) {
      Some(cancelled_state) => {
        self.outstanding_parse = Some(parse_branch_outstanding_state(branch))
        raise ParseError::Cancelled(cancelled_state)
      }
      None => ()
    }
    let branch_result : Result[Array[AcceptedParseBranch], ParseError] = capture_parser_result(() => {
        parse_branch_step(
          language,
          tables,
          input,
          encoding~,
          decode_callback~,
          chunk_end_offsets~,
          included_ranges~,
          logger~,
          branch,
          branches,
          next_order~,
        )
      },
    )
    match branch_result {
      Ok(accepted_now) => {
        next_order += accepted_now.length()
        for candidate in accepted_now {
          if accepted_branch_prefer(candidate, accepted) {
            accepted = Some(candidate)
          }
        }
      }
      Err(error) => if first_error is None { first_error = Some(error) }
    }
  }
  match accepted {
    Some(result) => result.tree
    None =>
      match first_error {
        Some(error) => raise error
        None => raise ParseError::ParseStackUnderflow
      }
  }
}

///|
fn parse_branch_step(
  language : Language,
  tables : @tables.ValidatedLanguageTables,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  included_ranges~ : Array[@api.Range],
  logger~ : Logger?,
  branch : ParseBranchState,
  branches : Array[ParseBranchState],
  next_order~ : Int,
) -> Array[AcceptedParseBranch] raise ParseError {
  guard branch.stack.last() is Some(top) else {
    raise ParseError::ParseStackUnderflow
  }
  match synthetic_extra_reduce_action(tables, top.state_id) {
    Some(action) => {
      if tables.is_extra_symbol(symbol_id_from_int(action.symbol_id)) {
        reduce_extra_stack(
          language,
          tables,
          branch.nodes,
          branch.leading_extras,
          branch.stack,
          branch.pending_extras,
          action~,
          fallback_byte=branch.current_byte,
          fallback_point=branch.current_point,
          force_fragile=true,
        )
      } else {
        reduce_stack(
          language,
          tables,
          branch.nodes,
          branch.leading_extras,
          branch.stack,
          symbol_id=action.symbol_id,
          child_count=action.child_count,
          dynamic_precedence=action.dynamic_precedence,
          production_id=action.production_id,
          force_fragile=true,
          fallback_byte=branch.current_byte,
          fallback_point=branch.current_point,
          trailing_extras=[],
        )
      }
      branches.push(branch)
      return []
    }
    None => ()
  }
  let token = match branch.lookahead {
    Some(value) => value
    None => {
      let lex_result : Result[LexedToken, ParseError] = capture_parser_result(() => {
        lex_main_token(
          tables,
          top.state_id,
          input,
          encoding~,
          decode_callback~,
          chunk_end_offsets~,
          branch.current_byte,
          branch.current_point,
          included_ranges~,
          external_scanner_state=branch.last_external_scanner_state,
          logger~,
        )
      })
      match lex_result {
        Ok(value) => {
          branch.lookahead = Some(value)
          value
        }
        Err(LexError(_)) => {
          if try_reduce_all_potential_at(
              language,
              tables,
              branch.nodes,
              branch.leading_extras,
              branch.stack,
              top.state_id,
              fallback_byte=branch.current_byte,
              fallback_point=branch.current_point,
              logger~,
            ) {
            branches.push(branch)
            return []
          }
          if branch.stack.length() > 1 &&
            !branch.did_insert_missing_token &&
            try_insert_missing_token_for_lex_error(
              language,
              tables,
              input,
              encoding~,
              decode_callback~,
              chunk_end_offsets~,
              included_ranges~,
              branch.nodes,
              branch.leading_extras,
              branch.stack,
              top.state_id,
              branch.current_byte,
              branch.current_point,
              external_scanner_state=branch.last_external_scanner_state,
              branch.pending_extras,
              logger~,
            ) {
            branch.did_insert_missing_token = true
            branch.parse_has_error = true
            branch.pending_extras = []
            branches.push(branch)
            return []
          }
          raise ParseError::LexError(
            byte_offset=branch.current_byte,
            state_id=state_id_from_int(top.state_id),
          )
        }
        Err(error) => raise error
      }
    }
  }
  let token_symbol = symbol_id_from_int(token.symbol_id)
  let accepted : Array[AcceptedParseBranch] = []
  match
    tables.parse_action_list_for_symbol(
      state_id_from_int(top.state_id),
      token_symbol,
    ) {
    Some(action_list) => {
      let runtime_actions = runtime_parse_actions(action_list.actions)
      if runtime_actions.length() == 0 {
        raise ParseError::ParseTableError(
          state_id=state_id_from_int(top.state_id),
          symbol_id=token_symbol,
        )
      } else if action_list.reusable || runtime_actions.length() == 1 {
        let selected = match selected_parse_action(action_list.actions) {
          Some(selected) => selected.action
          None => runtime_actions[0]
        }
        match
          apply_parse_branch_action(
            language,
            tables,
            input,
            encoding~,
            decode_callback~,
            chunk_end_offsets~,
            included_ranges~,
            branch,
            token,
            selected,
            force_fragile=action_list.actions.length() > 1,
          ) {
          Some(result) => accepted.push(result)
          None => branches.push(branch)
        }
      } else {
        for i in 0..<runtime_actions.length() {
          let child = parse_branch_clone(branch, order=next_order + i)
          match
            apply_parse_branch_action(
              language,
              tables,
              input,
              encoding~,
              decode_callback~,
              chunk_end_offsets~,
              included_ranges~,
              child,
              token,
              runtime_actions[i],
              force_fragile=true,
            ) {
            Some(result) => accepted.push(result)
            None => branches.push(child)
          }
        }
      }
    }
    None =>
      if try_reduce_all_potential(
          language,
          tables,
          branch.nodes,
          branch.leading_extras,
          branch.stack,
          top.state_id,
          token,
          branch.pending_extras,
          logger~,
        ) {
        branches.push(branch)
      } else if !branch.did_insert_missing_token &&
        try_insert_missing_token(
          language,
          tables,
          branch.nodes,
          branch.leading_extras,
          branch.stack,
          top.state_id,
          token,
          branch.pending_extras,
          logger~,
        ) {
        branch.did_insert_missing_token = true
        branch.parse_has_error = true
        branch.pending_extras = []
        branches.push(branch)
      } else if try_synchronize_stack_to_root(
          language,
          tables,
          branch.nodes,
          branch.leading_extras,
          branch.stack,
          branch.pending_extras,
          token,
          logger~,
        ) {
        branch.parse_has_error = true
        branches.push(branch)
      } else if branch.stack.length() > 1 {
        match
          try_skip_unexpected_token(
            language,
            input,
            encoding~,
            decode_callback~,
            chunk_end_offsets~,
            branch.nodes,
            branch.leading_extras,
            branch.pending_extras,
            token,
            logger~,
          ) {
          Some((next_byte, next_point)) => {
            match token.external_scanner_state {
              Some(state) => branch.last_external_scanner_state = state
              None => ()
            }
            branch.current_byte = next_byte
            branch.current_point = next_point
            branch.lookahead = None
            branch.parse_has_error = true
            branches.push(branch)
          }
          None =>
            raise ParseError::ParseTableError(
              state_id=state_id_from_int(top.state_id),
              symbol_id=token_symbol,
            )
        }
      } else {
        raise ParseError::ParseTableError(
          state_id=state_id_from_int(top.state_id),
          symbol_id=token_symbol,
        )
      }
  }
  accepted
}

///|
fn runtime_parse_actions(
  actions : Array[@tables.GeneratedParseAction],
) -> Array[@tables.GeneratedParseAction] {
  let result : Array[@tables.GeneratedParseAction] = []
  for action in actions {
    if parse_action_runtime_candidate(action) {
      result.push(action)
    }
  }
  result
}

///|
fn apply_parse_branch_action(
  language : Language,
  tables : @tables.ValidatedLanguageTables,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  included_ranges~ : Array[@api.Range],
  branch : ParseBranchState,
  token : LexedToken,
  action : @tables.GeneratedParseAction,
  force_fragile~ : Bool,
) -> AcceptedParseBranch? raise ParseError {
  match action {
    @tables.GeneratedParseAction::Accept => {
      parser_log(None, Parse, "parse accept")
      Some(
        parse_branch_accept(
          language,
          branch,
          included_ranges~,
          input~,
          encoding~,
          decode_callback~,
          chunk_end_offsets~,
        ),
      )
    }
    @tables.GeneratedParseAction::Shift(state_id~, is_repetition~) => {
      if is_repetition {
        raise ParseError::ParseTableError(
          state_id=state_id_from_int(branch.stack.last().unwrap().state_id),
          symbol_id=symbol_id_from_int(token.symbol_id),
        )
      }
      let node_index = push_parser_node(
        branch.nodes,
        branch.leading_extras,
        node_data_for_symbol(
          language,
          token.symbol_id,
          token.start_byte,
          token.end_byte,
          token.start_point,
          token.end_point,
          external_scanner_state=token.external_scanner_state,
          external_scanner_state_changed=token.external_scanner_state_changed,
          external_scanner_depends_on_column=token.external_scanner_depends_on_column,
          lookahead_byte_count=token.lookahead_byte_count,
          parse_state=Some(
            state_id_from_int(branch.stack.last().unwrap().state_id),
          ),
          next_parse_state=Some(state_id_from_int(state_id)),
        ),
        leading=branch.pending_extras,
      )
      branch.pending_extras = []
      branch.stack.push({ state_id, node_index })
      match token.external_scanner_state {
        Some(state) => branch.last_external_scanner_state = state
        None => ()
      }
      branch.current_byte = token.end_byte
      branch.current_point = token.end_point
      branch.lookahead = None
      None
    }
    @tables.GeneratedParseAction::ShiftExtra => {
      let top_state = match branch.stack.last() {
        Some(top) => top.state_id
        None => raise ParseError::ParseStackUnderflow
      }
      let node_index = push_parser_node(branch.nodes, branch.leading_extras, {
        ..node_data_for_symbol(
          language,
          token.symbol_id,
          token.start_byte,
          token.end_byte,
          token.start_point,
          token.end_point,
          external_scanner_state=token.external_scanner_state,
          external_scanner_state_changed=token.external_scanner_state_changed,
          external_scanner_depends_on_column=token.external_scanner_depends_on_column,
          lookahead_byte_count=token.lookahead_byte_count,
          parse_state=Some(state_id_from_int(top_state)),
          next_parse_state=Some(state_id_from_int(top_state)),
        ),
        extra: true,
      })
      branch.pending_extras.push(node_index)
      match token.external_scanner_state {
        Some(state) => branch.last_external_scanner_state = state
        None => ()
      }
      branch.current_byte = token.end_byte
      branch.current_point = token.end_point
      branch.lookahead = None
      None
    }
    @tables.GeneratedParseAction::Recover =>
      if token.symbol_id == 0 && token.end_byte <= token.start_byte {
        push_empty_recovered_error_node(
          language,
          branch.nodes,
          branch.leading_extras,
          branch.stack,
          token.start_byte,
          token.start_point,
          logger=None,
        )
        branch.parse_has_error = true
        None
      } else {
        match
          try_skip_unexpected_token(
            language,
            input,
            encoding~,
            decode_callback~,
            chunk_end_offsets~,
            branch.nodes,
            branch.leading_extras,
            branch.pending_extras,
            token,
            logger=None,
          ) {
          Some((next_byte, next_point)) => {
            match token.external_scanner_state {
              Some(state) => branch.last_external_scanner_state = state
              None => ()
            }
            branch.current_byte = next_byte
            branch.current_point = next_point
            branch.lookahead = None
            branch.parse_has_error = true
            None
          }
          None =>
            raise ParseError::ParseTableError(
              state_id=state_id_from_int(branch.stack.last().unwrap().state_id),
              symbol_id=symbol_id_from_int(token.symbol_id),
            )
        }
      }
    @tables.GeneratedParseAction::Reduce(
      symbol_id~,
      child_count~,
      dynamic_precedence~,
      production_id~
    ) => {
      reduce_stack(
        language,
        tables,
        branch.nodes,
        branch.leading_extras,
        branch.stack,
        symbol_id~,
        child_count~,
        dynamic_precedence~,
        production_id~,
        force_fragile~,
        fallback_byte=token.start_byte,
        fallback_point=token.start_point,
        trailing_extras=[],
      )
      None
    }
  }
}

///|
fn parse_branch_accept(
  language : Language,
  branch : ParseBranchState,
  included_ranges~ : Array[@api.Range],
  input~ : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
) -> AcceptedParseBranch raise ParseError {
  let tree = parser_tree_from_stack(
    language,
    branch.nodes,
    branch.leading_extras,
    branch.stack,
    pending_extras=branch.pending_extras,
    included_ranges~,
    source_bytes=if decode_callback is None { Some(input) } else { None },
    source_encoding=encoding,
    source_chunk_end_offsets=chunk_end_offsets,
  )
  let root_index = match branch.stack.last() {
    Some(top) => top.node_index
    None => -1
  }
  let (error_cost, dynamic_precedence) = if root_index >= 0 &&
    root_index < branch.nodes.length() {
    (
      branch.nodes[root_index].error_cost,
      branch.nodes[root_index].dynamic_precedence,
    )
  } else {
    (0, 0)
  }
  { tree, error_cost, dynamic_precedence, order: branch.order }
}

///|
fn parse_branch_clone(
  branch : ParseBranchState,
  order~ : Int,
) -> ParseBranchState {
  {
    stack: branch.stack.copy(),
    nodes: branch.nodes.copy(),
    leading_extras: copy_leading_extras(branch.leading_extras),
    pending_extras: branch.pending_extras.copy(),
    current_byte: branch.current_byte,
    current_point: branch.current_point,
    lookahead: branch.lookahead,
    last_external_scanner_state: branch.last_external_scanner_state,
    did_insert_missing_token: branch.did_insert_missing_token,
    parse_has_error: branch.parse_has_error,
    order,
  }
}

///|
fn parse_branch_outstanding_state(
  branch : ParseBranchState,
) -> OutstandingParseState {
  {
    stack: branch.stack,
    nodes: branch.nodes,
    leading_extras: branch.leading_extras,
    pending_extras: branch.pending_extras,
    current_byte: branch.current_byte,
    current_point: branch.current_point,
    lookahead: branch.lookahead,
    last_external_scanner_state: branch.last_external_scanner_state,
    did_insert_missing_token: branch.did_insert_missing_token,
    parse_has_error: branch.parse_has_error,
  }
}

///|
fn accepted_branch_prefer(
  candidate : AcceptedParseBranch,
  current : AcceptedParseBranch?,
) -> Bool {
  match current {
    Some(current) =>
      if candidate.error_cost != current.error_cost {
        candidate.error_cost < current.error_cost
      } else if candidate.dynamic_precedence != current.dynamic_precedence {
        candidate.dynamic_precedence > current.dynamic_precedence
      } else {
        candidate.order < current.order
      }
    None => true
  }
}

///|
fn selected_parse_action(
  actions : Array[@tables.GeneratedParseAction],
) -> SelectedParseAction? {
  guard actions.length() > 0 else { return None }
  let mut action : @tables.GeneratedParseAction? = None
  for candidate in actions {
    if parse_action_runtime_candidate(candidate) {
      match action {
        Some(current) =>
          if parse_action_prefer(candidate, current) {
            action = Some(candidate)
          }
        None => action = Some(candidate)
      }
    }
  }
  match action {
    Some(action) => Some({ action, force_fragile: actions.length() > 1 })
    None => None
  }
}

///|
fn parse_action_runtime_candidate(
  action : @tables.GeneratedParseAction,
) -> Bool {
  match action {
    @tables.GeneratedParseAction::Shift(is_repetition~, ..) => !is_repetition
    _ => true
  }
}

///|
fn parse_action_prefer(
  candidate : @tables.GeneratedParseAction,
  current : @tables.GeneratedParseAction,
) -> Bool {
  match (candidate, current) {
    (
      @tables.GeneratedParseAction::Reduce(
        dynamic_precedence=candidate_precedence,
        ..
      ),
      @tables.GeneratedParseAction::Reduce(
        dynamic_precedence=current_precedence,
        ..
      ),
    ) => candidate_precedence > current_precedence
    _ => false
  }
}

///|
fn try_insert_missing_token(
  language : Language,
  tables : @tables.ValidatedLanguageTables,
  nodes : Array[NodeData],
  leading_extras : Array[Array[Int]],
  stack : Array[ParseStackEntry],
  state_id : Int,
  token : LexedToken,
  pending_extras : Array[Int],
  logger~ : Logger?,
) -> Bool {
  for candidate_id in 1..<tables.token_count() {
    match recovery_shift_state_for_symbol(tables, state_id, candidate_id) {
      Some(next_state) =>
        if next_state != 0 &&
          next_state != state_id &&
          state_has_reduce_for_symbol(tables, next_state, token.symbol_id) {
          let node_index = push_parser_node(
            nodes,
            leading_extras,
            {
              ..node_data_for_symbol(
                language,
                candidate_id,
                token.start_byte,
                token.start_byte,
                token.start_point,
                token.start_point,
              ),
              missing: true,
              has_error: true,
              error_cost: error_cost_per_missing_tree + error_cost_per_recovery,
              fragile_left: true,
              fragile_right: true,
            },
            leading=pending_extras,
          )
          stack.push({ state_id: next_state, node_index })
          parser_log(logger, Parse, "insert missing token")
          return true
        }
      None => ()
    }
  }
  false
}

///|
fn try_insert_missing_token_for_lex_error(
  language : Language,
  tables : @tables.ValidatedLanguageTables,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  included_ranges~ : Array[@api.Range],
  nodes : Array[NodeData],
  leading_extras : Array[Array[Int]],
  stack : Array[ParseStackEntry],
  state_id : Int,
  current_byte : UInt,
  current_point : @api.Point,
  external_scanner_state~ : Bytes,
  pending_extras : Array[Int],
  logger~ : Logger?,
) -> Bool raise ParseError {
  match tables.lex_mode(state_id_from_int(state_id)) {
    Some(mode) =>
      if mode.external_lex_state != 0 &&
        mode.lex_state == @tables.lex_state_none() {
        return false
      }
    None => ()
  }
  for candidate_id in 1..<tables.token_count() {
    match recovery_shift_state_for_symbol(tables, state_id, candidate_id) {
      Some(next_state) =>
        if next_state != 0 &&
          next_state != state_id &&
          parse_state_can_lex_current_input(
            tables,
            next_state,
            input,
            encoding~,
            decode_callback~,
            chunk_end_offsets~,
            current_byte,
            current_point,
            included_ranges~,
            external_scanner_state~,
          ) {
          let node_index = push_parser_node(
            nodes,
            leading_extras,
            {
              ..node_data_for_symbol(
                language, candidate_id, current_byte, current_byte, current_point,
                current_point,
              ),
              missing: true,
              has_error: true,
              error_cost: error_cost_per_missing_tree + error_cost_per_recovery,
              fragile_left: true,
              fragile_right: true,
            },
            leading=pending_extras,
          )
          stack.push({ state_id: next_state, node_index })
          parser_log(logger, Parse, "insert missing token")
          return true
        }
      None => ()
    }
  }
  false
}

///|
fn parse_state_can_lex_current_input(
  tables : @tables.ValidatedLanguageTables,
  state_id : Int,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  current_byte : UInt,
  current_point : @api.Point,
  included_ranges~ : Array[@api.Range],
  external_scanner_state~ : Bytes,
) -> Bool raise ParseError {
  let result : Result[LexedToken, ParseError] = capture_parser_result(() => {
    lex_main_token(
      tables,
      state_id,
      input,
      encoding~,
      decode_callback~,
      chunk_end_offsets~,
      current_byte,
      current_point,
      included_ranges~,
      external_scanner_state~,
      logger=None,
    )
  })
  match result {
    Ok(_) => true
    Err(LexError(_)) => false
    Err(error) => raise error
  }
}

///|
fn recovery_shift_state_for_symbol(
  tables : @tables.ValidatedLanguageTables,
  state_id : Int,
  symbol_id : Int,
) -> Int? {
  match
    tables.parse_action_list_for_symbol(
      state_id_from_int(state_id),
      symbol_id_from_int(symbol_id),
    ) {
    Some(action_list) => {
      for action in action_list.actions {
        match action {
          @tables.GeneratedParseAction::Shift(state_id~, is_repetition~) =>
            if !is_repetition {
              return Some(state_id)
            }
          _ => ()
        }
      }
      None
    }
    None => None
  }
}

///|
fn try_reduce_all_potential(
  language : Language,
  tables : @tables.ValidatedLanguageTables,
  nodes : Array[NodeData],
  leading_extras : Array[Array[Int]],
  stack : Array[ParseStackEntry],
  state_id : Int,
  token : LexedToken,
  _trailing_extras : Array[Int],
  logger~ : Logger?,
) -> Bool raise ParseError {
  try_reduce_all_potential_at(
    language,
    tables,
    nodes,
    leading_extras,
    stack,
    state_id,
    fallback_byte=token.start_byte,
    fallback_point=token.start_point,
    logger~,
  )
}

///|
fn try_reduce_all_potential_at(
  language : Language,
  tables : @tables.ValidatedLanguageTables,
  nodes : Array[NodeData],
  leading_extras : Array[Array[Int]],
  stack : Array[ParseStackEntry],
  state_id : Int,
  fallback_byte~ : UInt,
  fallback_point~ : @api.Point,
  logger~ : Logger?,
) -> Bool raise ParseError {
  if tables.token_count() <= 1 {
    return false
  }
  guard tables.lookahead_symbols(state_id_from_int(state_id)) is Some(symbols) else {
    return false
  }
  let mut selected_reduce : PotentialReduceAction? = None
  let mut candidate_id = tables.token_count() - 1
  while candidate_id > 0 {
    if lookahead_symbols_contains(symbols, candidate_id) {
      match
        tables.parse_action_list_for_symbol(
          state_id_from_int(state_id),
          symbol_id_from_int(candidate_id),
        ) {
        Some(action_list) =>
          for action in action_list.actions {
            match action {
              @tables.GeneratedParseAction::Reduce(
                symbol_id~,
                child_count~,
                dynamic_precedence~,
                production_id~
              ) =>
                if child_count > 0 {
                  let candidate = {
                    symbol_id,
                    child_count,
                    dynamic_precedence,
                    production_id,
                  }
                  if potential_reduce_prefer(candidate, selected_reduce) {
                    selected_reduce = Some(candidate)
                  }
                }
              _ => ()
            }
          }
        None => ()
      }
    }
    candidate_id -= 1
  }
  match selected_reduce {
    Some(action) => {
      reduce_stack(
        language,
        tables,
        nodes,
        leading_extras,
        stack,
        symbol_id=action.symbol_id,
        child_count=action.child_count,
        dynamic_precedence=action.dynamic_precedence,
        production_id=action.production_id,
        force_fragile=true,
        fallback_byte~,
        fallback_point~,
        trailing_extras=[],
      )
      parser_log(logger, Parse, "reduce all potential")
      true
    }
    None => false
  }
}

///|
fn potential_reduce_prefer(
  candidate : PotentialReduceAction,
  current : PotentialReduceAction?,
) -> Bool {
  match current {
    Some(current) => candidate.symbol_id > current.symbol_id
    None => true
  }
}

///|
fn synthetic_extra_reduce_action(
  tables : @tables.ValidatedLanguageTables,
  state_id : Int,
) -> PotentialReduceAction? {
  let is_extra_state = tables.is_extra_state(state_id_from_int(state_id))
  let mut selected : PotentialReduceAction? = None
  match
    tables.parse_action_list_for_symbol(
      state_id_from_int(state_id),
      symbol_id_from_int(0),
    ) {
    Some(action_list) =>
      for action in action_list.actions {
        match action {
          @tables.GeneratedParseAction::Reduce(
            symbol_id~,
            child_count~,
            dynamic_precedence~,
            production_id~
          ) =>
            if tables.is_extra_symbol(symbol_id_from_int(symbol_id)) ||
              is_extra_state {
              let candidate = {
                symbol_id,
                child_count,
                dynamic_precedence,
                production_id,
              }
              if potential_reduce_prefer(candidate, selected) {
                selected = Some(candidate)
              }
            }
          _ => ()
        }
      }
    None => ()
  }
  selected
}

///|
fn reduce_extra_stack(
  language : Language,
  tables : @tables.ValidatedLanguageTables,
  nodes : Array[NodeData],
  leading_extras : Array[Array[Int]],
  stack : Array[ParseStackEntry],
  pending_extras : Array[Int],
  action~ : PotentialReduceAction,
  fallback_byte~ : UInt,
  fallback_point~ : @api.Point,
  force_fragile~ : Bool,
) -> Unit raise ParseError {
  reduce_stack(
    language,
    tables,
    nodes,
    leading_extras,
    stack,
    symbol_id=action.symbol_id,
    child_count=action.child_count,
    dynamic_precedence=action.dynamic_precedence,
    production_id=action.production_id,
    force_fragile~,
    fallback_byte~,
    fallback_point~,
    trailing_extras=pending_extras,
  )
  guard stack.pop() is Some(extra_entry) && extra_entry.node_index >= 0 else {
    raise ParseError::ParseStackUnderflow
  }
  let extra_index = extra_entry.node_index
  let carried_leading_extras = match leading_extras.get(extra_index) {
    Some(extras) => extras.copy()
    None => []
  }
  match leading_extras.get(extra_index) {
    Some(extras) =>
      while !extras.is_empty() {
        ignore(extras.pop())
      }
    None => ()
  }
  while !pending_extras.is_empty() {
    ignore(pending_extras.pop())
  }
  for extra in carried_leading_extras {
    pending_extras.push(extra)
  }
  if extra_index >= 0 && extra_index < nodes.length() {
    nodes[extra_index] = { ..nodes[extra_index], extra: true }
  }
  pending_extras.push(extra_index)
}

///|
fn lookahead_symbols_contains(
  symbols : Array[@api.SymbolId],
  symbol_id : Int,
) -> Bool {
  for symbol in symbols {
    if symbol.value().reinterpret_as_int() == symbol_id {
      return true
    }
  }
  false
}

///|
fn try_skip_unexpected_token(
  language : Language,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  nodes : Array[NodeData],
  leading_extras : Array[Array[Int]],
  pending_extras : Array[Int],
  token : LexedToken,
  logger~ : Logger?,
) -> (UInt, @api.Point)? raise ParseError {
  if token.end_byte <= token.start_byte {
    return None
  }
  let (lookahead_char, lookahead_bytes) = recovered_error_lookahead(
    input,
    encoding~,
    decode_callback~,
    chunk_end_offsets~,
    token.start_byte,
    token.end_byte,
  )
  push_recovered_error_node(
    language,
    nodes,
    leading_extras,
    pending_extras,
    token.start_byte,
    token.end_byte,
    token.start_point,
    token.end_point,
    lookahead_char~,
    lookahead_bytes~,
    log_message="skip unexpected token",
    logger~,
  )
  Some((token.end_byte, token.end_point))
}

///|
fn try_synchronize_stack_to_root(
  language : Language,
  tables : @tables.ValidatedLanguageTables,
  nodes : Array[NodeData],
  leading_extras : Array[Array[Int]],
  stack : Array[ParseStackEntry],
  pending_extras : Array[Int],
  token : LexedToken,
  logger~ : Logger?,
) -> Bool {
  if stack.length() <= 1 {
    return false
  }
  let root = stack[0]
  if tables.parse_action_list_for_symbol(
      state_id_from_int(root.state_id),
      symbol_id_from_int(token.symbol_id),
    )
    is None {
    return false
  }
  let children : Array[Int] = []
  for i in 1..<stack.length() {
    let node_index = stack[i].node_index
    if node_index >= 0 {
      children.push(node_index)
    }
  }
  if children.is_empty() {
    return false
  }
  let (start_byte, end_byte, start_point, end_point) = reduced_range(
    nodes,
    children,
    fallback_byte=token.start_byte,
    fallback_point=token.start_point,
  )
  let error_index = push_parser_node(
    nodes,
    leading_extras,
    {
      ..error_node_data(
        language,
        start_byte,
        end_byte,
        start_point,
        end_point,
        error_cost=node_children_error_cost(nodes, children) +
          recovered_error_cost(start_byte, end_byte, start_point, end_point),
      ),
      children,
    },
    leading=pending_extras,
  )
  for child in children {
    if child >= 0 && child < nodes.length() {
      nodes[child] = { ..nodes[child], parent: error_index }
    }
  }
  while stack.length() > 1 {
    ignore(stack.pop())
  }
  while !pending_extras.is_empty() {
    ignore(pending_extras.pop())
  }
  pending_extras.push(error_index)
  parser_log(logger, Parse, "synchronize error")
  true
}

///|
fn state_has_reduce_for_symbol(
  tables : @tables.ValidatedLanguageTables,
  state_id : Int,
  symbol_id : Int,
) -> Bool {
  match
    tables.parse_action_list_for_symbol(
      state_id_from_int(state_id),
      symbol_id_from_int(symbol_id),
    ) {
    Some(action_list) => {
      for action in action_list.actions {
        match action {
          @tables.GeneratedParseAction::Reduce(child_count~, ..) =>
            if child_count > 0 {
              return true
            }
          _ => ()
        }
      }
      false
    }
    None => false
  }
}

///|
fn recover_lex_error(
  language : Language,
  tables : @tables.ValidatedLanguageTables,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  current_byte : UInt,
  current_point : @api.Point,
  included_ranges~ : Array[@api.Range],
  external_scanner_state~ : Bytes,
  nodes : Array[NodeData],
  leading_extras : Array[Array[Int]],
  pending_extras : Array[Int],
  logger~ : Logger?,
) -> (UInt, @api.Point)? raise ParseError {
  let (start_byte, start_point) = snap_to_included_range(
    current_byte, current_point, included_ranges,
  )
  if external_context_eof(input, start_byte, included_ranges) {
    return None
  }
  match
    lex_error_state_token(
      tables,
      input,
      encoding~,
      decode_callback~,
      chunk_end_offsets~,
      start_byte,
      start_point,
      included_ranges~,
      external_scanner_state~,
      logger~,
    ) {
    Some(token) => {
      let (lookahead_char, lookahead_bytes) = recovered_error_lookahead(
        input,
        encoding~,
        decode_callback~,
        chunk_end_offsets~,
        token.start_byte,
        token.end_byte,
      )
      push_recovered_error_node(
        language,
        nodes,
        leading_extras,
        pending_extras,
        token.start_byte,
        token.end_byte,
        token.start_point,
        token.end_point,
        lookahead_char~,
        lookahead_bytes~,
        log_message="recover lex error",
        logger~,
      )
      return Some((token.end_byte, token.end_point))
    }
    None => ()
  }
  let start_index = start_byte.reinterpret_as_int()
  let input_end = input.length().reinterpret_as_uint()
  let active_end_uint = included_range_end_for_byte(
    included_ranges, start_byte, input_end,
  )
  let active_end = if active_end_uint > input_end {
    input.length()
  } else {
    active_end_uint.reinterpret_as_int()
  }
  guard decode_input_scalar(
      input,
      start_index,
      encoding~,
      decode_callback~,
      chunk_end_offsets~,
    )
    is Some(scalar) else {
    return None
  }
  if start_index >= active_end {
    return None
  }
  let byte_width = if start_index + scalar.byte_width <= active_end {
    scalar.byte_width
  } else {
    1
  }
  let codepoint = if byte_width == scalar.byte_width {
    scalar.codepoint
  } else {
    decode_error_codepoint
  }
  let end_byte = (start_index + byte_width).reinterpret_as_uint()
  let end_point = advance_point(start_point, byte_width, codepoint)
  let lookahead_bytes = consumed_input_bytes(input, start_index, byte_width)
  push_recovered_error_node(
    language,
    nodes,
    leading_extras,
    pending_extras,
    start_byte,
    end_byte,
    start_point,
    end_point,
    lookahead_char=codepoint,
    lookahead_bytes~,
    log_message="recover lex error",
    logger~,
  )
  Some((end_byte, end_point))
}

///|
fn lex_error_state_token(
  tables : @tables.ValidatedLanguageTables,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  start_byte : UInt,
  start_point : @api.Point,
  included_ranges~ : Array[@api.Range],
  external_scanner_state~ : Bytes,
  logger~ : Logger?,
) -> LexedToken? raise ParseError {
  let result : Result[LexedToken, ParseError] = capture_parser_result(() => {
    lex_main_token(
      tables,
      0,
      input,
      encoding~,
      decode_callback~,
      chunk_end_offsets~,
      start_byte,
      start_point,
      included_ranges~,
      external_scanner_state~,
      logger~,
    )
  })
  match result {
    Ok(token) =>
      if token.end_byte > token.start_byte {
        Some(token)
      } else {
        None
      }
    Err(LexError(_)) => None
    Err(error) => raise error
  }
}

///|
fn recovered_error_lookahead(
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  start_byte : UInt,
  end_byte : UInt,
) -> (Int, Bytes) raise ParseError {
  let start_index = start_byte.reinterpret_as_int()
  let end_index = end_byte.reinterpret_as_int()
  let span_width = end_index - start_index
  guard span_width > 0 else { return (decode_error_codepoint, Bytes::new(0)) }
  match
    decode_input_scalar(
      input,
      start_index,
      encoding~,
      decode_callback~,
      chunk_end_offsets~,
    ) {
    Some(scalar) =>
      if scalar.byte_width <= span_width {
        (
          scalar.codepoint,
          consumed_input_bytes(input, start_index, scalar.byte_width),
        )
      } else {
        (decode_error_codepoint, consumed_input_bytes(input, start_index, 1))
      }
    None =>
      (decode_error_codepoint, consumed_input_bytes(input, start_index, 1))
  }
}

///|
fn push_recovered_error_node(
  language : Language,
  nodes : Array[NodeData],
  leading_extras : Array[Array[Int]],
  pending_extras : Array[Int],
  start_byte : UInt,
  end_byte : UInt,
  start_point : @api.Point,
  end_point : @api.Point,
  lookahead_char~ : Int,
  lookahead_bytes~ : Bytes,
  log_message~ : String,
  logger~ : Logger?,
) -> Unit {
  let node_index = push_parser_node(
    nodes,
    leading_extras,
    error_node_data(
      language,
      start_byte,
      end_byte,
      start_point,
      end_point,
      lookahead_char=Some(lookahead_char),
      lookahead_bytes=Some(lookahead_bytes),
    ),
  )
  pending_extras.push(node_index)
  parser_log(logger, Parse, log_message)
}

///|
fn push_empty_recovered_error_node(
  language : Language,
  nodes : Array[NodeData],
  leading_extras : Array[Array[Int]],
  stack : Array[ParseStackEntry],
  byte : UInt,
  point : @api.Point,
  logger~ : Logger?,
) -> Unit {
  let node_index = push_parser_node(
    nodes,
    leading_extras,
    error_node_data(
      language,
      byte,
      byte,
      point,
      point,
      error_cost=error_cost_per_recovery,
    ),
  )
  stack.push({ state_id: 1, node_index })
  parser_log(logger, Parse, "recover eof")
}

///|
fn consumed_input_bytes(
  input : Bytes,
  start_index : Int,
  byte_width : Int,
) -> Bytes {
  let values : Array[Byte] = []
  for index in start_index..<(start_index + byte_width) {
    values.push(input[index])
  }
  Bytes::from_array(values)
}

///|
fn error_node_data(
  language : Language,
  start_byte : UInt,
  end_byte : UInt,
  start_point : @api.Point,
  end_point : @api.Point,
  lookahead_char? : Int? = None,
  lookahead_bytes? : Bytes? = None,
  error_cost? : Int = recovered_error_cost(
    start_byte, end_byte, start_point, end_point,
  ),
) -> NodeData {
  let error_symbol = match language.symbol_for_name("ERROR", is_named=true) {
    Some(symbol) => symbol
    None => @api.SymbolId::new(0)
  }
  NodeData::new(
    kind="ERROR",
    grammar_kind="ERROR",
    symbol=error_symbol,
    grammar_symbol=error_symbol,
    start_byte~,
    end_byte~,
    start_point~,
    end_point~,
    has_error=true,
    is_error=true,
    error_cost~,
    fragile_left=true,
    fragile_right=true,
    lookahead_char~,
    lookahead_bytes~,
  )
}

///|
fn recovered_error_cost(
  start_byte : UInt,
  end_byte : UInt,
  start_point : @api.Point,
  end_point : @api.Point,
) -> Int {
  let skipped_bytes = if end_byte > start_byte {
    (end_byte - start_byte).reinterpret_as_int()
  } else {
    0
  }
  let skipped_lines = if end_point.row > start_point.row {
    (end_point.row - start_point.row).reinterpret_as_int()
  } else {
    0
  }
  error_cost_per_recovery +
  error_cost_per_skipped_tree +
  skipped_bytes * error_cost_per_skipped_char +
  skipped_lines * error_cost_per_skipped_line
}

///|
fn create_external_scanner_session(
  tables : @tables.ValidatedLanguageTables,
) -> @tables.ExternalScannerDescriptor? raise ParseError {
  let scanner = tables.external_scanner()
  if !scanner.has_scan_callback() {
    return None
  }
  let result : Result[Unit, @api.ScannerError] = capture_parser_result(() => {
    scanner.create()
  })
  match result {
    Ok(_) => Some(scanner)
    Err(error) => raise ParseError::ScannerError(error)
  }
}

///|
fn destroy_external_scanner_session(
  scanner : @tables.ExternalScannerDescriptor?,
) -> Unit raise ParseError {
  match scanner {
    Some(scanner) => {
      let result : Result[Unit, @api.ScannerError] = capture_parser_result(() => {
        scanner.destroy()
      })
      match result {
        Ok(_) => ()
        Err(error) => raise ParseError::ScannerError(error)
      }
    }
    None => ()
  }
}

///|
fn Parser::destroy_outstanding_external_scanner(self : Parser) -> Unit {
  match self.outstanding_external_scanner {
    Some(scanner) => {
      self.outstanding_external_scanner = None
      let _ : Result[Unit, @api.ScannerError] = capture_parser_result(() => {
        scanner.destroy()
      })
    }
    None => ()
  }
}

///|
fn parser_log(logger : Logger?, kind : LogType, message : String) -> Unit {
  match logger {
    Some(value) => value.log(kind, message)
    None => ()
  }
}

///|
fn language_identity_matches(left : Language, right : Language) -> Bool {
  left.tables == right.tables
}

///|
fn validate_included_ranges(
  ranges : Array[@api.Range],
) -> Unit raise IncludedRangesError {
  for i in 0..<ranges.length() {
    let range = ranges[i]
    if range.start_byte > range.end_byte {
      raise IncludedRangesError::InvalidRange(index=i, range~)
    }
    if i > 0 {
      let previous = ranges[i - 1]
      if range.start_byte < previous.end_byte {
        raise IncludedRangesError::Overlap(index=i, previous~, current=range)
      }
    }
  }
}

///|
fn parser_tree_from_stack(
  language : Language,
  nodes : Array[NodeData],
  leading_extras : Array[Array[Int]],
  stack : Array[ParseStackEntry],
  pending_extras? : Array[Int] = [],
  included_ranges~ : Array[@api.Range],
  source_bytes? : Bytes? = None,
  source_encoding? : @api.InputEncoding = Utf8,
  source_chunk_end_offsets? : Array[Int] = [],
) -> Tree raise ParseError {
  guard stack.last() is Some(top) && top.node_index >= 0 else {
    raise ParseError::ParseStackUnderflow
  }
  let root_leading_extras = match leading_extras.get(top.node_index) {
    Some(extras) => extras
    None => []
  }
  attach_extras_to_root(
    nodes,
    top.node_index,
    leading_extras=root_leading_extras,
    trailing_extras=pending_extras,
  )
  let tree_ranges = if included_ranges.is_empty() {
    [@api.Range::unbounded(start_byte=0, start_point=@api.Point::zero())]
  } else {
    included_ranges.copy()
  }
  Tree::from_fixture(
    language,
    nodes,
    included_ranges=tree_ranges,
    root_index=top.node_index,
    source_bytes~,
    source_encoding~,
    source_chunk_end_offsets~,
  )
}

///|
fn attach_extras_to_root(
  nodes : Array[NodeData],
  root_index : Int,
  leading_extras~ : Array[Int],
  trailing_extras~ : Array[Int],
) -> Unit {
  if (leading_extras.is_empty() && trailing_extras.is_empty()) ||
    root_index < 0 ||
    root_index >= nodes.length() {
    return
  }
  let root = nodes[root_index]
  let children : Array[Int] = []
  let mut start_byte = root.start_byte
  let mut start_point = root.start_point
  let mut end_byte = root.end_byte
  let mut end_point = root.end_point
  let mut fragile_left = root.fragile_left
  let mut fragile_right = root.fragile_right
  let mut has_error = root.has_error
  let mut has_external_tokens = root.has_external_tokens
  let mut has_external_scanner_state_change = root.has_external_scanner_state_change
  let mut depends_on_column = root.depends_on_column
  let mut error_cost = root.error_cost
  let mut dynamic_precedence = root.dynamic_precedence
  let mut lookahead_byte_count = root.lookahead_byte_count
  for extra in leading_extras {
    if extra >= 0 && extra < nodes.length() {
      children.push(extra)
      set_extra_child_metadata(nodes, extra, root_index)
      let extra_node = nodes[extra]
      start_byte = extra_node.start_byte
      start_point = extra_node.start_point
      fragile_left = extra_node.fragile_left
      has_error = has_error || extra_node.has_error || extra_node.is_error
      has_external_tokens = has_external_tokens ||
        extra_node.has_external_tokens
      has_external_scanner_state_change = has_external_scanner_state_change ||
        extra_node.has_external_scanner_state_change
      depends_on_column = depends_on_column || extra_node.depends_on_column
      error_cost += extra_node.error_cost
      dynamic_precedence += extra_node.dynamic_precedence
    }
  }
  for child in root.children {
    children.push(child)
  }
  for extra in trailing_extras {
    if extra >= 0 && extra < nodes.length() {
      children.push(extra)
      set_extra_child_metadata(nodes, extra, root_index)
      let extra_node = nodes[extra]
      end_byte = extra_node.end_byte
      end_point = extra_node.end_point
      fragile_right = extra_node.fragile_right
      has_error = has_error || extra_node.has_error || extra_node.is_error
      has_external_tokens = has_external_tokens ||
        extra_node.has_external_tokens
      has_external_scanner_state_change = has_external_scanner_state_change ||
        extra_node.has_external_scanner_state_change
      depends_on_column = depends_on_column || extra_node.depends_on_column
      error_cost += extra_node.error_cost
      dynamic_precedence += extra_node.dynamic_precedence
      let extra_lookahead_byte_count = node_lookahead_byte_count_after_parent_end(
        extra_node, end_byte,
      )
      if extra_lookahead_byte_count > lookahead_byte_count {
        lookahead_byte_count = extra_lookahead_byte_count
      }
    }
  }
  lookahead_byte_count = node_children_lookahead_byte_count(
    nodes, children, end_byte,
  )
  has_external_tokens = has_external_tokens ||
    node_children_have_external_tokens(nodes, children)
  has_external_scanner_state_change = has_external_scanner_state_change ||
    node_children_have_external_scanner_state_change(nodes, children)
  depends_on_column = depends_on_column ||
    node_children_depend_on_column(nodes, children)
  nodes[root_index] = {
    ..root,
    children,
    start_byte,
    start_point,
    end_byte,
    end_point,
    fragile_left,
    fragile_right,
    has_error,
    has_external_tokens,
    has_external_scanner_state_change,
    depends_on_column,
    error_cost,
    dynamic_precedence,
    lookahead_byte_count,
  }
}

///|
fn reduce_stack(
  language : Language,
  tables : @tables.ValidatedLanguageTables,
  nodes : Array[NodeData],
  leading_extras : Array[Array[Int]],
  stack : Array[ParseStackEntry],
  symbol_id~ : Int,
  child_count~ : Int,
  dynamic_precedence~ : Int,
  production_id~ : Int,
  force_fragile? : Bool = false,
  fallback_byte~ : UInt,
  fallback_point~ : @api.Point,
  trailing_extras~ : Array[Int],
) -> Unit raise ParseError {
  let structural_children : Array[Int] = []
  for _ in 0..<child_count {
    match stack.pop() {
      Some(entry) =>
        if entry.node_index >= 0 {
          structural_children.insert(0, entry.node_index)
        }
      None => raise ParseError::ParseStackUnderflow
    }
  }
  guard stack.last() is Some(parent_stack_entry) else {
    raise ParseError::ParseStackUnderflow
  }
  let children : Array[Int] = []
  let extra_children : Array[Int] = []
  let parent_leading_extras : Array[Int] = []
  let mut saw_leading_anchor = false
  for child in structural_children {
    match leading_extras.get(child) {
      Some(extras) =>
        for extra in extras {
          if !saw_leading_anchor {
            parent_leading_extras.push(extra)
          } else {
            children.push(extra)
            extra_children.push(extra)
          }
        }
      None => ()
    }
    children.push(child)
    if node_blocks_parent_leading_extras(nodes, child) {
      saw_leading_anchor = true
    }
  }
  for extra in trailing_extras {
    children.push(extra)
    extra_children.push(extra)
  }
  let (start_byte, end_byte, start_point, end_point) = reduced_range(
    nodes,
    children,
    fallback_byte~,
    fallback_point~,
  )
  let next_state = match
    tables.goto_state_for_symbol(
      state_id_from_int(parent_stack_entry.state_id),
      symbol_id_from_int(symbol_id),
    ) {
    Some(next_state) => next_state
    None =>
      raise ParseError::ParseTableError(
        state_id=state_id_from_int(parent_stack_entry.state_id),
        symbol_id=symbol_id_from_int(symbol_id),
      )
  }
  let has_error = node_children_have_error(nodes, children)
  let has_external_tokens = node_children_have_external_tokens(nodes, children)
  let has_external_scanner_state_change = node_children_have_external_scanner_state_change(
    nodes, children,
  )
  let depends_on_column = node_children_depend_on_column(nodes, children)
  let error_cost = node_children_error_cost(nodes, children)
  let dynamic_precedence = dynamic_precedence +
    node_children_dynamic_precedence(nodes, children)
  let lookahead_byte_count = node_children_lookahead_byte_count(
    nodes, children, end_byte,
  )
  let (child_fragile_left, child_fragile_right) = node_children_fragility(
    nodes, children,
  )
  let fragile_left = force_fragile || child_fragile_left
  let fragile_right = force_fragile || child_fragile_right
  let parse_state = if has_error || force_fragile {
    None
  } else {
    Some(state_id_from_int(parent_stack_entry.state_id))
  }
  let next_parse_state = if has_error || force_fragile {
    None
  } else {
    Some(next_state)
  }
  let parent_index = push_parser_node(
    nodes,
    leading_extras,
    {
      ..node_data_for_symbol(
        language,
        symbol_id,
        start_byte,
        end_byte,
        start_point,
        end_point,
        children~,
        parse_state~,
        next_parse_state~,
        dynamic_precedence~,
        lookahead_byte_count~,
        has_external_tokens~,
        external_scanner_state_changed=has_external_scanner_state_change,
        external_scanner_depends_on_column=depends_on_column,
        fragile_left~,
        fragile_right~,
      ),
      has_error,
      error_cost,
    },
    leading=parent_leading_extras,
  )
  for extra in extra_children {
    set_extra_child_metadata(nodes, extra, parent_index)
  }
  for i in 0..<structural_children.length() {
    set_reduced_child_metadata(
      tables,
      nodes,
      structural_children[i],
      parent_index,
      production_id~,
      child_position=i,
    )
  }
  stack.push({
    state_id: next_state.value().reinterpret_as_int(),
    node_index: parent_index,
  })
}

///|
fn node_blocks_parent_leading_extras(
  nodes : Array[NodeData],
  child : Int,
) -> Bool {
  if child < 0 || child >= nodes.length() {
    return false
  }
  nodes[child].end_byte > nodes[child].start_byte
}

///|
fn node_children_have_error(
  nodes : Array[NodeData],
  children : Array[Int],
) -> Bool {
  for child in children {
    if child >= 0 && child < nodes.length() {
      let node = nodes[child]
      if node.has_error || node.is_error {
        return true
      }
    }
  }
  false
}

///|
fn node_children_have_external_tokens(
  nodes : Array[NodeData],
  children : Array[Int],
) -> Bool {
  for child in children {
    if child >= 0 && child < nodes.length() {
      if nodes[child].has_external_tokens {
        return true
      }
    }
  }
  false
}

///|
fn node_children_have_external_scanner_state_change(
  nodes : Array[NodeData],
  children : Array[Int],
) -> Bool {
  for child in children {
    if child >= 0 && child < nodes.length() {
      if nodes[child].has_external_scanner_state_change {
        return true
      }
    }
  }
  false
}

///|
fn node_children_depend_on_column(
  nodes : Array[NodeData],
  children : Array[Int],
) -> Bool {
  for child in children {
    if child >= 0 && child < nodes.length() {
      if nodes[child].depends_on_column {
        return true
      }
    }
  }
  false
}

///|
fn node_children_error_cost(
  nodes : Array[NodeData],
  children : Array[Int],
) -> Int {
  let mut cost = 0
  for child in children {
    if child >= 0 && child < nodes.length() {
      cost += nodes[child].error_cost
    }
  }
  cost
}

///|
fn node_children_dynamic_precedence(
  nodes : Array[NodeData],
  children : Array[Int],
) -> Int {
  let mut total = 0
  for child in children {
    if child >= 0 && child < nodes.length() {
      total += nodes[child].dynamic_precedence
    }
  }
  total
}

///|
fn node_children_lookahead_byte_count(
  nodes : Array[NodeData],
  children : Array[Int],
  parent_end_byte : UInt,
) -> Int {
  let mut lookahead_byte_count = 0
  for child in children {
    if child >= 0 && child < nodes.length() {
      let candidate = node_lookahead_byte_count_after_parent_end(
        nodes[child],
        parent_end_byte,
      )
      if candidate > lookahead_byte_count {
        lookahead_byte_count = candidate
      }
    }
  }
  lookahead_byte_count
}

///|
fn node_lookahead_byte_count_after_parent_end(
  node : NodeData,
  parent_end_byte : UInt,
) -> Int {
  let lookahead_end = node.end_byte +
    node.lookahead_byte_count.reinterpret_as_uint()
  if lookahead_end > parent_end_byte {
    (lookahead_end - parent_end_byte).reinterpret_as_int()
  } else {
    0
  }
}

///|
fn node_children_fragility(
  nodes : Array[NodeData],
  children : Array[Int],
) -> (Bool, Bool) {
  if node_children_have_error(nodes, children) {
    return (true, true)
  }
  let left = if children.length() > 0 {
    let child = children[0]
    if child >= 0 && child < nodes.length() {
      nodes[child].fragile_left
    } else {
      false
    }
  } else {
    false
  }
  let right = if children.length() > 0 {
    let child = children[children.length() - 1]
    if child >= 0 && child < nodes.length() {
      nodes[child].fragile_right
    } else {
      false
    }
  } else {
    false
  }
  (left, right)
}

///|
fn push_parser_node(
  nodes : Array[NodeData],
  leading_extras : Array[Array[Int]],
  node : NodeData,
  leading? : Array[Int] = [],
) -> Int {
  let index = nodes.length()
  nodes.push(node)
  leading_extras.push(leading.copy())
  index
}

///|
fn reduced_range(
  nodes : Array[NodeData],
  children : Array[Int],
  fallback_byte~ : UInt,
  fallback_point~ : @api.Point,
) -> (UInt, UInt, @api.Point, @api.Point) {
  if children.length() == 0 {
    (fallback_byte, fallback_byte, fallback_point, fallback_point)
  } else {
    let first = nodes[children[0]]
    let last = nodes[children[children.length() - 1]]
    (first.start_byte, last.end_byte, first.start_point, last.end_point)
  }
}

///|
fn set_reduced_child_metadata(
  tables : @tables.ValidatedLanguageTables,
  nodes : Array[NodeData],
  child_index : Int,
  parent_index : Int,
  production_id~ : Int,
  child_position~ : Int,
) -> Unit {
  if child_index < 0 || child_index >= nodes.length() {
    return
  }
  let field_id = production_field_id_for_child(
    tables, production_id, child_position,
  )
  let child = apply_production_alias_to_child(
    tables,
    nodes[child_index],
    production_alias_for_child(tables, production_id, child_position),
  )
  nodes[child_index] = { ..child, parent: parent_index, field_id }
}

///|
fn set_extra_child_metadata(
  nodes : Array[NodeData],
  child_index : Int,
  parent_index : Int,
) -> Unit {
  if child_index < 0 || child_index >= nodes.length() {
    return
  }
  nodes[child_index] = {
    ..nodes[child_index],
    parent: parent_index,
    field_id: @api.FieldId::new(0),
    extra: true,
  }
}

///|
fn apply_production_alias_to_child(
  tables : @tables.ValidatedLanguageTables,
  child : NodeData,
  alias_entry : @tables.GeneratedAlias?,
) -> NodeData {
  match alias_entry {
    Some(alias_info) => {
      let public_symbol = match tables.public_symbol_for_alias(alias_info) {
        Some(symbol) => symbol
        None => child.symbol
      }
      {
        ..child,
        kind: alias_info.value,
        symbol: public_symbol,
        alias_visible: true,
        named: alias_info.named,
      }
    }
    None => child
  }
}

///|
fn production_alias_for_child(
  tables : @tables.ValidatedLanguageTables,
  production_id : Int,
  child_position : Int,
) -> @tables.GeneratedAlias? {
  match tables.production_info(production_id) {
    Some(info) =>
      match info.alias_sequence.get(child_position) {
        Some(alias_entry) => alias_entry
        None => None
      }
    None => None
  }
}

///|
fn production_field_id_for_child(
  tables : @tables.ValidatedLanguageTables,
  production_id : Int,
  child_position : Int,
) -> @api.FieldId {
  match tables.production_info(production_id) {
    Some(info) => {
      for entry in info.field_map {
        for location in entry.locations {
          if location.index == child_position {
            return @api.FieldId::new(entry.field_id.reinterpret_as_uint())
          }
        }
      }
      @api.FieldId::new(0)
    }
    None => @api.FieldId::new(0)
  }
}

///|
fn node_data_for_symbol(
  language : Language,
  symbol_id : Int,
  start_byte : UInt,
  end_byte : UInt,
  start_point : @api.Point,
  end_point : @api.Point,
  children? : Array[Int] = [],
  external_scanner_state? : Bytes? = None,
  has_external_tokens? : Bool = external_scanner_state is Some(_),
  external_scanner_state_changed? : Bool = false,
  external_scanner_depends_on_column? : Bool = false,
  lookahead_byte_count? : Int = 0,
  parse_state? : @api.StateId? = None,
  next_parse_state? : @api.StateId? = None,
  dynamic_precedence? : Int = 0,
  fragile_left? : Bool = false,
  fragile_right? : Bool = false,
) -> NodeData {
  let grammar_symbol_id = symbol_id_from_int(symbol_id)
  let public_symbol_id = match
    language.tables.public_symbol_for_grammar_symbol(grammar_symbol_id) {
    Some(symbol) => symbol
    None => grammar_symbol_id
  }
  let kind = match language.symbol_name(grammar_symbol_id) {
    Some(value) => value
    None => ""
  }
  let symbol_type = language.symbol_type(grammar_symbol_id)
  let default_alias = language.tables.default_alias_for_symbol(
    grammar_symbol_id,
  )
  NodeData::new(
    kind=default_alias_kind(kind, default_alias),
    grammar_kind=kind,
    symbol=public_symbol_id,
    grammar_symbol=grammar_symbol_id,
    start_byte~,
    end_byte~,
    start_point~,
    end_point~,
    children~,
    visible=symbol_is_visible(kind, symbol_type),
    alias_visible=default_alias is Some(_),
    named=default_alias_named(symbol_type, default_alias),
    external_scanner_state~,
    has_external_tokens~,
    has_external_scanner_state_change=external_scanner_state_changed,
    depends_on_column=external_scanner_depends_on_column,
    lookahead_byte_count~,
    parse_state~,
    next_parse_state~,
    dynamic_precedence~,
    fragile_left~,
    fragile_right~,
  )
}

///|
fn symbol_is_visible(kind : String, symbol_type : @api.SymbolType?) -> Bool {
  symbol_type_is_visible(symbol_type) && !symbol_name_has_hidden_prefix(kind)
}

///|
fn symbol_name_has_hidden_prefix(kind : String) -> Bool {
  match kind.get_char(0) {
    Some('_') => true
    _ => false
  }
}

///|
fn default_alias_kind(
  grammar_kind : String,
  default_alias : @tables.GeneratedAlias?,
) -> String {
  match default_alias {
    Some(alias_info) => alias_info.value
    None => grammar_kind
  }
}

///|
fn default_alias_named(
  symbol_type : @api.SymbolType?,
  default_alias : @tables.GeneratedAlias?,
) -> Bool {
  match default_alias {
    Some(alias_info) => alias_info.named
    None => symbol_type_is_named(symbol_type)
  }
}

///|
fn symbol_type_is_visible(symbol_type : @api.SymbolType?) -> Bool {
  match symbol_type {
    Some(@api.SymbolType::Auxiliary) => false
    _ => true
  }
}

///|
fn symbol_type_is_named(symbol_type : @api.SymbolType?) -> Bool {
  match symbol_type {
    Some(@api.SymbolType::Anonymous) | Some(@api.SymbolType::Auxiliary) => false
    _ => true
  }
}

///|
fn lex_main_token(
  tables : @tables.ValidatedLanguageTables,
  parse_state_id : Int,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  start_byte : UInt,
  start_point : @api.Point,
  included_ranges~ : Array[@api.Range],
  external_scanner_state~ : Bytes,
  logger~ : Logger?,
) -> LexedToken raise ParseError {
  let state_id = state_id_from_int(parse_state_id)
  guard tables.lex_mode(state_id) is Some(mode) else {
    raise ParseError::LexError(byte_offset=start_byte, state_id~)
  }
  let (lex_start_byte, lex_start_point) = snap_to_included_range(
    start_byte, start_point, included_ranges,
  )
  if mode.external_lex_state != 0 {
    match
      scan_external_token(
        tables,
        mode,
        parse_state_id,
        input,
        encoding~,
        decode_callback~,
        chunk_end_offsets~,
        lex_start_byte,
        lex_start_point,
        included_ranges~,
        external_scanner_state~,
        logger~,
      ) {
      Some(token) => return token
      None => ()
    }
  }
  if mode.lex_state == @tables.lex_state_none() {
    raise ParseError::LexError(byte_offset=start_byte, state_id~)
  }
  guard tables.main_lex_table(mode.lex_state) is Some(table) else {
    raise ParseError::LexError(byte_offset=start_byte, state_id~)
  }
  parser_log(logger, Lex, "lex start")
  let token = scan_lex_table(
    table,
    input,
    encoding~,
    decode_callback~,
    chunk_end_offsets~,
    lex_start_byte,
    lex_start_point,
    included_ranges~,
    state_id~,
  )
  let result = keyword_fallback_token(
    tables,
    mode,
    token,
    input,
    encoding~,
    decode_callback~,
    chunk_end_offsets~,
    included_ranges~,
    state_id~,
  )
  parser_log(logger, Lex, "lex token")
  result
}

///|
fn scan_external_token(
  tables : @tables.ValidatedLanguageTables,
  mode : @tables.GeneratedLexMode,
  parse_state_id : Int,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  start_byte : UInt,
  start_point : @api.Point,
  included_ranges~ : Array[@api.Range],
  external_scanner_state~ : Bytes,
  logger~ : Logger?,
) -> LexedToken? raise ParseError {
  let scanner = tables.external_scanner()
  let valid_symbols = external_scanner_valid_symbols(
    scanner,
    mode.external_lex_state,
    tables.external_token_count(),
  )
  let previous_included_range_end = external_context_previous_included_range_end(
    start_byte, included_ranges,
  )
  let previous_included_range_end_byte = match previous_included_range_end {
    Some((byte, _point)) => Some(byte)
    None => None
  }
  let previous_included_range_end_point = match previous_included_range_end {
    Some((_byte, point)) => Some(point)
    None => None
  }
  parser_log(logger, Lex, "external scanner start")
  let deserialize_result : Result[Unit, @api.ScannerError] = capture_parser_result(() => {
      scanner.deserialize(external_scanner_state)
    },
  )
  match deserialize_result {
    Ok(_) => ()
    Err(error) => raise ParseError::ScannerError(error)
  }
  let context = @tables.ExternalScannerContext::new(
    input~,
    byte_offset=start_byte,
    point=start_point,
    valid_symbols~,
    is_at_included_range_start=external_context_is_at_included_range_start(
      start_byte, input, included_ranges,
    ),
    previous_included_range_end_byte~,
    previous_included_range_end_point~,
    eof=external_context_eof(input, start_byte, included_ranges),
    column=external_context_column(
      input,
      encoding~,
      decode_callback~,
      chunk_end_offsets~,
      start_byte~,
      start_point~,
    ),
    advance_steps=external_context_advance_steps(
      input,
      encoding~,
      decode_callback~,
      chunk_end_offsets~,
      start_byte~,
      included_ranges~,
    ),
  )
  let scan_result : Result[@tables.ExternalScanResult, @api.ScannerError] = capture_parser_result(() => {
      scanner.scan(context)
    },
  )
  flush_external_context_logs(context, logger)
  let scan_start_byte = start_byte
  match scan_result {
    Err(error) => raise ParseError::ScannerError(error)
    Ok(@tables.ExternalScanResult::NoToken) => None
    Ok(@tables.ExternalScanResult::Token(external_token_id~, bytes_read~)) => {
      let serialized = serialize_external_scanner_state(scanner)
      let state_changed = external_scanner_serialized_state_changed(
        external_scanner_state, serialized,
      )
      validate_external_scan_token(
        scanner,
        external_token_id~,
        bytes_read~,
        valid_symbols~,
        input~,
        start_byte~,
        included_ranges~,
      )
      guard scanner.symbol_for_external_token(external_token_id)
        is Some(symbol_id) else {
        raise ParseError::ScannerError(
          @api.ScannerError::InvalidResult(
            "external token has no symbol mapping",
          ),
        )
      }
      if external_scan_should_ignore_no_progress_token(
          tables, parse_state_id, symbol_id, bytes_read, state_changed,
        ) {
        return None
      }
      let end_byte = (start_byte.reinterpret_as_int() + bytes_read).reinterpret_as_uint()
      let end_point = external_scan_end_point(
        input,
        encoding~,
        decode_callback~,
        chunk_end_offsets~,
        start_byte~,
        start_point~,
        bytes_read~,
      )
      parser_log(logger, Lex, "external scanner token")
      Some({
        symbol_id,
        start_byte,
        end_byte,
        start_point,
        end_point,
        lookahead_byte_count: external_token_lookahead_byte_count(
          end_byte,
          input.length().reinterpret_as_uint(),
        ),
        external_scanner_state: Some(serialized),
        external_scanner_state_changed: state_changed,
        external_scanner_depends_on_column: context.did_get_column(),
      })
    }
    Ok(
      @tables.ExternalScanResult::TokenRange(
        external_token_id~,
        start_byte~,
        end_byte~,
        start_point~,
        end_point~,
        state_changed~
      )
    ) => {
      if end_byte < start_byte ||
        (
          start_byte < scan_start_byte &&
          !external_scan_range_matches_previous_included_range_end(
            start_byte, end_byte, start_point, end_point, scan_start_byte, included_ranges,
          )
        ) {
        raise ParseError::ScannerError(
          @api.ScannerError::InvalidResult(
            "external scanner token range is invalid",
          ),
        )
      }
      let bytes_read = (end_byte - start_byte).reinterpret_as_int()
      let serialized = serialize_external_scanner_state(scanner)
      let serialized_state_changed = external_scanner_serialized_state_changed(
        external_scanner_state, serialized,
      )
      let effective_state_changed = state_changed || serialized_state_changed
      validate_external_scan_token(
        scanner,
        external_token_id~,
        bytes_read~,
        valid_symbols~,
        input~,
        start_byte~,
        included_ranges~,
      )
      guard scanner.symbol_for_external_token(external_token_id)
        is Some(symbol_id) else {
        raise ParseError::ScannerError(
          @api.ScannerError::InvalidResult(
            "external token has no symbol mapping",
          ),
        )
      }
      if external_scan_should_ignore_no_progress_token(
          tables, parse_state_id, symbol_id, bytes_read, effective_state_changed,
        ) {
        return None
      }
      parser_log(logger, Lex, "external scanner token")
      Some({
        symbol_id,
        start_byte,
        end_byte,
        start_point,
        end_point,
        lookahead_byte_count: external_token_lookahead_byte_count(
          end_byte,
          input.length().reinterpret_as_uint(),
        ),
        external_scanner_state: Some(serialized),
        external_scanner_state_changed: effective_state_changed,
        external_scanner_depends_on_column: context.did_get_column(),
      })
    }
  }
}

///|
fn external_scanner_serialized_state_changed(
  previous : Bytes,
  current : Bytes,
) -> Bool {
  if previous.length() != current.length() {
    return true
  }
  for i in 0..<previous.length() {
    if previous[i] != current[i] {
      return true
    }
  }
  false
}

///|
fn flush_external_context_logs(
  context : @tables.ExternalScannerContext,
  logger : Logger?,
) -> Unit {
  for message in context.logged_messages() {
    parser_log(logger, Lex, message)
  }
}

///|
fn serialize_external_scanner_state(
  scanner : @tables.ExternalScannerDescriptor,
) -> Bytes raise ParseError {
  let result : Result[Bytes, @api.ScannerError] = capture_parser_result(() => {
    scanner.serialize()
  })
  match result {
    Ok(bytes) => {
      if bytes.length() > @tables.external_scanner_serialization_buffer_size() {
        raise ParseError::ScannerError(
          @api.ScannerError::InvalidResult(
            "external scanner serialized state too large",
          ),
        )
      }
      bytes
    }
    Err(error) => raise ParseError::ScannerError(error)
  }
}

///|
fn external_context_is_at_included_range_start(
  byte : UInt,
  input : Bytes,
  included_ranges : Array[@api.Range],
) -> Bool {
  if external_context_eof(input, byte, included_ranges) {
    return false
  }
  if included_ranges.is_empty() {
    return byte == 0
  }
  for range in included_ranges {
    if !range.is_empty() && byte == range.start_byte {
      return true
    }
  }
  false
}

///|
fn external_context_previous_included_range_end(
  byte : UInt,
  included_ranges : Array[@api.Range],
) -> (UInt, @api.Point)? {
  if included_ranges.is_empty() {
    return None
  }
  let mut previous_end : (UInt, @api.Point)? = None
  for range in included_ranges {
    if range.is_empty() {
      continue
    }
    if byte == range.start_byte {
      return previous_end
    }
    if byte < range.start_byte {
      return None
    }
    previous_end = Some((range.end_byte, range.end_point))
  }
  None
}

///|
fn external_context_eof(
  input : Bytes,
  byte : UInt,
  included_ranges : Array[@api.Range],
) -> Bool {
  let input_end = input.length().reinterpret_as_uint()
  let active_end = included_range_end_for_byte(included_ranges, byte, input_end)
  let effective_end = if active_end > input_end {
    input_end
  } else {
    active_end
  }
  byte >= effective_end
}

///|
fn external_context_column(
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  start_byte~ : UInt,
  start_point~ : @api.Point,
) -> UInt raise ParseError {
  if start_point.column > start_byte {
    return start_point.column
  }
  let mut byte_index = (start_byte - start_point.column).reinterpret_as_int()
  let end_byte = start_byte.reinterpret_as_int()
  let mut column : UInt = 0
  while byte_index < end_byte {
    guard decode_input_scalar(
        input,
        byte_index,
        encoding~,
        decode_callback~,
        chunk_end_offsets~,
      )
      is Some(scalar) else {
      raise ParseError::ScannerError(
        @api.ScannerError::InvalidResult(
          "external scanner column recompute failed",
        ),
      )
    }
    if byte_index + scalar.byte_width > end_byte {
      raise ParseError::ScannerError(
        @api.ScannerError::InvalidResult(
          "external scanner column recompute crossed token start",
        ),
      )
    }
    if scalar.codepoint == 10 {
      column = 0
    } else if byte_index == 0 && scalar.codepoint == bom_codepoint {
      ()
    } else {
      column += 1
    }
    byte_index += scalar.byte_width
  }
  column
}

///|
fn external_context_advance_steps(
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  start_byte~ : UInt,
  included_ranges~ : Array[@api.Range],
) -> Array[@tables.ExternalScannerAdvanceStep] raise ParseError {
  let input_end = input.length().reinterpret_as_uint()
  let active_end_uint = included_range_end_for_byte(
    included_ranges, start_byte, input_end,
  )
  let active_end = if active_end_uint > input_end {
    input.length()
  } else {
    active_end_uint.reinterpret_as_int()
  }
  let steps : Array[@tables.ExternalScannerAdvanceStep] = []
  let mut byte_index = start_byte.reinterpret_as_int()
  while byte_index < active_end {
    guard decode_input_scalar(
        input,
        byte_index,
        encoding~,
        decode_callback~,
        chunk_end_offsets~,
      )
      is Some(scalar) else {
      return steps
    }
    if byte_index + scalar.byte_width > active_end {
      return steps
    }
    steps.push(
      @tables.ExternalScannerAdvanceStep::new(
        byte_width=scalar.byte_width,
        codepoint=scalar.codepoint,
      ),
    )
    byte_index += scalar.byte_width
  }
  steps
}

///|
fn external_scanner_valid_symbols(
  scanner : @tables.ExternalScannerDescriptor,
  external_lex_state : Int,
  external_token_count : Int,
) -> Array[Bool] {
  let valid_symbols : Array[Bool] = []
  for token_id in 0..<external_token_count {
    match scanner.state_enabled(external_lex_state, token_id) {
      Some(enabled) => valid_symbols.push(enabled)
      None => valid_symbols.push(false)
    }
  }
  valid_symbols
}

///|
fn validate_external_scan_token(
  scanner : @tables.ExternalScannerDescriptor,
  external_token_id~ : Int,
  bytes_read~ : Int,
  valid_symbols~ : Array[Bool],
  input~ : Bytes,
  start_byte~ : UInt,
  included_ranges~ : Array[@api.Range],
) -> Unit raise ParseError {
  if external_token_id < 0 ||
    external_token_id >= scanner.external_token_count() {
    raise ParseError::ScannerError(
      @api.ScannerError::InvalidResult("external token id out of range"),
    )
  }
  if !valid_symbols[external_token_id] {
    raise ParseError::ScannerError(
      @api.ScannerError::InvalidResult("external token id is not valid"),
    )
  }
  if bytes_read < 0 {
    raise ParseError::ScannerError(
      @api.ScannerError::InvalidResult(
        "external scanner token range is invalid",
      ),
    )
  }
  let start_index = start_byte.reinterpret_as_int()
  if start_index + bytes_read > input.length() {
    raise ParseError::ScannerError(
      @api.ScannerError::InvalidResult("external scanner consumed past input"),
    )
  }
  let input_end = input.length().reinterpret_as_uint()
  let active_end_uint = included_range_end_for_byte(
    included_ranges, start_byte, input_end,
  )
  let active_end = if active_end_uint > input_end {
    input.length()
  } else {
    active_end_uint.reinterpret_as_int()
  }
  if start_index + bytes_read > active_end {
    raise ParseError::ScannerError(
      @api.ScannerError::InvalidResult(
        "external scanner consumed past included range",
      ),
    )
  }
}

///|
fn external_scan_range_matches_previous_included_range_end(
  start_byte : UInt,
  end_byte : UInt,
  start_point : @api.Point,
  end_point : @api.Point,
  scan_start_byte : UInt,
  included_ranges : Array[@api.Range],
) -> Bool {
  if start_byte != end_byte || start_point != end_point {
    return false
  }
  match
    external_context_previous_included_range_end(
      scan_start_byte, included_ranges,
    ) {
    Some((previous_end_byte, previous_end_point)) =>
      start_byte == previous_end_byte && start_point == previous_end_point
    None => false
  }
}

///|
fn external_scan_should_ignore_no_progress_token(
  tables : @tables.ValidatedLanguageTables,
  parse_state_id : Int,
  symbol_id : Int,
  bytes_read : Int,
  state_changed : Bool,
) -> Bool {
  if bytes_read != 0 || state_changed {
    return false
  }
  if parse_state_id == 0 {
    return true
  }
  match external_token_next_parse_state(tables, parse_state_id, symbol_id) {
    Some(next_state_id) => next_state_id == parse_state_id
    None => false
  }
}

///|
fn external_token_next_parse_state(
  tables : @tables.ValidatedLanguageTables,
  parse_state_id : Int,
  symbol_id : Int,
) -> Int? {
  match
    tables.parse_action_list_for_symbol(
      state_id_from_int(parse_state_id),
      symbol_id_from_int(symbol_id),
    ) {
    Some(action_list) => {
      let mut found_shift_extra = false
      let mut next_state : Int? = None
      for action in action_list.actions {
        match action {
          @tables.GeneratedParseAction::Shift(state_id~, ..) =>
            next_state = Some(state_id)
          @tables.GeneratedParseAction::ShiftExtra => found_shift_extra = true
          _ => ()
        }
      }
      match next_state {
        Some(value) => Some(value)
        None => if found_shift_extra { Some(parse_state_id) } else { None }
      }
    }
    None => None
  }
}

///|
fn external_scan_end_point(
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  start_byte~ : UInt,
  start_point~ : @api.Point,
  bytes_read~ : Int,
) -> @api.Point raise ParseError {
  let mut byte_index = start_byte.reinterpret_as_int()
  let end_byte = byte_index + bytes_read
  let mut point = start_point
  while byte_index < end_byte {
    guard decode_input_scalar(
        input,
        byte_index,
        encoding~,
        decode_callback~,
        chunk_end_offsets~,
      )
      is Some(scalar) else {
      raise ParseError::ScannerError(
        @api.ScannerError::InvalidResult(
          "external scanner consumed undecodable input",
        ),
      )
    }
    if byte_index + scalar.byte_width > end_byte {
      raise ParseError::ScannerError(
        @api.ScannerError::InvalidResult(
          "external scanner consumed partial code point",
        ),
      )
    }
    byte_index += scalar.byte_width
    point = advance_point(point, scalar.byte_width, scalar.codepoint)
  }
  point
}

///|
fn snap_to_included_range(
  start_byte : UInt,
  start_point : @api.Point,
  ranges : Array[@api.Range],
) -> (UInt, @api.Point) {
  if ranges.is_empty() {
    return (start_byte, start_point)
  }
  let mut saw_range = false
  let mut last_end_byte = start_byte
  let mut last_end_point = start_point
  for range in ranges {
    if range.is_empty() {
      continue
    }
    saw_range = true
    last_end_byte = range.end_byte
    last_end_point = range.end_point
    if start_byte < range.start_byte {
      return (range.start_byte, range.start_point)
    }
    if range.start_byte <= start_byte && start_byte < range.end_byte {
      if start_byte == range.start_byte {
        return (range.start_byte, range.start_point)
      } else {
        return (start_byte, start_point)
      }
    }
  }
  if saw_range {
    (last_end_byte, last_end_point)
  } else {
    (start_byte, start_point)
  }
}

///|
fn included_range_end_for_byte(
  ranges : Array[@api.Range],
  byte : UInt,
  default_end : UInt,
) -> UInt {
  if ranges.is_empty() {
    return default_end
  }
  let mut saw_range = false
  let mut last_end = byte
  for range in ranges {
    if range.is_empty() {
      continue
    }
    saw_range = true
    last_end = range.end_byte
    if byte < range.start_byte {
      return range.start_byte
    }
    if range.start_byte <= byte && byte <= range.end_byte {
      return range.end_byte
    }
  }
  if saw_range {
    last_end
  } else {
    byte
  }
}

///|
fn keyword_fallback_token(
  tables : @tables.ValidatedLanguageTables,
  mode : @tables.GeneratedLexMode,
  token : LexedToken,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  included_ranges~ : Array[@api.Range],
  state_id~ : @api.StateId,
) -> LexedToken {
  guard tables.keyword_capture_token() is Some(capture_token) else {
    return token
  }
  if token.symbol_id != capture_token.value().reinterpret_as_int() {
    return token
  }
  guard tables.keyword_lex_table() is Some(keyword_table) else { return token }
  let result : Result[LexedToken, ParseError] = capture_parser_result(() => {
    scan_lex_table(
      keyword_table,
      input,
      encoding~,
      decode_callback~,
      chunk_end_offsets~,
      token.start_byte,
      token.start_point,
      included_ranges~,
      state_id~,
    )
  })
  guard result is Ok(keyword) else { return token }
  if keyword.start_byte != token.start_byte ||
    keyword.end_byte != token.end_byte {
    return token
  }
  let keyword_symbol = symbol_id_from_int(keyword.symbol_id)
  let has_action = tables.parse_action_list_for_symbol(state_id, keyword_symbol)
    is Some(_)
  let reserved = reserved_word_set_contains_symbol(
    tables,
    mode.reserved_word_set_id,
    keyword.symbol_id,
  )
  if has_action || reserved {
    keyword
  } else {
    token
  }
}

///|
fn reserved_word_set_contains_symbol(
  tables : @tables.ValidatedLanguageTables,
  set_id : Int,
  symbol_id : Int,
) -> Bool {
  match tables.reserved_word_set(set_id) {
    Some(set) => {
      for candidate in set.symbol_ids {
        if candidate == symbol_id {
          return true
        }
      }
      false
    }
    None => false
  }
}

///|
fn external_token_lookahead_byte_count(
  _end_byte : UInt,
  _input_end : UInt,
) -> Int {
  1
}

///|
fn scan_lex_table(
  table : @tables.GeneratedLexTable,
  input : Bytes,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets~ : Array[Int],
  start_byte : UInt,
  start_point : @api.Point,
  included_ranges~ : Array[@api.Range],
  state_id~ : @api.StateId,
) -> LexedToken raise ParseError {
  let mut dfa_state = table.start_state
  let mut byte_index = start_byte.reinterpret_as_int()
  let mut point = start_point
  let mut token_start_byte = start_byte
  let mut token_start_point = start_point
  let mut best : LexedToken? = None
  let mut best_ended_on_decode_error = false
  let mut last_consumed_codepoint : Int? = None
  let mut eof_steps = 0
  let input_end = input.length().reinterpret_as_uint()
  if byte_index == 0 && point.row == 0 && point.column == 0 {
    let active_end_uint = included_range_end_for_byte(
      included_ranges, 0, input_end,
    )
    let active_end = if active_end_uint > input_end {
      input.length()
    } else {
      active_end_uint.reinterpret_as_int()
    }
    match
      decode_input_scalar(
        input,
        byte_index,
        encoding~,
        decode_callback~,
        chunk_end_offsets~,
      ) {
      Some(scalar) =>
        if scalar.codepoint == bom_codepoint &&
          byte_index + scalar.byte_width <= active_end {
          byte_index += scalar.byte_width
          point = advance_point(point, scalar.byte_width, scalar.codepoint)
          token_start_byte = byte_index.reinterpret_as_uint()
          token_start_point = point
        }
      None => ()
    }
  }
  while dfa_state >= 0 && dfa_state < table.states.length() {
    let state = table.states[dfa_state]
    match state.accept_symbol_id {
      Some(symbol_id) => {
        best = Some({
          symbol_id,
          start_byte: token_start_byte,
          end_byte: byte_index.reinterpret_as_uint(),
          start_point: token_start_point,
          end_point: point,
          lookahead_byte_count: 0,
          external_scanner_state: None,
          external_scanner_state_changed: false,
          external_scanner_depends_on_column: false,
        })
        best_ended_on_decode_error = token_start_byte <
          byte_index.reinterpret_as_uint() &&
          last_consumed_codepoint == Some(decode_error_codepoint)
      }
      None => ()
    }
    let active_end_uint = included_range_end_for_byte(
      included_ranges,
      byte_index.reinterpret_as_uint(),
      input_end,
    )
    let active_end = if active_end_uint > input_end {
      input.length()
    } else {
      active_end_uint.reinterpret_as_int()
    }
    if byte_index >= active_end {
      match state.eof_action {
        Some(target) =>
          if eof_steps == 0 {
            eof_steps += 1
            dfa_state = target
            continue
          } else {
            break
          }
        None => break
      }
    }
    guard decode_input_scalar(
        input,
        byte_index,
        encoding~,
        decode_callback~,
        chunk_end_offsets~,
      )
      is Some(scalar) else {
      raise ParseError::LexError(
        byte_offset=byte_index.reinterpret_as_uint(),
        state_id~,
      )
    }
    if byte_index + scalar.byte_width > active_end {
      break
    }
    match lex_transition_for_codepoint(state, scalar.codepoint) {
      Some(transition) => {
        byte_index += scalar.byte_width
        point = advance_point(point, scalar.byte_width, scalar.codepoint)
        if transition.is_separator {
          token_start_byte = byte_index.reinterpret_as_uint()
          token_start_point = point
        }
        last_consumed_codepoint = Some(scalar.codepoint)
        dfa_state = transition.target_state
      }
      None => break
    }
  }
  match best {
    Some(token) =>
      {
        ..token,
        lookahead_byte_count: token_lookahead_byte_count(
          token,
          byte_index.reinterpret_as_uint(),
          ended_on_decode_error=best_ended_on_decode_error,
        ),
      }
    None =>
      if external_context_eof(input, token_start_byte, included_ranges) {
        eof_lexed_token(token_start_byte, token_start_point)
      } else {
        raise ParseError::LexError(byte_offset=start_byte, state_id~)
      }
  }
}

///|
fn token_lookahead_byte_count(
  token : LexedToken,
  scan_byte : UInt,
  ended_on_decode_error~ : Bool,
) -> Int {
  let lookahead_end = scan_byte + 1
  let base_count = if lookahead_end > token.end_byte {
    (lookahead_end - token.end_byte).reinterpret_as_int()
  } else {
    0
  }
  if ended_on_decode_error && base_count < 4 {
    4
  } else {
    base_count
  }
}

///|
fn eof_lexed_token(byte : UInt, point : @api.Point) -> LexedToken {
  {
    symbol_id: 0,
    start_byte: byte,
    end_byte: byte,
    start_point: point,
    end_point: point,
    lookahead_byte_count: 1,
    external_scanner_state: None,
    external_scanner_state_changed: false,
    external_scanner_depends_on_column: false,
  }
}

///|
fn lex_transition_for_codepoint(
  state : @tables.GeneratedLexState,
  codepoint : Int,
) -> @tables.GeneratedLexTransition? {
  for transition in state.transitions {
    for range in transition.ranges {
      if range.start <= codepoint && codepoint <= range.end {
        return Some(transition)
      }
    }
  }
  None
}

///|
fn decode_input_scalar(
  input : Bytes,
  offset : Int,
  encoding~ : @api.InputEncoding,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end_offsets? : Array[Int] = [],
) -> DecodedScalar? raise ParseError {
  let chunk_end = chunk_end_for_offset(input, offset, chunk_end_offsets)
  match encoding {
    Utf8 => decode_utf8_scalar(input, offset, chunk_end~)
    Utf16LE =>
      decode_utf16_scalar(input, offset, little_endian=true, chunk_end~)
    Utf16BE =>
      decode_utf16_scalar(input, offset, little_endian=false, chunk_end~)
    Custom => decode_custom_scalar(input, offset, decode_callback~, chunk_end~)
  }
}

///|
fn chunk_end_for_offset(
  input : Bytes,
  offset : Int,
  chunk_end_offsets : Array[Int],
) -> Int {
  if chunk_end_offsets.is_empty() {
    return input.length()
  }
  for chunk_end in chunk_end_offsets {
    if offset < chunk_end {
      return chunk_end
    }
  }
  input.length()
}

///|
fn decode_custom_scalar(
  input : Bytes,
  offset : Int,
  decode_callback~ : ((Bytes, Int) -> InputDecodeResult)?,
  chunk_end~ : Int,
) -> DecodedScalar? raise ParseError {
  if offset < 0 || offset >= input.length() {
    return None
  }
  guard decode_callback is Some(decode) else {
    raise ParseError::InvalidInputDecode(
      byte_offset=offset.reinterpret_as_uint(),
      reason="custom input requires decode callback",
    )
  }
  match decode(input, offset) {
    InputDecodeResult::DecodeError => Some(decode_error_scalar())
    InputDecodeResult::CodePoint(codepoint, bytes~) => {
      if codepoint == decode_error_codepoint {
        return Some(decode_error_scalar())
      }
      if bytes <= 0 {
        raise ParseError::InvalidInputDecode(
          byte_offset=offset.reinterpret_as_uint(),
          reason="custom decode must consume bytes",
        )
      }
      if offset + bytes > input.length() {
        raise ParseError::InvalidInputDecode(
          byte_offset=offset.reinterpret_as_uint(),
          reason="custom decode consumed past input",
        )
      }
      if offset + bytes > chunk_end {
        raise ParseError::InvalidInputDecode(
          byte_offset=offset.reinterpret_as_uint(),
          reason="custom decode consumed past chunk",
        )
      }
      if codepoint < 0 || codepoint > 0x10FFFF {
        raise ParseError::InvalidInputDecode(
          byte_offset=offset.reinterpret_as_uint(),
          reason="custom decode code point out of range",
        )
      }
      Some({ codepoint, byte_width: bytes })
    }
  }
}

///|
fn decode_utf8_scalar(
  input : Bytes,
  offset : Int,
  chunk_end~ : Int,
) -> DecodedScalar? {
  if offset < 0 || offset >= input.length() {
    return None
  }
  let end = if chunk_end < input.length() { chunk_end } else { input.length() }
  let first = input[offset].to_int()
  if first < 0x80 {
    return Some({ codepoint: first, byte_width: 1 })
  }
  if first >= 0xC2 && first <= 0xDF {
    match utf8_continuation_value(input, offset + 1, end~) {
      Some(second) =>
        return Some({ codepoint: (first - 0xC0) * 0x40 + second, byte_width: 2 })
      None => return Some(utf8_decode_error_scalar())
    }
  }
  if first >= 0xE0 && first <= 0xEF {
    match
      (
        utf8_continuation_value(input, offset + 1, end~),
        utf8_continuation_value(input, offset + 2, end~),
      ) {
      (Some(second), Some(third)) => {
        let codepoint = (first - 0xE0) * 0x1000 + second * 0x40 + third
        if codepoint >= 0x800 && (codepoint < 0xD800 || codepoint > 0xDFFF) {
          return Some({ codepoint, byte_width: 3 })
        }
        ()
      }
      _ => ()
    }
    return Some(utf8_decode_error_scalar())
  } else if first >= 0xF0 && first <= 0xF4 {
    match
      (
        utf8_continuation_value(input, offset + 1, end~),
        utf8_continuation_value(input, offset + 2, end~),
        utf8_continuation_value(input, offset + 3, end~),
      ) {
      (Some(second), Some(third), Some(fourth)) => {
        let codepoint = (first - 0xF0) * 0x40000 +
          second * 0x1000 +
          third * 0x40 +
          fourth
        if codepoint >= 0x10000 && codepoint <= 0x10FFFF {
          return Some({ codepoint, byte_width: 4 })
        }
        ()
      }
      _ => ()
    }
    return Some(utf8_decode_error_scalar())
  } else {
    Some(utf8_decode_error_scalar())
  }
}

///|
fn decode_utf16_scalar(
  input : Bytes,
  offset : Int,
  little_endian~ : Bool,
  chunk_end~ : Int,
) -> DecodedScalar? {
  if offset < 0 || offset >= input.length() {
    return None
  }
  let end = if chunk_end < input.length() { chunk_end } else { input.length() }
  if offset + 1 >= end {
    return Some(decode_error_scalar())
  }
  let first = read_utf16_code_unit(input, offset, little_endian~)
  if is_leading_surrogate(first) {
    if offset + 3 < end {
      let second = read_utf16_code_unit(input, offset + 2, little_endian~)
      if is_trailing_surrogate(second) {
        let codepoint = 0x10000 + (first - 0xD800) * 0x400 + (second - 0xDC00)
        return Some({ codepoint, byte_width: 4 })
      }
    }
    return Some({ codepoint: first, byte_width: 2 })
  }
  Some({ codepoint: first, byte_width: 2 })
}

///|
fn read_utf16_code_unit(
  input : Bytes,
  offset : Int,
  little_endian~ : Bool,
) -> Int {
  let first = input[offset].to_int()
  let second = input[offset + 1].to_int()
  if little_endian {
    first + second * 0x100
  } else {
    first * 0x100 + second
  }
}

///|
fn is_leading_surrogate(value : Int) -> Bool {
  value >= 0xD800 && value <= 0xDBFF
}

///|
fn is_trailing_surrogate(value : Int) -> Bool {
  value >= 0xDC00 && value <= 0xDFFF
}

///|
fn utf8_decode_error_scalar() -> DecodedScalar {
  decode_error_scalar()
}

///|
fn decode_error_scalar() -> DecodedScalar {
  { codepoint: decode_error_codepoint, byte_width: 1 }
}

///|
fn utf8_continuation_value(input : Bytes, offset : Int, end~ : Int) -> Int? {
  if offset < 0 || offset >= input.length() || offset >= end {
    return None
  }
  let value = input[offset].to_int()
  if value >= 0x80 && value <= 0xBF {
    Some(value - 0x80)
  } else {
    None
  }
}

///|
fn advance_point(
  point : @api.Point,
  byte_width : Int,
  codepoint : Int,
) -> @api.Point {
  if codepoint == 0x0A {
    @api.Point::new(row=point.row + 1, column=0)
  } else {
    @api.Point::new(
      row=point.row,
      column=point.column + byte_width.reinterpret_as_uint(),
    )
  }
}

///|
fn symbol_id_from_int(value : Int) -> @api.SymbolId {
  @api.SymbolId::new(value.reinterpret_as_uint())
}

///|
fn state_id_from_int(value : Int) -> @api.StateId {
  @api.StateId::new(value.reinterpret_as_uint())
}
