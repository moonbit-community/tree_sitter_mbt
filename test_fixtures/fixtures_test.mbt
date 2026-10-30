///|
test "fixture baseline is pinned" {
  assert_eq(@test_fixtures.upstream_version(), "0.27.0")
  assert_eq(
    @test_fixtures.upstream_commit(),
    "4455da71029b13fa113956d1470c75c85db8fdc5",
  )
  assert_eq(@test_fixtures.native_abi_version(), 15)
}
