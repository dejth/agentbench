#!/usr/bin/env bash

set -Eeuo pipefail

TESTS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
requested=" ${*:-all} "
failures=0
executed=0

run_test() {
  local name="$1"
  local script_path="$2"

  if [[ "$requested" != *" all "* && "$requested" != *" $name "* ]]; then
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

if [[ "$executed" -eq 0 ]]; then
  printf 'No tests matched: %s\n' "${*:-}" >&2
  exit 2
fi

if [[ "$failures" -ne 0 ]]; then
  printf '%s test file(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'All %s test file(s) passed\n' "$executed"
