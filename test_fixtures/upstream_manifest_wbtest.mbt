///|
enum UpstreamFixtureStatus {
  RunnableCorpus
  ExpectedGenerateError
  UnsupportedExternalScanner
} derive(Eq, Debug)

///|
struct UpstreamExpectedGenerateError {
  category : String
  message_fragments : Array[String]
  upstream_expected_error : String
} derive(Eq, Debug)

///|
struct UpstreamFixture {
  name : String
  upstream_path : String
  status : UpstreamFixtureStatus
  grammar_json : String?
  corpus : String?
  expected_error : UpstreamExpectedGenerateError?
} derive(Eq, Debug)

///|
fn upstream_fixture_manifest() -> Array[UpstreamFixture] {
  [
    {
      name: "aliased_inlined_rules",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/aliased_inlined_rules",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"aliased_inlined_rules","rules":{"statement":{"type":"SEQ","members":[{"type":"SYMBOL","name":"_expression"},{"type":"STRING","value":";"}]},"_expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"member_expression"},{"type":"ALIAS","content":{"type":"SYMBOL","name":"identifier"},"named":true,"value":"variable_name"}]},"member_expression":{"type":"PREC_LEFT","value":1,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"_expression"},{"type":"STRING","value":"."},{"type":"ALIAS","content":{"type":"SYMBOL","name":"identifier"},"named":true,"value":"property_name"}]}},"identifier":{"type":"CHOICE","members":[{"type":"STRING","value":"a"},{"type":"STRING","value":"b"},{"type":"STRING","value":"c"}]}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":["identifier"],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|=========================
          #|OK
          #|=========================
          #|
          #|a.b.c;
          #|
          #|---
          #|
          #|(statement
          #|  (member_expression
          #|    (member_expression
          #|      (variable_name)
          #|      (property_name))
          #|    (property_name)))
        ),
      ),
      expected_error: None,
    },
    {
      name: "aliased_rules",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/aliased_rules",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"aliased_rules","rules":{"statement":{"type":"SEQ","members":[{"type":"SYMBOL","name":"_expression"},{"type":"STRING","value":";"}]},"_expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"call_expression"},{"type":"SYMBOL","name":"member_expression"},{"type":"ALIAS","content":{"type":"SYMBOL","name":"identifier"},"named":true,"value":"variable_name"}]},"call_expression":{"type":"PREC_LEFT","value":0,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"_expression"},{"type":"STRING","value":"("},{"type":"SYMBOL","name":"_expression"},{"type":"STRING","value":")"}]}},"member_expression":{"type":"PREC_LEFT","value":1,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"_expression"},{"type":"STRING","value":"."},{"type":"ALIAS","content":{"type":"SYMBOL","name":"identifier"},"named":true,"value":"property_name"}]}},"identifier":{"type":"PATTERN","value":"[a-z]+"},"star":{"type":"STRING","value":"*"},"unused":{"type":"ALIAS","content":{"type":"SYMBOL","name":"star"},"named":true,"value":"star_aliased"}},"extras":[{"type":"PATTERN","value":"\\s"},{"type":"SYMBOL","name":"star"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|======================================
          #|Method calls
          #|======================================
          #|
          #|*a.b(c(d.e));
          #|
          #|---
          #|
          #|(statement
          #|  (star)
          #|  (call_expression
          #|    (member_expression
          #|      (variable_name)
          #|      (property_name))
          #|    (call_expression
          #|      (variable_name)
          #|      (member_expression
          #|        (variable_name)
          #|        (property_name)))))
        ),
      ),
      expected_error: None,
    },
    {
      name: "aliased_token_rules",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/aliased_token_rules",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"aliased_token_rules","rules":{"expression":{"type":"SEQ","members":[{"type":"STRING","value":"a"},{"type":"ALIAS","content":{"type":"TOKEN","content":{"type":"SEQ","members":[{"type":"STRING","value":"b"},{"type":"STRING","value":"c"}]}},"named":true,"value":"X"},{"type":"ALIAS","content":{"type":"IMMEDIATE_TOKEN","content":{"type":"SEQ","members":[{"type":"STRING","value":"d"},{"type":"STRING","value":"e"}]}},"named":true,"value":"Y"}]}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|======================
          #|Aliased token rules
          #|======================
          #|
          #|abcde
          #|
          #|---
          #|
          #|(expression (X) (Y))
        ),
      ),
      expected_error: None,
    },
    {
      name: "aliased_unit_reductions",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/aliased_unit_reductions",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"aliased_unit_reductions","rules":{"statement":{"type":"SEQ","members":[{"type":"SYMBOL","name":"_a"},{"type":"ALIAS","content":{"type":"SYMBOL","name":"_b"},"named":true,"value":"b_prime"},{"type":"ALIAS","content":{"type":"SYMBOL","name":"_c"},"named":true,"value":"c_prime"},{"type":"SYMBOL","name":"_c"},{"type":"STRING","value":";"}]},"_a":{"type":"SYMBOL","name":"_A"},"_b":{"type":"SYMBOL","name":"_B"},"_c":{"type":"SYMBOL","name":"_C"},"_A":{"type":"SYMBOL","name":"identifier"},"_B":{"type":"SYMBOL","name":"identifier"},"_C":{"type":"SYMBOL","name":"identifier"},"identifier":{"type":"PATTERN","value":"[a-z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|==========================================
          #|Aliases on rules that are unit reductions
          #|==========================================
          #|
          #|one two three four;
          #|
          #|---
          #|
          #|(statement
          #|  (identifier)
          #|  (b_prime (identifier))
          #|  (c_prime (identifier))
          #|  (identifier))
        ),
      ),
      expected_error: None,
    },
    {
      name: "aliases_in_root",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/aliases_in_root",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"aliases_in_root","rules":{"document":{"type":"SEQ","members":[{"type":"ALIAS","content":{"type":"SYMBOL","name":"foo"},"named":true,"value":"bar"},{"type":"SYMBOL","name":"foo"}]},"foo":{"type":"STRING","value":"foo"},"comment":{"type":"PATTERN","value":"#.*"}},"extras":[{"type":"PATTERN","value":"\\s"},{"type":"SYMBOL","name":"comment"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|======================================
          #|Aliases within the root node
          #|======================================
          #|
          #|# this is a comment
          #|foo foo
          #|
          #|---
          #|
          #|(document
          #|  (comment)
          #|  (bar)
          #|  (foo))
        ),
      ),
      expected_error: None,
    },
    {
      name: "anonymous_error",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/anonymous_error",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"anonymous_error","rules":{"document":{"type":"REPEAT","content":{"type":"CHOICE","members":[{"type":"STRING","value":"ok"},{"type":"STRING","value":"ERROR"}]}}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|======================
          #|A simple error literal
          #|======================
          #|
          #|ERROR
          #|
          #|---
          #|
          #|(document)
        ),
      ),
      expected_error: None,
    },
    {
      name: "anonymous_tokens_with_escaped_chars",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/anonymous_tokens_with_escaped_chars",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"anonymous_tokens_with_escaped_chars","rules":{"first_rule":{"type":"CHOICE","members":[{"type":"STRING","value":"\n"},{"type":"STRING","value":"\r\n"},{"type":"STRING","value":"'hello'"},{"type":"PATTERN","value":"\\d+"}]}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|================================================
          #|anonymous tokens defined with character classes
          #|================================================
          #|1234
          #|---
          #|
          #|(first_rule)
          #|
          #|=================================================
          #|anonymous tokens defined with LF escape sequence
          #|=================================================
          #|
          #|
          #|---
          #|
          #|(first_rule)
          #|
          #|=================================================
          #|anonymous tokens defined with CR escape sequence
          #|=================================================
          #|
          #|
          #|---
          #|
          #|(first_rule)
          #|
          #|================================================
          #|anonymous tokens with quotes
          #|================================================
          #|'hello'
          #|---
          #|
          #|(first_rule)
        ),
      ),
      expected_error: None,
    },
    {
      name: "associativity_left",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/associativity_left",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"associativity_left","rules":{"expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"math_operation"},{"type":"SYMBOL","name":"identifier"}]},"math_operation":{"type":"PREC_LEFT","value":0,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"+"},{"type":"SYMBOL","name":"expression"}]}},"identifier":{"type":"PATTERN","value":"[a-z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|===================
          #|chained operations
          #|===================
          #|x+y+z
          #|---
          #|(expression (math_operation
          #|  (expression (math_operation (expression (identifier)) (expression (identifier))))
          #|  (expression (identifier))))
        ),
      ),
      expected_error: None,
    },
    {
      name: "associativity_right",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/associativity_right",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"associativity_right","rules":{"expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"math_operation"},{"type":"SYMBOL","name":"identifier"}]},"math_operation":{"type":"PREC_RIGHT","value":0,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"+"},{"type":"SYMBOL","name":"expression"}]}},"identifier":{"type":"PATTERN","value":"[a-z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|===================
          #|chained operations
          #|===================
          #|x+y+z
          #|---
          #|(expression (math_operation
          #|  (expression (identifier))
          #|  (expression (math_operation (expression (identifier)) (expression (identifier))))))
        ),
      ),
      expected_error: None,
    },
    {
      name: "dynamic_precedence",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/dynamic_precedence",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"dynamic_precedence","rules":{"program":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"declaration"},{"type":"SYMBOL","name":"expression"}]},"expression":{"type":"CHOICE","members":[{"type":"PREC_LEFT","value":0,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"*"},{"type":"SYMBOL","name":"expression"}]}},{"type":"SYMBOL","name":"identifier"}]},"declaration":{"type":"SEQ","members":[{"type":"SYMBOL","name":"type"},{"type":"SYMBOL","name":"declarator"}]},"declarator":{"type":"CHOICE","members":[{"type":"PREC_DYNAMIC","value":1,"content":{"type":"SEQ","members":[{"type":"STRING","value":"*"},{"type":"SYMBOL","name":"identifier"}]}},{"type":"SYMBOL","name":"identifier"}]},"type":{"type":"SYMBOL","name":"identifier"},"identifier":{"type":"PATTERN","value":"[a-z-A-Z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[["expression","type"]],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|===============================
          #|Declarations
          #|===============================
          #|
          #|T * x
          #|
          #|---
          #|
          #|(program (declaration
          #|  (type (identifier))
          #|  (declarator (identifier))))
          #|
          #|===============================
          #|Expressions
          #|===============================
          #|
          #|w * x * y
          #|
          #|---
          #|
          #|(program (expression
          #|  (expression
          #|    (expression (identifier))
          #|    (expression (identifier)))
          #|  (expression (identifier))))
        ),
      ),
      expected_error: None,
    },
    {
      name: "extra_non_terminals",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/extra_non_terminals",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"extra_non_terminals","rules":{"module":{"type":"SEQ","members":[{"type":"STRING","value":"a"},{"type":"STRING","value":"b"},{"type":"STRING","value":"c"},{"type":"STRING","value":"d"}]},"comment":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"paren_comment"},{"type":"SYMBOL","name":"line_comment"}]},"paren_comment":{"type":"TOKEN","content":{"type":"SEQ","members":[{"type":"STRING","value":"("},{"type":"REPEAT","content":{"type":"PATTERN","value":"[a-z]+"}},{"type":"STRING","value":")"}]}},"line_comment":{"type":"TOKEN","content":{"type":"SEQ","members":[{"type":"STRING","value":"//"},{"type":"PATTERN","value":".*"}]}}},"extras":[{"type":"PATTERN","value":"\\s"},{"type":"SYMBOL","name":"comment"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|==============
          #|No extras
          #|==============
          #|
          #|a b c d
          #|
          #|---
          #|
          #|(module)
          #|
          #|==============
          #|Extras
          #|==============
          #|
          #|a (one) b (two) (three) c d // e
          #|
          #|---
          #|
          #|(module
          #|  (comment (paren_comment))
          #|  (comment (paren_comment))
          #|  (comment (paren_comment))
          #|  (comment (line_comment)))
        ),
      ),
      expected_error: None,
    },
    {
      name: "extra_non_terminals_with_shared_rules",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/extra_non_terminals_with_shared_rules",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"extra_non_terminals_with_shared_rules","rules":{"program":{"type":"REPEAT","content":{"type":"SYMBOL","name":"statement"}},"statement":{"type":"SEQ","members":[{"type":"REPEAT","content":{"type":"SYMBOL","name":"label_declaration"}},{"type":"STRING","value":";"}]},"macro_statement":{"type":"SEQ","members":[{"type":"STRING","value":"%"},{"type":"SYMBOL","name":"statement"}]},"label_declaration":{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"STRING","value":":"}]},"identifier":{"type":"PATTERN","value":"[a-zA-Z]+"}},"extras":[{"type":"PATTERN","value":"\\s+"},{"type":"SYMBOL","name":"macro_statement"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|=====
          #|Extras
          #|=====
          #|
          #|;
          #|%;
          #|%foo:;
          #|;
          #|bar: baz:;
          #|;
          #|
          #|---
          #|
          #|(program
          #|  (statement)
          #|  (macro_statement (statement))
          #|  (macro_statement (statement
          #|    (label_declaration (identifier))))
          #|  (statement)
          #|  (statement
          #|    (label_declaration (identifier))
          #|    (label_declaration (identifier)))
          #|  (statement))
        ),
      ),
      expected_error: None,
    },
    {
      name: "immediate_tokens",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/immediate_tokens",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"immediate_tokens","rules":{"program":{"type":"SYMBOL","name":"_expression"},"_expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"call"},{"type":"SYMBOL","name":"infix"},{"type":"SYMBOL","name":"prefix"},{"type":"SYMBOL","name":"identifier"}]},"call":{"type":"PREC_LEFT","value":-1,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"_expression"},{"type":"SYMBOL","name":"_expression"}]}},"prefix":{"type":"SEQ","members":[{"type":"STRING","value":"::"},{"type":"SYMBOL","name":"identifier"}]},"infix":{"type":"SEQ","members":[{"type":"SYMBOL","name":"_expression"},{"type":"IMMEDIATE_TOKEN","content":{"type":"STRING","value":"::"}},{"type":"SYMBOL","name":"identifier"}]},"identifier":{"type":"PATTERN","value":"[a-z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|===============================
          #|prefix expressions as arguments
          #|===============================
          #|
          #|a ::b ::c
          #|
          #|---
          #|
          #|(program
          #|  (call
          #|    (call
          #|      (identifier)
          #|      (prefix (identifier)))
          #|    (prefix (identifier))))
          #|
          #|===============================
          #|infix expressions
          #|===============================
          #|
          #|a::b::c
          #|
          #|---
          #|
          #|(program
          #|  (infix
          #|    (infix
          #|      (identifier)
          #|      (identifier))
          #|    (identifier)))
        ),
      ),
      expected_error: None,
    },
    {
      name: "inline_rules",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/inline_rules",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"inline_rules","rules":{"program":{"type":"REPEAT1","content":{"type":"SYMBOL","name":"statement"}},"statement":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":";"}]},"expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"sum"},{"type":"SYMBOL","name":"product"},{"type":"SYMBOL","name":"number"},{"type":"SYMBOL","name":"parenthesized_expression"}]},"parenthesized_expression":{"type":"SEQ","members":[{"type":"STRING","value":"("},{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":")"}]},"sum":{"type":"PREC_LEFT","value":0,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"+"},{"type":"SYMBOL","name":"expression"}]}},"product":{"type":"PREC_LEFT","value":2,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"*"},{"type":"SYMBOL","name":"expression"}]}},"number":{"type":"PATTERN","value":"\\d+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":["expression"],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|==================================
          #|Expressions
          #|==================================
          #|
          #|1 + 2 * 3;
          #|4 * 5 + 6;
          #|7 * (8 + 9);
          #|
          #|---
          #|
          #|(program
          #|  (statement (sum
          #|    (number)
          #|    (product (number) (number))))
          #|  (statement (sum
          #|    (product (number) (number))
          #|    (number)))
          #|  (statement (product
          #|    (number)
          #|    (parenthesized_expression (sum (number) (number))))))
        ),
      ),
      expected_error: None,
    },
    {
      name: "inlined_aliased_rules",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/inlined_aliased_rules",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"inlined_aliased_rules","rules":{"statement":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":";"}]},"expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"call_expression"},{"type":"SYMBOL","name":"member_expression"},{"type":"ALIAS","content":{"type":"SYMBOL","name":"identifier"},"named":true,"value":"variable_name"}]},"call_expression":{"type":"PREC_LEFT","value":0,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"("},{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":")"}]}},"member_expression":{"type":"PREC_LEFT","value":1,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"."},{"type":"ALIAS","content":{"type":"SYMBOL","name":"identifier"},"named":true,"value":"property_name"}]}},"identifier":{"type":"PATTERN","value":"[a-z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":["expression"],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|======================================
          #|Method calls
          #|======================================
          #|
          #|a.b(c(d.e));
          #|
          #|---
          #|
          #|(statement
          #|  (call_expression
          #|    (member_expression
          #|      (variable_name)
          #|      (property_name))
          #|    (call_expression
          #|      (variable_name)
          #|      (member_expression
          #|        (variable_name)
          #|        (property_name)))))
        ),
      ),
      expected_error: None,
    },
    {
      name: "lexical_conflicts_due_to_state_merging",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/lexical_conflicts_due_to_state_merging",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"lexical_conflicts_due_to_state_merging","rules":{"expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"conditional"},{"type":"SYMBOL","name":"quotient"},{"type":"SYMBOL","name":"regex"},{"type":"SYMBOL","name":"number"},{"type":"SYMBOL","name":"parenthesized"}]},"conditional":{"type":"PREC_LEFT","value":1,"content":{"type":"SEQ","members":[{"type":"STRING","value":"if"},{"type":"SYMBOL","name":"parenthesized"},{"type":"SYMBOL","name":"expression"}]}},"quotient":{"type":"PREC_LEFT","value":0,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"/"},{"type":"SYMBOL","name":"expression"}]}},"regex":{"type":"PATTERN","value":"\\/[^/\\n]+\\/"},"number":{"type":"PATTERN","value":"\\d+"},"parenthesized":{"type":"SEQ","members":[{"type":"STRING","value":"("},{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":")"}]}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|========================
          #|regexes
          #|========================
          #|
          #|/a+/
          #|
          #|---
          #|
          #|(expression (regex))
          #|
          #|========================
          #|conditionals
          #|========================
          #|
          #|(if (1) /a+/)
          #|
          #|---
          #|
          #|(expression (parenthesized (expression (conditional
          #|  (parenthesized (expression (number)))
          #|  (expression (regex))))))
          #|
          #|========================
          #|quotients
          #|========================
          #|
          #|((1) / 2)
          #|
          #|---
          #|
          #|(expression (parenthesized (expression (quotient
          #|  (expression (parenthesized (expression (number))))
          #|  (expression (number))))))
        ),
      ),
      expected_error: None,
    },
    {
      name: "named_precedences",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/named_precedences",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"named_precedences","rules":{"program":{"type":"REPEAT","content":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"expression_statement"},{"type":"SYMBOL","name":"declaration_statement"}]}},"expression_statement":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":";"}]},"declaration_statement":{"type":"SEQ","members":[{"type":"SYMBOL","name":"type"},{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":";"}]},"expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"member_expression"},{"type":"SYMBOL","name":"binary_expression"},{"type":"SYMBOL","name":"identifier"}]},"member_expression":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"."},{"type":"SYMBOL","name":"identifier"}]},"binary_expression":{"type":"CHOICE","members":[{"type":"PREC_LEFT","value":"or","content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"||"},{"type":"SYMBOL","name":"expression"}]}},{"type":"PREC_LEFT","value":"and","content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"&&"},{"type":"SYMBOL","name":"expression"}]}}]},"type":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"nested_type"},{"type":"SYMBOL","name":"binary_type"},{"type":"SYMBOL","name":"identifier"}]},"nested_type":{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"STRING","value":"."},{"type":"SYMBOL","name":"identifier"}]},"binary_type":{"type":"CHOICE","members":[{"type":"PREC_LEFT","value":"type_union","content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"type"},{"type":"STRING","value":"||"},{"type":"SYMBOL","name":"type"}]}},{"type":"PREC_LEFT","value":"type_intersection","content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"type"},{"type":"STRING","value":"&&"},{"type":"SYMBOL","name":"type"}]}}]},"identifier":{"type":"PATTERN","value":"[a-z]\\w+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[["expression","type"],["expression","nested_type"]],"precedences":[[{"type":"SYMBOL","name":"member_expression"},{"type":"STRING","value":"and"},{"type":"STRING","value":"or"}],[{"type":"SYMBOL","name":"nested_type"},{"type":"STRING","value":"type_intersection"},{"type":"STRING","value":"type_union"}]],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|=============
          #|Declarations
          #|=============
          #|
          #|A||B c = d;
          #|E.F g = h;
          #|
          #|=============
          #|Expressions
          #|=============
          #|
          #|a || b.c;
        ),
      ),
      expected_error: None,
    },
    {
      name: "named_rule_aliased_as_anonymous",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/named_rule_aliased_as_anonymous",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"named_rule_aliased_as_anonymous","rules":{"a":{"type":"SEQ","members":[{"type":"ALIAS","content":{"type":"SYMBOL","name":"b"},"named":false,"value":"the-alias"},{"type":"SYMBOL","name":"c"},{"type":"SYMBOL","name":"b"}]},"b":{"type":"STRING","value":"B"},"c":{"type":"STRING","value":"C"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|================================================
          #|Named rules that are aliased as anonymous tokens
          #|================================================
          #|
          #|B C B
          #|
          #|---
          #|
          #|(a (c) (b))
        ),
      ),
      expected_error: None,
    },
    {
      name: "nested_inlined_rules",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/nested_inlined_rules",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"nested_inlined_rules","rules":{"program":{"type":"REPEAT1","content":{"type":"SYMBOL","name":"top_level_item"}},"top_level_item":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"statement"},{"type":"STRING","value":"!"}]},"statement":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"expression_statement"},{"type":"SYMBOL","name":"return_statement"}]},"return_statement":{"type":"SEQ","members":[{"type":"STRING","value":"return"},{"type":"SYMBOL","name":"number"},{"type":"STRING","value":";"}]},"expression_statement":{"type":"SEQ","members":[{"type":"SYMBOL","name":"number"},{"type":"STRING","value":";"}]},"number":{"type":"PATTERN","value":"\\d+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":["top_level_item","statement"],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|==================================
          #|Statements
          #|==================================
          #|
          #|return 1;
          #|return 2;
          #|
          #|---
          #|
          #|(program
          #|  (return_statement (number))
          #|  (return_statement (number)))
        ),
      ),
      expected_error: None,
    },
    {
      name: "next_sibling_from_zwt",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/next_sibling_from_zwt",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"next_sibling_from_zwt","rules":{"source":{"type":"SEQ","members":[{"type":"STRING","value":"a"},{"type":"SYMBOL","name":"_bc"},{"type":"STRING","value":"d"},{"type":"STRING","value":"e"},{"type":"STRING","value":"f"}]},"_bc":{"type":"SEQ","members":[{"type":"STRING","value":"b"},{"type":"STRING","value":"c"}]}},"extras":[{"type":"PATTERN","value":"\\s|\\\\\\r?\\n"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|===========================
          #|missing c node
          #|===========================
          #|
          #|abdef
          #|
          #|---
          #|
          #|(source
          #|    (MISSING "c"))
        ),
      ),
      expected_error: None,
    },
    {
      name: "precedence_on_single_child_negative",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/precedence_on_single_child_negative",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"precedence_on_single_child_negative","rules":{"expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"function_call"},{"type":"SYMBOL","name":"identifier"}]},"function_call":{"type":"PREC_RIGHT","value":-1,"content":{"type":"CHOICE","members":[{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"expression"}]},{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"block"}]},{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"expression"},{"type":"SYMBOL","name":"block"}]}]}},"block":{"type":"SEQ","members":[{"type":"STRING","value":"{"},{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"}"}]},"identifier":{"type":"PATTERN","value":"[a-zA-Z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|===========================
          #|function calls with blocks
          #|===========================
          #|
          #|foo bar { baz }
          #|
          #|---
          #|
          #|(expression (function_call
          #|  (identifier)
          #|  (expression (identifier))
          #|  (block (expression (identifier)))))
        ),
      ),
      expected_error: None,
    },
    {
      name: "precedence_on_single_child_positive",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/precedence_on_single_child_positive",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"precedence_on_single_child_positive","rules":{"expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"function_call"},{"type":"SYMBOL","name":"identifier"}]},"function_call":{"type":"PREC_RIGHT","value":1,"content":{"type":"CHOICE","members":[{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"expression"}]},{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"block"}]},{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"expression"},{"type":"SYMBOL","name":"block"}]}]}},"block":{"type":"SEQ","members":[{"type":"STRING","value":"{"},{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"}"}]},"identifier":{"type":"PATTERN","value":"[a-zA-X]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|===========================
          #|function calls with blocks
          #|===========================
          #|
          #|foo bar { baz }
          #|
          #|---
          #|
          #|(expression (function_call
          #|  (identifier)
          #|  (expression (function_call
          #|    (identifier)
          #|    (block (expression (identifier)))))))
        ),
      ),
      expected_error: None,
    },
    {
      name: "precedence_on_subsequence",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/precedence_on_subsequence",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"precedence_on_subsequence","rules":{"expression":{"type":"PREC_LEFT","value":0,"content":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"function_call"},{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"scope_resolution"}]}},"function_call":{"type":"CHOICE","members":[{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"expression"}]},{"type":"PREC","value":1,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"block"}]}},{"type":"PREC","value":-1,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"do_block"}]}},{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"PREC","value":1,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"SYMBOL","name":"block"}]}}]},{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"PREC","value":-1,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"SYMBOL","name":"do_block"}]}}]}]},"scope_resolution":{"type":"PREC_LEFT","value":1,"content":{"type":"CHOICE","members":[{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"::"},{"type":"SYMBOL","name":"expression"}]},{"type":"SEQ","members":[{"type":"STRING","value":"::"},{"type":"SYMBOL","name":"expression"}]}]}},"block":{"type":"STRING","value":"{}"},"do_block":{"type":"STRING","value":"do end"},"identifier":{"type":"PATTERN","value":"[a-zA-Z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|==========================================
          #|curly brace blocks with high precedence
          #|==========================================
          #|
          #|a b {}
          #|
          #|---
          #|
          #|(expression (function_call
          #|  (identifier)
          #|  (expression (function_call (identifier) (block)))))
          #|
          #|==========================================
          #|do blocks with low precedence
          #|==========================================
          #|
          #|a b do end
          #|
          #|---
          #|
          #|(expression (function_call
          #|  (identifier)
          #|  (expression (identifier))
          #|  (do_block)))
        ),
      ),
      expected_error: None,
    },
    {
      name: "precedence_on_token",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/precedence_on_token",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"precedence_on_token","rules":{"program":{"type":"REPEAT","content":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"string"},{"type":"SYMBOL","name":"regex"},{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"slash"}]}},"comment":{"type":"TOKEN","content":{"type":"PREC","value":1,"content":{"type":"PATTERN","value":"\\/\\/.*|\\/\\*[^*]*\\*\\/"}}},"string":{"type":"SEQ","members":[{"type":"STRING","value":"\""},{"type":"REPEAT","content":{"type":"CHOICE","members":[{"type":"TOKEN","content":{"type":"PREC","value":2,"content":{"type":"PATTERN","value":"[^\\\"\\n\\\\]+"}}},{"type":"SYMBOL","name":"escape_sequence"}]}},{"type":"STRING","value":"\""}]},"escape_sequence":{"type":"PATTERN","value":"\\\\."},"regex":{"type":"PATTERN","value":"\\/[^\\/\\n]+\\/[a-z]*"},"identifier":{"type":"PATTERN","value":"[a-z]\\w*"},"slash":{"type":"STRING","value":"/"}},"extras":[{"type":"PATTERN","value":"\\s"},{"type":"SYMBOL","name":"comment"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|==========================================
          #|obvious tokens
          #|==========================================
          #|
          #|// hi
          #|/* hi */
          #|hi
          #|/
          #|"hi"
          #|/hi/
          #|
          #|---
          #|
          #|(program
          #|  (comment)
          #|  (comment)
          #|  (identifier)
          #|  (slash)
          #|  (string)
          #|  (regex))
          #|
          #|==========================================
          #|strings starting with double slashes
          #|==========================================
          #|
          #|/*
          #|The lexer matches the string content correctly even though
          #|a comment could match all the way until the end of the line,
          #|because the string content token has a higher precedence
          #|than the comment token.
          #|*/
          #|
          #|"//one\n//two"
          #|
          #|---
          #|
          #|(program
          #|  (comment)
          #|  (string (escape_sequence)))
          #|
          #|==========================================
          #|comments that resemble regexes
          #|==========================================
          #|
          #|/*
          #|The lexer matches this as a comment followed by an identifier
          #|even though a regex token could match the entire thing, because
          #|the comment token has a higher precedence than the regex token
          #|*/
          #|
          #|/* hello */ui
          #|
          #|---
          #|
          #|(program
          #|  (comment)
          #|  (comment)
          #|  (identifier))
        ),
      ),
      expected_error: None,
    },
    {
      name: "readme_grammar",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/readme_grammar",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"readme_grammar","rules":{"expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"sum"},{"type":"SYMBOL","name":"product"},{"type":"SYMBOL","name":"number"},{"type":"SYMBOL","name":"variable"},{"type":"SEQ","members":[{"type":"STRING","value":"("},{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":")"}]}]},"sum":{"type":"PREC_LEFT","value":1,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"+"},{"type":"SYMBOL","name":"expression"}]}},"product":{"type":"PREC_LEFT","value":2,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"*"},{"type":"SYMBOL","name":"expression"}]}},"number":{"type":"PATTERN","value":"\\d+"},"comment":{"type":"PATTERN","value":"#.*"},"variable":{"type":"PATTERN","value":"(?i:[a-z])\\w*"}},"extras":[{"type":"PATTERN","value":"\\s"},{"type":"SYMBOL","name":"comment"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|==================================
          #|the readme example
          #|==================================
          #|
          #|a + b * c
          #|
          #|---
          #|
          #|(expression (sum
          #|  (expression (variable))
          #|  (expression (product
          #|     (expression (variable))
          #|     (expression (variable))))))
        ),
      ),
      expected_error: None,
    },
    {
      name: "reserved_words",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/reserved_words",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"reserved_words","word":"identifier","rules":{"program":{"type":"REPEAT","content":{"type":"SYMBOL","name":"_statement"}},"block":{"type":"SEQ","members":[{"type":"STRING","value":"{"},{"type":"REPEAT","content":{"type":"SYMBOL","name":"_statement"}},{"type":"STRING","value":"}"}]},"_statement":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"var_declaration"},{"type":"SYMBOL","name":"if_statement"},{"type":"SYMBOL","name":"while_statement"},{"type":"SYMBOL","name":"expression_statement"}]},"var_declaration":{"type":"SEQ","members":[{"type":"STRING","value":"var"},{"type":"SYMBOL","name":"identifier"},{"type":"STRING","value":"="},{"type":"SYMBOL","name":"_expression"},{"type":"STRING","value":";"}]},"if_statement":{"type":"SEQ","members":[{"type":"STRING","value":"if"},{"type":"SYMBOL","name":"parenthesized_expression"},{"type":"SYMBOL","name":"block"}]},"while_statement":{"type":"SEQ","members":[{"type":"STRING","value":"while"},{"type":"SYMBOL","name":"parenthesized_expression"},{"type":"SYMBOL","name":"block"}]},"expression_statement":{"type":"SEQ","members":[{"type":"SYMBOL","name":"_expression"},{"type":"STRING","value":";"}]},"_expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"parenthesized_expression"},{"type":"SYMBOL","name":"call_expression"},{"type":"SYMBOL","name":"member_expression"},{"type":"SYMBOL","name":"object"},{"type":"SYMBOL","name":"regex"}]},"parenthesized_expression":{"type":"SEQ","members":[{"type":"STRING","value":"("},{"type":"SYMBOL","name":"_expression"},{"type":"STRING","value":")"}]},"member_expression":{"type":"SEQ","members":[{"type":"SYMBOL","name":"_expression"},{"type":"STRING","value":"."},{"type":"SYMBOL","name":"identifier"}]},"call_expression":{"type":"SEQ","members":[{"type":"SYMBOL","name":"_expression"},{"type":"STRING","value":"("},{"type":"REPEAT","content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"_expression"},{"type":"STRING","value":","}]}},{"type":"STRING","value":")"}]},"object":{"type":"SEQ","members":[{"type":"STRING","value":"{"},{"type":"REPEAT","content":{"type":"SEQ","members":[{"type":"CHOICE","members":[{"type":"SYMBOL","name":"pair"},{"type":"SYMBOL","name":"getter"}]},{"type":"STRING","value":","}]}},{"type":"STRING","value":"}"}]},"regex":{"type":"SEQ","members":[{"type":"STRING","value":"/"},{"type":"SYMBOL","name":"regex_pattern"},{"type":"STRING","value":"/"}]},"regex_pattern":{"type":"TOKEN","content":{"type":"PREC","value":-1,"content":{"type":"PATTERN","value":"[^/\\n]+"}}},"pair":{"type":"SEQ","members":[{"type":"RESERVED","content":{"type":"SYMBOL","name":"identifier"},"context_name":"property"},{"type":"STRING","value":":"},{"type":"SYMBOL","name":"_expression"}]},"getter":{"type":"SEQ","members":[{"type":"STRING","value":"get"},{"type":"RESERVED","content":{"type":"SYMBOL","name":"identifier"},"context_name":"property"},{"type":"STRING","value":"("},{"type":"STRING","value":")"},{"type":"SYMBOL","name":"block"}]},"identifier":{"type":"PATTERN","value":"[a-z_]\\w*"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{"global":[{"type":"STRING","value":"if"},{"type":"STRING","value":"while"},{"type":"STRING","value":"var"}],"property":[{"type":"STRING","value":"var"}]}}
        ),
      ),
      corpus: Some(
        (
          #|==============
          #|Valid Code
          #|==============
          #|
          #|if (a) {
          #|  var b = {
          #|    c: d,
          #|    e: f,
          #|  };
          #|  while (g) {
          #|    h();
          #|  }
          #|}
          #|
          #|---
          #|
          #|(program
          #|  (if_statement
          #|    (parenthesized_expression (identifier))
          #|      (block
          #|        (var_declaration
          #|          (identifier)
          #|          (object
          #|            (pair (identifier) (identifier))
          #|            (pair (identifier) (identifier))))
          #|        (while_statement
          #|          (parenthesized_expression (identifier))
          #|          (block (expression_statement (call_expression (identifier))))))))
          #|
          #|================================================
          #|Error detected at globally-reserved word
          #|================================================
          #|
          #|var a =
          #|
          #|if (something) {
          #|  c();
          #|}
          #|
          #|---
          #|
          #|(program
          #|  (ERROR (identifier))
          #|  (if_statement
          #|    (parenthesized_expression (identifier))
          #|    (block
          #|      (expression_statement (call_expression (identifier))))))
          #|
          #|================================================
          #|Object keys that are reserved in other contexts
          #|================================================
          #|
          #|var x = {
          #|  if: a,
          #|  while: b,
          #|};
          #|
          #|---
          #|
          #|(program
          #|  (var_declaration
          #|    (identifier)
          #|    (object
          #|      (pair (identifier) (identifier))
          #|      (pair (identifier) (identifier)))))
          #|
          #|================================================
          #|Error detected at context-specific reserved word
          #|================================================
          #|
          #|var x = {
          #|var y = z;
          #|
          #|---
          #|
          #|(program
          #|  (ERROR (identifier))
          #|
          #|  ; Important - var declaration is still recognized,
          #|  ; because in this example grammar, `var` is a keyword
          #|  ; even within object literals.
          #|  (var_declaration
          #|    (identifier)
          #|    (identifier)))
          #|
          #|=============================================
          #|Other tokens that overlap with keyword tokens
          #|=============================================
          #|
          #|var a = /reserved-words-should-not-affect-this/;
          #|var d = /if/;
          #|
          #|---
          #|
          #|(program
          #|  (var_declaration
          #|    (identifier)
          #|    (regex (regex_pattern)))
          #|  (var_declaration
          #|    (identifier)
          #|    (regex (regex_pattern))))
        ),
      ),
      expected_error: None,
    },
    {
      name: "start_rule_is_blank",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/start_rule_is_blank",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"start_rule_is_blank","rules":{"first_rule":{"type":"BLANK"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|========================
          #|the empty string
          #|=======================
          #|
          #|---
          #|
          #|(first_rule)
        ),
      ),
      expected_error: None,
    },
    {
      name: "start_rule_is_token",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/start_rule_is_token",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"start_rule_is_token","rules":{"first_rule":{"type":"STRING","value":"the-value"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|===========================
          #|the single token
          #|==========================
          #|the-value
          #|---
          #|(first_rule)
        ),
      ),
      expected_error: None,
    },
    {
      name: "unicode_classes",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/unicode_classes",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"unicode_classes","rules":{"program":{"type":"REPEAT","content":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"lower"},{"type":"SYMBOL","name":"upper"},{"type":"SYMBOL","name":"math_sym"},{"type":"SYMBOL","name":"letter_number"}]}},"lower":{"type":"PATTERN","value":"\\p{Ll}\\p{L}*"},"upper":{"type":"PATTERN","value":"\\p{Lu}\\p{L}*"},"math_sym":{"type":"PATTERN","value":"\\p{Sm}+"},"letter_number":{"type":"PATTERN","value":"\\p{Letter_Number}"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|===============
          #|Uppercase words
          #|===============
          #|
          #|Δბㄱ  Ψ  Ɓƀ  Ƒ  Ɣ  Śřř
          #|
          #|---
          #|
          #|(program
          #|  (upper) (upper) (upper) (upper) (upper) (upper))
          #|
          #|================
          #|Lowercase words
          #|================
          #|
          #|śś  ťť  ßß
          #|
          #|---
          #|
          #|(program
          #|  (lower) (lower) (lower))
          #|
          #|================
          #|Math symbols
          #|================
          #|
          #|≺ ≼ ≠ ≝ ⨔∑
          #|
          #|---
          #|
          #|(program
          #|  (math_sym) (math_sym) (math_sym) (math_sym) (math_sym))
          #|
          #|================================
          #|Letterlike numeric characters
          #|================================
          #|
          #|ᛯ Ⅵ 〩
          #|
          #|---
          #|
          #|(program
          #|  (letter_number) (letter_number) (letter_number))
        ),
      ),
      expected_error: None,
    },
    {
      name: "unused_rules",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/unused_rules",
      status: RunnableCorpus,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"unused_rules","rules":{"a":{"type":"SEQ","members":[{"type":"SYMBOL","name":"d"},{"type":"SYMBOL","name":"h"}]},"b":{"type":"STRING","value":"B"},"c":{"type":"STRING","value":"C"},"d":{"type":"SEQ","members":[{"type":"SYMBOL","name":"e"},{"type":"SYMBOL","name":"f"}]},"e":{"type":"STRING","value":"E"},"f":{"type":"STRING","value":"F"},"g":{"type":"STRING","value":"G"},"h":{"type":"SEQ","members":[{"type":"SYMBOL","name":"i"},{"type":"SYMBOL","name":"j"}]},"i":{"type":"STRING","value":"I"},"j":{"type":"STRING","value":"J"},"k":{"type":"STRING","value":"K"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: Some(
        (
          #|=========================
          #|the language
          #|=========================
          #|
          #|E F I J
          #|
          #|---
          #|
          #|(a (d (e) (f)) (h (i) (j)))
        ),
      ),
      expected_error: None,
    },
    {
      name: "associativity_missing",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/associativity_missing",
      status: ExpectedGenerateError,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"associativity_missing","rules":{"expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"math_operation"},{"type":"SYMBOL","name":"identifier"}]},"math_operation":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"+"},{"type":"SYMBOL","name":"expression"}]},"identifier":{"type":"PATTERN","value":"[a-z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: None,
      expected_error: Some({
        category: "InvalidGrammar",
        message_fragments: ["unresolved conflict"],
        upstream_expected_error: (
          #|Unresolved conflict for symbol sequence:
          #|
          #|  expression  '+'  expression  •  '+'  …
          #|
          #|Possible interpretations:
          #|
          #|  1:  (math_operation  expression  '+'  expression)  •  '+'  …
          #|  2:  expression  '+'  (math_operation  expression  •  '+'  expression)
          #|
          #|Possible resolutions:
          #|
          #|  1:  Specify a left or right associativity in `math_operation`
          #|  2:  Add a conflict for these rules: `math_operation`
        ),
      }),
    },
    {
      name: "conflict_in_repeat_rule",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/conflict_in_repeat_rule",
      status: ExpectedGenerateError,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"conflict_in_repeat_rule","rules":{"statement":{"type":"CHOICE","members":[{"type":"SEQ","members":[{"type":"SYMBOL","name":"array"},{"type":"STRING","value":";"}]},{"type":"SEQ","members":[{"type":"SYMBOL","name":"array_type"},{"type":"SYMBOL","name":"identifier"},{"type":"STRING","value":";"}]}]},"array":{"type":"SEQ","members":[{"type":"STRING","value":"["},{"type":"REPEAT","content":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"identifier"},{"type":"STRING","value":"0"}]}},{"type":"STRING","value":"]"}]},"array_type":{"type":"SEQ","members":[{"type":"STRING","value":"["},{"type":"REPEAT","content":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"identifier"},{"type":"STRING","value":"void"}]}},{"type":"STRING","value":"]"}]},"identifier":{"type":"PATTERN","value":"[a-z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: None,
      expected_error: Some({
        category: "InvalidGrammar",
        message_fragments: ["unresolved conflict"],
        upstream_expected_error: (
          #|Unresolved conflict for symbol sequence:
          #|
          #|  '['  identifier  •  ']'  …
          #|
          #|Possible interpretations:
          #|
          #|  1:  '['  (array_repeat1  identifier)  •  ']'  …
          #|  2:  '['  (array_type_repeat1  identifier)  •  ']'  …
          #|
          #|Possible resolutions:
          #|
          #|  1:  Specify a higher precedence in `array_repeat1` than in the other rules.
          #|  2:  Specify a higher precedence in `array_type_repeat1` than in the other rules.
          #|  3:  Add a conflict for these rules: `array`, `array_type`
        ),
      }),
    },
    {
      name: "conflict_in_repeat_rule_after_external_token",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/conflict_in_repeat_rule_after_external_token",
      status: ExpectedGenerateError,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"conflict_in_repeat_rule_after_external_token","rules":{"statement":{"type":"CHOICE","members":[{"type":"SEQ","members":[{"type":"SYMBOL","name":"_program_start"},{"type":"SYMBOL","name":"array"},{"type":"STRING","value":";"}]},{"type":"SEQ","members":[{"type":"SYMBOL","name":"_program_start"},{"type":"SYMBOL","name":"array_type"},{"type":"SYMBOL","name":"identifier"},{"type":"STRING","value":";"}]}]},"array":{"type":"SEQ","members":[{"type":"STRING","value":"["},{"type":"REPEAT","content":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"identifier"},{"type":"STRING","value":"0"}]}},{"type":"STRING","value":"]"}]},"array_type":{"type":"SEQ","members":[{"type":"STRING","value":"["},{"type":"REPEAT","content":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"identifier"},{"type":"STRING","value":"void"}]}},{"type":"STRING","value":"]"}]},"identifier":{"type":"PATTERN","value":"[a-z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[{"type":"SYMBOL","name":"_program_start"}],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: None,
      expected_error: Some({
        category: "InvalidGrammar",
        message_fragments: ["unresolved conflict"],
        upstream_expected_error: (
          #|Unresolved conflict for symbol sequence:
          #|
          #|  _program_start  '['  identifier  •  ']'  …
          #|
          #|Possible interpretations:
          #|
          #|  1:  _program_start  '['  (array_repeat1  identifier)  •  ']'  …
          #|  2:  _program_start  '['  (array_type_repeat1  identifier)  •  ']'  …
          #|
          #|Possible resolutions:
          #|
          #|  1:  Specify a higher precedence in `array_repeat1` than in the other rules.
          #|  2:  Specify a higher precedence in `array_type_repeat1` than in the other rules.
          #|  3:  Add a conflict for these rules: `array`, `array_type`
        ),
      }),
    },
    {
      name: "conflicting_precedence",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/conflicting_precedence",
      status: ExpectedGenerateError,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"conflicting_precedence","rules":{"expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"sum"},{"type":"SYMBOL","name":"product"},{"type":"SYMBOL","name":"other_thing"}]},"sum":{"type":"PREC_LEFT","value":0,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"+"},{"type":"SYMBOL","name":"expression"}]}},"product":{"type":"PREC_LEFT","value":1,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"*"},{"type":"SYMBOL","name":"expression"}]}},"other_thing":{"type":"PREC_LEFT","value":-1,"content":{"type":"SEQ","members":[{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"*"},{"type":"STRING","value":"*"}]}},"identifier":{"type":"PATTERN","value":"[a-zA-Z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: None,
      expected_error: Some({
        category: "InvalidGrammar",
        message_fragments: ["unresolved conflict"],
        upstream_expected_error: (
          #|Unresolved conflict for symbol sequence:
          #|
          #|  expression  '+'  expression  •  '*'  …
          #|
          #|Possible interpretations:
          #|
          #|  1:  (sum  expression  '+'  expression)  •  '*'  …               (precedence: 0, associativity: Left)
          #|  2:  expression  '+'  (other_thing  expression  •  '*'  '*')     (precedence: -1, associativity: Left)
          #|  3:  expression  '+'  (product  expression  •  '*'  expression)  (precedence: 1, associativity: Left)
          #|
          #|Possible resolutions:
          #|
          #|  1:  Specify a higher precedence in `product` and `other_thing` than in the other rules.
          #|  2:  Specify a higher precedence in `sum` than in the other rules.
          #|  3:  Add a conflict for these rules: `sum`, `product`, `other_thing`
        ),
      }),
    },
    {
      name: "epsilon_rules",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/epsilon_rules",
      status: ExpectedGenerateError,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"epsilon_rules","rules":{"rule_1":{"type":"SYMBOL","name":"rule_2"},"rule_2":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"rule_3"},{"type":"BLANK"}]},"rule_3":{"type":"STRING","value":"x"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: None,
      expected_error: Some({
        category: "InvalidGrammar",
        message_fragments: ["matches empty string"],
        upstream_expected_error: (
          #|The rule `rule_2` matches the empty string.
          #|
          #|Tree-sitter does not support syntactic rules that match the empty string
          #|unless they are used only as the grammar's start rule.
        ),
      }),
    },
    {
      name: "indirect_recursion_in_transitions",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/indirect_recursion_in_transitions",
      status: ExpectedGenerateError,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"indirect_recursive_in_single_symbol_transitions","rules":{"source_file":{"type":"REPEAT","content":{"type":"SYMBOL","name":"_statement"}},"_statement":{"type":"SEQ","members":[{"type":"SYMBOL","name":"initialization_part"},{"type":"SYMBOL","name":"type_expression"}]},"type_expression":{"type":"CHOICE","members":[{"type":"STRING","value":"int"},{"type":"SYMBOL","name":"_expression"}]},"initialization_part":{"type":"SEQ","members":[{"type":"STRING","value":"="},{"type":"SYMBOL","name":"_expression"}]},"_expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"identifier_expression"},{"type":"SYMBOL","name":"type_expression"}]},"identifier_expression":{"type":"CHOICE","members":[{"type":"PATTERN","value":"[a-zA-Z_][a-zA-Z0-9_]*"},{"type":"SYMBOL","name":"type_expression"}]}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: None,
      expected_error: Some({
        category: "IndirectRecursion",
        message_fragments: ["type_expression", "identifier_expression"],
        upstream_expected_error: (
          #|Grammar contains an indirectly recursive rule: type_expression -> _expression -> identifier_expression -> type_expression
        ),
      }),
    },
    {
      name: "invisible_start_rule",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/invisible_start_rule",
      status: ExpectedGenerateError,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"invisible_start_rule","rules":{"_value":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"a"},{"type":"SYMBOL","name":"b"}]},"a":{"type":"STRING","value":"a"},"b":{"type":"STRING","value":"b"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: None,
      expected_error: Some({
        category: "InvalidGrammar",
        message_fragments: ["start rule", "visible"],
        upstream_expected_error: (
          #|A grammar's start rule must be visible.
        ),
      }),
    },
    {
      name: "partially_resolved_conflict",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/partially_resolved_conflict",
      status: ExpectedGenerateError,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"partially_resolved_conflict","rules":{"expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"binary"},{"type":"SYMBOL","name":"identifier"}]},"unary_a":{"type":"PREC","value":2,"content":{"type":"SEQ","members":[{"type":"STRING","value":"!"},{"type":"SYMBOL","name":"expression"}]}},"unary_b":{"type":"PREC","value":2,"content":{"type":"SEQ","members":[{"type":"STRING","value":"!"},{"type":"SYMBOL","name":"expression"}]}},"binary":{"type":"SEQ","members":[{"type":"CHOICE","members":[{"type":"SYMBOL","name":"unary_a"},{"type":"SYMBOL","name":"unary_b"},{"type":"SYMBOL","name":"expression"}]},{"type":"STRING","value":"<"},{"type":"SYMBOL","name":"expression"}]},"identifier":{"type":"PATTERN","value":"[a-z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: None,
      expected_error: Some({
        category: "InvalidGrammar",
        message_fragments: ["unresolved conflict"],
        upstream_expected_error: (
          #|Unresolved conflict for symbol sequence:
          #|
          #|  '!'  expression  •  '<'  …
          #|
          #|Possible interpretations:
          #|
          #|  1:  (unary_a  '!'  expression)  •  '<'  …  (precedence: 2)
          #|  2:  (unary_b  '!'  expression)  •  '<'  …  (precedence: 2)
          #|
          #|Possible resolutions:
          #|
          #|  1:  Specify a higher precedence in `unary_a` than in the other rules.
          #|  2:  Specify a higher precedence in `unary_b` than in the other rules.
          #|  3:  Add a conflict for these rules: `unary_a`, `unary_b`
        ),
      }),
    },
    {
      name: "precedence_on_single_child_missing",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/precedence_on_single_child_missing",
      status: ExpectedGenerateError,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"precedence_on_single_child_missing","rules":{"expression":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"function_call"},{"type":"SYMBOL","name":"identifier"}]},"function_call":{"type":"PREC_RIGHT","value":0,"content":{"type":"CHOICE","members":[{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"expression"}]},{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"block"}]},{"type":"SEQ","members":[{"type":"SYMBOL","name":"identifier"},{"type":"SYMBOL","name":"expression"},{"type":"SYMBOL","name":"block"}]}]}},"block":{"type":"SEQ","members":[{"type":"STRING","value":"{"},{"type":"SYMBOL","name":"expression"},{"type":"STRING","value":"}"}]},"identifier":{"type":"PATTERN","value":"[a-zA-Z]+"}},"extras":[{"type":"PATTERN","value":"\\s"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":[],"reserved":{}}
        ),
      ),
      corpus: None,
      expected_error: Some({
        category: "InvalidGrammar",
        message_fragments: ["unresolved conflict"],
        upstream_expected_error: (
          #|Unresolved conflict for symbol sequence:
          #|
          #|  identifier  identifier  •  '{'  …
          #|
          #|Possible interpretations:
          #|
          #|  1:  identifier  (expression  identifier)  •  '{'  …
          #|  2:  identifier  (function_call  identifier  •  block)  (precedence: 0, associativity: Right)
          #|
          #|Possible resolutions:
          #|
          #|  1:  Specify a higher precedence in `function_call` than in the other rules.
          #|  2:  Specify a higher precedence in `expression` than in the other rules.
          #|  3:  Specify a left or right associativity in `expression`
          #|  4:  Add a conflict for these rules: `expression`, `function_call`
        ),
      }),
    },
    {
      name: "terminal_supertype",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/terminal_supertype",
      status: ExpectedGenerateError,
      grammar_json: Some(
        (
          #|{"$schema":"https://tree-sitter.github.io/tree-sitter/assets/schemas/grammar.schema.json","name":"terminal_supertype","rules":{"source_file":{"type":"CHOICE","members":[{"type":"SYMBOL","name":"B"},{"type":"SYMBOL","name":"A"}]},"lineComment":{"type":"PATTERN","value":";;.*"},"lineComment2":{"type":"PATTERN","value":"##.*"},"A":{"type":"PATTERN","value":"xyz"},"C":{"type":"STRING","value":"xyz"},"B":{"type":"SEQ","members":[{"type":"STRING","value":"abc"},{"type":"SYMBOL","name":"C"}]}},"extras":[{"type":"SYMBOL","name":"lineComment"},{"type":"SYMBOL","name":"lineComment2"}],"conflicts":[],"precedences":[],"externals":[],"inline":[],"supertypes":["A"],"reserved":{}}
        ),
      ),
      corpus: None,
      expected_error: Some({
        category: "TerminalSupertype",
        message_fragments: ["A"],
        upstream_expected_error: (
          #|Terminal rule 'A' cannot be used as a supertype
        ),
      }),
    },
    {
      name: "depends_on_column",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/depends_on_column",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "epsilon_external_extra_tokens",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/epsilon_external_extra_tokens",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "epsilon_external_tokens",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/epsilon_external_tokens",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "external_and_internal_anonymous_tokens",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/external_and_internal_anonymous_tokens",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "external_and_internal_tokens",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/external_and_internal_tokens",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "external_extra_tokens",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/external_extra_tokens",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "external_lookahead_eof_boundary",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/external_lookahead_eof_boundary",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "external_tokens",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/external_tokens",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "external_unicode_column_alignment",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/external_unicode_column_alignment",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "get_col_eof",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/get_col_eof",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "get_col_should_hang_not_crash",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/get_col_should_hang_not_crash",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "inverted_external_token",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/inverted_external_token",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "uses_current_column",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/uses_current_column",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "utf16_surrogate_oob",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/utf16_surrogate_oob",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "wasm_realloc_clobber_region",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/wasm_realloc_clobber_region",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
    {
      name: "wasm_realloc_overflow_heap",
      upstream_path: "../tree-sitter/test/fixtures/test_grammars/wasm_realloc_overflow_heap",
      status: UnsupportedExternalScanner,
      grammar_json: None,
      corpus: None,
      expected_error: None,
    },
  ]
}
