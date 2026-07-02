///|
struct Tree {
  mut data : TreeData
}

///|
priv struct TreeData {
  identity : Int
  language : Language
  nodes : Array[NodeData]
  root_index : Int
  included_ranges : Array[@api.Range]
  source_bytes : Bytes?
  source_encoding : @api.InputEncoding
  source_chunk_end_offsets : Array[Int]
}

///|
let tree_identity_counter : Array[Int] = [0]

///|
fn next_tree_identity() -> Int {
  tree_identity_counter[0] = tree_identity_counter[0] + 1
  tree_identity_counter[0]
}

///|
priv struct NodeData {
  kind : String
  grammar_kind : String
  symbol : @api.SymbolId
  grammar_symbol : @api.SymbolId
  start_byte : UInt
  end_byte : UInt
  start_point : @api.Point
  end_point : @api.Point
  parent : Int
  children : Array[Int]
  field_id : @api.FieldId
  visible : Bool
  alias_visible : Bool
  named : Bool
  extra : Bool
  missing : Bool
  has_changes : Bool
  has_error : Bool
  is_error : Bool
  error_cost : Int
  dynamic_precedence : Int
  fragile_left : Bool
  fragile_right : Bool
  lookahead_char : Int?
  lookahead_bytes : Bytes?
  lookahead_byte_count : Int
  parse_state : @api.StateId?
  next_parse_state : @api.StateId?
  external_scanner_state : Bytes?
  has_external_tokens : Bool
  has_external_scanner_state_change : Bool
  depends_on_column : Bool
}

///|
struct Node {
  language : Language
  mut data : TreeData?
  index : Int
  byte_offset : UInt
  point_offset : @api.Point
}

///|
priv struct PublicChild {
  index : Int
  field_id : @api.FieldId
}

///|
struct TreeCursor {
  node : Node
  root : Node
}

///|
fn NodeData::new(
  kind~ : String,
  symbol~ : @api.SymbolId,
  start_byte~ : UInt,
  end_byte~ : UInt,
  start_point~ : @api.Point,
  end_point~ : @api.Point,
  grammar_kind? : String = kind,
  grammar_symbol? : @api.SymbolId = symbol,
  parent? : Int = -1,
  children? : Array[Int] = [],
  field_id? : @api.FieldId = @api.FieldId::new(0),
  visible? : Bool = true,
  alias_visible? : Bool = false,
  named? : Bool = true,
  extra? : Bool = false,
  missing? : Bool = false,
  has_changes? : Bool = false,
  has_error? : Bool = false,
  is_error? : Bool = false,
  error_cost? : Int = 0,
  dynamic_precedence? : Int = 0,
  fragile_left? : Bool = false,
  fragile_right? : Bool = false,
  lookahead_char? : Int? = None,
  lookahead_bytes? : Bytes? = None,
  lookahead_byte_count? : Int = 0,
  parse_state? : @api.StateId? = None,
  next_parse_state? : @api.StateId? = None,
  external_scanner_state? : Bytes? = None,
  has_external_tokens? : Bool = external_scanner_state is Some(_),
  has_external_scanner_state_change? : Bool = false,
  depends_on_column? : Bool = false,
) -> NodeData {
  {
    kind,
    grammar_kind,
    symbol,
    grammar_symbol,
    start_byte,
    end_byte,
    start_point,
    end_point,
    parent,
    children,
    field_id,
    visible,
    alias_visible,
    named,
    extra,
    missing,
    has_changes,
    has_error,
    is_error,
    error_cost,
    dynamic_precedence,
    fragile_left,
    fragile_right,
    lookahead_char,
    lookahead_bytes,
    lookahead_byte_count,
    parse_state,
    next_parse_state,
    external_scanner_state,
    has_external_tokens,
    has_external_scanner_state_change,
    depends_on_column,
  }
}

///|
fn Tree::from_fixture(
  language : Language,
  nodes : Array[NodeData],
  included_ranges? : Array[@api.Range] = [],
  root_index? : Int = 0,
  source_bytes? : Bytes? = None,
  source_encoding? : @api.InputEncoding = Utf8,
  source_chunk_end_offsets? : Array[Int] = [],
) -> Tree {
  {
    data: {
      identity: next_tree_identity(),
      language,
      nodes,
      root_index,
      included_ranges: included_ranges.copy(),
      source_bytes,
      source_encoding,
      source_chunk_end_offsets: source_chunk_end_offsets.copy(),
    },
  }
}

///|
pub fn Tree::language(self : Tree) -> Language {
  self.data.language
}

///|
pub fn Tree::root_node(self : Tree) -> Node {
  Node::from_tree(self.data, self.data.root_index)
}

///|
pub fn Tree::root_node_with_offset(
  self : Tree,
  byte_offset~ : UInt,
  point_offset~ : @api.Point,
) -> Node {
  Node::from_tree_with_offset(
    self.data,
    self.data.root_index,
    byte_offset~,
    point_offset~,
  )
}

///|
pub fn Tree::included_ranges(self : Tree) -> Array[@api.Range] {
  self.data.included_ranges.copy()
}

///|
pub fn Tree::copy(self : Tree) -> Tree {
  {
    data: {
      identity: next_tree_identity(),
      language: self.data.language,
      nodes: self.data.nodes.copy(),
      root_index: self.data.root_index,
      included_ranges: self.data.included_ranges.copy(),
      source_bytes: self.data.source_bytes,
      source_encoding: self.data.source_encoding,
      source_chunk_end_offsets: self.data.source_chunk_end_offsets.copy(),
    },
  }
}

///|
pub fn Tree::edit(self : Tree, edit : @api.InputEdit) -> Unit {
  self.data = self.data.edit(edit)
}

///|
pub fn Tree::changed_ranges(self : Tree, other : Tree) -> Array[@api.Range] {
  if tree_data_same(self.data, other.data) {
    []
  } else {
    let ranges = tree_changed_ranges_from_flags(self, other)
    let root_start_padding_range = tree_root_start_padding_changed_range(
      self, other,
    )
    match root_start_padding_range {
      Some(range) => push_changed_range(ranges, range)
      None => ()
    }
    let root_end_tail_range = tree_root_end_tail_changed_range(self, other)
    match root_end_tail_range {
      Some(range) => push_changed_range(ranges, range)
      None => ()
    }
    let metadata_ranges = tree_changed_ranges_from_metadata(
      self,
      other,
      ignore_root_start=root_start_padding_range is Some(_),
      ignore_root_end=root_end_tail_range is Some(_),
    )
    for range in metadata_ranges {
      push_changed_range(ranges, range)
    }
    if !ranges.is_empty() {
      return ranges
    }
    let included_range_diffs = tree_changed_ranges_from_included_ranges(
      self, other,
    )
    if !included_range_diffs.is_empty() {
      return included_range_diffs
    }
    let range = tree_combined_root_range(self, other)
    if range.is_empty() {
      []
    } else {
      [range]
    }
  }
}

///|
pub fn Tree::walk(self : Tree) -> TreeCursor {
  let root = self.root_node()
  { node: root, root }
}

///|
pub fn Tree::to_sexp(self : Tree) -> String {
  self.root_node().to_sexp()
}

///|
fn Node::from_tree(data : TreeData, index : Int) -> Node {
  Node::from_tree_with_offset(
    data,
    index,
    byte_offset=0,
    point_offset=@api.Point::zero(),
  )
}

///|
fn Node::from_tree_with_offset(
  data : TreeData,
  index : Int,
  byte_offset~ : UInt,
  point_offset~ : @api.Point,
) -> Node {
  {
    language: data.language,
    data: Some(data),
    index,
    byte_offset,
    point_offset,
  }
}

///|
fn Node::null(language : Language) -> Node {
  {
    language,
    data: None,
    index: -1,
    byte_offset: 0,
    point_offset: @api.Point::zero(),
  }
}

///|
fn Node::node_data(self : Node) -> NodeData? {
  match self.data {
    Some(data) =>
      if self.index >= 0 && self.index < data.nodes.length() {
        Some(data.nodes[self.index])
      } else {
        None
      }
    None => None
  }
}

///|
fn TreeData::edit(self : TreeData, edit : @api.InputEdit) -> TreeData {
  let included_ranges = []
  for range in self.included_ranges {
    included_ranges.push(range.edit(edit))
  }
  let nodes = []
  for i in 0..<self.nodes.length() {
    nodes.push(self.nodes[i].edit(i, edit, self))
  }
  {
    ..self,
    nodes,
    included_ranges,
    source_bytes: None,
    source_chunk_end_offsets: [],
  }
}

///|
fn Tree::copy_if_reusable_same_input(
  self : Tree,
  input : Bytes,
  encoding : @api.InputEncoding,
  chunk_end_offsets : Array[Int],
  included_ranges : Array[@api.Range],
) -> Tree? {
  match self.data.source_bytes {
    Some(source) =>
      if Bytes::equal(source, input) &&
        self.data.source_encoding == encoding &&
        int_arrays_same(self.data.source_chunk_end_offsets, chunk_end_offsets) &&
        included_ranges_same(self.data.included_ranges, included_ranges) &&
        !self.root_node().has_changes() {
        Some(self.copy())
      } else {
        None
      }
    None => None
  }
}

///|
fn NodeData::edit(
  self : NodeData,
  index : Int,
  edit : @api.InputEdit,
  tree : TreeData,
) -> NodeData {
  let range = @api.Range::new(
    start_byte=self.start_byte,
    end_byte=self.end_byte,
    start_point=self.start_point,
    end_point=self.end_point,
  ).edit(edit)
  {
    ..self,
    start_byte: range.start_byte,
    end_byte: range.end_byte,
    start_point: range.start_point,
    end_point: range.end_point,
    has_changes: self.has_changes ||
    node_data_touched_by_edit(self, index, edit, tree),
  }
}

///|
fn node_data_touched_by_edit(
  data : NodeData,
  index : Int,
  edit : @api.InputEdit,
  tree : TreeData,
) -> Bool {
  if node_data_column_touched_by_edit(data, edit) {
    return true
  }
  let invalidation_end_byte = node_data_invalidation_end_byte(data)
  if edit.start_byte == edit.old_end_byte {
    if data.parent < 0 {
      data.start_byte <= edit.start_byte &&
      edit.start_byte <= invalidation_end_byte
    } else if data.start_byte < edit.start_byte &&
      edit.start_byte <= invalidation_end_byte {
      true
    } else {
      data.start_byte == edit.start_byte &&
      edit.start_byte <= invalidation_end_byte &&
      !previous_sibling_touches_insertion(tree, index, edit.start_byte)
    }
  } else {
    edit.start_byte <= invalidation_end_byte &&
    data.start_byte <= edit.old_end_byte
  }
}

///|
fn node_data_column_touched_by_edit(
  data : NodeData,
  edit : @api.InputEdit,
) -> Bool {
  let column_shifted = edit.new_end_point.column != edit.old_end_point.column
  data.depends_on_column &&
  column_shifted &&
  edit.start_byte <= data.start_byte &&
  edit.old_end_point.row == data.start_point.row &&
  edit.old_end_point.column <= data.start_point.column
}

///|
fn node_data_invalidation_end_byte(data : NodeData) -> UInt {
  if data.lookahead_byte_count <= 0 {
    data.end_byte
  } else {
    add_u32_saturating(
      data.end_byte,
      data.lookahead_byte_count.reinterpret_as_uint(),
    )
  }
}

///|
fn previous_sibling_touches_insertion(
  tree : TreeData,
  index : Int,
  byte : UInt,
) -> Bool {
  if index < 0 || index >= tree.nodes.length() {
    return false
  }
  let data = tree.nodes[index]
  if data.parent < 0 || data.parent >= tree.nodes.length() {
    return false
  }
  let parent = tree.nodes[data.parent]
  for sibling_index in parent.children {
    if sibling_index == index {
      return false
    }
    if sibling_index >= 0 && sibling_index < tree.nodes.length() {
      let sibling = tree.nodes[sibling_index]
      if sibling.start_byte <= byte &&
        byte <= node_data_invalidation_end_byte(sibling) {
        return true
      }
    }
  }
  false
}

///|
fn int_arrays_same(left : Array[Int], right : Array[Int]) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if left[i] != right[i] {
      return false
    }
  }
  true
}

///|
pub fn Node::edit(self : Node, edit : @api.InputEdit) -> Unit {
  match self.data {
    Some(data) => self.data = Some(data.edit(edit))
    None => ()
  }
}

///|
pub fn Node::eq(self : Node, other : Node) -> Bool {
  match (self.data, other.data) {
    (Some(left), Some(right)) =>
      left.identity == right.identity && self.index == other.index
    (None, None) => language_identity_matches(self.language, other.language)
    _ => false
  }
}

///|
fn tree_data_same(left : TreeData, right : TreeData) -> Bool {
  language_identity_matches(left.language, right.language) &&
  left.root_index == right.root_index &&
  included_ranges_same(left.included_ranges, right.included_ranges) &&
  node_data_arrays_same(left.nodes, right.nodes)
}

///|
fn included_ranges_same(
  left : Array[@api.Range],
  right : Array[@api.Range],
) -> Bool {
  let normalized_left = normalized_included_ranges(left)
  let normalized_right = normalized_included_ranges(right)
  normalized_left == normalized_right
}

///|
fn normalized_included_ranges(ranges : Array[@api.Range]) -> Array[@api.Range] {
  if ranges.is_empty() {
    [@api.Range::unbounded(start_byte=0, start_point=@api.Point::zero())]
  } else {
    ranges
  }
}

///|
fn node_data_arrays_same(
  left : Array[NodeData],
  right : Array[NodeData],
) -> Bool {
  if left.length() != right.length() {
    return false
  }
  for i in 0..<left.length() {
    if !node_data_same(left[i], right[i]) {
      return false
    }
  }
  true
}

///|
fn node_data_same(left : NodeData, right : NodeData) -> Bool {
  left.kind == right.kind &&
  left.grammar_kind == right.grammar_kind &&
  left.symbol == right.symbol &&
  left.grammar_symbol == right.grammar_symbol &&
  left.start_byte == right.start_byte &&
  left.end_byte == right.end_byte &&
  left.start_point == right.start_point &&
  left.end_point == right.end_point &&
  left.parent == right.parent &&
  left.children == right.children &&
  left.field_id == right.field_id &&
  left.visible == right.visible &&
  left.alias_visible == right.alias_visible &&
  left.named == right.named &&
  left.extra == right.extra &&
  left.missing == right.missing &&
  left.has_changes == right.has_changes &&
  left.has_error == right.has_error &&
  left.is_error == right.is_error &&
  left.error_cost == right.error_cost &&
  left.dynamic_precedence == right.dynamic_precedence &&
  left.fragile_left == right.fragile_left &&
  left.fragile_right == right.fragile_right &&
  left.lookahead_char == right.lookahead_char &&
  left.lookahead_bytes == right.lookahead_bytes &&
  left.lookahead_byte_count == right.lookahead_byte_count &&
  left.parse_state == right.parse_state &&
  left.next_parse_state == right.next_parse_state &&
  left.external_scanner_state == right.external_scanner_state &&
  left.has_external_tokens == right.has_external_tokens &&
  left.has_external_scanner_state_change ==
  right.has_external_scanner_state_change &&
  left.depends_on_column == right.depends_on_column
}

///|
fn tree_changed_ranges_from_metadata(
  left : Tree,
  right : Tree,
  ignore_root_start? : Bool = false,
  ignore_root_end? : Bool = false,
) -> Array[@api.Range] {
  let ranges = []
  ignore(
    collect_metadata_changed_ranges(
      left.root_node(),
      right.root_node(),
      ranges~,
      ignore_start=ignore_root_start,
      ignore_end=ignore_root_end,
    ),
  )
  ranges
}

///|
fn collect_metadata_changed_ranges(
  left : Node,
  right : Node,
  ranges~ : Array[@api.Range],
  ignore_start? : Bool = false,
  ignore_end? : Bool = false,
) -> Bool {
  if left.is_null() || right.is_null() {
    return false
  }
  let mut found_changed_child = false
  let left_children = left.public_children()
  let right_children = right.public_children()
  if left_children.length() == right_children.length() {
    for i in 0..<left_children.length() {
      if collect_metadata_changed_ranges(
          left.child_node(left_children[i].index),
          right.child_node(right_children[i].index),
          ranges~,
        ) {
        found_changed_child = true
      }
    }
  }
  if node_metadata_differs(left, right, ignore_start~, ignore_end~) &&
    !found_changed_child {
    push_changed_range(ranges, node_combined_range(left, right))
    true
  } else {
    found_changed_child
  }
}

///|
fn node_metadata_differs(
  left : Node,
  right : Node,
  ignore_start? : Bool = false,
  ignore_end? : Bool = false,
) -> Bool {
  match (left.node_data(), right.node_data()) {
    (Some(left_data), Some(right_data)) =>
      if ignore_start || ignore_end {
        !node_data_same_ignoring_root_bounds(
          left_data,
          right_data,
          ignore_start~,
          ignore_end~,
        )
      } else {
        !node_data_same(left_data, right_data)
      }
    (None, None) => false
    _ => true
  }
}

///|
fn node_data_same_ignoring_root_bounds(
  left : NodeData,
  right : NodeData,
  ignore_start~ : Bool,
  ignore_end~ : Bool,
) -> Bool {
  let adjusted = {
    ..left,
    start_byte: if ignore_start {
      right.start_byte
    } else {
      left.start_byte
    },
    start_point: if ignore_start {
      right.start_point
    } else {
      left.start_point
    },
    end_byte: if ignore_end {
      right.end_byte
    } else {
      left.end_byte
    },
    end_point: if ignore_end {
      right.end_point
    } else {
      left.end_point
    },
  }
  node_data_same(adjusted, right)
}

///|
fn tree_changed_ranges_from_included_ranges(
  left : Tree,
  right : Tree,
) -> Array[@api.Range] {
  if included_ranges_same(left.data.included_ranges, right.data.included_ranges) {
    return []
  }
  range_array_changed_ranges(
    normalized_included_ranges(left.data.included_ranges),
    normalized_included_ranges(right.data.included_ranges),
  )
}

///|
fn range_array_changed_ranges(
  old_ranges : Array[@api.Range],
  new_ranges : Array[@api.Range],
) -> Array[@api.Range] {
  let differences = []
  let mut old_index = 0
  let mut new_index = 0
  let mut current_byte : UInt = 0
  let mut current_point = @api.Point::zero()
  let mut in_old_range = false
  let mut in_new_range = false
  while old_index < old_ranges.length() || new_index < new_ranges.length() {
    let (next_old_byte, next_old_point) = next_included_range_position(
      old_ranges, old_index, in_old_range,
    )
    let (next_new_byte, next_new_point) = next_included_range_position(
      new_ranges, new_index, in_new_range,
    )
    if next_old_byte < next_new_byte {
      if in_old_range != in_new_range {
        push_changed_range(
          differences,
          @api.Range::new(
            start_byte=current_byte,
            end_byte=next_old_byte,
            start_point=current_point,
            end_point=next_old_point,
          ),
        )
      }
      if in_old_range {
        old_index += 1
      }
      current_byte = next_old_byte
      current_point = next_old_point
      in_old_range = !in_old_range
    } else if next_new_byte < next_old_byte {
      if in_old_range != in_new_range {
        push_changed_range(
          differences,
          @api.Range::new(
            start_byte=current_byte,
            end_byte=next_new_byte,
            start_point=current_point,
            end_point=next_new_point,
          ),
        )
      }
      if in_new_range {
        new_index += 1
      }
      current_byte = next_new_byte
      current_point = next_new_point
      in_new_range = !in_new_range
    } else {
      if in_old_range != in_new_range {
        push_changed_range(
          differences,
          @api.Range::new(
            start_byte=current_byte,
            end_byte=next_new_byte,
            start_point=current_point,
            end_point=next_new_point,
          ),
        )
      }
      if in_old_range {
        old_index += 1
      }
      if in_new_range {
        new_index += 1
      }
      in_old_range = !in_old_range
      in_new_range = !in_new_range
      current_byte = next_new_byte
      current_point = next_new_point
    }
  }
  differences
}

///|
fn next_included_range_position(
  ranges : Array[@api.Range],
  index : Int,
  in_range : Bool,
) -> (UInt, @api.Point) {
  if in_range {
    let range = ranges[index]
    (range.end_byte, range.end_point)
  } else if index < ranges.length() {
    let range = ranges[index]
    (range.start_byte, range.start_point)
  } else {
    (@api.uint32_max(), @api.Point::max())
  }
}

///|
fn tree_combined_root_range(left : Tree, right : Tree) -> @api.Range {
  let left_root = left.root_node()
  let right_root = right.root_node()
  let (start_byte, start_point) = if left_root.start_byte() <=
    right_root.start_byte() {
    (left_root.start_byte(), left_root.start_point())
  } else {
    (right_root.start_byte(), right_root.start_point())
  }
  let (end_byte, end_point) = if left_root.end_byte() >= right_root.end_byte() {
    (left_root.end_byte(), left_root.end_point())
  } else {
    (right_root.end_byte(), right_root.end_point())
  }
  @api.Range::new(start_byte~, end_byte~, start_point~, end_point~)
}

///|
fn tree_root_start_padding_changed_range(
  left : Tree,
  right : Tree,
) -> @api.Range? {
  let left_root = left.root_node()
  let right_root = right.root_node()
  if left_root.start_byte() < right_root.start_byte() {
    Some(
      @api.Range::new(
        start_byte=left_root.start_byte(),
        end_byte=right_root.start_byte(),
        start_point=left_root.start_point(),
        end_point=right_root.start_point(),
      ),
    )
  } else if right_root.start_byte() < left_root.start_byte() {
    Some(
      @api.Range::new(
        start_byte=right_root.start_byte(),
        end_byte=left_root.start_byte(),
        start_point=right_root.start_point(),
        end_point=left_root.start_point(),
      ),
    )
  } else {
    None
  }
}

///|
fn tree_root_end_tail_changed_range(left : Tree, right : Tree) -> @api.Range? {
  let left_root = left.root_node()
  let right_root = right.root_node()
  if left_root.end_byte() < right_root.end_byte() {
    Some(
      @api.Range::new(
        start_byte=left_root.end_byte(),
        end_byte=right_root.end_byte(),
        start_point=left_root.end_point(),
        end_point=right_root.end_point(),
      ),
    )
  } else if right_root.end_byte() < left_root.end_byte() {
    Some(
      @api.Range::new(
        start_byte=right_root.end_byte(),
        end_byte=left_root.end_byte(),
        start_point=right_root.end_point(),
        end_point=left_root.end_point(),
      ),
    )
  } else {
    None
  }
}

///|
fn tree_changed_ranges_from_flags(
  left : Tree,
  right : Tree,
) -> Array[@api.Range] {
  let ranges = []
  let left_root = left.root_node()
  let right_root = right.root_node()
  if left_root.has_changes() {
    collect_node_changed_ranges(left_root, right_root, ranges~)
  } else if right_root.has_changes() {
    collect_node_changed_ranges(right_root, left_root, ranges~)
  }
  ranges
}

///|
fn collect_node_changed_ranges(
  left : Node,
  right : Node,
  ranges~ : Array[@api.Range],
) -> Unit {
  if left.is_null() || right.is_null() || !left.has_changes() {
    return
  }
  let mut found_changed_child = false
  if left.child_count() == right.child_count() {
    for i in 0..<left.child_count() {
      let left_child = left.child(i)
      if left_child.has_changes() {
        found_changed_child = true
        collect_node_changed_ranges(left_child, right.child(i), ranges~)
      }
    }
  }
  if !found_changed_child {
    push_changed_range(ranges, node_combined_range(left, right))
  }
}

///|
fn push_changed_range(ranges : Array[@api.Range], range : @api.Range) -> Unit {
  if range.is_empty() {
    return
  }
  match ranges.last() {
    Some(last) =>
      if range.start_byte <= last.end_byte {
        let index = ranges.length() - 1
        ranges[index] = range_union(last, range)
      } else {
        ranges.push(range)
      }
    None => ranges.push(range)
  }
}

///|
fn range_union(left : @api.Range, right : @api.Range) -> @api.Range {
  let (start_byte, start_point) = if left.start_byte <= right.start_byte {
    (left.start_byte, left.start_point)
  } else {
    (right.start_byte, right.start_point)
  }
  let (end_byte, end_point) = if left.end_byte >= right.end_byte {
    (left.end_byte, left.end_point)
  } else {
    (right.end_byte, right.end_point)
  }
  @api.Range::new(start_byte~, end_byte~, start_point~, end_point~)
}

///|
fn node_combined_range(left : Node, right : Node) -> @api.Range {
  let (start_byte, start_point) = if left.start_byte() <= right.start_byte() {
    (left.start_byte(), left.start_point())
  } else {
    (right.start_byte(), right.start_point())
  }
  let (end_byte, end_point) = if left.end_byte() >= right.end_byte() {
    (left.end_byte(), left.end_point())
  } else {
    (right.end_byte(), right.end_point())
  }
  @api.Range::new(start_byte~, end_byte~, start_point~, end_point~)
}

///|
pub fn Node::language(self : Node) -> Language {
  self.language
}

///|
pub fn Node::type_(self : Node) -> String {
  match self.node_data() {
    Some(data) => data.kind
    None => ""
  }
}

///|
pub fn Node::grammar_type(self : Node) -> String {
  match self.node_data() {
    Some(data) => data.grammar_kind
    None => ""
  }
}

///|
pub fn Node::symbol(self : Node) -> @api.SymbolId {
  match self.node_data() {
    Some(data) => data.symbol
    None => @api.SymbolId::new(0)
  }
}

///|
pub fn Node::grammar_symbol(self : Node) -> @api.SymbolId {
  match self.node_data() {
    Some(data) => data.grammar_symbol
    None => @api.SymbolId::new(0)
  }
}

///|
pub fn Node::start_byte(self : Node) -> UInt {
  match self.node_data() {
    Some(data) => add_u32_saturating(data.start_byte, self.byte_offset)
    None => 0
  }
}

///|
pub fn Node::end_byte(self : Node) -> UInt {
  match self.node_data() {
    Some(data) => add_u32_saturating(data.end_byte, self.byte_offset)
    None => 0
  }
}

///|
pub fn Node::start_point(self : Node) -> @api.Point {
  match self.node_data() {
    Some(data) => self.point_offset.add(data.start_point)
    None => @api.Point::zero()
  }
}

///|
pub fn Node::end_point(self : Node) -> @api.Point {
  match self.node_data() {
    Some(data) => self.point_offset.add(data.end_point)
    None => @api.Point::zero()
  }
}

///|
pub fn Node::is_null(self : Node) -> Bool {
  self.data is None
}

///|
pub fn Node::is_named(self : Node) -> Bool {
  match self.node_data() {
    Some(data) => data.named
    None => false
  }
}

///|
pub fn Node::is_missing(self : Node) -> Bool {
  match self.node_data() {
    Some(data) => data.missing
    None => false
  }
}

///|
pub fn Node::is_extra(self : Node) -> Bool {
  match self.node_data() {
    Some(data) => data.extra
    None => false
  }
}

///|
pub fn Node::has_changes(self : Node) -> Bool {
  match self.node_data() {
    Some(data) => data.has_changes
    None => false
  }
}

///|
pub fn Node::has_error(self : Node) -> Bool {
  match self.node_data() {
    Some(data) => data.has_error || data.is_error
    None => false
  }
}

///|
pub fn Node::is_error(self : Node) -> Bool {
  match self.node_data() {
    Some(data) => data.is_error
    None => false
  }
}

///|
pub fn Node::parse_state(self : Node) -> @api.StateId? {
  match self.node_data() {
    Some(data) => data.parse_state
    None => None
  }
}

///|
pub fn Node::next_parse_state(self : Node) -> @api.StateId? {
  match self.node_data() {
    Some(data) => data.next_parse_state
    None => None
  }
}

///|
pub fn Node::child_count(self : Node) -> Int {
  self.public_children().length()
}

///|
pub fn Node::named_child_count(self : Node) -> Int {
  let mut count = 0
  for child in self.public_children() {
    if self.child_node(child.index).is_named() {
      count += 1
    }
  }
  count
}

///|
pub fn Node::child(self : Node, index : Int) -> Node {
  let children = self.public_children()
  match children.get(index) {
    Some(child) => self.child_node(child.index)
    None => Node::null(self.language)
  }
}

///|
pub fn Node::named_child(self : Node, index : Int) -> Node {
  let mut seen = 0
  for child in self.public_children() {
    let node = self.child_node(child.index)
    if node.is_named() {
      if seen == index {
        return node
      }
      seen += 1
    }
  }
  Node::null(self.language)
}

///|
pub fn Node::parent(self : Node) -> Node {
  match self.data {
    Some(data) => {
      let mut index = match self.node_data() {
        Some(node_data) => node_data.parent
        None => -1
      }
      while index >= 0 && index < data.nodes.length() {
        if data.nodes[index].visible || data.nodes[index].alias_visible {
          return self.child_node(index)
        }
        index = data.nodes[index].parent
      }
      Node::null(self.language)
    }
    None => Node::null(self.language)
  }
}

///|
pub fn Node::next_sibling(self : Node) -> Node {
  self.sibling(step=1)
}

///|
pub fn Node::previous_sibling(self : Node) -> Node {
  self.sibling(step=-1)
}

///|
pub fn Node::next_named_sibling(self : Node) -> Node {
  self.named_sibling(step=1)
}

///|
pub fn Node::previous_named_sibling(self : Node) -> Node {
  self.named_sibling(step=-1)
}

///|
pub fn Node::field_name_for_child(self : Node, index : Int) -> String? {
  match self.public_children().get(index) {
    Some(child) => self.language.field_name_for_id(child.field_id)
    None => None
  }
}

///|
pub fn Node::field_name_for_named_child(self : Node, index : Int) -> String? {
  let mut seen = 0
  for child in self.public_children() {
    let node = self.child_node(child.index)
    if node.is_named() {
      if seen == index {
        return self.language.field_name_for_id(child.field_id)
      }
      seen += 1
    }
  }
  None
}

///|
pub fn Node::child_by_field_id(self : Node, field_id : @api.FieldId) -> Node {
  if field_id.value() == 0 {
    return Node::null(self.language)
  }
  for child in self.public_children() {
    if child.field_id == field_id {
      return self.child_node(child.index)
    }
  }
  Node::null(self.language)
}

///|
pub fn Node::child_by_field_name(self : Node, name : String) -> Node {
  match self.language.field_id_for_name(name) {
    Some(field_id) => self.child_by_field_id(field_id)
    None => Node::null(self.language)
  }
}

///|
pub fn Node::child_with_descendant(self : Node, descendant : Node) -> Node {
  if self.is_null() || descendant.is_null() {
    return Node::null(self.language)
  }
  if self.index == descendant.index {
    return self
  }
  for child in self.public_children() {
    let node = self.child_node(child.index)
    if node.contains_structural_index(descendant.index) {
      return node
    }
  }
  Node::null(self.language)
}

///|
pub fn Node::descendant_for_byte_range(
  self : Node,
  start_byte : UInt,
  end_byte : UInt,
) -> Node {
  self.descendant_for_byte_range_inner(start_byte, end_byte, named_only=false)
}

///|
pub fn Node::named_descendant_for_byte_range(
  self : Node,
  start_byte : UInt,
  end_byte : UInt,
) -> Node {
  self.descendant_for_byte_range_inner(start_byte, end_byte, named_only=true)
}

///|
pub fn Node::descendant_for_point_range(
  self : Node,
  start_point : @api.Point,
  end_point : @api.Point,
) -> Node {
  self.descendant_for_point_range_inner(
    start_point,
    end_point,
    named_only=false,
  )
}

///|
pub fn Node::named_descendant_for_point_range(
  self : Node,
  start_point : @api.Point,
  end_point : @api.Point,
) -> Node {
  self.descendant_for_point_range_inner(start_point, end_point, named_only=true)
}

///|
pub fn Node::first_child_for_byte(self : Node, byte : UInt) -> Node {
  self.first_child_for_byte_inner(byte, named_only=false)
}

///|
pub fn Node::first_named_child_for_byte(self : Node, byte : UInt) -> Node {
  self.first_child_for_byte_inner(byte, named_only=true)
}

///|
pub fn Node::first_child_for_point(self : Node, point : @api.Point) -> Node {
  self.first_child_for_point_inner(point, named_only=false)
}

///|
pub fn Node::first_named_child_for_point(
  self : Node,
  point : @api.Point,
) -> Node {
  self.first_child_for_point_inner(point, named_only=true)
}

///|
pub fn Node::descendant_count(self : Node) -> Int {
  if self.is_null() {
    0
  } else {
    1 + self.public_descendant_count()
  }
}

///|
pub fn Node::to_sexp(self : Node) -> String {
  let out = StringBuilder::new()
  self.write_sexp(out, field_id=@api.FieldId::new(0)) |> ignore
  out.to_string()
}

///|
fn Node::public_descendant_count(self : Node) -> Int {
  let mut count = 0
  for child in self.public_children() {
    let node = self.child_node(child.index)
    count += 1 + node.public_descendant_count()
  }
  count
}

///|
fn Node::descendant_for_byte_range_inner(
  self : Node,
  start_byte : UInt,
  end_byte : UInt,
  named_only~ : Bool,
) -> Node {
  if !self.covers_byte_range(start_byte, end_byte) {
    return Node::null(self.language)
  }
  for child in self.public_children() {
    let node = self.child_node(child.index)
    let node_end = node.end_byte()
    if node_end < end_byte {
      continue
    }
    if node.start_byte() == node_end {
      if node_end < start_byte {
        continue
      }
    } else if node_end <= start_byte {
      continue
    }
    if start_byte < node.start_byte() {
      break
    }
    let found = node.descendant_for_byte_range_inner(
      start_byte,
      end_byte,
      named_only~,
    )
    if !found.is_null() {
      return found
    }
    break
  }
  if !named_only || self.is_named() {
    self
  } else {
    Node::null(self.language)
  }
}

///|
fn Node::descendant_for_point_range_inner(
  self : Node,
  start_point : @api.Point,
  end_point : @api.Point,
  named_only~ : Bool,
) -> Node {
  if !self.covers_point_range(start_point, end_point) {
    return Node::null(self.language)
  }
  for child in self.public_children() {
    let node = self.child_node(child.index)
    let node_end = node.end_point()
    if node_end.lt(end_point) {
      continue
    }
    if node.start_point() == node_end {
      if node_end.lt(start_point) {
        continue
      }
    } else if node_end.lte(start_point) {
      continue
    }
    if start_point.lt(node.start_point()) {
      break
    }
    let found = node.descendant_for_point_range_inner(
      start_point,
      end_point,
      named_only~,
    )
    if !found.is_null() {
      return found
    }
    break
  }
  if !named_only || self.is_named() {
    self
  } else {
    Node::null(self.language)
  }
}

///|
fn Node::first_child_for_byte_inner(
  self : Node,
  byte : UInt,
  named_only~ : Bool,
) -> Node {
  for child in self.public_children() {
    let node = self.child_node(child.index)
    if node.end_byte() > byte && (!named_only || node.is_named()) {
      return node
    }
  }
  Node::null(self.language)
}

///|
fn Node::first_child_for_point_inner(
  self : Node,
  point : @api.Point,
  named_only~ : Bool,
) -> Node {
  for child in self.public_children() {
    let node = self.child_node(child.index)
    if node.end_point().gt(point) && (!named_only || node.is_named()) {
      return node
    }
  }
  Node::null(self.language)
}

///|
fn Node::covers_byte_range(
  self : Node,
  start_byte : UInt,
  end_byte : UInt,
) -> Bool {
  !self.is_null() &&
  start_byte <= end_byte &&
  self.start_byte() <= start_byte &&
  end_byte <= self.end_byte()
}

///|
fn Node::covers_point_range(
  self : Node,
  start_point : @api.Point,
  end_point : @api.Point,
) -> Bool {
  !self.is_null() &&
  start_point.lte(end_point) &&
  self.start_point().lte(start_point) &&
  end_point.lte(self.end_point())
}

///|
fn Node::contains_structural_index(self : Node, target : Int) -> Bool {
  match self.data {
    Some(data) =>
      if target < 0 || target >= data.nodes.length() {
        false
      } else {
        let mut index = target
        while index >= 0 && index < data.nodes.length() {
          if index == self.index {
            return true
          }
          index = data.nodes[index].parent
        }
        false
      }
    None => false
  }
}

///|
fn Node::sibling(self : Node, step~ : Int) -> Node {
  let parent = self.parent()
  if parent.is_null() {
    return Node::null(self.language)
  }
  let children = parent.public_children()
  for i in 0..<children.length() {
    if children[i].index == self.index {
      let next = i + step
      if next >= 0 && next < children.length() {
        return parent.child_node(children[next].index)
      }
      return Node::null(self.language)
    }
  }
  Node::null(self.language)
}

///|
fn Node::named_sibling(self : Node, step~ : Int) -> Node {
  let parent = self.parent()
  if parent.is_null() {
    return Node::null(self.language)
  }
  let named = parent.named_public_children()
  for i in 0..<named.length() {
    if named[i].index == self.index {
      let next = i + step
      if next >= 0 && next < named.length() {
        return parent.child_node(named[next].index)
      }
      return Node::null(self.language)
    }
  }
  Node::null(self.language)
}

///|
fn Node::child_node(self : Node, index : Int) -> Node {
  match self.data {
    Some(data) =>
      Node::from_tree_with_offset(
        data,
        index,
        byte_offset=self.byte_offset,
        point_offset=self.point_offset,
      )
    None => Node::null(self.language)
  }
}

///|
fn Node::public_children(self : Node) -> Array[PublicChild] {
  match self.node_data() {
    Some(data) => {
      let result = []
      for child in data.children {
        self.collect_public_children(
          child,
          inherited_field_id=@api.FieldId::new(0),
          result~,
        )
      }
      result
    }
    None => []
  }
}

///|
fn Node::named_public_children(self : Node) -> Array[PublicChild] {
  let result = []
  for child in self.public_children() {
    if self.child_node(child.index).is_named() {
      result.push(child)
    }
  }
  result
}

///|
fn Node::collect_public_children(
  self : Node,
  index : Int,
  inherited_field_id~ : @api.FieldId,
  result~ : Array[PublicChild],
) -> Unit {
  match self.data {
    Some(data) =>
      if index >= 0 && index < data.nodes.length() {
        let child = data.nodes[index]
        let effective_field_id = if child.extra {
          @api.FieldId::new(0)
        } else if child.field_id.value() != 0 {
          child.field_id
        } else {
          inherited_field_id
        }
        if child.visible || child.alias_visible {
          result.push({ index, field_id: effective_field_id })
        } else {
          for grandchild in child.children {
            self.collect_public_children(
              grandchild,
              inherited_field_id=effective_field_id,
              result~,
            )
          }
        }
      }
    None => ()
  }
}

///|
fn Node::public_child_position(self : Node) -> (Node, Int)? {
  let parent = self.parent()
  if parent.is_null() {
    None
  } else {
    let children = parent.public_children()
    for i in 0..<children.length() {
      if children[i].index == self.index {
        return Some((parent, i))
      }
    }
    None
  }
}

///|
fn Node::field_id_from_parent(self : Node) -> @api.FieldId {
  match self.public_child_position() {
    Some((parent, index)) =>
      match parent.public_children().get(index) {
        Some(child) => child.field_id
        None => @api.FieldId::new(0)
      }
    None => @api.FieldId::new(0)
  }
}

///|
fn Node::dfs_nodes(self : Node) -> Array[Node] {
  let result = []
  self.push_dfs(result~)
  result
}

///|
fn Node::push_dfs(self : Node, result~ : Array[Node]) -> Unit {
  if self.is_null() {
    return
  }
  result.push(self)
  for child in self.public_children() {
    self.child_node(child.index).push_dfs(result~)
  }
}

///|
fn Node::write_sexp(
  self : Node,
  out : StringBuilder,
  field_id~ : @api.FieldId,
) -> Bool {
  if self.is_null() {
    return false
  }
  if self.is_missing() {
    self.write_field_prefix(out, field_id~)
    out.write_string("(MISSING ")
    if self.is_named() {
      out.write_string(self.type_())
    } else {
      out.write_string("\"")
      out.write_string(self.type_())
      out.write_string("\"")
    }
    out.write_string(")")
    return true
  }
  if self.is_error() &&
    self.child_count() == 0 &&
    self.end_byte() > self.start_byte() {
    self.write_field_prefix(out, field_id~)
    out.write_string("(UNEXPECTED ")
    out.write_string(self.unexpected_error_text())
    out.write_string(")")
    return true
  }
  if !self.is_named() {
    return false
  }
  let child_parts = []
  for child in self.public_children() {
    let child_node = self.child_node(child.index)
    if self.has_redundant_lexical_child(child_node) {
      continue
    }
    let child_out = StringBuilder::new()
    if child_node.write_sexp(child_out, field_id=child.field_id) {
      child_parts.push(child_out.to_string())
    }
  }
  self.write_field_prefix(out, field_id~)
  out.write_string("(")
  out.write_string(self.type_())
  if !child_parts.is_empty() {
    out.write_string(" ")
    out.write_string(child_parts.join(" "))
  }
  out.write_string(")")
  true
}

///|
fn Node::has_redundant_lexical_child(self : Node, child : Node) -> Bool {
  if child.is_null() || child.is_missing() || child.is_error() {
    return false
  }
  if child.child_count() != 0 {
    return false
  }
  self.type_() == child.type_() &&
  self.start_byte() == child.start_byte() &&
  self.end_byte() == child.end_byte()
}

///|
fn Node::unexpected_error_text(self : Node) -> String {
  match self.node_data() {
    Some(data) =>
      match data.lookahead_char {
        Some(codepoint) => unexpected_codepoint_text(codepoint)
        None => self.type_()
      }
    None => self.type_()
  }
}

///|
fn unexpected_codepoint_text(codepoint : Int) -> String {
  if codepoint == -1 {
    return "INVALID"
  }
  if codepoint == 0 {
    return "'\\0'"
  }
  match codepoint.to_char() {
    Some(char) => char.escape()
    None => "\{codepoint}"
  }
}

///|
fn Node::write_field_prefix(
  self : Node,
  out : StringBuilder,
  field_id~ : @api.FieldId,
) -> Unit {
  match self.language.field_name_for_id(field_id) {
    Some(name) => {
      out.write_string(name)
      out.write_string(": ")
    }
    None => ()
  }
}

///|
fn add_u32_saturating(left : UInt, right : UInt) -> UInt {
  if right > @api.uint32_max() - left {
    @api.uint32_max()
  } else {
    left + right
  }
}

///|
pub fn TreeCursor::current_node(self : TreeCursor) -> Node {
  self.node
}

///|
pub fn TreeCursor::current_field_id(self : TreeCursor) -> @api.FieldId {
  self.node.field_id_from_parent()
}

///|
pub fn TreeCursor::current_field_name(self : TreeCursor) -> String? {
  self.node.language().field_name_for_id(self.current_field_id())
}

///|
pub fn TreeCursor::current_depth(self : TreeCursor) -> Int {
  let mut depth = 0
  let mut node = self.node
  while !node.is_null() && node.index != self.root.index {
    depth += 1
    node = node.parent()
  }
  depth
}

///|
pub fn TreeCursor::current_descendant_index(self : TreeCursor) -> Int {
  let nodes = self.root.dfs_nodes()
  for i in 0..<nodes.length() {
    if nodes[i].index == self.node.index {
      return i
    }
  }
  0
}

///|
pub fn TreeCursor::goto_parent(self : TreeCursor) -> TreeCursor? {
  if self.node.index == self.root.index {
    return None
  }
  let parent = self.node.parent()
  if parent.is_null() || !self.root.contains_structural_index(parent.index) {
    None
  } else {
    Some({ node: parent, root: self.root })
  }
}

///|
pub fn TreeCursor::goto_first_child(self : TreeCursor) -> TreeCursor? {
  let child = self.node.child(0)
  if child.is_null() {
    None
  } else {
    Some({ node: child, root: self.root })
  }
}

///|
pub fn TreeCursor::goto_first_child_for_byte(
  self : TreeCursor,
  byte : UInt,
) -> TreeCursor? {
  match self.goto_first_child_for_byte_with_index(byte) {
    Some((_, cursor)) => Some(cursor)
    None => None
  }
}

///|
pub fn TreeCursor::goto_first_child_for_byte_with_index(
  self : TreeCursor,
  byte : UInt,
) -> (Int, TreeCursor)? {
  let children = self.node.public_children()
  for i in 0..<children.length() {
    let child = self.node.child_node(children[i].index)
    if child.end_byte() > byte {
      return Some((i, { node: child, root: self.root }))
    }
  }
  None
}

///|
pub fn TreeCursor::goto_first_child_for_point(
  self : TreeCursor,
  point : @api.Point,
) -> TreeCursor? {
  match self.goto_first_child_for_point_with_index(point) {
    Some((_, cursor)) => Some(cursor)
    None => None
  }
}

///|
pub fn TreeCursor::goto_first_child_for_point_with_index(
  self : TreeCursor,
  point : @api.Point,
) -> (Int, TreeCursor)? {
  let children = self.node.public_children()
  for i in 0..<children.length() {
    let child = self.node.child_node(children[i].index)
    if child.end_point().gt(point) {
      return Some((i, { node: child, root: self.root }))
    }
  }
  None
}

///|
pub fn TreeCursor::goto_last_child(self : TreeCursor) -> TreeCursor? {
  let count = self.node.child_count()
  if count == 0 {
    None
  } else {
    Some({ node: self.node.child(count - 1), root: self.root })
  }
}

///|
pub fn TreeCursor::goto_next_sibling(self : TreeCursor) -> TreeCursor? {
  if self.node.index == self.root.index {
    return None
  }
  let node = self.node.next_sibling()
  if node.is_null() {
    None
  } else {
    Some({ node, root: self.root })
  }
}

///|
pub fn TreeCursor::goto_previous_sibling(self : TreeCursor) -> TreeCursor? {
  if self.node.index == self.root.index {
    return None
  }
  let node = self.node.previous_sibling()
  if node.is_null() {
    None
  } else {
    Some({ node, root: self.root })
  }
}

///|
pub fn TreeCursor::goto_descendant(
  self : TreeCursor,
  descendant_index : Int,
) -> TreeCursor? {
  let nodes = self.root.dfs_nodes()
  match nodes.get(descendant_index) {
    Some(node) => Some({ node, root: self.root })
    None => None
  }
}

///|
pub fn TreeCursor::reset(self : TreeCursor, node : Node) -> TreeCursor {
  let _ = self
  { node, root: node }
}

///|
pub fn TreeCursor::reset_to(
  self : TreeCursor,
  other : TreeCursor,
) -> TreeCursor {
  let _ = self
  other.copy()
}

///|
pub fn TreeCursor::copy(self : TreeCursor) -> TreeCursor {
  { node: self.node, root: self.root }
}
