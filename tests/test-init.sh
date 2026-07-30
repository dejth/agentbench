#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=tests/test-helper.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-helper.sh"
test_setup
trap test_teardown EXIT

make_git_repo "$TEST_TMP/project with space"
(
  cd "$TEST_TMP/project with space"
  "$TEST_ROOT/agentbench.sh" init >/dev/null
)

assert_file "$TEST_TMP/project with space/.agentbench/BENCHMARK.md"
assert_file "$TEST_TMP/project with space/.agentbench/setups/baseline/CONTEXT.md"
assert_file "$TEST_TMP/project with space/.agentbench/setups/candidate/CONTEXT.md"

printf 'user content\n' > "$TEST_TMP/project with space/.agentbench/setups/baseline/CONTEXT.md"
(
  cd "$TEST_TMP/project with space"
  "$TEST_ROOT/agentbench.sh" init >/dev/null
)

actual="$(cat "$TEST_TMP/project with space/.agentbench/setups/baseline/CONTEXT.md")"
[[ "$actual" == "user content" ]] || fail "init overwrote an existing file"

printf 'ok - init is non-destructive\n'
