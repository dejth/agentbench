#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=test-helper.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-helper.sh"
# shellcheck source=src/utils.sh
source "$TEST_ROOT/src/utils.sh"
# shellcheck source=src/parser.sh
source "$TEST_ROOT/src/parser.sh"
# shellcheck source=adapters/custom.sh
source "$TEST_ROOT/adapters/custom.sh"
test_setup
trap test_teardown EXIT

mkdir -p "$TEST_TMP/workspace" "$TEST_TMP/output"
cp "$TEST_ROOT/templates/BENCHMARK.md" "$TEST_TMP/BENCHMARK.md"
cp "$TEST_ROOT/templates/CONTEXT.md" "$TEST_TMP/CONTEXT.md"
ab_build_agent_prompt \
  "$TEST_TMP/BENCHMARK.md" \
  "$TEST_TMP/CONTEXT.md" \
  "$TEST_TMP/output/prompt.md"
assert_file "$TEST_TMP/output/prompt.md"

ab_run_custom_agent \
  "$TEST_TMP/workspace" \
  'cat > received-prompt.md; printf success' \
  "$TEST_TMP/output/prompt.md" \
  3 \
  "$TEST_TMP/output/stdout" \
  "$TEST_TMP/output/stderr"
[[ "$AB_AGENT_EXIT_CODE" -eq 0 ]] || fail "successful agent returned non-zero"
assert_file "$TEST_TMP/workspace/received-prompt.md"
assert_contains "Setup Context" "$(cat "$TEST_TMP/workspace/received-prompt.md")"
assert_contains "success" "$(cat "$TEST_TMP/output/stdout")"

ab_run_custom_agent \
  "$TEST_TMP/workspace" \
  'printf failed >&2; exit 23' \
  "$TEST_TMP/output/prompt.md" \
  3 \
  "$TEST_TMP/output/stdout" \
  "$TEST_TMP/output/stderr"
[[ "$AB_AGENT_EXIT_CODE" -eq 23 ]] || fail "agent failure status was not captured"
assert_contains "failed" "$(cat "$TEST_TMP/output/stderr")"

ab_run_custom_agent \
  "$TEST_TMP/workspace" \
  'sleep 5' \
  "$TEST_TMP/output/prompt.md" \
  1 \
  "$TEST_TMP/output/stdout" \
  "$TEST_TMP/output/stderr"
[[ "$AB_AGENT_EXIT_CODE" -eq 124 ]] || fail "timeout status was not normalized"
[[ "$AB_AGENT_TIMED_OUT" == "true" ]] || fail "timeout flag was not recorded"

ab_run_custom_agent \
  "$TEST_TMP/workspace" \
  'printf recovered' \
  "$TEST_TMP/output/prompt.md" \
  3 \
  "$TEST_TMP/output/stdout" \
  "$TEST_TMP/output/stderr"
[[ "$AB_AGENT_EXIT_CODE" -eq 0 ]] || fail "adapter state leaked after timeout"
[[ "$AB_AGENT_TIMED_OUT" == "false" ]] || fail "timeout flag was not reset"

printf 'ok - custom adapter captures success, failure, and timeout\n'
