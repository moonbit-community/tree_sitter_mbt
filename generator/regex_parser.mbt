///|
priv enum RegexAst {
  RegexEmpty
  RegexLiteral(UInt)
  RegexClass(CharacterSet)
  RegexSeq(Array[RegexAst])
  RegexChoice(Array[RegexAst])
  RegexRepeat(content~ : RegexAst, min~ : Int, max~ : Int?)
}

///|
priv struct RegexParser {
  chars : Array[Char]
  mut index : Int
}

///|
fn parse_regex(pattern : String) -> Result[RegexAst, String] {
  let parser = RegexParser::new(pattern)
  match parser.parse_alternation(stop_on_paren=false) {
    Err(message) => Err(message)
    Ok(ast) =>
      if parser.is_eof() {
        Ok(ast)
      } else {
        Err("Unexpected character at index \{parser.index}")
      }
  }
}

///|
fn RegexParser::new(pattern : String) -> RegexParser {
  { chars: pattern.to_array(), index: 0 }
}

///|
fn RegexParser::is_eof(self : RegexParser) -> Bool {
  self.index >= self.chars.length()
}

///|
fn RegexParser::peek(self : RegexParser) -> Char? {
  if self.index < self.chars.length() {
    Some(self.chars[self.index])
  } else {
    None
  }
}

///|
fn RegexParser::peek_offset(self : RegexParser, offset : Int) -> Char? {
  let index = self.index + offset
  if index >= 0 && index < self.chars.length() {
    Some(self.chars[index])
  } else {
    None
  }
}

///|
fn RegexParser::advance(self : RegexParser) -> Char? {
  match self.peek() {
    Some(char) => {
      self.index += 1
      Some(char)
    }
    None => None
  }
}

///|
fn RegexParser::consume(self : RegexParser, expected : Char) -> Bool {
  match self.peek() {
    Some(char) =>
      if char == expected {
        self.index += 1
        true
      } else {
        false
      }
    None => false
  }
}

///|
fn RegexParser::starts_with_two(
  self : RegexParser,
  first : Char,
  second : Char,
) -> Bool {
  self.peek() == Some(first) && self.peek_offset(1) == Some(second)
}

///|
fn RegexParser::parse_alternation(
  self : RegexParser,
  stop_on_paren~ : Bool,
) -> Result[RegexAst, String] {
  let alternatives : Array[RegexAst] = []
  match self.parse_concat(stop_on_paren~) {
    Err(message) => return Err(message)
    Ok(ast) => alternatives.push(ast)
  }
  while self.consume('|') {
    match self.parse_concat(stop_on_paren~) {
      Err(message) => return Err(message)
      Ok(ast) => alternatives.push(ast)
    }
  }
  if alternatives.length() == 1 {
    Ok(alternatives[0])
  } else {
    Ok(RegexAst::RegexChoice(alternatives))
  }
}

///|
fn RegexParser::parse_concat(
  self : RegexParser,
  stop_on_paren~ : Bool,
) -> Result[RegexAst, String] {
  let items : Array[RegexAst] = []
  while !self.is_eof() {
    match self.peek() {
      Some('|') => break
      Some(')') =>
        if stop_on_paren {
          break
        } else {
          return Err("Unmatched ')' at index \{self.index}")
        }
      _ =>
        match self.parse_repetition() {
          Err(message) => return Err(message)
          Ok(ast) => items.push(ast)
        }
    }
  }
  if items.length() == 0 {
    Ok(RegexAst::RegexEmpty)
  } else if items.length() == 1 {
    Ok(items[0])
  } else {
    Ok(RegexAst::RegexSeq(items))
  }
}

///|
fn RegexParser::parse_repetition(
  self : RegexParser,
) -> Result[RegexAst, String] {
  match self.parse_atom() {
    Err(message) => Err(message)
    Ok(ast) =>
      match self.peek() {
        Some('*') => {
          let _ = self.advance()
          Ok(RegexAst::RegexRepeat(content=ast, min=0, max=None))
        }
        Some('+') => {
          let _ = self.advance()
          Ok(RegexAst::RegexRepeat(content=ast, min=1, max=None))
        }
        Some('?') => {
          let _ = self.advance()
          Ok(RegexAst::RegexRepeat(content=ast, min=0, max=Some(1)))
        }
        Some('{') => self.parse_bounded_repetition(ast)
        _ => Ok(ast)
      }
  }
}

///|
fn RegexParser::parse_bounded_repetition(
  self : RegexParser,
  ast : RegexAst,
) -> Result[RegexAst, String] {
  let _ = self.advance()
  match self.parse_decimal() {
    None => Err("Expected repetition lower bound at index \{self.index}")
    Some(minimum) => {
      let maximum = if self.consume(',') {
        match self.peek() {
          Some('}') => None
          _ =>
            match self.parse_decimal() {
              Some(value) => Some(value)
              None =>
                return Err(
                  "Expected repetition upper bound at index \{self.index}",
                )
            }
        }
      } else {
        Some(minimum)
      }
      if !self.consume('}') {
        return Err("Expected '}' at index \{self.index}")
      }
      match maximum {
        Some(value) =>
          if value < minimum {
            Err("Invalid repetition range at index \{self.index}")
          } else {
            Ok(RegexAst::RegexRepeat(content=ast, min=minimum, max=maximum))
          }
        None => Ok(RegexAst::RegexRepeat(content=ast, min=minimum, max=None))
      }
    }
  }
}

///|
fn RegexParser::parse_atom(self : RegexParser) -> Result[RegexAst, String] {
  match self.advance() {
    None => Err("Unexpected end of regex")
    Some('(') =>
      if self.peek() == Some('?') {
        Err("Unsupported regex assertion at index \{self.index - 1}")
      } else {
        match self.parse_alternation(stop_on_paren=true) {
          Err(message) => Err(message)
          Ok(ast) =>
            if self.consume(')') {
              Ok(ast)
            } else {
              Err("Expected ')' at index \{self.index}")
            }
        }
      }
    Some('[') => self.parse_character_class()
    Some('.') => Ok(RegexAst::RegexClass(character_set_any()))
    Some('\\') => self.parse_escape_atom()
    Some('*') | Some('+') | Some('?') | Some('{') =>
      Err("Unexpected repetition operator at index \{self.index - 1}")
    Some(char) => Ok(RegexAst::RegexLiteral(char.to_uint()))
  }
}

///|
fn RegexParser::parse_escape_atom(
  self : RegexParser,
) -> Result[RegexAst, String] {
  match self.parse_escape_set_or_char() {
    Err(message) => Err(message)
    Ok(EscapeValue::EscapeChar(char)) => Ok(RegexAst::RegexLiteral(char))
    Ok(EscapeValue::EscapeSet(set)) => Ok(RegexAst::RegexClass(set))
  }
}

///|
priv enum EscapeValue {
  EscapeChar(UInt)
  EscapeSet(CharacterSet)
}

///|
fn RegexParser::parse_escape_set_or_char(
  self : RegexParser,
) -> Result[EscapeValue, String] {
  match self.advance() {
    None => Err("Trailing escape at index \{self.index}")
    Some('n') => Ok(EscapeValue::EscapeChar(10U))
    Some('r') => Ok(EscapeValue::EscapeChar(13U))
    Some('t') => Ok(EscapeValue::EscapeChar(9U))
    Some('0') => Ok(EscapeValue::EscapeChar(0U))
    Some('d') => Ok(EscapeValue::EscapeSet(character_set_ascii_digit()))
    Some('D') =>
      Ok(
        EscapeValue::EscapeSet(
          character_set_negated(character_set_ascii_digit()),
        ),
      )
    Some('w') => Ok(EscapeValue::EscapeSet(character_set_ascii_word()))
    Some('W') =>
      Ok(
        EscapeValue::EscapeSet(
          character_set_negated(character_set_ascii_word()),
        ),
      )
    Some('s') => Ok(EscapeValue::EscapeSet(character_set_ascii_whitespace()))
    Some('S') =>
      Ok(
        EscapeValue::EscapeSet(
          character_set_negated(character_set_ascii_whitespace()),
        ),
      )
    Some('u') => self.parse_unicode_escape(4)
    Some('U') => self.parse_unicode_escape(8)
    Some('p') => self.parse_unicode_property_escape(negated=false)
    Some('P') => self.parse_unicode_property_escape(negated=true)
    Some(char) => Ok(EscapeValue::EscapeChar(char.to_uint()))
  }
}

///|
fn RegexParser::parse_unicode_escape(
  self : RegexParser,
  fixed_digits : Int,
) -> Result[EscapeValue, String] {
  if self.consume('{') {
    let mut value = 0U
    let mut digits = 0
    while !self.is_eof() && self.peek() != Some('}') {
      match self.advance() {
        Some(char) =>
          match hex_value(char) {
            Some(hex) => {
              value = value * 16U + hex
              digits += 1
            }
            None =>
              return Err("Invalid Unicode escape at index \{self.index - 1}")
          }
        None => ()
      }
    }
    if digits == 0 || !self.consume('}') {
      return Err("Invalid Unicode escape at index \{self.index}")
    }
    if value > unicode_scalar_max {
      Err("Unicode escape out of range at index \{self.index}")
    } else {
      Ok(EscapeValue::EscapeChar(value))
    }
  } else {
    let mut value = 0U
    for _ in 0..<fixed_digits {
      match self.advance() {
        Some(char) =>
          match hex_value(char) {
            Some(hex) => value = value * 16U + hex
            None =>
              return Err("Invalid Unicode escape at index \{self.index - 1}")
          }
        None => return Err("Invalid Unicode escape at index \{self.index}")
      }
    }
    Ok(EscapeValue::EscapeChar(value))
  }
}

///|
fn RegexParser::parse_unicode_property_escape(
  self : RegexParser,
  negated~ : Bool,
) -> Result[EscapeValue, String] {
  let property_index = self.index
  let property = if self.consume('{') {
    let chars : Array[Char] = []
    while !self.is_eof() && self.peek() != Some('}') {
      match self.advance() {
        Some(char) => chars.push(char)
        None => ()
      }
    }
    if chars.length() == 0 || !self.consume('}') {
      return Err("Expected Unicode property name at index \{property_index}")
    }
    String::from_array(chars)
  } else {
    match self.advance() {
      Some(char) => char.to_string()
      None =>
        return Err("Expected Unicode property name at index \{property_index}")
    }
  }
  match unicode_property_set(property) {
    Some(set) =>
      if negated {
        Ok(EscapeValue::EscapeSet(character_set_negated(set)))
      } else {
        Ok(EscapeValue::EscapeSet(set))
      }
    None =>
      Err(
        "Unsupported Unicode property '\{property}' at index \{property_index}",
      )
  }
}

///|
fn RegexParser::parse_character_class(
  self : RegexParser,
) -> Result[RegexAst, String] {
  match self.parse_character_class_set() {
    Err(message) => Err(message)
    Ok(set) => Ok(RegexAst::RegexClass(set))
  }
}

///|
fn RegexParser::parse_character_class_set(
  self : RegexParser,
) -> Result[CharacterSet, String] {
  let negated = self.consume('^')
  match self.parse_class_union() {
    Err(message) => Err(message)
    Ok(first) => {
      let mut set = first
      while !self.is_eof() && self.peek() != Some(']') {
        if self.starts_with_two('&', '&') {
          self.index += 2
          match self.parse_class_union() {
            Err(message) => return Err(message)
            Ok(right) => set = character_set_intersection(set, right)
          }
        } else if self.starts_with_two('-', '-') {
          self.index += 2
          match self.parse_class_union() {
            Err(message) => return Err(message)
            Ok(right) => set = character_set_difference(set, right)
          }
        } else if self.starts_with_two('~', '~') {
          self.index += 2
          match self.parse_class_union() {
            Err(message) => return Err(message)
            Ok(right) => set = character_set_symmetric_difference(set, right)
          }
        } else {
          return Err("Expected class set operator at index \{self.index}")
        }
      }
      if !self.consume(']') {
        return Err("Expected ']' at index \{self.index}")
      }
      if negated {
        Ok(character_set_negated(set))
      } else {
        Ok(set)
      }
    }
  }
}

///|
fn RegexParser::parse_class_union(
  self : RegexParser,
) -> Result[CharacterSet, String] {
  let mut set = character_set_empty()
  let mut consumed = false
  while !self.is_eof() && self.peek() != Some(']') && !self.is_class_operator() {
    match self.parse_class_atom() {
      Err(message) => return Err(message)
      Ok(atom) => {
        set = character_set_union(set, atom)
        consumed = true
      }
    }
  }
  if consumed {
    Ok(set)
  } else {
    Err("Expected character class item at index \{self.index}")
  }
}

///|
fn RegexParser::is_class_operator(self : RegexParser) -> Bool {
  self.starts_with_two('&', '&') ||
  self.starts_with_two('-', '-') ||
  self.starts_with_two('~', '~')
}

///|
fn RegexParser::parse_class_atom(
  self : RegexParser,
) -> Result[CharacterSet, String] {
  let start = match self.advance() {
    Some('[') => return self.parse_character_class_set()
    Some('\\') =>
      match self.parse_escape_set_or_char() {
        Ok(EscapeValue::EscapeSet(set)) => return Ok(set)
        Ok(EscapeValue::EscapeChar(char)) => char
        Err(message) => return Err(message)
      }
    Some(char) => char.to_uint()
    None => return Err("Expected character class item at index \{self.index}")
  }
  if self.peek() == Some('-') &&
    self.peek_offset(1) != Some(']') &&
    !self.starts_with_two('-', '-') {
    let _ = self.advance()
    let end = match self.advance() {
      Some('\\') =>
        match self.parse_escape_set_or_char() {
          Ok(EscapeValue::EscapeChar(char)) => char
          Ok(EscapeValue::EscapeSet(_)) =>
            return Err("Character class range cannot end in a class escape")
          Err(message) => return Err(message)
        }
      Some(char) => char.to_uint()
      None => return Err("Expected range end at index \{self.index}")
    }
    Ok(character_set_range(start, end))
  } else {
    Ok(character_set_range(start, start))
  }
}

///|
fn RegexParser::parse_decimal(self : RegexParser) -> Int? {
  let mut value = 0
  let mut digits = 0
  while !self.is_eof() {
    match self.peek() {
      Some(char) =>
        if is_ascii_digit_char(char) {
          value = value * 10 + digit_value(char)
          digits += 1
          let _ = self.advance()
        } else {
          break
        }
      None => break
    }
  }
  if digits == 0 {
    None
  } else {
    Some(value)
  }
}

///|
fn is_ascii_digit_char(char : Char) -> Bool {
  let value = char.to_uint()
  48U <= value && value <= 57U
}

///|
fn digit_value(char : Char) -> Int {
  (char.to_uint() - 48U).reinterpret_as_int()
}

///|
fn hex_value(char : Char) -> UInt? {
  let value = char.to_uint()
  if 48U <= value && value <= 57U {
    Some(value - 48U)
  } else if 65U <= value && value <= 70U {
    Some(value - 65U + 10U)
  } else if 97U <= value && value <= 102U {
    Some(value - 97U + 10U)
  } else {
    None
  }
}

///|
fn unicode_property_set(property : String) -> CharacterSet? {
  let normalized = canonical_unicode_property_name(property)
  let name = unicode_property_value_name(normalized)
  match name {
    "l" | "letter" => Some(character_set_unicode_letter())
    "ll" | "lowercaseletter" => Some(character_set_unicode_lowercase_letter())
    "lu" | "uppercaseletter" => Some(character_set_unicode_uppercase_letter())
    "n" | "number" => Some(character_set_unicode_number())
    "nd" | "decimalnumber" => Some(character_set_unicode_decimal_number())
    "nl" | "letternumber" => Some(character_set_unicode_letter_number())
    "sm" | "mathsymbol" => Some(character_set_unicode_math_symbol())
    "z" | "separator" => Some(character_set_unicode_separator())
    "whitespace" | "space" => Some(character_set_unicode_white_space())
    "emoji" => Some(character_set_unicode_emoji())
    _ => None
  }
}

///|
fn canonical_unicode_property_name(property : String) -> String {
  let normalized : Array[Char] = []
  for char in property.to_lower().to_array() {
    match char {
      '_' | '-' | ' ' => ()
      _ => normalized.push(char)
    }
  }
  String::from_array(normalized)
}

///|
fn unicode_property_value_name(normalized : String) -> String {
  if normalized.has_prefix("generalcategory=") {
    normalized.unsafe_substring(start=16, end=normalized.length())
  } else if normalized.has_prefix("gc=") {
    normalized.unsafe_substring(start=3, end=normalized.length())
  } else {
    normalized
  }
}

///|
fn character_set_unicode_letter() -> CharacterSet {
  character_set_union(
    character_set_unicode_uppercase_letter(),
    character_set_union(
      character_set_unicode_lowercase_letter(),
      character_set_from_ranges([
        { start: 880U, end: 1023U },
        { start: 4256U, end: 4351U },
        { start: 12592U, end: 12687U },
        { start: 19968U, end: 40959U },
        { start: 44032U, end: 55203U },
      ]),
    ),
  )
}

///|
fn character_set_unicode_uppercase_letter() -> CharacterSet {
  character_set_from_ranges([
    { start: 65U, end: 90U },
    { start: 192U, end: 214U },
    { start: 216U, end: 222U },
    { start: 346U, end: 346U },
    { start: 385U, end: 385U },
    { start: 390U, end: 390U },
    { start: 391U, end: 391U },
    { start: 393U, end: 394U },
    { start: 398U, end: 401U },
    { start: 404U, end: 404U },
    { start: 406U, end: 408U },
    { start: 913U, end: 929U },
    { start: 931U, end: 939U },
  ])
}

///|
fn character_set_unicode_lowercase_letter() -> CharacterSet {
  character_set_from_ranges([
    { start: 97U, end: 122U },
    { start: 223U, end: 246U },
    { start: 248U, end: 255U },
    { start: 345U, end: 345U },
    { start: 347U, end: 347U },
    { start: 357U, end: 357U },
    { start: 384U, end: 384U },
    { start: 940U, end: 974U },
  ])
}

///|
fn character_set_unicode_number() -> CharacterSet {
  character_set_union(
    character_set_unicode_decimal_number(),
    character_set_unicode_letter_number(),
  )
}

///|
fn character_set_unicode_decimal_number() -> CharacterSet {
  character_set_from_ranges([
    { start: 48U, end: 57U },
    { start: 1632U, end: 1641U },
    { start: 1776U, end: 1785U },
    { start: 2406U, end: 2415U },
    { start: 65296U, end: 65305U },
  ])
}

///|
fn character_set_unicode_letter_number() -> CharacterSet {
  character_set_from_ranges([
    { start: 5870U, end: 5872U },
    { start: 8544U, end: 8584U },
    { start: 12321U, end: 12329U },
    { start: 12344U, end: 12346U },
  ])
}

///|
fn character_set_unicode_math_symbol() -> CharacterSet {
  character_set_from_ranges([
    { start: 43U, end: 43U },
    { start: 172U, end: 172U },
    { start: 177U, end: 177U },
    { start: 215U, end: 215U },
    { start: 247U, end: 247U },
    { start: 8704U, end: 8959U },
    { start: 10752U, end: 11007U },
  ])
}

///|
fn character_set_unicode_separator() -> CharacterSet {
  character_set_from_ranges([
    { start: 32U, end: 32U },
    { start: 160U, end: 160U },
    { start: 5760U, end: 5760U },
    { start: 8192U, end: 8202U },
    { start: 8232U, end: 8233U },
    { start: 8239U, end: 8239U },
    { start: 8287U, end: 8287U },
    { start: 12288U, end: 12288U },
  ])
}

///|
fn character_set_unicode_white_space() -> CharacterSet {
  character_set_union(
    character_set_range(9U, 13U),
    character_set_unicode_separator(),
  )
}

///|
fn character_set_unicode_emoji() -> CharacterSet {
  character_set_from_ranges([
    { start: 35U, end: 35U },
    { start: 42U, end: 42U },
    { start: 48U, end: 57U },
    { start: 169U, end: 169U },
    { start: 174U, end: 174U },
    { start: 8252U, end: 8252U },
    { start: 8265U, end: 8265U },
    { start: 8482U, end: 8482U },
    { start: 8505U, end: 8505U },
    { start: 8986U, end: 8987U },
    { start: 9193U, end: 9203U },
    { start: 9208U, end: 9210U },
    { start: 127744U, end: 129791U },
  ])
}

///|
fn regex_parser_smoke_weight() -> Int {
  match parse_regex("(a|b){1,2}\\d") {
    Ok(ast) => regex_ast_weight(ast)
    Err(message) => message.length()
  }
}

///|
fn regex_ast_case_insensitive(ast : RegexAst) -> RegexAst {
  match ast {
    RegexEmpty => RegexAst::RegexEmpty
    RegexLiteral(value) =>
      RegexAst::RegexClass(case_insensitive_code_point_set(value))
    RegexClass(set) => RegexAst::RegexClass(case_insensitive_character_set(set))
    RegexSeq(items) =>
      RegexAst::RegexSeq(regex_ast_case_insensitive_array(items))
    RegexChoice(items) =>
      RegexAst::RegexChoice(regex_ast_case_insensitive_array(items))
    RegexRepeat(content~, min~, max~) =>
      RegexAst::RegexRepeat(
        content=regex_ast_case_insensitive(content),
        min~,
        max~,
      )
  }
}

///|
fn regex_ast_case_insensitive_array(items : Array[RegexAst]) -> Array[RegexAst] {
  let result : Array[RegexAst] = []
  for item in items {
    result.push(regex_ast_case_insensitive(item))
  }
  result
}

///|
fn case_insensitive_character_set(set : CharacterSet) -> CharacterSet {
  let mut result = set
  for range in set.ranges {
    let mut code_point = range.start
    while code_point <= range.end {
      result = character_set_union(
        result,
        case_insensitive_code_point_set_raw(code_point),
      )
      if code_point == unicode_scalar_max {
        break
      }
      code_point += 1U
    }
  }
  remove_unintentional_long_s(set, result)
}

///|
fn case_insensitive_code_point_set(code_point : UInt) -> CharacterSet {
  remove_unintentional_long_s(
    character_set_range(code_point, code_point),
    case_insensitive_code_point_set_raw(code_point),
  )
}

///|
fn case_insensitive_code_point_set_raw(code_point : UInt) -> CharacterSet {
  if 65U <= code_point && code_point <= 90U {
    let lower = code_point + 32U
    let set = character_set_from_ranges([
      { start: code_point, end: code_point },
      { start: lower, end: lower },
    ])
    if code_point == 83U {
      character_set_union(set, character_set_range(383U, 383U))
    } else {
      set
    }
  } else if 97U <= code_point && code_point <= 122U {
    let set = character_set_from_ranges([
      { start: code_point - 32U, end: code_point - 32U },
      { start: code_point, end: code_point },
    ])
    if code_point == 115U {
      character_set_union(set, character_set_range(383U, 383U))
    } else {
      set
    }
  } else if code_point == 383U {
    character_set_from_ranges([
      { start: 83U, end: 83U },
      { start: 115U, end: 115U },
      { start: 383U, end: 383U },
    ])
  } else {
    character_set_range(code_point, code_point)
  }
}

///|
fn remove_unintentional_long_s(
  original : CharacterSet,
  folded : CharacterSet,
) -> CharacterSet {
  if !character_set_contains(original, 383U) &&
    character_set_range_count(folded) == 3 &&
    character_set_contains(folded, 83U) &&
    character_set_contains(folded, 115U) &&
    character_set_contains(folded, 383U) {
    character_set_difference(folded, character_set_range(383U, 383U))
  } else {
    folded
  }
}

///|
fn regex_ast_weight(ast : RegexAst) -> Int {
  match ast {
    RegexEmpty => 1
    RegexLiteral(value) => value.reinterpret_as_int()
    RegexClass(set) => character_set_weight(set)
    RegexSeq(items) | RegexChoice(items) => {
      let mut weight = items.length()
      for item in items {
        weight += regex_ast_weight(item)
      }
      weight
    }
    RegexRepeat(content~, min~, max~) => {
      let max_weight = match max {
        Some(value) => value
        None => 0
      }
      regex_ast_weight(content) + min + max_weight
    }
  }
}
