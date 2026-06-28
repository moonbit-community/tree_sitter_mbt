///|
test "fixture baseline is pinned" {
  assert_eq(upstream_version(), "0.27.0")
  assert_eq(upstream_commit(), "4455da71029b13fa113956d1470c75c85db8fdc5")
  assert_eq(native_abi_version(), 15)
}
