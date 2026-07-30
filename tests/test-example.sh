#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=tests/test-helper.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-helper.sh"
test_setup
trap test_teardown EXIT

cp -R "$TEST_ROOT/examples/prompt-comparison" "$TEST_TMP/project"
cp "$TEST_ROOT/agentbench.sh" "$TEST_TMP/project/agentbench.sh"
git -C "$TEST_TMP/project" init -q
git -C "$TEST_TMP/project" config user.name "AgentBench Tests"
git -C "$TEST_TMP/project" config user.email "tests@agentbench.local"
git -C "$TEST_TMP/project" add .
git -C "$TEST_TMP/project" commit -qm "example fixture"

(
  cd "$TEST_TMP/project"
  if ./agentbench.sh run \
    --setup baseline \
    --agent-command "./fake-agent.sh" \
    --runs 1 \
    --timeout 5 >/dev/null; then
    fail "documented baseline unexpectedly passed"
  fi
  ./agentbench.sh run \
    --setup candidate \
    --agent-command "./fake-agent.sh" \
    --runs 1 \
    --timeout 5 >/dev/null
  ./agentbench.sh compare baseline candidate >/dev/null
)

latest_file="$TEST_TMP/project/.agentbench/reports/latest.json"
assert_file "$latest_file"
[[ "$(jq '.baseline.pass_rate' "$latest_file")" -eq 0 ]] || fail "example baseline pass rate is incorrect"
[[ "$(jq '.candidate.pass_rate' "$latest_file")" -eq 100 ]] || fail "example candidate pass rate is incorrect"

printf 'ok - documented example reproduces baseline and candidate evidence\n'
