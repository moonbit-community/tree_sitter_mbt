# moonbit-community/tree_sitter_mbt

MoonBit-native Tree-sitter runtime and generator work in progress.

This repository targets upstream Tree-sitter 0.27.0 at commit
`4455da71029b13fa113956d1470c75c85db8fdc5`. The mapped upstream source roots
are:

- runtime: `../tree-sitter/lib/src`
- public C API reference: `../tree-sitter/lib/include/tree_sitter/api.h`
- generator: `../tree-sitter/crates/generate/src`
- CLI: `../tree-sitter/crates/cli/src`

The v1 native target is Tree-sitter language ABI 15. The MoonBit core packages
stay platform-IO free; file IO is isolated in CLI-facing packages.

## Package Layout

- `api`: shared public value types such as points, ranges, edits, encodings, and
  callback-facing scanner errors.
- root package: stable opaque runtime facade types such as `Language`, `Parser`,
  `Tree`, `Node`, and `TreeCursor`.
- `runtime`: internal runtime implementation package.
- `runtime/tables`: generated table construction, validation, metadata, and
  scanner descriptor boundary.
- `grammar`: `grammar.json` parsing and normalized input grammar IR.
- `generator`: MoonBit-native generator entry point returning generated sources
  and metadata without writing files.
- `query`: query parser, cursor, captures, and predicate filtering helpers.
- `highlight`: highlight configuration and event generation over query/runtime.
- `tags`: tags configuration and tag extraction over query/runtime.
- `cli`: in-memory command argument parsing and command runners.
- `cli/native`: file-backed adapters around the CLI command runners.
- `cmd/tree-sitter-mbt`: executable package; currently supports file-backed
  `generate`, `parse`, `test`, `query`, and `tags`. Dynamic language loading is
  still rejected; grammar.json and tree-sitter.json based loading is supported.
- `test_fixtures`: embedded fixture constants for all-target tests.

Generated parser packages should import the root package and `runtime/tables`.
Packages with external tokens should also import `api` for callback-facing
types. Import aliases are generator options, not hard-coded source paths.

## Runtime Boundary

The root package intentionally owns the stable `Language`, `Parser`, `Tree`,
`Node`, and `TreeCursor` facade in v1. Parser/tree/node implementation code
currently lives in the root package rather than being fully moved under
`runtime`; this is a documented package-boundary divergence while the v1 table
model and corpus behavior stabilize.

## CLI Boundary

The `cli` package remains an all-target, in-memory command layer. It may depend
on the root package, `generator`, `query`, `highlight`, and `tags`, but it does
not perform direct filesystem operations. The `cli/native` package owns file
reads and writes via `moonbitlang/async/fs` and delegates to `cli` runners. Native
`generate` reads an adjacent `tree-sitter.json` when present and uses
`metadata.version` for generated language metadata; if that file is absent, the
metadata defaults to `0.0.0`.
