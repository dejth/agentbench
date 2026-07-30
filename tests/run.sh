#!/usr/bin/env bash

set -Eeuo pipefail

TESTS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
requested=" ${*:-all} "
failures=0
executed=0

run_test() {
  local aliases="$1"
  local script_path="$2"
  local test_name
  local selected=false

  if [[ "$requested" == *" all "* ]]; then
    selected=true
  else
    for test_name in $aliases; do
      if [[ "$requested" == *" $test_name "* ]]; then
        selected=true
      fi
    done
  fi

  if [[ "$selected" != "true" ]]; then
    return 0
  fi

  executed=$((executed + 1))
  if ! "$script_path"; then
    failures=$((failures + 1))
  fi
}

run_test init "$TESTS_ROOT/test-init.sh"
run_test parser "$TESTS_ROOT/test-parser.sh"
run_test workspace "$TESTS_ROOT/test-workspace.sh"
run_test adapter "$TESTS_ROOT/test-adapter.sh"
run_test evaluator "$TESTS_ROOT/test-evaluator.sh"
run_test scoring "$TESTS_ROOT/test-scoring.sh"
run_test schema "$TESTS_ROOT/test-schema.sh"
run_test runner "$TESTS_ROOT/test-runner.sh"
run_test "comparison report" "$TESTS_ROOT/test-comparison.sh"
run_test cli "$TESTS_ROOT/test-cli.sh"
run_test failures "$TESTS_ROOT/test-failures.sh"
run_test clean "$TESTS_ROOT/test-clean.sh"
run_test standalone "$TESTS_ROOT/test-standalone.sh"
run_test example "$TESTS_ROOT/test-example.sh"
run_test docs "$TESTS_ROOT/test-docs.sh"

if [[ "$executed" -eq 0 ]]; then
  printf 'No tests matched: %s\n' "${*:-}" >&2
  exit 2
fi

if [[ "$failures" -ne 0 ]]; then
  printf '%s test file(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'All %s test file(s) passed\n' "$executed"
