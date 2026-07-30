#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=test-helper.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-helper.sh"
test_setup
trap test_teardown EXIT

cp "$TEST_ROOT/templates/BENCHMARK.md" "$TEST_TMP/valid.md"
output="$($TEST_ROOT/agentbench.sh validate --benchmark "$TEST_TMP/valid.md")"
assert_contains "is valid" "$output"

awk '!/^## Critical Failures$/' "$TEST_TMP/valid.md" > "$TEST_TMP/invalid.md"
if "$TEST_ROOT/agentbench.sh" validate --benchmark "$TEST_TMP/invalid.md" \
  >"$TEST_TMP/stdout" 2>"$TEST_TMP/stderr"; then
  fail "benchmark with a missing section passed"
fi
actual="$(cat "$TEST_TMP/stderr")"
assert_contains "missing required section: ## Critical Failures" "$actual"

sed 's/^Format-Version: 1$/Format-Version: 2/' \
  "$TEST_TMP/valid.md" > "$TEST_TMP/unsupported.md"
if "$TEST_ROOT/agentbench.sh" validate --benchmark "$TEST_TMP/unsupported.md" \
  >"$TEST_TMP/stdout" 2>"$TEST_TMP/stderr"; then
  fail "benchmark with an unsupported format version passed"
fi
actual="$(cat "$TEST_TMP/stderr")"
assert_contains "unsupported or missing Format-Version: 2" "$actual"

# shellcheck source=src/utils.sh
source "$TEST_ROOT/src/utils.sh"
# shellcheck source=src/parser.sh
source "$TEST_ROOT/src/parser.sh"
commands="$(ab_validation_commands "$TEST_TMP/valid.md")"
[[ "$commands" == "./tests/example-test.sh" ]] || fail "validation block parsed incorrectly"

printf 'ok - parser accepts valid and rejects invalid benchmarks\n'
