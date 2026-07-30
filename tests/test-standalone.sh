#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=tests/test-helper.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-helper.sh"
test_setup
trap test_teardown EXIT

make_git_repo "$TEST_TMP/project"
cp "$TEST_ROOT/agentbench.sh" "$TEST_TMP/project/agentbench.sh"
chmod +x "$TEST_TMP/project/agentbench.sh"
(
  cd "$TEST_TMP/project"
  ./agentbench.sh init >/dev/null
  ./agentbench.sh validate >/dev/null
)

assert_file "$TEST_TMP/project/.agentbench/BENCHMARK.md"
assert_file "$TEST_TMP/project/.agentbench/.gitignore"
assert_not_exists "$TEST_TMP/project/src"
assert_not_exists "$TEST_TMP/project/templates"

printf 'ok - standalone runner initializes without source modules\n'
