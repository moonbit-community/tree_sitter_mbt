///|
fn empty_parse_table_rows(
  row_count : Int,
  symbol_count : Int,
) -> Array[Array[@tables.GeneratedParseTableCell]] {
  let rows : Array[Array[@tables.GeneratedParseTableCell]] = []
  for _ in 0..<row_count {
    let row : Array[@tables.GeneratedParseTableCell] = []
    for _ in 0..<symbol_count {
      row.push(@tables.GeneratedParseTableCell::EmptyCell)
    }
    rows.push(row)
  }
  rows
}

///|
fn fixture_language() -> Language raise @tables.TableValidationError {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="fixture",
      symbol_count=5,
      token_count=2,
      state_count=4,
      field_count=2,
      symbol_names=["document", "item", ",", "comment", "alias_item"],
      symbol_types=[
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
        @api.SymbolType::Anonymous,
        @api.SymbolType::Regular,
        @api.SymbolType::Regular,
      ],
      field_names=["", "body", "separator"],
      lex_modes=[
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(),
        @tables.GeneratedLexMode::new(),
      ],
      primary_state_ids=[0, 1, 2, 3],
      large_state_count=4,
      large_parse_table=empty_parse_table_rows(4, 5),
    ),
  )
}

///|
fn wb_parser_smoke_language(dynamic_precedence? : Int = 0) -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="minimal_wb",
      symbol_count=3,
      token_count=2,
      state_count=4,
      production_id_count=1,
      main_lex_state_count=2,
      large_state_count=4,
      symbol_names=["end", "a", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
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
            symbol_id=2,
            child_count=1,
            dynamic_precedence~,
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
fn wb_decode_error_language() -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="decode_error_wb",
      symbol_count=3,
      token_count=2,
      state_count=4,
      production_id_count=1,
      main_lex_state_count=2,
      large_state_count=4,
      symbol_names=["end", "invalid_utf8", "document"],
      symbol_types=[
        @api.SymbolType::Regular,
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
              @tables.GeneratedCharacterRange::new(start=-1, end=-1),
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
fn wb_external_scanner_language(
  scanner : @tables.ExternalScannerDescriptor,
) -> Language raise {
  language_from_generated_tables(
    @tables.GeneratedLanguageTables::new(
      name="external_scan_wb",
      symbol_count=3,
      token_count=2,
      external_token_count=1,
      state_count=4,
      production_id_count=1,
      main_lex_state_count=1,
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
fn wb_external_scanner(
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
fn fixture_tree() -> Tree raise @tables.TableValidationError {
  let language = fixture_language()
  Tree::from_fixture(
    language,
    [
      NodeData::new(
        kind="document",
        symbol=@api.SymbolId::new(0),
        start_byte=0,
        end_byte=4,
        start_point=@api.Point::zero(),
        end_point=@api.Point::new(row=0, column=4),
        children=[1, 4, 5, 6, 7, 9],
        parse_state=Some(@api.StateId::new(1)),
        next_parse_state=Some(@api.StateId::new(2)),
      ),
      NodeData::new(
        kind="_hidden",
        symbol=@api.SymbolId::new(1),
        start_byte=0,
        end_byte=1,
        start_point=@api.Point::zero(),
        end_point=@api.Point::new(row=0, column=1),
        parent=0,
        children=[2, 3],
        field_id=@api.FieldId::new(1),
        visible=false,
        named=false,
      ),
      NodeData::new(
        kind="item",
        symbol=@api.SymbolId::new(1),
        start_byte=0,
        end_byte=1,
        start_point=@api.Point::zero(),
        end_point=@api.Point::new(row=0, column=1),
        parent=1,
        parse_state=Some(@api.StateId::new(2)),
        next_parse_state=Some(@api.StateId::new(3)),
      ),
      NodeData::new(
        kind="comment",
        symbol=@api.SymbolId::new(3),
        start_byte=1,
        end_byte=1,
        start_point=@api.Point::new(row=0, column=1),
        end_point=@api.Point::new(row=0, column=1),
        parent=1,
        named=false,
        extra=true,
      ),
      NodeData::new(
        kind=",",
        symbol=@api.SymbolId::new(2),
        start_byte=1,
        end_byte=2,
        start_point=@api.Point::new(row=0, column=1),
        end_point=@api.Point::new(row=0, column=2),
        parent=0,
        field_id=@api.FieldId::new(2),
        named=false,
      ),
      NodeData::new(
        kind="item",
        symbol=@api.SymbolId::new(1),
        start_byte=2,
        end_byte=3,
        start_point=@api.Point::new(row=0, column=2),
        end_point=@api.Point::new(row=0, column=3),
        parent=0,
        field_id=@api.FieldId::new(1),
        has_changes=true,
      ),
      NodeData::new(
        kind="item",
        symbol=@api.SymbolId::new(1),
        start_byte=3,
        end_byte=3,
        start_point=@api.Point::new(row=0, column=3),
        end_point=@api.Point::new(row=0, column=3),
        parent=0,
        field_id=@api.FieldId::new(1),
        missing=true,
        has_error=true,
      ),
      NodeData::new(
        kind="_alias_hidden",
        symbol=@api.SymbolId::new(1),
        start_byte=3,
        end_byte=4,
        start_point=@api.Point::new(row=0, column=3),
        end_point=@api.Point::new(row=0, column=4),
        parent=0,
        children=[8],
        field_id=@api.FieldId::new(1),
        visible=false,
        named=false,
      ),
      NodeData::new(
        kind="alias_item",
        symbol=@api.SymbolId::new(4),
        start_byte=3,
        end_byte=4,
        start_point=@api.Point::new(row=0, column=3),
        end_point=@api.Point::new(row=0, column=4),
        grammar_kind="item",
        grammar_symbol=@api.SymbolId::new(1),
        parent=7,
        visible=false,
        alias_visible=true,
      ),
      NodeData::new(
        kind="_empty",
        symbol=@api.SymbolId::new(1),
        start_byte=4,
        end_byte=4,
        start_point=@api.Point::new(row=0, column=4),
        end_point=@api.Point::new(row=0, column=4),
        parent=0,
        field_id=@api.FieldId::new(1),
        visible=false,
        named=false,
      ),
    ],
    included_ranges=[
      @api.Range::new(
        start_byte=0,
        end_byte=4,
        start_point=@api.Point::zero(),
        end_point=@api.Point::new(row=0, column=4),
      ),
    ],
  )
}

///|
test "manual tree fixture navigates public children and fields" {
  let tree = fixture_tree()
  let root = tree.root_node()
  assert_eq(root.type_(), "document")
  assert_eq(root.child_count(), 6)
  assert_eq(root.named_child_count(), 4)
  assert_true(root.field_name_for_child(0) == Some("body"))
  assert_true(root.field_name_for_child(1) is None)
  assert_true(root.field_name_for_child(2) == Some("separator"))
  assert_true(root.field_name_for_child(5) == Some("body"))
  assert_true(root.field_name_for_named_child(0) == Some("body"))
  assert_true(root.field_name_for_named_child(3) == Some("body"))
  assert_eq(root.child_by_field_name("body").type_(), "item")
  assert_true(root.child_by_field_name("missing_field").is_null())
  assert_eq(root.child(5).type_(), "alias_item")
  assert_eq(root.child(5).grammar_type(), "item")
}

///|
test "changed ranges notice external scanner metadata mismatch" {
  let language = fixture_language()
  let left = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      children=[1],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      parent=0,
      external_scanner_state=Some(b"a"),
      has_external_scanner_state_change=true,
      depends_on_column=true,
    ),
  ])
  let right = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      children=[1],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      parent=0,
      external_scanner_state=Some(b"b"),
      has_external_scanner_state_change=true,
      depends_on_column=true,
    ),
  ])
  assert_true(
    left.changed_ranges(right) ==
    [
      @api.Range::new(
        start_byte=0,
        end_byte=1,
        start_point=@api.Point::zero(),
        end_point=@api.Point::new(row=0, column=1),
      ),
    ],
  )
}

///|
test "changed ranges narrow metadata mismatch to public child" {
  let language = fixture_language()
  let left = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=3,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=3),
      children=[1, 2],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      parent=0,
      lookahead_byte_count=1,
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=2,
      end_byte=3,
      start_point=@api.Point::new(row=0, column=2),
      end_point=@api.Point::new(row=0, column=3),
      parent=0,
    ),
  ])
  let right = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=3,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=3),
      children=[1, 2],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      parent=0,
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=2,
      end_byte=3,
      start_point=@api.Point::new(row=0, column=2),
      end_point=@api.Point::new(row=0, column=3),
      parent=0,
    ),
  ])
  assert_true(
    left.changed_ranges(right) ==
    [
      @api.Range::new(
        start_byte=0,
        end_byte=1,
        start_point=@api.Point::zero(),
        end_point=@api.Point::new(row=0, column=1),
      ),
    ],
  )
}

///|
test "changed ranges report included range symmetric difference" {
  let language = fixture_language()
  let nodes = [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=10,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=10),
      children=[1],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=10,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=10),
      parent=0,
    ),
  ]
  let left = Tree::from_fixture(language, nodes, included_ranges=[
    @api.Range::new(
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
    ),
    @api.Range::new(
      start_byte=3,
      end_byte=4,
      start_point=@api.Point::new(row=0, column=3),
      end_point=@api.Point::new(row=0, column=4),
    ),
  ])
  let right = Tree::from_fixture(language, nodes, included_ranges=[
    @api.Range::new(
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
    ),
    @api.Range::new(
      start_byte=5,
      end_byte=6,
      start_point=@api.Point::new(row=0, column=5),
      end_point=@api.Point::new(row=0, column=6),
    ),
  ])
  assert_true(
    left.changed_ranges(right) ==
    [
      @api.Range::new(
        start_byte=3,
        end_byte=4,
        start_point=@api.Point::new(row=0, column=3),
        end_point=@api.Point::new(row=0, column=4),
      ),
      @api.Range::new(
        start_byte=5,
        end_byte=6,
        start_point=@api.Point::new(row=0, column=5),
        end_point=@api.Point::new(row=0, column=6),
      ),
    ],
  )
}

///|
test "changed ranges notice external token presence mismatch" {
  let language = fixture_language()
  let left = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=3,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=3),
      children=[1, 2],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      parent=0,
      has_external_tokens=true,
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=2,
      end_byte=3,
      start_point=@api.Point::new(row=0, column=2),
      end_point=@api.Point::new(row=0, column=3),
      parent=0,
    ),
  ])
  let right = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=3,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=3),
      children=[1, 2],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      parent=0,
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=2,
      end_byte=3,
      start_point=@api.Point::new(row=0, column=2),
      end_point=@api.Point::new(row=0, column=3),
      parent=0,
    ),
  ])
  assert_true(
    left.changed_ranges(right) ==
    [
      @api.Range::new(
        start_byte=0,
        end_byte=1,
        start_point=@api.Point::zero(),
        end_point=@api.Point::new(row=0, column=1),
      ),
    ],
  )
}

///|
test "changed ranges reports root start padding difference" {
  let language = fixture_language()
  let left = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=10,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=10),
      children=[1],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=2,
      end_byte=10,
      start_point=@api.Point::new(row=0, column=2),
      end_point=@api.Point::new(row=0, column=10),
      parent=0,
    ),
  ])
  let right = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=2,
      end_byte=10,
      start_point=@api.Point::new(row=0, column=2),
      end_point=@api.Point::new(row=0, column=10),
      children=[1],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=2,
      end_byte=10,
      start_point=@api.Point::new(row=0, column=2),
      end_point=@api.Point::new(row=0, column=10),
      parent=0,
    ),
  ])
  assert_true(
    left.changed_ranges(right) ==
    [
      @api.Range::new(
        start_byte=0,
        end_byte=2,
        start_point=@api.Point::zero(),
        end_point=@api.Point::new(row=0, column=2),
      ),
    ],
  )
}

///|
test "changed ranges reports root end tail difference" {
  let language = fixture_language()
  let left = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=8,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=8),
      children=[1],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=8,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=8),
      parent=0,
    ),
  ])
  let right = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=10,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=10),
      children=[1],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=8,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=8),
      parent=0,
    ),
  ])
  assert_true(
    left.changed_ranges(right) ==
    [
      @api.Range::new(
        start_byte=8,
        end_byte=10,
        start_point=@api.Point::new(row=0, column=8),
        end_point=@api.Point::new(row=0, column=10),
      ),
    ],
  )
}

///|
test "changed ranges treats empty included ranges as default unbounded" {
  let language = fixture_language()
  let nodes = [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=10,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=10),
      children=[1],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=10,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=10),
      parent=0,
    ),
  ]
  let implicit = Tree::from_fixture(language, nodes)
  let explicit = Tree::from_fixture(language, nodes, included_ranges=[
    @api.Range::unbounded(start_byte=0, start_point=@api.Point::zero()),
  ])
  assert_eq(implicit.changed_ranges(explicit).length(), 0)
}

///|
test "changed ranges compares default unbounded included range to restricted ranges" {
  let language = fixture_language()
  let nodes = [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=10,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=10),
      children=[1],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=10,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=10),
      parent=0,
    ),
  ]
  let implicit = Tree::from_fixture(language, nodes)
  let restricted = Tree::from_fixture(language, nodes, included_ranges=[
    @api.Range::new(
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
    ),
  ])
  assert_true(
    implicit.changed_ranges(restricted) ==
    [
      @api.Range::new(
        start_byte=1,
        end_byte=@api.uint32_max(),
        start_point=@api.Point::new(row=0, column=1),
        end_point=@api.Point::max(),
      ),
    ],
  )
}

///|
test "reduce propagates external scanner metadata to parent" {
  let language = wb_parser_smoke_language()
  let nodes = [
    NodeData::new(
      kind="a",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      external_scanner_state=Some(b"s"),
      has_external_scanner_state_change=true,
      depends_on_column=true,
    ),
  ]
  let leading_extras : Array[Array[Int]] = []
  let stack : Array[ParseStackEntry] = [
    { state_id: 1, node_index: -1 },
    { state_id: 2, node_index: 0 },
  ]
  reduce_stack(
    language,
    language.tables,
    nodes,
    leading_extras,
    stack,
    symbol_id=2,
    child_count=1,
    dynamic_precedence=0,
    production_id=0,
    fallback_byte=0,
    fallback_point=@api.Point::zero(),
    trailing_extras=[],
  )
  assert_eq(nodes.length(), 2)
  assert_true(nodes[1].has_external_tokens)
  assert_true(nodes[1].has_external_scanner_state_change)
  assert_true(nodes[1].depends_on_column)
}

///|
test "pending external extras propagate metadata to root" {
  let nodes = [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(2),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      children=[1],
    ),
    NodeData::new(
      kind="a",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      parent=0,
    ),
    NodeData::new(
      kind="external_extra",
      symbol=@api.SymbolId::new(3),
      start_byte=1,
      end_byte=2,
      start_point=@api.Point::new(row=0, column=1),
      end_point=@api.Point::new(row=0, column=2),
      external_scanner_state=Some(b"s"),
      has_external_scanner_state_change=true,
      depends_on_column=true,
    ),
  ]
  attach_extras_to_root(nodes, 0, leading_extras=[], trailing_extras=[2])

  assert_true(nodes[0].children == [1, 2])
  assert_eq(nodes[0].end_byte, 2)
  assert_true(nodes[0].has_external_tokens)
  assert_true(nodes[0].has_external_scanner_state_change)
  assert_true(nodes[0].depends_on_column)
  assert_true(nodes[2].extra)
  assert_eq(nodes[2].parent, 0)
}

///|
test "edit invalidation uses lookahead byte dependency" {
  let language = fixture_language()
  let tree = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=4,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=4),
      children=[1, 2],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      parent=0,
      lookahead_byte_count=2,
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=2,
      end_byte=4,
      start_point=@api.Point::new(row=0, column=2),
      end_point=@api.Point::new(row=0, column=4),
      parent=0,
    ),
  ])
  tree.edit(
    @api.InputEdit::new(
      start_byte=2,
      old_end_byte=2,
      new_end_byte=3,
      start_point=@api.Point::new(row=0, column=2),
      old_end_point=@api.Point::new(row=0, column=2),
      new_end_point=@api.Point::new(row=0, column=3),
    ),
  )
  let root = tree.root_node()
  assert_true(root.has_changes())
  assert_true(root.child(0).has_changes())
  assert_true(!root.child(1).has_changes())
}

///|
test "edit invalidation uses external scanner column dependency" {
  let language = fixture_language()
  let tree = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=3,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=3),
      children=[1, 2],
      depends_on_column=true,
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      parent=0,
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=2,
      end_byte=3,
      start_point=@api.Point::new(row=0, column=2),
      end_point=@api.Point::new(row=0, column=3),
      parent=0,
      depends_on_column=true,
    ),
  ])
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
  assert_true(root.has_changes())
  assert_true(root.child(1).has_changes())
}

///|
test "edit invalidation ignores column dependency without column shift" {
  let language = fixture_language()
  let tree = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=3,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=3),
      children=[1, 2],
      depends_on_column=true,
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      parent=0,
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=2,
      end_byte=3,
      start_point=@api.Point::new(row=0, column=2),
      end_point=@api.Point::new(row=0, column=3),
      parent=0,
      depends_on_column=true,
    ),
  ])
  tree.edit(
    @api.InputEdit::new(
      start_byte=0,
      old_end_byte=1,
      new_end_byte=1,
      start_point=@api.Point::zero(),
      old_end_point=@api.Point::new(row=0, column=1),
      new_end_point=@api.Point::new(row=0, column=1),
    ),
  )
  let root = tree.root_node()
  assert_true(root.has_changes())
  assert_true(root.child(0).has_changes())
  assert_true(!root.child(1).has_changes())
}

///|
test "hidden wrapper public parent and extra field inheritance behavior" {
  let root = fixture_tree().root_node()
  let first = root.child(0)
  let extra = root.child(1)
  assert_eq(first.type_(), "item")
  assert_eq(first.parent().type_(), "document")
  assert_eq(first.next_sibling().type_(), "comment")
  assert_true(first.previous_sibling().is_null())
  assert_true(extra.is_extra())
  assert_true(root.field_name_for_child(1) is None)
}

///|
test "named extra children do not report or satisfy fields" {
  let language = fixture_language()
  let tree = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=3,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=3),
      children=[1, 2, 3],
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      parent=0,
      field_id=@api.FieldId::new(1),
    ),
    NodeData::new(
      kind="comment",
      symbol=@api.SymbolId::new(3),
      start_byte=1,
      end_byte=2,
      start_point=@api.Point::new(row=0, column=1),
      end_point=@api.Point::new(row=0, column=2),
      parent=0,
      field_id=@api.FieldId::new(1),
      extra=true,
    ),
    NodeData::new(
      kind="item",
      symbol=@api.SymbolId::new(1),
      start_byte=2,
      end_byte=3,
      start_point=@api.Point::new(row=0, column=2),
      end_point=@api.Point::new(row=0, column=3),
      parent=0,
      field_id=@api.FieldId::new(2),
    ),
  ])
  let root = tree.root_node()
  assert_eq(root.named_child_count(), 3)
  assert_eq(root.named_child(1).type_(), "comment")
  assert_true(root.field_name_for_child(1) is None)
  assert_true(root.field_name_for_named_child(1) is None)
  assert_eq(root.child_by_field_id(@api.FieldId::new(1)).start_byte(), 0)
  assert_eq(root.child_by_field_id(@api.FieldId::new(2)).start_byte(), 2)
}

///|
test "manual tree fixture exposes ranges offsets metadata and descendants" {
  let tree = fixture_tree()
  let ranges = tree.included_ranges()
  ranges.push(
    @api.Range::new(
      start_byte=9,
      end_byte=10,
      start_point=@api.Point::new(row=1, column=0),
      end_point=@api.Point::new(row=1, column=1),
    ),
  )
  assert_eq(tree.included_ranges().length(), 1)

  let shifted = tree.root_node_with_offset(
    byte_offset=10,
    point_offset=@api.Point::new(row=2, column=5),
  )
  assert_eq(shifted.start_byte(), 10)
  assert_eq(shifted.child(3).start_byte(), 12)
  assert_true(shifted.start_point() == @api.Point::new(row=2, column=5))
  assert_true(
    shifted.child(3).start_point() == @api.Point::new(row=2, column=7),
  )

  let root = tree.root_node()
  assert_eq(root.descendant_count(), 7)
  assert_true(root.parse_state() == Some(@api.StateId::new(1)))
  assert_true(root.next_parse_state() == Some(@api.StateId::new(2)))
  assert_eq(root.child(3).grammar_type(), "item")
  assert_true(root.child(3).has_changes())
  assert_true(root.child(4).is_missing())
  assert_true(root.child(4).has_error())
}

///|
test "node equality follows tree identity and subtree slot" {
  let tree = fixture_tree()
  let root = tree.root_node()
  assert_true(root.eq(tree.root_node()))
  assert_true(
    root.eq(
      tree.root_node_with_offset(
        byte_offset=10,
        point_offset=@api.Point::new(row=2, column=5),
      ),
    ),
  )
  assert_true(root.child(0).eq(tree.root_node().child(0)))
  assert_true(!root.child(0).eq(root.child(1)))

  let copied = tree.copy()
  assert_true(!root.eq(copied.root_node()))

  let edit = @api.InputEdit::new(
    start_byte=1,
    old_end_byte=1,
    new_end_byte=2,
    start_point=@api.Point::new(row=0, column=1),
    old_end_point=@api.Point::new(row=0, column=1),
    new_end_point=@api.Point::new(row=0, column=2),
  )
  tree.edit(edit)
  assert_true(root.eq(tree.root_node()))
}

///|
test "node lookup APIs honor ranges hidden wrappers and zero width children" {
  let tree = fixture_tree()
  let root = tree.root_node()
  let first = root.child(0)
  let separator = root.child(2)
  let alias_node = root.child(5)

  assert_eq(root.child_with_descendant(root).type_(), "document")
  assert_eq(root.child_with_descendant(first).type_(), "item")
  assert_eq(root.child_with_descendant(alias_node).type_(), "alias_item")
  assert_true(separator.child_with_descendant(alias_node).is_null())

  assert_eq(root.descendant_for_byte_range(0, 1).type_(), "item")
  assert_eq(root.descendant_for_byte_range(1, 1).type_(), "comment")
  assert_eq(root.named_descendant_for_byte_range(1, 1).type_(), "document")
  assert_eq(root.descendant_for_byte_range(1, 2).type_(), ",")
  assert_eq(root.named_descendant_for_byte_range(1, 2).type_(), "document")
  assert_true(root.descendant_for_byte_range(3, 3).is_missing())
  assert_eq(root.descendant_for_byte_range(3, 4).type_(), "alias_item")
  assert_true(root.descendant_for_byte_range(4, 3).is_null())

  assert_eq(
    root
    .descendant_for_point_range(
      @api.Point::new(row=0, column=1),
      @api.Point::new(row=0, column=1),
    )
    .type_(),
    "comment",
  )
  assert_eq(
    root
    .named_descendant_for_point_range(
      @api.Point::new(row=0, column=1),
      @api.Point::new(row=0, column=1),
    )
    .type_(),
    "document",
  )
  assert_true(
    root
    .descendant_for_point_range(
      @api.Point::new(row=0, column=3),
      @api.Point::new(row=0, column=3),
    )
    .is_missing(),
  )
  assert_eq(
    root
    .descendant_for_point_range(
      @api.Point::new(row=0, column=3),
      @api.Point::new(row=0, column=4),
    )
    .type_(),
    "alias_item",
  )
  assert_eq(
    root
    .named_descendant_for_point_range(
      @api.Point::new(row=0, column=1),
      @api.Point::new(row=0, column=2),
    )
    .type_(),
    "document",
  )
  assert_true(
    root
    .descendant_for_point_range(
      @api.Point::new(row=0, column=4),
      @api.Point::new(row=0, column=3),
    )
    .is_null(),
  )

  assert_eq(root.first_child_for_byte(0).type_(), "item")
  assert_eq(root.first_child_for_byte(1).type_(), ",")
  assert_eq(root.first_named_child_for_byte(1).type_(), "item")
  assert_eq(root.first_child_for_byte(3).type_(), "alias_item")
  assert_true(root.first_child_for_byte(4).is_null())
  assert_eq(
    root.first_child_for_point(@api.Point::new(row=0, column=1)).type_(),
    ",",
  )
  assert_eq(
    root.first_named_child_for_point(@api.Point::new(row=0, column=1)).type_(),
    "item",
  )
  assert_eq(
    root.first_child_for_point(@api.Point::new(row=0, column=3)).type_(),
    "alias_item",
  )
  assert_true(
    root.first_child_for_point(@api.Point::new(row=0, column=4)).is_null(),
  )

  let shifted = tree.root_node_with_offset(
    byte_offset=10,
    point_offset=@api.Point::new(row=2, column=5),
  )
  assert_eq(shifted.descendant_for_byte_range(12, 13).type_(), "item")
  assert_eq(shifted.first_child_for_byte(13).type_(), "alias_item")
  assert_eq(
    shifted.first_child_for_point(@api.Point::new(row=2, column=8)).type_(),
    "alias_item",
  )
}

///|
test "tree cursor moves through public tree view" {
  let cursor = fixture_tree().walk()
  assert_eq(cursor.current_node().type_(), "document")
  assert_eq(cursor.current_depth(), 0)
  assert_eq(cursor.current_descendant_index(), 0)

  let first = cursor.goto_first_child().unwrap()
  assert_eq(first.current_node().type_(), "item")
  assert_true(first.current_field_name() == Some("body"))
  assert_eq(first.current_depth(), 1)
  assert_eq(first.current_descendant_index(), 1)

  let extra = first.goto_next_sibling().unwrap()
  assert_eq(extra.current_node().type_(), "comment")
  assert_true(extra.current_field_name() is None)
  assert_eq(
    extra.goto_previous_sibling().unwrap().current_node().type_(),
    "item",
  )
  assert_eq(extra.goto_parent().unwrap().current_node().type_(), "document")

  let separator = cursor.goto_descendant(3).unwrap()
  assert_eq(separator.current_node().type_(), ",")
  assert_true(separator.current_field_name() == Some("separator"))
  let alias_cursor = cursor.goto_last_child().unwrap()
  assert_eq(alias_cursor.current_node().type_(), "alias_item")
  assert_true(alias_cursor.current_field_name() == Some("body"))
}

///|
test "tree cursor seeks by byte and point and preserves reset roots" {
  let cursor = fixture_tree().walk()
  let (comma_index, comma_cursor) = cursor
    .goto_first_child_for_byte_with_index(1)
    .unwrap()
  assert_eq(comma_index, 2)
  assert_eq(comma_cursor.current_node().type_(), ",")
  let (alias_index, alias_cursor) = cursor
    .goto_first_child_for_byte_with_index(3)
    .unwrap()
  assert_eq(alias_index, 5)
  assert_eq(alias_cursor.current_node().type_(), "alias_item")
  assert_true(cursor.goto_first_child_for_byte_with_index(4) is None)
  assert_eq(
    cursor.goto_first_child_for_byte(1).unwrap().current_node().type_(),
    ",",
  )
  assert_eq(
    cursor.goto_first_child_for_byte(3).unwrap().current_node().type_(),
    "alias_item",
  )
  assert_true(cursor.goto_first_child_for_byte(4) is None)
  let (point_comma_index, point_comma_cursor) = cursor
    .goto_first_child_for_point_with_index(@api.Point::new(row=0, column=1))
    .unwrap()
  assert_eq(point_comma_index, 2)
  assert_eq(point_comma_cursor.current_node().type_(), ",")
  let (point_alias_index, point_alias_cursor) = cursor
    .goto_first_child_for_point_with_index(@api.Point::new(row=0, column=3))
    .unwrap()
  assert_eq(point_alias_index, 5)
  assert_eq(point_alias_cursor.current_node().type_(), "alias_item")
  assert_eq(
    cursor
    .goto_first_child_for_point(@api.Point::new(row=0, column=1))
    .unwrap()
    .current_node()
    .type_(),
    ",",
  )
  assert_eq(
    cursor
    .goto_first_child_for_point(@api.Point::new(row=0, column=3))
    .unwrap()
    .current_node()
    .type_(),
    "alias_item",
  )

  let item_cursor = cursor.goto_descendant(4).unwrap()
  let isolated = cursor.reset(item_cursor.current_node())
  assert_eq(isolated.current_node().type_(), "item")
  assert_eq(isolated.current_depth(), 0)
  assert_eq(isolated.current_descendant_index(), 0)
  assert_true(isolated.goto_parent() is None)
  assert_true(isolated.goto_next_sibling() is None)

  let copied = item_cursor.copy()
  assert_eq(copied.current_node().type_(), "item")
  assert_eq(cursor.reset_to(copied).current_node().type_(), "item")
}

///|
test "s-expression output prints named public tree with fields and aliases" {
  let tree = fixture_tree()
  assert_eq(
    tree.to_sexp(),
    "(document body: (item) body: (item) body: (MISSING item) body: (alias_item))",
  )
  assert_eq(tree.root_node().child(5).to_sexp(), "(alias_item)")
  assert_eq(tree.root_node().child(4).to_sexp(), "(MISSING item)")
  assert_eq(tree.root_node().child(2).to_sexp(), "")
}

///|
test "s-expression output handles anonymous missing and error leaves" {
  let language = fixture_language()
  let tree = Tree::from_fixture(language, [
    NodeData::new(
      kind="document",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      children=[1, 2],
      has_error=true,
    ),
    NodeData::new(
      kind="ERROR",
      symbol=@api.SymbolId::new(0),
      start_byte=0,
      end_byte=1,
      start_point=@api.Point::zero(),
      end_point=@api.Point::new(row=0, column=1),
      parent=0,
      is_error=true,
    ),
    NodeData::new(
      kind=";",
      symbol=@api.SymbolId::new(2),
      start_byte=1,
      end_byte=1,
      start_point=@api.Point::new(row=0, column=1),
      end_point=@api.Point::new(row=0, column=1),
      parent=0,
      named=false,
      missing=true,
    ),
  ])
  assert_eq(tree.to_sexp(), "(document (UNEXPECTED ERROR) (MISSING \";\"))")
}

///|
test "parsed error reduction clears state and marks fragility" {
  let parser = Parser::new()
  parser.set_language(wb_parser_smoke_language())
  let tree = parser.parse_bytes(b"xa")
  let root = tree.root_node()
  assert_true(root.has_error())
  assert_true(root.parse_state() is None)
  assert_true(root.next_parse_state() is None)
  guard root.node_data() is Some(root_data) else { fail("root data") }
  assert_true(root_data.fragile_left)
  assert_true(root_data.fragile_right)
  assert_eq(
    root_data.error_cost,
    error_cost_per_recovery +
    error_cost_per_skipped_tree +
    error_cost_per_skipped_char,
  )
  let error = root.child(0)
  assert_true(error.is_error())
  guard error.node_data() is Some(error_data) else { fail("error data") }
  assert_true(error_data.fragile_left)
  assert_true(error_data.fragile_right)
  assert_eq(
    error_data.error_cost,
    error_cost_per_recovery +
    error_cost_per_skipped_tree +
    error_cost_per_skipped_char,
  )
  let token = root.child(1)
  assert_true(!token.has_error())
  guard token.node_data() is Some(token_data) else { fail("token data") }
  assert_true(!token_data.fragile_left)
  assert_true(!token_data.fragile_right)
  assert_eq(token_data.error_cost, 0)
}

///|
test "parsed newline error includes skipped line cost" {
  let parser = Parser::new()
  parser.set_language(wb_parser_smoke_language())
  let tree = parser.parse_bytes(b"\na")
  let error = tree.root_node().child(0)
  guard error.node_data() is Some(error_data) else { fail("error data") }
  assert_eq(
    error_data.error_cost,
    error_cost_per_recovery +
    error_cost_per_skipped_tree +
    error_cost_per_skipped_char +
    error_cost_per_skipped_line,
  )
}

///|
test "parsed missing token carries missing recovery cost" {
  let parser = Parser::new()
  parser.set_language(wb_parser_smoke_language())
  let tree = parser.parse_bytes(b"")
  let root = tree.root_node()
  assert_true(root.has_error())
  guard root.node_data() is Some(root_data) else { fail("root data") }
  assert_eq(
    root_data.error_cost,
    error_cost_per_missing_tree + error_cost_per_recovery,
  )
  let missing = root.child(0)
  assert_true(missing.is_missing())
  guard missing.node_data() is Some(missing_data) else { fail("missing data") }
  assert_eq(
    missing_data.error_cost,
    error_cost_per_missing_tree + error_cost_per_recovery,
  )
  assert_true(missing_data.fragile_left)
  assert_true(missing_data.fragile_right)
}

///|
test "parsed reduction records dynamic precedence" {
  let parser = Parser::new()
  parser.set_language(wb_parser_smoke_language(dynamic_precedence=7))
  let tree = parser.parse_bytes(b"a")
  let root = tree.root_node()
  guard root.node_data() is Some(root_data) else { fail("root data") }
  assert_eq(root_data.dynamic_precedence, 7)
  assert_eq(root_data.lookahead_byte_count, 1)
  let token = root.child(0)
  guard token.node_data() is Some(token_data) else { fail("token data") }
  assert_eq(token_data.dynamic_precedence, 0)
  assert_eq(token_data.lookahead_byte_count, 1)
}

///|
test "parsed decode error token records widened lookahead dependency" {
  let parser = Parser::new()
  parser.set_language(wb_decode_error_language())
  let tree = parser.parse_bytes(Bytes::from_array([b'\xFF']))
  let root = tree.root_node()
  guard root.node_data() is Some(root_data) else { fail("root data") }
  assert_eq(root_data.lookahead_byte_count, 4)
  let token = root.child(0)
  guard token.node_data() is Some(token_data) else { fail("token data") }
  assert_eq(token_data.lookahead_byte_count, 4)
  assert_eq(token_data.start_byte, 0)
  assert_eq(token_data.end_byte, 1)
}

///|
test "edit invalidation uses parsed decode error lookahead dependency" {
  let parser = Parser::new()
  parser.set_language(wb_decode_error_language())
  let tree = parser.parse_bytes(Bytes::from_array([b'\xFF']))
  tree.edit(
    @api.InputEdit::new(
      start_byte=4,
      old_end_byte=4,
      new_end_byte=5,
      start_point=@api.Point::new(row=0, column=4),
      old_end_point=@api.Point::new(row=0, column=4),
      new_end_point=@api.Point::new(row=0, column=5),
    ),
  )
  let root = tree.root_node()
  assert_true(root.has_changes())
  assert_true(root.child(0).has_changes())
}

///|
test "parsed external token at input end records eof lookahead dependency" {
  let parser = Parser::new()
  parser.set_language(
    wb_external_scanner_language(
      wb_external_scanner(_context => {
        @tables.ExternalScanResult::Token(external_token_id=0, bytes_read=1)
      }),
    ),
  )
  let tree = parser.parse_bytes(b"x")
  let root = tree.root_node()
  guard root.node_data() is Some(root_data) else { fail("root data") }
  assert_eq(root_data.lookahead_byte_count, 1)
  let token = root.child(0)
  guard token.node_data() is Some(token_data) else { fail("token data") }
  assert_eq(token_data.lookahead_byte_count, 1)
  assert_eq(token_data.start_byte, 0)
  assert_eq(token_data.end_byte, 1)
}

///|
test "parsed zero-width external token at eof records eof lookahead dependency" {
  let parser = Parser::new()
  parser.set_language(
    wb_external_scanner_language(
      wb_external_scanner(context => {
        context.token(external_token_id=0, state_changed=true)
      }),
    ),
  )
  let tree = parser.parse_bytes(b"")
  let root = tree.root_node()
  guard root.node_data() is Some(root_data) else { fail("root data") }
  assert_eq(root_data.lookahead_byte_count, 1)
  let token = root.child(0)
  guard token.node_data() is Some(token_data) else { fail("token data") }
  assert_eq(token_data.lookahead_byte_count, 1)
  assert_eq(token_data.start_byte, 0)
  assert_eq(token_data.end_byte, 0)
}
