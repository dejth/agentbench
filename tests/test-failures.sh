#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=tests/test-helper.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-helper.sh"
test_setup
trap test_teardown EXIT

make_git_repo "$TEST_TMP/project"
(
  cd "$TEST_TMP/project"
  "$TEST_ROOT/agentbench.sh" init >/dev/null
)

run_expect_failure() {
  local command_text="$1"
  local timeout_seconds="$2"

  set +e
  (
    cd "$TEST_TMP/project"
    "$TEST_ROOT/agentbench.sh" run \
      --setup baseline \
      --agent-command "$command_text" \
      --runs 1 \
      --timeout "$timeout_seconds" >/dev/null
  )
  status=$?
  set -e
  [[ "$status" -ne 0 ]] || fail "failing benchmark returned success"
}

run_expect_failure true 3
index_file="$TEST_TMP/project/.agentbench/results/baseline/runs.json"
[[ "$(jq '.results[0].validations[0].passed' "$index_file")" == "false" ]] || fail "failed validation was not recorded"
[[ "$(jq '[.results[0].required_files[] | select(.exists == false)] | length' "$index_file")" -eq 1 ]] || fail "missing required file was not recorded"

run_expect_failure 'exit 23' 3
[[ "$(jq '.results[0].agent.exit_code' "$index_file")" -eq 23 ]] || fail "agent command failure exit was not recorded"

run_expect_failure 'sleep 5' 1
[[ "$(jq '.results[0].agent.timed_out' "$index_file")" == "true" ]] || fail "agent timeout was not recorded"
workspace_count="$(find "$TEST_TMP/project/.agentbench/tmp" -name OWNER -print | wc -l | tr -d ' ')"
[[ "$workspace_count" -eq 0 ]] || fail "timeout left a managed workspace"

printf 'ok - failed validation, missing file, agent failure, and timeout are preserved\n'
