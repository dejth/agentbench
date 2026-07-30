#!/usr/bin/env bash

set -Eeuo pipefail

TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP=""

test_setup() {
  TEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/agentbench-test.XXXXXX")"
}

test_teardown() {
  if [[ -n "$TEST_TMP" && -d "$TEST_TMP" ]]; then
    rm -rf "$TEST_TMP"
  fi
}

fail() {
  printf 'not ok - %s\n' "$1" >&2
  return 1
}

assert_file() {
  [[ -f "$1" ]] || fail "expected file: $1"
}

assert_contains() {
  local expected="$1"
  local actual="$2"
  [[ "$actual" == *"$expected"* ]] || fail "expected output to contain: $expected"
}

make_git_repo() {
  local destination="$1"
  mkdir -p "$destination"
  git -C "$destination" init -q
  git -C "$destination" config user.name "AgentBench Tests"
  git -C "$destination" config user.email "tests@agentbench.local"
  printf '# Fixture\n' > "$destination/README.md"
  git -C "$destination" add README.md
  git -C "$destination" commit -qm "fixture"
}

assert_not_exists() {
  [[ ! -e "$1" ]] || fail "expected path not to exist: $1"
}
