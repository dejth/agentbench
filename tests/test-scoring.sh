#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=tests/test-helper.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-helper.sh"
# shellcheck source=src/utils.sh
source "$TEST_ROOT/src/utils.sh"
# shellcheck source=src/parser.sh
source "$TEST_ROOT/src/parser.sh"
# shellcheck source=src/scoring.sh
source "$TEST_ROOT/src/scoring.sh"
test_setup
trap test_teardown EXIT

cp "$TEST_ROOT/templates/BENCHMARK.md" "$TEST_TMP/BENCHMARK.md"
ab_calculate_score "$TEST_TMP/BENCHMARK.md" 2 2 true true true 0
[[ "$AB_SCORE_TOTAL" -eq 100 ]] || fail "successful score must be 100"
[[ "$AB_SCORE_STATUS" == "PASS" ]] || fail "successful score must pass"

ab_calculate_score "$TEST_TMP/BENCHMARK.md" 2 1 true true true 1
[[ "$AB_SCORE_TOTAL" -eq 40 ]] || fail "partial score calculation is incorrect"
[[ "$AB_SCORE_STATUS" == "FAIL" ]] || fail "critical failure must override score"

printf 'ok - scoring is deterministic and critical failures override score\n'
