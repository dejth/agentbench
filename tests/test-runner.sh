#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=test-helper.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-helper.sh"
test_setup
trap test_teardown EXIT

make_git_repo "$TEST_TMP/project"
(
  cd "$TEST_TMP/project"
  "$TEST_ROOT/agentbench.sh" init >/dev/null
  "$TEST_ROOT/agentbench.sh" run \
    --setup baseline \
    --agent-command "bash $TEST_ROOT/tests/fixtures/success-agent.sh" \
    --runs 2 \
    --timeout 5 >/dev/null
)

index_file="$TEST_TMP/project/.agentbench/results/baseline/runs.json"
assert_file "$index_file"
[[ "$(jq '.results | length' "$index_file")" -eq 2 ]] || fail "runner did not preserve two results"
[[ "$(jq '[.results[] | select(.status == "PASS")] | length' "$index_file")" -eq 2 ]] || fail "successful runs did not pass"
[[ "$(git -C "$TEST_TMP/project" status --short --untracked-files=no)" == "" ]] || fail "runner modified tracked files in original checkout"
workspace_count="$(find "$TEST_TMP/project/.agentbench/tmp" -name OWNER -print | wc -l | tr -d ' ')"
[[ "$workspace_count" -eq 0 ]] || fail "runner left a managed workspace"

printf 'ok - runner preserves repeated isolated results\n'
