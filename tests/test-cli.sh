#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=tests/test-helper.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-helper.sh"
test_setup
trap test_teardown EXIT

assert_contains "AgentBench — Test your AI context" "$("$TEST_ROOT/agentbench.sh" help)"
[[ "$("$TEST_ROOT/agentbench.sh" version)" == "AgentBench 0.1.0" ]] || fail "version output is incorrect"

set +e
(cd "$TEST_TMP" && "$TEST_ROOT/agentbench.sh" init) \
  >"$TEST_TMP/stdout" 2>"$TEST_TMP/stderr"
status=$?
set -e
[[ "$status" -ne 0 ]] || fail "init outside Git succeeded"
assert_contains "inside a Git repository" "$(cat "$TEST_TMP/stderr")"

make_git_repo "$TEST_TMP/project"
(
  cd "$TEST_TMP/project"
  "$TEST_ROOT/agentbench.sh" init >/dev/null
)

set +e
(
  cd "$TEST_TMP/project"
  "$TEST_ROOT/agentbench.sh" run --setup missing --agent-command true
) >"$TEST_TMP/stdout" 2>"$TEST_TMP/stderr"
status=$?
set -e
[[ "$status" -ne 0 ]] || fail "invalid setup succeeded"
assert_contains "setup not found" "$(cat "$TEST_TMP/stderr")"

set +e
"$TEST_ROOT/agentbench.sh" unknown-command \
  >"$TEST_TMP/stdout" 2>"$TEST_TMP/stderr"
status=$?
set -e
[[ "$status" -eq 2 ]] || fail "unknown command did not use exit 2"

set +e
bash -c 'source "$1/src/utils.sh"; ab_require_command agentbench-command-that-does-not-exist' \
  _ "$TEST_ROOT" >"$TEST_TMP/stdout" 2>"$TEST_TMP/stderr"
status=$?
set -e
[[ "$status" -ne 0 ]] || fail "missing dependency succeeded"
assert_contains "required command not found" "$(cat "$TEST_TMP/stderr")"

printf 'ok - CLI rejects invalid repository, setup, command, and dependency inputs\n'
