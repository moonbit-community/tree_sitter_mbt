///|
#cfg(target="native")
extern "c" fn read_cli_stdin_bytes_ffi() -> Bytes = "tree_sitter_mbt_cli_read_stdin_bytes"

///|
#cfg(not(target="native"))
fn read_cli_stdin_bytes_ffi() -> Bytes {
  b""
}

///|
fn read_cli_stdin_bytes() -> Bytes {
  read_cli_stdin_bytes_ffi()
}
