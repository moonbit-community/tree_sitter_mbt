///|
pub fn language() -> @tree_sitter_mbt.Language raise @tables.TableValidationError {
  @tree_sitter_mbt.language_from_generated_tables(generated_language_tables())
}

///|
fn generated_language_tables() -> @tables.GeneratedLanguageTables {
  @tables.GeneratedLanguageTables::new(
    name="dynamic_precedence",
    abi_version=15,
    metadata=@tables.LanguageMetadata::new(major=0, minor=0, patch=0),
    symbol_count=8,
    alias_count=0,
    token_count=3,
    external_token_count=0,
    state_count=16,
    field_count=0,
    production_id_count=1,
    max_alias_sequence_length=3,
    supertype_count=0,
    main_lex_state_count=15,
    external_lex_state_count=1,
    reserved_word_set_count=1,
    max_reserved_word_set_size=0,
    large_state_count=2,
    keyword_capture_token=None,
    symbol_names=[
      "end", "*", "identifier", "program", "expression", "declaration", "declarator",
      "type",
    ],
    symbol_types=[
      @api.SymbolType::Regular,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
    ],
    public_symbol_map=[0, 1, 2, 3, 4, 5, 6, 7],
    alias_symbols=[],
    non_terminal_aliases=[],
    field_names=[""],
    lex_modes=[
      @tables.GeneratedLexMode::new(
        lex_state=65535,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=0,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=1,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=2,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=3,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=4,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=5,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=6,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=7,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=8,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=9,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=10,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=11,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=12,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=13,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=14,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
    ],
    primary_state_ids=[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
    parse_action_lists=[
      @tables.GeneratedParseActionList::new(actions=[], reusable=false),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=4,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Reduce(
            symbol_id=7,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=false,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=7,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=4,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[@tables.GeneratedParseAction::Accept],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=7, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=3,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=8, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=9, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=11, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=13, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=6,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=5,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=4,
            child_count=3,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=14, is_repetition=false),
        ],
        reusable=false,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=4,
            child_count=3,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=6,
            child_count=2,
            dynamic_precedence=1,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
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
        @tables.GeneratedParseTableCell::EmptyCell,
      ],
      [
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::ActionCell(1),
        @tables.GeneratedParseTableCell::StateCell(3),
        @tables.GeneratedParseTableCell::StateCell(4),
        @tables.GeneratedParseTableCell::StateCell(5),
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::StateCell(6),
      ],
    ],
    small_parse_table=[
      @tables.GeneratedSmallParseTableRow::new(state_id=2, offset=0, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=2,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=3,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=4,
          symbols=[0],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=3, offset=10, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=5,
          symbols=[0],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=4, offset=14, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=6,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=7,
          symbols=[0],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=5, offset=21, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=7,
          symbols=[0],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=6, offset=25, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=8,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=9,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=10,
          symbols=[6],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=7, offset=35, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=10,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=12,
          symbols=[4],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=8, offset=42, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=11,
          symbols=[2],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=9, offset=46, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=12,
          symbols=[0],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=10, offset=50, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=13,
          symbols=[0],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=11, offset=54, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=4,
          symbols=[0, 1],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=12, offset=59, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=14,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=15,
          symbols=[0],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=13, offset=66, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=16,
          symbols=[0],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=14, offset=70, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=10,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=15,
          symbols=[4],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=15, offset=77, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=14,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=15,
          symbols=[0],
        ),
      ]),
    ],
    small_parse_table_map=[
      0, 10, 14, 21, 25, 35, 42, 46, 50, 54, 59, 66, 70, 77,
    ],
    extra_symbol_ids=[],
    extra_state_ids=[],
    default_aliases=[],
    supertype_entries=[],
    reserved_word_sets=[@tables.GeneratedTokenSet::new(symbol_ids=[])],
    external_lex_states=[
      @tables.GeneratedExternalLexState::new(external_token_ids=[]),
    ],
    external_scanner=@tables.ExternalScannerDescriptor::none(),
    production_infos=[
      @tables.GeneratedProductionInfo::new(alias_sequence=[], field_map=[]),
    ],
    main_lex_tables=[
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=45, end=45),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=45, end=45),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=Some(1),
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=42, end=42)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=45, end=45),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=45, end=45),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=Some(1),
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=None,
            transitions=[],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=Some(1),
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=42, end=42)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=Some(1),
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=None,
            transitions=[],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=42, end=42)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=45, end=45),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=45, end=45),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=45, end=45),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=45, end=45),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=45, end=45),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=45, end=45),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=Some(1),
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=None,
            transitions=[],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=Some(1),
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=None,
            transitions=[],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=Some(1),
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=42, end=42)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=Some(1),
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=42, end=42)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=Some(1),
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=None,
            transitions=[],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=45, end=45),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=45, end=45),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
        ],
        start_state=0,
      ),
      @tables.GeneratedLexTable::new(
        states=[
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=Some(1),
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=42, end=42)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(0),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[],
          ),
        ],
        start_state=0,
      ),
    ],
    keyword_lex_table=None,
  )
}
