///|
test "parse minimal grammar preserves rule order and defaults" {
  let grammar = @grammar.parse_grammar(
    (
      #|{
      #|  "$schema": "https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json",
      #|  "name": "minimal",
      #|  "unknown": "ignored",
      #|  "rules": {
      #|    "document": { "type": "STRING", "value": "a" },
      #|    "tail": { "type": "BLANK" }
      #|  }
      #|}
    ),
  )
  assert_eq(grammar.name, "minimal")
  assert_true(grammar.start_rule == Some("document"))
  assert_eq(grammar.rules.length(), 1)
  assert_eq(grammar.rules[0].name, "document")
  assert_true(grammar.rules[0].rule == @grammar.Rule::String("a"))
  assert_eq(grammar.extras.length(), 0)
  assert_eq(grammar.externals.length(), 0)
  assert_eq(grammar.inline.length(), 0)
  assert_eq(grammar.conflicts.length(), 0)
  assert_eq(grammar.precedences.length(), 0)
  assert_true(grammar.word is None)
  assert_eq(grammar.reserved.length(), 1)
  assert_eq(grammar.reserved[0].name, "")
  assert_eq(grammar.reserved[0].rules.length(), 0)
  assert_eq(grammar.supertypes.length(), 0)
  assert_true(grammar.inherits is None)
}

///|
test "parse grammar rule forms and ordered top level collections" {
  let grammar = @grammar.parse_grammar(
    (
      #|{
      #|  "name": "forms",
      #|  "inherits": "base",
      #|  "rules": {
      #|    "document": {
      #|      "type": "SEQ",
      #|      "members": [
      #|        { "type": "FIELD", "name": "left", "content": { "type": "SYMBOL", "name": "identifier" } },
      #|        { "type": "CHOICE", "members": [
      #|          { "type": "STRING", "value": "a" },
      #|          { "type": "CHOICE", "members": [
      #|            { "type": "STRING", "value": "a" },
      #|            { "type": "BLANK" }
      #|          ] }
      #|        ] },
      #|        { "type": "REPEAT", "content": { "type": "PATTERN", "value": "[a-z]+", "flags": "iuvx" } },
      #|        { "type": "REPEAT1", "content": { "type": "STRING", "value": "b" } },
      #|        { "type": "ALIAS", "content": { "type": "SYMBOL", "name": "identifier" }, "value": "name", "named": true },
      #|        { "type": "PREC", "value": 1, "content": { "type": "STRING", "value": "p" } },
      #|        { "type": "PREC_LEFT", "value": "left_group", "content": { "type": "STRING", "value": "l" } },
      #|        { "type": "PREC_RIGHT", "value": "right_group", "content": { "type": "STRING", "value": "r" } },
      #|        { "type": "PREC_DYNAMIC", "value": 2, "content": { "type": "STRING", "value": "d" } },
      #|        { "type": "TOKEN", "content": { "type": "STRING", "value": "tok" } },
      #|        { "type": "IMMEDIATE_TOKEN", "content": { "type": "PATTERN", "value": "[0-9]+" } },
      #|        { "type": "RESERVED", "context_name": "global", "content": { "type": "SYMBOL", "name": "identifier" } }
      #|      ]
      #|    },
      #|    "identifier": { "type": "PATTERN", "value": "[a-z_]+" }
      #|  },
      #|  "extras": [{ "type": "STRING", "value": " " }],
      #|  "externals": [{ "type": "SYMBOL", "name": "external_token" }],
      #|  "inline": ["_inline"],
      #|  "conflicts": [["a", "b"]],
      #|  "precedences": [["low", 1, { "type": "SYMBOL", "name": "call" }, { "type": "STRING", "value": "and" }]],
      #|  "word": "identifier",
      #|  "reserved": {
      #|    "global": [{ "type": "SYMBOL", "name": "identifier" }],
      #|    "empty": []
      #|  },
      #|  "supertypes": ["expression"]
      #|}
    ),
  )

  assert_eq(grammar.name, "forms")
  assert_true(grammar.inherits == Some("base"))
  assert_true(grammar.word == Some("identifier"))
  assert_eq(grammar.extras.length(), 1)
  assert_true(grammar.extras[0] == @grammar.Rule::String(" "))
  assert_eq(grammar.externals.length(), 1)
  assert_true(grammar.externals[0] == @grammar.Rule::Symbol("external_token"))
  assert_eq(grammar.inline.length(), 0)
  assert_eq(grammar.conflicts.length(), 0)
  assert_true(
    grammar.precedences[0][0] == @grammar.PrecedenceValue::Name("low"),
  )
  assert_true(grammar.precedences[0][1] == @grammar.PrecedenceValue::Number(1))
  assert_true(
    grammar.precedences[0][2] == @grammar.PrecedenceValue::Name("call"),
  )
  assert_true(
    grammar.precedences[0][3] == @grammar.PrecedenceValue::Name("and"),
  )
  assert_eq(grammar.reserved.length(), 2)
  assert_eq(grammar.reserved[0].name, "global")
  assert_true(
    grammar.reserved[0].rules[0] == @grammar.Rule::Symbol("identifier"),
  )
  assert_eq(grammar.reserved[1].name, "empty")
  assert_eq(grammar.supertypes.length(), 0)

  guard grammar.rules[0].rule is @grammar.Rule::Seq(members) else {
    fail("document should parse as a sequence")
  }
  assert_true(
    members[0] ==
    @grammar.Rule::Field(
      name="left",
      content=@grammar.Rule::Symbol("identifier"),
    ),
  )
  assert_true(
    members[1] ==
    @grammar.Rule::Choice([@grammar.Rule::String("a"), @grammar.Rule::Blank]),
  )
  assert_true(
    members[2] ==
    @grammar.Rule::Choice([
      @grammar.Rule::Repeat(
        @grammar.Rule::Pattern(value="[a-z]+", flags="iuvx"),
      ),
      @grammar.Rule::Blank,
    ]),
  )
  assert_true(members[3] == @grammar.Rule::Repeat1(@grammar.Rule::String("b")))
  assert_true(
    members[4] ==
    @grammar.Rule::Alias(
      content=@grammar.Rule::Symbol("identifier"),
      value="name",
      named=true,
    ),
  )
  assert_true(
    members[5] ==
    @grammar.Rule::Prec(
      value=@grammar.PrecedenceValue::Number(1),
      content=@grammar.Rule::String("p"),
    ),
  )
  assert_true(
    members[6] ==
    @grammar.Rule::PrecLeft(
      value=@grammar.PrecedenceValue::Name("left_group"),
      content=@grammar.Rule::String("l"),
    ),
  )
  assert_true(
    members[7] ==
    @grammar.Rule::PrecRight(
      value=@grammar.PrecedenceValue::Name("right_group"),
      content=@grammar.Rule::String("r"),
    ),
  )
  assert_true(
    members[8] ==
    @grammar.Rule::PrecDynamic(value=2, content=@grammar.Rule::String("d")),
  )
  assert_true(members[9] == @grammar.Rule::Token(@grammar.Rule::String("tok")))
  assert_true(
    members[10] ==
    @grammar.Rule::ImmediateToken(
      @grammar.Rule::Pattern(value="[0-9]+", flags=""),
    ),
  )
  assert_true(
    members[11] ==
    @grammar.Rule::Reserved(
      context_name="global",
      content=@grammar.Rule::Symbol("identifier"),
    ),
  )
}

///|
test "parse grammar reports stable shape errors" {
  let token_result = @test.expect_error(() => {
    @grammar.parse_grammar(
      (
        #|{
        #|  "name": "bad",
        #|  "rules": {
        #|    "document": {
        #|      "type": "TOKEN",
        #|      "content": { "type": "SYMBOL", "name": "identifier" }
        #|    }
        #|  }
        #|}
      ),
    )
  })
  assert_true(
    token_result
    is @grammar.GrammarError::TokenContainsSymbol(
      path="$.rules.document",
      symbol="identifier"
    ),
  )

  let extra_result = @test.expect_error(() => {
    @grammar.parse_grammar(
      (
        #|{
        #|  "name": "bad_extra",
        #|  "rules": {
        #|    "document": { "type": "BLANK" }
        #|  },
        #|  "extras": [{ "type": "STRING", "value": "" }]
        #|}
      ),
    )
  })
  assert_true(
    extra_result is @grammar.GrammarError::EmptyStringExtra("$.extras[0]"),
  )

  let unknown_result = @test.expect_error(() => {
    @grammar.parse_grammar(
      (
        #|{
        #|  "name": "bad_type",
        #|  "rules": {
        #|    "document": { "type": "NOPE" }
        #|  }
        #|}
      ),
    )
  })
  assert_true(
    unknown_result
    is @grammar.GrammarError::UnknownRuleType(
      path="$.rules.document",
      rule_type="NOPE"
    ),
  )
}

///|
test "parse grammar normalizes reachable rules and metadata references" {
  let grammar = @grammar.parse_grammar(
    (
      #|{
      #|  "name": "normalize",
      #|  "rules": {
      #|    "document": { "type": "SYMBOL", "name": "node" },
      #|    "node": { "type": "STRING", "value": "n" },
      #|    "unused": { "type": "STRING", "value": "u" },
      #|    "word_rule": { "type": "TOKEN", "content": { "type": "STRING", "value": "w" } },
      #|    "extra_rule": { "type": "STRING", "value": " " },
      #|    "reserved_rule": { "type": "TOKEN", "content": { "type": "STRING", "value": "r" } },
      #|    "external_token": { "type": "STRING", "value": "x" }
      #|  },
      #|  "word": "word_rule",
      #|  "extras": [{ "type": "SYMBOL", "name": "extra_rule" }],
      #|  "externals": [{ "type": "SYMBOL", "name": "external_token" }],
      #|  "inline": ["node", "unused", "external_token"],
      #|  "conflicts": [["document", "unused"], ["unused"], ["node", "word_rule"]],
      #|  "supertypes": ["document", "unused", "external_token"],
      #|  "reserved": {
      #|    "global": [
      #|      { "type": "SYMBOL", "name": "reserved_rule" },
      #|      { "type": "SYMBOL", "name": "missing_rule" }
      #|    ]
      #|  }
      #|}
    ),
  )

  assert_eq(grammar.rules.length(), 5)
  assert_eq(grammar.rules[0].name, "document")
  assert_eq(grammar.rules[1].name, "node")
  assert_eq(grammar.rules[2].name, "word_rule")
  assert_eq(grammar.rules[3].name, "extra_rule")
  assert_eq(grammar.rules[4].name, "reserved_rule")
  assert_true(grammar.word == Some("word_rule"))
  assert_true(grammar.inline == ["node"])
  assert_true(grammar.conflicts == [["document"], ["node", "word_rule"]])
  assert_true(grammar.supertypes == ["document"])
  assert_eq(grammar.reserved.length(), 1)
  assert_eq(grammar.reserved[0].name, "global")
  assert_eq(grammar.reserved[0].rules.length(), 1)
  assert_true(
    grammar.reserved[0].rules[0] == @grammar.Rule::Symbol("reserved_rule"),
  )
}

///|
test "parse grammar rejects undeclared reserved context" {
  let result = @test.expect_error(() => {
    @grammar.parse_grammar(
      (
        #|{
        #|  "name": "bad_reserved_context",
        #|  "rules": {
        #|    "document": {
        #|      "type": "RESERVED",
        #|      "context_name": "local",
        #|      "content": { "type": "STRING", "value": "x" }
        #|    }
        #|  },
        #|  "reserved": {
        #|    "global": []
        #|  }
        #|}
      ),
    )
  })
  assert_true(
    result is @grammar.GrammarError::UndeclaredReservedContext("local"),
  )
}

///|
test "parse grammar reports reserved word set shape errors" {
  let result = @test.expect_error(() => {
    @grammar.parse_grammar(
      (
        #|{
        #|  "name": "bad_reserved_shape",
        #|  "rules": {
        #|    "document": { "type": "BLANK" }
        #|  },
        #|  "reserved": {
        #|    "global": { "type": "SYMBOL", "name": "identifier" }
        #|  }
        #|}
      ),
    )
  })
  assert_true(
    result is @grammar.GrammarError::ExpectedArray("$.reserved.global"),
  )
}
