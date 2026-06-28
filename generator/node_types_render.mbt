///|
priv struct NodeTypeRef {
  type_name : String
  named : Bool
} derive(Eq)

///|
priv struct NodeTypeChildrenDraft {
  types : Array[NodeTypeRef]
  required : Bool
  multiple : Bool
}

///|
priv struct NodeTypeFieldDraft {
  name : String
  types : Array[NodeTypeRef]
  required : Bool
  multiple : Bool
}

///|
priv struct NodeTypeFieldAccumulator {
  name : String
  types : Array[NodeTypeRef]
  production_count : Int
  multiple : Bool
}

///|
priv struct NodeTypeProductionField {
  name : String
  types : Array[NodeTypeRef]
  count : Int
}

///|
priv struct NodeTypeEntryDraft {
  type_name : String
  named : Bool
  root : Bool
  extra : Bool
  subtypes : Array[NodeTypeRef]
  fields : Array[NodeTypeFieldDraft]
  children : NodeTypeChildrenDraft?
}

///|
priv struct NodeTypeSupertypeMap {
  supertype : NodeTypeRef
  subtypes : Array[NodeTypeRef]
}

///|
fn generated_node_types_json(grammar : PreparedGrammar) -> String {
  let entries = node_type_entries(grammar)
  node_type_process_supertypes(entries)
  render_node_type_entries(entries)
}

///|
fn node_type_entries(grammar : PreparedGrammar) -> Array[NodeTypeEntryDraft] {
  let entries : Array[NodeTypeEntryDraft] = []
  for symbol in grammar.syntax.supertype_symbols {
    match node_type_ref_for_symbol(grammar, symbol, apply_default_alias=false) {
      Some(node_ref) =>
        push_node_type_entry(entries, {
          type_name: node_ref.type_name,
          named: node_ref.named,
          root: node_type_symbol_is_root(grammar, symbol),
          extra: false,
          subtypes: node_type_supertype_refs(grammar, symbol),
          fields: [],
          children: None,
        })
      None => ()
    }
  }
  for i in 0..<grammar.syntax.variables.length() {
    let symbol = InternalSymbol::NonTerminal(i)
    if !contains_internal_symbol(grammar.syntax.supertype_symbols, symbol) {
      match node_type_ref_for_symbol(grammar, symbol) {
        Some(node_ref) =>
          push_node_type_entry(
            entries,
            node_type_entry_for_variable(grammar, i, node_ref),
          )
        None => ()
      }
    }
  }
  node_type_push_alias_entries(grammar, entries)
  for i in 0..<grammar.lexical.variables.length() {
    let symbol = InternalSymbol::Terminal(i)
    match node_type_ref_for_symbol(grammar, symbol) {
      Some(node_ref) =>
        push_node_type_entry(
          entries,
          node_type_leaf_entry(grammar, symbol, node_ref),
        )
      None => ()
    }
  }
  for i in 0..<grammar.syntax.external_tokens.length() {
    let symbol = InternalSymbol::External(i)
    match node_type_ref_for_symbol(grammar, symbol) {
      Some(node_ref) =>
        push_node_type_entry(
          entries,
          node_type_leaf_entry(grammar, symbol, node_ref),
        )
      None => ()
    }
  }
  entries
}

///|
fn node_type_push_alias_entries(
  grammar : PreparedGrammar,
  entries : Array[NodeTypeEntryDraft],
) -> Unit {
  for variable in grammar.syntax.variables {
    for production in variable.productions {
      for step in production.steps {
        match step.alias_name {
          Some(value) =>
            push_node_type_entry(
              entries,
              node_type_entry_for_alias_step(grammar, step, {
                type_name: value,
                named: step.alias_named,
              }),
            )
          None => ()
        }
      }
    }
  }
}

///|
fn node_type_entry_for_alias_step(
  grammar : PreparedGrammar,
  step : ProductionStep,
  node_ref : NodeTypeRef,
) -> NodeTypeEntryDraft {
  match step.symbol {
    InternalSymbol::NonTerminal(index) =>
      if index >= 0 && index < grammar.syntax.variables.length() {
        let variable = grammar.syntax.variables[index]
        {
          type_name: node_ref.type_name,
          named: node_ref.named,
          root: false,
          extra: node_type_symbol_is_extra(grammar, step.symbol),
          subtypes: [],
          fields: node_type_fields_for_variable(grammar, variable),
          children: node_type_children_for_variable(grammar, variable),
        }
      } else {
        node_type_leaf_entry(grammar, step.symbol, node_ref)
      }
    InternalSymbol::Terminal(_) | InternalSymbol::External(_) =>
      node_type_leaf_entry(grammar, step.symbol, node_ref)
  }
}

///|
fn node_type_entry_for_variable(
  grammar : PreparedGrammar,
  index : Int,
  node_ref : NodeTypeRef,
) -> NodeTypeEntryDraft {
  let symbol = InternalSymbol::NonTerminal(index)
  let variable = grammar.syntax.variables[index]
  {
    type_name: node_ref.type_name,
    named: node_ref.named,
    root: node_type_symbol_is_root(grammar, symbol),
    extra: node_type_symbol_is_extra(grammar, symbol),
    subtypes: [],
    fields: node_type_fields_for_variable(grammar, variable),
    children: node_type_children_for_variable(grammar, variable),
  }
}

///|
fn node_type_leaf_entry(
  grammar : PreparedGrammar,
  symbol : InternalSymbol,
  node_ref : NodeTypeRef,
) -> NodeTypeEntryDraft {
  {
    type_name: node_ref.type_name,
    named: node_ref.named,
    root: node_type_symbol_is_root(grammar, symbol),
    extra: node_type_symbol_is_extra(grammar, symbol),
    subtypes: [],
    fields: [],
    children: None,
  }
}

///|
fn node_type_supertype_refs(
  grammar : PreparedGrammar,
  supertype : InternalSymbol,
) -> Array[NodeTypeRef] {
  let refs : Array[NodeTypeRef] = []
  match supertype {
    InternalSymbol::NonTerminal(index) =>
      if index >= 0 && index < grammar.syntax.variables.length() {
        for production in grammar.syntax.variables[index].productions {
          for step in production.steps {
            if step.symbol != supertype {
              let step_refs = node_type_refs_for_visible_step(grammar, step, [])
              for node_ref in step_refs {
                push_node_type_ref(refs, node_ref)
              }
            }
          }
        }
      }
    _ => ()
  }
  refs.sort_by(node_type_ref_compare)
  refs
}

///|
fn node_type_children_for_variable(
  grammar : PreparedGrammar,
  variable : FlattenedVariable,
) -> NodeTypeChildrenDraft? {
  let types : Array[NodeTypeRef] = []
  let mut required = variable.productions.length() > 0
  let mut multiple = false
  for production in variable.productions {
    let production_types : Array[NodeTypeRef] = []
    let mut production_child_count = 0
    for step in production.steps {
      if step.field_name is None {
        let step_refs = node_type_refs_for_unfielded_step(grammar, step, [])
        production_child_count += step_refs.length()
        for node_ref in step_refs {
          push_node_type_ref(production_types, node_ref)
        }
      }
    }
    if production_child_count == 0 {
      required = false
    }
    if production_child_count > 1 {
      multiple = true
    }
    for node_ref in production_types {
      push_node_type_ref(types, node_ref)
    }
  }
  if types.is_empty() {
    None
  } else {
    types.sort_by(node_type_ref_compare)
    Some({ types, required, multiple })
  }
}

///|
fn node_type_fields_for_variable(
  grammar : PreparedGrammar,
  variable : FlattenedVariable,
) -> Array[NodeTypeFieldDraft] {
  let accumulators : Array[NodeTypeFieldAccumulator] = []
  for production in variable.productions {
    let fields = node_type_fields_for_production(grammar, production)
    for field in fields {
      node_type_record_field(accumulators, field)
    }
  }
  let result : Array[NodeTypeFieldDraft] = []
  for accumulator in accumulators {
    let types = accumulator.types
    types.sort_by(node_type_ref_compare)
    result.push({
      name: accumulator.name,
      types,
      required: variable.productions.length() > 0 &&
      accumulator.production_count == variable.productions.length(),
      multiple: accumulator.multiple,
    })
  }
  result
}

///|
fn node_type_fields_for_production(
  grammar : PreparedGrammar,
  production : FlattenedProduction,
) -> Array[NodeTypeProductionField] {
  node_type_fields_for_production_with_visited(grammar, production, [])
}

///|
fn node_type_fields_for_production_with_visited(
  grammar : PreparedGrammar,
  production : FlattenedProduction,
  visited : Array[InternalSymbol],
) -> Array[NodeTypeProductionField] {
  let fields : Array[NodeTypeProductionField] = []
  for step in production.steps {
    match step.field_name {
      Some(name) => {
        let step_refs = node_type_refs_for_visible_step(grammar, step, visited)
        for node_ref in step_refs {
          node_type_record_production_field(fields, name, node_ref)
        }
      }
      None => {
        let inherited_fields = node_type_inherited_fields_for_step(
          grammar, step, visited,
        )
        for inherited_field in inherited_fields {
          node_type_merge_production_field(fields, inherited_field)
        }
      }
    }
  }
  fields
}

///|
fn node_type_record_production_field(
  fields : Array[NodeTypeProductionField],
  name : String,
  node_ref : NodeTypeRef,
) -> Unit {
  node_type_merge_production_field(fields, { name, types: [node_ref], count: 1 })
}

///|
fn node_type_merge_production_field(
  fields : Array[NodeTypeProductionField],
  production_field : NodeTypeProductionField,
) -> Unit {
  for i in 0..<fields.length() {
    let comparison = fields[i].name.compare(production_field.name)
    if comparison == 0 {
      for node_ref in production_field.types {
        push_node_type_ref(fields[i].types, node_ref)
      }
      fields[i] = {
        ..fields[i],
        count: fields[i].count + production_field.count,
      }
      return
    }
    if comparison > 0 {
      fields.insert(i, production_field)
      return
    }
  }
  fields.push(production_field)
}

///|
fn node_type_refs_for_unfielded_step(
  grammar : PreparedGrammar,
  step : ProductionStep,
  visited : Array[InternalSymbol],
) -> Array[NodeTypeRef] {
  match node_type_ref_for_step(grammar, step) {
    Some(node_ref) => [node_ref]
    None =>
      node_type_refs_for_hidden_symbol(
        grammar,
        step.symbol,
        visited,
        include_fielded=false,
      )
  }
}

///|
fn node_type_refs_for_visible_step(
  grammar : PreparedGrammar,
  step : ProductionStep,
  visited : Array[InternalSymbol],
) -> Array[NodeTypeRef] {
  match node_type_ref_for_step(grammar, step) {
    Some(node_ref) => [node_ref]
    None =>
      node_type_refs_for_hidden_symbol(
        grammar,
        step.symbol,
        visited,
        include_fielded=true,
      )
  }
}

///|
fn node_type_inherited_fields_for_step(
  grammar : PreparedGrammar,
  step : ProductionStep,
  visited : Array[InternalSymbol],
) -> Array[NodeTypeProductionField] {
  let result : Array[NodeTypeProductionField] = []
  match step.symbol {
    InternalSymbol::NonTerminal(index) =>
      if node_type_nonterminal_can_inherit(grammar, index) &&
        !contains_internal_symbol(visited, step.symbol) {
        let next_visited = visited.copy()
        next_visited.push(step.symbol)
        for production in grammar.syntax.variables[index].productions {
          let fields = node_type_fields_for_production_with_visited(
            grammar, production, next_visited,
          )
          for field in fields {
            node_type_merge_production_field(result, field)
          }
        }
      }
    InternalSymbol::Terminal(_) | InternalSymbol::External(_) => ()
  }
  result
}

///|
fn node_type_refs_for_hidden_symbol(
  grammar : PreparedGrammar,
  symbol : InternalSymbol,
  visited : Array[InternalSymbol],
  include_fielded~ : Bool,
) -> Array[NodeTypeRef] {
  let refs : Array[NodeTypeRef] = []
  match symbol {
    InternalSymbol::NonTerminal(index) =>
      if node_type_nonterminal_can_inherit(grammar, index) &&
        !contains_internal_symbol(visited, symbol) {
        let next_visited = visited.copy()
        next_visited.push(symbol)
        for production in grammar.syntax.variables[index].productions {
          for step in production.steps {
            if include_fielded || step.field_name is None {
              let step_refs = node_type_refs_for_visible_step(
                grammar, step, next_visited,
              )
              for node_ref in step_refs {
                push_node_type_ref(refs, node_ref)
              }
            }
          }
        }
      }
    InternalSymbol::Terminal(_) | InternalSymbol::External(_) => ()
  }
  refs
}

///|
fn node_type_nonterminal_can_inherit(
  grammar : PreparedGrammar,
  index : Int,
) -> Bool {
  index >= 0 &&
  index < grammar.syntax.variables.length() &&
  (
    is_hidden_kind(grammar.syntax.variables[index].kind) ||
    is_auxiliary_kind(grammar.syntax.variables[index].kind)
  )
}

///|
fn node_type_record_field(
  accumulators : Array[NodeTypeFieldAccumulator],
  production_field : NodeTypeProductionField,
) -> Unit {
  for i in 0..<accumulators.length() {
    let comparison = accumulators[i].name.compare(production_field.name)
    if comparison == 0 {
      let types = accumulators[i].types
      for node_ref in production_field.types {
        push_node_type_ref(types, node_ref)
      }
      accumulators[i] = {
        name: accumulators[i].name,
        types,
        production_count: accumulators[i].production_count + 1,
        multiple: accumulators[i].multiple || production_field.count > 1,
      }
      return
    }
    if comparison > 0 {
      accumulators.insert(i, {
        name: production_field.name,
        types: production_field.types,
        production_count: 1,
        multiple: production_field.count > 1,
      })
      return
    }
  }
  accumulators.push({
    name: production_field.name,
    types: production_field.types,
    production_count: 1,
    multiple: production_field.count > 1,
  })
}

///|
fn node_type_ref_for_step(
  grammar : PreparedGrammar,
  step : ProductionStep,
) -> NodeTypeRef? {
  match step.alias_name {
    Some(value) => Some({ type_name: value, named: step.alias_named })
    None => node_type_ref_for_symbol(grammar, step.symbol)
  }
}

///|
fn node_type_ref_for_symbol(
  grammar : PreparedGrammar,
  symbol : InternalSymbol,
  apply_default_alias? : Bool = true,
) -> NodeTypeRef? {
  if apply_default_alias {
    match node_type_default_alias_for_symbol(grammar.default_aliases, symbol) {
      Some(default_alias) =>
        return Some({
          type_name: default_alias.value,
          named: default_alias.named,
        })
      None => ()
    }
  }
  match symbol {
    InternalSymbol::Terminal(index) =>
      if index >= 0 && index < grammar.lexical.variables.length() {
        node_type_ref_for_kind(
          grammar.lexical.variables[index].name,
          grammar.lexical.variables[index].kind,
        )
      } else {
        None
      }
    InternalSymbol::External(index) =>
      if index >= 0 && index < grammar.syntax.external_tokens.length() {
        node_type_ref_for_kind(
          grammar.syntax.external_tokens[index].name,
          grammar.syntax.external_tokens[index].kind,
        )
      } else {
        None
      }
    InternalSymbol::NonTerminal(index) =>
      if contains_internal_symbol(grammar.syntax.supertype_symbols, symbol) {
        Some({ type_name: grammar.syntax.variables[index].name, named: true })
      } else if index >= 0 && index < grammar.syntax.variables.length() {
        node_type_ref_for_kind(
          grammar.syntax.variables[index].name,
          grammar.syntax.variables[index].kind,
        )
      } else {
        None
      }
  }
}

///|
fn node_type_ref_for_kind(name : String, kind : VariableKind) -> NodeTypeRef? {
  match kind {
    VariableKind::Named => Some({ type_name: name, named: true })
    VariableKind::Anonymous => Some({ type_name: name, named: false })
    VariableKind::Hidden | VariableKind::Auxiliary => None
  }
}

///|
fn node_type_default_alias_for_symbol(
  aliases : Array[DefaultAlias],
  symbol : InternalSymbol,
) -> DefaultAlias? {
  for default_alias in aliases {
    if default_alias.symbol == symbol {
      return Some(default_alias)
    }
  }
  None
}

///|
fn node_type_symbol_is_root(
  grammar : PreparedGrammar,
  symbol : InternalSymbol,
) -> Bool {
  grammar.syntax.start_symbol == Some(symbol)
}

///|
fn node_type_symbol_is_extra(
  grammar : PreparedGrammar,
  symbol : InternalSymbol,
) -> Bool {
  contains_internal_symbol(grammar.syntax.extra_symbols, symbol)
}

///|
fn push_node_type_entry(
  entries : Array[NodeTypeEntryDraft],
  entry : NodeTypeEntryDraft,
) -> Unit {
  for i in 0..<entries.length() {
    if entries[i].type_name == entry.type_name &&
      entries[i].named == entry.named {
      entries[i] = node_type_merge_entries(entries[i], entry)
      return
    }
  }
  entries.push(entry)
}

///|
fn node_type_merge_entries(
  left : NodeTypeEntryDraft,
  right : NodeTypeEntryDraft,
) -> NodeTypeEntryDraft {
  let subtypes = left.subtypes
  for node_ref in right.subtypes {
    push_node_type_ref(subtypes, node_ref)
  }
  subtypes.sort_by(node_type_ref_compare)
  {
    type_name: left.type_name,
    named: left.named,
    root: left.root || right.root,
    extra: left.extra || right.extra,
    subtypes,
    fields: node_type_merge_fields(left.fields, right.fields),
    children: node_type_merge_children(left.children, right.children),
  }
}

///|
fn node_type_merge_fields(
  left : Array[NodeTypeFieldDraft],
  right : Array[NodeTypeFieldDraft],
) -> Array[NodeTypeFieldDraft] {
  let fields : Array[NodeTypeFieldDraft] = []
  for left_field in left {
    match node_type_find_field(right, left_field.name) {
      Some(right_field) =>
        fields.push(node_type_merge_field(left_field, right_field))
      None => fields.push({ ..left_field, required: false })
    }
  }
  for right_field in right {
    match node_type_find_field(left, right_field.name) {
      Some(_) => ()
      None => fields.push({ ..right_field, required: false })
    }
  }
  fields.sort_by(node_type_field_compare)
  fields
}

///|
fn node_type_merge_field(
  left : NodeTypeFieldDraft,
  right : NodeTypeFieldDraft,
) -> NodeTypeFieldDraft {
  let types = node_type_merge_ref_arrays(left.types, right.types)
  {
    name: left.name,
    types,
    required: left.required && right.required,
    multiple: left.multiple || right.multiple,
  }
}

///|
fn node_type_find_field(
  fields : Array[NodeTypeFieldDraft],
  name : String,
) -> NodeTypeFieldDraft? {
  for field in fields {
    if field.name == name {
      return Some(field)
    }
  }
  None
}

///|
fn node_type_field_compare(
  left : NodeTypeFieldDraft,
  right : NodeTypeFieldDraft,
) -> Int {
  left.name.compare(right.name)
}

///|
fn node_type_merge_children(
  left : NodeTypeChildrenDraft?,
  right : NodeTypeChildrenDraft?,
) -> NodeTypeChildrenDraft? {
  match left {
    Some(left_children) =>
      match right {
        Some(right_children) =>
          Some(node_type_merge_child_drafts(left_children, right_children))
        None => Some({ ..left_children, required: false })
      }
    None =>
      match right {
        Some(right_children) => Some({ ..right_children, required: false })
        None => None
      }
  }
}

///|
fn node_type_merge_child_drafts(
  left : NodeTypeChildrenDraft,
  right : NodeTypeChildrenDraft,
) -> NodeTypeChildrenDraft {
  let types = node_type_merge_ref_arrays(left.types, right.types)
  {
    types,
    required: left.required && right.required,
    multiple: left.multiple || right.multiple,
  }
}

///|
fn node_type_merge_ref_arrays(
  left : Array[NodeTypeRef],
  right : Array[NodeTypeRef],
) -> Array[NodeTypeRef] {
  let refs = left.copy()
  for node_ref in right {
    push_node_type_ref(refs, node_ref)
  }
  refs.sort_by(node_type_ref_compare)
  refs
}

///|
fn node_type_process_supertypes(entries : Array[NodeTypeEntryDraft]) -> Unit {
  let subtype_map = node_type_subtype_map(entries)
  if subtype_map.is_empty() {
    return
  }
  node_type_sort_subtype_map(subtype_map)
  for i in 0..<entries.length() {
    let entry = entries[i]
    let fields : Array[NodeTypeFieldDraft] = []
    for field in entry.fields {
      fields.push(node_type_process_field_supertypes(field, subtype_map))
    }
    let children = match entry.children {
      Some(value) =>
        Some(node_type_process_children_supertypes(value, subtype_map))
      None => None
    }
    entries[i] = { ..entry, fields, children }
  }
}

///|
fn node_type_subtype_map(
  entries : Array[NodeTypeEntryDraft],
) -> Array[NodeTypeSupertypeMap] {
  let result : Array[NodeTypeSupertypeMap] = []
  for entry in entries {
    if !entry.subtypes.is_empty() {
      result.push({
        supertype: { type_name: entry.type_name, named: entry.named },
        subtypes: entry.subtypes,
      })
    }
  }
  result
}

///|
fn node_type_sort_subtype_map(maps : Array[NodeTypeSupertypeMap]) -> Unit {
  maps.sort_by((left, right) => {
    let left_depth = node_type_supertype_depth(left.supertype, maps, [])
    let right_depth = node_type_supertype_depth(right.supertype, maps, [])
    if left_depth == right_depth {
      node_type_ref_compare(left.supertype, right.supertype)
    } else {
      left_depth - right_depth
    }
  })
}

///|
fn node_type_supertype_depth(
  supertype : NodeTypeRef,
  maps : Array[NodeTypeSupertypeMap],
  visited : Array[NodeTypeRef],
) -> Int {
  if node_type_ref_array_contains(visited, supertype) {
    0
  } else {
    let next_visited = visited.copy()
    next_visited.push(supertype)
    let mut depth = 0
    match node_type_find_supertype_map(maps, supertype) {
      Some(entry) =>
        for subtype in entry.subtypes {
          match node_type_find_supertype_map(maps, subtype) {
            Some(_) => {
              let subtype_depth = 1 +
                node_type_supertype_depth(subtype, maps, next_visited)
              if subtype_depth > depth {
                depth = subtype_depth
              }
            }
            None => ()
          }
        }
      None => ()
    }
    depth
  }
}

///|
fn node_type_find_supertype_map(
  maps : Array[NodeTypeSupertypeMap],
  supertype : NodeTypeRef,
) -> NodeTypeSupertypeMap? {
  for entry in maps {
    if entry.supertype == supertype {
      return Some(entry)
    }
  }
  None
}

///|
fn node_type_process_field_supertypes(
  field : NodeTypeFieldDraft,
  subtype_map : Array[NodeTypeSupertypeMap],
) -> NodeTypeFieldDraft {
  {
    ..field,
    types: node_type_process_type_supertypes(field.types, subtype_map),
  }
}

///|
fn node_type_process_children_supertypes(
  children : NodeTypeChildrenDraft,
  subtype_map : Array[NodeTypeSupertypeMap],
) -> NodeTypeChildrenDraft {
  {
    ..children,
    types: node_type_process_type_supertypes(children.types, subtype_map),
  }
}

///|
fn node_type_process_type_supertypes(
  types : Array[NodeTypeRef],
  subtype_map : Array[NodeTypeSupertypeMap],
) -> Array[NodeTypeRef] {
  let result = types.copy()
  for entry in subtype_map {
    if node_type_ref_array_contains(result, entry.supertype) {
      node_type_remove_refs(result, entry.subtypes)
    }
  }
  result.sort_by(node_type_ref_compare)
  result
}

///|
fn node_type_remove_refs(
  refs : Array[NodeTypeRef],
  removed : Array[NodeTypeRef],
) -> Unit {
  for i = refs.length() - 1; i >= 0; i = i - 1 {
    if node_type_ref_array_contains(removed, refs[i]) {
      ignore(refs.remove(i))
    }
  }
}

///|
fn node_type_ref_array_contains(
  refs : Array[NodeTypeRef],
  node_ref : NodeTypeRef,
) -> Bool {
  for existing in refs {
    if existing == node_ref {
      return true
    }
  }
  false
}

///|
fn push_node_type_ref(
  refs : Array[NodeTypeRef],
  node_ref : NodeTypeRef,
) -> Unit {
  for existing in refs {
    if existing == node_ref {
      return
    }
  }
  refs.push(node_ref)
}

///|
fn node_type_ref_compare(left : NodeTypeRef, right : NodeTypeRef) -> Int {
  let type_comparison = left.type_name.compare(right.type_name)
  if type_comparison != 0 {
    type_comparison
  } else if left.named == right.named {
    0
  } else if left.named {
    1
  } else {
    -1
  }
}

///|
fn render_node_type_entries(entries : Array[NodeTypeEntryDraft]) -> String {
  if entries.is_empty() {
    "[]"
  } else {
    let rendered : Array[String] = []
    for entry in entries {
      rendered.push("  \{render_node_type_entry(entry)}")
    }
    "[\n\{rendered.join(",\n")}\n]"
  }
}

///|
fn render_node_type_entry(entry : NodeTypeEntryDraft) -> String {
  let fields : Array[String] = [
    "\"type\": \{render_node_type_string(entry.type_name)}",
    "\"named\": \{render_node_type_bool(entry.named)}",
  ]
  if entry.root {
    fields.push("\"root\": true")
  }
  if entry.extra {
    fields.push("\"extra\": true")
  }
  if !entry.subtypes.is_empty() {
    fields.push("\"subtypes\": \{render_node_type_ref_array(entry.subtypes)}")
  }
  if !entry.fields.is_empty() {
    fields.push("\"fields\": \{render_node_type_field_map(entry.fields)}")
  }
  match entry.children {
    Some(children) =>
      fields.push("\"children\": \{render_node_type_children(children)}")
    None => ()
  }
  "{\{fields.join(", ")}}"
}

///|
fn render_node_type_field_map(fields : Array[NodeTypeFieldDraft]) -> String {
  let rendered : Array[String] = []
  for field in fields {
    rendered.push(
      "\{render_node_type_string(field.name)}: \{render_node_type_field(field)}",
    )
  }
  "{\{rendered.join(", ")}}"
}

///|
fn render_node_type_field(field : NodeTypeFieldDraft) -> String {
  let parts = [
    "\"multiple\": \{render_node_type_bool(field.multiple)}",
    "\"required\": \{render_node_type_bool(field.required)}",
    "\"types\": \{render_node_type_ref_array(field.types)}",
  ]
  "{\{parts.join(", ")}}"
}

///|
fn render_node_type_children(children : NodeTypeChildrenDraft) -> String {
  let parts = [
    "\"multiple\": \{render_node_type_bool(children.multiple)}",
    "\"required\": \{render_node_type_bool(children.required)}",
    "\"types\": \{render_node_type_ref_array(children.types)}",
  ]
  "{\{parts.join(", ")}}"
}

///|
fn render_node_type_ref_array(refs : Array[NodeTypeRef]) -> String {
  let rendered : Array[String] = []
  for node_ref in refs {
    rendered.push(render_node_type_ref(node_ref))
  }
  "[\{rendered.join(", ")}]"
}

///|
fn render_node_type_ref(node_ref : NodeTypeRef) -> String {
  let parts = [
    "\"type\": \{render_node_type_string(node_ref.type_name)}",
    "\"named\": \{render_node_type_bool(node_ref.named)}",
  ]
  "{\{parts.join(", ")}}"
}

///|
fn render_node_type_bool(value : Bool) -> String {
  if value {
    "true"
  } else {
    "false"
  }
}

///|
fn render_node_type_string(value : String) -> String {
  let pieces : Array[String] = ["\""]
  for char in value.to_array() {
    match char {
      '"' => pieces.push("\\\"")
      '\\' => pieces.push("\\\\")
      '\n' => pieces.push("\\n")
      '\r' => pieces.push("\\r")
      '\t' => pieces.push("\\t")
      _ => pieces.push(char.to_string())
    }
  }
  pieces.push("\"")
  pieces.join("")
}
