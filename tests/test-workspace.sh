#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=test-helper.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/test-helper.sh"
# shellcheck source=src/utils.sh
source "$TEST_ROOT/src/utils.sh"
# shellcheck source=src/workspace.sh
source "$TEST_ROOT/src/workspace.sh"
test_setup
trap test_teardown EXIT

make_git_repo "$TEST_TMP/project with space"
mkdir -p "$TEST_TMP/project with space/.agentbench/tmp"
revision="$(git -C "$TEST_TMP/project with space" rev-parse HEAD)"

ab_workspace_create "$TEST_TMP/project with space" "$revision" "workspace-test"
workspace="$AB_WORKSPACE_PATH"
parent="$AB_WORKSPACE_PARENT"
assert_file "$workspace/README.md"
printf 'isolated change\n' >> "$workspace/README.md"

original="$(cat "$TEST_TMP/project with space/README.md")"
[[ "$original" == "# Fixture" ]] || fail "worktree modified the original checkout"

ab_workspace_cleanup "$TEST_TMP/project with space"
assert_not_exists "$parent"

set +e
bash -c '
  set -Eeuo pipefail
  source "$1/src/utils.sh"
  source "$1/src/workspace.sh"
  ab_workspace_create "$2" "$3" interruption-test
  printf "%s\n" "$AB_WORKSPACE_PARENT" > "$4"
  ab_workspace_install_cleanup_trap "$2"
  kill -TERM "$$"
' _ \
  "$TEST_ROOT" \
  "$TEST_TMP/project with space" \
  "$revision" \
  "$TEST_TMP/interrupted-parent"
interrupt_status=$?
set -e
[[ "$interrupt_status" -eq 143 ]] || fail "interrupt status was not preserved"
interrupted_parent="$(cat "$TEST_TMP/interrupted-parent")"
assert_not_exists "$interrupted_parent"

mkdir -p "$TEST_TMP/project with space/.agentbench/tmp/unmanaged/worktree"
if ab_workspace_discard_parent \
  "$TEST_TMP/project with space" \
  "$TEST_TMP/project with space/.agentbench/tmp/unmanaged" \
  2>/dev/null; then
  fail "cleanup accepted an unmanaged directory"
fi
assert_not_exists "$TEST_TMP/project with space/.agentbench/tmp/unmanaged/OWNER"

printf 'ok - worktree is isolated and cleanup requires ownership\n'
