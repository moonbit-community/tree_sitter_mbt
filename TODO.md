# TODO

## 上游 Fixture 矩阵

- 完成 `test_fixtures` 中可执行的上游 fixture 矩阵。
  - 当前 manifest 目标：覆盖 56 个上游 fixture 目录。
  - 分组：30 个可运行 corpus fixture，10 个预期生成失败 fixture，16 个暂不支持的 C scanner fixture。
  - 当前矩阵文件：
    - `test_fixtures/upstream_manifest_wbtest.mbt`
    - `test_fixtures/upstream_matrix_wbtest.mbt`

## Runtime / Generator 缺口

- 实现真正的 dynamic precedence 冲突处理。
  - 失败 fixture：`dynamic_precedence`。
  - 现象：`T * x` 应解析为：
    `(program (declaration (type (identifier)) (declarator (identifier))))`
    但当前解析为：
    `(program (expression (expression (identifier)) (expression (identifier))))`
  - 可能根因：当前 runtime 是确定性 parser，没有保留足够久的竞争 parse 分支，无法按 Tree-sitter 风格用 dynamic precedence 选择最终结果。

- 补全 generator 中 unresolved conflict 的检测。
  - 失败的 expected-error fixture：`conflicting_precedence`。
  - 现象：当前 generation 会成功，但上游预期应报 unresolved conflict。
  - 已有部分工作：无声明 conflicts 时的校验可以捕获部分多 action 冲突，并跳过合法的 auxiliary repeat continuation 冲突。

- 修复 non-terminal extras 的增量重解析。
  - 失败 fixture：`extra_non_terminals`。
  - 现象：编辑并带 `old_tree` 重解析后，incremental smoke test 抛出 `LexError(byte_offset=8, state_id={ value: 2 })`。
  - 需要检查的区域：old-tree edit/reparse 复用、non-terminal extras、lexer state，以及 pending/leading extras 的处理。

## 尚未完成的矩阵测试

- 让 `moon test test_fixtures` 通过。
  - 当前失败项：
    - `upstream expected-error fixtures fail local generation as classified`
    - `upstream runnable corpus fixtures pass through generator and runtime`
    - `upstream runnable corpus fixtures reparse edited input like fresh parse`

- 修完缺口后，重跑计划中的验证命令：
  - `moon check`
  - `moon test test_fixtures`
  - `moon test test_fixtures/generated_upstream_inline_rules`
  - `moon test test_fixtures/generated_upstream_reserved_words`
  - `moon test test_fixtures/generated_upstream_immediate_tokens`
  - `moon test test_fixtures/generated_upstream_unicode_classes`
  - `moon test test_fixtures/generated_upstream_dynamic_precedence`
  - `moon test generator/generator_test.mbt`
  - `moon test generator/generator_wbtest.mbt`
  - `moon info && moon fmt`

## Scanner Fixtures

- 在 MoonBit-native 或 C-interop external scanner 策略实现前，继续将 16 个带 `scanner.c` 的上游 fixture 明确标记为 unsupported。
- scanner 支持完成后，把已支持的 case 从 `UnsupportedExternalScanner` 移到 runnable corpus 覆盖中。
