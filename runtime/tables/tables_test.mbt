///|
test "validates minimal ABI 15 tables" {
  let tables = GeneratedLanguageTables::new(name="fixture")
  let validated = validate(tables)
  assert_eq(validated.abi_version(), target_abi_version())
  assert_eq(validated.name(), "fixture")
}

///|
test "validates symbol and field metadata shape" {
  let tables = GeneratedLanguageTables::new(
    name="fixture",
    symbol_count=1,
    field_count=1,
    symbol_names=["document"],
    symbol_types=[@api.SymbolType::Regular],
    field_names=["", "body"],
  )
  let validated = validate(tables)
  assert_true(validated.symbol_name(@api.SymbolId::new(0)) == Some("document"))
  assert_true(
    validated.symbol_type(@api.SymbolId::new(0)) ==
    Some(@api.SymbolType::Regular),
  )
  assert_true(validated.field_name_for_id(@api.FieldId::new(1)) == Some("body"))
  assert_true(validated.field_id_for_name("body") == Some(@api.FieldId::new(1)))
}

///|
test "validates public symbol map and appended alias symbols" {
  let tables = GeneratedLanguageTables::new(
    name="aliases",
    symbol_count=2,
    alias_count=1,
    symbol_names=["end", "a"],
    symbol_types=[@api.SymbolType::Regular, @api.SymbolType::Anonymous],
    public_symbol_map=[0, 2],
    alias_symbols=[GeneratedAlias::new(value="leaf", named=true)],
    non_terminal_aliases=[
      GeneratedNonTerminalAliasEntry::new(symbol_id=1, public_symbol_id=2, alias_symbol_ids=[
        2,
      ]),
    ],
  )
  let validated = validate(tables)
  assert_eq(validated.public_symbol_count(), 3)
  assert_true(validated.symbol_name(@api.SymbolId::new(1)) == Some("a"))
  assert_true(validated.symbol_name(@api.SymbolId::new(2)) == Some("leaf"))
  assert_true(
    validated.symbol_type(@api.SymbolId::new(2)) ==
    Some(@api.SymbolType::Regular),
  )
  assert_true(
    validated.public_symbol_for_grammar_symbol(@api.SymbolId::new(1)) ==
    Some(@api.SymbolId::new(2)),
  )
  assert_true(
    validated.public_symbol_for_alias(
      GeneratedAlias::new(value="leaf", named=true),
    ) ==
    Some(@api.SymbolId::new(2)),
  )
}

///|
test "validates supertype metadata map" {
  let tables = GeneratedLanguageTables::new(
    name="supertypes",
    symbol_count=3,
    supertype_count=1,
    symbol_names=["expr", "identifier", "+"],
    symbol_types=[
      @api.SymbolType::Supertype,
      @api.SymbolType::Regular,
      @api.SymbolType::Anonymous,
    ],
    supertype_entries=[
      GeneratedSupertypeEntry::new(symbol_id=0, subtype_symbol_ids=[1, 2]),
    ],
  )
  let validated = validate(tables)
  assert_true(validated.supertypes() == [@api.SymbolId::new(0)])
  assert_true(
    validated.subtypes(@api.SymbolId::new(0)) ==
    [@api.SymbolId::new(1), @api.SymbolId::new(2)],
  )
  assert_eq(validated.subtypes(@api.SymbolId::new(2)).length(), 0)
}

///|
test "validates lex mode rows" {
  let tables = GeneratedLanguageTables::new(
    name="lex",
    state_count=2,
    main_lex_state_count=1,
    external_lex_state_count=2,
    reserved_word_set_count=2,
    max_reserved_word_set_size=1,
    lex_modes=[
      GeneratedLexMode::new(
        lex_state=0,
        external_lex_state=1,
        reserved_word_set_id=1,
      ),
      GeneratedLexMode::new(),
    ],
    primary_state_ids=[0, 1],
    large_state_count=2,
    large_parse_table=[[], []],
    main_lex_tables=[GeneratedLexTable::new(states=[GeneratedLexState::new()])],
    reserved_word_sets=[GeneratedTokenSet::new(), GeneratedTokenSet::new()],
    external_lex_states=[
      GeneratedExternalLexState::new(),
      GeneratedExternalLexState::new(),
    ],
  )
  let validated = validate(tables)
  assert_eq(validated.main_lex_state_count(), 1)
  assert_eq(validated.external_lex_state_count(), 2)
  assert_eq(validated.reserved_word_set_count(), 2)
  assert_eq(validated.max_reserved_word_set_size(), 1)
  assert_true(
    validated.lex_mode(@api.StateId::new(0)) ==
    Some(
      GeneratedLexMode::new(
        lex_state=0,
        external_lex_state=1,
        reserved_word_set_id=1,
      ),
    ),
  )
  assert_true(validated.lex_mode(@api.StateId::new(2)) is None)
  assert_true(
    validated.primary_state_id(@api.StateId::new(1)) ==
    Some(@api.StateId::new(1)),
  )
  assert_true(validated.primary_state_id(@api.StateId::new(2)) is None)
}

///|
test "validates decode error character range" {
  let tables = GeneratedLanguageTables::new(
    name="decode_error_range",
    main_lex_state_count=1,
    main_lex_tables=[
      GeneratedLexTable::new(states=[
        GeneratedLexState::new(transitions=[
          GeneratedLexTransition::new(target_state=0, ranges=[
            GeneratedCharacterRange::new(start=-1, end=-1),
          ]),
        ]),
      ]),
    ],
  )
  let _ = validate(tables)
}

///|
test "rejects mixed decode error character range" {
  let tables = GeneratedLanguageTables::new(
    name="bad_decode_error_range",
    main_lex_state_count=1,
    main_lex_tables=[
      GeneratedLexTable::new(states=[
        GeneratedLexState::new(transitions=[
          GeneratedLexTransition::new(target_state=0, ranges=[
            GeneratedCharacterRange::new(start=-1, end=0),
          ]),
        ]),
      ]),
    ],
  )
  let result = @test.expect_error(() => validate(tables))
  match result {
    InvalidId(
      field="main_lex_tables[0].states[0].transitions[0].ranges[0].start",
      value=-1,
      min=0,
      max=1114111
    ) => ()
    _ => fail("expected mixed decode error range diagnostic")
  }
}

///|
test "validates parse action lists" {
  let tables = GeneratedLanguageTables::new(
    name="actions",
    symbol_count=1,
    state_count=1,
    symbol_names=["document"],
    symbol_types=[@api.SymbolType::Regular],
    lex_modes=[GeneratedLexMode::new()],
    primary_state_ids=[0],
    parse_action_lists=[
      GeneratedParseActionList::new(actions=[
        GeneratedParseAction::Accept,
        GeneratedParseAction::Recover,
        GeneratedParseAction::Shift(state_id=0, is_repetition=false),
        GeneratedParseAction::ShiftExtra,
        GeneratedParseAction::Reduce(
          symbol_id=0,
          child_count=1,
          dynamic_precedence=0,
          production_id=0,
        ),
      ]),
    ],
    large_state_count=1,
    large_parse_table=[[GeneratedParseTableCell::EmptyCell]],
  )
  let validated = validate(tables)
  assert_eq(validated.parse_action_list_count(), 1)
  assert_true(validated.parse_action_list(1) is None)
  assert_true(
    validated.parse_action_list(0) ==
    Some(
      GeneratedParseActionList::new(actions=[
        GeneratedParseAction::Accept,
        GeneratedParseAction::Recover,
        GeneratedParseAction::Shift(state_id=0, is_repetition=false),
        GeneratedParseAction::ShiftExtra,
        GeneratedParseAction::Reduce(
          symbol_id=0,
          child_count=1,
          dynamic_precedence=0,
          production_id=0,
        ),
      ]),
    ),
  )
}

///|
test "external scanner token clamps marked end before skipped input" {
  let context = ExternalScannerContext::new(
    input=b"xy",
    byte_offset=0,
    point=@api.Point::zero(),
    valid_symbols=[true],
    advance_steps=[
      ExternalScannerAdvanceStep::new(byte_width=1, codepoint=120),
      ExternalScannerAdvanceStep::new(byte_width=1, codepoint=121),
    ],
  )
  context.advance()
  context.mark_end()
  context.advance(skip=true)

  assert_eq(context.current_byte(), 2)
  assert_true(context.current_point() == @api.Point::new(row=0, column=2))
  match context.token(external_token_id=0) {
    TokenRange(
      external_token_id=0,
      start_byte=1,
      end_byte=1,
      start_point~,
      end_point~,
      state_changed=false
    ) => {
      assert_true(start_point == @api.Point::new(row=0, column=1))
      assert_true(end_point == @api.Point::new(row=0, column=1))
    }
    _ => fail("expected token range clamped to marked end")
  }
}

///|
test "external scanner mark_end at included range start backs up to previous range end" {
  let context = ExternalScannerContext::new(
    input=b"x--y",
    byte_offset=3,
    point=@api.Point::new(row=0, column=3),
    valid_symbols=[true],
    is_at_included_range_start=true,
    previous_included_range_end_byte=Some(1),
    previous_included_range_end_point=Some(@api.Point::new(row=0, column=1)),
  )
  context.mark_end()

  match context.token(external_token_id=0) {
    TokenRange(
      external_token_id=0,
      start_byte=1,
      end_byte=1,
      start_point~,
      end_point~,
      state_changed=false
    ) => {
      assert_true(start_point == @api.Point::new(row=0, column=1))
      assert_true(end_point == @api.Point::new(row=0, column=1))
    }
    _ => fail("expected mark_end to use previous included range end")
  }
}

///|
test "external scanner context updates range start and eof after advance" {
  let context = ExternalScannerContext::new(
    input=b"x",
    byte_offset=0,
    point=@api.Point::zero(),
    valid_symbols=[true],
    is_at_included_range_start=true,
    advance_steps=[ExternalScannerAdvanceStep::new(byte_width=1, codepoint=120)],
  )
  assert_true(context.is_at_included_range_start())
  assert_true(!context.eof())

  context.advance()

  assert_true(!context.is_at_included_range_start())
  assert_true(context.eof())
}

///|
test "validates keyword capture and lex table metadata" {
  let keyword_table = GeneratedLexTable::new(states=[
    GeneratedLexState::new(accept_symbol_id=Some(1)),
  ])
  let tables = GeneratedLanguageTables::new(
    name="keywords",
    symbol_count=2,
    keyword_capture_token=Some(1),
    symbol_names=["end", "identifier"],
    symbol_types=[@api.SymbolType::Regular, @api.SymbolType::Regular],
    keyword_lex_table=Some(keyword_table),
  )
  let validated = validate(tables)
  assert_true(validated.keyword_capture_token() == Some(@api.SymbolId::new(1)))
  assert_true(validated.keyword_lex_table() == Some(keyword_table))
}

///|
test "validates parse table layout" {
  let tables = GeneratedLanguageTables::new(
    name="layout",
    symbol_count=2,
    state_count=2,
    symbol_names=["end", "document"],
    symbol_types=[@api.SymbolType::Regular, @api.SymbolType::Regular],
    lex_modes=[GeneratedLexMode::new(), GeneratedLexMode::new()],
    primary_state_ids=[0, 1],
    parse_action_lists=[
      GeneratedParseActionList::new(),
      GeneratedParseActionList::new(actions=[GeneratedParseAction::Accept]),
    ],
    large_state_count=1,
    large_parse_table=[
      [
        GeneratedParseTableCell::EmptyCell,
        GeneratedParseTableCell::ActionCell(1),
      ],
    ],
    small_parse_table_map=[0],
    small_parse_table=[
      GeneratedSmallParseTableRow::new(state_id=1, offset=0, sections=[
        GeneratedSmallParseTableSection::new(
          kind=GeneratedSmallParseTableSectionKind::SmallAction,
          value=1,
          symbols=[0],
        ),
        GeneratedSmallParseTableSection::new(
          kind=GeneratedSmallParseTableSectionKind::SmallState,
          value=1,
          symbols=[1],
        ),
      ]),
    ],
  )
  let validated = validate(tables)
  assert_eq(validated.large_state_count(), 1)
  assert_true(
    validated.large_parse_table_cell(
      @api.StateId::new(0),
      @api.SymbolId::new(1),
    ) ==
    Some(GeneratedParseTableCell::ActionCell(1)),
  )
  assert_true(
    validated.large_parse_table_cell(
      @api.StateId::new(1),
      @api.SymbolId::new(0),
    )
    is None,
  )
  assert_true(
    validated.parse_table_cell(@api.StateId::new(0), @api.SymbolId::new(1)) ==
    Some(GeneratedParseTableCell::ActionCell(1)),
  )
  assert_true(
    validated.parse_action_list_for_symbol(
      @api.StateId::new(0),
      @api.SymbolId::new(1),
    ) ==
    Some(GeneratedParseActionList::new(actions=[GeneratedParseAction::Accept])),
  )
  assert_true(validated.small_parse_table_offset(0) == Some(0))
  assert_true(validated.small_parse_table_row(0) is Some(_))
  assert_true(
    validated.parse_table_cell(@api.StateId::new(1), @api.SymbolId::new(0)) ==
    Some(GeneratedParseTableCell::ActionCell(1)),
  )
  assert_true(
    validated.parse_action_list_for_symbol(
      @api.StateId::new(1),
      @api.SymbolId::new(0),
    ) ==
    Some(GeneratedParseActionList::new(actions=[GeneratedParseAction::Accept])),
  )
  assert_true(
    validated.parse_table_cell(@api.StateId::new(1), @api.SymbolId::new(1)) ==
    Some(GeneratedParseTableCell::StateCell(1)),
  )
  assert_true(
    validated.goto_state_for_symbol(@api.StateId::new(1), @api.SymbolId::new(1)) ==
    Some(@api.StateId::new(1)),
  )
  assert_true(
    validated.parse_table_cell(@api.StateId::new(2), @api.SymbolId::new(0))
    is None,
  )
  assert_true(
    validated.parse_action_list_for_symbol(
      @api.StateId::new(1),
      @api.SymbolId::new(1),
    )
    is None,
  )
  assert_true(
    validated.goto_state_for_symbol(@api.StateId::new(1), @api.SymbolId::new(0))
    is None,
  )
}

///|
test "validates reserved and external token set rows" {
  let tables = GeneratedLanguageTables::new(
    name="token_rows",
    symbol_count=2,
    external_token_count=1,
    reserved_word_set_count=2,
    external_lex_state_count=2,
    max_reserved_word_set_size=1,
    symbol_names=["end", "keyword"],
    symbol_types=[@api.SymbolType::Regular, @api.SymbolType::Regular],
    reserved_word_sets=[
      GeneratedTokenSet::new(),
      GeneratedTokenSet::new(symbol_ids=[1]),
    ],
    external_lex_states=[
      GeneratedExternalLexState::new(),
      GeneratedExternalLexState::new(external_token_ids=[0]),
    ],
    external_scanner=ExternalScannerDescriptor::new(
      external_token_count=1,
      external_state_count=2,
      states=[[false], [true]],
      symbol_map=[1],
    ),
  )
  let validated = validate(tables)
  assert_true(
    validated.reserved_word_set(1) ==
    Some(GeneratedTokenSet::new(symbol_ids=[1])),
  )
  assert_true(
    validated.external_lex_state(1) ==
    Some(GeneratedExternalLexState::new(external_token_ids=[0])),
  )
  let scanner = validated.external_scanner()
  assert_true(scanner.state_enabled(1, 0) == Some(true))
  assert_true(scanner.symbol_for_external_token(0) == Some(1))
}

///|
test "rejects non-native ABI versions" {
  let tables = GeneratedLanguageTables::new(name="old", abi_version=14)
  let result = @test.expect_error(() => validate(tables))
  match result {
    UnsupportedAbi(14) => ()
    _ => fail("expected unsupported ABI diagnostic")
  }
}

///|
test "rejects mismatched metadata lengths" {
  let tables = GeneratedLanguageTables::new(
    name="bad",
    symbol_count=1,
    symbol_names=[],
    symbol_types=[],
  )
  let result = @test.expect_error(() => validate(tables))
  match result {
    InvalidLength(field="symbol_names", expected=1, actual=0) => ()
    _ => fail("expected symbol_names length diagnostic")
  }
}

///|
test "rejects mismatched lex mode count" {
  let tables = GeneratedLanguageTables::new(name="bad", state_count=1)
  let result = @test.expect_error(() => validate(tables))
  match result {
    InvalidLength(field="lex_modes", expected=1, actual=0) => ()
    _ => fail("expected lex mode length diagnostic")
  }
}

///|
test "rejects out of range lex mode ids" {
  let tables = GeneratedLanguageTables::new(
    name="bad",
    state_count=1,
    lex_modes=[GeneratedLexMode::new(external_lex_state=1)],
    primary_state_ids=[0],
  )
  let result = @test.expect_error(() => validate(tables))
  match result {
    InvalidId(field="lex_modes[0].external_lex_state", value=1, min=0, max=0) =>
      ()
    _ => fail("expected external lex state id diagnostic")
  }
}

///|
test "rejects out of range primary state ids" {
  let tables = GeneratedLanguageTables::new(
    name="bad",
    state_count=1,
    lex_modes=[GeneratedLexMode::new()],
    primary_state_ids=[1],
  )
  let result = @test.expect_error(() => validate(tables))
  match result {
    InvalidId(field="primary_state_ids[0]", value=1, min=0, max=0) => ()
    _ => fail("expected primary state id diagnostic")
  }
}

///|
test "rejects out of range parse action ids" {
  let tables = GeneratedLanguageTables::new(
    name="bad",
    symbol_count=1,
    state_count=1,
    symbol_names=["document"],
    symbol_types=[@api.SymbolType::Regular],
    lex_modes=[GeneratedLexMode::new()],
    primary_state_ids=[0],
    parse_action_lists=[
      GeneratedParseActionList::new(actions=[
        GeneratedParseAction::Shift(state_id=1, is_repetition=false),
      ]),
    ],
  )
  let result = @test.expect_error(() => validate(tables))
  match result {
    InvalidId(
      field="parse_action_lists[0].actions[0].state_id",
      value=1,
      min=0,
      max=0
    ) => ()
    _ => fail("expected parse action state id diagnostic")
  }
}

///|
test "rejects compact parse rows that do not match layout map" {
  let tables = GeneratedLanguageTables::new(
    name="bad",
    symbol_count=1,
    state_count=2,
    symbol_names=["document"],
    symbol_types=[@api.SymbolType::Regular],
    lex_modes=[GeneratedLexMode::new(), GeneratedLexMode::new()],
    primary_state_ids=[0, 1],
    parse_action_lists=[
      GeneratedParseActionList::new(),
      GeneratedParseActionList::new(actions=[GeneratedParseAction::Accept]),
    ],
    large_state_count=1,
    large_parse_table=[[GeneratedParseTableCell::EmptyCell]],
    small_parse_table_map=[0],
    small_parse_table=[
      GeneratedSmallParseTableRow::new(state_id=0, offset=0, sections=[
        GeneratedSmallParseTableSection::new(
          kind=GeneratedSmallParseTableSectionKind::SmallAction,
          value=1,
          symbols=[0],
        ),
      ]),
    ],
  )
  let result = @test.expect_error(() => validate(tables))
  match result {
    InvalidId(field="small_parse_table[0].state_id", value=0, min=1, max=1) =>
      ()
    _ => fail("expected compact row state id diagnostic")
  }
}
