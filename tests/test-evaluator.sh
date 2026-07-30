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
# shellcheck source=adapters/custom.sh
source "$TEST_ROOT/adapters/custom.sh"
# shellcheck source=src/evaluator.sh
source "$TEST_ROOT/src/evaluator.sh"
test_setup
trap test_teardown EXIT

make_git_repo "$TEST_TMP/project"
mkdir -p "$TEST_TMP/project/src" "$TEST_TMP/project/tests" "$TEST_TMP/output"
printf 'base\n' > "$TEST_TMP/project/src/app.txt"
git -C "$TEST_TMP/project" add src/app.txt
git -C "$TEST_TMP/project" commit -qm "add app"
starting_commit="$(git -C "$TEST_TMP/project" rev-parse HEAD)"

cp "$TEST_ROOT/templates/BENCHMARK.md" "$TEST_TMP/BENCHMARK.md"
# The backticks are literal Markdown code spans.
# shellcheck disable=SC2016
sed -e 's#`tests/example-test.sh`#`tests/regression.txt`#' \
  -e 's#./tests/example-test.sh#test -f tests/regression.txt#' \
  "$TEST_TMP/BENCHMARK.md" > "$TEST_TMP/BENCHMARK.next"
mv "$TEST_TMP/BENCHMARK.next" "$TEST_TMP/BENCHMARK.md"
cp "$TEST_ROOT/templates/CONTEXT.md" "$TEST_TMP/CONTEXT.md"
: > "$TEST_TMP/agent.stdout"
: > "$TEST_TMP/agent.stderr"
printf 'TOKEN=secretvalue123\n' > "$TEST_TMP/agent.stdout"

printf 'changed\n' >> "$TEST_TMP/project/src/app.txt"
printf 'covered\n' > "$TEST_TMP/project/tests/regression.txt"
result_path="$(ab_evaluate_run \
  "$TEST_TMP/project" \
  "$TEST_TMP/project" \
  "$TEST_TMP/BENCHMARK.md" \
  "$TEST_TMP/CONTEXT.md" \
  baseline \
  run-success \
  "$starting_commit" \
  'fake-agent' \
  0 \
  2 \
  false \
  "$TEST_TMP/agent.stdout" \
  "$TEST_TMP/agent.stderr" \
  30 \
  "$TEST_TMP/output/success")"
[[ "$(jq -r '.status' "$result_path")" == "PASS" ]] || fail "valid run did not pass"
[[ "$(jq -r '.score' "$result_path")" -eq 100 ]] || fail "valid run score was not 100"
[[ "$(jq '.scope_violations | length' "$result_path")" -eq 0 ]] || fail "allowed files violated scope"
assert_contains "[REDACTED]" "$(jq -r '.agent.stdout' "$result_path")"
[[ "$(jq -r '.human_intervention_count' "$result_path")" == "null" ]] || fail "unavailable human intervention was invented"
assert_file "$TEST_TMP/output/success/evidence/git.diff"
assert_contains "src/app.txt" "$(jq -r '.git_diff.stat' "$result_path")"

printf 'violation\n' > "$TEST_TMP/project/outside.txt"
result_path="$(ab_evaluate_run \
  "$TEST_TMP/project" \
  "$TEST_TMP/project" \
  "$TEST_TMP/BENCHMARK.md" \
  "$TEST_TMP/CONTEXT.md" \
  candidate \
  run-failure \
  "$starting_commit" \
  'fake-agent' \
  0 \
  2 \
  false \
  "$TEST_TMP/agent.stdout" \
  "$TEST_TMP/agent.stderr" \
  30 \
  "$TEST_TMP/output/failure")"
[[ "$(jq -r '.status' "$result_path")" == "FAIL" ]] || fail "scope violation did not fail"
[[ "$(jq -r '.scope_violations[0]' "$result_path")" == "outside.txt" ]] || fail "scope violation was not recorded"

sed 's#test -f tests/regression.txt#sleep 5#' \
  "$TEST_TMP/BENCHMARK.md" > "$TEST_TMP/timeout.md"
mkdir -p "$TEST_TMP/output/timeout"
ab_run_validations \
  "$TEST_TMP/project" \
  "$TEST_TMP/timeout.md" \
  "$TEST_TMP/output/timeout" \
  "$TEST_TMP/output/timeout/validations.json" \
  1
[[ "$(jq '.[0].exit_code' "$TEST_TMP/output/timeout/validations.json")" -eq 124 ]] || fail "validation timeout status was not recorded"
[[ "$(jq -r '.[0].timed_out' "$TEST_TMP/output/timeout/validations.json")" == "true" ]] || fail "validation timeout flag was not recorded"

printf 'ok - evaluator records pass and critical scope failure evidence\n'
