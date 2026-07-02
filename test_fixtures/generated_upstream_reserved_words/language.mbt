///|
pub fn language() -> @tree_sitter_mbt.Language raise @tables.TableValidationError {
  @tree_sitter_mbt.language_from_generated_tables(generated_language_tables())
}

///|
fn generated_language_tables() -> @tables.GeneratedLanguageTables {
  @tables.GeneratedLanguageTables::new(
    name="reserved_words",
    abi_version=15,
    metadata=@tables.LanguageMetadata::new(major=0, minor=0, patch=0),
    symbol_count=35,
    alias_count=0,
    token_count=17,
    external_token_count=0,
    state_count=116,
    field_count=0,
    production_id_count=1,
    max_alias_sequence_length=5,
    supertype_count=0,
    main_lex_state_count=115,
    external_lex_state_count=1,
    reserved_word_set_count=3,
    max_reserved_word_set_size=3,
    large_state_count=2,
    keyword_capture_token=Some(1),
    symbol_names=[
      "end", "identifier", "{", "}", "var", "=", ";", "if", "while", "(", ")", ".",
      ",", "/", "regex_pattern", ":", "get", "program", "block", "_statement", "var_declaration",
      "if_statement", "while_statement", "expression_statement", "_expression", "parenthesized_expression",
      "member_expression", "call_expression", "object", "regex", "pair", "getter",
      "program_repeat1", "call_expression_repeat1", "object_repeat1",
    ],
    symbol_types=[
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Regular,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Anonymous,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Regular,
      @api.SymbolType::Auxiliary,
      @api.SymbolType::Auxiliary,
      @api.SymbolType::Auxiliary,
    ],
    public_symbol_map=[
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
      22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
    ],
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
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=1,
        external_lex_state=0,
        reserved_word_set_id=2,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=2,
        external_lex_state=0,
        reserved_word_set_id=1,
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
        reserved_word_set_id=1,
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
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=10,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=11,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=12,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=13,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=14,
        external_lex_state=0,
        reserved_word_set_id=2,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=15,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=16,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=17,
        external_lex_state=0,
        reserved_word_set_id=2,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=18,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=19,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=20,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=21,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=22,
        external_lex_state=0,
        reserved_word_set_id=2,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=23,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=24,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=25,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=26,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=27,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=28,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=29,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=30,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=31,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=32,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=33,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=34,
        external_lex_state=0,
        reserved_word_set_id=2,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=35,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=36,
        external_lex_state=0,
        reserved_word_set_id=2,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=37,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=38,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=39,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=40,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=41,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=42,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=43,
        external_lex_state=0,
        reserved_word_set_id=2,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=44,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=45,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=46,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=47,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=48,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=49,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=50,
        external_lex_state=0,
        reserved_word_set_id=2,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=51,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=52,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=53,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=54,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=55,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=56,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=57,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=58,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=59,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=60,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=61,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=62,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=63,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=64,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=65,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=66,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=67,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=68,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=69,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=70,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=71,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=72,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=73,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=74,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=75,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=76,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=77,
        external_lex_state=0,
        reserved_word_set_id=2,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=78,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=79,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=80,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=81,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=82,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=83,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=84,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=85,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=86,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=87,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=88,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=89,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=90,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=91,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=92,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=93,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=94,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=95,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=96,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=97,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=98,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=99,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=100,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=101,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=102,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=103,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=104,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=105,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=106,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=107,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=108,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=109,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=110,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=111,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=112,
        external_lex_state=0,
        reserved_word_set_id=0,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=113,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
      @tables.GeneratedLexMode::new(
        lex_state=114,
        external_lex_state=0,
        reserved_word_set_id=1,
      ),
    ],
    primary_state_ids=[
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 6, 21,
      22, 2, 6, 7, 8, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 27, 40, 41,
      42, 14, 18, 27, 28, 30, 48, 31, 50, 2, 6, 53, 7, 8, 56, 57, 58, 59, 60, 61,
      48, 63, 3, 4, 5, 10, 11, 12, 70, 36, 48, 50, 53, 57, 58, 14, 18, 27, 28, 30,
      31, 83, 84, 85, 86, 87, 19, 21, 22, 29, 92, 32, 84, 36, 48, 50, 53, 57, 58,
      40, 102, 38, 40, 41, 42, 84, 63, 70, 61, 63, 70, 92, 87, 92,
    ],
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
          @tables.GeneratedParseAction::Shift(state_id=3, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=4, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=5, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=6, is_repetition=false),
        ],
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
          @tables.GeneratedParseAction::Shift(state_id=8, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=17,
            child_count=0,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=14, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=15, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=16, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=19, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=20, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=23, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=24, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=25, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=26, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=28, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=24,
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
          @tables.GeneratedParseAction::Reduce(
            symbol_id=32,
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
            symbol_id=19,
            child_count=1,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=29, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=30, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=31, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=17,
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
            symbol_id=28,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=33, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=34, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=35, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=36, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=38, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=40, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=43, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=46, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=47, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=48, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=49, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=50, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=23,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=51, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=52, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=53, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=54, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=55, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=58, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=32,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=2, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=32,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=3, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=32,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=4, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=32,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=5, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=32,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=6, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=32,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=7, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=32,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=8, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=32,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=59, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=34,
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
            symbol_id=28,
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
            symbol_id=34,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=15, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=34,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=16, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=62, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=63, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=64, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=65, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=66, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=21,
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
            symbol_id=22,
            child_count=3,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=71, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=72, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=73, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=74, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=25,
            child_count=3,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=76, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=29,
            child_count=3,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=77, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=27,
            child_count=3,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=80, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=81, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=82, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=83, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=84, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=26,
            child_count=3,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=86, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=30,
            child_count=3,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=87, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=18,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=88, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=91, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=92, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=94, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=95, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=96, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=97, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=98, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=100, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=33,
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
            symbol_id=27,
            child_count=4,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=33,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=51, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=33,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=52, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=33,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=54, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=33,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=55, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=101, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=20,
            child_count=5,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=103, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=104, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=18,
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
            symbol_id=32,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=64, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=32,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=65, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=32,
            child_count=2,
            dynamic_precedence=0,
            production_id=0,
          ),
          @tables.GeneratedParseAction::Shift(state_id=66, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=107, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=108, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Reduce(
            symbol_id=31,
            child_count=5,
            dynamic_precedence=0,
            production_id=0,
          ),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=111, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=113, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=114, is_repetition=false),
        ],
        reusable=true,
      ),
      @tables.GeneratedParseActionList::new(
        actions=[
          @tables.GeneratedParseAction::Shift(state_id=115, is_repetition=false),
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
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
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
        @tables.GeneratedParseTableCell::ActionCell(8),
        @tables.GeneratedParseTableCell::ActionCell(7),
        @tables.GeneratedParseTableCell::ActionCell(1),
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::ActionCell(2),
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::ActionCell(3),
        @tables.GeneratedParseTableCell::ActionCell(4),
        @tables.GeneratedParseTableCell::ActionCell(5),
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::ActionCell(6),
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::StateCell(9),
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::StateCell(10),
        @tables.GeneratedParseTableCell::StateCell(11),
        @tables.GeneratedParseTableCell::StateCell(11),
        @tables.GeneratedParseTableCell::StateCell(11),
        @tables.GeneratedParseTableCell::StateCell(11),
        @tables.GeneratedParseTableCell::StateCell(12),
        @tables.GeneratedParseTableCell::StateCell(8),
        @tables.GeneratedParseTableCell::StateCell(8),
        @tables.GeneratedParseTableCell::StateCell(8),
        @tables.GeneratedParseTableCell::StateCell(8),
        @tables.GeneratedParseTableCell::StateCell(8),
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::StateCell(13),
        @tables.GeneratedParseTableCell::EmptyCell,
        @tables.GeneratedParseTableCell::EmptyCell,
      ],
    ],
    small_parse_table=[
      @tables.GeneratedSmallParseTableRow::new(state_id=2, offset=0, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=9,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=10,
          symbols=[16],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=11,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=18,
          symbols=[34],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=17,
          symbols=[30, 31],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=3, offset=17, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=12,
          symbols=[1],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=4, offset=21, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=13,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=21,
          symbols=[25],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=5, offset=28, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=13,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=22,
          symbols=[25],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=6, offset=35, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=14,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=15,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=16,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=17,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=27,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=26,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=7, offset=58, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=18,
          symbols=[14],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=8, offset=62, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=19,
          symbols=[6, 9, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=9, offset=68, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=20,
          symbols=[0],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=10, offset=72, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=21,
          symbols=[0, 1, 2, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=11, offset=83, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=22,
          symbols=[0, 1, 2, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=12, offset=94, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=23,
          symbols=[6],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=24,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=25,
          symbols=[11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=13, offset=104, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=1,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=2,
          symbols=[4],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=3,
          symbols=[7],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=4,
          symbols=[8],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=5,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=6,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=7,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=26,
          symbols=[0],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=10,
          symbols=[19],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=12,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=32,
          symbols=[32],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=11,
          symbols=[20, 21, 22, 23],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=8,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=14, offset=151, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=27,
          symbols=[6, 9, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=15, offset=157, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=28,
          symbols=[1],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=16, offset=161, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=29,
          symbols=[15],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=17, offset=165, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=30,
          symbols=[12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=18, offset=169, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=10,
          symbols=[16],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=11,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=31,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=37,
          symbols=[34],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=17,
          symbols=[30, 31],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=19, offset=186, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=32,
          symbols=[5],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=20, offset=190, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=14,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=15,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=16,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=17,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=39,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=26,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=21, offset=213, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=33,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=41,
          symbols=[18],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=22, offset=220, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=33,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=42,
          symbols=[18],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=23, offset=227, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=10,
          symbols=[16],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=11,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=34,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=44,
          symbols=[34],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=17,
          symbols=[30, 31],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=24, offset=244, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=14,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=15,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=16,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=17,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=45,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=26,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=25, offset=267, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=35,
          symbols=[14],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=26, offset=271, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=19,
          symbols=[9, 10, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=27, offset=277, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=36,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=37,
          symbols=[10],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=38,
          symbols=[11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=28, offset=287, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=39,
          symbols=[13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=29, offset=291, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=40,
          symbols=[0, 1, 2, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=30, offset=302, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=41,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=42,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=43,
          symbols=[10],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=44,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=45,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=56,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=57,
          symbols=[33],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=55,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=31, offset=331, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=46,
          symbols=[1],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=32, offset=335, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=47,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=48,
          symbols=[4],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=49,
          symbols=[7],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=50,
          symbols=[8],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=51,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=52,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=53,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=54,
          symbols=[0],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=10,
          symbols=[19],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=12,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=32,
          symbols=[32],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=11,
          symbols=[20, 21, 22, 23],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=8,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=33, offset=382, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=55,
          symbols=[9],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=34, offset=386, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=41,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=42,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=44,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=45,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=60,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=55,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=35, offset=409, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=56,
          symbols=[1, 3, 16],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=36, offset=415, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=57,
          symbols=[6, 9, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=37, offset=421, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=56,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=58,
          symbols=[16],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=59,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=37,
          symbols=[34],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=17,
          symbols=[30, 31],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=38, offset=438, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=1,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=5,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=6,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=7,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=61,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=8,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=39, offset=461, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=36,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=38,
          symbols=[11],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=60,
          symbols=[10],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=40, offset=471, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=1,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=5,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=6,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=7,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=61,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=62,
          symbols=[4],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=63,
          symbols=[7],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=64,
          symbols=[8],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=67,
          symbols=[19],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=69,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=70,
          symbols=[32],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=68,
          symbols=[20, 21, 22, 23],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=8,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=41, offset=518, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=65,
          symbols=[0, 1, 2, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=42, offset=529, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=66,
          symbols=[0, 1, 2, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=43, offset=540, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=27,
          symbols=[9, 10, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=44, offset=546, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=10,
          symbols=[16],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=11,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=67,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=37,
          symbols=[34],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=17,
          symbols=[30, 31],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=45, offset=563, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=36,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=38,
          symbols=[11],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=68,
          symbols=[10],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=46, offset=573, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=69,
          symbols=[13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=47, offset=577, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=41,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=42,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=44,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=45,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=70,
          symbols=[10],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=56,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=75,
          symbols=[33],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=55,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=48, offset=606, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=71,
          symbols=[6, 9, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=49, offset=612, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=72,
          symbols=[1],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=50, offset=616, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=73,
          symbols=[6, 9, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=51, offset=622, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=10,
          symbols=[16],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=11,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=74,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=78,
          symbols=[34],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=17,
          symbols=[30, 31],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=52, offset=639, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=14,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=15,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=16,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=17,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=79,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=26,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=53, offset=662, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=75,
          symbols=[6, 9, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=54, offset=668, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=76,
          symbols=[14],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=55, offset=672, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=19,
          symbols=[9, 11, 12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=56, offset=678, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=77,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=78,
          symbols=[11],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=79,
          symbols=[12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=57, offset=688, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=41,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=42,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=44,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=45,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=80,
          symbols=[10],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=56,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=85,
          symbols=[33],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=55,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=58, offset=717, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=81,
          symbols=[6, 9, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=59, offset=723, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=82,
          symbols=[10],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=60, offset=727, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=77,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=78,
          symbols=[11],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=83,
          symbols=[12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=61, offset=737, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=24,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=25,
          symbols=[11],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=84,
          symbols=[6],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=62, offset=747, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=71,
          symbols=[2],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=63, offset=751, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=85,
          symbols=[0, 1, 2, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=64, offset=762, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=86,
          symbols=[1],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=65, offset=766, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=13,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=89,
          symbols=[25],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=66, offset=773, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=13,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=90,
          symbols=[25],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=67, offset=780, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=21,
          symbols=[1, 2, 3, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=68, offset=791, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=22,
          symbols=[1, 2, 3, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=69, offset=802, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=24,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=25,
          symbols=[11],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=87,
          symbols=[6],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=70, offset=812, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=1,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=5,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=6,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=7,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=62,
          symbols=[4],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=63,
          symbols=[7],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=64,
          symbols=[8],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=88,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=67,
          symbols=[19],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=69,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=93,
          symbols=[32],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=68,
          symbols=[20, 21, 22, 23],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=8,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=71, offset=859, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=57,
          symbols=[9, 10, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=72, offset=865, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=71,
          symbols=[9, 10, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=73, offset=871, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=73,
          symbols=[9, 10, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=74, offset=877, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=75,
          symbols=[9, 10, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=75, offset=883, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=41,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=42,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=44,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=45,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=89,
          symbols=[10],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=56,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=85,
          symbols=[33],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=55,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=76, offset=912, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=81,
          symbols=[9, 10, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=77, offset=918, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=27,
          symbols=[9, 11, 12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=78, offset=924, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=10,
          symbols=[16],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=11,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=90,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=37,
          symbols=[34],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=17,
          symbols=[30, 31],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=79, offset=941, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=36,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=38,
          symbols=[11],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=91,
          symbols=[10],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=80, offset=951, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=92,
          symbols=[13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=81, offset=955, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=41,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=42,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=44,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=45,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=93,
          symbols=[10],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=56,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=99,
          symbols=[33],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=55,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=82, offset=984, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=94,
          symbols=[1],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=83, offset=988, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=95,
          symbols=[1, 2, 9, 10, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=84, offset=996, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=96,
          symbols=[6, 9, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=85, offset=1002, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=95,
          symbols=[10],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=97,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=98,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=99,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=100,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=56,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=85,
          symbols=[33],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=55,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=86, offset=1031, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=101,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=102,
          symbols=[18],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=87, offset=1038, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=102,
          symbols=[0, 1, 2, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=88, offset=1049, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=103,
          symbols=[5],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=89, offset=1053, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=104,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=105,
          symbols=[18],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=90, offset=1060, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=104,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=106,
          symbols=[18],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=91, offset=1067, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=40,
          symbols=[1, 2, 3, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=92, offset=1078, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=105,
          symbols=[0, 1, 2, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=93, offset=1089, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=47,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=51,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=52,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=53,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=54,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=106,
          symbols=[4],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=107,
          symbols=[7],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=108,
          symbols=[8],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=67,
          symbols=[19],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=69,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=93,
          symbols=[32],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=68,
          symbols=[20, 21, 22, 23],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=8,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=94, offset=1136, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=96,
          symbols=[9, 10, 11],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=95, offset=1142, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=57,
          symbols=[9, 11, 12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=96, offset=1148, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=71,
          symbols=[9, 11, 12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=97, offset=1154, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=73,
          symbols=[9, 11, 12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=98, offset=1160, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=75,
          symbols=[9, 11, 12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=99, offset=1166, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=41,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=42,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=44,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=45,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=109,
          symbols=[10],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=56,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=85,
          symbols=[33],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=55,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=100, offset=1195, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=81,
          symbols=[9, 11, 12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=101, offset=1201, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=1,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=5,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=6,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=7,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=62,
          symbols=[4],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=63,
          symbols=[7],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=64,
          symbols=[8],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=110,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=67,
          symbols=[19],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=69,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=109,
          symbols=[32],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=68,
          symbols=[20, 21, 22, 23],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=8,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=102, offset=1248, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=111,
          symbols=[12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=103, offset=1252, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=1,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=5,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=6,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=7,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=110,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=8,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=104, offset=1275, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=1,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=5,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=6,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=7,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=62,
          symbols=[4],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=63,
          symbols=[7],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=64,
          symbols=[8],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=112,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=67,
          symbols=[19],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=69,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=112,
          symbols=[32],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=68,
          symbols=[20, 21, 22, 23],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=8,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=105, offset=1322, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=65,
          symbols=[1, 2, 3, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=106, offset=1333, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=66,
          symbols=[1, 2, 3, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=107, offset=1344, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=96,
          symbols=[9, 11, 12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=108, offset=1350, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=85,
          symbols=[12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=109, offset=1354, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=1,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=5,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=6,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=7,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=62,
          symbols=[4],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=63,
          symbols=[7],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=64,
          symbols=[8],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=113,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=67,
          symbols=[19],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=69,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=93,
          symbols=[32],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=68,
          symbols=[20, 21, 22, 23],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=8,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=110, offset=1401, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=24,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=25,
          symbols=[11],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=114,
          symbols=[6],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=111, offset=1411, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=85,
          symbols=[1, 2, 3, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=112, offset=1422, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=1,
          symbols=[2],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=5,
          symbols=[9],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=6,
          symbols=[13],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=7,
          symbols=[1],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=62,
          symbols=[4],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=63,
          symbols=[7],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=64,
          symbols=[8],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=115,
          symbols=[3],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=67,
          symbols=[19],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=69,
          symbols=[24],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=93,
          symbols=[32],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=68,
          symbols=[20, 21, 22, 23],
        ),
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallState,
          value=8,
          symbols=[25, 26, 27, 28, 29],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=113, offset=1469, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=105,
          symbols=[12],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=114, offset=1473, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=102,
          symbols=[1, 2, 3, 4, 7, 8, 9, 13],
        ),
      ]),
      @tables.GeneratedSmallParseTableRow::new(state_id=115, offset=1484, sections=[
        @tables.GeneratedSmallParseTableSection::new(
          kind=@tables.GeneratedSmallParseTableSectionKind::SmallAction,
          value=105,
          symbols=[1, 2, 3, 4, 7, 8, 9, 13],
        ),
      ]),
    ],
    small_parse_table_map=[
      0, 17, 21, 28, 35, 58, 62, 68, 72, 83, 94, 104, 151, 157, 161, 165, 169, 186,
      190, 213, 220, 227, 244, 267, 271, 277, 287, 291, 302, 331, 335, 382, 386,
      409, 415, 421, 438, 461, 471, 518, 529, 540, 546, 563, 573, 577, 606, 612,
      616, 622, 639, 662, 668, 672, 678, 688, 717, 723, 727, 737, 747, 751, 762,
      766, 773, 780, 791, 802, 812, 859, 865, 871, 877, 883, 912, 918, 924, 941,
      951, 955, 984, 988, 996, 1002, 1031, 1038, 1049, 1053, 1060, 1067, 1078, 1089,
      1136, 1142, 1148, 1154, 1160, 1166, 1195, 1201, 1248, 1252, 1275, 1322, 1333,
      1344, 1350, 1354, 1401, 1411, 1422, 1469, 1473, 1484,
    ],
    extra_symbol_ids=[],
    extra_state_ids=[],
    default_aliases=[],
    supertype_entries=[],
    reserved_word_sets=[
      @tables.GeneratedTokenSet::new(symbol_ids=[]),
      @tables.GeneratedTokenSet::new(symbol_ids=[4, 7, 8]),
      @tables.GeneratedTokenSet::new(symbol_ids=[4]),
    ],
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
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
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
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
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                  @tables.GeneratedCharacterRange::new(start=0, end=8),
                  @tables.GeneratedCharacterRange::new(start=14, end=31),
                  @tables.GeneratedCharacterRange::new(start=33, end=46),
                  @tables.GeneratedCharacterRange::new(start=48, end=1114111),
                ],
                target_state=1,
                is_separator=false,
                precedence=-1,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=9),
                  @tables.GeneratedCharacterRange::new(start=11, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=10, end=10)],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(14),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=0, end=9),
                  @tables.GeneratedCharacterRange::new(start=11, end=46),
                  @tables.GeneratedCharacterRange::new(start=48, end=1114111),
                ],
                target_state=1,
                is_separator=false,
                precedence=-1,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(14),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=0, end=8),
                  @tables.GeneratedCharacterRange::new(start=14, end=31),
                  @tables.GeneratedCharacterRange::new(start=33, end=46),
                  @tables.GeneratedCharacterRange::new(start=48, end=1114111),
                ],
                target_state=1,
                is_separator=false,
                precedence=-1,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=9),
                  @tables.GeneratedCharacterRange::new(start=11, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=10, end=10)],
                target_state=0,
                is_separator=true,
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=59, end=59)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(6),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
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
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
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
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=59, end=59)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(6),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
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
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=59, end=59)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(6),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=58, end=58)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(15),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
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
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=61, end=61)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(5),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
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
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
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
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                  @tables.GeneratedCharacterRange::new(start=0, end=8),
                  @tables.GeneratedCharacterRange::new(start=14, end=31),
                  @tables.GeneratedCharacterRange::new(start=33, end=46),
                  @tables.GeneratedCharacterRange::new(start=48, end=1114111),
                ],
                target_state=1,
                is_separator=false,
                precedence=-1,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=9),
                  @tables.GeneratedCharacterRange::new(start=11, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=10, end=10)],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(14),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=0, end=9),
                  @tables.GeneratedCharacterRange::new(start=11, end=46),
                  @tables.GeneratedCharacterRange::new(start=48, end=1114111),
                ],
                target_state=1,
                is_separator=false,
                precedence=-1,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(14),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=0, end=8),
                  @tables.GeneratedCharacterRange::new(start=14, end=31),
                  @tables.GeneratedCharacterRange::new(start=33, end=46),
                  @tables.GeneratedCharacterRange::new(start=48, end=1114111),
                ],
                target_state=1,
                is_separator=false,
                precedence=-1,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=9),
                  @tables.GeneratedCharacterRange::new(start=11, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=10, end=10)],
                target_state=0,
                is_separator=true,
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
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
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
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
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
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
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=59, end=59)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(6),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
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
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
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
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
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
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
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
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=59, end=59)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(6),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=59, end=59)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(6),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
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
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=59, end=59)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(6),
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
                  @tables.GeneratedCharacterRange::new(start=0, end=8),
                  @tables.GeneratedCharacterRange::new(start=14, end=31),
                  @tables.GeneratedCharacterRange::new(start=33, end=46),
                  @tables.GeneratedCharacterRange::new(start=48, end=1114111),
                ],
                target_state=1,
                is_separator=false,
                precedence=-1,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=9),
                  @tables.GeneratedCharacterRange::new(start=11, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=10, end=10)],
                target_state=0,
                is_separator=true,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(14),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=0, end=9),
                  @tables.GeneratedCharacterRange::new(start=11, end=46),
                  @tables.GeneratedCharacterRange::new(start=48, end=1114111),
                ],
                target_state=1,
                is_separator=false,
                precedence=-1,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(14),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=0, end=8),
                  @tables.GeneratedCharacterRange::new(start=14, end=31),
                  @tables.GeneratedCharacterRange::new(start=33, end=46),
                  @tables.GeneratedCharacterRange::new(start=48, end=1114111),
                ],
                target_state=1,
                is_separator=false,
                precedence=-1,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=9, end=9),
                  @tables.GeneratedCharacterRange::new(start=11, end=13),
                  @tables.GeneratedCharacterRange::new(start=32, end=32),
                ],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=10, end=10)],
                target_state=0,
                is_separator=true,
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=59, end=59)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(6),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=59, end=59)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(6),
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
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
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
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=59, end=59)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(6),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
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
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=59, end=59)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(6),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
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
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=61, end=61)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(5),
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
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
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
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
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
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=41, end=41)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(10),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=46, end=46)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=59, end=59)],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(11),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(6),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=44, end=44)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(12),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
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
                ranges=[@tables.GeneratedCharacterRange::new(start=40, end=40)],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=47, end=47)],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=123, end=123),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=125, end=125),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(9),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(13),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(1),
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=48, end=57),
                  @tables.GeneratedCharacterRange::new(start=65, end=90),
                  @tables.GeneratedCharacterRange::new(start=95, end=95),
                  @tables.GeneratedCharacterRange::new(start=97, end=122),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(2),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(3),
            eof_action=None,
            transitions=[],
          ),
        ],
        start_state=0,
      ),
    ],
    keyword_lex_table=Some(
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
                  @tables.GeneratedCharacterRange::new(start=103, end=103),
                ],
                target_state=1,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=105, end=105),
                ],
                target_state=2,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=118, end=118),
                ],
                target_state=3,
                is_separator=false,
                precedence=0,
              ),
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=119, end=119),
                ],
                target_state=4,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=101, end=101),
                ],
                target_state=5,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=102, end=102),
                ],
                target_state=6,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[@tables.GeneratedCharacterRange::new(start=97, end=97)],
                target_state=7,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=104, end=104),
                ],
                target_state=8,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=116, end=116),
                ],
                target_state=9,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(7),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=114, end=114),
                ],
                target_state=10,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=105, end=105),
                ],
                target_state=11,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(16),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(4),
            eof_action=None,
            transitions=[],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=108, end=108),
                ],
                target_state=12,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=None,
            eof_action=None,
            transitions=[
              @tables.GeneratedLexTransition::new(
                ranges=[
                  @tables.GeneratedCharacterRange::new(start=101, end=101),
                ],
                target_state=13,
                is_separator=false,
                precedence=0,
              ),
            ],
          ),
          @tables.GeneratedLexState::new(
            accept_symbol_id=Some(8),
            eof_action=None,
            transitions=[],
          ),
        ],
        start_state=0,
      ),
    ),
  )
}
