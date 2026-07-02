///|
test "language facade wraps validated tables without runtime leakage" {
  let tables = @tables.GeneratedLanguageTables::new(
    name="fixture",
    symbol_count=1,
    token_count=1,
    state_count=2,
    field_count=1,
    symbol_names=["document"],
    symbol_types=[@api.SymbolType::Regular],
    field_names=["", "body"],
    lex_modes=[@tables.GeneratedLexMode::new(), @tables.GeneratedLexMode::new()],
    primary_state_ids=[0, 1],
    large_state_count=2,
    large_parse_table=[
      [@tables.GeneratedParseTableCell::EmptyCell],
      [@tables.GeneratedParseTableCell::EmptyCell],
    ],
  )
  let language = language_from_generated_tables(tables)
  assert_eq(language.name(), "fixture")
  assert_eq(language.abi_version(), @tables.target_abi_version())
  assert_eq(language.symbol_count(), 1)
  assert_true(language.symbol_name(@api.SymbolId::new(0)) == Some("document"))
  assert_true(
    language.symbol_type(@api.SymbolId::new(0)) ==
    Some(@api.SymbolType::Regular),
  )
  assert_true(language.field_name_for_id(@api.FieldId::new(1)) == Some("body"))
  assert_true(language.field_id_for_name("body") == Some(@api.FieldId::new(1)))
  assert_true(
    language.symbol_for_name("document", is_named=true) ==
    Some(@api.SymbolId::new(0)),
  )
  assert_true(language.symbol_for_name("document", is_named=false) is None)
  assert_true(language.symbol_for_name("missing", is_named=true) is None)
}

///|
test "parser requires a language before parsing" {
  let parser = Parser::new()
  let result = @test.expect_error(() => parser.parse_bytes(b""))
  match result {
    NoLanguage => ()
    _ => fail("expected NoLanguage")
  }
}

///|
test "parser rejects old tree from another language" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())

  let old_parser = Parser::new()
  old_parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "other",
        #|  "rules": {
        #|    "document": { "type": "STRING", "value": "b" }
        #|  }
        #|}
      ),
    ),
  )
  let old_tree = old_parser.parse_bytes(b"b")

  let result = @test.expect_error(() => {
    parser.parse_bytes(b"a", old_tree=Some(old_tree))
  })
  assert_true(result is LanguageMismatch)
}

///|
test "parser accepts same-language old tree with full reparse fallback" {
  let language = parser_smoke_language()
  let old_parser = Parser::new()
  old_parser.set_language(language)
  let old_tree = old_parser.parse_bytes(b"a")

  let parser = Parser::new()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a", old_tree=Some(old_tree))
  assert_eq(tree.to_sexp(), "(document)")
  assert_eq(tree.root_node().end_byte(), 1)
}

///|
fn facade_range(start_byte : UInt, end_byte : UInt) -> @api.Range {
  @api.Range::new(
    start_byte~,
    end_byte~,
    start_point=@api.Point::zero(),
    end_point=@api.Point::new(row=0, column=end_byte),
  )
}

///|
fn facade_range_at(start_byte : UInt, end_byte : UInt) -> @api.Range {
  @api.Range::new(
    start_byte~,
    end_byte~,
    start_point=@api.Point::new(row=0, column=start_byte),
    end_point=@api.Point::new(row=0, column=end_byte),
  )
}

///|
fn facade_unbounded_range() -> @api.Range {
  @api.Range::unbounded(start_byte=0, start_point=@api.Point::zero())
}

///|
test "parser included ranges validate and preserve copies" {
  let parser = Parser::new()
  assert_eq(parser.included_ranges().length(), 0)

  let ranges = [facade_range(0, 1)]
  parser.set_included_ranges(ranges)
  ranges.push(facade_range(2, 3))
  assert_true(parser.included_ranges() == [facade_range(0, 1)])

  let returned = parser.included_ranges()
  returned.push(facade_range(4, 5))
  assert_true(parser.included_ranges() == [facade_range(0, 1)])

  let invalid = @test.expect_error(() => {
    parser.set_included_ranges([facade_range(3, 2)])
  })
  assert_true(invalid is InvalidRange(index=0, ..))
  assert_true(parser.included_ranges() == [facade_range(0, 1)])

  let overlapping = @test.expect_error(() => {
    parser.set_included_ranges([facade_range(0, 2), facade_range(1, 3)])
  })
  assert_true(overlapping is Overlap(index=1, ..))
  assert_true(parser.included_ranges() == [facade_range(0, 1)])

  let point_reordered = @api.Range::new(
    start_byte=4,
    end_byte=5,
    start_point=@api.Point::new(row=9, column=9),
    end_point=@api.Point::new(row=1, column=1),
  )
  parser.set_included_ranges([point_reordered])
  assert_true(parser.included_ranges() == [point_reordered])

  parser.set_included_ranges([])
  assert_eq(parser.included_ranges().length(), 0)
}

///|
test "parser lexes from a single included range" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  parser.set_included_ranges([facade_range_at(2, 3)])
  let tree = parser.parse_bytes(b"xxa")
  assert_eq(tree.to_sexp(), "(document)")
  let root = tree.root_node()
  assert_eq(root.start_byte(), 2)
  assert_eq(root.end_byte(), 3)
  assert_true(root.start_point() == @api.Point::new(row=0, column=2))
  assert_true(root.end_point() == @api.Point::new(row=0, column=3))
  let child = root.child(0)
  assert_eq(child.type_(), "a")
  assert_eq(child.start_byte(), 2)
  assert_eq(child.end_byte(), 3)
}

///|
test "parser lexes across multiple included ranges" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "included_range_sequence",
        #|  "rules": {
        #|    "document": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "STRING", "value": "a" },
        #|        { "type": "STRING", "value": "b" }
        #|      ]
        #|    }
        #|  }
        #|}
      ),
    ),
  )
  parser.set_included_ranges([facade_range_at(2, 3), facade_range_at(5, 6)])
  let tree = parser.parse_bytes(b"xxayyb")
  assert_eq(tree.to_sexp(), "(document)")
  let root = tree.root_node()
  assert_eq(root.start_byte(), 2)
  assert_eq(root.end_byte(), 6)
  let first = root.child(0)
  assert_eq(first.type_(), "a")
  assert_eq(first.start_byte(), 2)
  assert_eq(first.end_byte(), 3)
  let second = root.child(1)
  assert_eq(second.type_(), "b")
  assert_eq(second.start_byte(), 5)
  assert_eq(second.end_byte(), 6)
}

///|
test "parser skips empty included ranges while lexing" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  parser.set_included_ranges([
    facade_range_at(0, 0),
    facade_range_at(2, 2),
    facade_range_at(3, 4),
  ])
  let tree = parser.parse_bytes(b"xxxa")
  assert_eq(tree.to_sexp(), "(document)")
  let root = tree.root_node()
  assert_eq(root.start_byte(), 3)
  assert_eq(root.end_byte(), 4)
  assert_true(root.start_point() == @api.Point::new(row=0, column=3))
  assert_true(root.end_point() == @api.Point::new(row=0, column=4))
}

///|
test "parser accepts explicit unbounded included range" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  parser.set_included_ranges([
    @api.Range::unbounded(start_byte=0, start_point=@api.Point::zero()),
  ])
  let tree = parser.parse_bytes(b"a")
  assert_eq(tree.to_sexp(), "(document)")
  assert_eq(tree.root_node().start_byte(), 0)
  assert_eq(tree.root_node().end_byte(), 1)
}

///|
fn facade_log_entry(kind : LogType, message : String) -> String {
  let kind_name = match kind {
    Lex => "lex"
    Parse => "parse"
  }
  "\{kind_name}:\{message}"
}

///|
fn facade_contains_string(values : Array[String], value : String) -> Bool {
  for item in values {
    if item == value {
      return true
    }
  }
  false
}

///|
fn facade_contains_symbol(
  values : Array[@api.SymbolId],
  value : @api.SymbolId,
) -> Bool {
  for item in values {
    if item == value {
      return true
    }
  }
  false
}

///|
test "parser logger can be replaced, observed, and cleared" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let logs : Array[String] = []
  parser.set_logger(
    Some(
      Logger::new((kind, message) => logs.push(facade_log_entry(kind, message))),
    ),
  )
  match parser.logger() {
    Some(logger) => logger.log(Parse, "manual")
    None => fail("logger should be stored")
  }
  assert_true(facade_contains_string(logs, "parse:manual"))

  let _ = parser.parse_bytes(b"a")
  assert_true(facade_contains_string(logs, "parse:parse start"))
  assert_true(facade_contains_string(logs, "parse:parse accept"))
  assert_true(facade_contains_string(logs, "lex:lex start"))

  let count_after_parse = logs.length()
  parser.set_logger(None)
  assert_true(parser.logger() is None)
  let _ = parser.parse_bytes(b"a")
  assert_eq(logs.length(), count_after_parse)
}

///|
test "parser reset preserves configured facade state" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let ranges = [facade_range(0, 1)]
  parser.set_included_ranges(ranges)

  let logs : Array[String] = []
  parser.set_logger(
    Some(
      Logger::new((kind, message) => logs.push(facade_log_entry(kind, message))),
    ),
  )

  parser.reset()
  assert_true(parser.language() is Some(_))
  assert_true(parser.included_ranges() == ranges)
  match parser.logger() {
    Some(logger) => logger.log(Parse, "after reset")
    None => fail("logger should survive reset")
  }
  assert_true(facade_contains_string(logs, "parse:after reset"))
  assert_eq(parser.parse_bytes(b"a").to_sexp(), "(document)")
}

///|
fn generated_language_from(grammar_json : String) -> Language raise {
  let generated = @generator.generate_language(grammar_json)
  language_from_generated_tables(generated.tables)
}

///|
fn parser_smoke_language() -> Language raise {
  generated_language_from(
    (
      #|{
      #|  "name": "minimal",
      #|  "rules": {
      #|    "document": { "type": "STRING", "value": "a" }
      #|  }
      #|}
    ),
  )
}

///|
test "language symbol lookup and next state use generated table entries" {
  let language = parser_smoke_language()
  assert_true(
    language.symbol_for_name("document", is_named=true) ==
    Some(@api.SymbolId::new(2)),
  )
  assert_true(
    language.symbol_for_name("a", is_named=false) == Some(@api.SymbolId::new(1)),
  )
  assert_true(language.symbol_for_name("a", is_named=true) is None)
  assert_true(
    language.symbol_for_name("ERROR", is_named=true) ==
    Some(@api.SymbolId::new(0)),
  )
  assert_true(language.symbol_for_name("ERROR", is_named=false) is None)
  assert_true(language.symbol_for_name("ERR", is_named=true) is None)
  assert_true(
    language.next_state(@api.StateId::new(1), @api.SymbolId::new(1)) ==
    Some(@api.StateId::new(2)),
  )
  assert_true(
    language.next_state(@api.StateId::new(1), @api.SymbolId::new(2)) ==
    Some(@api.StateId::new(3)),
  )
  assert_true(
    language.next_state(@api.StateId::new(99), @api.SymbolId::new(1)) is None,
  )
  assert_true(
    language.next_state(@api.StateId::new(1), @api.SymbolId::new(99)) is None,
  )
}

///|
fn lookahead_names(iterator : LookaheadIterator) -> Array[String] {
  let names : Array[String] = []
  while iterator.next() {
    match iterator.current_symbol_name() {
      Some(name) => names.push(name)
      None => names.push("<missing>")
    }
  }
  names
}

///|
test "language lookahead iterator exposes valid large-state symbols" {
  let language = parser_smoke_language()
  guard language.lookahead_iterator(@api.StateId::new(1)) is Some(iterator) else {
    fail("state 1 should have a lookahead iterator")
  }
  assert_eq(iterator.language().name(), "minimal")
  assert_true(iterator.state() == @api.StateId::new(1))
  assert_true(iterator.current_symbol() == @api.SymbolId::new(0))
  assert_true(iterator.current_symbol_name() == Some("ERROR"))
  assert_true(lookahead_names(iterator) == ["a", "document"])
  assert_true(iterator.current_symbol_name() == Some("document"))
  assert_true(!iterator.next())
  assert_true(language.lookahead_iterator(@api.StateId::new(99)) is None)
}

///|
test "lookahead iterator reset preserves invalid state failures" {
  let language = parser_smoke_language()
  guard language.lookahead_iterator(@api.StateId::new(1)) is Some(iterator) else {
    fail("state 1 should have a lookahead iterator")
  }
  ignore(iterator.next())
  assert_true(!iterator.reset_state(@api.StateId::new(99)))
  assert_true(iterator.current_symbol_name() == Some("a"))
  assert_true(iterator.reset_state(@api.StateId::new(1)))
  assert_true(iterator.current_symbol_name() == Some("ERROR"))
  assert_true(lookahead_names(iterator) == ["a", "document"])

  let other = language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="lookahead_reset",
      symbol_count=1,
      token_count=1,
      state_count=2,
      symbol_names=["end"],
      symbol_types=[@api.SymbolType::Anonymous],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(),
      ],
      primary_state_ids=[0, 1],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_state_count=2,
      large_parse_table=[
        [@tables.GeneratedParseTableCell::EmptyCell],
        [@tables.GeneratedParseTableCell::ActionCell(1)],
      ],
    ),
  )
  assert_true(iterator.reset(other, @api.StateId::new(1)))
  assert_eq(iterator.language().name(), "lookahead_reset")
  assert_true(lookahead_names(iterator) == ["end"])
}

///|
test "language lookahead iterator preserves small table section order" {
  let language = language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="small_lookahead",
      symbol_count=3,
      token_count=2,
      state_count=3,
      symbol_names=["end", "a", "document"],
      symbol_types=[
        @api.SymbolType::Anonymous,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(),
      ],
      primary_state_ids=[0, 1, 2],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
      ],
      large_state_count=1,
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      small_parse_table_map=[0, 1],
      small_parse_table=[
        @tables.GeneratedSmallParseTableRow::new(state_id=1, offset=0, sections=[
          @tables.GeneratedSmallParseTableSection::new(
            kind=SmallAction,
            value=1,
            symbols=[1, 0],
          ),
          @tables.GeneratedSmallParseTableSection::new(
            kind=SmallState,
            value=2,
            symbols=[2],
          ),
        ]),
        @tables.GeneratedSmallParseTableRow::new(state_id=2, offset=1),
      ],
    ),
  )
  guard language.lookahead_iterator(@api.StateId::new(1)) is Some(iterator) else {
    fail("small state should have a lookahead iterator")
  }
  assert_true(lookahead_names(iterator) == ["a", "end", "document"])
}

///|
test "language exposes supertypes and subtypes" {
  let language = generated_language_from(
    (
      #|{
      #|  "name": "supertypes",
      #|  "rules": {
      #|    "document": { "type": "SYMBOL", "name": "expr" },
      #|    "expr": {
      #|      "type": "CHOICE",
      #|      "members": [
      #|        { "type": "SYMBOL", "name": "literal" },
      #|        { "type": "SYMBOL", "name": "identifier" },
      #|        { "type": "STRING", "value": "?" }
      #|      ]
      #|    },
      #|    "literal": { "type": "STRING", "value": "a" },
      #|    "identifier": { "type": "STRING", "value": "b" }
      #|  },
      #|  "supertypes": ["expr"]
      #|}
    ),
  )
  guard language.symbol_for_name("expr", is_named=true) is Some(expr) else {
    fail("expr supertype should be visible")
  }
  guard language.symbol_for_name("literal", is_named=true) is Some(literal) else {
    fail("literal subtype should be visible")
  }
  guard language.symbol_for_name("identifier", is_named=true)
    is Some(identifier) else {
    fail("identifier subtype should be visible")
  }
  guard language.symbol_for_name("?", is_named=false) is Some(question) else {
    fail("anonymous subtype should be visible")
  }
  assert_true(language.supertypes() == [expr])
  let subtypes = language.subtypes(expr)
  assert_eq(subtypes.length(), 3)
  assert_true(facade_contains_symbol(subtypes, literal))
  assert_true(facade_contains_symbol(subtypes, identifier))
  assert_true(facade_contains_symbol(subtypes, question))
  assert_eq(language.subtypes(literal).length(), 0)
}

///|
test "language next state treats shift extra as same state" {
  let language = language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="shift_extra",
      symbol_count=1,
      token_count=1,
      state_count=2,
      symbol_names=["end"],
      symbol_types=[@api.SymbolType::Anonymous],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(),
      ],
      primary_state_ids=[0, 1],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::ShiftExtra,
        ]),
      ],
      large_state_count=2,
      large_parse_table=[
        [@tables.GeneratedParseTableCell::EmptyCell],
        [@tables.GeneratedParseTableCell::ActionCell(1)],
      ],
    ),
  )
  assert_true(
    language.next_state(@api.StateId::new(1), @api.SymbolId::new(0)) ==
    Some(@api.StateId::new(1)),
  )
}

///|
fn accept_trailing_extra_language() -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="accept_trailing_extra",
      symbol_count=4,
      token_count=3,
      state_count=4,
      production_id_count=1,
      main_lex_state_count=3,
      large_state_count=4,
      symbol_names=["end", "a", "comment", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=2),
        @tables.GeneratedLexMode::new(lex_state=2),
      ],
      primary_state_ids=[0, 1, 2, 3],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=3,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::ShiftExtra,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::StateCell(3),
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(4),
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=97, end=97),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(eof_action=Some(2), transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=33, end=33),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(2)),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
fn accept_trailing_external_extra_language(
  scanner : @tables.ExternalScannerDescriptor,
) -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="accept_trailing_external_extra",
      symbol_count=4,
      token_count=3,
      external_token_count=1,
      state_count=4,
      production_id_count=1,
      main_lex_state_count=2,
      external_lex_state_count=2,
      large_state_count=4,
      symbol_names=["end", "a", "external_comment", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=1, external_lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=1, external_lex_state=1),
      ],
      primary_state_ids=[0, 1, 2, 3],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=3,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::ShiftExtra,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::StateCell(3),
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(4),
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      external_lex_states=[
        @tables.GeneratedExternalLexState::new(),
        @tables.GeneratedExternalLexState::new(external_token_ids=[0]),
      ],
      external_scanner=scanner,
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=97, end=97),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
fn external_extra_between_tokens_language(
  scanner : @tables.ExternalScannerDescriptor,
) -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="external_extra_between_tokens",
      symbol_count=5,
      token_count=4,
      external_token_count=1,
      state_count=5,
      production_id_count=1,
      main_lex_state_count=3,
      external_lex_state_count=2,
      large_state_count=5,
      symbol_names=["end", "a", "b", "external_comment", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=1, external_lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=2),
        @tables.GeneratedLexMode::new(lex_state=2),
      ],
      primary_state_ids=[0, 1, 2, 3, 4],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=3, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::ShiftExtra,
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=4,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::StateCell(4),
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(4),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(5),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      external_lex_states=[
        @tables.GeneratedExternalLexState::new(),
        @tables.GeneratedExternalLexState::new(external_token_ids=[0]),
      ],
      external_scanner=scanner,
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=97, end=97),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=98, end=98),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(2)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
test "parser preserves trailing extra shifted after root reduction" {
  let parser = Parser::new()
  parser.set_language(accept_trailing_extra_language())
  let tree = parser.parse_bytes(b"a!")
  assert_eq(tree.to_sexp(), "(document (comment))")
  let root = tree.root_node()
  assert_eq(root.end_byte(), 2)
  assert_eq(root.child_count(), 2)
  assert_eq(root.named_child_count(), 1)
  let comment = root.named_child(0)
  assert_eq(comment.type_(), "comment")
  assert_true(comment.is_extra())
  assert_eq(comment.start_byte(), 1)
  assert_eq(comment.end_byte(), 2)
  assert_eq(comment.parent().type_(), "document")
}

///|
test "parser preserves trailing external extra shifted after root reduction" {
  let parser = Parser::new()
  parser.set_language(
    accept_trailing_external_extra_language(
      @tables.ExternalScannerDescriptor::with_scan(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[2],
        scan=context => {
          if context.byte_offset == 1 {
            @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
          } else {
            @tables.ExternalScanResult::NoToken
          }
        },
      ),
    ),
  )
  let tree = parser.parse_bytes(b"a!")
  assert_eq(tree.to_sexp(), "(document (external_comment))")
  let root = tree.root_node()
  assert_eq(root.end_byte(), 2)
  assert_eq(root.child_count(), 2)
  assert_eq(root.named_child_count(), 1)
  let comment = root.named_child(0)
  assert_eq(comment.type_(), "external_comment")
  assert_true(comment.is_extra())
  assert_eq(comment.start_byte(), 1)
  assert_eq(comment.end_byte(), 2)
  assert_eq(comment.parent().type_(), "document")
}

///|
test "parser preserves external extra between ordinary tokens" {
  let parser = Parser::new()
  parser.set_language(
    external_extra_between_tokens_language(
      @tables.ExternalScannerDescriptor::with_scan(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[3],
        scan=context => {
          if context.byte_offset == 1 && context.valid_symbols == [true] {
            @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=3)
          } else {
            @tables.ExternalScanResult::NoToken
          }
        },
      ),
    ),
  )
  let tree = parser.parse_bytes(b"a#x\nb")
  assert_eq(tree.to_sexp(), "(document (external_comment))")
  let root = tree.root_node()
  assert_eq(root.child_count(), 3)
  assert_eq(root.named_child_count(), 1)
  assert_eq(root.child(0).type_(), "a")
  assert_eq(root.child(0).start_byte(), 0)
  assert_eq(root.child(0).end_byte(), 1)
  let comment = root.child(1)
  assert_eq(comment.type_(), "external_comment")
  assert_true(comment.is_extra())
  assert_eq(comment.start_byte(), 1)
  assert_eq(comment.end_byte(), 4)
  assert_eq(root.child(2).type_(), "b")
  assert_eq(root.child(2).start_byte(), 4)
  assert_eq(root.child(2).end_byte(), 5)
}

///|
test "parser ignores zero-width external extra between ordinary tokens" {
  let parser = Parser::new()
  parser.set_language(
    external_extra_between_tokens_language(
      @tables.ExternalScannerDescriptor::with_scan(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[3],
        scan=context => {
          if context.byte_offset == 1 && context.valid_symbols == [true] {
            @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=0)
          } else {
            @tables.ExternalScanResult::NoToken
          }
        },
      ),
    ),
  )
  let tree = parser.parse_bytes(b"ab")
  assert_eq(tree.to_sexp(), "(document)")
  let root = tree.root_node()
  assert_eq(root.child_count(), 2)
  assert_eq(root.named_child_count(), 0)
  assert_eq(root.child(0).type_(), "a")
  assert_eq(root.child(0).start_byte(), 0)
  assert_eq(root.child(0).end_byte(), 1)
  assert_eq(root.child(1).type_(), "b")
  assert_eq(root.child(1).start_byte(), 1)
  assert_eq(root.child(1).end_byte(), 2)
}

///|
test "language next state maps builtin error symbols to error state" {
  let language = language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="builtin_error",
      symbol_count=3,
      state_count=2,
      symbol_names=["ERROR", "_ERROR", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Auxiliary,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(),
      ],
      primary_state_ids=[0, 1],
      large_state_count=2,
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
    ),
  )
  assert_true(
    language.next_state(@api.StateId::new(99), @api.SymbolId::new(0)) ==
    Some(@api.StateId::new(0)),
  )
  assert_true(
    language.next_state(@api.StateId::new(99), @api.SymbolId::new(1)) ==
    Some(@api.StateId::new(0)),
  )
  assert_true(
    language.next_state(@api.StateId::new(99), @api.SymbolId::new(2)) is None,
  )
}

///|
test "parser skips repetition shift as runtime parse action" {
  let language = language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="repetition_shift",
      symbol_count=1,
      token_count=1,
      state_count=2,
      symbol_names=["x"],
      symbol_types=[@api.SymbolType::Anonymous],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
      ],
      primary_state_ids=[0, 1],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=1, is_repetition=true),
        ]),
      ],
      large_state_count=2,
      large_parse_table=[
        [@tables.GeneratedParseTableCell::EmptyCell],
        [@tables.GeneratedParseTableCell::ActionCell(1)],
      ],
      main_lex_state_count=1,
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=120, end=120),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
  let parser = Parser::new()
  parser.set_language(language)
  let result = @test.expect_error(() => parser.parse_bytes(b"x"))
  match result {
    ParseTableError(state_id~, symbol_id~) => {
      assert_true(state_id == @api.StateId::new(1))
      assert_true(symbol_id == @api.SymbolId::new(0))
    }
    _ => fail("expected ParseTableError without ordinary repetition shift")
  }
}

///|
test "parser missing-token recovery skips repetition shifts" {
  let language = language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="missing_repetition_shift",
      symbol_count=3,
      token_count=2,
      state_count=4,
      production_id_count=1,
      symbol_names=["end", "a", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=0),
      ],
      primary_state_ids=[0, 1, 2, 3],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=true),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=2,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_state_count=4,
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::StateCell(3),
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      main_lex_state_count=1,
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(eof_action=Some(1)),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
      production_infos=[@tables.GeneratedProductionInfo::new()],
    ),
  )
  let parser = Parser::new()
  parser.set_language(language)
  let result = @test.expect_error(() => parser.parse_bytes(b""))
  match result {
    ParseTableError(state_id~, symbol_id~) => {
      assert_true(state_id == @api.StateId::new(1))
      assert_true(symbol_id == @api.SymbolId::new(0))
    }
    _ => fail("expected ParseTableError without missing recovery")
  }
}

///|
test "parser recovers by inserting a missing terminal before EOF" {
  let language = language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="missing_terminal",
      symbol_count=3,
      token_count=2,
      state_count=4,
      production_id_count=1,
      symbol_names=["end", "a", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=0),
      ],
      primary_state_ids=[0, 1, 2, 3],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=2,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_state_count=4,
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::StateCell(3),
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      main_lex_state_count=1,
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(eof_action=Some(1)),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
      production_infos=[@tables.GeneratedProductionInfo::new()],
    ),
  )
  let logs : Array[String] = []
  let parser = Parser::new()
  parser.set_logger(
    Some(
      Logger::new((kind, message) => logs.push(facade_log_entry(kind, message))),
    ),
  )
  parser.set_language(language)
  let tree = parser.parse_bytes(b"")
  assert_eq(tree.to_sexp(), "(document (MISSING \"a\"))")
  let root = tree.root_node()
  assert_true(root.has_error())
  assert_true(root.child(0).is_missing())
  assert_true(facade_contains_string(logs, "parse:insert missing token"))
}

///|
test "parser parses minimal generated language from bytes" {
  let parser = Parser::new()
  let language = parser_smoke_language()
  parser.set_language(language)
  let tree = parser.parse_bytes(b"a")
  assert_eq(tree.to_sexp(), "(document)")
  assert_true(tree.included_ranges() == [facade_unbounded_range()])
  let root = tree.root_node()
  assert_eq(root.type_(), "document")
  assert_eq(root.start_byte(), 0)
  assert_eq(root.end_byte(), 1)
  assert_eq(root.child_count(), 1)
  assert_eq(root.named_child_count(), 0)
  assert_eq(root.child(0).type_(), "a")
  assert_true(!root.child(0).is_named())
  assert_true(root.parse_state() == Some(@api.StateId::new(1)))
  assert_true(root.next_parse_state() == Some(@api.StateId::new(3)))
  assert_true(root.child(0).parse_state() == Some(@api.StateId::new(1)))
  assert_true(root.child(0).next_parse_state() == Some(@api.StateId::new(2)))
}

///|
test "parser recovers lex failure as error leaf before generated token" {
  let logs : Array[String] = []
  let parser = Parser::new()
  parser.set_logger(
    Some(
      Logger::new((kind, message) => logs.push(facade_log_entry(kind, message))),
    ),
  )
  parser.set_language(parser_smoke_language())
  let tree = parser.parse_bytes(b"xa")
  assert_eq(tree.to_sexp(), "(document (UNEXPECTED 'x'))")
  let root = tree.root_node()
  assert_true(root.has_error())
  assert_eq(root.start_byte(), 0)
  assert_eq(root.end_byte(), 2)
  assert_eq(root.child_count(), 2)
  let error = root.child(0)
  assert_true(error.is_error())
  assert_eq(error.type_(), "ERROR")
  assert_eq(error.start_byte(), 0)
  assert_eq(error.end_byte(), 1)
  assert_true(error.end_point() == @api.Point::new(row=0, column=1))
  assert_eq(root.child(1).type_(), "a")
  assert_true(facade_contains_string(logs, "parse:recover lex error"))
}

///|
test "parser formats recovered unexpected character boundaries" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  assert_eq(
    parser.parse_bytes(b"\na").to_sexp(),
    "(document (UNEXPECTED '\\n'))",
  )
  assert_eq(
    parser.parse_bytes(Bytes::from_array([b'\x00', b'a'])).to_sexp(),
    "(document (UNEXPECTED '\\0'))",
  )
  assert_eq(
    parser.parse_bytes(Bytes::from_array([b'\xFF', b'a'])).to_sexp(),
    "(document (UNEXPECTED INVALID))",
  )
}

///|
fn error_lex_fallback_language() -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="error_lex_fallback",
      symbol_count=4,
      token_count=3,
      state_count=4,
      production_id_count=1,
      main_lex_state_count=3,
      large_state_count=4,
      symbol_names=["end", "a", "error_chunk", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=2),
        @tables.GeneratedLexMode::new(lex_state=2),
      ],
      primary_state_ids=[0, 1, 2, 3],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=3,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::StateCell(3),
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=97, end=97),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=120, end=120),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(2), transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=120, end=120),
            ]),
          ]),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
test "parser uses error-state lex mode for recovered error span" {
  let parser = Parser::new()
  parser.set_language(error_lex_fallback_language())
  let tree = parser.parse_bytes(b"xxa")
  assert_eq(tree.to_sexp(), "(document (UNEXPECTED 'x'))")
  let error = tree.root_node().child(0)
  assert_true(error.is_error())
  assert_eq(error.start_byte(), 0)
  assert_eq(error.end_byte(), 2)
  assert_eq(tree.root_node().child(1).start_byte(), 2)
}

///|
fn unexpected_token_skip_language() -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="unexpected_token_skip",
      symbol_count=4,
      token_count=3,
      state_count=4,
      production_id_count=1,
      main_lex_state_count=2,
      large_state_count=4,
      symbol_names=["end", "a", "b", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=1),
      ],
      primary_state_ids=[0, 1, 2, 3],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=3,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::StateCell(3),
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=97, end=97),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(eof_action=Some(2), transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=98, end=98),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(2)),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
fn recover_action_language() -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="recover_action",
      symbol_count=4,
      token_count=3,
      state_count=4,
      production_id_count=1,
      main_lex_state_count=3,
      large_state_count=4,
      symbol_names=["end", "a", "b", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=2),
      ],
      primary_state_ids=[0, 1, 2, 3],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=3,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Recover,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::StateCell(3),
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(4),
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=97, end=97),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(eof_action=Some(2), transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=98, end=98),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(2)),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
test "parser executes recover action by wrapping lookahead" {
  let logs : Array[String] = []
  let parser = Parser::new()
  parser.set_logger(
    Some(
      Logger::new((kind, message) => logs.push(facade_log_entry(kind, message))),
    ),
  )
  parser.set_language(recover_action_language())
  let tree = parser.parse_bytes(b"ab")
  assert_eq(tree.to_sexp(), "(document (UNEXPECTED 'b'))")
  let root = tree.root_node()
  assert_true(root.has_error())
  assert_eq(root.child_count(), 2)
  assert_eq(root.child(0).type_(), "a")
  assert_true(root.child(1).is_error())
  assert_eq(root.child(1).start_byte(), 1)
  assert_eq(root.child(1).end_byte(), 2)
  assert_true(facade_contains_string(logs, "parse:skip unexpected token"))
}

///|
fn recover_eof_language() -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="recover_eof",
      symbol_count=2,
      token_count=2,
      state_count=2,
      main_lex_state_count=2,
      large_state_count=2,
      symbol_names=["end", "a"],
      symbol_types=[@api.SymbolType::Regular, @api.SymbolType::Anonymous],
      lex_modes=[
        @tables.GeneratedLexMode::new(lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=0),
      ],
      primary_state_ids=[0, 1],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=0, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Recover,
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::ActionCell(1),
        ],
      ],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=97, end=97),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
test "parser recovers eof by pushing empty error node" {
  let logs : Array[String] = []
  let parser = Parser::new()
  parser.set_logger(
    Some(
      Logger::new((kind, message) => logs.push(facade_log_entry(kind, message))),
    ),
  )
  parser.set_language(recover_eof_language())
  let tree = parser.parse_bytes(b"a")
  let root = tree.root_node()
  assert_eq(tree.to_sexp(), "(ERROR)")
  assert_true(root.is_error())
  assert_true(root.has_error())
  assert_eq(root.start_byte(), 1)
  assert_eq(root.end_byte(), 1)
  assert_true(facade_contains_string(logs, "parse:recover eof"))
}

///|
fn all_potential_reduce_language() -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="all_potential_reduce",
      symbol_count=6,
      token_count=4,
      state_count=5,
      production_id_count=2,
      main_lex_state_count=3,
      large_state_count=5,
      symbol_names=["end", "a", "b", "c", "prefix", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=2),
        @tables.GeneratedLexMode::new(lex_state=2),
      ],
      primary_state_ids=[0, 1, 2, 3, 4],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=4,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=5,
            child_count=1,
            dynamic_precedence=0,
            production_id=1,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::StateCell(3),
          @tables.GeneratedParseTableCell::StateCell(4),
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(4),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      production_infos=[
        @tables.GeneratedProductionInfo::new(),
        @tables.GeneratedProductionInfo::new(),
      ],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=97, end=97),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=99, end=99),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(3)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
test "parser tries all potential reductions before skipping token" {
  let logs : Array[String] = []
  let parser = Parser::new()
  parser.set_logger(
    Some(
      Logger::new((kind, message) => logs.push(facade_log_entry(kind, message))),
    ),
  )
  parser.set_language(all_potential_reduce_language())
  let tree = parser.parse_bytes(b"ac")
  assert_eq(tree.to_sexp(), "(document (prefix) (UNEXPECTED 'c'))")
  let root = tree.root_node()
  assert_true(root.has_error())
  assert_eq(root.child_count(), 2)
  assert_eq(root.child(0).type_(), "prefix")
  assert_true(root.child(0).parse_state() is None)
  assert_true(root.child(0).next_parse_state() is None)
  assert_true(root.child(1).is_error())
  assert_true(facade_contains_string(logs, "parse:reduce all potential"))
  assert_true(facade_contains_string(logs, "parse:skip unexpected token"))
}

///|
fn all_potential_reduce_order_language() -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="all_potential_reduce_order",
      symbol_count=7,
      token_count=5,
      state_count=4,
      production_id_count=2,
      main_lex_state_count=3,
      large_state_count=4,
      symbol_names=["end", "a", "x", "y", "c", "low", "high"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=2),
      ],
      primary_state_ids=[0, 1, 2, 3],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=5,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=6,
            child_count=1,
            dynamic_precedence=0,
            production_id=1,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::StateCell(3),
          @tables.GeneratedParseTableCell::StateCell(3),
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(4),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      production_infos=[
        @tables.GeneratedProductionInfo::new(),
        @tables.GeneratedProductionInfo::new(),
      ],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=97, end=97),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=99, end=99),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(4)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
test "parser orders all potential reductions by reduce symbol" {
  let parser = Parser::new()
  parser.set_language(all_potential_reduce_order_language())
  let tree = parser.parse_bytes(b"ac")
  assert_eq(tree.to_sexp(), "(high (UNEXPECTED 'c'))")
  assert_eq(tree.root_node().type_(), "high")
}

///|
fn dynamic_reduce_choice_language() -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="dynamic_reduce_choice",
      symbol_count=4,
      token_count=2,
      state_count=4,
      production_id_count=2,
      main_lex_state_count=2,
      large_state_count=4,
      symbol_names=["end", "a", "low", "high"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=1),
      ],
      primary_state_ids=[0, 1, 2, 3],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=2,
            child_count=1,
            dynamic_precedence=1,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Reduce(
            symbol_id=3,
            child_count=1,
            dynamic_precedence=7,
            production_id=1,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::StateCell(3),
          @tables.GeneratedParseTableCell::StateCell(3),
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      production_infos=[
        @tables.GeneratedProductionInfo::new(),
        @tables.GeneratedProductionInfo::new(),
      ],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=97, end=97),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
test "parser prefers higher dynamic precedence among reduce alternatives" {
  let parser = Parser::new()
  parser.set_language(dynamic_reduce_choice_language())
  let tree = parser.parse_bytes(b"a")
  let root = tree.root_node()
  assert_eq(tree.to_sexp(), "(high)")
  assert_eq(root.type_(), "high")
  assert_true(root.parse_state() is None)
  assert_true(root.next_parse_state() is None)
}

///|
test "parser prefers higher dynamic precedence across shift reduce branches" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "dynamic_shift_reduce",
        #|  "rules": {
        #|    "program": {
        #|      "type": "CHOICE",
        #|      "members": [
        #|        { "type": "SYMBOL", "name": "declaration" },
        #|        { "type": "SYMBOL", "name": "expression" }
        #|      ]
        #|    },
        #|    "expression": {
        #|      "type": "CHOICE",
        #|      "members": [
        #|        {
        #|          "type": "PREC_LEFT",
        #|          "value": 0,
        #|          "content": {
        #|            "type": "SEQ",
        #|            "members": [
        #|              { "type": "SYMBOL", "name": "expression" },
        #|              { "type": "STRING", "value": "*" },
        #|              { "type": "SYMBOL", "name": "expression" }
        #|            ]
        #|          }
        #|        },
        #|        { "type": "SYMBOL", "name": "identifier" }
        #|      ]
        #|    },
        #|    "declaration": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "SYMBOL", "name": "type" },
        #|        { "type": "SYMBOL", "name": "declarator" }
        #|      ]
        #|    },
        #|    "declarator": {
        #|      "type": "CHOICE",
        #|      "members": [
        #|        {
        #|          "type": "PREC_DYNAMIC",
        #|          "value": 1,
        #|          "content": {
        #|            "type": "SEQ",
        #|            "members": [
        #|              { "type": "STRING", "value": "*" },
        #|              { "type": "SYMBOL", "name": "identifier" }
        #|            ]
        #|          }
        #|        },
        #|        { "type": "SYMBOL", "name": "identifier" }
        #|      ]
        #|    },
        #|    "type": { "type": "SYMBOL", "name": "identifier" },
        #|    "identifier": { "type": "PATTERN", "value": "[a-z-A-Z]+" }
        #|  },
        #|  "extras": [{ "type": "PATTERN", "value": "\\s" }],
        #|  "conflicts": [["expression", "type"]]
        #|}
      ),
    ),
  )
  let tree = parser.parse_bytes(b"T * x")
  assert_eq(
    tree.to_sexp(),
    "(program (declaration (type (identifier)) (declarator (identifier))))",
  )
}

///|
test "parser skips lexed unexpected token before reducing" {
  let logs : Array[String] = []
  let parser = Parser::new()
  parser.set_logger(
    Some(
      Logger::new((kind, message) => logs.push(facade_log_entry(kind, message))),
    ),
  )
  parser.set_language(unexpected_token_skip_language())
  let tree = parser.parse_bytes(b"ab")
  assert_eq(tree.to_sexp(), "(document (UNEXPECTED 'b'))")
  let root = tree.root_node()
  assert_true(root.has_error())
  assert_eq(root.child_count(), 2)
  assert_eq(root.child(0).type_(), "a")
  assert_true(root.child(1).is_error())
  assert_eq(root.child(1).start_byte(), 1)
  assert_eq(root.child(1).end_byte(), 2)
  assert_true(facade_contains_string(logs, "parse:skip unexpected token"))
}

///|
test "parser recovers missing terminal in generated language" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let tree = parser.parse_bytes(b"")
  assert_eq(tree.to_sexp(), "(document (MISSING \"a\"))")
  assert_true(tree.root_node().has_error())
}

///|
test "parser attaches recovered lex error before generated missing token" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let tree = parser.parse_bytes(b"x")
  assert_eq(tree.to_sexp(), "(document (UNEXPECTED 'x') (MISSING \"a\"))")
  let root = tree.root_node()
  assert_true(root.has_error())
  assert_true(root.child(0).is_error())
  assert_true(root.child(1).is_missing())
}

///|
fn external_scanner_language(
  scanner : @tables.ExternalScannerDescriptor,
  main_lex? : Bool = false,
) -> Language raise {
  let token_lex_state = if main_lex { 0 } else { @tables.lex_state_none() }
  let eof_lex_state = if main_lex { 1 } else { 0 }
  let main_lex_tables = if main_lex {
    [
      @tables.GeneratedLexTable::new(states=[
        @tables.GeneratedLexState::new(transitions=[
          @tables.GeneratedLexTransition::new(target_state=1, ranges=[
            @tables.GeneratedCharacterRange::new(start=120, end=120),
          ]),
        ]),
        @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
      ]),
      @tables.GeneratedLexTable::new(states=[
        @tables.GeneratedLexState::new(
          accept_symbol_id=Some(0),
          eof_action=Some(1),
        ),
        @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
      ]),
    ]
  } else {
    [
      @tables.GeneratedLexTable::new(states=[
        @tables.GeneratedLexState::new(
          accept_symbol_id=Some(0),
          eof_action=Some(1),
        ),
        @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
      ]),
    ]
  }
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="external_scan",
      symbol_count=3,
      token_count=2,
      external_token_count=1,
      state_count=4,
      production_id_count=1,
      main_lex_state_count=main_lex_tables.length(),
      external_lex_state_count=2,
      large_state_count=4,
      symbol_names=["end", "external_token", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(
          lex_state=token_lex_state,
          external_lex_state=1,
        ),
        @tables.GeneratedLexMode::new(lex_state=eof_lex_state),
        @tables.GeneratedLexMode::new(lex_state=eof_lex_state),
      ],
      primary_state_ids=[0, 1, 2, 3],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=2,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::StateCell(3),
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      external_lex_states=[
        @tables.GeneratedExternalLexState::new(),
        @tables.GeneratedExternalLexState::new(external_token_ids=[0]),
      ],
      external_scanner=scanner,
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables~,
    ),
  )
}

///|
fn external_internal_line_break_language(
  scanner : @tables.ExternalScannerDescriptor,
  internal_token_name? : String = "line_break",
) -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="external_internal_line_break",
      symbol_count=4,
      token_count=3,
      external_token_count=1,
      state_count=5,
      production_id_count=1,
      main_lex_state_count=2,
      external_lex_state_count=2,
      large_state_count=5,
      symbol_names=["end", "a", internal_token_name, "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(
          lex_state=@tables.lex_state_none(),
          external_lex_state=1,
        ),
        @tables.GeneratedLexMode::new(lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=1),
      ],
      primary_state_ids=[0, 1, 2, 3, 4],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=3, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=3,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::StateCell(4),
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(4),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      external_lex_states=[
        @tables.GeneratedExternalLexState::new(),
        @tables.GeneratedExternalLexState::new(external_token_ids=[0]),
      ],
      external_scanner=scanner,
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=97, end=97),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
fn epsilon_external_then_token_language(
  scanner : @tables.ExternalScannerDescriptor,
) -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="epsilon_external_tokens",
      symbol_count=4,
      token_count=3,
      external_token_count=1,
      state_count=5,
      production_id_count=1,
      main_lex_state_count=2,
      external_lex_state_count=2,
      large_state_count=5,
      symbol_names=["end", "zero_width", "hello", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(
          lex_state=@tables.lex_state_none(),
          external_lex_state=1,
        ),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=1),
      ],
      primary_state_ids=[0, 1, 2, 3, 4],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=3, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=3,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::StateCell(4),
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(4),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      external_lex_states=[
        @tables.GeneratedExternalLexState::new(),
        @tables.GeneratedExternalLexState::new(external_token_ids=[0]),
      ],
      external_scanner=scanner,
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=104, end=104),
            ]),
          ]),
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=2, ranges=[
              @tables.GeneratedCharacterRange::new(start=101, end=101),
            ]),
          ]),
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=3, ranges=[
              @tables.GeneratedCharacterRange::new(start=108, end=108),
            ]),
          ]),
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=4, ranges=[
              @tables.GeneratedCharacterRange::new(start=108, end=108),
            ]),
          ]),
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=5, ranges=[
              @tables.GeneratedCharacterRange::new(start=111, end=111),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(2)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
fn utf16_surrogate_scanner_language(
  scanner : @tables.ExternalScannerDescriptor,
  language_name? : String = "utf16_surrogate_oob",
  first_token_name? : String = "surrogate",
  second_token_name? : String = "supplementary",
  root_name? : String = "program",
) -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name=language_name,
      symbol_count=4,
      token_count=3,
      external_token_count=2,
      state_count=4,
      production_id_count=1,
      main_lex_state_count=1,
      external_lex_state_count=2,
      large_state_count=4,
      symbol_names=["end", first_token_name, second_token_name, root_name],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(
          lex_state=@tables.lex_state_none(),
          external_lex_state=1,
        ),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=0),
      ],
      primary_state_ids=[0, 1, 2, 3],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=3,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::StateCell(3),
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      external_lex_states=[
        @tables.GeneratedExternalLexState::new(),
        @tables.GeneratedExternalLexState::new(external_token_ids=[0, 1]),
      ],
      external_scanner=scanner,
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
fn external_lookahead_eof_boundary_language(
  scanner : @tables.ExternalScannerDescriptor,
) -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="external_lookahead_eof_boundary",
      symbol_count=6,
      token_count=4,
      external_token_count=3,
      state_count=7,
      production_id_count=2,
      main_lex_state_count=1,
      external_lex_state_count=3,
      large_state_count=7,
      symbol_names=[
        "end", "open_delim", "close_delim", "unclosed_delim", "span", "document",
      ],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(
          lex_state=@tables.lex_state_none(),
          external_lex_state=1,
        ),
        @tables.GeneratedLexMode::new(
          lex_state=@tables.lex_state_none(),
          external_lex_state=2,
        ),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=0),
      ],
      primary_state_ids=[0, 1, 2, 3, 4, 5, 6],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=4, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=3, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=4,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=5,
            child_count=1,
            dynamic_precedence=0,
            production_id=1,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::StateCell(5),
          @tables.GeneratedParseTableCell::StateCell(6),
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(4),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(5),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(5),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(6),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      external_lex_states=[
        @tables.GeneratedExternalLexState::new(),
        @tables.GeneratedExternalLexState::new(external_token_ids=[0, 2]),
        @tables.GeneratedExternalLexState::new(external_token_ids=[1]),
      ],
      external_scanner=scanner,
      production_infos=[
        @tables.GeneratedProductionInfo::new(),
        @tables.GeneratedProductionInfo::new(),
      ],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
fn external_zero_width_extra_fallback_language(
  scanner : @tables.ExternalScannerDescriptor,
) -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="external_zero_width_extra_fallback",
      symbol_count=4,
      token_count=3,
      external_token_count=1,
      state_count=4,
      production_id_count=1,
      main_lex_state_count=2,
      external_lex_state_count=2,
      large_state_count=4,
      symbol_names=["end", "x", "external_extra", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0, external_lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=1),
      ],
      primary_state_ids=[0, 1, 2, 3],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::ShiftExtra,
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=3,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::StateCell(3),
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(4),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      external_lex_states=[
        @tables.GeneratedExternalLexState::new(),
        @tables.GeneratedExternalLexState::new(external_token_ids=[0]),
      ],
      external_scanner=scanner,
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=120, end=120),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
fn external_scanner(
  scan : (@tables.ExternalScannerContext) -> @tables.ExternalScanResult raise @api.ScannerError,
) -> @tables.ExternalScannerDescriptor {
  @tables.ExternalScannerDescriptor::with_scan(
    external_token_count=1,
    external_state_count=2,
    states=[[false], [true]],
    symbol_map=[1],
    scan~,
  )
}

///|
fn external_lookahead_eof_boundary_scanner() -> @tables.ExternalScannerDescriptor {
  @tables.ExternalScannerDescriptor::with_scan(
    external_token_count=3,
    external_state_count=3,
    states=[[false, false, false], [true, false, true], [false, true, false]],
    symbol_map=[1, 2, 3],
    scan=context => {
      if context.eof() ||
        context.advance_steps[context.current_step_index].codepoint != 96 {
        return @tables.ExternalScanResult::NoToken
      }
      context.advance()
      context.mark_end()
      if context.valid_symbols[1] {
        return context.token(external_token_id=1)
      }
      if context.valid_symbols[0] {
        while !context.eof() {
          if context.advance_steps[context.current_step_index].codepoint == 96 {
            return context.token(external_token_id=0)
          }
          context.advance()
        }
        if context.valid_symbols[2] {
          return context.token(external_token_id=2)
        }
      }
      @tables.ExternalScanResult::NoToken
    },
  )
}

///|
fn external_pair_scanner_language(
  scanner : @tables.ExternalScannerDescriptor,
) -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="external_pair_scan",
      symbol_count=3,
      token_count=2,
      external_token_count=1,
      state_count=5,
      production_id_count=1,
      main_lex_state_count=1,
      external_lex_state_count=2,
      large_state_count=5,
      symbol_names=["end", "external_token", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(
          lex_state=@tables.lex_state_none(),
          external_lex_state=1,
        ),
        @tables.GeneratedLexMode::new(
          lex_state=@tables.lex_state_none(),
          external_lex_state=1,
        ),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=0),
      ],
      primary_state_ids=[0, 1, 2, 3, 4],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=3, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=2,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::StateCell(4),
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(4),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      external_lex_states=[
        @tables.GeneratedExternalLexState::new(),
        @tables.GeneratedExternalLexState::new(external_token_ids=[0]),
      ],
      external_scanner=scanner,
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
fn external_after_a_scanner_language(
  scanner : @tables.ExternalScannerDescriptor,
) -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="external_after_a_scan",
      symbol_count=4,
      token_count=3,
      external_token_count=1,
      state_count=5,
      production_id_count=1,
      main_lex_state_count=1,
      external_lex_state_count=2,
      large_state_count=5,
      symbol_names=["end", "a", "external_token", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(
          lex_state=@tables.lex_state_none(),
          external_lex_state=1,
        ),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=0),
      ],
      primary_state_ids=[0, 1, 2, 3, 4],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=3, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=3,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::StateCell(4),
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(4),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      external_lex_states=[
        @tables.GeneratedExternalLexState::new(),
        @tables.GeneratedExternalLexState::new(external_token_ids=[0]),
      ],
      external_scanner=scanner,
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(start=97, end=97),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
      ],
    ),
  )
}

///|
test "parser accepts external scanner token" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        if context.byte_offset != 0 {
          raise @api.ScannerError::Failure("unexpected byte offset")
        }
        if context.point != @api.Point::zero() {
          raise @api.ScannerError::Failure("unexpected point")
        }
        if context.valid_symbols != [true] {
          raise @api.ScannerError::Failure("unexpected valid symbols")
        }
        @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
      }),
    ),
  )
  let tree = parser.parse_bytes(b"x")
  assert_eq(tree.to_sexp(), "(document (external_token))")
  let child = tree.root_node().child(0)
  assert_eq(child.type_(), "external_token")
  assert_eq(child.start_byte(), 0)
  assert_eq(child.end_byte(), 1)
}

///|
test "parser maps external scanner token to paired internal terminal" {
  let parser = Parser::new()
  parser.set_language(
    external_internal_line_break_language(
      @tables.ExternalScannerDescriptor::with_scan(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[2],
        scan=context => {
          if context.valid_symbols != [true] {
            raise @api.ScannerError::Failure("expected line break whitelist")
          }
          if context.byte_offset == 1 {
            @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
          } else {
            @tables.ExternalScanResult::NoToken
          }
        },
      ),
    ),
  )
  let tree = parser.parse_bytes(b"a\n")
  assert_eq(tree.to_sexp(), "(document)")
  let root = tree.root_node()
  assert_eq(root.child_count(), 2)
  assert_eq(root.child(0).type_(), "a")
  assert_eq(root.child(1).type_(), "line_break")
  assert_eq(root.child(1).start_byte(), 1)
  assert_eq(root.child(1).end_byte(), 2)
}

///|
test "parser maps external scanner token to paired anonymous literal terminal" {
  let parser = Parser::new()
  parser.set_language(
    external_internal_line_break_language(
      @tables.ExternalScannerDescriptor::with_scan(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[2],
        scan=context => {
          if context.byte_offset == 1 {
            @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
          } else {
            @tables.ExternalScanResult::NoToken
          }
        },
      ),
      internal_token_name="\n",
    ),
  )
  let tree = parser.parse_bytes(b"a\n")
  assert_eq(tree.to_sexp(), "(document)")
  let root = tree.root_node()
  assert_eq(root.child_count(), 2)
  assert_eq(root.child(0).type_(), "a")
  assert_eq(root.child(1).type_(), "\n")
  assert_eq(root.child(1).start_byte(), 1)
  assert_eq(root.child(1).end_byte(), 2)
}

///|
test "parser accepts external scanner token built with advance and mark_end" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        context.advance(skip=true)
        if context.current_byte() != 1 {
          raise @api.ScannerError::Failure("expected skipped byte")
        }
        context.advance()
        context.mark_end()
        context.token(external_token_id=0)
      }),
    ),
  )
  let tree = parser.parse_bytes(b"xy")
  assert_eq(tree.to_sexp(), "(document (external_token))")
  let child = tree.root_node().child(0)
  assert_eq(child.start_byte(), 1)
  assert_eq(child.end_byte(), 2)
  assert_true(child.start_point() == @api.Point::new(row=0, column=1))
  assert_true(child.end_point() == @api.Point::new(row=0, column=2))
}

///|
test "external scanner token after mark_end clamps start to marked end" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        context.advance()
        context.mark_end()
        context.advance(skip=true)
        context.advance(skip=true)
        context.token(external_token_id=0)
      }),
    ),
  )
  let tree = parser.parse_bytes(b"\n  ")
  let child = tree.root_node().child(0)
  assert_eq(child.type_(), "external_token")
  assert_eq(child.start_byte(), 1)
  assert_eq(child.end_byte(), 1)
  assert_true(child.start_point() == @api.Point::new(row=1, column=0))
  assert_true(child.end_point() == @api.Point::new(row=1, column=0))
}

///|
test "external scanner context records column access and logs through parser logger" {
  let parser = Parser::new()
  let logs : Array[String] = []
  parser.set_logger(
    Some(
      Logger::new((kind, message) => logs.push(facade_log_entry(kind, message))),
    ),
  )
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        context.log("scanner note")
        if context.get_column() != 0 {
          raise @api.ScannerError::Failure("expected column")
        }
        if !context.did_get_column() {
          raise @api.ScannerError::Failure("expected column access flag")
        }
        @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
      }),
    ),
  )
  let tree = parser.parse_bytes(b"x")
  assert_eq(tree.to_sexp(), "(document (external_token))")
  assert_true(facade_contains_string(logs, "lex:scanner note"))
}

///|
test "external scanner column ignores file start BOM" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        context.advance(skip=true)
        if context.current_byte() != 3 {
          raise @api.ScannerError::Failure("expected skipped UTF-8 BOM")
        }
        if context.get_column() != 0 {
          raise @api.ScannerError::Failure("BOM should not increment column")
        }
        context.advance()
        context.mark_end()
        context.token(external_token_id=0)
      }),
    ),
  )
  let tree = parser.parse_bytes(
    Bytes::from_array([b'\xEF', b'\xBB', b'\xBF', b'x']),
  )
  assert_eq(tree.to_sexp(), "(document (external_token))")
  let child = tree.root_node().child(0)
  assert_eq(child.start_byte(), 3)
  assert_eq(child.end_byte(), 4)
  assert_true(child.start_point() == @api.Point::new(row=0, column=3))
  assert_true(child.end_point() == @api.Point::new(row=0, column=4))
}

///|
test "parser accepts external scanner zero-width state change token" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        context.token(external_token_id=0, state_changed=true)
      }),
    ),
  )
  let tree = parser.parse_bytes(b"")
  assert_eq(tree.to_sexp(), "(document (external_token))")
  let child = tree.root_node().child(0)
  assert_eq(child.start_byte(), 0)
  assert_eq(child.end_byte(), 0)
}

///|
test "parser accepts external scanner zero-width serialized state change token" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      @tables.ExternalScannerDescriptor::with_callbacks(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[1],
        create=() => (),
        destroy=() => (),
        deserialize=_state => (),
        serialize=() => Bytes::from_array([b's']),
        scan=_context => {
          @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=0)
        },
      ),
    ),
  )
  let tree = parser.parse_bytes(b"")
  assert_eq(tree.to_sexp(), "(document (external_token))")
  let child = tree.root_node().child(0)
  assert_eq(child.start_byte(), 0)
  assert_eq(child.end_byte(), 0)
}

///|
test "parser accepts external scanner zero-width ordinary token without state change" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(_context => {
        @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=0)
      }),
    ),
  )
  let tree = parser.parse_bytes(b"")
  assert_eq(tree.to_sexp(), "(document (external_token))")
  let child = tree.root_node().child(0)
  assert_eq(child.start_byte(), 0)
  assert_eq(child.end_byte(), 0)
}

///|
test "parser accepts zero-width external token before main token" {
  let parser = Parser::new()
  parser.set_language(
    epsilon_external_then_token_language(
      @tables.ExternalScannerDescriptor::with_scan(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[1],
        scan=_context => {
          @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=0)
        },
      ),
    ),
  )
  let tree = parser.parse_bytes(b"hello")
  assert_eq(tree.to_sexp(), "(document (zero_width))")
  let root = tree.root_node()
  assert_eq(root.child_count(), 2)
  assert_eq(root.child(0).type_(), "zero_width")
  assert_eq(root.child(0).start_byte(), 0)
  assert_eq(root.child(0).end_byte(), 0)
  assert_eq(root.child(1).type_(), "hello")
  assert_eq(root.child(1).start_byte(), 0)
  assert_eq(root.child(1).end_byte(), 5)
}

///|
test "parser ignores zero-width external extra without state change" {
  let parser = Parser::new()
  parser.set_language(
    external_zero_width_extra_fallback_language(
      @tables.ExternalScannerDescriptor::with_scan(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[2],
        scan=_context => {
          @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=0)
        },
      ),
    ),
  )
  let tree = parser.parse_bytes(b"x")
  assert_eq(tree.to_sexp(), "(document)")
  assert_eq(tree.root_node().end_byte(), 1)
}

///|
test "parser ignores zero-width external extra range without state change" {
  let parser = Parser::new()
  parser.set_language(
    external_zero_width_extra_fallback_language(
      @tables.ExternalScannerDescriptor::with_scan(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[2],
        scan=context => context.token(external_token_id=0),
      ),
    ),
  )
  let tree = parser.parse_bytes(b"x")
  assert_eq(tree.to_sexp(), "(document)")
  assert_eq(tree.root_node().end_byte(), 1)
}

///|
test "parser falls back to main lexer when external scanner returns no token" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(_context => @tables.ExternalScanResult::NoToken),
      main_lex=true,
    ),
  )
  let tree = parser.parse_bytes(b"x")
  assert_eq(tree.to_sexp(), "(document (external_token))")
  assert_eq(tree.root_node().child(0).end_byte(), 1)
}

///|
test "parser runs external scanner lifecycle callbacks" {
  let events : Array[String] = []
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      @tables.ExternalScannerDescriptor::with_callbacks(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[1],
        create=() => events.push("create"),
        destroy=() => events.push("destroy"),
        deserialize=state => events.push("deserialize:\{state.length()}"),
        serialize=() => {
          events.push("serialize")
          Bytes::from_array([b's'])
        },
        scan=_context => {
          events.push("scan")
          @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
        },
      ),
    ),
  )
  let tree = parser.parse_bytes(b"x")
  assert_eq(tree.to_sexp(), "(document (external_token))")
  assert_true(
    events == ["create", "deserialize:0", "scan", "serialize", "destroy"],
  )
}

///|
test "parser reuses unchanged same-input old tree without scanner session" {
  let events : Array[String] = []
  let language = external_scanner_language(
    @tables.ExternalScannerDescriptor::with_callbacks(
      external_token_count=1,
      external_state_count=2,
      states=[[false], [true]],
      symbol_map=[1],
      create=() => events.push("create"),
      destroy=() => events.push("destroy"),
      deserialize=state => events.push("deserialize:\{state.length()}"),
      serialize=() => {
        events.push("serialize")
        Bytes::new(0)
      },
      scan=_context => {
        events.push("scan")
        @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
      },
    ),
  )
  let parser = Parser::new()
  parser.set_language(language)
  let old_tree = parser.parse_bytes(b"x")
  assert_true(
    events == ["create", "deserialize:0", "scan", "serialize", "destroy"],
  )

  let logs : Array[String] = []
  let reparsing_parser = Parser::new()
  reparsing_parser.set_logger(
    Some(
      Logger::new((kind, message) => logs.push(facade_log_entry(kind, message))),
    ),
  )
  reparsing_parser.set_language(language)
  let reused = reparsing_parser.parse_bytes(b"x", old_tree=Some(old_tree))
  assert_eq(reused.to_sexp(), "(document (external_token))")
  assert_true(!old_tree.root_node().eq(reused.root_node()))
  assert_true(facade_contains_string(logs, "parse:reuse old tree"))
  assert_true(
    events == ["create", "deserialize:0", "scan", "serialize", "destroy"],
  )
}

///|
test "parser passes previous external scanner state to next scan" {
  let events : Array[String] = []
  let scan_count = [0]
  let parser = Parser::new()
  parser.set_language(
    external_pair_scanner_language(
      @tables.ExternalScannerDescriptor::with_callbacks(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[1],
        create=() => events.push("create"),
        destroy=() => events.push("destroy"),
        deserialize=state => {
          if state.length() == 0 {
            events.push("deserialize:empty")
          } else {
            events.push("deserialize:\{state[0].to_int()}")
          }
        },
        serialize=() => {
          events.push("serialize:\{scan_count[0]}")
          Bytes::from_array([scan_count[0].to_byte()])
        },
        scan=context => {
          scan_count[0] += 1
          events.push("scan:\{context.byte_offset}")
          @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
        },
      ),
    ),
  )
  let tree = parser.parse_bytes(b"xy")
  assert_eq(tree.to_sexp(), "(document (external_token) (external_token))")
  assert_true(
    events ==
    [
      "create", "deserialize:empty", "scan:0", "serialize:1", "deserialize:1", "scan:1",
      "serialize:2", "destroy",
    ],
  )
}

///|
test "parser destroys external scanner after scanner failure" {
  let events : Array[String] = []
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      @tables.ExternalScannerDescriptor::with_callbacks(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[1],
        create=() => events.push("create"),
        destroy=() => events.push("destroy"),
        deserialize=_state => events.push("deserialize"),
        serialize=() => Bytes::new(0),
        scan=_context => {
          events.push("scan")
          raise @api.ScannerError::Failure("boom")
        },
      ),
    ),
  )
  let result = @test.expect_error(() => parser.parse_bytes(b"x"))
  match result {
    ScannerError(error) =>
      assert_true(error == @api.ScannerError::Failure("boom"))
    _ => fail("expected ScannerError")
  }
  assert_true(events == ["create", "deserialize", "scan", "destroy"])
}

///|
test "parser reset destroys external scanner retained after cancellation" {
  let events : Array[String] = []
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      @tables.ExternalScannerDescriptor::with_callbacks(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[1],
        create=() => events.push("create"),
        destroy=() => events.push("destroy"),
        deserialize=_state => events.push("deserialize"),
        serialize=() => {
          events.push("serialize")
          Bytes::new(0)
        },
        scan=_context => {
          events.push("scan")
          @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
        },
      ),
    ),
  )
  let result = @test.expect_error(() => {
    parser.parse_bytes(
      b"x",
      options=ParseOptions::progress(state => state.current_byte_offset == 0),
    )
  })
  match result {
    Cancelled(state) => assert_eq(state.current_byte_offset, 0)
    _ => fail("expected cancellation")
  }
  assert_true(events == ["create"])

  parser.reset()
  assert_true(events == ["create", "destroy"])

  parser.reset()
  assert_true(events == ["create", "destroy"])
}

///|
test "parser set_language destroys external scanner retained after cancellation" {
  let events : Array[String] = []
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      @tables.ExternalScannerDescriptor::with_callbacks(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[1],
        create=() => events.push("create"),
        destroy=() => events.push("destroy"),
        deserialize=_state => events.push("deserialize"),
        serialize=() => {
          events.push("serialize")
          Bytes::new(0)
        },
        scan=_context => {
          events.push("scan")
          @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
        },
      ),
    ),
  )
  let result = @test.expect_error(() => {
    parser.parse_bytes(
      b"x",
      options=ParseOptions::progress(state => state.current_byte_offset == 0),
    )
  })
  assert_true(result is Cancelled(_))
  assert_true(events == ["create"])

  parser.set_language(parser_smoke_language())
  assert_true(events == ["create", "destroy"])
}

///|
test "parser reuses external scanner retained after cancellation" {
  let events : Array[String] = []
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      @tables.ExternalScannerDescriptor::with_callbacks(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[1],
        create=() => events.push("create"),
        destroy=() => events.push("destroy"),
        deserialize=_state => events.push("deserialize"),
        serialize=() => {
          events.push("serialize")
          Bytes::new(0)
        },
        scan=_context => {
          events.push("scan")
          @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
        },
      ),
    ),
  )
  let result = @test.expect_error(() => {
    parser.parse_bytes(
      b"x",
      options=ParseOptions::progress(state => state.current_byte_offset == 0),
    )
  })
  assert_true(result is Cancelled(_))
  assert_true(events == ["create"])

  let tree = parser.parse_bytes(b"x")
  assert_eq(tree.to_sexp(), "(document (external_token))")
  assert_true(
    events == ["create", "deserialize", "scan", "serialize", "destroy"],
  )
}

///|
test "parser resumes external scanner state retained after cancellation" {
  let events : Array[String] = []
  let scan_count = [0]
  let parser = Parser::new()
  parser.set_language(
    external_pair_scanner_language(
      @tables.ExternalScannerDescriptor::with_callbacks(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[1],
        create=() => events.push("create"),
        destroy=() => events.push("destroy"),
        deserialize=state => {
          if state.length() == 0 {
            events.push("deserialize:empty")
          } else {
            events.push("deserialize:\{state[0].to_int()}")
          }
        },
        serialize=() => {
          events.push("serialize:\{scan_count[0]}")
          Bytes::from_array([scan_count[0].to_byte()])
        },
        scan=context => {
          scan_count[0] += 1
          events.push("scan:\{context.byte_offset}")
          @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
        },
      ),
    ),
  )
  let cancelled = @test.expect_error(() => {
    parser.parse_bytes(
      b"xy",
      options=ParseOptions::progress(state => state.current_byte_offset >= 1),
    )
  })
  match cancelled {
    Cancelled(state) => assert_eq(state.current_byte_offset, 1)
    _ => fail("expected progress callback cancellation")
  }
  assert_true(
    events == ["create", "deserialize:empty", "scan:0", "serialize:1"],
  )

  let tree = parser.parse_bytes(b"xy")
  assert_eq(tree.to_sexp(), "(document (external_token) (external_token))")
  assert_true(
    events ==
    [
      "create", "deserialize:empty", "scan:0", "serialize:1", "deserialize:1", "scan:1",
      "serialize:2", "destroy",
    ],
  )
}

///|
test "parser validates external scanner serialized state size" {
  let events : Array[String] = []
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      @tables.ExternalScannerDescriptor::with_callbacks(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[1],
        create=() => events.push("create"),
        destroy=() => events.push("destroy"),
        deserialize=_state => events.push("deserialize"),
        serialize=() => {
          events.push("serialize")
          Bytes::new(@tables.external_scanner_serialization_buffer_size() + 1)
        },
        scan=_context => {
          events.push("scan")
          @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
        },
      ),
    ),
  )
  let result = @test.expect_error(() => parser.parse_bytes(b"x"))
  match result {
    ScannerError(error) =>
      assert_true(
        error ==
        @api.ScannerError::InvalidResult(
          "external scanner serialized state too large",
        ),
      )
    _ => fail("expected ScannerError")
  }
  assert_true(
    events == ["create", "deserialize", "scan", "serialize", "destroy"],
  )
}

///|
test "parser reports missing external scanner callback" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      @tables.ExternalScannerDescriptor::new(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[1],
      ),
    ),
  )
  let result = @test.expect_error(() => parser.parse_bytes(b"x"))
  match result {
    ScannerError(error) =>
      assert_true(
        error ==
        @api.ScannerError::Failure("external scanner scan callback missing"),
      )
    _ => fail("expected ScannerError")
  }
}

///|
test "parser reports external scanner callback failure" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(_context => raise @api.ScannerError::Failure("boom")),
    ),
  )
  let result = @test.expect_error(() => parser.parse_bytes(b"x"))
  match result {
    ScannerError(error) =>
      assert_true(error == @api.ScannerError::Failure("boom"))
    _ => fail("expected ScannerError")
  }
}

///|
test "parser validates external scanner token id" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(_context => {
        @tables.ExternalScanResult::Token(external_token_id=1, bytes_read=1)
      }),
    ),
  )
  let result = @test.expect_error(() => parser.parse_bytes(b"x"))
  match result {
    ScannerError(error) =>
      assert_true(
        error ==
        @api.ScannerError::InvalidResult("external token id out of range"),
      )
    _ => fail("expected ScannerError")
  }
}

///|
test "parser validates external scanner whitelist" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      @tables.ExternalScannerDescriptor::with_scan(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [false]],
        symbol_map=[1],
        scan=_context => {
          @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
        },
      ),
    ),
  )
  let result = @test.expect_error(() => parser.parse_bytes(b"x"))
  match result {
    ScannerError(error) =>
      assert_true(
        error ==
        @api.ScannerError::InvalidResult("external token id is not valid"),
      )
    _ => fail("expected ScannerError")
  }
}

///|
test "parser validates external scanner consumed input bounds" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(_context => {
        @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=2)
      }),
    ),
  )
  let result = @test.expect_error(() => parser.parse_bytes(b"x"))
  match result {
    ScannerError(error) =>
      assert_true(
        error ==
        @api.ScannerError::InvalidResult("external scanner consumed past input"),
      )
    _ => fail("expected ScannerError")
  }
}

///|
test "parser rejects external scanner token range before current byte" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(_context => {
        @tables.ExternalScanResult::TokenRange(
          external_token_id=0,
          start_byte=0,
          end_byte=1,
          start_point=@api.Point::zero(),
          end_point=@api.Point::new(row=0, column=1),
          state_changed=false,
        )
      }),
    ),
  )
  parser.set_included_ranges([facade_range_at(1, 3)])
  let result = @test.expect_error(() => parser.parse_bytes(b"xyz"))
  match result {
    ScannerError(error) =>
      assert_true(
        error ==
        @api.ScannerError::InvalidResult(
          "external scanner token range is invalid",
        ),
      )
    _ => fail("expected ScannerError")
  }
}

///|
test "parser passes snapped included range start to external scanner" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        if context.byte_offset != 1 {
          raise @api.ScannerError::Failure("expected included range start")
        }
        if context.point != @api.Point::new(row=0, column=1) {
          raise @api.ScannerError::Failure("expected included range point")
        }
        if !context.is_at_included_range_start() {
          raise @api.ScannerError::Failure("expected included range flag")
        }
        if context.eof() {
          raise @api.ScannerError::Failure("unexpected eof")
        }
        @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
      }),
    ),
  )
  parser.set_included_ranges([facade_range_at(1, 2)])
  let tree = parser.parse_bytes(b"xy")
  assert_eq(tree.to_sexp(), "(document (external_token))")
  let child = tree.root_node().child(0)
  assert_eq(child.start_byte(), 1)
  assert_eq(child.end_byte(), 2)
}

///|
test "parser external scanner context updates eof after advance" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        if context.eof() {
          raise @api.ScannerError::Failure("unexpected initial eof")
        }
        if !context.is_at_included_range_start() {
          raise @api.ScannerError::Failure("expected initial range start")
        }
        context.advance()
        if !context.eof() {
          raise @api.ScannerError::Failure("expected eof after advance")
        }
        if context.is_at_included_range_start() {
          raise @api.ScannerError::Failure("range start should update")
        }
        context.token(external_token_id=0)
      }),
    ),
  )
  let tree = parser.parse_bytes(b"x")
  assert_eq(tree.to_sexp(), "(document (external_token))")
  let child = tree.root_node().child(0)
  assert_eq(child.start_byte(), 0)
  assert_eq(child.end_byte(), 1)
}

///|
test "parser external scanner mark_end at included range start uses previous range end" {
  let scan_offsets : Array[UInt] = []
  let parser = Parser::new()
  parser.set_language(
    external_pair_scanner_language(
      external_scanner(context => {
        scan_offsets.push(context.byte_offset)
        if context.byte_offset == 0 {
          context.advance()
          return context.token(external_token_id=0)
        }
        if context.byte_offset != 3 {
          raise @api.ScannerError::Failure(
            "expected second included range start",
          )
        }
        if !context.is_at_included_range_start() {
          raise @api.ScannerError::Failure("expected included range flag")
        }
        context.mark_end()
        context.token(external_token_id=0)
      }),
    ),
  )
  parser.set_included_ranges([facade_range_at(0, 1), facade_range_at(3, 4)])
  let tree = parser.parse_bytes(b"x--y")
  assert_eq(tree.to_sexp(), "(document (external_token) (external_token))")
  assert_true(scan_offsets == [0, 3])
  let root = tree.root_node()
  let first = root.child(0)
  let second = root.child(1)
  assert_eq(first.start_byte(), 0)
  assert_eq(first.end_byte(), 1)
  assert_eq(second.start_byte(), 1)
  assert_eq(second.end_byte(), 1)
  assert_true(second.start_point() == @api.Point::new(row=0, column=1))
  assert_true(second.end_point() == @api.Point::new(row=0, column=1))
}

///|
test "external scanner eof lookahead follows included range expansion" {
  let parser = Parser::new()
  parser.set_language(
    external_lookahead_eof_boundary_language(
      external_lookahead_eof_boundary_scanner(),
    ),
  )
  parser.set_included_ranges([facade_range_at(0, 1)])
  let tree1 = parser.parse_bytes(b"``")
  assert_eq(tree1.to_sexp(), "(document (unclosed_delim))")

  parser.set_included_ranges([facade_range_at(0, 2)])
  let tree2 = parser.parse_bytes(b"``", old_tree=Some(tree1))
  assert_eq(tree2.to_sexp(), "(document (span (open_delim) (close_delim)))")
}

///|
test "parser passes EOF state to external scanner context" {
  let saw_eof = [false]
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        saw_eof[0] = context.eof()
        if context.is_at_included_range_start() {
          raise @api.ScannerError::Failure("EOF should not be range start")
        }
        @tables.ExternalScanResult::NoToken
      }),
    ),
  )
  let result = @test.expect_error(() => parser.parse_bytes(b""))
  match result {
    LexError(byte_offset=0, ..) => ()
    _ => fail("expected LexError after scanner declined EOF")
  }
  assert_true(saw_eof[0])
}

///|
test "external scanner get_column works at EOF" {
  let saw_eof = [false]
  let saw_column = [false]
  let parser = Parser::new()
  parser.set_language(
    external_after_a_scanner_language(
      external_scanner(context => {
        saw_eof[0] = context.eof()
        if !context.eof() {
          raise @api.ScannerError::Failure("expected EOF")
        }
        if context.byte_offset != 1 {
          raise @api.ScannerError::Failure("expected EOF byte")
        }
        if context.get_column() != 1 {
          raise @api.ScannerError::Failure("expected EOF column")
        }
        saw_column[0] = context.did_get_column()
        @tables.ExternalScanResult::NoToken
      }),
    ),
  )
  let result = @test.expect_error(() => parser.parse_bytes(b"a"))
  match result {
    LexError(byte_offset=1, ..) => ()
    _ => fail("expected LexError after scanner declined EOF")
  }
  assert_true(saw_eof[0])
  assert_true(saw_column[0])
}

///|
test "external scanner repeated get_column after advance is bounded" {
  let columns : Array[UInt] = []
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        for _ in 0..<10 {
          context.advance()
          columns.push(context.get_column())
        }
        @tables.ExternalScanResult::NoToken
      }),
    ),
  )
  let result = @test.expect_error(() => parser.parse_bytes(b"\nHello"))
  ignore(result)
  let expected_prefix : Array[UInt] = [0, 1, 2, 3, 4, 5, 5, 5, 5, 5]
  assert_true(columns.length() >= expected_prefix.length())
  for i in 0..<expected_prefix.length() {
    assert_eq(columns[i], expected_prefix[i])
  }
}

///|
test "external scanner context reports code point column" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        if context.point.column != 2 {
          raise @api.ScannerError::Failure("expected byte column")
        }
        if context.get_column() != 1 {
          raise @api.ScannerError::Failure("expected code point column")
        }
        @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
      }),
    ),
  )
  parser.set_included_ranges([facade_range_at(2, 3)])
  let tree = parser.parse_bytes(Bytes::from_array([b'\xC3', b'\xA9', b'x']))
  assert_eq(tree.to_sexp(), "(document (external_token))")
}

///|
test "external scanner chooses token from current column" {
  let make_language = () => {
    utf16_surrogate_scanner_language(
      @tables.ExternalScannerDescriptor::with_scan(
        external_token_count=2,
        external_state_count=2,
        states=[[false, false], [true, true]],
        symbol_map=[1, 2],
        scan=context => {
          if context.get_column() == 0 {
            @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
          } else {
            @tables.ExternalScanResult::Token(external_token_id=1, bytes_read=1)
          }
        },
      ),
      language_name="external_current_column",
      first_token_name="column_zero",
      second_token_name="column_nonzero",
      root_name="document",
    )
  }

  let leading_parser = Parser::new()
  leading_parser.set_language(make_language())
  let leading_tree = leading_parser.parse_bytes(b"x")
  assert_eq(leading_tree.to_sexp(), "(document (column_zero))")
  let leading_child = leading_tree.root_node().child(0)
  assert_eq(leading_child.type_(), "column_zero")
  assert_eq(leading_child.start_byte(), 0)
  assert_eq(leading_child.end_byte(), 1)

  let indented_parser = Parser::new()
  indented_parser.set_language(make_language())
  indented_parser.set_included_ranges([facade_range_at(2, 3)])
  let indented_tree = indented_parser.parse_bytes(b"  x")
  assert_eq(indented_tree.to_sexp(), "(document (column_nonzero))")
  let indented_child = indented_tree.root_node().child(0)
  assert_eq(indented_child.type_(), "column_nonzero")
  assert_eq(indented_child.start_byte(), 2)
  assert_eq(indented_child.end_byte(), 3)
}

///|
test "external scanner skip unicode extra keeps code point column" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        while !context.eof() {
          let codepoint = context.advance_steps[context.current_step_index].codepoint
          if codepoint == 0x25A1 || codepoint == 32 {
            context.advance(skip=true)
          } else {
            break
          }
        }
        if context.current_byte() != 4 {
          raise @api.ScannerError::Failure("expected byte offset after skips")
        }
        if context.current_point() != @api.Point::new(row=0, column=4) {
          raise @api.ScannerError::Failure("expected byte column after skips")
        }
        if context.get_column() != 2 {
          raise @api.ScannerError::Failure("expected code point column")
        }
        context.advance()
        context.token(external_token_id=0)
      }),
    ),
  )
  let tree = parser.parse_bytes(
    Bytes::from_array([b'\xE2', b'\x96', b'\xA1', b' ', b'-']),
  )
  assert_eq(tree.to_sexp(), "(document (external_token))")
  let child = tree.root_node().child(0)
  assert_eq(child.start_byte(), 4)
  assert_eq(child.end_byte(), 5)
  assert_true(child.start_point() == @api.Point::new(row=0, column=4))
  assert_true(child.end_point() == @api.Point::new(row=0, column=5))
}

///|
test "external scanner get_column marks node changed after column shift" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        if context.get_column() != 2 {
          raise @api.ScannerError::Failure("expected scanner column")
        }
        @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
      }),
    ),
  )
  parser.set_included_ranges([facade_range_at(2, 3)])
  let tree = parser.parse_bytes(b"xxa")
  assert_eq(tree.to_sexp(), "(document (external_token))")
  let initial_child = tree.root_node().child(0)
  assert_eq(initial_child.start_byte(), 2)
  assert_true(!initial_child.has_changes())

  tree.edit(
    @api.InputEdit::new(
      start_byte=1,
      old_end_byte=1,
      new_end_byte=2,
      start_point=@api.Point::new(row=0, column=1),
      old_end_point=@api.Point::new(row=0, column=1),
      new_end_point=@api.Point::new(row=0, column=2),
    ),
  )
  let shifted_child = tree.root_node().child(0)
  assert_eq(shifted_child.start_byte(), 3)
  assert_true(shifted_child.has_changes())
}

///|
test "external scanner context does not count leading BOM as column" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(context => {
        if context.point.column != 3 {
          raise @api.ScannerError::Failure("expected byte column after BOM")
        }
        if context.get_column() != 0 {
          raise @api.ScannerError::Failure("expected BOM-neutral column")
        }
        @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
      }),
    ),
  )
  parser.set_included_ranges([facade_range_at(3, 4)])
  let tree = parser.parse_bytes(
    Bytes::from_array([b'\xEF', b'\xBB', b'\xBF', b'x']),
  )
  assert_eq(tree.to_sexp(), "(document (external_token))")
}

///|
test "parser validates external scanner consumed included range bounds" {
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      external_scanner(_context => {
        @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=2)
      }),
    ),
  )
  parser.set_included_ranges([facade_range_at(0, 1)])
  let result = @test.expect_error(() => parser.parse_bytes(b"xy"))
  match result {
    ScannerError(error) =>
      assert_true(
        error ==
        @api.ScannerError::InvalidResult(
          "external scanner consumed past included range",
        ),
      )
    _ => fail("expected ScannerError")
  }
}

///|
fn scalar_token_language(
  name : String,
  token_name : String,
  codepoint : Int,
) -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name~,
      symbol_count=3,
      token_count=2,
      state_count=4,
      production_id_count=1,
      main_lex_state_count=3,
      large_state_count=4,
      symbol_names=["end", token_name, "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=2),
      ],
      primary_state_ids=[0, 1, 2, 3],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=2,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::StateCell(3),
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(
                start=codepoint,
                end=codepoint,
              ),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
fn scalar_pair_language(
  name : String,
  first_token : String,
  first_codepoint : Int,
  second_token : String,
  second_codepoint : Int,
) -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name~,
      symbol_count=4,
      token_count=3,
      state_count=5,
      production_id_count=1,
      main_lex_state_count=4,
      large_state_count=5,
      symbol_names=["end", first_token, second_token, "document"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
      ],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(lex_state=0),
        @tables.GeneratedLexMode::new(lex_state=1),
        @tables.GeneratedLexMode::new(lex_state=2),
        @tables.GeneratedLexMode::new(lex_state=3),
      ],
      primary_state_ids=[0, 1, 2, 3, 4],
      parse_action_lists=[
        @tables.GeneratedParseActionList::new(),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Shift(state_id=3, is_repetition=false),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=3,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
        ]),
        @tables.GeneratedParseActionList::new(actions=[
          @tables.GeneratedParseAction::Accept,
        ]),
      ],
      large_parse_table=[
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(1),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::StateCell(4),
        ],
        [
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::ActionCell(2),
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(3),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
        [
          @tables.GeneratedParseTableCell::ActionCell(4),
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
          @tables.GeneratedParseTableCell::EmptyCell,
        ],
      ],
      production_infos=[@tables.GeneratedProductionInfo::new()],
      main_lex_tables=[
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(
                start=first_codepoint,
                end=first_codepoint,
              ),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(1)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(transitions=[
            @tables.GeneratedLexTransition::new(target_state=1, ranges=[
              @tables.GeneratedCharacterRange::new(
                start=second_codepoint,
                end=second_codepoint,
              ),
            ]),
          ]),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(2)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
        @tables.GeneratedLexTable::new(states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=Some(1),
          ),
          @tables.GeneratedLexState::new(accept_symbol_id=Some(0)),
        ]),
      ],
    ),
  )
}

///|
fn invalid_utf8_language() -> Language raise {
  scalar_token_language("invalid_utf8", "invalid_utf8", -1)
}

///|
test "parser advances invalid UTF-8 as decode error token" {
  let parser = Parser::new()
  parser.set_language(invalid_utf8_language())
  let tree = parser.parse_bytes(Bytes::from_array([b'\xFF']))
  assert_eq(tree.to_sexp(), "(document)")
  let root = tree.root_node()
  assert_eq(root.start_byte(), 0)
  assert_eq(root.end_byte(), 1)
  assert_true(root.end_point() == @api.Point::new(row=0, column=1))
  let child = root.child(0)
  assert_eq(child.type_(), "invalid_utf8")
  assert_eq(child.start_byte(), 0)
  assert_eq(child.end_byte(), 1)
  assert_true(!child.is_named())
}

///|
test "parser does not join UTF-8 scalar across callback chunks" {
  let parser = Parser::new()
  parser.set_language(
    scalar_pair_language(
      "split_utf8_decode_errors", "invalid_first", -1, "invalid_second", -1,
    ),
  )
  let input = Input::from_callback((byte, _point) => {
    if byte == 0 {
      InputChunk::from_bytes(Bytes::from_array([b'\xC2']))
    } else if byte == 1 {
      InputChunk::from_bytes(Bytes::from_array([b'\xB1']))
    } else {
      InputChunk::eof()
    }
  })
  let tree = parser.parse(input)
  assert_eq(tree.to_sexp(), "(document)")
  let root = tree.root_node()
  assert_eq(root.child(0).type_(), "invalid_first")
  assert_eq(root.child(0).start_byte(), 0)
  assert_eq(root.child(0).end_byte(), 1)
  assert_eq(root.child(1).type_(), "invalid_second")
  assert_eq(root.child(1).start_byte(), 1)
  assert_eq(root.child(1).end_byte(), 2)
}

///|
test "parser parses UTF-16 input facade" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())

  let le = parser.parse(Input::from_string("a", encoding=Utf16LE))
  assert_eq(le.to_sexp(), "(document)")
  assert_eq(le.root_node().end_byte(), 2)
  assert_true(le.root_node().end_point() == @api.Point::new(row=0, column=2))

  let be = parser.parse(
    Input::from_bytes(Bytes::from_array([b'\x00', b'a']), encoding=Utf16BE),
  )
  assert_eq(be.to_sexp(), "(document)")
  assert_eq(be.root_node().end_byte(), 2)
  assert_true(be.root_node().end_point() == @api.Point::new(row=0, column=2))
}

///|
test "parser encodes supplementary UTF-16 string input as surrogate pair" {
  let face_codepoint = 0x1F600
  guard face_codepoint.to_char() is Some(face) else {
    fail("expected valid supplementary char")
  }
  let source = String::from_array([face])
  let parser = Parser::new()
  parser.set_language(
    scalar_token_language("string_utf16_face", "face", 0x1F600),
  )

  let le = parser.parse(Input::from_string(source, encoding=Utf16LE))
  assert_eq(le.to_sexp(), "(document)")
  let le_child = le.root_node().child(0)
  assert_eq(le_child.type_(), "face")
  assert_eq(le_child.start_byte(), 0)
  assert_eq(le_child.end_byte(), 4)
  assert_true(le_child.end_point() == @api.Point::new(row=0, column=4))

  let be = parser.parse(Input::from_string(source, encoding=Utf16BE))
  assert_eq(be.to_sexp(), "(document)")
  let be_child = be.root_node().child(0)
  assert_eq(be_child.type_(), "face")
  assert_eq(be_child.start_byte(), 0)
  assert_eq(be_child.end_byte(), 4)
  assert_true(be_child.end_point() == @api.Point::new(row=0, column=4))
}

///|
test "parser skips file-start BOM before lexing" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())

  let utf8 = parser.parse_bytes(
    Bytes::from_array([b'\xEF', b'\xBB', b'\xBF', b'a']),
  )
  let utf8_child = utf8.root_node().child(0)
  assert_eq(utf8_child.type_(), "a")
  assert_eq(utf8_child.start_byte(), 3)
  assert_eq(utf8_child.end_byte(), 4)
  assert_true(utf8_child.start_point() == @api.Point::new(row=0, column=3))

  let utf16 = parser.parse(
    Input::from_bytes(
      Bytes::from_array([b'\xFF', b'\xFE', b'a', b'\x00']),
      encoding=Utf16LE,
    ),
  )
  let utf16_child = utf16.root_node().child(0)
  assert_eq(utf16_child.type_(), "a")
  assert_eq(utf16_child.start_byte(), 2)
  assert_eq(utf16_child.end_byte(), 4)
  assert_true(utf16_child.start_point() == @api.Point::new(row=0, column=2))
}

///|
test "parser treats non-file-start BOM as ordinary input" {
  let parser = Parser::new()
  parser.set_language(scalar_token_language("bom_token", "bom", 0xFEFF))
  parser.set_included_ranges([facade_range_at(1, 4)])
  let tree = parser.parse_bytes(
    Bytes::from_array([b'x', b'\xEF', b'\xBB', b'\xBF']),
  )
  assert_eq(tree.to_sexp(), "(document)")
  let child = tree.root_node().child(0)
  assert_eq(child.type_(), "bom")
  assert_eq(child.start_byte(), 1)
  assert_eq(child.end_byte(), 4)
  assert_true(child.start_point() == @api.Point::new(row=0, column=1))
}

///|
test "parser decodes UTF-16 surrogate pair as one code point" {
  let parser = Parser::new()
  parser.set_language(scalar_token_language("grinning_face", "face", 0x1F600))
  let tree = parser.parse(
    Input::from_bytes(
      Bytes::from_array([b'\x3D', b'\xD8', b'\x00', b'\xDE']),
      encoding=Utf16LE,
    ),
  )
  assert_eq(tree.to_sexp(), "(document)")
  let child = tree.root_node().child(0)
  assert_eq(child.type_(), "face")
  assert_eq(child.start_byte(), 0)
  assert_eq(child.end_byte(), 4)
  assert_true(child.end_point() == @api.Point::new(row=0, column=4))
}

///|
test "parser keeps lone UTF-16 surrogate as code point" {
  let parser = Parser::new()
  parser.set_language(
    scalar_token_language("lone_lead_surrogate", "lead", 0xD800),
  )
  let tree = parser.parse(
    Input::from_bytes(Bytes::from_array([b'\x00', b'\xD8']), encoding=Utf16LE),
  )
  assert_eq(tree.to_sexp(), "(document)")
  let child = tree.root_node().child(0)
  assert_eq(child.type_(), "lead")
  assert_eq(child.start_byte(), 0)
  assert_eq(child.end_byte(), 2)
  assert_true(child.end_point() == @api.Point::new(row=0, column=2))
}

///|
test "parser does not join UTF-16 surrogate pair across callback chunks" {
  let parser = Parser::new()
  parser.set_language(
    scalar_pair_language("split_surrogates", "lead", 0xD800, "trail", 0xDE00),
  )
  let input = Input::from_callback(
    (byte, _point) => {
      if byte == 0 {
        InputChunk::from_bytes(Bytes::from_array([b'\x00', b'\xD8']))
      } else if byte == 2 {
        InputChunk::from_bytes(Bytes::from_array([b'\x00', b'\xDE']))
      } else {
        InputChunk::eof()
      }
    },
    encoding=Utf16LE,
  )
  let tree = parser.parse(input)
  assert_eq(tree.to_sexp(), "(document)")
  let root = tree.root_node()
  assert_eq(root.child(0).type_(), "lead")
  assert_eq(root.child(0).start_byte(), 0)
  assert_eq(root.child(0).end_byte(), 2)
  assert_eq(root.child(1).type_(), "trail")
  assert_eq(root.child(1).start_byte(), 2)
  assert_eq(root.child(1).end_byte(), 4)
}

///|
test "external scanner sees UTF-16 lead surrogate at callback chunk end" {
  let parser = Parser::new()
  parser.set_language(
    utf16_surrogate_scanner_language(
      @tables.ExternalScannerDescriptor::with_scan(
        external_token_count=2,
        external_state_count=2,
        states=[[false, false], [true, true]],
        symbol_map=[1, 2],
        scan=context => {
          if context.advance_steps.length() == 0 {
            return @tables.ExternalScanResult::NoToken
          }
          let codepoint = context.advance_steps[0].codepoint
          if codepoint >= 0xD800 &&
            codepoint <= 0xDFFF &&
            context.valid_symbols[0] {
            context.advance()
            context.mark_end()
            context.token(external_token_id=0)
          } else if codepoint > 0xFFFF && context.valid_symbols[1] {
            context.advance()
            context.mark_end()
            context.token(external_token_id=1)
          } else {
            @tables.ExternalScanResult::NoToken
          }
        },
      ),
    ),
  )
  let poisoned_chunk = Bytes::from_array([b'\x3E', b'\xD8', b'\x8B', b'\xDD'])
  let input = Input::from_callback(
    (byte, _point) => {
      if byte == 0 {
        InputChunk::new(chunk=Some(poisoned_chunk), bytes_read=2)
      } else {
        InputChunk::eof()
      }
    },
    encoding=Utf16LE,
  )
  let tree = parser.parse(input)
  assert_eq(tree.to_sexp(), "(program (surrogate))")
}

///|
test "parser advances odd UTF-16 tail as decode error token" {
  let parser = Parser::new()
  parser.set_language(invalid_utf8_language())
  let tree = parser.parse(
    Input::from_bytes(Bytes::from_array([b'\x61']), encoding=Utf16LE),
  )
  assert_eq(tree.to_sexp(), "(document)")
  let child = tree.root_node().child(0)
  assert_eq(child.type_(), "invalid_utf8")
  assert_eq(child.start_byte(), 0)
  assert_eq(child.end_byte(), 1)
  assert_true(child.end_point() == @api.Point::new(row=0, column=1))
}

///|
test "parser stores configured included ranges on parse tree" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let ranges = [facade_range(0, 1)]
  parser.set_included_ranges(ranges)
  let tree = parser.parse_bytes(b"a")
  assert_true(tree.included_ranges() == ranges)
}

///|
test "tree copy preserves syntax and copied included ranges" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let ranges = [facade_range(0, 1)]
  parser.set_included_ranges(ranges)
  let tree = parser.parse_bytes(b"a")
  let copied = tree.copy()

  assert_eq(copied.to_sexp(), tree.to_sexp())
  assert_eq(copied.root_node().type_(), tree.root_node().type_())
  assert_true(copied.included_ranges() == ranges)

  let returned_ranges = copied.included_ranges()
  returned_ranges.push(facade_range(2, 3))
  assert_true(copied.included_ranges() == ranges)

  assert_eq(tree.changed_ranges(copied).length(), 0)
  copied.edit(
    @api.InputEdit::new(
      start_byte=0,
      old_end_byte=1,
      new_end_byte=2,
      start_point=@api.Point::zero(),
      old_end_point=@api.Point::new(row=0, column=1),
      new_end_point=@api.Point::new(row=0, column=2),
    ),
  )
  assert_eq(tree.root_node().end_byte(), 1)
  assert_eq(copied.root_node().end_byte(), 2)
  assert_true(tree.changed_ranges(copied) == [facade_range(0, 2)])
}

///|
test "changed ranges ignores empty combined root range" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "blank_changed_ranges",
        #|  "rules": {
        #|    "document": { "type": "BLANK" }
        #|  }
        #|}
      ),
    ),
  )
  let tree = parser.parse_bytes(b"")

  let ranged_parser = Parser::new()
  ranged_parser.set_language(parser.language().unwrap())
  ranged_parser.set_included_ranges([
    @api.Range::unbounded(start_byte=0, start_point=@api.Point::zero()),
  ])
  let ranged_tree = ranged_parser.parse_bytes(b"")

  assert_eq(tree.root_node().start_byte(), 0)
  assert_eq(tree.root_node().end_byte(), 0)
  assert_eq(ranged_tree.root_node().start_byte(), 0)
  assert_eq(ranged_tree.root_node().end_byte(), 0)
  assert_eq(tree.changed_ranges(ranged_tree).length(), 0)
}

///|
test "tree edit updates ranges and marks touched nodes changed" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "edit_ranges",
        #|  "rules": {
        #|    "document": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "STRING", "value": "a" },
        #|        { "type": "STRING", "value": "b" }
        #|      ]
        #|    }
        #|  }
        #|}
      ),
    ),
  )
  let tree = parser.parse_bytes(b"ab")
  tree.edit(
    @api.InputEdit::new(
      start_byte=0,
      old_end_byte=1,
      new_end_byte=2,
      start_point=@api.Point::zero(),
      old_end_point=@api.Point::new(row=0, column=1),
      new_end_point=@api.Point::new(row=0, column=2),
    ),
  )

  let root = tree.root_node()
  assert_eq(root.start_byte(), 0)
  assert_eq(root.end_byte(), 3)
  assert_true(root.end_point() == @api.Point::new(row=0, column=3))
  assert_true(root.has_changes())

  let first = root.child(0)
  assert_eq(first.start_byte(), 0)
  assert_eq(first.end_byte(), 2)
  assert_true(first.has_changes())

  let second = root.child(1)
  assert_eq(second.start_byte(), 2)
  assert_eq(second.end_byte(), 3)
  assert_true(second.has_changes())

  assert_true(tree.included_ranges() == [facade_unbounded_range()])
}

///|
test "tree edit pure insertion leaves shifted sibling unchanged" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "edit_pure_insert",
        #|  "rules": {
        #|    "document": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "STRING", "value": "a" },
        #|        { "type": "STRING", "value": "b" }
        #|      ]
        #|    }
        #|  }
        #|}
      ),
    ),
  )
  let tree = parser.parse_bytes(b"ab")
  tree.edit(
    @api.InputEdit::new(
      start_byte=1,
      old_end_byte=1,
      new_end_byte=2,
      start_point=@api.Point::new(row=0, column=1),
      old_end_point=@api.Point::new(row=0, column=1),
      new_end_point=@api.Point::new(row=0, column=2),
    ),
  )

  let root = tree.root_node()
  assert_eq(root.end_byte(), 3)
  assert_true(root.has_changes())

  let first = root.child(0)
  assert_eq(first.start_byte(), 0)
  assert_eq(first.end_byte(), 2)
  assert_true(first.has_changes())

  let second = root.child(1)
  assert_eq(second.start_byte(), 2)
  assert_eq(second.end_byte(), 3)
  assert_true(!second.has_changes())
}

///|
test "tree edit pure insertion at first child start marks first child" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "edit_pure_insert_start",
        #|  "rules": {
        #|    "document": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "STRING", "value": "a" },
        #|        { "type": "STRING", "value": "b" }
        #|      ]
        #|    }
        #|  }
        #|}
      ),
    ),
  )
  let tree = parser.parse_bytes(b"ab")
  tree.edit(
    @api.InputEdit::new(
      start_byte=0,
      old_end_byte=0,
      new_end_byte=1,
      start_point=@api.Point::zero(),
      old_end_point=@api.Point::zero(),
      new_end_point=@api.Point::new(row=0, column=1),
    ),
  )

  let root = tree.root_node()
  assert_true(root.has_changes())

  let first = root.child(0)
  assert_eq(first.start_byte(), 1)
  assert_eq(first.end_byte(), 2)
  assert_true(first.has_changes())

  let second = root.child(1)
  assert_eq(second.start_byte(), 2)
  assert_eq(second.end_byte(), 3)
  assert_true(!second.has_changes())
}

///|
test "changed ranges narrows edited old tree against full reparse" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "changed_ranges_reparse",
        #|  "rules": {
        #|    "document": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "PATTERN", "value": "a+" },
        #|        { "type": "STRING", "value": "b" }
        #|      ]
        #|    }
        #|  }
        #|}
      ),
    ),
  )
  let old_tree = parser.parse_bytes(b"ab")
  let edited_old_tree = old_tree.copy()
  edited_old_tree.edit(
    @api.InputEdit::new(
      start_byte=1,
      old_end_byte=1,
      new_end_byte=2,
      start_point=@api.Point::new(row=0, column=1),
      old_end_point=@api.Point::new(row=0, column=1),
      new_end_point=@api.Point::new(row=0, column=2),
    ),
  )

  let new_tree = parser.parse_bytes(b"aab", old_tree=Some(edited_old_tree))
  assert_true(
    edited_old_tree.changed_ranges(new_tree) == [facade_range_at(0, 2)],
  )
}

///|
test "node edit lets held handles follow tree edits explicitly" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "node_edit",
        #|  "rules": {
        #|    "document": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "STRING", "value": "a" },
        #|        { "type": "STRING", "value": "b" }
        #|      ]
        #|    }
        #|  }
        #|}
      ),
    ),
  )
  let tree = parser.parse_bytes(b"ab")
  let held_root = tree.root_node()
  let held_second = held_root.child(1)
  let edit = @api.InputEdit::new(
    start_byte=0,
    old_end_byte=1,
    new_end_byte=2,
    start_point=@api.Point::zero(),
    old_end_point=@api.Point::new(row=0, column=1),
    new_end_point=@api.Point::new(row=0, column=2),
  )

  tree.edit(edit)
  assert_eq(held_root.end_byte(), 2)
  assert_eq(held_second.start_byte(), 1)
  assert_eq(tree.root_node().end_byte(), 3)

  held_root.edit(edit)
  held_second.edit(edit)
  assert_eq(held_root.end_byte(), 3)
  assert_eq(held_second.start_byte(), 2)
  assert_true(held_root.has_changes())
  assert_true(held_second.has_changes())
}

///|
test "parser parses minimal generated language from string" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  assert_eq(parser.parse_string("a").to_sexp(), "(document)")
}

///|
test "parser parses UTF-8 Input facade" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let input = Input::from_string("a")
  assert_eq(parser.parse(input).to_sexp(), "(document)")
}

///|
test "parser reads chunked Input callback" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let offsets : Array[UInt] = []
  let columns : Array[UInt] = []
  let input = Input::from_callback((byte, point) => {
    offsets.push(byte)
    columns.push(point.column)
    if byte == 0 {
      InputChunk::from_bytes(b"a")
    } else {
      InputChunk::eof()
    }
  })
  let tree = parser.parse(input)
  assert_eq(tree.to_sexp(), "(document)")
  assert_true(offsets == [0, 1])
  assert_true(columns == [0, 1])
}

///|
test "parser checks Input language before reading callback" {
  let parser = Parser::new()
  let offsets : Array[UInt] = []
  let input = Input::from_callback((byte, _point) => {
    offsets.push(byte)
    InputChunk::new(chunk=None, bytes_read=1)
  })
  let result = @test.expect_error(() => parser.parse(input))
  match result {
    NoLanguage => ()
    _ => fail("expected NoLanguage")
  }
  assert_eq(offsets.length(), 0)
}

///|
test "parser checks Input old tree before reading callback" {
  let old_parser = Parser::new()
  old_parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "other_input_old_tree",
        #|  "rules": {
        #|    "document": { "type": "STRING", "value": "b" }
        #|  }
        #|}
      ),
    ),
  )
  let old_tree = old_parser.parse_bytes(b"b")

  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let offsets : Array[UInt] = []
  let input = Input::from_callback((byte, _point) => {
    offsets.push(byte)
    InputChunk::new(chunk=None, bytes_read=1)
  })
  let result = @test.expect_error(() => {
    parser.parse(input, old_tree=Some(old_tree))
  })
  match result {
    LanguageMismatch => ()
    _ => fail("expected LanguageMismatch")
  }
  assert_eq(offsets.length(), 0)
}

///|
test "parser can cancel Input before reading callback" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let offsets : Array[UInt] = []
  let input = Input::from_callback((byte, _point) => {
    offsets.push(byte)
    InputChunk::from_bytes(b"a")
  })
  let result = @test.expect_error(() => {
    parser.parse(
      input,
      options=ParseOptions::progress(state => state.current_byte_offset == 0),
    )
  })
  match result {
    Cancelled(state) => assert_eq(state.current_byte_offset, 0)
    _ => fail("expected Cancelled")
  }
  assert_eq(offsets.length(), 0)
}

///|
test "parser checks Input progress once at initial byte" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let progress_offsets : Array[UInt] = []
  let input_offsets : Array[UInt] = []
  let input = Input::from_callback((byte, _point) => {
    input_offsets.push(byte)
    if byte == 0 {
      InputChunk::from_bytes(b"a")
    } else {
      InputChunk::eof()
    }
  })
  let tree = parser.parse(
    input,
    options=ParseOptions::progress(state => {
      progress_offsets.push(state.current_byte_offset)
      false
    }),
  )
  assert_eq(tree.to_sexp(), "(document)")
  assert_true(input_offsets == [0, 1])
  let mut zero_count = 0
  let mut saw_after_input = false
  for offset in progress_offsets {
    if offset == 0 {
      zero_count += 1
    }
    if offset == 1 {
      saw_after_input = true
    }
  }
  assert_eq(zero_count, 1)
  assert_true(saw_after_input)
}

///|
test "parser advances Input callback point across newlines" {
  let parser = Parser::new()
  parser.set_language(
    scalar_pair_language("input_callback_newline_point", "newline", 10, "a", 97),
  )
  let offsets : Array[UInt] = []
  let rows : Array[UInt] = []
  let columns : Array[UInt] = []
  let input = Input::from_callback((byte, point) => {
    offsets.push(byte)
    rows.push(point.row)
    columns.push(point.column)
    if byte == 0 {
      InputChunk::from_bytes(b"\n")
    } else if byte == 1 {
      InputChunk::from_bytes(b"a")
    } else {
      InputChunk::eof()
    }
  })
  let tree = parser.parse(input)
  assert_eq(tree.to_sexp(), "(document)")
  assert_true(offsets == [0, 1, 2])
  assert_true(rows == [0, 1, 1])
  assert_true(columns == [0, 0, 1])
}

///|
test "parser Input resume skips fresh initial progress check" {
  let parser = Parser::new()
  parser.set_language(
    scalar_pair_language("input_progress_resume", "a", 97, "b", 98),
  )
  let cancelled = @test.expect_error(() => {
    parser.parse(
      Input::from_bytes(b"ab"),
      options=ParseOptions::progress(state => state.current_byte_offset >= 1),
    )
  })
  match cancelled {
    Cancelled(state) => assert_eq(state.current_byte_offset, 1)
    _ => fail("expected progress callback cancellation")
  }

  let resume_offsets : Array[UInt] = []
  let tree = parser.parse(
    Input::from_bytes(b"ab"),
    options=ParseOptions::progress(state => {
      resume_offsets.push(state.current_byte_offset)
      state.current_byte_offset == 0
    }),
  )
  assert_eq(tree.to_sexp(), "(document)")
  assert_true(!resume_offsets.is_empty())
  assert_eq(resume_offsets[0], 1)
  for offset in resume_offsets {
    assert_true(offset != 0)
  }
}

///|
test "parser reports invalid Input callback chunk" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let input = Input::from_callback((_byte, _point) => {
    InputChunk::new(chunk=None, bytes_read=1)
  })
  let result = @test.expect_error(() => parser.parse(input))
  match result {
    InvalidInputCallback(
      byte_offset=0,
      reason="non-empty read without chunk",
      ..
    ) => ()
    _ => fail("expected InvalidInputCallback")
  }
}

///|
test "parser reports oversized Input callback chunk length" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let input = Input::from_callback((_byte, _point) => {
    InputChunk::new(chunk=Some(b"a"), bytes_read=2)
  })
  let result = @test.expect_error(() => parser.parse(input))
  match result {
    InvalidInputCallback(
      byte_offset=0,
      reason="bytes_read exceeds chunk length",
      ..
    ) => ()
    _ => fail("expected InvalidInputCallback")
  }
}

///|
test "parser reports negative Input callback chunk length" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let input = Input::from_callback((_byte, _point) => {
    InputChunk::new(chunk=Some(b"a"), bytes_read=-1)
  })
  let result = @test.expect_error(() => parser.parse(input))
  match result {
    InvalidInputCallback(byte_offset=0, reason="negative bytes_read", ..) => ()
    _ => fail("expected InvalidInputCallback")
  }
}

///|
test "parser reports non-empty EOF Input callback chunk" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let input = Input::from_callback((_byte, _point) => {
    InputChunk::new(chunk=Some(b"a"), bytes_read=0)
  })
  let result = @test.expect_error(() => parser.parse(input))
  match result {
    InvalidInputCallback(
      byte_offset=0,
      reason="EOF read returned non-empty chunk",
      ..
    ) => ()
    _ => fail("expected InvalidInputCallback")
  }
}

///|
test "parser parse options can cancel before parsing" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let state = ParseState::new(current_byte_offset=7, has_error=true)
  let result = @test.expect_error(() => {
    parser.parse_bytes(b"a", options=ParseOptions::cancelled(state))
  })
  match result {
    Cancelled(cancelled) => assert_true(cancelled == state)
    _ => fail("expected Cancelled")
  }
}

///|
test "parser preconfigured cancellation skips external scanner create" {
  let events : Array[String] = []
  let parser = Parser::new()
  parser.set_language(
    external_scanner_language(
      @tables.ExternalScannerDescriptor::with_callbacks(
        external_token_count=1,
        external_state_count=2,
        states=[[false], [true]],
        symbol_map=[1],
        create=() => events.push("create"),
        destroy=() => events.push("destroy"),
        deserialize=_state => events.push("deserialize"),
        serialize=() => {
          events.push("serialize")
          Bytes::new(0)
        },
        scan=_context => {
          events.push("scan")
          @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
        },
      ),
    ),
  )
  let state = ParseState::new(current_byte_offset=7, has_error=true)
  let result = @test.expect_error(() => {
    parser.parse_bytes(b"x", options=ParseOptions::cancelled(state))
  })
  match result {
    Cancelled(cancelled) => assert_true(cancelled == state)
    _ => fail("expected Cancelled")
  }
  assert_true(events.is_empty())
}

///|
test "parser progress callback can cancel during parsing" {
  let parser = Parser::new()
  parser.set_language(scalar_pair_language("progress_cancel", "a", 97, "b", 98))
  let offsets : Array[UInt] = []
  let result = @test.expect_error(() => {
    parser.parse_bytes(
      b"ab",
      options=ParseOptions::progress(state => {
        offsets.push(state.current_byte_offset)
        state.current_byte_offset >= 1
      }),
    )
  })
  match result {
    Cancelled(state) => {
      assert_eq(state.current_byte_offset, 1)
      assert_true(!state.has_error)
    }
    _ => fail("expected progress callback cancellation")
  }
  assert_true(offsets == [0, 1])
}

///|
test "parser resumes outstanding parse after progress cancellation" {
  let parser = Parser::new()
  parser.set_language(scalar_pair_language("progress_resume", "a", 97, "b", 98))
  let cancelled = @test.expect_error(() => {
    parser.parse_bytes(
      b"ab",
      options=ParseOptions::progress(state => state.current_byte_offset >= 1),
    )
  })
  match cancelled {
    Cancelled(state) => assert_eq(state.current_byte_offset, 1)
    _ => fail("expected progress callback cancellation")
  }

  let resume_offsets : Array[UInt] = []
  let tree = parser.parse_bytes(
    b"ab",
    options=ParseOptions::progress(state => {
      resume_offsets.push(state.current_byte_offset)
      state.current_byte_offset == 0
    }),
  )
  assert_eq(tree.to_sexp(), "(document)")
  assert_true(!resume_offsets.is_empty())
  assert_eq(resume_offsets[0], 1)
  for offset in resume_offsets {
    assert_true(offset != 0)
  }
}

///|
test "parser logs when resuming outstanding parse" {
  let parser = Parser::new()
  parser.set_language(
    scalar_pair_language("progress_resume_log", "a", 97, "b", 98),
  )
  let logs : Array[String] = []
  parser.set_logger(
    Some(
      Logger::new((kind, message) => logs.push(facade_log_entry(kind, message))),
    ),
  )
  let cancelled = @test.expect_error(() => {
    parser.parse_bytes(
      b"ab",
      options=ParseOptions::progress(state => state.current_byte_offset >= 1),
    )
  })
  assert_true(cancelled is Cancelled(_))

  let _ = parser.parse_bytes(b"ab")
  assert_true(facade_contains_string(logs, "parse:resume parsing"))
}

///|
test "parser resume ignores newly supplied old tree" {
  let parser = Parser::new()
  parser.set_language(
    scalar_pair_language("progress_resume_old_tree", "a", 97, "b", 98),
  )
  let cancelled = @test.expect_error(() => {
    parser.parse_bytes(
      b"ab",
      options=ParseOptions::progress(state => state.current_byte_offset >= 1),
    )
  })
  assert_true(cancelled is Cancelled(_))

  let old_parser = Parser::new()
  old_parser.set_language(parser_smoke_language())
  let unrelated_old_tree = old_parser.parse_bytes(b"a")
  let tree = parser.parse_bytes(b"ab", old_tree=Some(unrelated_old_tree))
  assert_eq(tree.to_sexp(), "(document)")
}

///|
test "parser preconfigured cancellation preserves outstanding parse state" {
  let parser = Parser::new()
  parser.set_language(
    scalar_pair_language(
      "progress_resume_preconfigured_cancel", "a", 97, "b", 98,
    ),
  )
  let cancelled = @test.expect_error(() => {
    parser.parse_bytes(
      b"ab",
      options=ParseOptions::progress(state => state.current_byte_offset >= 1),
    )
  })
  assert_true(cancelled is Cancelled(_))

  let configured_state = ParseState::new(current_byte_offset=7, has_error=true)
  let configured = @test.expect_error(() => {
    parser.parse_bytes(b"ab", options=ParseOptions::cancelled(configured_state))
  })
  match configured {
    Cancelled(state) => assert_true(state == configured_state)
    _ => fail("expected preconfigured cancellation")
  }

  let resume_offsets : Array[UInt] = []
  let tree = parser.parse_bytes(
    b"ab",
    options=ParseOptions::progress(state => {
      resume_offsets.push(state.current_byte_offset)
      state.current_byte_offset == 0
    }),
  )
  assert_eq(tree.to_sexp(), "(document)")
  assert_true(!resume_offsets.is_empty())
  assert_eq(resume_offsets[0], 1)
}

///|
test "parser reset clears parse state retained after cancellation" {
  let parser = Parser::new()
  parser.set_language(
    scalar_pair_language("progress_reset_resume", "a", 97, "b", 98),
  )
  let cancelled = @test.expect_error(() => {
    parser.parse_bytes(
      b"ab",
      options=ParseOptions::progress(state => state.current_byte_offset >= 1),
    )
  })
  assert_true(cancelled is Cancelled(_))

  parser.reset()
  let restarted = @test.expect_error(() => {
    parser.parse_bytes(
      b"ab",
      options=ParseOptions::progress(state => state.current_byte_offset == 0),
    )
  })
  match restarted {
    Cancelled(state) => assert_eq(state.current_byte_offset, 0)
    _ => fail("expected fresh parse cancellation")
  }
}

///|
test "parser set_language clears parse state retained after cancellation" {
  let parser = Parser::new()
  parser.set_language(
    scalar_pair_language("progress_set_language_resume", "a", 97, "b", 98),
  )
  let cancelled = @test.expect_error(() => {
    parser.parse_bytes(
      b"ab",
      options=ParseOptions::progress(state => state.current_byte_offset >= 1),
    )
  })
  assert_true(cancelled is Cancelled(_))

  parser.set_language(parser_smoke_language())
  let restarted = @test.expect_error(() => {
    parser.parse_bytes(
      b"a",
      options=ParseOptions::progress(state => state.current_byte_offset == 0),
    )
  })
  match restarted {
    Cancelled(state) => assert_eq(state.current_byte_offset, 0)
    _ => fail("expected fresh parse cancellation")
  }
}

///|
test "parser progress state reports recovered lex errors" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let saw_error_state = [false]
  let tree = parser.parse_bytes(
    b"xa",
    options=ParseOptions::progress(state => {
      if state.current_byte_offset == 1 && state.has_error {
        saw_error_state[0] = true
      }
      false
    }),
  )
  assert_eq(tree.to_sexp(), "(document (UNEXPECTED 'x'))")
  assert_true(saw_error_state[0])
}

///|
test "parser progress state reports missing-token recovery" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let result = @test.expect_error(() => {
    parser.parse_bytes(
      b"",
      options=ParseOptions::progress(state => state.has_error),
    )
  })
  match result {
    Cancelled(state) => {
      assert_eq(state.current_byte_offset, 0)
      assert_true(state.has_error)
    }
    _ => fail("expected progress callback cancellation after recovery")
  }
}

///|
test "parser parses custom decoded input" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let input = Input::from_custom_bytes(Bytes::from_array([b'\xFE']), (
    _bytes,
    _offset,
  ) => InputDecodeResult::CodePoint(97, bytes=1))
  let tree = parser.parse(input)
  assert_eq(tree.to_sexp(), "(document)")
  let child = tree.root_node().child(0)
  assert_eq(child.type_(), "a")
  assert_eq(child.start_byte(), 0)
  assert_eq(child.end_byte(), 1)
}

///|
test "parser maps custom decode error to sentinel token" {
  let parser = Parser::new()
  parser.set_language(invalid_utf8_language())
  let input = Input::from_custom_bytes(Bytes::from_array([b'\xFE']), (
    _bytes,
    _offset,
  ) => InputDecodeResult::DecodeError)
  let tree = parser.parse(input)
  assert_eq(tree.to_sexp(), "(document)")
  let child = tree.root_node().child(0)
  assert_eq(child.type_(), "invalid_utf8")
  assert_eq(child.start_byte(), 0)
  assert_eq(child.end_byte(), 1)
}

///|
test "parser maps custom negative code point to decode error sentinel" {
  let parser = Parser::new()
  parser.set_language(invalid_utf8_language())
  let input = Input::from_custom_bytes(Bytes::from_array([b'\xFE']), (
    _bytes,
    _offset,
  ) => InputDecodeResult::CodePoint(-1, bytes=0))
  let tree = parser.parse(input)
  assert_eq(tree.to_sexp(), "(document)")
  let child = tree.root_node().child(0)
  assert_eq(child.type_(), "invalid_utf8")
  assert_eq(child.start_byte(), 0)
  assert_eq(child.end_byte(), 1)
}

///|
test "parser advances custom Input callback point by consumed bytes" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let offsets : Array[UInt] = []
  let columns : Array[UInt] = []
  let input = Input::from_custom_callback(
    (byte, point) => {
      offsets.push(byte)
      columns.push(point.column)
      if byte == 0 {
        InputChunk::from_bytes(Bytes::from_array([b'\x01', b'\x02']))
      } else {
        InputChunk::eof()
      }
    },
    (_bytes, _offset) => InputDecodeResult::CodePoint(97, bytes=2),
  )
  let tree = parser.parse(input)
  assert_eq(tree.to_sexp(), "(document)")
  assert_true(offsets == [0, 2])
  assert_true(columns == [0, 2])
  assert_eq(tree.root_node().child(0).end_byte(), 2)
}

///|
test "parser passes absolute offsets to custom decoder across chunks" {
  let parser = Parser::new()
  parser.set_language(
    scalar_pair_language("custom_decoder_offsets", "a", 97, "b", 98),
  )
  let read_offsets : Array[UInt] = []
  let decode_offsets : Array[Int] = []
  let input = Input::from_custom_callback(
    (byte, _point) => {
      read_offsets.push(byte)
      if byte == 0 {
        InputChunk::from_bytes(Bytes::from_array([b'\x01']))
      } else if byte == 1 {
        InputChunk::from_bytes(Bytes::from_array([b'\x02']))
      } else {
        InputChunk::eof()
      }
    },
    (_bytes, offset) => {
      decode_offsets.push(offset)
      if offset == 0 {
        InputDecodeResult::CodePoint(97, bytes=1)
      } else {
        InputDecodeResult::CodePoint(98, bytes=1)
      }
    },
  )
  let tree = parser.parse(input)
  assert_eq(tree.to_sexp(), "(document)")
  assert_true(read_offsets == [0, 1, 2])
  assert_true(decode_offsets.length() >= 4)
  assert_eq(decode_offsets[0], 0)
  assert_eq(decode_offsets[1], 1)
  let mut saw_lex_offset_0 = false
  let mut saw_lex_offset_1 = false
  for i in 2..<decode_offsets.length() {
    assert_true(decode_offsets[i] == 0 || decode_offsets[i] == 1)
    if decode_offsets[i] == 0 {
      saw_lex_offset_0 = true
    }
    if decode_offsets[i] == 1 {
      saw_lex_offset_1 = true
    }
  }
  assert_true(saw_lex_offset_0)
  assert_true(saw_lex_offset_1)
}

///|
test "parser rejects custom Input without decoder" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let input = Input::from_bytes(b"a", encoding=Custom)
  let result = @test.expect_error(() => parser.parse(input))
  match result {
    InvalidInputDecode(
      byte_offset=0,
      reason="custom input requires decode callback"
    ) => ()
    _ => fail("expected InvalidInputDecode")
  }
}

///|
test "parser rejects custom callback without decoder before reading" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let offsets : Array[UInt] = []
  let input = Input::from_callback(
    (byte, _point) => {
      offsets.push(byte)
      InputChunk::from_bytes(b"a")
    },
    encoding=Custom,
  )
  let result = @test.expect_error(() => parser.parse(input))
  match result {
    InvalidInputDecode(
      byte_offset=0,
      reason="custom input requires decode callback"
    ) => ()
    _ => fail("expected InvalidInputDecode")
  }
  assert_eq(offsets.length(), 0)
}

///|
test "parser validates custom decode consumed byte count" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let input = Input::from_custom_bytes(b"a", (_bytes, _offset) => {
    InputDecodeResult::CodePoint(97, bytes=0)
  })
  let result = @test.expect_error(() => parser.parse(input))
  match result {
    InvalidInputDecode(byte_offset=0, reason="custom decode must consume bytes") =>
      ()
    _ => fail("expected InvalidInputDecode")
  }
}

///|
test "parser validates custom decode consumed input bounds" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let input = Input::from_custom_bytes(b"a", (_bytes, _offset) => {
    InputDecodeResult::CodePoint(97, bytes=2)
  })
  let result = @test.expect_error(() => parser.parse(input))
  match result {
    InvalidInputDecode(
      byte_offset=0,
      reason="custom decode consumed past input"
    ) => ()
    _ => fail("expected InvalidInputDecode")
  }
}

///|
test "parser validates custom decode consumed chunk bounds" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let input = Input::from_custom_callback(
    (byte, _point) => {
      if byte == 0 {
        InputChunk::from_bytes(b"a")
      } else if byte == 1 {
        InputChunk::from_bytes(b"b")
      } else {
        InputChunk::eof()
      }
    },
    (bytes, offset) => {
      if bytes.length() == 1 || offset > 0 {
        InputDecodeResult::CodePoint(97, bytes=1)
      } else {
        InputDecodeResult::CodePoint(97, bytes=2)
      }
    },
  )
  let result = @test.expect_error(() => parser.parse(input))
  match result {
    InvalidInputDecode(
      byte_offset=0,
      reason="custom decode consumed past chunk"
    ) => ()
    _ => fail("expected InvalidInputDecode")
  }
}

///|
test "parser validates custom decode code point range" {
  let parser = Parser::new()
  parser.set_language(parser_smoke_language())
  let input = Input::from_custom_bytes(b"a", (_bytes, _offset) => {
    InputDecodeResult::CodePoint(0x110000, bytes=1)
  })
  let result = @test.expect_error(() => parser.parse(input))
  match result {
    InvalidInputDecode(
      byte_offset=0,
      reason="custom decode code point out of range"
    ) => ()
    _ => fail("expected InvalidInputDecode")
  }
}

///|
test "parser handles blank start rule" {
  let parser = Parser::new()
  let language = generated_language_from(
    (
      #|{
      #|  "name": "blank_start",
      #|  "rules": {
      #|    "document": { "type": "BLANK" }
      #|  }
      #|}
    ),
  )
  assert_true(language.symbol_name(@api.SymbolId::new(0)) == Some("end"))
  parser.set_language(language)
  let tree = parser.parse_bytes(b"")
  assert_eq(tree.to_sexp(), "(document)")
  let root = tree.root_node()
  assert_eq(root.start_byte(), 0)
  assert_eq(root.end_byte(), 0)
  assert_eq(root.child_count(), 0)
}

///|
test "parser handles token start rule" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "token_start",
        #|  "rules": {
        #|    "document": {
        #|      "type": "TOKEN",
        #|      "content": { "type": "STRING", "value": "tok" }
        #|    }
        #|  }
        #|}
      ),
    ),
  )
  let tree = parser.parse_bytes(b"tok")
  assert_eq(tree.to_sexp(), "(document)")
  let root = tree.root_node()
  assert_eq(root.start_byte(), 0)
  assert_eq(root.end_byte(), 3)
  assert_eq(root.child_count(), 0)
}

///|
test "parser honors immediate token boundaries" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "immediate_tokens",
        #|  "rules": {
        #|    "document": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "STRING", "value": "a" },
        #|        {
        #|          "type": "IMMEDIATE_TOKEN",
        #|          "content": { "type": "STRING", "value": "b" }
        #|        }
        #|      ]
        #|    }
        #|  },
        #|  "extras": [{ "type": "STRING", "value": " " }]
        #|}
      ),
    ),
  )
  let tree = parser.parse_bytes(b"ab")
  assert_eq(tree.root_node().type_(), "document")
  assert_eq(tree.root_node().start_byte(), 0)
  assert_eq(tree.root_node().end_byte(), 2)

  let result = @test.expect_error(() => parser.parse_bytes(b"a b"))
  assert_true(result is LexError(byte_offset=1, ..))
}

///|
test "parser keeps terminal extras outside reduce child counts" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "terminal_extras",
        #|  "rules": {
        #|    "document": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "STRING", "value": "a" },
        #|        { "type": "STRING", "value": "b" }
        #|      ]
        #|    },
        #|    "comment": { "type": "STRING", "value": "!" }
        #|  },
        #|  "extras": [{ "type": "SYMBOL", "name": "comment" }]
        #|}
      ),
    ),
  )

  let between = parser.parse_bytes(b"a!b")
  assert_eq(between.to_sexp(), "(document (comment))")
  let between_root = between.root_node()
  assert_eq(between_root.child_count(), 3)
  assert_eq(between_root.named_child_count(), 1)
  let between_comment = between_root.named_child(0)
  assert_eq(between_comment.type_(), "comment")
  assert_true(between_comment.is_extra())
  assert_eq(between_comment.start_byte(), 1)
  assert_eq(between_comment.end_byte(), 2)
  assert_eq(between_comment.parent().type_(), "document")

  let trailing = parser.parse_bytes(b"ab!")
  assert_eq(trailing.to_sexp(), "(document (comment))")
  assert_eq(trailing.root_node().end_byte(), 3)
  assert_true(trailing.root_node().named_child(0).is_extra())
}

///|
test "parser omits inlined named helper rules" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "inline_rules",
        #|  "rules": {
        #|    "document": { "type": "SYMBOL", "name": "item" },
        #|    "item": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "STRING", "value": "a" },
        #|        { "type": "STRING", "value": "b" }
        #|      ]
        #|    }
        #|  },
        #|  "inline": ["item"]
        #|}
      ),
    ),
  )
  let tree = parser.parse_bytes(b"ab")
  assert_eq(tree.to_sexp(), "(document)")
  let root = tree.root_node()
  assert_eq(root.child_count(), 2)
  assert_eq(root.named_child_count(), 0)
}

///|
test "parser generated repeat1 accepts multiple items" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "repeat1_items",
        #|  "rules": {
        #|    "document": {
        #|      "type": "REPEAT1",
        #|      "content": { "type": "SYMBOL", "name": "item" }
        #|    },
        #|    "item": { "type": "STRING", "value": "a" }
        #|  }
        #|}
      ),
    ),
  )

  let tree = parser.parse_bytes(b"aa")
  assert_eq(tree.to_sexp(), "(document (item) (item))")
}

///|
test "parser inserts missing token before unlexable next sibling" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "next_sibling_from_zwt",
        #|  "rules": {
        #|    "source": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "STRING", "value": "a" },
        #|        { "type": "SYMBOL", "name": "_bc" },
        #|        { "type": "STRING", "value": "d" },
        #|        { "type": "STRING", "value": "e" },
        #|        { "type": "STRING", "value": "f" }
        #|      ]
        #|    },
        #|    "_bc": {
        #|      "type": "SEQ",
        #|      "members": [
        #|        { "type": "STRING", "value": "b" },
        #|        { "type": "STRING", "value": "c" }
        #|      ]
        #|    }
        #|  },
        #|  "extras": [{ "type": "PATTERN", "value": "\\s|\\\\\\r?\\n" }]
        #|}
      ),
    ),
  )

  let tree = parser.parse_bytes(b"abdef")
  assert_eq(tree.to_sexp(), "(source (MISSING \"c\"))")
}

///|
test "parser handles readme-style expression grammar" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "readme_grammar",
        #|  "rules": {
        #|    "expression": {
        #|      "type": "CHOICE",
        #|      "members": [
        #|        { "type": "SYMBOL", "name": "sum" },
        #|        { "type": "SYMBOL", "name": "product" },
        #|        { "type": "SYMBOL", "name": "number" },
        #|        { "type": "SYMBOL", "name": "variable" },
        #|        {
        #|          "type": "SEQ",
        #|          "members": [
        #|            { "type": "STRING", "value": "(" },
        #|            { "type": "SYMBOL", "name": "expression" },
        #|            { "type": "STRING", "value": ")" }
        #|          ]
        #|        }
        #|      ]
        #|    },
        #|    "sum": {
        #|      "type": "PREC_LEFT",
        #|      "value": 1,
        #|      "content": {
        #|        "type": "SEQ",
        #|        "members": [
        #|          { "type": "SYMBOL", "name": "expression" },
        #|          { "type": "STRING", "value": "+" },
        #|          { "type": "SYMBOL", "name": "expression" }
        #|        ]
        #|      }
        #|    },
        #|    "product": {
        #|      "type": "PREC_LEFT",
        #|      "value": 2,
        #|      "content": {
        #|        "type": "SEQ",
        #|        "members": [
        #|          { "type": "SYMBOL", "name": "expression" },
        #|          { "type": "STRING", "value": "*" },
        #|          { "type": "SYMBOL", "name": "expression" }
        #|        ]
        #|      }
        #|    },
        #|    "number": { "type": "PATTERN", "value": "\\d+" },
        #|    "comment": { "type": "PATTERN", "value": "#.*" },
        #|    "variable": { "type": "PATTERN", "value": "[a-z]\\w*", "flags": "i" }
        #|  },
        #|  "extras": [
        #|    { "type": "PATTERN", "value": "\\s" },
        #|    { "type": "SYMBOL", "name": "comment" }
        #|  ]
        #|}
      ),
    ),
  )
  assert_eq(
    parser.parse_string("a + b * c").to_sexp(),
    (
      #|(expression (sum (expression (variable)) (expression (product (expression (variable)) (expression (variable))))))
    ),
  )
}

///|
test "parser applies named aliases in root productions" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "aliases_in_root",
        #|  "rules": {
        #|    "document": {
        #|      "type": "ALIAS",
        #|      "content": { "type": "STRING", "value": "a" },
        #|      "value": "letter",
        #|      "named": true
        #|    }
        #|  }
        #|}
      ),
    ),
  )
  let tree = parser.parse_bytes(b"a")
  assert_eq(tree.to_sexp(), "(document (letter))")
  let child = tree.root_node().child(0)
  assert_eq(child.type_(), "letter")
  assert_eq(child.grammar_type(), "a")
  assert_true(child.language().symbol_name(child.symbol()) == Some("letter"))
  assert_true(child.language().symbol_name(child.grammar_symbol()) == Some("a"))
  assert_true(child.symbol() != child.grammar_symbol())
  assert_true(child.is_named())
}

///|
test "parser applies anonymous aliases to named rules" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "named_rule_aliased_as_anonymous",
        #|  "rules": {
        #|    "document": {
        #|      "type": "ALIAS",
        #|      "content": { "type": "SYMBOL", "name": "item" },
        #|      "value": "anonymous_item",
        #|      "named": false
        #|    },
        #|    "item": { "type": "STRING", "value": "a" }
        #|  }
        #|}
      ),
    ),
  )
  let tree = parser.parse_bytes(b"a")
  assert_eq(tree.to_sexp(), "(document)")
  let root = tree.root_node()
  assert_eq(root.child_count(), 1)
  assert_eq(root.named_child_count(), 0)
  let child = root.child(0)
  assert_eq(child.type_(), "anonymous_item")
  assert_eq(child.grammar_type(), "item")
  assert_true(
    child.language().symbol_name(child.symbol()) == Some("anonymous_item"),
  )
  assert_true(
    child.language().symbol_name(child.grammar_symbol()) == Some("item"),
  )
  assert_true(child.symbol() != child.grammar_symbol())
  assert_true(!child.is_named())
}

///|
test "parser treats anonymous ERROR token as ordinary token" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "anonymous_error",
        #|  "rules": {
        #|    "document": { "type": "STRING", "value": "ERROR" }
        #|  }
        #|}
      ),
    ),
  )
  guard parser.language() is Some(language) else {
    fail("language should be set")
  }
  assert_true(language.symbol_for_name("ERROR", is_named=false) is Some(_))
  let tree = parser.parse_bytes(b"ERROR")
  assert_eq(tree.to_sexp(), "(document)")
  let token = tree.root_node().child(0)
  assert_eq(token.type_(), "ERROR")
  assert_true(!token.is_named())
  assert_true(!token.is_error())
  assert_true(!tree.root_node().has_error())
}

///|
test "parser rejects exact reserved word in word-token context" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "reserved_words_minimal",
        #|  "word": "identifier",
        #|  "rules": {
        #|    "document": {
        #|      "type": "RESERVED",
        #|      "context_name": "global",
        #|      "content": { "type": "SYMBOL", "name": "identifier" }
        #|    },
        #|    "identifier": { "type": "PATTERN", "value": "[a-z]+" },
        #|    "keyword": { "type": "STRING", "value": "if" }
        #|  },
        #|  "reserved": {
        #|    "global": [{ "type": "SYMBOL", "name": "keyword" }]
        #|  }
        #|}
      ),
    ),
  )
  assert_eq(parser.parse_bytes(b"abc").to_sexp(), "(document (identifier))")
  assert_eq(parser.parse_bytes(b"ifx").to_sexp(), "(document (identifier))")

  let result = @test.expect_error(() => parser.parse_bytes(b"if"))
  assert_true(result is ParseTableError(_))
}

///|
test "parser falls back unreserved keyword candidate to word token" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "unreserved_keyword_fallback",
        #|  "word": "identifier",
        #|  "rules": {
        #|    "document": { "type": "SYMBOL", "name": "identifier" },
        #|    "identifier": { "type": "PATTERN", "value": "[a-z]+" },
        #|    "keyword": { "type": "STRING", "value": "if" }
        #|  },
        #|  "reserved": {
        #|    "none": [],
        #|    "global": [{ "type": "SYMBOL", "name": "keyword" }]
        #|  }
        #|}
      ),
    ),
  )

  let tree = parser.parse_bytes(b"if")
  assert_eq(tree.to_sexp(), "(document (identifier))")
  let identifier = tree.root_node().named_child(0)
  assert_eq(identifier.type_(), "identifier")
  assert_eq(identifier.start_byte(), 0)
  assert_eq(identifier.end_byte(), 2)
}

///|
test "parser replaces word capture with keyword accepted by current state" {
  let parser = Parser::new()
  parser.set_language(
    generated_language_from(
      (
        #|{
        #|  "name": "keyword_action_fallback",
        #|  "word": "identifier",
        #|  "rules": {
        #|    "document": {
        #|      "type": "CHOICE",
        #|      "members": [
        #|        { "type": "SYMBOL", "name": "keyword" },
        #|        { "type": "SYMBOL", "name": "identifier" }
        #|      ]
        #|    },
        #|    "identifier": { "type": "PATTERN", "value": "[a-z]+" },
        #|    "keyword": { "type": "STRING", "value": "if" }
        #|  }
        #|}
      ),
    ),
  )

  assert_eq(parser.parse_bytes(b"if").to_sexp(), "(document (keyword))")
  assert_eq(parser.parse_bytes(b"iff").to_sexp(), "(document (identifier))")
}
