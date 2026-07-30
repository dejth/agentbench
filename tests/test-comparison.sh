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
  "$TEST_ROOT/agentbench.sh" run \
    --setup baseline \
    --agent-command "bash $TEST_ROOT/tests/fixtures/success-agent.sh" \
    --runs 1 \
    --timeout 5 >/dev/null
  if "$TEST_ROOT/agentbench.sh" run \
    --setup candidate \
    --agent-command "bash $TEST_ROOT/tests/fixtures/scope-failure-agent.sh" \
    --runs 1 \
    --timeout 5 >/dev/null; then
    fail "scope-violating candidate unexpectedly passed"
  fi
  printf 'changed after benchmark execution\n' > .agentbench/setups/baseline/CONTEXT.md
  "$TEST_ROOT/agentbench.sh" compare baseline candidate > "$TEST_TMP/comparison-output"
)

latest_file="$TEST_TMP/project/.agentbench/reports/latest.json"
assert_file "$latest_file"
[[ "$(jq '.baseline.pass_rate' "$latest_file")" -eq 100 ]] || fail "baseline pass rate is incorrect"
[[ "$(jq '.candidate.pass_rate' "$latest_file")" -eq 0 ]] || fail "candidate pass rate is incorrect"
comparison_id="$(jq -r '.comparison_id' "$latest_file")"
report_file="$TEST_TMP/project/.agentbench/reports/$comparison_id/BENCHMARK.md"
assert_file "$report_file"
assert_contains "## Individual Run Results" "$(cat "$report_file")"
assert_contains "## Reproduction" "$(cat "$report_file")"
assert_contains "candidate pass rate was 100 percentage points lower" "$(cat "$TEST_TMP/comparison-output")"

assert_contains "Keep the benchmark task constant" "$(cat "$report_file")"
if [[ "$(cat "$report_file")" == *"changed after benchmark execution"* ]]; then
  fail "report used a setup definition changed after execution"
fi

report_output="$(cd "$TEST_TMP/project" && "$TEST_ROOT/agentbench.sh" report "$comparison_id")"
assert_contains "# AgentBench Comparison" "$report_output"

printf 'ok - comparison statistics and reports match stored evidence\n'
