///|
pub(all) struct FixtureSource {
  name : String
  upstream_path : String
  grammar_json : String
  corpus : String
  external_scanner_status : String
} derive(Eq, Debug)

///|
pub fn upstream_version() -> String {
  "0.27.0"
}

///|
pub fn upstream_commit() -> String {
  "4455da71029b13fa113956d1470c75c85db8fdc5"
}

///|
pub fn native_abi_version() -> Int32 {
  15
}

///|
pub fn minimal_fixture() -> FixtureSource {
  let grammar_json =
    #|{
    #|  "name": "minimal",
    #|  "rules": {
    #|    "document": {
    #|      "type": "STRING",
    #|      "value": "a"
    #|    }
    #|  }
    #|}
  let corpus =
    #|===
    #|single literal
    #|===
    #|a
    #|---
    #|(document)
  {
    name: "minimal",
    upstream_path: "local/minimal",
    grammar_json,
    corpus,
    external_scanner_status: "none",
  }
}

///|
pub extend FixtureSource with Debug::{to_repr}

///|
pub extend FixtureSource with Eq::{not_equal, equal}
